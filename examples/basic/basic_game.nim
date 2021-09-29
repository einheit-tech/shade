import ../../src/shade

const
  width = 1920
  height = 1080

initEngineSingleton("Basic Example Game", width, height)

let layer = newPhysicsLayer(newSpatialGrid(150))
Game.scene.addLayer layer

type CustomBody = ref object of PhysicsBody
  color*: Color

proc newCustomBody(radius: float, center: Vec2, velocity: Vec2 = VEC2_ZERO): CustomBody =
  result = CustomBody(
    kind: pbKinematic,
    collisionhull: newCircleCollisionHull(newCircle(VEC2_ZERO, radius)),
    center: center,
    flags: {loUpdate, loRender, loPhysics},
    color: GREEN
  )
  result.velocity = velocity

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

proc listener(layer: PhysicsLayer, collisionOwner, collided: PhysicsBody, result: CollisionResult) =
  if result != nil:
    echo "collision: " & $result.contactNormal

layer.addCollisionListener listener

let (someSong, err) = capture loadMusic("./examples/basic/night_prowler.ogg")

if err == nil:
  discard capture fadeInMusic(someSong, 2.0, 0.15)

Game.start()

