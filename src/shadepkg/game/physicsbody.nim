import 
  ../math/collision/collisionhull,
  entity,
  ../render/color

export entity, collisionhull

type
  PhysicsBodyKind* = enum
    pbKinematic,
    pbStatic

  PhysicsBody* = ref object of Entity
    collisionHull*: CollisionHull
    material*: Material
    kind*: PhysicsBodyKind

proc initPhysicsBody*(
  body: PhysicsBody,
  kind: PhysicsBodyKind,
  hull: CollisionHull,
  material: Material = NULL,
  flags: set[LayerObjectFlags] = {loUpdate, loRender, loPhysics},
  centerX: float = 0.0,
  centerY: float = 0.0
) =
  initEntity(Entity(body), flags, centerX, centerY)
  body.kind = kind
  body.collisionHull = hull
  body.material = material
  body.addChild(body.collisionHull)

proc newPhysicsBody*(
  kind: PhysicsBodyKind,
  hull: CollisionHull,
  material: Material = NULL,
  flags: set[LayerObjectFlags] = {loUpdate, loRender, loPhysics},
  centerX: float = 0.0,
  centerY: float = 0.0
): PhysicsBody =
  result = PhysicsBody()
  initPhysicsBody(
    result,
    kind,
    hull,
    material,
    flags,
    centerX,
    centerY
  )

template getMass*(this: Entity): float =
  this.collisionHull.getArea() * this.material.density

method bounds*(this: PhysicsBody): Rectangle {.base.} =
  ## Gets the bounds of the Entity's collision hull.
  ## The bounds are relative to the center of the object.
  return this.collisionHull.getBounds()

method update*(this: PhysicsBody, deltaTime: float) =
  if this.kind != pbStatic:
    procCall Entity(this).update(deltaTime)

