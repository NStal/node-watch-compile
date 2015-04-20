fs = require("fs");
vm = require("vm");
Watcher = require "./watcher"
wrench = require "wrench"
Queue = require "./queue"
Rule = require "./rule"
commander = require("commander");
program = commander
    .option("-f,--file <filename>","specifail the watchfile default is Watchfile")
    .option("-c,--create-default","create and default rules save as ./Watchfile")
    .option("-v,--version","print version")
    .option("-s,--start-compile","compile all matched file at start")
    .version("0.0.5")
    .parse(process.argv);

defaultWatchFile = """
//{basename} /css/style.less => style.less
//{fullpath} /css/style.less => /css/style.less (unchanged)
//{filename} /css/style.less => style
//{extname}  /css/style.less => .less
//{directory} /css/style.less => /css/
exports.watchList = [
    [/^.*coffee$/,'coffee -c {fullpath}']
    ,[/^.*less$/,'lessc {fullpath} > {directory}{filename}.css']
]
""";
if program.createDefault
    console.log "create default Watchfile at ./Watchfile"
    if fs.existsSync "./Watchfile"
        console.log "./Watchfile exists,not overwrite"
        process.exit(1);
    fs.writeFileSync "./Watchfile",defaultWatchFile
    console.log "done create default watchfile"

# avoid Warnning->possible EventEmitter memory leak detected. 11 listeners added. Use emitter.setMaxListeners() to increase limit.
process.stdout.setMaxListeners(2000)
process.stderr.setMaxListeners(2000)
ignoreHidden = !program.all;
watchFile = program.file || "./Watchfile";

try
    context = vm.createContext({exports:{}})
    WatchfileCode = fs.readFileSync(watchFile)
    vm.runInContext(WatchfileCode,context,"watchFile")
    list = context.exports.watchList || [];
#    console.log(JSON.stringify context,((k,v)->
#        if v?.constructor?.name isnt "RegExp"
#            return v
#        return "RegExp(/#{v.source}/)"
#    ),4);
catch e
    console.error "invalid watchfile '%s'",watchFile
    process.exit(1);

rules = []
queue = new Queue
for config in list
    rules.push new Rule config
if program.startCompile
    files = wrench.readdirSyncRecursive "./"
    for path in files
        for rule in rules
            if rule.test path
                task = rule.taskFromPath path
                console.log "create #{task.toString()} by #{path}: inital compile"
                queue.add task
watcher = new Watcher(".")
watcher.on "change",(path)->
    for rule in rules
        if rule.test path
            task = rule.taskFromPath path
            console.log "create #{task.toString()} by #{path}: modification"
            queue.add task
console.log "start watching"
