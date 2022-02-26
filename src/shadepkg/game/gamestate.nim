import ../math/mathutils

type ResolutionCallback = proc()

var
  time*: float
  screenResolution: Vector
  resolutionCallbacks: seq[ResolutionCallback]

template resolutionX*: float =
  screenResolution.x

template resolutionY*: float =
  screenResolution.y

template addResolutionChangedCallback*(callback: ResolutionCallback) =
  resolutionCallbacks.add(callback)

template notifyResolutionCallbacks =
  for callback in resolutionCallbacks:
    callback()

template `resolution=`*(size: Vector) =
  screenResolution = size
  notifyResolutionCallbacks()

template `resolution.x=`*(x: float) =
  screenResolution.x = x
  notifyResolutionCallbacks()

template `resolution.y=`*(y: float) =
  screenResolution.y = y
  notifyResolutionCallbacks()

