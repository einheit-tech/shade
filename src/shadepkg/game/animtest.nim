import 
  std/[macros, macrocache],
  math

type
  Frameable* = concept f, type F
    lerp(f, f, 1.0) is F
  KeyFrame*[T: Frameable] = object
    val: T
    time: float

proc lerp*(start, `end`: SomeFloat, completionRatio: float): SomeFloat =
  return start + (`end` - start) * completionRatio

proc lerp*(start, `end`: SomeInteger, completionRatio: float): SomeInteger =
  return int round(start.float + (`end` - start).float * completionRatio)

proc sample*[T](frames: openArray[KeyFrame[T]], time: float): T =
  for i in 0..<frames.high:
    if time >= frames[i].time and time <= frames[i + 1].time:
      let lerpVal = (time - frames[i].time) / (frames[i + 1].time - frames[i].time)
      result = lerp(frames[i].val, frames[i + 1].val, lerpVal)

proc toData*[T](t: openArray[tuple[value: T, time: float]]): seq[KeyFrame[T]] =
  for x in t:
    result.add KeyFrame[T](val: x[0], time: x[1])

const animProcs = CacheSeq "AnimProcs"

proc getObj(dotExpr: NimNode): NimNode =
  result = dotExpr
  while result.kind == nnkDotExpr:
    result = result[0]

macro makeAnim*(field: typed, data: openArray[tuple[value: typed, time: float]]): untyped =
  if field.kind != nnkDotExpr:
    error("This only works for fields of objects", field)

  let
    procName = gensym(nskProc, "update" & $field.repr)
    obj = getObj(field)

  block addProc:
    for x in animProcs:
      if x[0] == obj:
        x.add procName
        break addProc
    animProcs.add newStmtList(obj, procName)

  result = quote do:
    proc `procName`(t: float) =
      const data = toData(`data`)
      `field` = sample(data, t)

macro animate*(obj: typed, time: float): untyped =
  if obj.kind != nnkSym:
    error("'obj' must be a variable.", obj)
  result = newStmtList()
  for x in animProcs:
    if x[0] == obj:
      for i, y in x:
        if i > 0:
          result.add newCall(y, time)
  if result.len == 0:
    error("No animators subscribed for this object", obj)

type Foo = object
  rot: float
  posX: float
  frame: int

var obj = Foo()
makeAnim obj.rot, [(0.0, 0.0), (0.5, 30.0), (1.0, 50.0)]
makeAnim obj.posX, [(0.0, 0.0), (0.3, 1.0), (1.0, 100.0)]
makeAnim obj.frame, [(0, 0.0), (3, 1.0), (5, 100.0)]
animate(obj, 0.5)

# echo obj
