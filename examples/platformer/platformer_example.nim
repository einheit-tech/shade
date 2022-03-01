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
player.x = 1920 / 2
player.y = 640

# Track the player with the camera.
let camera = newCamera(player, 0.25, easeInAndOutQuadratic)
camera.z = 0.55
Game.scene.camera = camera

let
  (_, groundImage) = Images.loadImage("./examples/assets/images/ground.png", FILTER_NEAREST)
  (_, wallImage) = Images.loadImage("./examples/assets/images/wall.png", FILTER_NEAREST)

# Ground
let
  halfGroundWidth = groundImage.w.float / 2
  halfGroundHeight = groundImage.h.float / 2

let groundShape = newPolygonCollisionShape(
  newPolygon([
    vector(halfGroundWidth, halfGroundHeight),
    vector(halfGroundWidth, -halfGroundHeight),
    vector(-halfGroundWidth, -halfGroundHeight),
    vector(-halfGroundWidth, halfGroundHeight)
  ])
)
groundShape.material = PLATFORM

let ground = newPhysicsBody(
  kind = pbStatic
)

ground.x = 1920 / 2
ground.y = 1080 - groundShape.getBounds().height / 2

ground.collisionShape = groundShape
let groundSprite = newSprite(groundImage)
ground.onRender = proc(this: Node, ctx: Target) =
  groundSprite.render(ctx)

let wallShapePolygon = newPolygon([
  vector(wallImage.w.float / 2, wallImage.h.float / 2),
  vector(wallImage.w.float / 2, -wallImage.h.float / 2),
  vector(-wallImage.w.float / 2, -wallImage.h.float / 2),
  vector(-wallImage.w.float / 2, wallImage.h.float / 2),
])

let wallSprite = newSprite(wallImage)

proc createWall(): PhysicsBody =
  # Left wall
  let wallShape = newPolygonCollisionShape(wallShapePolygon)
  wallShape.material = PLATFORM
  result = newPhysicsBody(kind = pbStatic)
  result.collisionShape = wallShape
  
  result.onRender = proc(this: Node, ctx: Target) =
    wallSprite.render(ctx)

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
  maxSpeed = 400.0
  acceleration = 100.0
  jumpForce = -350.0

proc physicsProcess(this: Node, deltaTime: float) =
  let
    leftStickX = Input.leftStickX()
    leftPressed = Input.isKeyPressed(K_LEFT) or leftStickX < -0.01
    rightPressed = Input.isKeyPressed(K_RIGHT) or leftStickX > 0.01

  var
    x: float = player.velocityX
    y: float = player.velocityY

  proc run(x, y: var float) =
    ## Handles player running
    if leftPressed == rightPressed:
      player.playAnimation("idle")
      return

    let accel =
      if leftStickX == 0.0:
        acceleration
      else:
        acceleration * abs(leftStickX)

    if rightPressed:
      x = min(player.velocityX + accel, maxSpeed)
      if player.scale.x < 0.0:
        player.scale = vector(abs(player.scale.x), player.scale.y)
    else:
      x = max(player.velocityX - accel, -maxSpeed)
      if player.scale.y > 0.0:
        player.scale = vector(-1 * abs(player.scale.x), player.scale.y)

    player.playAnimation("run")

  proc jump() =
    if player.isOnGround and (
      Input.wasKeyJustPressed(K_SPACE) or Input.wasControllerButtonJustPressed(CONTROLLER_BUTTON_A)
    ):
      y += jumpForce

  proc friction() =
    x *= (1 - ground.collisionShape.material.friction)

  friction()
  run(x, y)
  jump()

  player.velocity = vector(x, y)

  camera.z += Input.wheelScrolledLastFrame.float * 0.03

player.onUpdate = physicsProcess

# Use a negative x scale to flip the image
rightWall.scale = vector(-1, 1)

when not defined(debug):
  # Play some music
  let (someSong, err) = capture loadMusic("./examples/assets/music/night_prowler.ogg")
  if err == nil:
    discard capture fadeInMusic(someSong, 2.0, 0.15)
  else:
    echo "Error playing music: " & err.msg

Game.start()

