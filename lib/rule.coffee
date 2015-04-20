Task = require "./task"
class Rule
    constructor:(@config,option = {})->
        @type = option.type or "create"
        @reg = @config[0]
        @command = @config[1]
    test:(path)->
        return @reg.test path
    taskFromPath:(path)->
        return new Task(path,@command)
module.exports = Rule
