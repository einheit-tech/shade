import chipmunk7

import 
  ../math/collision/collisionshape,
  ../render/color,
  material,
  node

export
  node,
  material,
  collisionshape

type
  PhysicsBodyKind* = enum
    pbDynamic,
    pbStatic,
    pbKinematic

  PhysicsBody* = ref object of Node
    space: Space
    collisionShape*: CollisionShape
    material: Material
    body: Body
    kind: BodyType

proc initPhysicsBody*(
  physicsBody: PhysicsBody,
  kind: PhysicsBodyKind,
  material: Material = ROCK,
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  centerX: float = 0.0,
  centerY: float = 0.0
) =
  initNode(Node(physicsBody), flags, centerX, centerY)
  physicsBody.kind = 
    case kind:
      of pbDynamic:
        BODY_TYPE_DYNAMIC
      of pbStatic:
        BODY_TYPE_STATIC
      of pbKinematic:
        BODY_TYPE_KINEMATIC

  physicsBody.material = material

  case kind:
    of pbDynamic:
      # NOTE: http://chipmunk-physics.net/release/ChipmunkLatest-Docs/#cpBody-DynamicBodies
      # There are two ways to set up a dynamic body.
      # The easiest option is to create a body with a mass and moment of 0,
      # and set the mass or density of each collision shape added to the body.
      # Chipmunk will automatically calculate the mass, moment of inertia,
      # and center of gravity for you.
      # This is probably preferred in most cases.

      # The other option is to set the mass of the body when it’s created,
      # and leave the mass of the shapes added to it as 0.0.
      # This approach is more flexible, but is not as easy to use.
      # Don’t set the mass of both the body and the shapes.
      # If you do so, it will recalculate and overwite your custom mass value
      # when the shapes are added to the body.
      physicsBody.body = newBody(0, 0)
    of pbStatic:
      physicsBody.body = newStaticBody()
    of pbKinematic:
      physicsBody.body = newKinematicBody()

  physicsBody.body.position = cast[Vect](physicsBody.center)

proc newPhysicsBody*(
  kind: PhysicsBodyKind,
  material: Material = ROCK,
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  centerX: float = 0.0,
  centerY: float = 0.0
): PhysicsBody =
  ## Creates a new PhysicsBody.
  result = PhysicsBody()
  initPhysicsBody(
    result,
    kind,
    material,
    flags,
    centerX,
    centerY
  )

proc attachCollisionShapeToBody(this: PhysicsBody) =
  if this.collisionShape != nil:
    this.collisionShape.attachToBody(this.body, this.material)

method `scale=`*(this: PhysicsBody, scale: DVec2) =
  procCall `scale=`(Node(this), scale)

  if this.space != nil:
    this.collisionShape.removeFromSpace(this.space)

  this.collisionShape.scale = scale
  this.attachCollisionShapeToBody()

  if this.space != nil:
    this.collisionShape.addToSpace(this.space)

method onParentScaled*(this: PhysicsBody, parentScale: DVec2) =
  procCall Node(this).onParentScaled(parentScale)

  if this.space != nil:
    this.collisionShape.removeFromSpace(this.space)

  this.collisionShape.scale = this.scale * parentScale
  this.attachCollisionShapeToBody()

  if this.space != nil:
    this.collisionShape.addToSpace(this.space)

proc velocity*(this: PhysicsBody): DVec2 =
  return dvec2(
    this.body.velocity.x,
    this.body.velocity.y
  )

proc `velocity=`*(this: PhysicsBody, velocity: DVec2) =
  this.body.velocity = cast[Vect](velocity)

proc `angularVelocity=`*(this: PhysicsBody, velocity: float) =
  this.body.angularVelocity = cfloat velocity

method `rotation=`*(this: PhysicsBody, rotation: float) =
  procCall `rotation=`(Node(this), rotation)
  this.body.angle = this.rotation.degToRad()

proc setVelocityDampening*(this: PhysicsBody, damping: float, dt: float) =
  this.body.updateVelocity(vzero, damping, dt)

method onChildAdded*(this: PhysicsBody, child: Node) =
  procCall Node(this).onChildAdded(child)
  if child of CollisionShape:
    let shape = CollisionShape(child)
    this.collisionShape = shape
    shape.attachToBody(this.body, this.material)

proc addToSpace*(this: PhysicsBody, space: Space) =
  when defined(debug):
    if this.collisionshape == nil:
      raise newException(Exception, "Nil collision shape!")

  if this.space != nil:
    this.collisionShape.removeFromSpace(this.space)

  this.space = space
  this.collisionShape.addToSpace(this.space)
  discard this.space.addBody(this.body)
  this.body.position = cast[Vect](this.center)

proc destroy*(this: PhysicsBody) =
  if this.collisionShape != nil:
    this.collisionShape.destroy()
  if this.body != nil:
    this.body.destroy()

method update*(this: PhysicsBody, deltaTime: float) =
  procCall Node(this).update(deltaTime)
  this.x = this.body.position.x
  this.y = this.body.position.y
  this.rotation = this.body.angle.radToDeg()

