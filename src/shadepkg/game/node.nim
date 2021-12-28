import
  hashes,
  sequtils,
  deques,
  locks

import
  gamestate,
  constants,
  ../render/render,
  ../render/shader,
  ../math/mathutils

export 
  hashes,
  sequtils,
  render,
  mathutils

type 
  ## Flags indicating how the object should be treated by a layer.
  LayerObjectFlags* = enum
    loUpdate
    loRender

  Node* = ref object of RootObj
    # Invoked after this node and its children have been updated.
    onUpdate*: proc(this: Node, deltaTime: float)
    # Called when this node has rendered (before children).
    # This can be used to draw within its localized rendering space.
    onRender*: proc(this: Node, ctx: Target)
    # Called when this node has rendered, including children.
    # This can be used to draw within its localized rendering space.
    afterRender*: proc(this: Node, ctx: Target)

    shader: Shader
    children: seq[Node]
    flags*: set[LayerObjectFlags]

    childLock: Lock
    additionQueue: Deque[Node]
    removeQueue: Deque[Node]

    scale: Vector
    center: Vector
    # Rotation in degrees (clockwise).
    rotation: float

method onCenterChanged*(this: Node) {.base.}
method center*(this: Node): Vector {.base.}
method `center=`*(this: Node, center: Vector) {.base.}
method `x=`*(this: Node, x: float) {.base.}
method `y=`*(this: Node, y: float) {.base.}
method shader*(this: Node): Shader {.base.}
method `shader=`*(this: Node, shader: Shader) {.base.}
method scale*(this: Node): Vector {.base.}
method `scale=`*(this: Node, scale: Vector) {.base.}
method onParentScaled*(this: Node, parentScale: Vector) {.base.}
method `rotation=`*(this: Node, rotation: float) {.base.}
method onChildAdded*(this: Node, child: Node) {.base.}
method onChildRemoved*(this: Node, child: Node) {.base.}
method hash*(this: Node): Hash {.base.}
method update*(this: Node, deltaTime: float) {.base.}
method renderChildren*(this: Node, ctx: Target) {.base.}
method render*(this: Node, ctx: Target, callback: proc() = nil) {.base.}

proc initNode*(node: Node, flags: set[LayerObjectFlags], centerX, centerY: float = 0.0) =
  node.flags = flags
  node.scale = VECTOR_ONE
  node.center = vector(centerX, centerY)
  initLock(node.childLock)

proc newNode*(flags: set[LayerObjectFlags]): Node =
  result = Node()
  initNode(result, flags)

method onCenterChanged*(this: Node) {.base.} =
  ## Fired whenever the location of the node changes.
  discard

method center*(this: Node): Vector {.base.} =
  return this.center

method `center=`*(this: Node, center: Vector) {.base.} =
  this.center = center
  this.onCenterChanged()

proc x*(this: Node): float =
  return this.center.x

method `x=`*(this: Node, x: float) {.base.} =
  `center=`(this, vector(x, this.center.y))
  this.onCenterChanged()

proc y*(this: Node): float =
  return this.center.y

method `y=`*(this: Node, y: float) {.base.} =
  `center=`(this, vector(this.center.x, y))
  this.onCenterChanged()

method shader*(this: Node): Shader {.base.} =
  return this.shader

method `shader=`*(this: Node, shader: Shader) {.base.} =
  this.shader = shader

method scale*(this: Node): Vector {.base.} =
  return this.scale

method `scale=`*(this: Node, scale: Vector) {.base.} =
  ## Sets the scale of the node.
  this.scale = scale
  for child in this.children:
    child.onParentScaled(scale)

method onParentScaled*(this: Node, parentScale: Vector) {.base.} =
  ## Called when the parent node has been scaled.
  ## `parentScale` is the multiplicative scale of all parents above this node.
  let scale =
    if this.scale == VECTOR_ONE:
      parentScale
    else:
      parentScale * this.scale
  
  # The whole tree needs to be notified of scaling.
  for child in this.children:
    child.onParentScaled(scale)

