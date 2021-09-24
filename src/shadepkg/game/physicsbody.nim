import 
  ../math/collision/collisionhull,
  entity

export entity, collisionhull

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
  center: Vec2 = VEC2_ZERO,
  flags: set[LayerObjectFlags] = {loUpdate, loRender, loPhysics},
  material: Material = NULL,
): PhysicsBody =
  return PhysicsBody(
    kind: kind,
    collisionHull: hull,
    center: center,
    flags: flags,
    material: material
  )

template getMass*(this: Entity): float =
  this.collisionHull.getArea() * this.material.density

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
    ctx.strokeStyle = rgba(255, 0, 0, 255)
    ctx.lineWidth = 1
    ctx.lineCap = lcSquare
    this.collisionHull.stroke(ctx)

