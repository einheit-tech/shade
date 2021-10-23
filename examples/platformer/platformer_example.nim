import ../../src/shade
import king

const
  width = 1920
  height = 1080

initEngineSingleton(
  "Physics Example",
  width,
  height,
  clearColor = newColor(91, 188, 228)
)

let layer = newPhysicsLayer()
Game.scene.addLayer layer

# King
let player = createNewKing()
player.x = 200
player.y = 400

# Ground
let groundShape = newPolygonCollisionShape(newPolygon([
  dvec2(width / 2, 80),
  dvec2(width / 2, -80),
  dvec2(-width / 2, -80),
  dvec2(-width / 2, 80),
]))

let ground = newPhysicsBody(
  kind = pbStatic,
  material = PLATFORM,
  centerX = 960,
  centerY = height - groundShape.getBounds().height / 2
)

ground.addChild(groundShape)

let (_, groundImage) = Images.loadImage("./examples/assets/images/ground.png")
groundImage.setImageFilter(FILTER_NEAREST)
ground.addChild(newSprite(groundImage))

let (_, wallImage) = Images.loadImage("./examples/assets/images/wall.png")
wallImage.setImageFilter(FILTER_NEAREST)
let wallShapePolygon = newPolygon([
  dvec2(16, 192),
  dvec2(16, -192),
  dvec2(-16, -192),
  dvec2(-16, 192),
])

proc createWall(): PhysicsBody =
  # Left wall
  let wallShape = newPolygonCollisionShape(wallShapePolygon)

  result = newPhysicsBody(
    kind = pbStatic,
    material = PLATFORM,
  )

  result.addChild(wallShape)
  result.addChild(newSprite(wallImage))

let leftWall = createWall()
leftWall.x = wallShapePolygon.getBounds().width
leftWall.y = (height - groundShape.getBounds().height) / 2 - 32

let rightWall = createWall()
rightWall.x = width - wallShapePolygon.getBounds().width
rightWall.y = (height - groundShape.getBounds().height) / 2 - 32

layer.addChild(leftWall)
layer.addChild(rightWall)
layer.addChild(ground)
layer.addChild(player)

# Custom physics handling for the player
const
  maxSpeed = 500
  acceleration = 100
  jumpForce = -700

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
      player.scale = dvec2(abs(player.scale.x), player.scale.y)
    else:
      x = max(player.velocityX - acceleration, -maxSpeed)
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

player.onPhysicsUpdate = physicsProcess

# Scale everything up for visibility
player.scale = dvec2(2, 2)
ground.scale = dvec2(2, 2)
leftWall.scale = dvec2(2, 2)
# Use a negative x scale to flip the image
rightWall.scale = dvec2(-2, 2)

# Play some music
let (someSong, err) = capture loadMusic("./examples/assets/music/night_prowler.ogg")
if err == nil:
  discard capture fadeInMusic(someSong, 2.0, 0.15)
else:
  echo "Error playing music: " & repr err

Game.start()

