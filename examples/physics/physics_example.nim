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
platform.center = vector(width / 2, 900)
layer.addChild(platform)

const colors = [ RED, GREEN, BLUE, PURPLE, ORANGE ]
template getRandomColor(): Color = colors[rand(colors.high)]

proc addRandomBodyToLayer() =
  let
    body = newPhysicsBody(pbDynamic)
    bodyHull = newCircleCollisionShape(newCircle(VECTOR_ZERO, 30))

  body.collisionShape = bodyHull
  body.center = Input.mouseLocation

  let randColor = getRandomColor()
  body.onRender = proc(this: Node, ctx: Target) =
    PhysicsBody(this).collisionShape.fill(ctx, randColor)
    PhysicsBody(this).collisionShape.stroke(ctx, WHITE)

  layer.addChild(body)

# Add random shapes on click.
Input.addMousePressEventListener(addRandomBodyToLayer)

Game.start()

