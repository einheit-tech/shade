import 
  locks,
  deques,
  node,
  ../math/collision/collisionshape,
  ../math/collision/collisionresult

export
  node,
  collisionshape,
  collisionresult

type
  CollisionListener* = proc(this, other: PhysicsBody, result: CollisionResult, gravityNormal: Vector)
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
    bounds: Rectangle

    case kind*: PhysicsBodyKind:
      of pbDynamic, pbKinematic:
        isOnGround*: bool
        isOnWall*: bool
        ## Forces applied to the center of mass, this frame.
        forces*: seq[Vector]
      of pbStatic:
        discard

    collisionListenersLock: Lock
    collisionListeners: seq[CollisionListener]
    collisionListenersToAdd: Deque[(CollisionListener, bool)]
    collisionListenersToRemove: Deque[CollisionListener]

proc addCollisionListener*(this: PhysicsBody, listener: CollisionListener, fireOnce: bool = false)
proc removeCollisionListener*(this: PhysicsBody, listener: CollisionListener)
proc wallAndGroundSetter(this, other: PhysicsBody, collisionResult: CollisionResult, gravityNormal: Vector)
proc getBounds*(this: PhysicsBody): Rectangle

proc initPhysicsBody*(physicsBody: var PhysicsBody, flags: set[LayerObjectFlags] = {loUpdate, loRender}) =
  initNode(Node(physicsBody), flags)
  initLock(physicsBody.collisionListenersLock)
  if physicsBody.kind != pbStatic:
    physicsBody.addCollisionListener(wallAndGroundSetter)

proc newPhysicsBody*(
  kind: PhysicsBodyKind,
  flags: set[LayerObjectFlags] = {loUpdate, loRender}
): PhysicsBody =
  ## Creates a new PhysicsBody.
  result = PhysicsBody(kind: kind)
  initPhysicsBody(result, flags)

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
    echo this.bounds.topLeft.y

  procCall setLocation((Node) this, x, y)

proc getBounds*(this: PhysicsBody): Rectangle =
  if this.bounds == nil:
    this.bounds = this.collisionShape.getBounds().getTranslatedInstance(this.getLocation())
  return this.bounds

proc addCollisionListenerNow*(this: PhysicsBody, listener: CollisionListener, fireOnce: bool = false) =
  if fireOnce:
    var onceListener: CollisionListener
    onceListener = proc(a, b: PhysicsBody, collisionResult: CollisionResult, gravityNormal: Vector) =
      listener(a, b, collisionResult, gravityNormal)
      this.removeCollisionListener(onceListener)
    this.collisionListeners.add(onceListener)
  else:
    this.collisionListeners.add(listener)

proc addCollisionListener*(this: PhysicsBody, listener: CollisionListener, fireOnce: bool = false) =
  if tryAcquire(this.collisionListenersLock):
    this.addCollisionListenerNow(listener, fireOnce)
    this.collisionListenersLock.release()
  else:
    this.collisionListenersToAdd.addLast((listener, fireOnce))

proc removeCollisionListenerNow*(this: PhysicsBody, listener: CollisionListener) =
  var index = -1
  for i, l in this.collisionListeners:
    if l == listener:
      index = i
      break
  
  if index >= 0:
    this.collisionListeners.delete(index)

proc removeCollisionListener*(this: PhysicsBody, listener: CollisionListener) =
  if tryAcquire(this.collisionListenersLock):
    this.removeCollisionListenerNow(listener)
    this.collisionListenersLock.release()
  else:
    this.collisionListenersToRemove.addLast(listener)

proc notifyCollisionListeners*(
  this, other: PhysicsBody,
  collisionResult: CollisionResult,
  gravityNormal: Vector
) =
  withLock(this.collisionListenersLock):
    for listener in this.collisionListeners:
      listener(this, other, collisionResult, gravityNormal)

proc wallAndGroundSetter(
  this, other: PhysicsBody,
  collisionResult: CollisionResult,
  gravityNormal: Vector
) =
  if collisionResult.normal.negate.dotProduct(gravityNormal) > 0.5:
    this.isOnGround = true

  if abs(collisionResult.normal.crossProduct(gravityNormal)) > 0.5:
    this.isOnWall = true

method update*(this: PhysicsBody, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  if this.velocity != VECTOR_ZERO:
    this.move(this.velocity * deltaTime)

  withLock(this.collisionListenersLock):
    while this.collisionListenersToRemove.len > 0:
      let listener = this.collisionListenersToRemove.popFirst()
      this.removeCollisionListenerNow(listener)

    while this.collisionListenersToAdd.len > 0:
      let (listener, fireOnce) = this.collisionListenersToAdd.popFirst()
      this.addCollisionListenerNow(listener, fireOnce)

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

