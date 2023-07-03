import ../math/vector2

type ResolutionCallback = proc()

var
  runTime*: float
  # NOTE: Do not update the resolution directly; use updateResolution
  resolution*: Vector
  resolutionCallbacks: seq[ResolutionCallback]

template onResolutionChanged*(body: untyped) =
  resolutionCallbacks.add(proc = body)

template notifyResolutionCallbacks =
  for callback in resolutionCallbacks:
    callback()

proc updateResolution*(x, y: float) =
  resolution.x = x
  resolution.y = y
  notifyResolutionCallbacks()

