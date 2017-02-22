exports.genReadableDateString = (date = new Date)->
    parts = [date.getHours(),date.getMinutes(),date.getSeconds()]
    return parts.map((item)->item.toString().length < 2 && "0"+item.toString() || item.toString()).join(":")
