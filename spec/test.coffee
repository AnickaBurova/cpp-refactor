
print = (x...) ->
  console.log x.reduce (a,b) ->
    a + if b? then ", " + b else ""

id = "daemon"

reg = ///
  (?:
  (class|struct)\s+                       #class or struct
  (\w+\s*(?:\([\w\(\),\-\+\*\/]*\))*\s+)*  #any definition like some macro befor class name
  (#{id})(?:\s*:|\s*\n*)
  )
///

text = "class daemon"


m = reg.exec(text)

print m
