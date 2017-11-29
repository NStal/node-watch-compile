EventEmitter = (require "events").EventEmitter
chokidar = require('chokidar')
class Watcher extends EventEmitter
    constructor:(@watchRoots)->
        if typeof @watchRoots is "string"
            @watchRoots = [@watchRoots]
        @init()
    init:()->
        @watcher = chokidar.watch @watchRoots,{
          persistent: true
          usePolling: true
          interval: 100
          ignoreInitial: true
        }
        @watcher.on "add",(path)=>
            @emit "change",path
        @watcher.on "change",(path)=>
            @emit "change",path

module.exports = Watcher
