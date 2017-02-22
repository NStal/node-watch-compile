fs = require("fs");
vm = require("vm");
Watcher = require "./watcher"
child_process = require "child_process"
wrench = require "wrench"
Queue = require "./queue"
DateString = require "./dateString"
Rule = require "./rule"
commander = require("commander");
program = commander
    .option("-f,--file <filename>","specifail the watchfile default is Watchfile")
    .option("-c,--create-default","create and default rules save as ./Watchfile")
    .option("-v,--version","print version")
    .option("-s,--start-compile","compile all matched file at start")
    .option("-q,--quit","combined with -s, quit program after start compile")
    .version("0.0.5")
    .parse(process.argv);

defaultWatchFile = """//{basename} /css/style.less => style.less
//{fullpath} /css/style.less => /css/style.less (unchanged)
//{filename} /css/style.less => style
//{extname}  /css/style.less => .less
//{directory} /css/style.less => /css/
exports.watchList = [
    // [testFunction,commandToRun]
    // [RegExp|(path:string)=>boolean,string]
    [/^.*\.coffee$/,'coffee -c {fullpath}'],
    [/^.*\.less$/,'lessc {fullpath} > {directory}{filename}.css'],
];

exports.serviceList = [
    //commandToRunOnceAtStart
    "echo WatchCompileStart",
    "echo 'start tsc watch' && tsc -p ./ --watch"
]
"""
if program.createDefault
    console.log "create default Watchfile at ./Watchfile"
    if fs.existsSync "./Watchfile"
        console.error "./Watchfile exists, don't overwrite it."
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
    list = context.exports.watchList || []
    serviceList = context.exports.serviceList || []
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
for service in serviceList
    do (service)->
        cp = child_process.exec(service)
        cp.stdout.pipe(process.stdout)
        cp.stderr.pipe(process.stderr)
for config in list
    rules.push new Rule config
if program.startCompile
    files = wrench.readdirSyncRecursive "./"
    for path in files
        for rule in rules
            if rule.test path
                task = rule.taskFromPath path
                console.log "#{DateString.genReadableDateString()} create #{task.toString()} by #{path}: inital compile"
                queue.add task
watcher = new Watcher(".")
watcher.on "change",(path)->
    for rule in rules
        if rule.test path
            task = rule.taskFromPath path
            console.log "#{DateString.genReadableDateString()} create #{task.toString()} by #{path}: modification"
            queue.add task
queue.on "empty",()->
    if program.startCompile and program.quit
        console.log "start compile done and quit by -q"
        process.exit(0)
if not program.quit
    console.log "start watching"
