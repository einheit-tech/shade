import macros

import
  node,
  ../math/collision/collisionshape,
  ../math/collision/collisionresult,
  ../collections/safeset

export
  node,
  collisionshape,
  collisionresult

type
  CollisionListener* = proc(this, other: PhysicsBody, result: CollisionResult, gravityNormal: Vector): bool
  ## Return true if we should remove the listener after it's been invoked.

  PhysicsBodyKind* = enum
    ## A body controlled by applied forces.
    pbDynamic,
    ## A body that does not move based on forces, collisions, etc.
    ## Mainly used for terrain, moving platforms, and the like.
    pbStatic,
    ## A body which is controlled by code, rather than the physics engine.
    ## TODO: More docs about Kinematic bodies
    pbKinematic

  PhysicsBody* = ref object of Node
    # TODO: Make collisionShape required.
    collisionShape: CollisionShape
    velocity*: Vector
    bounds: AABB

    case kind*: PhysicsBodyKind:
      of pbDynamic, pbKinematic:
        isOnGround*: bool
        isOnWall*: bool
        ## Forces applied to the center of mass, this frame.
        forces*: seq[Vector]
      of pbStatic:
        discard

    collisionListeners: SafeSet[CollisionListener]

proc addCollisionListener*(this: PhysicsBody, listener: CollisionListener)
proc removeCollisionListener*(this: PhysicsBody, listener: CollisionListener)
proc wallAndGroundSetter(this, other: PhysicsBody, collisionResult: CollisionResult, gravityNormal: Vector): bool
proc getBounds*(this: PhysicsBody): AABB

proc initPhysicsBody*(physicsBody: var PhysicsBody, flags: set[LayerObjectFlags] = {loUpdate, loRender}) =
  initNode(Node(physicsBody), flags)
  physicsBody.collisionListeners = newSafeSet[CollisionListener]()
  if physicsBody.kind != pbStatic:
    physicsBody.addCollisionListener(wallAndGroundSetter)

proc newPhysicsBody*(
  kind: PhysicsBodyKind,
  flags: set[LayerObjectFlags] = {loUpdate, loRender}
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
  if this.kind == pbStatic:
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
  if this.bounds == nil:
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

  if this.velocity != VECTOR_ZERO:
    this.move(this.velocity * deltaTime)

  if this.kind != pbStatic:
    # Reset the state every update.
    this.isOnGround = false
    this.isOnWall = false

PhysicsBody.renderAsNodeChild:
  when defined(collisionoutlines):
    if this.collisionShape != nil:
      this.collisionShape.render(ctx)

  if callback != nil:
    callback()

