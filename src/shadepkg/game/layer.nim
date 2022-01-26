import
  node,
  locks,
  deques

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
  Layer* = ref object of RootObj
    onUpdate*: proc(this: Layer, deltaTime: float)
    # Location of the layer on the `z` axis.
    z: float
    zChangeListeners: seq[ZChangeListener]

    children: seq[Node]
    childLock: Lock
    childrenToAdd: Deque[Node]
    childrenToRemove: Deque[Node]

proc initLayer*(layer: Layer, z: float = 1.0) =
  initLock(layer.childLock)
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

iterator childIterator*(this: Layer): Node =
  for child in this.children:
    yield child

method addChildNow*(this: Layer, child: Node) {.base.} =
  ## Adds the child IMMEDIATELY.
  ## This is unsafe; use addChild unless you know what you're doing.
  this.children.add(child)

proc addChild*(this: Layer, child: Node) =
  ## Adds the child to this Node.
  ## If the children are being iterated over at the time of this call,
  ## the child will be added at the start of the next update.
  if tryAcquire(this.childLock):
    this.addChildNow(child)
    this.childLock.release()
  else:
    this.childrenToAdd.addLast(child)

method removeChildNow*(this: Layer, child: Node) {.base.} =
  ## Removes the child IMMEDIATELY.
  ## This is unsafe; use removeChild unless you know what you're doing.
  var index = -1
  for i, n in this.children:
    if n == child:
      index = i
      break
  
  if index >= 0:
    this.children.delete(index)

proc removeChild*(this: Layer, child: Node) =
  ## Removes the child from this Node.
  ## If the children are being iterated over at the time of this call,
  ## the child will be removed at the start of the next update.
  if tryAcquire(this.childLock):
    this.removeChildNow(child)
    this.childLock.release()
  else:
    this.childrenToRemove.addLast(child)

proc removeAllChildren*(this: Layer) =
  ## Removes all children from the node.
  if tryAcquire(this.childLock):
    this.children.setLen(0)
    this.childLock.release()
  else:
    for child in this.children:
      this.childrenToRemove.addLast(child)

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

method update*(this: Layer, deltaTime: float, onChildUpdate: proc(child: Node) = nil) {.base.} =
  if this.onUpdate != nil:
    this.onUpdate(this, deltaTime)

  withLock(this.childLock):
    while this.childrenToRemove.len > 0:
      let child = this.childrenToRemove.popFirst()
      this.removeChildNow(child)

    while this.childrenToAdd.len > 0:
      let child = this.childrenToAdd.popFirst()
      this.addChildNow(child)

    for child in this.children:
      if loUpdate in child.flags:
        child.update(deltaTime)
        if onChildUpdate != nil:
          onChildUpdate(child)

Layer.renderAsParent:
  for child in this.children:
    if loRender in child.flags:
      child.render(ctx)

  if callback != nil:
    callback()

