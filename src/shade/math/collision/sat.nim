import options
import
  collisionhull,
  collisionresult,
  ../vector2

export
  collisionresult,
  collisionhull

type MinMaxProjectionInterval* = object
  min: float
  minPoint: Vector2
  max: float
  maxPoint: Vector2

proc newMinMaxProjectionInterval*(
  min: float,
  minPoint: Vector2,
  max: float,
  maxPoint: Vector2
): MinMaxProjectionInterval =
  ## @param min
  ## @param minPoint
  ## @param max
  ## @param maxPoint
  MinMaxProjectionInterval(
    min: min,
    minPoint: minPoint,
    max: max,
    maxPoint: maxPoint
  )

func getMiddle*(this, interval: MinMaxProjectionInterval): MinMaxProjectionInterval =
  ## Gets the middle two projections of the 4 projections.
  let
    minInterval = if this.min > interval.min: this else: interval
    maxInterval = if this.max < interval.max: this else: interval
  return
    newMinMaxProjectionInterval(
      minInterval.min,
      minInterval.minPoint,
      maxInterval.max,
      maxInterval.maxPoint
    )

func projectionFrom*(vertices: seq[Vector2], axis: Vector2): MinMaxProjectionInterval =
  ## Calculates a min-max projection interval from the list of vertices and an axis.
  ## @param vertices:
  ##   The vertices to project.
  ## @param axis:
  ##   The axis to project the vertices upon.
  if vertices.len == 0:
    raise newException(
      Exception,
      "Vertices cannot be empty: " &
      "Vertices: " & vertices.repr &
      ", " &
      "Axis: " & axis.repr
    )

  var
    min = Inf
    max = NegInf
    minPoint: Option[Vector2]
    maxPoint: Option[Vector2]

  for vert in vertices:
    let value = vert.dotProduct(axis)
    if value < min:
      min = value
      minPoint = vert.option
    if value > max:
      max = value
      maxPoint = vert.option

  if minPoint.isNone or maxPoint.isNone:
    raise newException(
      Exception,
      "minPoint and/or maxPoint are null: make sure parameters are correct: " &
      "Vertices: " & vertices.repr &
      ", " &
      "Axis: " & axis.repr
    )

  return newMinMaxProjectionInterval(min, minPoint.get, max, maxPoint.get)

proc translateVertices(vertices: seq[Vector2], delta: Vector2): seq[Vector2] =
  for i in 0..<vertices.len:
    result.add(vertices[i] + delta)

func getContactPoint(
  ownerLoc: Vector2,
  ownerHull: CollisionHull,
  ownerContactNormal: Vector2,
  otherLoc: Vector2,
  otherHull: CollisionHull,
  otherContactNormal: Vector2
): Vector2 =
  ## Gets the contact point of the collision between the two touching hulls.
  ## The hulls must be translated to the point in which they are touching
  ## before being passed into this method.
  ##
  ## @param ownerLoc:
  ##   The location of the collision owner after being moved.
  ##
  ## @param ownerHull:
  ##   The shape of the collision owner.
  ##
  ## @param ownerContactNormal:
  ##   The contact normal relative to the collision owner.
  ##
  ## @param otherLoc:
  ##   The location of the other shape.
  ##
  ## @param otherHull:
  ##   The other collision shape.
  ##
  ## @param otherContactNormal:
  ##   The contact normal relative to the other shape.

  # Shape B
  let otherFarthestPoints =
    translateVertices(
      otherHull.getFarthest(otherContactNormal),
      otherLoc
    )
  # If the contact point is a vertex on shape B, return that point.
  if otherFarthestPoints.len == 1:
    return otherFarthestPoints[0]

  let ownerFarthestPoints =
    translateVertices(
      ownerHull.getFarthest(ownerContactNormal),
      ownerLoc
    )
  if ownerFarthestPoints.len == 1:
    return ownerFarthestPoints[0]

  # Two parallel sides collided with each other.
  # 1) Project points onto the perpendicular of the normal (the edge).
  # 2) Get the minimum and maximum points (2 points) for each shape.
  # 3) Compare the 4 points.
  # 4) Return the two "middle-most" points.

  # Get the vector perpendicular to the contact normal.
  let edge = ownerContactNormal.perpendicular()

  let
    # Get the projections of the points of the owner shape onto the edge.
    minMaxProjectionOwner = projectionFrom(ownerFarthestPoints, edge)
    # Get the projections of the points of the other shape onto the edge.
    minMaxProjectionOther = projectionFrom(otherFarthestPoints, edge)

  # Merge interval (finds the inner points)
  let mergeInterval = minMaxProjectionOther.getMiddle(minMaxProjectionOwner)
  return mergeInterval.minPoint + mergeInterval.maxPoint * 0.5

