Task = require "./task"
class Rule
    constructor:(@config,option = {})->
        @type = option.type or "create"
        @reg = @config[0]
        @command = @config[1]
    test:(path)->
        if @reg.test
            return @reg.test path
        else if typeof @reg is "function"
            return @reg(path)
    taskFromPath:(path)->
        return new Task(path,@command)
module.exports = Rule
