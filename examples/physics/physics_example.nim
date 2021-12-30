import ../../src/shade

const
  width = 1920
  height = 1080

initEngineSingleton("Animation Player Example", width, height)
let layer = newPhysicsLayer()
Game.scene.addLayer(layer)

# TODO: Generate shapes, add them to the layer.

let body1 = newPhysicsBody(pbDynamic)
let body1Hull = newCircleCollisionShape(newCircle(VECTOR_ZERO, 10))
body1.collisionShape = body1Hull
body1.center = vector(100, 100)
body1.velocity = vector(100, 100)
layer.addChild(body1)

let body2 = newPhysicsBody(pbDynamic)
let body2Hull = newPolygonCollisionShape(newPolygon([
  vector(-100, -100),
  vector(100, -100),
  vector(100, 100),
  vector(-100, 100)
]))
body2.collisionShape = body2Hull
body2.center = vector(300, 300)
layer.addChild(body2)

Game.start()

