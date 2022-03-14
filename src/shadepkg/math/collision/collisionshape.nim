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

const DEFAULT_MATERIAL* = METAL

type
  Shape = Circle|Polygon
  CollisionShapeKind* = enum
    chkCircle
    chkPolygon

  CollisionShape* = ref object
    inverseMass: float

    material*: Material
    bounds: Rectangle

    case kind*: CollisionShapeKind:
    of chkCircle:
      circle*: Circle
    of chkPolygon:
      polygon*: Polygon
      projectionAxes: seq[Vector]

proc getBounds*(this: CollisionShape): Rectangle

template area*(this: CollisionShape): float =
  case this.kind:
    of chkPolygon:
      this.polygon.area
    of chkCircle:
      this.circle.area

template width*(this: CollisionShape): float =
  this.getBounds().width

template height*(this: CollisionShape): float =
  this.getBounds().height

template calculateMass(this: CollisionShape): float =
  this.area * this.density

template inverseMass*(this: CollisionShape): float =
  this.inverseMass

template mass*(this: CollisionShape): float =
  if this.inverseMass == 0:
    0.0
  else:
    1.0 / this.inverseMass

template `mass=`*(this: CollisionShape, mass: float) =
  ## Sets the mass of the object.
  ## Should be for internal use only, for calculations.
  if mass == 0:
    this.inverseMass = 0.0
  else:
    this.inverseMass = 1.0 / mass

template elasticity*(this: CollisionShape): float =
  this.material.elasticity

template `elasticity=`*(this: CollisionShape, e: CompletionRatio) =
  this.material.elasticity = e

template density*(this: CollisionShape): float =
  this.material.density

template `density=`*(this: CollisionShape, density: CompletionRatio) =
  this.material.density = density
  this.mass = this.calculateMass()

template friction*(this: CollisionShape): float =
  this.material.friction

template `friction=`*(this: CollisionShape, friction: CompletionRatio) =
  this.material.friction = friction

proc initCollisionShape*(collisionShape: CollisionShape, shape: Shape, material = DEFAULT_MATERIAL) =
  when shape is Circle:
    collisionShape.circle = shape
  elif shape is Polygon:
    collisionShape.polygon = shape
  else:
    raise newException(Exception, "Unsupported shape: ", typeof shape)

  collisionShape.material = material
  collisionShape.mass = collisionShape.calculateMass()

proc newCollisionShape*(shape: Shape, material = DEFAULT_MATERIAL): CollisionShape =
  when shape is Circle:
    result = CollisionShape(kind: chkCircle)
  elif shape is Polygon:
    result = CollisionShape(kind: chkPolygon)
  else:
    raise newException(Exception, "Unsupported shape: ", typeof shape)

  initCollisionShape(result, shape, material)

proc getBounds*(this: CollisionShape): Rectangle =
  if this.bounds == nil:
    case this.kind:
      of chkPolygon:
        this.bounds = this.polygon.getBounds()
      of chkCircle:
        this.bounds = this.circle.calcBounds()
  return this.bounds

template projectOnAxis*(circ: Circle, location, axis: Vector): Vector =
  let centerDot = axis.dotProduct(circ.center + location)
  vector(centerDot - circ.radius, centerDot + circ.radius)

template projectOnAxis*(this: Polygon, location, axis: Vector): Vector =
  let startLoc = this[0] + location
  var
    dotProduct = axis.dotProduct(startLoc)
    projection = vector(dotProduct, dotProduct)

  for i in 1..<this.len:
    let currLoc = this[i] + location
    dotProduct = axis.dotProduct(currLoc)
    if dotProduct < projection.x:
      projection.x = dotProduct
    if dotProduct > projection.y:
      projection.y = dotProduct

  projection

func getCircleToCircleProjectionAxes*(circleA, circleB: Circle, relativeLoc: Vector): seq[Vector] =
  result.add(
    (circleB.center - circleA.center + relativeLoc).normalize()
  )

func getPolygonProjectionAxes*(poly: Polygon): seq[Vector] =
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
    if edge.getMagnitude() == 0.0:
        continue
    let axis: Vector = edge.perpendicular().normalize()
    result.add(if clockwise: axis.negate() else: axis)
    i.inc
    j.inc

func getCircleToPolygonProjectionAxes*(
  circle: Circle,
  poly: Polygon,
  circleToPoly: Vector
): seq[Vector] =
  for v in poly:
    result.add(normalize(v - circle.center + circleToPoly))

func getProjectionAxes*(
  this: CollisionShape,
  otherShape: CollisionShape,
  toOther: Vector
): seq[Vector] =
  ## Generates projection axes facing away from this shape towards the given other shape.
  ## @param otherShape The collision shape being tested against.
  ## @param toOther A vector from this shape's reference frame to the other shape's reference frame.
  ## @return The array of axes.
  case this.kind:
    of chkCircle:
      case otherShape.kind:
      of chkCircle:
        return this.circle.getCircleToCircleProjectionAxes(otherShape.circle, toOther)
      of chkPolygon:
        return this.circle.getCircleToPolygonProjectionAxes(otherShape.polygon, toOther)

    of chkPolygon:
      if this.projectionAxes.len == 0:
        this.projectionAxes = this.polygon.getPolygonProjectionAxes()
      return this.projectionAxes

template project*(this: CollisionShape, relativeLoc, axis: Vector): Vector =
  case this.kind:
  of chkPolygon:
    this.polygon.projectOnAxis(relativeLoc, axis)
  of chkCircle:
    this.circle.projectOnAxis(relativeLoc, axis)

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

