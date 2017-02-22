Errors = require "./errors"
child_process = require "child_process"
pathModule = require "path"
class Task
    constructor:(@path,@rawCommand,@option = {})->

        @extname =pathModule.extname(@path)
        @filename = pathModule.basename(@path,@extname);
        @basename = @filename + @extname
        @directory = pathModule.dirname(@path)+"/";
        @command = @rawCommand.replace(/\{filename\}/g,@filename)
            .replace(/\{fullpath\}/g,@path)
            .replace(/\{directory\}/g,@directory)
            .replace(/\{basename\}/g,@basename)
            .replace(/\{extname\}/g,@extname);
        return
    equal:(task)->
        return @command is task.command
    exec:(callback = ()->)->
        if @isDone
            callback new Errors.AlreadyDone()
            return

        if @isExecuting
            callback new Errors.AlreadyExcuting()
            return
        @cp = child_process.exec @command

        @cp.stdout.pipe process.stdout
        @cp.stderr.pipe process.stderr
        @cp.once "error",(err)=>
            callback new Errors.TaskFailed "task #{@toString()} failed with error #{err}",{via:err}
        @cp.once "exit",(code)=>
            @isDone = true
            if code isnt 0
                callback new Errors.TaskFailed("task #{@toString()} failed with code #{code}")
                return
            callback()
    toString:()->
        return "[Task:#{@path} -> #{@command}]"
module.exports = Task
