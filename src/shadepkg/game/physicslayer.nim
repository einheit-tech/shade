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
const DEFAULT_GRAVITY* = vector(0, 577)

type PhysicsLayer* = ref object of Layer
  gravity*: Vector
  physicsBodyChildren: seq[PhysicsBody]

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

template resolve(collision: CollisionResult, bodyA, bodyB: PhysicsBody) =
  ## Resolves a collision between two bodies.
  ## NOTE: Perfectly inelastic collisions are not calculated correctly,
  ## and some momentum will be added.
  let
    relVelocity = bodyB.velocity - bodyA.velocity
    velAlongNormal = relVelocity.dotProduct(collision.normal)

  template iMassA: float = bodyA.collisionShape.inverseMass
  template iMassB: float = bodyB.collisionShape.inverseMass
  let totalInverseMass = iMassA + iMassB

  # Calculate restitution.
  let e = min(bodyA.collisionShape.elasticity, bodyB.collisionShape.elasticity)

  # Calculate impuse scalar.
  let impulse = collision.normal * ((-(1.0 + e) * velAlongNormal) / totalInverseMass)

  if bodyB.kind == pbStatic:
    # Translate bodyA out of bodyB.
    bodyA.center += collision.getMinimumTranslationVector()
    bodyA.velocity -= impulse * iMassA
  elif bodyA.kind == pbStatic:
    # Translate bodyB out of bodyA.
    bodyB.center -= collision.getMinimumTranslationVector()
    bodyB.velocity += impulse * iMassB
  else:
    # Apply the impulse.
    bodyA.velocity -= impulse * iMassA
    bodyB.velocity += impulse * iMassB
    # Translate bodies out of each other.
    let massRatio = iMassA / totalInverseMass
    bodyA.center += collision.getMinimumTranslationVector() * massRatio
    bodyB.center += collision.getMinimumTranslationVector() * (massRatio - 1.0)

template handleCollisions*(this: PhysicsLayer, deltaTime: float) =
  # TODO: Implement broad collision phase.
  for i, bodyA in this.physicsBodyChildren:
    if bodyA.collisionShape == nil or bodyA.collisionShape.mass <= 0:
      # Static bodies do not need to be checked,
      # but other bodies may collide with them.
      continue

    for j in countup(i + 1, this.physicsBodyChildren.high):
      let bodyB = this.physicsBodyChildren[j]
      if 
        bodyA == bodyB or
        bodyB.collisionShape == nil or
        bodyB.collisionShape.mass <= 0 or
        bodyA.kind == pbStatic and bodyB.kind == pbStatic:
        # Don't collide with self,
        # objects without collision shapes,
        # or massless objects.
        continue

      let collision = collides(
        bodyA.center,
        bodyA.collisionShape,
        bodyB.center,
        bodyB.collisionShape
      )

      if collision == nil:
        continue

      collision.resolve(bodyA, bodyB)

template applyForcesToBodies*(this: PhysicsLayer, deltaTime: float) =
  for body in this.physicsBodyChildren:
    if body.kind != pbStatic:
      # Apply forces to all non-static bodies.
      for force in body.forces:
        body.velocity += force * deltaTime

    # Clear forces every frame.
    if body.kind == pbDynamic and this.gravity != VECTOR_ZERO:
      # Re-apply gravity to dynamic bodies.
      body.forces.setLen(1)
      body.forces[0] = this.gravity
    else:
      body.forces.setLen(0)

# TODO: Make this configurable,
# and changed CollisionShape so we can cache polygon projection axes.
const iterations = 32

method update*(this: PhysicsLayer, deltaTime: float) =
  procCall Layer(this).update(deltaTime)

  for i in 1..iterations:
    this.handleCollisions(deltaTime / iterations)

  this.applyForcesToBodies(deltaTime)

PhysicsLayer.renderAsChildOf(Layer):
  for body in this.physicsBodyChildren:
    body.render(ctx)

