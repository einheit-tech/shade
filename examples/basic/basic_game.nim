import ../../src/shade

const
  width = 1920
  height = 1080

initEngineSingleton("Basic Example Game", width, height)

let layer = newPhysicsLayer(newSpatialGrid(150))
Game.scene.addLayer layer

let ball = newPhysicsBody(
  kind = pbKinematic,
  hull = newCircleCollisionHull(newCircle(VEC2_ZERO, 10)),
  centerX = 1150,
  centerY = 100,
)
ball.velocity.x = 32

let rect = newPhysicsBody(
  kind = pbStatic,
  hull = newPolygonCollisionHull(newPolygon([
    vec2(0, 0),
    vec2(0, -624),
    vec2(-32, -624),
    vec2(-32, 0),
  ])),
  centerX = 1232,
  centerY = 672
)

layer.addChild(ball)
layer.addChild(rect)

var i = 0
proc listener(layer: PhysicsLayer, collisionOwner, collided: PhysicsBody, result: CollisionResult) =
  if result != nil:
    echo "collision " & $i & ": " & $result.contactNormal
    i.inc

layer.addCollisionListener(listener)

let (someSong, err) = capture loadMusic("./examples/assets/music/night_prowler.ogg")

if err == nil:
  discard capture fadeInMusic(someSong, 2.0, 0.15)
else:
  echo "Error playing music: " & repr err

Game.start()

