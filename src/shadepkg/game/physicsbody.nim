import hashes

import 
  ../math/collision/collisionhull,
  material,
  entity

export collisionhull, material, entity.LayerObjectFlags

type
  PhysicsBodyKind* = enum
    pbKinematic,
    pbStatic

  PhysicsBody* = ref object of Entity
    collisionHull*: CollisionHull
    material*: Material
    kind*: PhysicsBodyKind

proc newPhysicsBody*(
  kind: PhysicsBodyKind,
  hull: CollisionHull,
  flags: set[LayerObjectFlags] = {loUpdate, loRender, loPhysics},
  material: Material = NULL,
  centerX, centerY: float = 0.0
): PhysicsBody =
  return PhysicsBody(
    kind: kind,
    collisionHull: hull,
    flags: flags,
    material: material,
    center: vec2(centerX, centerY)
  )

template getMass*(this: Entity): float =
  this.collisionHull.getArea() * this.material.density

method hash*(this: PhysicsBody): Hash = hash(this[].unsafeAddr)

method bounds*(this: PhysicsBody): Rectangle {.base.} =
  ## Gets the bounds of the Entity's collision hull.
  ## The bounds are relative to the center of the object.
  return this.collisionHull.getBounds()

method update*(this: PhysicsBody, deltaTime: float) {.locks: 0.} =
  if this.kind != pbStatic:
    procCall Entity(this).update(deltaTime)

render(PhysicsBody, Entity):
  if callback != nil:
    callback()

  # Render the collisionHull outlines.
  when defined(collisionoutlines):
    ctx.strokeStyle = rgba(0, 0, 255, 255)
    ctx.lineWidth = 1
    ctx.lineCap = lcSquare
    this.collisionHull.stroke(ctx, this.collisionHull.center)

