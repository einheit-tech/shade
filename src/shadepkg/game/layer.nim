import node, safeseq

export node, safeseq

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
    children: SafeSeq[Node]
    # Location of the layer on the `z` axis.
    z: float
    zChangeListeners: seq[ZChangeListener]
    onUpdate*: proc(this: Layer, deltaTime: float)

proc initLayer*(layer: Layer, z: float = 1.0) =
  layer.z = z
  layer.children = newSafeSeq[Node]()

proc newLayer*(z: float = 1.0): Layer =
  result = Layer()
  initLayer(result, z)

template z*(this: Layer): float =
  this.z

proc `z=`*(this: Layer, z: float) =
  if this.z != z:
    let oldZ = this.z
    this.z = z
    for listener in this.zChangeListeners:
      listener(oldZ, this.z)

iterator childIterator*(this: Layer): Node =
  for child in this.children:
    yield child

method addChild*(this: Layer, child: Node) {.base.} =
  ## Adds the child to this Node.
  this.children.add(child)

method removeChild*(this: Layer, child: Node) {.base.} =
  ## Removes the child from this Node.
  this.children.remove(child)

method visitChildren*(this: Layer, handler: proc(child: Node)) {.base.} =
  for child in this.children:
    handler(child)

template forEachChild*(this: Layer, body: untyped) =
  this.visitChildren(
    proc(child {.inject.}: Node) =
      body
  )

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

method update*(this: Layer, deltaTime: float) {.base.} =
  if this.onUpdate != nil:
    this.onUpdate(this, deltaTime)

  for child in this.childIterator:
    if LayerObjectFlags.UPDATE in child.flags:
      child.update(deltaTime)

Layer.renderAsParent:
  this.forEachChild:
    if LayerObjectFlags.RENDER in child.flags:
      child.render(ctx, offsetX, offsetY)

