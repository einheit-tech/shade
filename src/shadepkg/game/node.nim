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

  Node* = ref object of RootObj
    # Invoked after this node has been updated.
    onUpdate*: proc(this: Node, deltaTime: float)
    # Called when this node has rendered.
    # This can be used to draw within its localized rendering space.
    onRender*: proc(this: Node, ctx: Target)

    shader*: Shader
    flags*: set[LayerObjectFlags]

    center*: Vector
    scale*: Vector
    # Rotation in degrees (clockwise).
    rotation*: float

method hash*(this: Node): Hash {.base.}
method update*(this: Node, deltaTime: float) {.base.}
method render*(this: Node, ctx: Target, callback: proc() = nil) {.base.}

proc initNode*(node: Node, flags: set[LayerObjectFlags] = {loUpdate, loRender}) =
  node.flags = flags
  node.scale = VECTOR_ONE

proc newNode*(flags: set[LayerObjectFlags] = {loUpdate, loRender}): Node =
  result = Node()
  initNode(result, flags)

template x*(this: Node): float =
  this.center.x

template `x=`*(this: Node, x: float) =
  this.center = vector(x, this.center.y)

template y*(this: Node): float =
  this.center.y

template `y=`*(this: Node, y: float) =
  this.center = vector(this.center.x, y)

method hash*(this: Node): Hash {.base.} =
  return hash(this[].unsafeAddr)

method update*(this: Node, deltaTime: float) {.base.} =
  if this.onUpdate != nil:
    this.onUpdate(this, deltaTime)

method render*(this: Node, ctx: Target, callback: proc() = nil) {.base.} =
  ## Renders the node with its given position, rotation, and scale.
  if this.center != VECTOR_ZERO:
    translate(this.center.x, this.center.y, 0)

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

  if this.shader != nil:
    activateShaderProgram(0, nil)

  if this.scale != VECTOR_ONE:
    scale(1 / this.scale.x, 1 / this.scale.y, 1.0)

  if this.rotation != 0:
    rotate(this.rotation, 0, 0, -1)

  if this.center != VECTOR_ZERO:
    translate(-this.center.x, -this.center.y, 0)

