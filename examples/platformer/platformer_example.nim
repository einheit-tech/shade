import ../../src/shade
import king

initEngineSingleton(
  "Physics Example",
  1920,
  1080,
  clearColor = newColor(91, 188, 228)
)

let layer = newPhysicsLayer()
Game.scene.addLayer layer

# King
let player = createNewKing()
player.x = resolutionMeters.x / 2
player.y = 20

# Track the player with the camera.
let camera = newCamera(player, 0.25, easeInAndOutQuadratic)
Game.scene.camera = camera

let (_, groundImage) = Images.loadImage("./examples/assets/images/ground.png")
groundImage.setImageFilter(FILTER_NEAREST)

let (_, wallImage) = Images.loadImage("./examples/assets/images/wall.png")
wallImage.setImageFilter(FILTER_NEAREST)

# Ground
let
  halfGroundWidth = groundImage.w.float / 2 * pixelToMeterScalar
  halfGroundHeight = groundImage.h.float / 2 * pixelToMeterScalar
let groundShape = newPolygonCollisionShape(
  newPolygon([
    dvec2(halfGroundWidth, halfGroundHeight),
    dvec2(halfGroundWidth, -halfGroundHeight),
    dvec2(-halfGroundWidth, -halfGroundHeight),
    dvec2(-halfGroundWidth, halfGroundHeight)
  ])
)

let ground = newPhysicsBody(
  kind = pbStatic,
  material = PLATFORM,
  centerX = resolutionMeters.x / 2,
  centerY = resolutionMeters.y - groundShape.getBounds().height / 2
)

ground.addChild(newSprite(groundImage))
ground.addChild(groundShape)

let wallShapePolygon = newPolygon([
  dvec2(wallImage.w.float / 2, wallImage.h.float / 2),
  dvec2(wallImage.w.float / 2, -wallImage.h.float / 2),
  dvec2(-wallImage.w.float / 2, -wallImage.h.float / 2),
  dvec2(-wallImage.w.float / 2, wallImage.h.float / 2),
]).getScaledInstance(VEC2_PIXELS_TO_METERS)

proc createWall(): PhysicsBody =
  # Left wall
  let wallShape = newPolygonCollisionShape(wallShapePolygon)
  result = newPhysicsBody(
    kind = pbStatic,
    material = PLATFORM
  )
  result.addChild(newSprite(wallImage))
  result.addChild(wallShape)

let leftWall = createWall()
leftWall.x = ground.x - ground.width / 2 + leftWall.width / 2
leftWall.y = ground.y - ground.height / 2 - leftWall.height / 2

let rightWall = createWall()
rightWall.x = ground.x + ground.width / 2 - rightWall.width / 2
rightWall.y = leftWall.y

layer.addChild(ground)
layer.addChild(leftWall)
layer.addChild(rightWall)
layer.addChild(player)

# Custom physics handling for the player
const
  maxSpeed = 500 * pixelToMeterScalar
  acceleration = 100 * pixelToMeterScalar
  jumpForce = -700 * pixelToMeterScalar

proc physicsProcess(gravity: DVec2, damping, deltaTime: float) =
  let
    leftPressed = Input.isKeyPressed(K_LEFT)
    rightPressed = Input.isKeyPressed(K_RIGHT)

  var
    x: float = player.velocityX
    y: float = player.velocityY

  proc run(x, y: var float) =
    ## Handles player running
    if leftPressed == rightPressed:
      player.playAnimation("idle")
      return

    if rightPressed:
      x = min(player.velocityX + acceleration, maxSpeed)
      if Input.wasKeyJustPressed(K_RIGHT):
        player.scale = dvec2(abs(player.scale.x), player.scale.y)
    else:
      x = max(player.velocityX - acceleration, -maxSpeed)
      if Input.wasKeyJustPressed(K_LEFT):
        player.scale = dvec2(-1 * abs(player.scale.x), player.scale.y)

    player.playAnimation("run")

  proc jump() =
    if player.isOnGround and Input.wasKeyJustPressed(K_SPACE):
      y += jumpForce

  proc friction() =
    x *= (1 - ground.material.friction)

  friction()
  run(x, y)
  jump()

  player.velocity = dvec2(x, y)

  camera.z += Input.wheelScrolledLastFrame.float * 0.01

player.onPhysicsUpdate = physicsProcess

# Use a negative x scale to flip the image
rightWall.scale = dvec2(-1, 1)

# Play some music
let (someSong, err) = capture loadMusic("./examples/assets/music/night_prowler.ogg")
if err == nil:
  discard capture fadeInMusic(someSong, 2.0, 0.15)
else:
  echo "Error playing music: " & repr err

Game.start()

