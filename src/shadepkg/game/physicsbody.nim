import
  macros,
  safeseq

import
  node,
  ../math/mathutils,
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
    # We are tracking the rotation from the last frame to see if we need to rotate the collisionShape.
    previousRotation: float
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

    collisionListeners: SafeSeq[CollisionListener]

proc addCollisionListener*(this: PhysicsBody, listener: CollisionListener)
proc removeCollisionListener*(this: PhysicsBody, listener: CollisionListener)
proc getBounds*(this: PhysicsBody): AABB
proc wallAndGroundSetter(
  this, other: PhysicsBody,
  collisionResult: CollisionResult,
  gravityNormal: Vector
): bool

template `collisionShape=`*(this: PhysicsBody, shape: var CollisionShape) =
  this.collisionShape = shape
  if this.kind == PhysicsBodyKind.STATIC:
    this.collisionShape.mass = 0

proc initPhysicsBody*(
  physicsBody: var PhysicsBody,
  shape: var CollisionShape,
  flags = UPDATE_AND_RENDER
) =
  initNode(Node(physicsBody), flags)
  `collisionShape=`(physicsBody, shape)
  physicsBody.collisionListeners = newSafeSeq[CollisionListener]()
  if physicsBody.kind != PhysicsBodyKind.STATIC:
    physicsBody.addCollisionListener(wallAndGroundSetter)

  physicsBody.previousRotation = physicsBody.rotation

proc newPhysicsBody*(
  kind: PhysicsBodyKind,
  shape: var CollisionShape,
  flags = UPDATE_AND_RENDER
): PhysicsBody =
  ## Creates a new PhysicsBody.
  result = PhysicsBody(kind: kind)
  initPhysicsBody(result, shape, flags)

proc collisionListenerCount*(this: PhysicsBody): int =
  this.collisionListeners.len

template collisionShape*(this: PhysicsBody): CollisionShape =
  this.collisionShape

template width*(this: PhysicsBody): float =
  this.collisionShape.width()

template height*(this: PhysicsBody): float =
  this.collisionShape.height()

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
  if this.bounds != AABB_ZERO:
    let delta = vector(x, y) - this.getLocation()
    this.bounds.topLeft += delta
    this.bounds.bottomRight += delta

  procCall setLocation((Node) this, x, y)

proc getBounds*(this: PhysicsBody): AABB =
  if this.bounds == AABB_ZERO:
    this.bounds = this.collisionShape.getBounds().getTranslatedInstance(this.getLocation())
  return this.bounds

proc addCollisionListener*(this: PhysicsBody, listener: CollisionListener) =
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

  if this.previousRotation != this.rotation:
    # Ensure the collisionShape has been rotated
    this.collisionShape.setRotation(this.rotation.toRadians())
    this.previousRotation = this.rotation

  this.lastMoveVector = this.velocity * deltaTime
  if this.velocity != VECTOR_ZERO:
    this.move(this.lastMoveVector)

  if this.kind != PhysicsBodyKind.STATIC:
    # Reset the state every update.
    this.isOnGround = false
    this.isOnWall = false

when defined(collisionoutlines):
  PhysicsBody.renderAsNodeChild:
    discard setLineThickness(1.0)
    this.collisionShape.render(ctx, this.x + offsetX, this.y + offsetY)

