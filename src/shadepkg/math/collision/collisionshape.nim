## CollisionShapes are the shapes used to determine collisions between objects.
##
## The shape location is relative to its owner,
## so the shape should be centered around the origin (0, 0).
## The CollisionShape's `center` property is NOT TAKEN INTO ACCOUNT.

import sdl2_nim/sdl_gpu

import
  ../../game/node,
  ../../game/material,
  ../circle,
  ../polygon,
  ../mathutils,
  ../../render/color

export
  circle,
  polygon

type
  CollisionShapeKind* = enum
    chkCircle
    chkPolygon

  CollisionShape* = ref object
    elasticity*: float
    friction*: float
    mass*: float

    material*: Material
    bounds: Rectangle

    case kind*: CollisionShapeKind:
    of chkCircle:
      circle: Circle
    of chkPolygon:
      polygon: Polygon

proc getBounds*(this: CollisionShape): Rectangle

proc initPolygonCollisionShape*(shape: CollisionShape, polygon: Polygon) =
  shape.polygon = polygon

proc newPolygonCollisionShape*(polygon: Polygon): CollisionShape =
  result = CollisionShape(kind: chkPolygon)
  initPolygonCollisionShape(result, polygon)

proc initCircleCollisionShape*(shape: CollisionShape, circle: Circle) =
  shape.circle = circle

proc newCircleCollisionShape*(circle: Circle): CollisionShape =
  result = CollisionShape(kind: chkCircle)
  initCircleCollisionShape(result, circle)

proc getBounds*(this: CollisionShape): Rectangle =
  if this.bounds == nil:
    case this.kind:
      of chkPolygon:
        this.bounds = this.polygon.getBounds()
      of chkCircle:
        this.bounds = this.circle.calcBounds()
  return this.bounds

template width*(this: CollisionShape): float =
  this.getBounds().width

template height*(this: CollisionShape): float =
  this.getBounds().height

func getCircleToCircleProjectionAxes(circleA, circleB: Circle, aToB: Vector): seq[Vector] =
  result.add(
    (circleB.center - circleA.center + aToB).normalize()
  )

func getPolygonProjectionAxes(poly: Polygon): seq[Vector] =
  ## Fills an array with the projection axes of the PolygonCollisionShape facing away from the shape.
  ## @param poly the Polygon of the PolygonCollisionShape.
  ## @returns The array of axes facing away from the shape.
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
    let axis: Vector = edge.perpendicular().normalize()
    result.add(if clockwise: axis.negate() else: axis)
    i.inc
    j.inc

func getCircleToPolygonProjectionAxes(
  circle: Circle,
  poly: Polygon,
  circleToPoly: Vector
): seq[Vector] =
  for i in 0..<poly.len:
    result.add(
      normalize((poly[i] - circle.center) - circleToPoly)
    )

func getProjectionAxes*(
  this: CollisionShape,
  otherShape: CollisionShape,
  toOther: Vector
): seq[Vector] =
  ## Generates projection axes facing away from this shape towards the given other shape.
  ## @param toOther A vector from this shape's reference frame to the other shape's reference frame.
  ## @param otherShape The collision shape being tested against.
  ## @return The array of axes.
  case this.kind:
    of chkCircle:
      case otherShape.kind:
      of chkCircle:
        return this.circle.getCircleToCircleProjectionAxes(otherShape.circle, toOther)
      of chkPolygon:
        return this.circle.getCircleToPolygonProjectionAxes(otherShape.polygon, toOther)

    of chkPolygon:
      case otherShape.kind:
      of chkCircle:
        return otherShape.circle.getCircleToPolygonProjectionAxes(this.polygon, toOther.negate())
      of chkPolygon:
        return this.polygon.getPolygonProjectionAxes()

func project*(this: CollisionShape, relativeLoc, axis: Vector): Vector =
  case this.kind:
  of chkPolygon:
    return this.polygon.project(relativeLoc, axis)
  of chkCircle:
    return this.circle.project(relativeLoc, axis)

func getFarthest*(this: CollisionShape, direction: Vector): seq[Vector] =
  ## Gets the farthest point(s) of the CollisionShape in the direction of the vector.
  case this.kind:
    of chkCircle:
      return @[this.circle.center + direction.normalize() * this.circle.radius]
    of chkPolygon:
      return this.polygon.getFarthest(direction)

proc stroke*(this: CollisionShape, ctx: Target, color: Color = RED) =
  case this.kind:
  of chkPolygon:
    this.polygon.stroke(ctx, color)
  of chkCircle:
    this.circle.stroke(ctx, color)

proc fill*(this: CollisionShape, ctx: Target, color: Color) =
  case this.kind:
  of chkPolygon:
    this.polygon.fill(ctx, color)
  of chkCircle:
    this.circle.fill(ctx, color)

render(CollisionShape):
  this.stroke(ctx)

