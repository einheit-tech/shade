import
  ../../src/shade,
  std/random

randomize()

const
  width = 1920
  height = 1080

type PhysicsShape = ref object of PhysicsBody
  color: Color

proc newPhysicsShape(shape: var CollisionShape, color: Color): PhysicsShape =
  result = PhysicsShape(kind: PhysicsBodyKind.DYNAMIC, color: color)
  initPhysicsBody(PhysicsBody(result), shape)

PhysicsShape.renderAsChildOf(PhysicsBody):
  PhysicsBody(this).collisionShape.fill(
    ctx,
    this.x + offsetX,
    this.y + offsetY,
    this.color
  )

  PhysicsBody(this).collisionShape.stroke(
    ctx,
    this.x + offsetX,
    this.y + offsetY,
    WHITE
  )

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
var platformHull = newCollisionShape(newPolygon([
  vector(-platformWidth / 2, -100),
  vector(platformWidth / 2, -100),
  vector(platformWidth / 2, 100),
  vector(-platformWidth / 2, 100)
]))
let platform = newPhysicsBody(PhysicsBodyKind.STATIC, platformHull)
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
      result = newCollisionShape(aabb(-halfWidth, -halfHeight, halfHeight, halfWidth))

proc addRandomBodyToLayer(mouseButton: int, state: ButtonState, x, y, clicks: int) =
  if state.justPressed:
    var shape = createRandomCollisionShape(mouseButton)
    let body = newPhysicsShape(shape, getRandomColor())

    body.setLocation(vector(x, y))

    body.onUpdate = proc(this: Node, deltaTime: float) =
      # Remove the body if off screen
      if Entity(this).y > height + 100:
        layer.removeChild(this)

    body.buildCollisionListener:
      if this.collisionShape.kind == CollisionShapeKind.CIRCLE and
         other.collisionShape.kind == CollisionShapeKind.CIRCLE:
        echo "Circle collisions!"
        return true

    layer.addChild(body)

# Add random shapes on click.
Input.addMouseButtonListener(addRandomBodyToLayer)
Input.onKeyPressed(K_ESCAPE):
  Game.stop()

Game.start()