template `rotation`*(this: Node): float =
  this.rotation

method `rotation=`*(this: Node, rotation: float) {.base.} =
  ## Sets the rotation of the node.
  this.rotation = rotation

proc children*(this: Node): lent seq[Node] =
  return this.children

method onChildAdded*(this: Node, child: Node) {.base.} =
  ## Invoked when a child has been added to this node.
  discard

proc addChildNow(this, child: Node) =
  ## Adds the child IMMEDIATELY.
  this.children.add(child)
  this.onChildAdded(child)

method addChild*(this: Node, child: Node) {.base.} =
  ## Adds the child to this Node.
  ## If the children are being iterated over at the time of this call,
  ## the child will be added at the start of the next update.
  if tryAcquire(this.childLock):
    this.addChildNow(child)
    this.childLock.release()
  else:
    this.additionQueue.addFirst(child)

method onChildRemoved*(this: Node, child: Node) {.base.} =
  ## Invoked when a child has been removed from this node.
  discard

proc removeChildNow(this, child: Node) =
  ## Removes the child IMMEDIATELY.
  ## This is an "unsafe" operation.
  var index: int = -1
  for i, n in this.children:
    if n == child:
      index = i
      break
  
  if index >= 0:
    this.children.delete(index)
    this.onChildRemoved(child)

method removeChild*(this, child: Node) {.base.} =
  ## Removes the child from this Node.
  ## If the children are being iterated over at the time of this call,
  ## the child will be removed at the start of the next update.
  if tryAcquire(this.childLock):
    this.removeChildNow(child)
    this.childLock.release()
  else:
    this.removeQueue.addFirst(child)

method removeAllChildren*(this: Node) {.base.} =
  ## Removes all children from the node.
  withLock(this.childLock):
    for child in this.children:
      this.removeQueue.addFirst(child)

method hash*(this: Node): Hash {.base.} =
  return hash(this[].unsafeAddr)

method update*(this: Node, deltaTime: float) {.base.} =
  withLock(this.childLock):
    while this.additionQueue.len > 0:
      let child = this.additionQueue.popFirst()
      this.addChildNow(child)

  withLock(this.childLock):
    while this.removeQueue.len > 0:
      let child = this.removeQueue.popFirst()
      this.removeChildNow(child)

  withLock(this.childLock):
    for child in this.children:
      if loUpdate in child.flags:
        child.update(deltaTime)

  if this.onUpdate != nil:
    this.onUpdate(this, deltaTime)

method renderChildren*(this: Node, ctx: Target) {.base.} =
  withLock(this.childLock):
   for child in this.children:
      if loRender in child.flags:
        child.render(ctx)

method render*(this: Node, ctx: Target, callback: proc() = nil) {.base.} =
  ## Renders the node with its given position, rotation, and scale.
  ## It will render its children relative to its center.
  if this.center != VECTOR_ZERO:
    translate(this.center.x * meterToPixelScalar, this.center.y * meterToPixelScalar, 0)

  if this.rotation != 0:
    rotate(this.rotation, 0, 0, 1)

  if this.scale != VECTOR_ONE:
    scale(this.scale.x, this.scale.y, 1.0)

  if this.shader != nil:
    this.shader.render(time, resolutionPixels)

  if callback != nil:
    callback()

  if this.onRender != nil:
    this.onRender(this, ctx)

  this.renderChildren(ctx)

  if this.afterRender != nil:
    this.afterRender(this, ctx)

  if this.shader != nil:
    activateShaderProgram(0, nil)

  if this.scale != VECTOR_ONE:
    scale(1 / this.scale.x, 1 / this.scale.y, 1.0)

  if this.rotation != 0:
    rotate(this.rotation, 0, 0, -1)

  if this.center != VECTOR_ZERO:
    translate(-this.center.x * meterToPixelScalar, -this.center.y * meterToPixelScalar, 0)

