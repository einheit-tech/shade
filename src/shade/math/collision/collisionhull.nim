## CollisionHulls are the shapes used to determine collisions between objects.
##
## The hull location is relative to its owner,
## so the hull should be centered around the origin (0, 0),
## if the goal is to center it on its owner for collisions.

import
  math

import
  ../vector2,
  ../circle,
  ../polygon

export
  vector2,
  circle,
  polygon

type
  CollisionHullKind* = enum
    chkCirle
    chkPolygon

  CollisionHull* = ref object
    bounds: Rectangle
    case kind: CollisionHullKind
    of chkCirle:
      circle: Circle
    of chkPolygon:
      polygon: Polygon

proc newPolygonCollisionHull*(polygon: Polygon): CollisionHull =
  CollisionHull(kind: chkPolygon, polygon: polygon)

proc newCircleCollisionHull*(circle: Circle): CollisionHull =
  CollisionHull(kind: chkCirle, circle: circle)

proc getBounds*(this: CollisionHull): Rectangle =
  if this.bounds == nil:
    case this.kind:
    of chkCirle:
      this.bounds = newRectangle(
        this.circle.center.x - this.circle.radius,
        this.circle.center.y - this.circle.radius,
        this.circle.radius * 2,
        this.circle.radius * 2
      )
    of chkPolygon:
      this.bounds = this.polygon.getBounds()

  return this.bounds

proc getArea*(this: CollisionHull): float =
  case this.kind:
  of chkPolygon:
    return this.polygon.getArea()
  of chkCirle:
    return this.circle.getArea()

template width*(this: CollisionHull): float = this.getBounds().width
template height*(this: CollisionHull): float = this.getBounds().height

template center*(this: CollisionHull): Vector2 =
  case this.kind:
  of chkPolygon:
    this.polygon.center
  of chkCirle:
    this.circle.center

func getCircleToCircleProjectionAxes(circleA, circleB: Circle, aToB: Vector2): seq[Vector2] =
  result.add(
    (circleB.center - circleA.center + aToB)
    .normalize()
  )

func getPolygonProjectionAxes(poly: Polygon): seq[Vector2] =
  ## Fills an array with the projection axes of the PolygonCollisionHull facing away from the hull.
  ## @param poly the Polygon of the PolygonCollisionHull.
  ## @returns The array of axes facing away from the hull.
  let clockwise = poly.isClockwise()
  var
    i = 0
    j = 1
  while i < poly.len:
    let
      nextPoint = if j == poly.len: poly[0] else: poly[j]
      currentPoint = poly[i]
      edge = nextPoint - currentPoint
    if edge.getMagnitude() == 0f:
        continue
    let axis: Vector2 = edge.perpendicular().normalize()
    result.add(if clockwise: axis.negate() else: axis)
    i.inc
    j.inc

func getCircleToPolygonProjectionAxes(
  circle: Circle,
  poly: Polygon,
  circleToPoly: Vector2
): seq[Vector2] =
  for i in 0..<poly.len:
    result.add(
      normalize((poly[i] - circle.center) - circleToPoly)
    )

func getProjectionAxes*(
  this: CollisionHull,
  otherHull: CollisionHull,
  toOther: Vector2
): seq[Vector2] =
  ## Generates projection axes facing away from this hull towards the given other hull.
  ## @param toOther A vector from this hull's reference frame to the other hull's reference frame.
  ## @param otherHull The collision hull being tested against.
  ## @return The array of axes.
  case this.kind:
  of chkCirle:
    case otherHull.kind:
    of chkCirle:
      return this.circle.getCircleToCircleProjectionAxes(otherHull.circle, toOther)
    of chkPolygon:
      return this.circle.getCircleToPolygonProjectionAxes(otherHull.polygon, toOther)

  of chkPolygon:
    case otherHull.kind:
    of chkCirle:
      return otherHull.circle.getCircleToPolygonProjectionAxes(this.polygon, toOther.negate())
    of chkPolygon:
      return this.polygon.getPolygonProjectionAxes()

func project*(this: CollisionHull, relativeLoc, axis: Vector2): Vector2 =
  case this.kind:
  of chkPolygon:
    return this.polygon.project(relativeLoc, axis)
  of chkCirle:
    return this.circle.project(relativeLoc, axis)

func polygonGetFarthest(this: Polygon, direction: Vector2): seq[Vector2] =
  ## Gets the farthest point(s) of the Polygon in the direction of the vector.
  var max = NegInf
  for i in 0..<this.len:
    let vertex = this[i]
    # Normalize the numeric precision of the dot product.
    # NOTE: strformat will be much slower.
    let projection = round(direction.dotProduct(vertex), MaxFloatPrecision)
    if projection >= max:
      if projection > max:
        max = projection
        result.setLen(0)
      result.add(vertex)

func getFarthest*(this: CollisionHull, direction: Vector2): seq[Vector2] =
  ## Gets the farthest point(s) of the CollisionHull in the direction of the vector.
  case this.kind:
  of chkCirle:
    return @[this.circle.center + direction.normalize(this.circle.radius)];
  of chkPolygon:
    return this.polygon.polygonGetFarthest(direction)

proc rotate*(this: CollisionHull, deltaRotation: float) =
  case this.kind:
  of chkCirle:
    return
  of chkPolygon:
    this.polygon.rotate(deltaRotation)

proc render*(this: CollisionHull, offset: Vector2) =
  case this.kind:
  of chkPolygon:
    this.polygon.render(offset)
  of chkCirle:
    this.circle.render(offset)

