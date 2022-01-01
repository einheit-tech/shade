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
    collisionShape*: CollisionShape
    acceleration*: Vector
    velocity*: Vector

    # TODO:
    # Should have an array of applied forces?
    # They would be applied, then cleared every frame.
    # If gravity isn't (0, 0), apply always.

    # Applying a force:
    # acceleration += force * mass
    # velocity += acceleration * deltaTime

    # Then we can calculate the velocity
    # at a given point during the tick.

    ## Forces applied to the center of mass, this frame.
    forces*: seq[Vector]

    # angularVelocity*: float

    case kind*: PhysicsBodyKind:
      of pbDynamic, pbKinematic:
        isOnGround*: bool
        isOnWall*: bool
      of pbStatic:
        discard

proc initPhysicsBody*(physicsBody: var PhysicsBody, flags: set[LayerObjectFlags] = {loUpdate, loRender}) =
  initNode(Node(physicsBody), flags)

proc newPhysicsBody*(
  kind: PhysicsBodyKind,
  flags: set[LayerObjectFlags] = {loUpdate, loRender}
): PhysicsBody =
  ## Creates a new PhysicsBody.
  result = PhysicsBody(kind: kind)
  initPhysicsBody(result, flags)

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

template velocityX*(this: PhysicsBody): float =
  this.velocity.x

template `velocityX=`*(this: PhysicsBody, x: float) =
  this.velocity = vector(x, this.velocity.y)

template velocityY*(this: PhysicsBody): float =
  this.velocity.y

template `velocityY=`*(this: PhysicsBody, y: float) =
  this.velocity = vector(this.velocity.x, y)

method update*(this: PhysicsBody, deltaTime: float) =
  procCall Node(this).update(deltaTime)
  this.center += this.velocity * deltaTime

PhysicsBody.renderAsNodeChild:
  when defined(collisionoutlines):
    if this.collisionShape != nil:
      this.collisionShape.render(ctx)

  if callback != nil:
    callback()

