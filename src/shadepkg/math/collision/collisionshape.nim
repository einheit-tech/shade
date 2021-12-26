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

  CollisionShape* = ref object of Node
    elasticity*: float
    friction*: float
    mass*: float

    material: Material
    bounds: Rectangle

    case kind*: CollisionShapeKind:
    of chkCircle:
      unscaledCircle: Circle
      scaledCircle: Circle
    of chkPolygon:
      unscaledPolygon: Polygon
      scaledPolygon: Polygon

proc setShapeScale(this: CollisionShape, scale: Vector)
proc getBounds*(this: CollisionShape): Rectangle

proc initPolygonCollisionShape*(shape: CollisionShape, polygon: Polygon) =
  initNode(
    Node(shape),
    when defined(collisionoutlines):
      {loRender}
    else:
      {}
  )
  shape.unscaledPolygon = polygon
  shape.setShapeScale(shape.scale)

proc newPolygonCollisionShape*(polygon: Polygon): CollisionShape =
  result = CollisionShape(kind: chkPolygon)
  initPolygonCollisionShape(result, polygon)

proc initCircleCollisionShape*(shape: CollisionShape, circle: Circle) =
  initNode(
    Node(shape),
    when defined(collisionoutlines):
      {loRender}
    else:
      {}
  )
  shape.unscaledCircle = circle
  shape.setShapeScale(shape.scale)

proc newCircleCollisionShape*(circle: Circle): CollisionShape =
  result = CollisionShape(kind: chkCircle)
  initCircleCollisionShape(result, circle)

method onCenterChanged*(this: CollisionShape) =
  procCall Node(this).onCenterChanged()
  case this.kind:
    of chkCircle:
      this.unscaledCircle.center = this.center
      this.scaledCircle.center = this.center
    of chkPolygon:
      this.unscaledPolygon = this.unscaledPolygon.getTranslatedInstance(
        this.center - this.unscaledPolygon.center
      )
      this.scaledPolygon = this.scaledPolygon.getTranslatedInstance(
        this.center - this.scaledPolygon.center
      )

proc setShapeScale(this: CollisionShape, scale: Vector) =
  ## Sets the scale of the internal shape.
  ## This scales from the size of the original shape.
  case this.kind:
    of chkCircle:
      this.scaledCircle = this.unscaledCircle.getScaledInstance(scale)
    of chkPolygon:
      this.scaledPolygon = this.unscaledPolygon.getScaledInstance(scale)

method `scale=`*(this: CollisionShape, scale: Vector) =
  ## Scales the underlying shapes.

  # Scale shapes before notifying children nodes.
  this.setShapeScale(scale)
  procCall `scale=`(Node(this), scale)

proc getBounds*(this: CollisionShape): Rectangle =
  if this.bounds == nil:
    case this.kind:
      of chkPolygon:
        this.bounds = this.scaledPolygon.getBounds()
      of chkCircle:
        this.bounds = this.scaledCircle.calcBounds()
  return this.bounds

template width*(this: CollisionShape): float =
  this.getBounds().width

template height*(this: CollisionShape): float =
  this.getBounds().height

func polygonGetFarthest(this: Polygon, direction: Vector): seq[Vector] =
  ## Gets the farthest point(s) of the Polygon in the direction of the vector.
  var max = NegInf
  for i in 0..<this.len:
    let vertex = this[i]
    # Normalize the numeric precision of the dot product.
    # NOTE: strformat will be much slower.
    let projection = round(direction.dotProduct(vertex), MaxFloatPrecision)
    # TODO: Is this logic correct?
    if projection >= max:
      if projection > max:
        max = projection
        result.setLen(0)
      result.add(vertex)

func getFarthest*(this: CollisionShape, direction: Vector): seq[Vector] =
  ## Gets the farthest point(s) of the CollisionHull in the direction of the vector.
  case this.kind:
    of chkCircle:
      return @[this.scaledCircle.center + direction.normalize() * this.scaledCircle.radius]
    of chkPolygon:
      return polygonGetFarthest(this.scaledPolygon, direction)

proc stroke*(this: CollisionShape, ctx: Target, color: Color = RED) =
  case this.kind:
  of chkPolygon:
    this.unscaledPolygon.getScaledInstance(VEC2_METERS_TO_PIXELS).stroke(ctx, color)
  of chkCircle:
    this.unscaledCircle.getScaledInstance(VEC2_METERS_TO_PIXELS).stroke(ctx, color)

proc fill*(this: CollisionShape, ctx: Target, color: Color) =
  case this.kind:
  of chkPolygon:
    this.unscaledPolygon.getScaledInstance(VEC2_METERS_TO_PIXELS).fill(ctx, color)
  of chkCircle:
    this.unscaledCircle.getScaledInstance(VEC2_METERS_TO_PIXELS).fill(ctx, color)

render(CollisionShape, Node):
  scale(1 / this.scale.x, 1 / this.scale.y, 1.0)

  this.stroke(ctx)

  if callback != nil:
    callback()

  scale(this.scale.x, this.scale.y, 1.0)

