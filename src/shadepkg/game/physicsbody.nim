import hashes

import 
  ../math/collision/collisionhull,
  material,
  entity

export collisionhull, material, entity.LayerObjectFlags

type
  PhysicsBodyKind* = enum
    pbStatic,
    pbKinematic

  PhysicsBody* = ref object of Entity
    collisionHull*: CollisionHull
    material*: Material
    kind*: PhysicsBodyKind

proc newPhysicsBody*(
  kind: PhysicsBodyKind,
  flags: set[LayerObjectFlags] = {loUpdate, loRender, loPhysics},
  material: Material = NULL,
  centerX, centerY: float = 0.0
): PhysicsBody =
  return PhysicsBody(flags: flags, material: material, center: vec2(centerX, centerY))

template getMass*(this: Entity): float =
  this.collisionHull.getArea() * this.material.density

method hash*(this: PhysicsBody): Hash = hash(this[].unsafeAddr)

method bounds*(this: PhysicsBody): Rectangle {.base.} =
  ## Gets the bounds of the Entity's collision hull.
  ## The bounds are relative to the center of the object.
  return this.collisionHull.getBounds()

method update*(this: PhysicsBody, deltaTime: float) {.locks: 0.} =
  if this.kind != pbStatic:
    this.lastMoveVector = this.velocity * deltaTime
    this.center += this.lastMoveVector

render(PhysicsBody, Entity):
  if callback != nil:
    callback()

  # Render the collisionHull outlines.
  when defined(collisionoutlines):
    ctx.strokeStyle = rgba(255, 0, 0, 255)
    ctx.lineWidth = 1
    ctx.lineCap = lcSquare
    this.collisionHull.stroke(ctx, this.center)

