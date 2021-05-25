import entity

type
  ZChangeListener = proc(oldZ, newZ: float): void
  ## Layer is a container of entities that exist on a two-dimensional plane,
  ## perpendicular to the camera which views the game.
  ## Entityhey update and render any objects they hold.
  ##
  ## Layers have a `z` axis coordinate.
  ## All objects on the layer are assumed to share this same coordinate.
  ##
  Layer* = ref object of RootObj
    objects: seq[Entity]
    # Location of the layer on the `z` axis.
    z: float
    zChangeListeners: seq[ZChangeListener]

proc newLayer*(z: float = 1.0): Layer = Layer(z: z)

template objectCount*(this: Layer): int = this.objects.len

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
  ## Use this returned object if you need to remove the listener early.
  let onceListener =
    proc(oldZ, newZ: float) =
      listener(oldZ, newZ)
      this.removeZChangeListener(listener)

  this.zChangeListeners.add(onceListener)
  return onceListener

iterator items*(this: Layer): Entity =
  for e in this.objects:
    yield e

iterator pairs*(this: Layer): (int, Entity) =
  for i, e in this.objects:
    yield (i, e)

template add*(this: Layer, obj: Entity) =
  this.objects.add(obj)

template remove*(this: Layer, i: Natural) =
  ## Removes the object at the given index, maintaining object order.
  this.objects.delete(i)

template remove*(this: Layer, obj: Entity) =
  ## Removes the object, maintaining object order.
  for i, o in this:
    if o == obj:
      this.remove(i)
      break

method update*(this: Layer, deltaTime: float) {.base.} =
  for e in this:
    if e.flags.includes(loUpdate):
      e.update(deltaTime)

method render*(this: Layer) {.base.} =
  for e in this:
    if e.flags.includes(loRender):
      e.render()

