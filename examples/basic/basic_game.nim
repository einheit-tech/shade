import ../../src/shade

const
  width = 1920
  height = 1080

var game: Game = newGame("Basic Example Game", width, height)
let layer = newPhysicsLayer(newSpatialGrid(150))
game.scene.addLayer layer

type CustomBody = ref object of PhysicsBody
  color*: ColorRGBX

proc newCustomBody(radius: float, center: Vec2, velocity: Vec2 = VEC2_ZERO): CustomBody =
  result = CustomBody(
    kind: pbKinematic,
    collisionhull: newCircleCollisionHull(newCircle(VEC2_ZERO, radius)),
    center: center,
    flags: {loUpdate, loRender, loPhysics},
    color: rgba(0, 255, 0, 255)
  )
  result.velocity = velocity

# TODO: Debug weird collision detection issue.

let ball = newCustomBody(10, vec2(1000, 100), vec2(128, 0))

let rect = newPhysicsBody(
  kind = pbStatic,
  hull = newPolygonCollisionHull(newPolygon([
    vec2(0, 0),
    vec2(0, -624),
    vec2(-32, -624),
    vec2(-32, 0),
  ])),
  center = vec2(1232, 672)
)

layer.add(ball)
layer.add(rect)

proc listener(collisionOwner, collided: PhysicsBody, result: CollisionResult) =
  if result != nil:
    echo "collision: " & $result.contactNormal

layer.addCollisionListener listener

game.start()

