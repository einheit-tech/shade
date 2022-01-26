import macros

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

method addChildNow(this: PhysicsLayer, child: Node) =
  procCall Layer(this).addChildNow(child)
  if child of PhysicsBody:
    this.physicsBodyChildren.add((PhysicsBody) child)
    this.aabbTree.addObject((PhysicsBody) child)

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
      this.aabbTree.removeObject((PhysicsBody) child)
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
    bodyB.move(mtv.negate())
  elif bodyB.kind == pbStatic:
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

      if bodyA.kind == pbStatic and bodyB.kind == pbStatic:
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

      bodyA.notifyCollisionListeners(bodyB, collision, this.gravityNormal)
      bodyB.notifyCollisionListeners(bodyA, collision.invert(), this.gravityNormal)

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

method update*(this: PhysicsLayer, deltaTime: float, onChildUpdate: proc(child: Node) = nil) =
  procCall Layer(this).update(deltaTime)

  let subdividedDeltaTime = deltaTime / COLLISION_ITERATIONS
  for i in 1..COLLISION_ITERATIONS:
    this.handleCollisions(subdividedDeltaTime)

  this.applyForcesToBodies(deltaTime)

when defined(aabbtreeOutlines):
  PhysicsLayer.renderAsChildOf(Layer):
    this.aabbTree.render(ctx)

