## CollisionHulls are the shapes used to determine collisions between objects.
##
## The hull location is relative to its owner,
## so the hull should be centered around the origin (0, 0),
## if the goal is to center it on its owner for collisions.
import sdl2_nim/sdl_gpu

import
  ../../game/node,
  ../circle,
  ../polygon,
  ../mathutils,
  ../../render/color

export
  circle,
  polygon

type
  CollisionHullKind* = enum
    chkCircle
    chkPolygon

  CollisionHull* = ref object of Node
    bounds: Rectangle
    hullScale: Vec2
    case kind: CollisionHullKind
    of chkCircle:
      unscaledCircle: Circle
      scaledCircle: Circle
    of chkPolygon:
      unscaledPolygon: Polygon
      scaledPolygon: Polygon

proc getBounds*(this: CollisionHull): Rectangle

proc initPolygonCollisionHull*(hull: CollisionHull, polygon: Polygon) =
  initNode(
    Node(hull),
    when defined(collisionoutlines):
      {loRender}
    else:
      {}
  )
  hull.hullScale = VEC2_ONE
  hull.unscaledPolygon = polygon

proc newPolygonCollisionHull*(polygon: Polygon): CollisionHull =
  result = CollisionHull(kind: chkPolygon)
  initPolygonCollisionHull(result, polygon)

proc initCircleCollisionHull*(hull: CollisionHull, circle: Circle) =
  initNode(
    Node(hull),
    when defined(collisionoutlines):
      {loRender}
    else:
      {}
  )
  hull.hullScale = VEC2_ONE
  hull.unscaledCircle = circle

proc newCircleCollisionHull*(circle: Circle): CollisionHull =
  result = CollisionHull(kind: chkCircle)
  initCircleCollisionHull(result, circle)

template width*(this: CollisionHull): float = this.getBounds().width
template height*(this: CollisionHull): float = this.getBounds().height

template circle*(this: CollisionHull): Circle =
  if this.scaledCircle == nil:
    this.scaledCircle = this.unscaledCircle.getScaledInstance(this.hullScale)
  this.scaledCircle

template polygon*(this: CollisionHull): Polygon =
  if this.scaledPolygon == nil:
    this.scaledPolygon = this.unscaledPolygon.getScaledInstance(this.hullScale)
  this.scaledPolygon

method onParentScaled*(this: CollisionHull, parentScale: Vec2) =
  this.hullScale = parentScale
  # Invalidate the scaled shape when the hull is rescaled.
  case this.kind:
    of chkCircle:
      this.scaledCircle = nil
    of chkPolygon:
      this.scaledPolygon = nil

proc getBounds*(this: CollisionHull): Rectangle =
  if this.bounds == nil:
    case this.kind:
    of chkCircle:
      this.bounds = this.circle.calcBounds()
    of chkPolygon:
      this.bounds = this.polygon.getBounds()
  return this.bounds

proc getUnscaledBounds*(this: CollisionHull): Rectangle =
  case this.kind:
  of chkCircle:
    this.unscaledCircle.calcBounds()
  of chkPolygon:
    this.unscaledPolygon.getBounds()

proc getArea*(this: CollisionHull): float =
  case this.kind:
  of chkPolygon:
    return this.polygon.getArea()
  of chkCircle:
    return this.circle.getArea()

template center*(this: CollisionHull): Vec2 =
  case this.kind:
  of chkPolygon:
    this.polygon.center
  of chkCircle:
    this.circle.center

proc getCircleToCircleProjectionAxes(circleA, circleB: Circle, aToB: Vec2): seq[Vec2] =
  result.add(
    (circleB.center - circleA.center + aToB)
    .normalize()
  )

func getPolygonProjectionAxes(poly: Polygon): seq[Vec2] =
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
    if edge.length() == 0f:
      continue
    let axis: Vec2 = edge.perpendicular().normalize()
    result.add(if clockwise: axis.negate() else: axis)
    i.inc
    j.inc

func getCircleToPolygonProjectionAxes(
  circle: Circle,
  poly: Polygon,
  circleToPoly: Vec2
): seq[Vec2] =
  for i in 0..<poly.len:
    result.add(normalize(poly[i] - circle.center + circleToPoly))

proc getProjectionAxes*(
  this: CollisionHull,
  otherHull: CollisionHull,
  toOther: Vec2
): seq[Vec2] =
  ## Generates projection axes facing away from this hull towards the given other hull.
  ## @param otherHull The collision hull being tested against.
  ## @param toOther A vector from this hull's reference frame to the other hull's reference frame.
  ## @return The array of axes.
  case this.kind:
  of chkCircle:
    case otherHull.kind:
    of chkCircle:
      return this.circle.getCircleToCircleProjectionAxes(otherHull.circle, toOther)
    of chkPolygon:
      return this.circle.getCircleToPolygonProjectionAxes(otherHull.polygon, toOther)

  of chkPolygon:
    case otherHull.kind:
    of chkCircle, chkPolygon:
      return this.polygon.getPolygonProjectionAxes()

func project*(this: CollisionHull, relativeLoc, axis: Vec2): Vec2 =
  case this.kind:
  of chkPolygon:
    return this.polygon.project(relativeLoc, axis)
  of chkCircle:
    return this.circle.project(relativeLoc, axis)

func polygonGetFarthest(this: Polygon, direction: Vec2): seq[Vec2] =
  ## Gets the farthest point(s) of the Polygon in the direction of the vector.
  var max = NegInf
  for i in 0..<this.len:
    let vertex = this[i]
    # Normalize the numeric precision of the dot product.
    # NOTE: strformat will be much slower.
    let projection = round(direction.dot(vertex), MaxFloatPrecision)
    if projection >= max:
      if projection > max:
        max = projection
        result.setLen(0)
      result.add(vertex)

func getFarthest*(this: CollisionHull, direction: Vec2): seq[Vec2] =
  ## Gets the farthest point(s) of the CollisionHull in the direction of the vector.
  case this.kind:
  of chkCircle:
    return @[this.circle.center + direction.normalize(this.circle.radius)]
  of chkPolygon:
    return this.polygon.polygonGetFarthest(direction)

proc rotate*(this: CollisionHull, deltaRotation: float) =
  case this.kind:
  of chkCircle:
    return
  of chkPolygon:
    this.polygon.rotate(deltaRotation)

proc stroke*(this: CollisionHull, ctx: Target, color: Color = RED) =
  case this.kind:
  of chkPolygon:
    this.unscaledPolygon.stroke(ctx, color)
    discard
  of chkCircle:
    this.unscaledCircle.stroke(ctx, color)

proc fill*(this: CollisionHull, ctx: Target, color: Color) =
  case this.kind:
  of chkPolygon:
    this.unscaledPolygon.fill(ctx, color)
    discard
  of chkCircle:
    this.unscaledCircle.fill(ctx, color)

render(CollisionHull, Node):
  this.fill(ctx, GREEN)
  this.getUnscaledBounds().stroke(ctx)

  if callback != nil:
    callback()

