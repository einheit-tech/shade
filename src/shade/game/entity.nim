import
  pixie,
  hashes

import
  ../math/rectangle,
  ../math/collision/collisionhull,
  material

export pixie, rectangle, collisionhull, material

## Flags indicating how the object should be treated by a layer.
type LayerObjectFlags* = enum
  ## Only update
  loUpdate = 0b1
  ## Only render
  loRender = 0b10
  ## Render and update
  loUpdateRender = loUpdate.int or loRender.int
  ## Render, update, and use in physics
  loPhysics = loUpdateRender.int or 0b100

template includes*(this, flags: LayerObjectFlags): bool =
  (this.int and flags.int) == flags.int

type Entity* = ref object of RootObj
  flags*: LayerObjectFlags
  center*: Vec2
  # Pixels per second.
  velocity*: Vec2
  rotation*: float
  lastMoveVector*: Vec2
  collisionHull*: CollisionHull
  material*: Material

proc newEntity*(
  flags: LayerObjectFlags,
  material: Material = NULL,
  x, y: float = 0.0
): Entity =
  result = Entity(
    flags: flags,
    material: material,
    center: vec2(x, y)
  )

template getMass*(this: Entity): float =
  if this.collisionHull != nil:
    this.collisionHull.getArea() * this.material.density
  else:
    0.0

template x*(this: Entity): float = this.center.x
template y*(this: Entity): float = this.center.y

template translate*(this: Entity, delta: Vec2) =
  this.center += delta

template rotate*(this: Entity, deltaRotation: float) =
  this.rotation += deltaRotation
  this.collisionHull.rotate(deltaRotation)

method bounds*(this: Entity): Rectangle {.base.} =
  ## Gets the bounds of the Entity's collision hull.
  ## The bounds are relative to the center of the object.
  if this.collisionHull != nil:
    return this.collisionHull.getBounds()

method hash*(this: Entity): Hash {.base.} = hash(this[].unsafeAddr)

method update*(this: Entity, deltaTime: float) {.base.} =
  this.lastMoveVector = this.velocity * deltaTime
  this.center += this.lastMoveVector

method render*(this: Entity, ctx: Context) {.base.} = discard

