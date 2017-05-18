fs = require "fs"
crypto = require("crypto")
module.exports = class ChangeMap
    constructor:()->
        this.map = {}
    checkAndUpdate:(path)->
        hash = crypto.createHash("md5")
        try
            hash.update fs.readFileSync(path)
        catch e
            return false
        hashString = hash.digest("hex")
        if this.map[path] is hashString
            return false
        this.map[path] =  hashString
        return true
