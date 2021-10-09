import ../../src/shade

const
  width = 1920
  height = 1080

initEngineSingleton("Basic Example Game", width, height)

let layer = newPhysicsLayer()
Game.scene.addLayer layer

let ball = newPhysicsBody(
  kind = pbDynamic,
  material = initMaterial(1, 0.8, 1),
  centerX = 960,
  centerY = 400
)
ball.velocity = dvec2(32, 0)

let ballShape = newCircleCollisionShape(newCircle(VEC2_ZERO, 10))
ball.addChild(ballShape)

let rect = newPhysicsBody(
  kind = pbStatic,
  material = METAL,
  centerX = 960,
  centerY = 540
)

let rectShape = newPolygonCollisionShape(newPolygon([
  dvec2(160, 32),
  dvec2(160, 0),
  dvec2(-160, 0),
  dvec2(-160, 32),
]))
rect.addChild(rectShape)

layer.addChild(ball)
layer.addChild(rect)

let (someSong, err) = capture loadMusic("./examples/assets/music/night_prowler.ogg")

if err == nil:
  discard capture fadeInMusic(someSong, 2.0, 0.15)
else:
  echo "Error playing music: " & repr err

Game.start()

