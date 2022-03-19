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
  ../aabb,
  ../mathutils,
  ../../render/color

export
  circle,
  polygon

const
  DEFAULT_MATERIAL* = METAL
  aabbProjectionAxes = [vector(1, 0), vector(0, 1)]

type
  Shape = Circle|Polygon|AABB
  CollisionShapeKind* {.pure.} = enum
    CIRCLE
    POLYGON
    AABB

  CollisionShape* = ref object
    inverseMass: float

    material*: Material
    bounds: AABB

    case kind*: CollisionShapeKind:
    of CollisionShapeKind.CIRCLE:
      circle*: Circle
    of CollisionShapeKind.POLYGON:
      polygon*: Polygon
      polyProjectionAxes: seq[Vector]
    of CollisionShapeKind.AABB:
      aabb*: AABB
      aabbProjectionAxes: seq[Vector]

proc getBounds*(this: CollisionShape): AABB

template area*(this: CollisionShape): float =
  case this.kind:
    of CollisionShapeKind.POLYGON:
      this.polygon.area
    of CollisionShapeKind.CIRCLE:
      this.circle.area
    of CollisionShapeKind.AABB:
      this.aabb.getArea()

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
  elif shape is AABB:
    collisionShape.aabb = shape
  else:
    raise newException(Exception, "Unsupported shape: ", typeof shape)

  collisionShape.material = material
  collisionShape.mass = collisionShape.calculateMass()

proc newCollisionShape*(shape: Shape, material = DEFAULT_MATERIAL): CollisionShape =
  when shape is Circle:
    result = CollisionShape(kind: CollisionShapeKind.CIRCLE)
  elif shape is Polygon:
    result = CollisionShape(kind: CollisionShapeKind.POLYGON)
  elif shape is AABB:
    result = CollisionShape(kind: CollisionShapeKind.AABB)
  else:
    raise newException(Exception, "Unsupported shape: ", typeof shape)

  initCollisionShape(result, shape, material)

proc getBounds*(this: CollisionShape): AABB =
  if this.bounds == nil:
    case this.kind:
      of CollisionShapeKind.POLYGON:
        this.bounds = this.polygon.getBounds()
      of CollisionShapeKind.CIRCLE:
        this.bounds = this.circle.calcBounds()
      of CollisionShapeKind.AABB:
        this.bounds = this.aabb
  return this.bounds

template projectOnAxis*(circ: Circle, location, axis: Vector): Vector =
  let centerDot = axis.dotProduct(circ.center + location)
  vector(centerDot - circ.radius, centerDot + circ.radius)

template projectOnAxis*(this: openArray[Vector], location, axis: Vector): Vector =
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

template projectOnAxis*(this: Polygon, location, axis: Vector): Vector =
  this.vertices.projectOnAxis(location, axis)

template projectOnAxis*(this: AABB, location, axis: Vector): Vector =
  this.vertices.projectOnAxis(location, axis)

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

func getAABBProjectionAxes*(aabb: AABB): array[2, Vector] =
  # TODO: Need to check that we don't need vectors pointing in all 4 directions.
  return aabbProjectionAxes

func getCircleToPolygonProjectionAxes*(
  circle: Circle,
  poly: Polygon,
  circleToPoly: Vector
): seq[Vector] =
  for v in poly:
    result.add(normalize(v - circle.center + circleToPoly))

func getCircleToAABBProjectionAxes*(
  circle: Circle,
  aabb: AABB,
  circleToAABB: Vector
): seq[Vector] =
  for v in aabb:
    result.add(normalize(v - circle.center + circleToAABB))

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
    of CollisionShapeKind.CIRCLE:
      case otherShape.kind:
      of CollisionShapeKind.CIRCLE:
        return this.circle.getCircleToCircleProjectionAxes(otherShape.circle, toOther)
      of CollisionShapeKind.POLYGON:
        return this.circle.getCircleToPolygonProjectionAxes(otherShape.polygon, toOther)
      of CollisionShapeKind.AABB:
        return this.circle.getCircleToAABBProjectionAxes(otherShape.aabb, toOther)

    of CollisionShapeKind.POLYGON:
      if this.polyProjectionAxes.len == 0:
        this.polyProjectionAxes = this.polygon.getPolygonProjectionAxes()
      return this.polyProjectionAxes

    of CollisionShapeKind.AABB:
      return this.aabbProjectionAxes

template project*(this: CollisionShape, relativeLoc, axis: Vector): Vector =
  case this.kind:
  of CollisionShapeKind.POLYGON:
    this.polygon.projectOnAxis(relativeLoc, axis)
  of CollisionShapeKind.CIRCLE:
    this.circle.projectOnAxis(relativeLoc, axis)
  of CollisionShapeKind.AABB:
    this.aabb.projectOnAxis(relativeLoc, axis)

proc stroke*(this: CollisionShape, ctx: Target, color: Color = RED) =
  case this.kind:
  of CollisionShapeKind.POLYGON:
    this.polygon.stroke(ctx, color)
  of CollisionShapeKind.CIRCLE:
    this.circle.stroke(ctx, color)
  of CollisionShapeKind.AABB:
    this.aabb.stroke(ctx, color)

proc fill*(this: CollisionShape, ctx: Target, color: Color) =
  case this.kind:
  of CollisionShapeKind.POLYGON:
    this.polygon.fill(ctx, color)
  of CollisionShapeKind.CIRCLE:
    this.circle.fill(ctx, color)
  of CollisionShapeKind.AABB:
    this.aabb.fill(ctx, color)

render(CollisionShape):
  this.stroke(ctx)

