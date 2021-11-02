import ../../src/shade

const
  width = 1920
  height = 1080

initEngineSingleton("Physics Example", width, height)

let layer = newPhysicsLayer()
Game.scene.addLayer layer

# Ball
let
  ball = newPhysicsBody(
    kind = pbDynamic,
    material = initMaterial(1, 0.8, 1),
    centerX = width / 2 * pixelToMeterScalar,
    centerY = 400 * pixelToMeterScalar
  )
  (_, ballImage) = Images.loadImage("./examples/assets/images/alienGreen_round.png")
  ballSprite = newSprite(ballImage)

ball.addChild(ballSprite)
ball.addChild(
  newCircleCollisionShape(
    newCircle(VEC2_ZERO, ballImage.w.float / 2 * pixelToMeterScalar)
  )
)

ball.velocity = dvec2(1, 0)
ball.scale = dvec2(3, 3)

# Ground
let rect = newPhysicsBody(
  kind = pbStatic,
  material = METAL,
  centerX = 960 * pixelToMeterScalar,
  centerY = 540 * pixelToMeterScalar
)

let rectShape = newPolygonCollisionShape(
  newPolygon([
    dvec2(960, 16),
    dvec2(960, -16),
    dvec2(-960, -16),
    dvec2(-960, 16),
  ]).getScaledInstance(dvec2(pixelToMeterScalar, pixelToMeterScalar))
)
rect.addChild(rectShape)

layer.addChild(ball)
layer.addChild(rect)

# Test scaling AFTER the game has started.
let scaleUpBallTask = newTask(
  onUpdate = (proc(this: Task, deltaTime: float) = discard),
  checkCompletionCondition = (proc(this: Task): bool = this.elapsedTime >= 1.0),
  onCompletion = (proc(this: Task) = 
    ball.scale = dvec2(5, 5)
    layer.removeChild(this)
  )
)
layer.addChild(scaleUpBallTask)

let scaleDownBallTask = newTask(
  onUpdate = (proc(this: Task, deltaTime: float) = discard),
  checkCompletionCondition = (proc(this: Task): bool = this.elapsedTime >= 2.0),
  onCompletion = (proc(this: Task) = 
    ball.scale = dvec2(1, 1)
    layer.removeChild(this)
  )
)
layer.addChild(scaleDownBallTask)

let (someSong, err) = capture loadMusic("./examples/assets/music/night_prowler.ogg")
if err == nil:
  discard capture fadeInMusic(someSong, 2.0, 0.15)
else:
  echo "Error playing music: " & repr err

Game.start()

