import
  hashes,
  sequtils

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
    loPhysics

  Node* = ref object of RootObj
    shader: Shader
    children: seq[Node]
    flags*: set[LayerObjectFlags]

    scale: Vec2
    center*: Vec2
    # TODO: Would be nice to have radians, but `rotate` takes degrees.
    # TODO: Need to handle rotation in the same manner as scale.
    rotation*: float

proc initNode*(node: Node, flags: set[LayerObjectFlags]) =
  node.flags = flags
  node.scale = VEC2_ONE

proc newNode*(flags: set[LayerObjectFlags]): Node =
  result = Node()
  initNode(result, flags)

proc `shader=`*(this: Node, shader: Shader) =
  this.shader = shader

template scale*(this: Node): Vec2 =
  this.scale

method onParentScaled*(this: Node, parentScale: Vec2) {.base.} =
  ## Called when a parent of this node has been scaled.
  discard

proc `scale=`*(this: Node, scale: Vec2) =
  ## Sets the scale of the node.
  this.scale = scale
  for child in this.children:
    child.onParentScaled(this.scale)

method onParentRotated*(this: Node, parentRotation: float) {.base.} =
  ## Called when a parent of this node has been rotated.
  discard

proc `rotation=`*(this: Node, rotation: float) =
  ## Sets the rotation of the node.
  this.rotation = rotation
  for child in this.children:
    child.onParentRotated(this.rotation)

proc children*(this: Node): lent seq[Node] =
  return this.children

template addChild*(this: Node, n: Node) =
  ## Appends a child to the list of children.
  this.children.add(n)

template removeChild*(this: Node, n: Node) =
  ## Removes the child while preserving order of the children.
  ## This is slower than `removeChildFast`.
  this.children.delete(n)

template removeChildFast*(this: Node, n: Node) =
  ## Removes the child WITHOUT preserving order of the children.
  ## This is faster than `removeChild`.
  this.children.del(n)

method hash*(this: Node): Hash {.base.} =
  return hash(this[].unsafeAddr)

method update*(this: Node, deltaTime: float) {.base.} =
  for child in this.children:
    if loUpdate in child.flags:
      child.update(deltaTime)

method render*(this: Node, ctx: Target, callback: proc() = nil) {.base.} =
  if this.center != VEC2_ZERO:
    translate(cfloat this.center.x, cfloat this.center.y, cfloat 0)

  if this.rotation != 0:
    rotate(this.rotation, cfloat 0, cfloat 0, cfloat 0)

  scale(this.scale.x, this.scale.y, 1.0)

  if this.shader != nil:
    this.shader.render(time, resolution)

  for child in this.children:
    if loRender in child.flags:
      child.render(ctx)

  if callback != nil:
    callback()

  scale(1 / this.scale.x, 1 / this.scale.y, 1.0)

  if this.rotation != 0:
    rotate(-this.rotation, cfloat 0, cfloat 0, cfloat 0)

  if this.center != VEC2_ZERO:
    translate(cfloat -this.center.x, cfloat -this.center.y, cfloat 0)

