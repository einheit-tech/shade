import
  std/[
    macros,
    macrocache,
    genasts,
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

macro unionType*(vals: typed): untyped =
  # TODO: Ideally sort the vals
  const myTable = CacheTable "checkedValTypes"
  let
    name = genSym(nskType, "CheckedType")
    cacheName = vals.repr
  for key, val in myTable.pairs:
    if key.eqIdent cacheName:
      return val
  
  myTable[vals.repr] = name
  result = genast(vals, name, typeOfColl = vals[0].getTypeInst):
    type name[T: static openarray[typeOfColl]] = distinct typeOfColl
    name[vals]

template makeUnionConverter*(Subtype: typedesc, Type: typedesc) =
  converter toFixed(t: Type): Subtype =
    assert t in Subtype.T
    Subtype t

  # TODO: This is probably incorrect, hit up Elegantbeef about it.
  converter toFixed(s: Subtype): Type =
    Type s

# Example:
#
# type
#   Direction = enum
#     LEFT
#     UP
#     RIGHT
#     DOWN

# type Horizontal = unionType([LEFT, RIGHT])
# Horizontal.makeUnionConverter(Direction)

# let dir: Horizontal = LEFT
# echo repr dir

