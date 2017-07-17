path = require 'path'
module.exports =
    formatFrame: ({level, addr, func, file, line}, detailed) ->
        if not level? then level = 0
        if file? and not detailed
            addr = ''
        fmt = "##{level} #{addr} in #{func}()"
        if file?
            fmt += " at "
            fmt += if detailed then file else path.basename(file)
            fmt += ":#{line}"
        return fmt

    cidentFromLine: (line, pos) ->
        cident = /^[A-Za-z0-9_\.]+/
        while (match = line.slice(pos).match cident) and pos >= 0
            ret = match[0]
            pos--
        ret

    escapeHTML: (text) ->
        text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
