## CollisionShapes are the shapes used to determine collisions between objects.
##
## The shape location is relative to its owner,
## so the shape should be centered around the origin (0, 0),
## if the goal is to center it on its owner for collisions.
##
## The CollisionShape's `center` property is NOT TAKEN INTO ACCOUNT.
##
## See: http://chipmunk-physics.net/release/ChipmunkLatest-Docs/#cpShape

import
  sdl2_nim/sdl_gpu,
  chipmunk7

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
    bounds: Rectangle
    case kind*: CollisionShapeKind
    of chkCircle:
      unscaledCircle: Circle
      scaledCircle: Circle
      circleCollisionShape*: CircleShape
    of chkPolygon:
      unscaledPolygon: Polygon
      scaledPolygon: Polygon
      polygonCollisionShape*: PolyShape

proc createScaledShape(this: CollisionShape, scale: DVec2)
proc getBounds*(this: CollisionShape): Rectangle

proc initPolygonCollisionShape*(shape: CollisionShape, polygon: Polygon) =
  # TODO: Document our compile time flags in our wiki/README.
  when defined(checkSafeCollisionShapes):
    if polygon.isClockwise():
      raise newException(Exception, "Polygon must be counter-clockwise!\n" & repr polygon)

  initNode(
    Node(shape),
    when defined(collisionoutlines):
      {loRender}
    else:
      {}
  )
  shape.unscaledPolygon = polygon
  shape.createScaledShape(shape.scale)

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
  shape.createScaledShape(shape.scale)

proc newCircleCollisionShape*(circle: Circle): CollisionShape =
  result = CollisionShape(kind: chkCircle)
  initCircleCollisionShape(result, circle)

template collisionShape(this: CollisionShape): Shape =
  case this.kind:
    of chkCircle:
      this.circleCollisionShape
    of chkPolygon:
      this.polygonCollisionShape

template elasticity*(this: CollisionShape): float =
  this.collisionShape.elasticity

proc `elasticity=`*(this: CollisionShape, elasticity: float) =
  this.collisionShape.elasticity = elasticity

template friction*(this: CollisionShape): float =
  ## Gets the coefficient of friction.
  this.collisionShape.friction

proc `friction=`*(this: CollisionShape, friction: float) =
  ## Sets the coefficient of friction.
  this.collisionShape.friction = friction

template mass*(this: CollisionShape): float =
  ## Gets the mass of the shape.
  this.collisionShape.mass

proc `mass=`*(this: CollisionShape, mass: float) =
  ## Sets the mass of the shape.
  this.collisionShape.mass = mass

proc `surfaceVelocity=`*(this: CollisionShape, velocity: DVec2) =
  this.collisionShape.surfaceVelocity = cast[Vect](velocity)

proc createScaledShape(this: CollisionShape, scale: DVec2) =
  case this.kind:
    of chkCircle:
      this.scaledCircle = this.unscaledCircle.getScaledInstance(scale)
    of chkPolygon:
      this.scaledPolygon = this.unscaledPolygon.getScaledInstance(scale)

method `scale=`*(this: CollisionShape, scale: DVec2) =
  ## Scales the underlying shapes.
  ## `attachToBody` must be called after scaling.
  procCall `scale=`(Node(this), scale)

  # Recreate scaled shapes
  this.createScaledShape(scale)

proc attachToBody*(this: CollisionShape, body: Body, material: Material) =
  case this.kind:
    of chkCircle:
      this.circleCollisionShape = newCircleShape(body, this.scaledCircle.radius, vzero)
      if body.mass == 0 and body.moment == 0:
        this.mass = material.density * this.scaledCircle.getArea()

    of chkPolygon:
      this.polygonCollisionShape = newPolyShape(
        body,
        cint this.scaledPolygon.len,
        cast[ptr Vect](this.scaledPolygon.vertices[0].addr),
        TransformIdentity,
        cfloat 0.0
      )

      if body.mass == 0 and body.moment == 0:
        this.mass = material.density * this.scaledPolygon.getArea()

  this.elasticity = material.elasticity
  this.friction = material.friction

proc addToSpace*(this: CollisionShape, space: Space) =
  ## Adds this collision shape to the given space.
  ## `attachToBody` must be call beforehand.
  discard space.addShape(this.collisionShape)

proc removeFromSpace*(this: CollisionShape, space: Space) =
  ## Removes the shape from the given space, if it exists in that space.
  let shape = this.collisionShape
  if shape == nil:
    raise newException(Exception, "nil underlying collision shape")

  # TODO: This isn't very efficient,
  # but `removeShape` just calls `abort()` otherwise.
  # Only other option is to fork Chipmunk2D.
  if space.containsShape(this.collisionShape):
    space.removeShape(shape)

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

proc destroy*(this: CollisionShape) =
  this.collisionShape.destroy()

proc stroke*(this: CollisionShape, ctx: Target, color: Color = RED) =
  case this.kind:
  of chkPolygon:
    this.unscaledPolygon.getScaledInstance(VEC2_METERS_TO_PIXELS).stroke(ctx, color)
    discard
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

