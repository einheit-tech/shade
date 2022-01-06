import
  collisionshape,
  collisionresult,
  ../mathutils

export
  collisionresult,
  collisionshape

template getOverlap(projectionA, projectionB: Vector): float =
  ## Returns the amount of overlap of the two projections.
  ## If the result is not positive, there is no overlap.
  min(projectionA.y - projectionB.x, projectionB.y - projectionA.x)

func collides*(
  locA: Vector,
  hullA: CollisionShape,
  locB: Vector,
  hullB: CollisionShape
): CollisionResult =
  ## Performs the SAT algorithm on the given collision hulls
  ## to determine whether they are colliding or will collide.
  ##
  ## All locations and move vectors are relative to hullB.
  ##
  ## @param locA:
  ##   The world location of collision hull A.
  ##
  ## @param hullA:
  ##   The collision hull of the moving object.
  ##
  ## @param locB:
  ##   The world location of the collision hull B.
  ##
  ## @param hullB:
  ##   The collision hull of the stationary object.
  ##
  ## @return:
  ##   A collision result containing information for collision resolution,
  ##   or nil if the collision hulls are not and will not collide.
  ##
  let
    # Get the location of A relative to B (assume B is at origin)
    relativeLocation = locA - locB
    projectionAxesA = hullA.getProjectionAxes(hullB, relativeLocation)
    numOfShapeAxesA = projectionAxesA.len
    projectionAxesB = hullB.getProjectionAxes(hullA, relativeLocation)
    numOfShapeAxesB = projectionAxesB.len
    numOfAxes = numOfShapeAxesA + numOfShapeAxesB

  var
    minOverlap = Inf
    collisionNormal: Vector = VECTOR_ZERO

  # Iterate through all the axes.
  for i in 0 ..< numOfAxes:
    let isA = i < numOfShapeAxesA
    let axis = if isA: projectionAxesA[i] else: projectionAxesB[i - numOfShapeAxesA]

    # Find the projection of each hull on the current axis.
    let
      projA = hullA.project(relativeLocation, axis)
      projB = hullB.project(VECTOR_ZERO, axis)
      overlap = getOverlap(projA, projB)

    # No overlap, no collision.
    if overlap <= 0:
      return nil
    
    # There is an overlap on this axis.
    if overlap < minOverlap:
      minOverlap = overlap
      # TODO: Is there a way to optimize this?
      collisionNormal =
        if isA:
          if (projA.x + projA.y) > (projB.x + projB.y):
            axis
          else:
            axis.negate()
        elif (projA.x + projA.y) < (projB.x + projB.y):
          axis.negate()
        else:
          axis

  return newCollisionResult(
    minOverlap,
    collisionNormal
  )