func getContactPoint(
  locA: Vector2,
  shapeA: CollisionHull,
  locB: Vector2,
  shapeB: CollisionHull,
  contactNormal: Vector2,
  isShapeA: bool
): Vector2 =
  ## Gets the contact point of the collision between the two touching hulls.
  ## The hulls must be translated to the point in which they are touching,
  ## before being passed into this function.
  ##
  ## @param locA:
  ##   The location of shape A after being moved.
  ##
  ## @param shapeA:
  ##   The (active) collision shape.
  ##
  ## @param locB:
  ##   The location of shape B.
  ##
  ## @param shapeB:
  ##   The (passive) collision shape.
  ##
  ## @param contactNormal:
  ##   The contact normal of the collision.
  ##
  ## @param isShapeA:
  ##   boolean Whether the contact normal is relative to A.

  # Resolve contact normals
  var
    contactNormalA: Vector2
    contactNormalB: Vector2
  if isShapeA:
    contactNormalA = contactNormal
    contactNormalB = contactNormal.negate()
  else:
    contactNormalA = contactNormal.negate()
    contactNormalB = contactNormal

  if isShapeA:
    return getContactPoint(locA, shapeA, contactNormalA, locB, shapeB, contactNormalB)
  else:
    # Flip the parameters to make the normal relative to shapeA.
    return getContactPoint(locB, shapeB, contactNormalB, locA, shapeA, contactNormalA)

func normalizeNormal(isA: bool, axis, projA, projB: Vector2): Vector2 =
  ## Generates a normal that is always pointing away from shape A.
  ##
  ## @param isA Whether the axis was provided from shape A or shape B.
  ## @param axis The projection axis from the shape (outward from shape).
  ## @param projA The projection of shape A onto the axis (relative to the axis direction)
  ## @param projB The projection of shape B onto the axis (relative to the axis direction)
  let
    centerProjA = (projA.x + projA.y) # * 0.5 (unneeded because we only compare)
    centerProjB = (projB.x + projB.y) # * 0.5 (unneeded because we only compare)
  return if isA == (centerProjA > centerProjB): axis.negate() else: axis

