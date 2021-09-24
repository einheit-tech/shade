import
  node,
  pixie

type
  ZChangeListener = proc(oldZ, newZ: float): void
  ## Layer is a container of nodes that exist on a two-dimensional plane,
  ## perpendicular to the camera which views the game.
  ## They update and render any nodes they hold.
  ##
  ## Layers have a `z` axis coordinate.
  ## All nodes on the layer are assumed to share this same coordinate.
  ##
  Layer* = ref object of RootObj
    nodes*: seq[Node]
    # Location of the layer on the `z` axis.
    z: float
    zChangeListeners: seq[ZChangeListener]

proc newLayer*(z: float = 1.0): Layer = Layer(z: z)

template nodeCount*(this: Layer): int = this.nodes.len

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
  ## Use this returned entity if you need to remove the listener early.
  let onceListener =
    proc(oldZ, newZ: float) =
      listener(oldZ, newZ)
      this.removeZChangeListener(listener)

  this.zChangeListeners.add(onceListener)
  return onceListener

iterator items*(this: Layer): Node =
  for e in this.nodes:
    yield e

iterator pairs*(this: Layer): (int, Node) =
  for i, e in this.nodes:
    yield (i, e)

template add*(this: Layer, obj: Node) =
  this.nodes.add(obj)

template remove*(this: Layer, i: Natural) =
  ## Removes the entity at the given index, maintaining entity order.
  this.nodes.delete(i)

template remove*(this: Layer, obj: Node) =
  ## Removes the entity, maintaining entity order.
  for i, o in this:
    if o == obj:
      this.remove(i)
      break

method update*(this: Layer, deltaTime: float) {.base.} =
  for e in this:
    if loUpdate in e.flags:
      e.update(deltaTime)

method render*(this: Layer, ctx: Context, callback: proc() = nil) {.base.} =
  for e in this:
    if loRender in e.flags:
      e.render(ctx)

  if callback != nil:
    callback()

