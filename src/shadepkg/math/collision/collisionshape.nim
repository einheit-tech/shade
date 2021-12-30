## CollisionShapes are the shapes used to determine collisions between objects.
##
## The shape location is relative to its owner,
## so the shape should be centered around the origin (0, 0).
## The CollisionShape's `center` property is NOT TAKEN INTO ACCOUNT.

import sdl2_nim/sdl_gpu

import
  ../../game/constants,
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

func getFarthest*(this: CollisionShape, direction: Vector): seq[Vector] =
  ## Gets the farthest point(s) of the CollisionHull in the direction of the vector.
  case this.kind:
    of chkCircle:
      return @[this.circle.center + direction.normalize() * this.circle.radius]
    of chkPolygon:
      return this.polygon.getFarthest(direction)

proc stroke*(this: CollisionShape, ctx: Target, color: Color = RED) =
  case this.kind:
  of chkPolygon:
    this.polygon.getScaledInstance(VEC2_METERS_TO_PIXELS).stroke(ctx, color)
  of chkCircle:
    this.circle.getScaledInstance(VEC2_METERS_TO_PIXELS).stroke(ctx, color)

proc fill*(this: CollisionShape, ctx: Target, color: Color) =
  case this.kind:
  of chkPolygon:
    this.polygon.getScaledInstance(VEC2_METERS_TO_PIXELS).fill(ctx, color)
  of chkCircle:
    this.circle.getScaledInstance(VEC2_METERS_TO_PIXELS).fill(ctx, color)

render(CollisionShape):
  this.stroke(ctx)

