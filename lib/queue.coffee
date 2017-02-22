DateString = require "./dateString"
States = require "logicoma"
class Queue extends States
    constructor:(@verbose = false)->
        super()
        @tasks = []
        @setState "waiting"
    reset:()->
        super()
    add:(task)->
        for item in @tasks
            if item.equal task
                if this.verbose
                    console.log "Merging task #{task.toString()}"
                return false
        @tasks.push task
        if @isWaitingFor "startSignal"
            @give "startSignal"
    pause:()->
        @data.shouldPause = true
    atWaiting:()->
        @data.currentTask = null
        @waitFor "startSignal",()=>
            @setState "working"
    atWorking:(sole)->
        if @data.shouldPause
            @setState "waiting"
            return
        task = @tasks.shift()
        if not task
            @emit "empty"
            @data.currentTask = null
            @setState "waiting"
            return
        @data.currentTask = task
        start = Date.now()
        task.exec (err)=>
            if err
                console.error err
            if @stale sole
                return
            end = Date.now()
            console.log DateString.genReadableDateString(),task.toString(),"done (#{(end - start + "ms")})"
            @setState "working"
module.exports = Queue
