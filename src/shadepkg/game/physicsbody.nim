import 
  ../math/collision/collisionshape,
  node

export
  node,
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
    collisionShape: CollisionShape
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
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  centerX: float = 0.0,
  centerY: float = 0.0
) =
  initNode(Node(physicsBody), flags, centerX, centerY)

proc newPhysicsBody*(
  kind: PhysicsBodyKind,
  flags: set[LayerObjectFlags] = {loUpdate, loRender},
  centerX: float = 0.0,
  centerY: float = 0.0
): PhysicsBody =
  ## Creates a new PhysicsBody.
  result = PhysicsBody(kind: kind)
  initPhysicsBody(
    result,
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

template collisionShape*(this: PhysicsBody): CollisionShape =
  this.collisionShape

method `scale=`*(this: PhysicsBody, scale: Vector) =
  procCall `scale=`(Node(this), scale)
  if this.collisionShape != nil:
    this.collisionShape.scale = scale

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
  # TODO: In the future, support multiple shapes per body.
  if child of CollisionShape:
    this.collisionShape = CollisionShape(child)
    # TODO: This may not be accurate
    # if the scale of the body's parent is not (1, 1)
    this.collisionShape.scale = this.scale

