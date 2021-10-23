import chipmunk7

import 
  ../math/collision/collisionshape,
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

  PhysicsUpdateFunc* = proc(gravity: DVec2, damping: float, deltaTime: float)
  PhysicsBody* = ref object of Node
    collisionShape*: CollisionShape
    material: Material
    body: Body
    kind: BodyType

    space: Space
    physicsUpdateFunc: PhysicsUpdateFunc

    # lastContactNormal*: DVec2
    isOnGround: bool
    isOnWall: bool

proc setLastContactNormal(this: PhysicsBody, gravity: DVec2)
proc defaultVelocityUpdateFunc(this: PhysicsBody, body: Body, gravity: Vect, damping: Float, dt: Float) {.cdecl.}
method `onPhysicsUpdate=`*(this: PhysicsBody, onPhysicsUpdate: PhysicsUpdateFunc) {.base.}

proc initPhysicsBody*(
  physicsBody: var PhysicsBody,
  kind: PhysicsBodyKind,
  material: Material = ROCK,
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  centerX: float = 0.0,
  centerY: float = 0.0,
  mass: float = 0.0,
  momentOfInertia: float = 0.0
) =
  ## Leave mass and momentOfInertia as 0.0, unless you have a reason.
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
      # If you do so, it will recalculate and overwrite your custom mass value
      # when the shapes are added to the body.

      # TODO: Allow passing in values here.
      # If values are passed in, do NOT set the mass of the collision shape later!
      # This is how rotation is prevented (setting moment as INF here with mass-less shapes).
      physicsBody.body = newBody(mass, momentOfInertia)
    of pbStatic:
      physicsBody.body = newStaticBody()
    of pbKinematic:
      physicsBody.body = newKinematicBody()

  physicsBody.body.position = cast[Vect](physicsBody.center)
  physicsBody.body.userData = cast[pointer](physicsBody)

  # This initializes the default function.
  physicsBody.onPhysicsUpdate = nil

proc newPhysicsBody*(
  kind: PhysicsBodyKind,
  material: Material = ROCK,
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  centerX: float = 0.0,
  centerY: float = 0.0,
  mass: float = 0.0,
  momentOfInertia: float = 0.0,
): PhysicsBody =
  ## Creates a new PhysicsBody.
  ## Leave mass and momentOfInertia as 0.0, unless you have a reason.
  result = PhysicsBody()
  initPhysicsBody(
    result,
    kind,
    material,
    flags,
    centerX,
    centerY,
    mass,
    momentOfInertia
  )

proc initPlayerBody*(
  playerBody: var PhysicsBody,
  mass: float = 1.0,
  material: Material = ROCK,
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  centerX: float = 0.0,
  centerY: float = 0.0
) =
  ## Creates a new dynamic body with infinite inertia.
  ## This means the body will not rotate due to physics,
  ## and is commonly used for the player in 2d platformers.
  initPhysicsBody(
    playerBody,
    kind = pbDynamic,
    material = material,
    flags = flags,
    centerX = centerX,
    centerY = centerY,
    mass = mass,
    momentOfInertia = INF
  )

proc newPlayerBody*(
  mass: float = 1.0,
  material: Material = ROCK,
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  centerX: float = 0.0,
  centerY: float = 0.0
): PhysicsBody =
  ## Creates a new dynamic body with infinite inertia.
  ## This means the body will not rotate due to physics,
  ## and is commonly used for the player in 2d platformers.

  # Infinity inertia prevents the body from rotating due to physics.
  result = PhysicsBody()
  initPlayerBody(result, mass, material, flags, centerX, centerY)

proc `surfaceVelocity=`*(this: PhysicsBody, velocity: DVec2) =
  this.collisionShape.surfaceVelocity = velocity

template isOnGround*(this: PhysicsBody): bool =
  this.isOnGround

template isOnWall*(this: PhysicsBody): bool =
  this.isOnWall

template material*(this: PhysicsBody): Material =
  this.material

template `parent`(body: Body): PhysicsBody =
  cast[PhysicsBody](body.userData)

