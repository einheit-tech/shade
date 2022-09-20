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

    shader*: Shader
    flags*: set[LayerObjectFlags]

    location: Vector
    # Rotation in degrees (clockwise).
    rotation*: float

const UPDATE_RENDER_FLAGS* = {LayerObjectFlags.UPDATE, LayerObjectFlags.RENDER}

method setLocation*(this: Node, x, y: float) {.base.}
method hash*(this: Node): Hash {.base.}
method update*(this: Node, deltaTime: float) {.base.}

proc initNode*(node: Node, flags: set[LayerObjectFlags] = UPDATE_RENDER_FLAGS) =
  node.flags = flags

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

template move*(this: Node, dx, dy: float) =
  this.setLocation(this.x + dx, this.y + dy)

template move*(this: Node, v: Vector) =
  this.setLocation(this.x + v.x, this.y + v.y)

method hash*(this: Node): Hash {.base.} =
  return hash(this[].unsafeAddr)

method update*(this: Node, deltaTime: float) {.base.} =
  if this.onUpdate != nil:
    this.onUpdate(this, deltaTime)

Node.renderAsParent:
  if this.shader != nil:
    this.shader.render(gamestate.runTime, gamestate.resolution)

