States = require "logicoma"
class Queue extends States
    constructor:()->
        super()
        @tasks = []
        @setState "waiting"
    reset:()->
        super()
    add:(task)->
        for item in @tasks
            if item.equal task
                return false
#        if @currentTask?.equal?(item)
#            return false
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
            console.log task.toString(),"done (#{(end - start + "ms")})"
            @setState "working"
module.exports = Queue
