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

# NOTE:
# When a PhysicsBody is scaled,
# we create a copy of the internal collisionShape
# e.g. unscaledPolygon and scaledPolygon.
# We _render_ the unscaledPolygon,
# but use the scaledPolygon for physics.

# TODO: How do we know about scaling of the whole tree?
# Propagate downward when `scale=` is called,
# but when a CollisionShape is attached to an already-scaled node?
# We _could_ query the whole tree;
# this would only be done when a child is added,
# so it isn't that costly.
# It does mean we'll need children to know about their parents?

# When the body is rotated,
# TODO:

# When the body is translated,
# we do nothing to the body
# because children are relative.

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

template collisionShape*(this: PhysicsBody): CollisionShape =
  this.collisionShape

template velocityX*(this: PhysicsBody): float =
  this.velocity.x

template `velocityX=`*(this: PhysicsBody, x: float) =
  this.velocity = vector(x, this.velocity.y)

template velocityY*(this: PhysicsBody): float =
  this.velocity.y

template `velocityY=`*(this: PhysicsBody, y: float) =
  this.velocity = vector(this.velocity.x, y)

