import
  macros,
  safeset

import
  node,
  ../math/collision/collisionshape,
  ../math/collision/collisionresult

export
  node,
  collisionshape,
  collisionresult

type
  CollisionListener* = proc(this, other: PhysicsBody, result: CollisionResult, gravityNormal: Vector): bool
  ## Return true if we should remove the listener after it's been invoked.

  PhysicsBodyKind* {.pure.} = enum
    ## A body controlled by applied forces.
    DYNAMIC
    ## A body that does not move based on forces, collisions, etc.
    ## Mainly used for terrain, moving platforms, and the like.
    STATIC
    ## A body which is controlled by code, rather than the physics engine.
    ## TODO: More docs about Kinematic bodies
    KINEMATIC

  PhysicsBody* = ref object of Node
    # TODO: Make collisionShape required.
    collisionShape: CollisionShape
    velocity*: Vector
    lastMoveVector*: Vector
    bounds: AABB

    case kind*: PhysicsBodyKind:
      of DYNAMIC, KINEMATIC:
        isOnGround*: bool
        isOnWall*: bool
        ## Forces applied to the center of mass, this frame.
        forces*: seq[Vector]
      of STATIC:
        discard

    collisionListeners: SafeSet[CollisionListener]

proc addCollisionListener*(this: PhysicsBody, listener: CollisionListener)
proc removeCollisionListener*(this: PhysicsBody, listener: CollisionListener)
proc getBounds*(this: PhysicsBody): AABB
proc wallAndGroundSetter(
  this, other: PhysicsBody,
  collisionResult: CollisionResult,
  gravityNormal: Vector
): bool

proc initPhysicsBody*(
  physicsBody: var PhysicsBody,
  flags: set[LayerObjectFlags] = {LayerObjectFlags.UPDATE, LayerObjectFlags.RENDER}
) =
  initNode(Node(physicsBody), flags)
  physicsBody.collisionListeners = newSafeSet[CollisionListener]()
  if physicsBody.kind != PhysicsBodyKind.STATIC:
    physicsBody.addCollisionListener(wallAndGroundSetter)

proc newPhysicsBody*(
  kind: PhysicsBodyKind,
  flags: set[LayerObjectFlags] = {LayerObjectFlags.UPDATE, LayerObjectFlags.RENDER}
): PhysicsBody =
  ## Creates a new PhysicsBody.
  result = PhysicsBody(kind: kind)
  initPhysicsBody(result, flags)

proc collisionListenerCount*(this: PhysicsBody): int =
  this.collisionListeners.len

template collisionShape*(this: PhysicsBody): CollisionShape =
  this.collisionShape

template `collisionShape=`*(this: PhysicsBody, shape: CollisionShape) =
  this.collisionShape = shape
  if this.kind == PhysicsBodyKind.STATIC and this.collisionShape != nil:
    this.collisionShape.mass = 0

template width*(this: PhysicsBody): float =
  if this.collisionShape != nil:
    this.collisionShape.width()
  else:
    0

template height*(this: PhysicsBody): float =
  if this.collisionShape != nil:
    this.collisionShape.height()
  else:
    0

template velocityX*(this: PhysicsBody): float =
  this.velocity.x

template `velocityX=`*(this: PhysicsBody, x: float) =
  this.velocity = vector(x, this.velocity.y)

template velocityY*(this: PhysicsBody): float =
  this.velocity.y

template `velocityY=`*(this: PhysicsBody, y: float) =
  this.velocity = vector(this.velocity.x, y)

method setLocation*(this: PhysicsBody, x, y: float) =
  # Move the bounds accordingly.
  if this.bounds != nil:
    let delta = vector(x, y) - this.getLocation()
    this.bounds.topLeft += delta
    this.bounds.bottomRight += delta

  procCall setLocation((Node) this, x, y)

proc getBounds*(this: PhysicsBody): AABB =
  if this.bounds == nil and this.collisionShape != nil:
    this.bounds = this.collisionShape.getBounds().getTranslatedInstance(this.getLocation())
  return this.bounds

proc addCollisionListener(this: PhysicsBody, listener: CollisionListener) =
  this.collisionListeners.add(listener)

template buildCollisionListener*(thisBody: PhysicsBody, body: untyped) =
  let listener: CollisionListener =
    proc(
      this {.inject.}, other {.inject.}: PhysicsBody,
      collisionResult {.inject.}: CollisionResult,
      gravityNormal {.inject.}: Vector
    ): bool =
      body

  thisBody.addCollisionListener(listener)

proc removeCollisionListener*(this: PhysicsBody, listener: CollisionListener) =
  this.collisionListeners.remove(listener)

proc notifyCollisionListeners*(
  this, other: PhysicsBody,
  collisionResult: CollisionResult,
  gravityNormal: Vector
) =
  for listener in this.collisionListeners:
    if listener(this, other, collisionResult, gravityNormal):
      this.collisionListeners.remove(listener)

proc wallAndGroundSetter(
  this, other: PhysicsBody,
  collisionResult: CollisionResult,
  gravityNormal: Vector
): bool =
  if collisionResult.normal.negate.dotProduct(gravityNormal) > 0.5:
    this.isOnGround = true

  if abs(collisionResult.normal.crossProduct(gravityNormal)) > 0.5:
    this.isOnWall = true

method update*(this: PhysicsBody, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  this.lastMoveVector = this.velocity * deltaTime
  if this.velocity != VECTOR_ZERO:
    this.move(this.lastMoveVector)

  if this.kind != PhysicsBodyKind.STATIC:
    # Reset the state every update.
    this.isOnGround = false
    this.isOnWall = false

PhysicsBody.renderAsNodeChild:
  if callback != nil:
    callback()

  when defined(collisionoutlines):
    if this.collisionShape != nil:
      ctx.scale(1.0 / this.scale.x, 1.0 / this.scale.y):
        this.collisionShape.render(ctx)