proc attachCollisionShapeToBody(this: PhysicsBody) =
  if this.collisionShape != nil:
    this.collisionShape.attachToBody(this.body, this.material)

proc defaultVelocityUpdateFunc(
  this: PhysicsBody,
  body: Body,
  gravity: Vect,
  damping: Float,
  dt: Float
) {.cdecl.} =
  body.updateVelocity(gravity, damping, dt)
  this.setLastContactNormal(cast[DVec2](gravity))
  this.x = body.position.x
  this.y = body.position.y
  this.rotation = body.angle.radToDeg()

method `onPhysicsUpdate=`*(this: PhysicsBody, onPhysicsUpdate: PhysicsUpdateFunc) {.base.} =
  this.physicsUpdateFunc = onPhysicsUpdate

  # Wire up chipmunk's velocityUpdateFunc
  this.body.velocityUpdateFunc =
    proc(body: Body, gravity: Vect, damping: Float, dt: Float) {.cdecl.} =
      let parent: PhysicsBody = body.parent
      parent.defaultVelocityUpdateFunc(body, gravity, damping, dt)
      if parent.physicsUpdateFunc != nil:
        parent.physicsUpdateFunc(cast[DVec2](gravity), damping, dt)

method `scale=`*(this: PhysicsBody, scale: DVec2) =
  procCall `scale=`(Node(this), scale)

  this.collisionShape.scale = scale

  if this.space != nil:
    # See http://chipmunk-physics.net/release/ChipmunkLatest-Docs/#CollisionCallbacks-PostStep
    discard this.space.addPostStepCallback(
      (proc (space: Space; key: pointer; data: pointer) {.cdecl.} =
        let this: PhysicsBody = cast[PhysicsBody](data)
        this.collisionShape.removeFromSpace(space)
        this.attachCollisionShapeToBody()
        this.collisionShape.addToSpace(space)
      ),
      cast[pointer](this.collisionShape),
      cast[pointer](this)
    )
  else:
    this.attachCollisionShapeToBody()

method onParentScaled*(this: PhysicsBody, parentScale: DVec2) =
  procCall Node(this).onParentScaled(parentScale)

  if this.space != nil:
    this.collisionShape.removeFromSpace(this.space)

  this.collisionShape.scale = this.scale * parentScale
  this.attachCollisionShapeToBody()

  if this.space != nil:
    this.collisionShape.addToSpace(this.space)

method velocity*(this: PhysicsBody): DVec2 {.base.} =
  return cast[DVec2](this.body.velocity)

method `velocity=`*(this: PhysicsBody, velocity: DVec2) {.base.} =
  this.body.velocity = cast[Vect](velocity)

method velocityX*(this: PhysicsBody): float {.base.} =
  this.body.velocity.x

method `velocityX=`*(this: PhysicsBody, x: float) {.base.} =
  this.body.velocity = cast[Vect](dvec2(x, this.velocity.y))

method velocityY*(this: PhysicsBody): float {.base.} =
  this.body.velocity.y

method `velocityY=`*(this: PhysicsBody, y: float) {.base.} =
  this.body.velocity = cast[Vect](dvec2(this.velocity.x, y))

method `angularVelocity=`*(this: PhysicsBody, velocity: float) {.base.} =
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

proc selectPlayerGroundNormal(body: Body; arbiter: Arbiter; data: pointer) {.cdecl.} =
  var normals = cast[ptr seq[DVec2]](data)
  let collisionNormal = arbiter.normal()
  normals[].add(cast[DVec2](collisionNormal))

proc setLastContactNormal(this: PhysicsBody, gravity: DVec2) =
  if this.body != nil:
    var normals: seq[DVec2] = @[]
    this.body.eachArbiter(
      BodyArbiterIteratorFunc(selectPlayerGroundNormal),
      cast[pointer](addr normals)
    )

    this.isOnGround = false
    this.isOnWall = false

    for normal in normals:
      if normal.dot(gravity) > 0:
        this.isOnGround = true
      elif normal.isPerpendicular(gravity):
        this.isOnWall = true

