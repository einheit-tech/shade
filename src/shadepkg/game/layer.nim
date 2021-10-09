import node

export node

type
  ZChangeListener = proc(oldZ, newZ: float): void
  ## Layer is a container of nodes that exist on a two-dimensional plane,
  ## perpendicular to the camera which views the game.
  ## They update and render any nodes they hold.
  ##
  ## Layers have a `z` axis coordinate.
  ## All nodes on the layer are assumed to share this same coordinate.
  ##
  Layer* = ref object of Node
    # Location of the layer on the `z` axis.
    z: float
    zChangeListeners: seq[ZChangeListener]

proc initLayer*(layer: Layer, z: float = 1.0) =
  initNode(layer, {loUpdate, loRender})
  layer.z = z

proc newLayer*(z: float = 1.0): Layer =
  result = Layer()
  initLayer(result, z)

template z*(this: Layer): float = this.z

proc `z=`*(this: Layer, z: float) =
  if this.z != z:
    let oldZ = this.z
    this.z = z
    for listener in this.zChangeListeners:
      listener(oldZ, this.z)

proc addZChangeListener*(this: Layer, listener: ZChangeListener) =
  this.zChangeListeners.add(listener)

proc removeZChangeListener*(this: Layer, listener: ZChangeListener) =
  for i, l in this.zChangeListeners:
    if l == listener:
      this.zChangeListeners.del(i)
      break

proc addZChangeListenerOnce*(this: Layer, listener: ZChangeListener): ZChangeListener =
  ## Add a listener that is removed automatically after one invocation.
  ## Returns the listener that was directly added to the Layer.
  ## Use this returned node if you need to remove the listener early.
  let onceListener =
    proc(oldZ, newZ: float) =
      listener(oldZ, newZ)
      this.removeZChangeListener(listener)

  this.zChangeListeners.add(onceListener)
  return onceListener

