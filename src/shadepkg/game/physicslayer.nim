{.experimental: "codeReordering".}

import
  layer,
  physicsbody,
  ../math/collision/spatialgrid as sgrid,
  ../math/collision/sat,
  ../math/mathutils

export
  layer,
  physicsbody,
  sgrid,
  sat

type
  CollisionListener* = proc(collisionOwner, collided: PhysicsBody, result: CollisionResult)
  PhysicsLayer* = ref object of Layer
    spatialGrid*: SpatialGrid
    collisionListeners: seq[CollisionListener]

proc newPhysicsLayer*(grid: SpatialGrid, z: float = 1.0): PhysicsLayer =
  result = PhysicsLayer(spatialGrid: grid)
  result.z = z

method addCollisionListener*(this: PhysicsLayer, listener: CollisionListener) {.base.} =
  this.collisionListeners.add(listener)

method removeCollisionListener*(this: PhysicsLayer, listener: CollisionListener) {.base.} =
  for i, l in this.collisionListeners:
    if l == listener:
      this.collisionListeners.delete(i)
      break

method removeAllCollisionListeners*(this: PhysicsLayer) {.base.} =
  this.collisionListeners.setLen(0)

proc detectCollisions(this: PhysicsLayer, deltaTime: float) =
  ## Detects collisions between all objects in the spatial grid.
  ## When a collision occurs, all CollisionListeners will be notified.
  if this.collisionListeners.len == 0:
    return

  # Perform collision checks.
  for objA in this.spatialGrid:
    # Active body information.
    let
      locA = objA.center
      hullA = objA.collisionHull
      boundsA = objA.bounds()
      moveVectorA = objA.velocity * deltaTime

    let (objectsInBounds, cells) = this.spatialGrid.query(boundsA)
    # Iterate through collidable objects to check for collisions with the local object (objA).
    for objB in objectsInBounds:

      # Don't collide with yourself, dummy.
      if objA == objB:
        continue

      # Passive entity information.
      let
        locB = objB.center
        hullB = objB.collisionHull
        moveVectorB = objB.velocity * deltaTime

      # Get collision result.
      let collisionResult =
        sat.collides(
          locA,
          hullA,
          moveVectorA,
          locB,
          hullB,
          moveVectorB
        )

      if collisionResult == nil:
        continue

      # Notify collision listeners.
      for listener in this.collisionListeners:
        listener(objA, objB, collisionResult)

    # Remove the object so we don't have duplicate collision checks.
    this.spatialGrid.removeFromCells(objA, cells)

method update*(this: PhysicsLayer, deltaTime: float) =
  procCall Layer(this).update(deltaTime)

  # Add all entities to the spatial grid.
  for entity in this:
    if entity of PhysicsBody and loPhysics in entity.flags:
      this.spatialGrid.addBody(PhysicsBody entity, entity.lastMoveVector)

  # Detect collisions using the data in the spatial grid.
  # All listeners are notified.
  this.detectCollisions(deltaTime)

  # Remove everything from the grid.
  this.spatialGrid.clear()

