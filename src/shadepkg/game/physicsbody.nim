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
    # TODO: Define what these mean.
    pbDynamic,
    pbStatic,
    pbKinematic

  PhysicsBody* = ref object of Node
    # TODO: PhysicsBodies need to support multiple CollisionShapes at some point.
    collisionShape*: CollisionShape
    material*: Material

    case kind*: PhysicsBodyKind:
      of pbDynamic, pbKinematic:
        isOnGround*: bool
        isOnWall*: bool
      of pbStatic:
        discard

proc initPhysicsBody*(
  physicsBody: var PhysicsBody,
  material: Material = ROCK,
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  centerX: float = 0.0,
  centerY: float = 0.0
) =
  initNode(Node(physicsBody), flags, centerX, centerY)
  physicsBody.material = material

proc newPhysicsBody*(
  kind: PhysicsBodyKind,
  material: Material = ROCK,
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  centerX: float = 0.0,
  centerY: float = 0.0
): PhysicsBody =
  ## Creates a new PhysicsBody.
  result = PhysicsBody(kind: kind)
  initPhysicsBody(
    result,
    material,
    flags,
    centerX,
    centerY
  )

template width*(this: PhysicsBody): float =
  if this.collisionShape != nil:
    this.collisionShape.width()
  else:
    0

template height*(this: PhysicsBody): float =
  if this.collisionShape != nil:
    this.collisionShape.height()
  else:
    0

method `center=`*(this: PhysicsBody, center: DVec2) =
  procCall `center=`(Node(this), center)
  this.body.position = center

method `scale=`*(this: PhysicsBody, scale: DVec2) =
  procCall `scale=`(Node(this), scale)
  this.collisionShape.scale = scale

method onParentScaled*(this: PhysicsBody, parentScale: DVec2) =
  procCall Node(this).onParentScaled(parentScale)
  this.collisionShape.scale = this.scale * parentScale

method velocity*(this: PhysicsBody): DVec2 {.base.} =
  return this.body.velocity

method `velocity=`*(this: PhysicsBody, velocity: DVec2) {.base.} =
  this.body.velocity = velocity

method velocityX*(this: PhysicsBody): float {.base.} =
  this.body.velocity.x

method `velocityX=`*(this: PhysicsBody, x: float) {.base.} =
  this.body.velocity = dvec2(x, this.velocity.y)

method velocityY*(this: PhysicsBody): float {.base.} =
  this.body.velocity.y

method `velocityY=`*(this: PhysicsBody, y: float) {.base.} =
  this.body.velocity = dvec2(this.velocity.x, y)

method `angularVelocity=`*(this: PhysicsBody, velocity: float) {.base.} =
  this.body.angularVelocity = cfloat velocity

method `force=`*(this: PhysicsBody, force: DVec2) {.base.} =
  this.body.force = force

method `rotation=`*(this: PhysicsBody, rotation: float) =
  procCall `rotation=`(Node(this), rotation)
  this.body.angle = this.rotation.degToRad()

method onChildAdded*(this: PhysicsBody, child: Node) =
  procCall Node(this).onChildAdded(child)
  if child of CollisionShape:
    this.collisionShape = CollisionShape(child)

