import
  hashes,
  sequtils,
  deques

import
  gamestate,
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
    onUpdate*: proc(this: Node, deltaTime: float)

    shader: Shader
    children: seq[Node]
    removeQueue: Deque[Node]
    flags*: set[LayerObjectFlags]

    scale: DVec2
    center: DVec2
    # Rotation in degrees (clockwise).
    rotation*: float

method onCenterChanged*(this: Node) {.base.}
method center*(this: Node): DVec2 {.base.}
method `center=`*(this: Node, center: DVec2) {.base.}
method `x=`*(this: Node, x: float) {.base.}
method `y=`*(this: Node, y: float) {.base.}
method shader*(this: Node): Shader {.base.}
method `shader=`*(this: Node, shader: Shader) {.base.}
method scale*(this: Node): DVec2 {.base.}
method `scale=`*(this: Node, scale: DVec2) {.base.}
method onParentScaled*(this: Node, parentScale: DVec2) {.base.}
method `rotation=`*(this: Node, rotation: float) {.base.}
method onChildAdded*(this: Node, child: Node) {.base.}
method onChildRemoved*(this: Node, child: Node) {.base.}
method hash*(this: Node): Hash {.base.}
method update*(this: Node, deltaTime: float) {.base.}
method render*(this: Node, ctx: Target, callback: proc() = nil) {.base.}

proc initNode*(node: Node, flags: set[LayerObjectFlags], centerX, centerY: float = 0.0) =
  node.flags = flags
  node.scale = VEC2_ONE
  node.center = dvec2(centerX, centerY)

proc newNode*(flags: set[LayerObjectFlags]): Node =
  result = Node()
  initNode(result, flags)

method onCenterChanged*(this: Node) {.base.} =
  ## Fired whenever the location of the node changes.
  discard

method center*(this: Node): DVec2 {.base.} =
  return this.center

method `center=`*(this: Node, center: DVec2) {.base.} =
  this.center = center
  this.onCenterChanged()

proc x*(this: Node): float =
  return this.center.x

method `x=`*(this: Node, x: float) {.base.} =
  this.center.x = x
  this.onCenterChanged()

proc y*(this: Node): float =
  return this.center.y

method `y=`*(this: Node, y: float) {.base.} =
  this.center.y = y
  this.onCenterChanged()

method shader*(this: Node): Shader {.base.} =
  return this.shader

method `shader=`*(this: Node, shader: Shader) {.base.} =
  this.shader = shader

method scale*(this: Node): DVec2 {.base.} =
  return this.scale

method `scale=`*(this: Node, scale: DVec2) {.base.} =
  ## Sets the scale of the node.
  this.scale = scale
  for child in this.children:
    child.onParentScaled(scale)

method onParentScaled*(this: Node, parentScale: DVec2) {.base.} =
  ## Called when the parent node has been scaled.
  ## `parentScale` is the multiplicative scale of all parents above this node.
  let scale =
    if this.scale == VEC2_ONE:
      parentScale
    else:
      parentScale * this.scale

  # The whole tree needs to be notified of scaling.
  for child in this.children:
    child.onParentScaled(scale)

method `rotation=`*(this: Node, rotation: float) {.base.} =
  ## Sets the rotation of the node.
  this.rotation = rotation

proc children*(this: Node): lent seq[Node] =
  return this.children

method onChildAdded*(this: Node, child: Node) {.base.} =
  ## Invoked when a child has been added to this node.
  discard

method addChild*(this: Node, n: Node) {.base.} =
  ## Appends a child to the list of children.
  this.children.add(n)
  this.onChildAdded(n)

method onChildRemoved*(this: Node, child: Node) {.base.} =
  ## Invoked when a child has been removed from this node.
  discard

proc removeChildNow(this, child: Node) =
  ## Removes the child IMMEDIATELY.
  var index: int = -1
  for i, n in this.children:
    if n == child:
      index = i
      break
  
  if index >= 0:
    this.children.delete(index)
    this.onChildRemoved(child)

method removeChild*(this, child: Node) {.base.} =
  ## Adds the child to the removal queue.
  ## It will be removed at the start of the next update.
  this.removeQueue.addFirst(child)

method removeAllChildren*(this: Node) {.base.} =
  ## Removes all children from the node.
  for child in this.children:
    this.removeQueue.addFirst(child)

method hash*(this: Node): Hash {.base.} =
  return hash(this[].unsafeAddr)

method update*(this: Node, deltaTime: float) {.base.} =
  while this.removeQueue.len > 0:
    let child = this.removeQueue.popFirst()
    this.removeChildNow(child)

  if this.onUpdate != nil:
    this.onUpdate(this, deltaTime)

  for child in this.children:
    if loUpdate in child.flags:
      child.update(deltaTime)

method render*(this: Node, ctx: Target, callback: proc() = nil) {.base.} =
  if this.center != VEC2_ZERO:
    translate(this.center.x, this.center.y, 0)

  if this.rotation != 0:
    rotate(this.rotation, 0, 0, 1)

  if this.scale != VEC2_ONE:
    scale(this.scale.x, this.scale.y, 1.0)

  if this.shader != nil:
    this.shader.render(time, resolution)

  if callback != nil:
    callback()

  for child in this.children:
    if loRender in child.flags:
      child.render(ctx)

  if this.shader != nil:
    activateShaderProgram(0, nil)

  if this.scale != VEC2_ONE:
    scale(1 / this.scale.x, 1 / this.scale.y, 1.0)

  if this.rotation != 0:
    rotate(this.rotation, 0, 0, -1)

  if this.center != VEC2_ZERO:
    translate(-this.center.x, -this.center.y, 0)

