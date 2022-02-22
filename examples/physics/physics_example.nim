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
  clearColor = newColor(20, 20, 20)
)

let layer = newPhysicsLayer()
Game.scene.addLayer(layer)

# Create and add the platform.
const platformWidth = width - 200
let platform = newPhysicsBody(pbStatic)
let platformHull = newPolygonCollisionShape(newPolygon([
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
      result = newCircleCollisionShape(newCircle(VECTOR_ZERO, 30.0 + rand(20.0)))
    of BUTTON_RIGHT:
      let size = rand(15..45)
      result = newPolygonCollisionShape(newPolygon([
        vector(0, -size),
        vector(-size, size),
        vector(size, size),
      ]))
    else:
      let
        halfWidth = rand(15..45)
        halfHeight = rand(15..45)
      result = newPolygonCollisionShape(newPolygon([
        vector(halfWidth, halfHeight),
        vector(halfWidth, -halfHeight),
        vector(-halfWidth, -halfHeight),
        vector(-halfWidth, halfHeight)
      ]))

proc addRandomBodyToLayer(mouseButton: int) =
  let body = newPhysicsBody(pbDynamic)

  body.collisionShape = createRandomCollisionShape(mouseButton)
  body.setLocation(Input.mouseLocation)

  let randColor = getRandomColor()
  body.onRender = proc(this: Node, ctx: Target) =
    PhysicsBody(this).collisionShape.fill(ctx, randColor)
    PhysicsBody(this).collisionShape.stroke(ctx, WHITE)

  body.onUpdate = proc(this: Node, deltaTime: float) =
    # Remove the body if off screen
    if this.y > height + 200:
      layer.removeChild(this)

  layer.addChild(body)

# Add random shapes on click.
Input.addMousePressEventListener(addRandomBodyToLayer)

Game.start()

