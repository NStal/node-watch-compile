node-watch-compile
==================
# Note
Only tested under linux.Nodejs's fs.watch is used to watch file changes,but these API is not gareteed in all platform.The availability can be found at http://nodejs.org/api/fs.html#fs_availability

An watch-compile tool for nodejs.Useful for webdev real-time compilation for less/coffee or what ever.
# Install
```bash
sudo npm install -g watch-compile
```

# Usage
```bash
# watchcompile or nwc
# create a template Watchfile
watchcompile -c
# Run it
watchcompile -s
# Or run with custom Watchfile
# watchcompile -f /path/to/Watchfile.server
```

`-f` is used to specify the Watchfile which contained watch rules. default is "./Watchfile"
`-s` make watchcompile run initial compilation for all matched files.

When changes occured between minimum interval, the compile process will not be aborted, and the latest change will get compiled. In order to prevent unwanted result the -i should be less than default settings.

When change happend after minimum compile interval, an recompile will be triggered immediately. In case the previous compilation of the same file and same command is still running, that previous compilation task will be stopped immediately.


#Watchfile
```bash
#create an default Watchfile at ./
watchcompile -c
```
A default Watchfile is like below
```javascript
//{basename} /css/style.less => style.less
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
```
Watchfile's working directory is always based on `pwd` of your shell.

Watchfile is considered as an standard node module and latter running by require("vm").runInContext.

Consider the folder structure
```
/Watchfile  #this one is the example
/index.html
/js/code.coffee
/css/style.less
```

When running watchcompile at /

```
/js/code.coffee is matched by [/^.*coffee$/,"coffee -c {fullpath}"]
/css/style.less is matched by [/^.*less$/,"lessc {fullpath} > {directory}{basename}.css"]
]
```

Note that the `RegExp` can also be replaced by a `function` with signature `(path:string)=>boolean`. 

When /css/style.less changed."lessc /css/style.less > /css/style.css" is excuted.

Supported macros are :

```
{basename} /css/style.less => style.less
{fullpath} /css/style.less => /css/style.less (unchanged)
{filename} /css/style.less => style
{extname}  /css/style.less => .less
{directory} /css/style.less => /css/
```

Since Watchfile is considered and excuted as node module. So you can do what ever you can with javascript to generate any `exports.watchList` you want.

### ServiceList

Some compilation has it's own watch system and some of them, such as `typescript`, may have incremental compilation which lead to a huge performance boost than normal compilation. So we provide a `exports.serviceList` to run it at start of watchcompile. Also you can run any other command as you wish as a service. It is actually just a command run at start of the watchcompile as a child process.

### Notification

Watchcompile it self don't provide notification, but you may write it yourself using command like:

```js
exports.watchList = [
    ["/*\.ts/","tsc -p ./ && notify-send '{fullpath} compile success' || notify-send 'something is wrong with {fullpath}'"]
]
```

`notify-send` is a desktop notification service provide by most desktop environment of Linux. OSX user may use applescript instead.
