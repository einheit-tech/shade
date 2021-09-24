import
  std/[
    macros,
    strutils,
    sequtils
  ]

proc addBases(bases: var seq[string], t: NimNode) =
  proc cleanIdent(n: NimNode): string = 
    ($n.repr).multiReplace:
      [("(", ""),
       (")", ""),
       ("{", ""),
       ("}", ""),
       ("[", ""),
       (")", ""),
       (":", ""),
       (" ", ""),
       (",", ""),
       (";", "")]
  let (left, _, right) = t.unpackInfix

  if left.kind != nnkInfix:
    bases.add left.cleanIdent
  else:
    bases.addBases(left)

  if right.kind != nnkInfix:
    bases.add right.cleanIdent
  else:
    bases.addBases(right)

macro makeEnum*(t: typedesc, enumName: untyped, prefix: static string, exported = true): untyped = 
  let impl = t.getImpl
  var bases: seq[string]
  bases.addBases(impl[^1])
  if prefix.len > 0:
    for x in bases.mitems:
      x[0] = x[0].toUpperAscii
      x = prefix & x
  var nodes = bases.map(proc(n: string): NimNode = ident(n))
  newEnum(enumName, nodes, exported.boolVal, false)

