import
  hashes,
  sequtils

import
  gamestate,
  ../render/render,
  ../render/shader,
  ../math/vector2

export
  hashes,
  sequtils,
  render

type
  ## Flags indicating how the object should be treated by a layer.
  LayerObjectFlags* = uint8

  Node* = ref object of RootObj
    flags*: LayerObjectFlags
    # Invoked after this node has been updated.
    onUpdate*: proc(this: Node, deltaTime: float)

    shader*: Shader

    location: Vector
    # Rotation in degrees (clockwise).
    rotation*: float

const
  DEAD* =  0b0001'u8
  UPDATE* = 0b0010'u8
  RENDER* = 0b0100'u8
  UPDATE_AND_RENDER*: LayerObjectFlags = UPDATE or RENDER

method setLocation*(this: Node, x, y: float) {.base.}
method hash*(this: Node): Hash {.base.}
method update*(this: Node, deltaTime: float) {.base.}

proc initNode*(node: Node, flags: LayerObjectFlags = UPDATE_AND_RENDER) =
  node.flags = flags

proc newNode*(flags: LayerObjectFlags = UPDATE_AND_RENDER): Node =
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

template isAlive*(this: Node): bool =
  (this.flags and DEAD) == not DEAD

template isDead*(this: Node): bool =
  (this.flags and DEAD) == DEAD

template shouldUpdate*(this: Node): bool =
  (this.flags and UPDATE) == UPDATE

template shouldRender*(this: Node): bool =
  (this.flags and RENDER) == RENDER

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

