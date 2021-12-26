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
    ## A body controlled by applied forces.
    pbDynamic,
    ## A body that does not move based on forces, collisions, etc.
    ## Mainly used for terrain, moving platforms, and the like.
    pbStatic,
    ## A body which is controlled by code, rather than the physics engine.
    ## TODO: More docs about Kinematic bodies
    pbKinematic

  PhysicsBody* = ref object of Node
    # TODO: PhysicsBodies need to support multiple CollisionShapes at some point.
    collisionShape*: CollisionShape
    material*: Material
    velocity*: Vector
    ## Total force applied to the center of mass.
    force*: Vector
    angularVelocity*: float

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

method `scale=`*(this: PhysicsBody, scale: Vector) =
  procCall `scale=`(Node(this), scale)
  this.collisionShape.scale = scale

method onParentScaled*(this: PhysicsBody, parentScale: Vector) =
  procCall Node(this).onParentScaled(parentScale)
  this.collisionShape.scale = this.scale * parentScale

method velocityX*(this: PhysicsBody): float {.base.} =
  this.velocity.x

method `velocityX=`*(this: PhysicsBody, x: float) {.base.} =
  this.velocity = vector(x, this.velocity.y)

method velocityY*(this: PhysicsBody): float {.base.} =
  this.velocity.y

method `velocityY=`*(this: PhysicsBody, y: float) {.base.} =
  this.velocity = vector(this.velocity.x, y)

method onChildAdded*(this: PhysicsBody, child: Node) =
  procCall Node(this).onChildAdded(child)
  if child of CollisionShape:
    this.collisionShape = CollisionShape(child)

