Task = require "./task"
class Rule
    constructor:(@config,option = {})->
        @type = option.type or "create"
        @reg = @config[0]
        @command = @config[1]
    test:(path)->
        if typeof @reg.test is "function"
            return @reg.test path
        else if typeof @reg is "function"
            return @reg(path)
        return false
    taskFromPath:(path)->
        return new Task(path,@command)
module.exports = Rule
