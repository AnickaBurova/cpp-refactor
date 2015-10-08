fs = require('fs')

print = (x...) ->
  console.log x.reduce (a,b) ->
    a + if b? then ", " + b else ""

ident_to_find = "daemon"

reg = ///
  (?:
  (class|struct)\s+                       #class or struct
  (\w+\s*(?:\([\w\(\),\-\+\*\/]*\))*\s+)*  #any definition like some macro befor class name
  (#{ident_to_find})\s*(?::|\n|$)
  )
///


for_each_line = (filepath, func) ->
  lineindex = 0
  for line in fs.readFileSync(filepath).toString().split '\n'
    func line, lineindex++


for_each_line "/Users/milanburansky/Code/bb/portal-daemon/lib/daemon/daemon.h", (line,linei) ->
  if m = reg.exec(line)
    print linei,line
