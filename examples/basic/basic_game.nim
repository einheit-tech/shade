import ../../src/shade

const
  width = 800
  height = 600

var game: Game = newGame("Basic Example Game", width, height)
let layer = newPhysicsLayer(newSpatialGrid(150))
game.scene.addLayer layer

type CustomBody = ref object of PhysicsBody
  color*: ColorRGBX

proc newCustomBody(radius: float, center: Vec2, velocity: Vec2 = VEC2_ZERO): CustomBody =
  CustomBody(
    kind: pbKinematic,
    velocity: velocity,
    collisionhull: newCircleCollisionHull(newCircle(VEC2_ZERO, radius)),
    flags: {loUpdate, loRender, loPhysics},
    center: center,
    color: rgba(0, 255, 0, 255)
  )

# TODO: Add custom rendering example
render(CustomBody, PhysicsBody):
  ctx.fillStyle = rgba(0, 0, 255, 255)
  ctx.fillCircle(VEC2_ZERO, this.collisionHull.circle.radius)

let bodyA = newCustomBody(24f, VEC2_ZERO, vec2(50, 50))
let bodyB = newCustomBody(150f, vec2(174, 174))
layer.add(bodyA)
layer.add(bodyB)

game.start()

