#!/usr/bin/env node
var fs = require("fs");
var vm = require("vm");
var wrench = require("wrench");
var path = require("path");
var exec = require("child_process").exec;
var commander = require("commander");

var program = commander
	.option("-f,--file <filename>", "specify the watchfile location; default is ./Watchfile")
	//.option("-a,--all","don't ignore file with '.' start")
	.option("-i,--interval <interval>", "minimum compile interval between changes; default is 0.5sec", parseInt)
	.option("-c,--create-default", "create default rules; saved as ./Watchfile")
	.option("-v,--version", "print version")
	.option("-s,--start-compile", "compile all matched file at start")
	.option("-w,--use-watch-file", "use watchFile method instead of watch (from the fs module); use only if the first one is not working properly")
	.version("0.0.6")
	.parse(process.argv);

var defaultWatchFile = "//{basename} /css/style.less => style.less\n"
	+"//{fullpath} /css/style.less => /css/style.less (unchanged)\n"
	+"//{filename} /css/style.less => style\n"
	+"//{extname}  /css/style.less => .less\n"
	+"//{directory} /css/style.less => /css/\n\n"
	+"exports.watchList = [\n"
	+"\t[/^.*coffee$/,'coffee -c {fullpath}'],\n"
	+"\t[/^.*less$/,'lessc {fullpath} > {directory}{filename}.css'],\n"
	+"];";

if (program.createDefault) {
	console.log("create default Watchfile at ./Watchfile");
	if (fs.existsSync("./Watchfile")) {
		console.log("./Watchfile exists,not overwrite");
		process.exit(1);
	}
	fs.writeFileSync("./Watchfile", defaultWatchFile);
	console.log("done");
	process.exit(0);
}
// avoid Warnning->possible EventEmitter memory leak detected. 11 listeners added. Use emitter.setMaxListeners() to increase limit.
process.stdout.setMaxListeners(2000)
process.stderr.setMaxListeners(2000)
var ignoreHidden = !program.all;
var watchFile = program.file || "./Watchfile";
var interval = Math.abs(program.interval) || 500;
console.log("watchFile is %s", watchFile);
console.log("minum compile interval is %d", interval);
var compilingCount = 0;
try{
	var context = vm.createContext({exports:{}});
	var WatchfileCode = fs.readFileSync(watchFile);
	vm.runInContext(WatchfileCode, context, "watchFile");
	var list = context.exports.watchList || [];
	console.log(context);
}catch(e){
	console.error("invalid watchfile '%s'", watchFile);
	process.exit(1);
}
var result = wrench.readdirSyncRecursive("./");

function matchList(fullpath){
	for (var i=0; i<list.length; i++) {
		(function(){
			if (list[i][0].test(fullpath)) {
				var rule = list[i];
				var basename = path.basename(fullpath);
				var extname = path.extname(fullpath);
				var filename = basename.replace(extname, "");
				var directory = path.dirname(fullpath) + "/";
				var lastCompile = 0;
				var cmd = rule[1].replace(/\{filename\}/g, filename)
					.replace(/\{fullpath\}/g, fullpath)
					.replace(/\{directory\}/g, directory)
					.replace(/\{basename\}/g, basename)
					.replace(/\{extname\}/g, extname);
				var _param = cmd.split(/\s+/);
				var _execname = _param.shift();
				var _isCompiling = false;
				var compileProcess = null;
				console.log("matched", fullpath);
				var compile = function(){
					console.log(cmd);
					lastCompile = Date.now();
					compileProcess = exec(cmd);
					_isCompiling = true;
					compileProcess.stdout.pipe(process.stdout);
					compileProcess.stderr.pipe(process.stderr);
					compileProcess.on("exit",function(code){
						_isCompiling = false;
						if (code === 0) {
							console.log(fullpath,"recompile done");
						} else {
							console.error("fail to compile %s,error code %i",fullpath,code);
						}
					})
				};
				var processCompiling = function(){
					console.log(fullpath, "changed, recompile...");
					if (_isCompiling && compileProcess) {
						console.log("last compiling in progress; abort last compiling");
						compileProcess.on("exit", compile);
						compileProcess.kill();
					} else {
						compile();
					}
				};
				if (program.useWatchFile) {
					fs.watchFile(fullpath, {interval:interval}, function(curr, prev){
						if (Date.now() - lastCompile > interval) {
							processCompiling();
						}
					});
				} else {
					fs.watch(fullpath, function(ev,_filename){
						// according to node API doc, _filename is not garenteed to be provided, so we don't use it
						if (ev == "change" && Date.now() - lastCompile > interval) {
							processCompiling();
						}
					});
				}
				if (program.startCompile) {
					compile();
				}
				return;
			}
		})();
	}
};
for (var i=0; i<result.length; i++) {
	if (!fs.existsSync(result[i])) {
		continue;
	}
	matchList(result[i]);
}
