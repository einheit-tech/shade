import
  layer,
  physicsbody,
  ../math/mathutils,
  ../math/collision/sat,
  ../math/collision/collisionresult

import ../util/timer

export
  layer,
  physicsbody

# TODO: Tune and make configurable.
const
  DEFAULT_GRAVITY* = vector(0, 577)
  COLLISION_ITERATIONS* = 20

type
  PhysicsLayer* = ref object of Layer
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
    bodiesAreNotSeparating = velAlongNormal > 0.0
    mtv = collision.getMinimumTranslationVector()

  # Translate bodies out of each other.
  if bodyA.kind == pbStatic:
    bodyB.center -= mtv
  elif bodyB.kind == pbStatic:
    bodyA.center += mtv
  else:
    bodyA.center += mtv * 0.5
    bodyB.center += mtv * -0.5

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
  # TODO: Implement broad collision phase.
  for i, bodyA in this.physicsBodyChildren:
    for j in countup(i + 1, this.physicsBodyChildren.high):
      let bodyB = this.physicsBodyChildren[j]
      if bodyA.kind == pbStatic and bodyB.kind == pbStatic:
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

      bodyA.notifyCollisionListeners(bodyB, collision)
      bodyB.notifyCollisionListeners(bodyA, collision)

template applyForcesToBodies*(this: PhysicsLayer, deltaTime: float) =
  for body in this.physicsBodyChildren:
    if body.kind == pbStatic:
      continue

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

method update*(this: PhysicsLayer, deltaTime: float) =
  procCall Layer(this).update(deltaTime)

  let subdividedDeltaTime = deltaTime / COLLISION_ITERATIONS
  for i in 1..COLLISION_ITERATIONS:
    this.handleCollisions(subdividedDeltaTime)

  this.applyForcesToBodies(deltaTime)

PhysicsLayer.renderAsChildOf(Layer):
  for body in this.physicsBodyChildren:
    body.render(ctx)