proc collides*(
  locA: Vector2,
  hullA: CollisionHull,
  moveVectorA: Vector2,
  locB: Vector2,
  hullB: CollisionHull,
  moveVectorB: Vector2
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
  ## @param moveVectorA:
  ##   The movement vector of collision hull A.
  ##
  ## @param locB:
  ##   The world location of the collision hull B.
  ##
  ## @param hullB:
  ##   The collision hull of the stationary object.
  ##
  ## @param moveVectorB:
  ##   The movement vector of collision hull B.
  ##
  ## @return:
  ##   A collision result containing information for collision resolution,
  ##   or nil if the collision hulls are not and will not collide.
  ##
  let
    # Get the location of A relative to B (assume B is at origin)
    relativeLocation = locA - locB
    # Get the move vector of A relative to B.
    relativeMoveVector = moveVectorA - moveVectorB

  # Calculate projection axes for both collision hulls
  let
    projectionAxesA = hullA.getProjectionAxes(hullB, relativeLocation)
    numOfShapeAxesA = projectionAxesA.len
    projectionAxesB = hullB.getProjectionAxes(hullA, relativeLocation)
    numOfShapeAxesB = projectionAxesB.len
    numOfAxes = numOfShapeAxesA + numOfShapeAxesB

  var
    isShapeA_MTV = true
    intrusion_MTV = Inf
    mtvNormal: Option[Vector2]
    isShapeA_Contact = true
    intrusion_Contact = 0f
    contactNormal: Option[Vector2]
    minExitTimeRatio = Inf
    maxEnterTimeRatio = NegInf

  # Iterate through all the axes.
  for i in 0..<numOfAxes:
    let isA = i < numOfShapeAxesA
    let axis = if isA: projectionAxesA[i] else: projectionAxesB[i - numOfShapeAxesA]
    # Find the projection of each hull on the current axis.
    let projA = hullA.project(relativeLocation, axis)
    let projB = hullB.project(VectorZero, axis)

    # Project the velocity on the current axis.
    let moveVectorProjection = relativeMoveVector.dotProduct(axis)
    var totalProjectionMinA = projA.x
    var totalProjectionMaxA = projA.y

    # Calculate contact time ratio
    var enterTimeRatio: float
    var exitTimeRatio: float
    if projA.x > projB.y:
      # A is to the right of B
      if moveVectorProjection >= 0:
        return nil

      enterTimeRatio = (projB.y - projA.x) / moveVectorProjection
      exitTimeRatio = (projB.x - projA.y) / moveVectorProjection
      totalProjectionMinA += moveVectorProjection
    elif projA.y < projB.x:
      # A is to the left of B
      if moveVectorProjection <= 0:
        return nil
      enterTimeRatio = (projB.x - projA.y) / moveVectorProjection
      exitTimeRatio = (projB.y - projA.x) / moveVectorProjection
      totalProjectionMaxA += moveVectorProjection
    else:
      # A is intersecting B (already)
      if moveVectorProjection > 0:
        enterTimeRatio = (projB.x - projA.y) / moveVectorProjection
        exitTimeRatio = (projB.y - projA.x) / moveVectorProjection
        totalProjectionMaxA += moveVectorProjection
      elif moveVectorProjection < 0:
        enterTimeRatio = (projB.y - projA.x) / moveVectorProjection
        exitTimeRatio = (projB.x - projA.y) / moveVectorProjection
        totalProjectionMinA += moveVectorProjection
      else:
        enterTimeRatio = NegInf
        exitTimeRatio = Inf

    if enterTimeRatio > 1.0:
      # Polygons are not intersecting and will not intersect.
      return nil

    # Calculate intrusion
    let
      rightOverlap = totalProjectionMaxA - projB.x
      leftOverlap = projB.y - totalProjectionMinA
      # Get the minimum overlap distance along the axis
      overlap = min(rightOverlap, leftOverlap)

    if overlap < intrusion_MTV:
      intrusion_MTV = overlap
      mtvNormal = normalizeNormal(isA, axis, projA, projB).option
      isShapeA_MTV = isA

    minExitTimeRatio = min(minExitTimeRatio, exitTimeRatio)

    if enterTimeRatio > maxEnterTimeRatio:
      maxEnterTimeRatio = enterTimeRatio
      intrusion_Contact = overlap
      contactNormal = normalizeNormal(isA, axis, projA, projB).option
      isShapeA_Contact = isA

  if maxEnterTimeRatio <= minExitTimeRatio:
    if contactNormal.isSome:
      # Dynamic collision
      let moveVectorDot = contactNormal.get.dotProduct(relativeMoveVector)
      if moveVectorDot != 0:
        # Calculate the location of hullA at time of collision
        let collisionLocA = locA + (relativeMoveVector * maxEnterTimeRatio)
        return newCollisionResult(
          isShapeA_Contact,
          intrusion_Contact,
          contactNormal.get,
          getContactPoint(collisionLocA, hullA, locB, hullB, contactNormal.get, isShapeA_Contact),
          maxEnterTimeRatio
        )
    elif mtvNormal.isSome:
      # Static collision
      return newCollisionResult(
        isShapeA_MTV,
        intrusion_MTV,
        mtvNormal.get,
        getContactPoint(locA, hullA, locB, hullB, mtvNormal.get, isShapeA_Contact)
      )
  # No collision
  return nil

