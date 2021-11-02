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
  centerX = width / 2 * pixelToMeterScalar,
  centerY = height / 2 * pixelToMeterScalar - 5
)
ball.velocity = dvec2(1, 0)

let ballShape = newCircleCollisionShape(newCircle(VEC2_ZERO, 10 * pixelToMeterScalar))
ball.addChild(ballShape)

let rect = newPhysicsBody(
  kind = pbStatic,
  material = METAL,
  centerX = 960 * pixelToMeterScalar,
  centerY = 540 * pixelToMeterScalar
)

let rectShape = newPolygonCollisionShape(
  newPolygon([
    dvec2(160, 16),
    dvec2(160, -16),
    dvec2(-160, -16),
    dvec2(-160, 16),
  ]).getScaledInstance(VEC2_PIXELS_TO_METERS)
)
rect.addChild(rectShape)

layer.addChild(ball)
layer.addChild(rect)

let (someSong, err) = capture loadMusic("./examples/assets/music/night_prowler.ogg")

if err == nil:
  discard capture fadeInMusic(someSong, 2.0, 0.15)
else:
  echo "Error playing music: " & repr err

Game.start()

