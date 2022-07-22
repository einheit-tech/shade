import
  ../../src/shade,
  std/random

randomize()

const
  width = 1920
  height = 1080

initEngineSingleton(
  "Physics Example",
  width,
  height,
  fullscreen = true,
  clearColor = newColor(20, 20, 20)
)

let grid = newSpatialGrid(10, 6, 200)
let layer = newPhysicsLayer(grid)
Game.scene.addLayer(layer)

# Create and add the platform.
const platformWidth = width - 200
let platform = newPhysicsBody(PhysicsBodyKind.STATIC)
let platformHull = newCollisionShape(newPolygon([
  vector(-platformWidth / 2, -100),
  vector(platformWidth / 2, -100),
  vector(platformWidth / 2, 100),
  vector(-platformWidth / 2, 100)
]))
platform.collisionShape = platformHull
platform.setLocation(width / 2, 800)
layer.addChild(platform)

const colors = [ RED, GREEN, BLUE, PURPLE, ORANGE ]
template getRandomColor(): Color = colors[rand(colors.high)]

proc createRandomCollisionShape(mouseButton: int): CollisionShape =
  case mouseButton:
    of BUTTON_LEFT:
      result = newCollisionShape(newCircle(VECTOR_ZERO, 30.0 + rand(20.0)))
    of BUTTON_RIGHT:
      let size = rand(15..45)
      result = newCollisionShape(newPolygon([
        vector(0, -size),
        vector(-size, size),
        vector(size, size),
      ]))
    else:
      let
        halfWidth = float rand(15..45)
        halfHeight = float rand(15..45)
      result = newCollisionShape(newAABB(-halfWidth, -halfHeight, halfHeight, halfWidth))

proc addRandomBodyToLayer(mouseButton: int, state: ButtonState, x, y, clicks: int) =
  let body = newPhysicsBody(PhysicsBodyKind.DYNAMIC)

  body.collisionShape = createRandomCollisionShape(mouseButton)
  body.setLocation(vector(x, y))

  let randColor = getRandomColor()
  body.onRender = proc(this: Node, ctx: Target) =
    PhysicsBody(this).collisionShape.fill(ctx, randColor)
    PhysicsBody(this).collisionShape.stroke(ctx, WHITE)

  body.onUpdate = proc(this: Node, deltaTime: float) =
    # Remove the body if off screen
    if this.y > height + 100:
      layer.removeChild(this)

  body.buildCollisionListener:
    if this.collisionShape.kind == CollisionShapeKind.CIRCLE and
       other.collisionShape.kind == CollisionShapeKind.CIRCLE:
      echo "Circle collisions!"
      return true

  layer.addChild(body)

# Add random shapes on click.
Input.addMousePressedListener(addRandomBodyToLayer)
Input.addKeyPressedListener(
  K_ESCAPE,
  proc(key: Keycode, state: KeyState) =
    Game.stop()
)

Game.start()

