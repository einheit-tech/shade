import
  macros,
  tables

import
  layer,
  physicsbody,
  ../math/mathutils,
  ../math/collision/sat,
  ../math/collision/collisionresult,
  ../math/collision/aabbtree

export
  layer,
  physicsbody

# TODO: Tune and make configurable.
const
  DEFAULT_GRAVITY* = vector(0, 577)
  COLLISION_ITERATIONS* = 20

type
  PhysicsLayer* = ref object of Layer
    gravity: Vector
    gravityNormal: Vector
    physicsBodyChildren: seq[PhysicsBody]
    aabbTree: AABBTree[PhysicsBody]
    # Collisions that happened this frame.
    # Only tracks collisions for PhysicsBodies that have collision callbacks.
    currentFrameCollisions: Table[tuple[owner: PhysicsBody, other: PhysicsBody], CollisionResult]

template gravity*(this: PhysicsLayer): Vector =
  this.gravity

template `gravity=`*(this: PhysicsLayer, gravity: Vector) =
  this.gravity = gravity
  this.gravityNormal = this.gravity.normalize()

proc initPhysicsLayer*(
  layer: PhysicsLayer,
  gravity: Vector = DEFAULT_GRAVITY,
  z: float = 1.0
) =
  initLayer(layer, z)
  `gravity=`(layer, gravity)
  layer.aabbTree = newAABBTree[PhysicsBody]()

proc newPhysicsLayer*(gravity: Vector = DEFAULT_GRAVITY, z: float = 1.0): PhysicsLayer =
  result = PhysicsLayer()
  initPhysicsLayer(result, gravity, z)

method addChild(this: PhysicsLayer, child: Node) =
  procCall Layer(this).addChild(child)
  if child of PhysicsBody:
    this.physicsBodyChildren.add((PhysicsBody) child)
    # this.aabbTree.addObject((PhysicsBody) child)

method removeChild*(this: PhysicsLayer, child: Node) =
  procCall Layer(this).removeChild(child)
  if child of PhysicsBody:
    let body = (PhysicsBody) child
    var index = -1
    for i, n in this.physicsBodyChildren:
      if n == body:
        index = i
        break
    
    if index >= 0:
      # this.aabbTree.removeObject((PhysicsBody) child)
      this.physicsBodyChildren.delete(index)

template resolve(collision: CollisionResult, bodyA, bodyB: PhysicsBody) =
  ## Resolves a collision between two bodies.
  ## NOTE: Perfectly inelastic collisions are not calculated correctly,
  ## and some momentum will be added.
  let
    relVelocity = bodyB.velocity - bodyA.velocity
    velAlongNormal = relVelocity.dotProduct(collision.normal)
    bodiesAreNotSeparating = velAlongNormal > 0.0
    mtv = collision.getMinimumTranslationVector()

  # Translate bodies out of each other.
  if bodyA.kind == PhysicsBodyKind.STATIC:
    bodyB.move(mtv.negate())
  elif bodyB.kind == PhysicsBodyKind.STATIC:
    bodyA.move(mtv)
  else:
    bodyA.move(mtv * 0.5)
    bodyB.move(mtv * -0.5)

  template iMassA: float = bodyA.collisionShape.inverseMass
  template iMassB: float = bodyB.collisionShape.inverseMass

  # Apply impulses if bodies are not moving away from one another.
  if bodiesAreNotSeparating:
    let
      restitution = min(bodyA.collisionShape.elasticity, bodyB.collisionShape.elasticity)
      impulse = collision.normal * (-(1.0 + restitution) * velAlongNormal / (iMassA + iMassB))
    bodyA.velocity -= impulse * iMassA
    bodyB.velocity += impulse * iMassB

template handleCollisions*(this: PhysicsLayer, deltaTime: float) =
  for i, bodyA in this.physicsBodyChildren:

    # TODO: Left half of objects not seen as colliding?
    # let bodies = this.aabbTree.findOverlappingObjects(bodyA.getBounds())
    # for bodyB in bodies:
    for j in countup(i + 1, this.physicsBodyChildren.len - 1):
      let bodyB = this.physicsBodyChildren[j]

      if bodyA.kind == PhysicsBodyKind.STATIC and bodyB.kind == PhysicsBodyKind.STATIC:
        continue
      
      let collision = collides(
        bodyA.getLocation(),
        bodyA.collisionShape,
        bodyB.getLocation(),
        bodyB.collisionShape
      )

      if collision == nil:
        continue

      collision.resolve(bodyA, bodyB)

      # Register the collision for any existing callbacks.
      if bodyA.collisionListenerCount > 0 or bodyB.collisionListenerCount > 0:
        this.currentFrameCollisions[(bodyA, bodyB)] = collision

template applyForcesToBodies*(this: PhysicsLayer, deltaTime: float) =
  for body in this.physicsBodyChildren:
    if body.kind == PhysicsBodyKind.STATIC:
      continue

    # Apply forces to all non-static bodies.
    for force in body.forces:
      body.velocity += force * deltaTime

    # Clear forces every frame.
    if body.kind == PhysicsBodyKind.DYNAMIC and this.gravity != VECTOR_ZERO:
      # Re-apply gravity to dynamic bodies.
      body.forces.setLen(1)
      body.forces[0] = this.gravity
    else:
      body.forces.setLen(0)

method update*(this: PhysicsLayer, deltaTime: float, onChildUpdate: proc(child: Node) = nil) =
  procCall Layer(this).update(deltaTime)

  let subdividedDeltaTime = deltaTime / COLLISION_ITERATIONS
  for i in 1..COLLISION_ITERATIONS:
    this.handleCollisions(subdividedDeltaTime)

  this.applyForcesToBodies(deltaTime)

  # Notify the callbacks and clear after the frame.
  for bodies, collision in this.currentFrameCollisions:
    bodies.owner.notifyCollisionListeners(bodies.other, collision, this.gravityNormal)
    bodies.other.notifyCollisionListeners(bodies.owner, collision.invert(), this.gravityNormal)

  this.currentFrameCollisions.clear()

when defined(aabbtreeOutlines):
  PhysicsLayer.renderAsChildOf(Layer):
    this.aabbTree.render(ctx)

