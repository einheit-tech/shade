import
  hashes,
  sequtils

import
  ../render/render,
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
    children: seq[Node]
    flags*: set[LayerObjectFlags]

    scale*: Vec2
    center*: Vec2
    # TODO: Would be nice to have radians, but `rotate` takes degrees.
    rotation*: float

proc initNode*(node: Node, flags: set[LayerObjectFlags]) =
  node.flags = flags
  node.scale = VEC2_ONE

proc newNode*(flags: set[LayerObjectFlags]): Node =
  result = Node()
  initNode(result, flags)

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

  if callback != nil:
    callback()

  scale(1 / this.scale.x, 1 / this.scale.y, 1.0)

  if this.rotation != 0:
    rotate(-this.rotation, cfloat 0, cfloat 0, cfloat 0)

  if this.center != VEC2_ZERO:
    translate(cfloat -this.center.x, cfloat -this.center.y, cfloat 0)

  for child in this.children:
    if loRender in child.flags:
      child.render(ctx)

