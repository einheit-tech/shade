import
  collisionshape,
  collisionresult,
  ../mathutils

export
  collisionresult,
  collisionshape

func getOverlap(projectionA, projectionB: Vector): float =
  ## Returns the amount of overlap of the two projections.
  ## If the result is not positive, there is no overlap.
  return min(projectionA.y - projectionB.x, projectionB.y - projectionA.x)

func checkCollisionCircles(
  locA: Vector,
  circleA: Circle,
  locB: Vector,
  circleB: Circle
): CollisionResult =
  let
    dist = distance(locA, locB)
    radii = circleA.radius + circleB.radius

  if dist >= radii:
    return nil

  return newCollisionResult(
    radii - dist,
    normalize(circleA.center - circleB.center + locB - locA)
  )

func checkCollisionCircleAndPolygon(
  locA: Vector,
  circle: Circle,
  locB: Vector,
  poly: Polygon
): CollisionResult =
  # TODO: Can merge much of this code with checkCollisionPolygons.
  let
    circleToPoly = locB - locA
    circleProjAxes = circle.getCircleToPolygonProjectionAxes(poly, circleToPoly)
    polyProjAxes = poly.getPolygonProjectionAxes()

  var
    minOverlap = Inf
    collisionNormal: Vector = VECTOR_ZERO

  # Iterate through all the axes.
  for axis in polyProjAxes:
    # Find the projection of each hull on the current axis.
    let
      projA = circle.project(VECTOR_ZERO, axis)
      projB = poly.project(circleToPoly, axis)
      overlap = getOverlap(projA, projB)

    # No overlap, no collision.
    if overlap <= 0:
      return nil
    
    # There is an overlap on this axis.
    if overlap < minOverlap:
      minOverlap = overlap
      collisionNormal =
        # TODO: Sometimes this is incorrect (when circle is underneath).
        if (projA.x + projA.y) > (projB.x + projB.y):
          axis.negate()
        else:
          axis

  for axis in circleProjAxes:
    # Find the projection of each hull on the current axis.
    let
      projA = circle.project(circleToPoly, axis)
      projB = poly.project(VECTOR_ZERO, axis)
      overlap = getOverlap(projA, projB)

    # No overlap, no collision.
    if overlap <= 0:
      return nil
    
    # There is an overlap on this axis.
    if overlap < minOverlap:
      minOverlap = overlap
      collisionNormal =
        if (projA.x + projA.y) > (projB.x + projB.y):
          axis.negate()
        else:
          axis

  return newCollisionResult(
    minOverlap,
    collisionNormal
  )

func checkCollisionPolygons(
  locA: Vector,
  polyA: Polygon,
  locB: Vector,
  polyB: Polygon
): CollisionResult =
  let
    # Get the location of A relative to B (assume B is at origin)
    relativeLocation = locA - locB
    projectionAxesA = polyA.getPolygonProjectionAxes()
    numOfShapeAxesA = projectionAxesA.len
    projectionAxesB = polyB.getPolygonProjectionAxes()
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
      projA = polyA.project(relativeLocation, axis)
      projB = polyB.project(VECTOR_ZERO, axis)
      overlap = getOverlap(projA, projB)

    # No overlap, no collision.
    if overlap <= 0:
      return nil
    
    # There is an overlap on this axis.
    if overlap < minOverlap:
      minOverlap = overlap
      collisionNormal =
        if isA and (projA.x + projA.y) > (projB.x + projB.y):
          axis.negate()
        else:
          axis

  return newCollisionResult(
    minOverlap,
    collisionNormal
  )

proc collides*(
  locA: Vector,
  hullA: CollisionShape,
  locB: Vector,
  hullB: CollisionShape,
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

  case hullA.kind:
    of chkCircle:
      case hullB.kind:
        of chkCircle:
          return checkCollisionCircles(
            locA,
            hullA.circle,
            locB,
            hullB.circle
          )
        of chkPolygon:
          return checkCollisionCircleAndPolygon(
            locA,
            hullA.circle,
            locB,
            hullB.polygon
          )

    of chkPolygon:
      case hullB.kind:
        of chkCircle:
          return checkCollisionCircleAndPolygon(
            locB,
            hullB.circle,
            locA,
            hullA.polygon
          )
        of chkPolygon:
          return checkCollisionPolygons(
            locA,
            hullA.polygon,
            locB,
            hullB.polygon
          )
  
