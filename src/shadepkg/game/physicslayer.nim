import
  layer,
  physicsbody,
  ../math/mathutils,
  ../math/collision/sat,
  ../math/collision/collisionresult

export
  layer,
  physicsbody

# TODO: Tune
# const DEFAULT_GRAVITY* = vector(0, 2000)
const DEFAULT_GRAVITY* = vector(0, 577)

type PhysicsLayer* = ref object of Layer
  gravity*: Vector
  physicsBodyChildren: seq[PhysicsBody]
  slop*: float

proc initPhysicsLayer*(
  layer: PhysicsLayer,
  gravity: Vector = DEFAULT_GRAVITY,
  z: float = 1.0
) =
  initLayer(layer, z)
  layer.gravity = gravity

proc newPhysicsLayer*(gravity: Vector = DEFAULT_GRAVITY, z: float = 1.0): PhysicsLayer =
  result = PhysicsLayer()
  initPhysicsLayer(result, gravity, z)

method addChildNow(this: PhysicsLayer, child: Node) =
  procCall Layer(this).addChildNow(child)
  if child of PhysicsBody:
    this.physicsBodyChildren.add((PhysicsBody) child)

method removeChildNow*(this: PhysicsLayer, child: Node) =
  procCall Layer(this).removeChildNow(child)
  if child of PhysicsBody:
    let body = (PhysicsBody) child
    var index = -1
    for i, n in this.physicsBodyChildren:
      if n == body:
        index = i
        break
    
    if index >= 0:
      this.physicsBodyChildren.delete(index)

template resolve(collision: CollisionResult, bodyA, bodyB: PhysicsBody, deltaTime: float) =
  ## Resolves a collision between two bodies.
  ## NOTE: Perfectly inelastic collisions are not calculated correctly,
  ## and some momentum will be added.

  if collision.contactRatio < 0:
    # TODO: Our SAT algorithm has a bug (at least one).
    # This should be impossible, right?
    # Also check getCircleToPolygonProjectionAxes etc
    echo collision.contactRatio

  let
    collisionA = if collision.isCollisionOwnerA: collision else: collision.flip()
    relVelocity = bodyB.velocity - bodyA.velocity
    velAlongNormal = relVelocity.dotProduct(collisionA.normal)

  if velAlongNormal > 0:
    # Do not resolve if velocities are separating.
    # TODO: Return some useful value?
    continue

  template iMassA: float = bodyA.collisionShape.inverseMass
  template iMassB: float = bodyB.collisionShape.inverseMass
  let totalInverseMass = iMassA + iMassB

  # Calculate restitution.
  let e = min(bodyA.collisionShape.elasticity, bodyB.collisionShape.elasticity)

  # Calculate impuse scalar.
  let impulse = collisionA.normal * (-(1.0 + e) * velAlongNormal) / totalInverseMass

  if bodyB.kind != pbStatic:
    # Translate the bodies to the point of collision.
    bodyA.center += bodyA.velocity * deltaTime * collisionA.contactRatio
    bodyB.center += bodyB.velocity * deltaTime * (1.0 - collisionA.contactRatio)

    # Apply the impulse.
    bodyA.velocity -= impulse * iMassA
    bodyB.velocity += impulse * iMassB

    # Move the bodies the remainder of the time in the frame.
    # bodyA.center += bodyA.velocity * deltaTime * (1.0 - collisionA.contactRatio)
    # bodyB.center += bodyB.velocity * deltaTime * collisionA.contactRatio

  else:
    # Translate bodyA out of bodyB.

    # TODO: Extract these vars,
    # explore improving this,
    # and implement it in the above example as well?
    const
      slop = 0.1
      percent = 0.6

    if collisionA.intrusion > slop:
      let correction = (collisionA.intrusion - slop) / totalInverseMass
      bodyA.center += collisionA.normal * percent * correction * iMassA

    bodyA.center += bodyA.velocity * deltaTime * collisionA.contactRatio

    # Apply the impulse.
    bodyA.velocity -= impulse * iMassA

    # Move the body the remainder of the time in the frame.
    # bodyA.center += bodyA.velocity * deltaTime * (1.0 - collisionA.contactRatio)

template handleCollisions*(this: PhysicsLayer, deltaTime: float) =
  # TODO: Implement broad collision phase.
  for i, bodyA in this.physicsBodyChildren:
    if bodyA.kind == pbStatic or bodyA.collisionShape == nil or bodyA.collisionShape.mass <= 0:
      # Static bodies do not need to be checked,
      # but other bodies may collide with them.
      continue

    let moveVectorA = bodyA.velocity * deltaTime
    for j in countup(0, this.physicsBodyChildren.high):
      let bodyB = this.physicsBodyChildren[j]
      if bodyA == bodyB or bodyB.collisionShape == nil or bodyB.collisionShape.mass <= 0:
        # Don't collide with self.
        continue

      let collision = collides(
        bodyA.center,
        bodyA.collisionShape,
        moveVectorA,
        bodyB.center,
        bodyB.collisionShape,
        bodyB.velocity * deltaTime
      )

      if collision == nil:
        continue

      collision.resolve(bodyA, bodyB, deltaTime)

template applyForcesToBodies*(this: PhysicsLayer, deltaTime: float) =
  for body in this.physicsBodyChildren:
    if body.kind != pbStatic:
      # Apply forces to all non-static bodies.
      for force in body.forces:
        body.velocity += force * deltaTime

    # Clear forces every frame.
    if body.kind == pbDynamic and this.gravity != VECTOR_ZERO:
      # Re-apply gravity to dynamic bodies.
      body.forces = @[this.gravity]
    else:
      body.forces.setLen(0)

method update*(this: PhysicsLayer, deltaTime: float) =
  procCall Layer(this).update(deltaTime)
  this.applyForcesToBodies(deltaTime)
  this.handleCollisions(deltaTime)

PhysicsLayer.renderAsChildOf(Layer):
  for body in this.physicsBodyChildren:
    body.render(ctx)

