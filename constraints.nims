# mmm... totally overkill!
import pegs
import strutils
import tables


type
  constraint = tuple[op: string, version: string]


var
  constraints = initTable[string, seq[constraint]]()


proc constrain(constraint: string) =
  if constraint =~ peg"""rule <- {name} ws constraints
                   name <- [a-zA-Z_0-9-]+
                   ws <- \s+
                   constraints <- constraint (ws constraint)*
                   constraint <- {op} ws {version}
                   op <- '<=' / '>=' / '!=' / '==' / '<' / '>'
                   version <- [0-9\.]+
                   """:
    var
      c: seq[constraint]
      i = 1
    while matches[i] != "":
      c.add((matches[i], matches[i + 1]))
      i += 2
    constraints[matches[0]] = c
  else:
    echo "Syntax error: " & constraint
    quit(QuitFailure)


constrain "mqtt-blinky < 1.2.0"
constrain "blinky-lib < 1.2.0"

for line in readAllFromStdin().split():
  let dir = line.strip(chars = {'/'})
  if dir in constraints:
    var result = true
    for constraint in constraints[dir]:
      case constraint.op
      of "<=": result = result and NimVersion <= constraint.version
      of ">=": result = result and NimVersion >= constraint.version
      of "!=": result = result and NimVersion != constraint.version
      of "==": result = result and NimVersion == constraint.version
      of "<": result = result and NimVersion < constraint.version
      of ">": result = result and NimVersion > constraint.version
      else:
        echo("Should not get here...")
        quit(QuitFailure)
    if not result:
      continue
  echo(line)
