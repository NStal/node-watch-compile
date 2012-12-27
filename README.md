node-watch-compile
==================

An watch-compile tool for nodejs.Useful for webdev real-time compilation for less/coffee or what ever.
# Install
```bash
sudo npm install -g watch-compile
```

# Usage
```bash
watchcompile -f Watchfile -i 300
```
-f is used to specify the Watchfile which contained watch rules. default is "./Watchfile"
-i special the minum recompile interval.Default is 500ms.

When change between minum interval,the compile process will not be abort,and the latest change will not compiled.In order to prevent unwanted result the -i should be less than default settings.

When change happend after minum compile interval,then an recompile will triggered,by your rules defined in Watchfile(latter example).But when the last change-compile is still running,That one will be aborted.

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
    [/^.*coffee$/,"coffee -c {fullpath}"]	
    ,[/^.*less$/,"lessc {fullpath} > {directory}{basename}.css"]
]
```
Watchfile is considered as an standard node module and latter running by require("vm").runInContext.
exports.watchList MUST be an Array of 2 dimension.Each of the elements contain [RegExp for matched file,cmdline for what to do when compile]

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
So when /js/code.coffee changed."coffee -c /js/code.coffee" is excuted.

When /css/style.less changed."lessc /css/style.less > /css/style.css" is excuted.

Supported place holder are :
```
{basename} /css/style.less => style.less
{fullpath} /css/style.less => /css/style.less (unchanged)
{filename} /css/style.less => style
{extname}  /css/style.less => .less
{directory} /css/style.less => /css/
```
# Note
Since Watchfile is considered and excuted as node module.So you can do what ever you want in side to generate any exports.watchList you want in your own logic.
