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
  LayerObjectFlags* {.pure.} = enum
    UPDATE
    RENDER

  Node* = ref object of RootObj
    # Invoked after this node has been updated.
    onUpdate*: proc(this: Node, deltaTime: float)
    # Called when this node has rendered.
    # This can be used to draw within its localized rendering space.
    onRender*: proc(this: Node, ctx: Target)

    shader*: Shader
    flags*: set[LayerObjectFlags]

    location: Vector
    scale*: Vector
    # Rotation in degrees (clockwise).
    rotation*: float

const UPDATE_RENDER_FLAGS* = {LayerObjectFlags.UPDATE, LayerObjectFlags.RENDER}

method setLocation*(this: Node, x, y: float) {.base.}
method hash*(this: Node): Hash {.base.}
method update*(this: Node, deltaTime: float) {.base.}
method render*(this: Node, ctx: Target, callback: proc() = nil) {.base.}

proc initNode*(node: Node, flags: set[LayerObjectFlags] = UPDATE_RENDER_FLAGS) =
  node.flags = flags
  node.scale = VECTOR_ONE

proc newNode*(flags: set[LayerObjectFlags] = UPDATE_RENDER_FLAGS): Node =
  result = Node()
  initNode(result, flags)

template getLocation*(this: Node): Vector =
  this.location

template x*(this: Node): float =
  this.location.x

template `x=`*(this: Node, x: float) =
  this.setLocation(x, this.y)

template y*(this: Node): float =
  this.location.y

template `y=`*(this: Node, y: float) =
  this.setLocation(this.x, y)

method setLocation*(this: Node, x, y: float) {.base.} =
  this.location.x = x
  this.location.y = y

template setLocation*(this: Node, v: Vector) =
  this.setLocation(v.x, v.y)

template move*(this: Node, x, y: float) =
  this.setLocation(this.x + x, this.y + y)

template move*(this: Node, v: Vector) =
  this.setLocation(this.x + v.x, this.y + v.y)

method hash*(this: Node): Hash {.base.} =
  return hash(this[].unsafeAddr)

method update*(this: Node, deltaTime: float) {.base.} =
  if this.onUpdate != nil:
    this.onUpdate(this, deltaTime)

method render*(this: Node, ctx: Target, callback: proc() = nil) {.base.} =
  ## Renders the node with its given position, rotation, and scale.
  pushMatrix()

  if this.location != VECTOR_ZERO:
    translate(this.location.x, this.location.y, 0)

  if this.rotation != 0:
    rotate(this.rotation, 0, 0, 1)

  if this.scale != VECTOR_ONE:
    scale(this.scale.x, this.scale.y, 1.0)

  if this.shader != nil:
    this.shader.render(gamestate.runTime, gamestate.resolution)

  if this.onRender != nil:
    this.onRender(this, ctx)

  if callback != nil:
    callback()

  if this.shader != nil:
    activateShaderProgram(0, nil)

  popMatrix()
