import ../../src/shade

const
  width = 1920
  height = 1080

initEngineSingleton("Physics Example", width, height)
let layer = newPhysicsLayer(gravity = VECTOR_ZERO)
Game.scene.addLayer(layer)

let body1 = newPhysicsBody(pbDynamic)
let body1Hull = newCircleCollisionShape(newCircle(VECTOR_ZERO, 10))
body1Hull.mass = 10
body1Hull.elasticity = 1.0

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
body2Hull.mass = 20
body2Hull.elasticity = 1.0

body2.collisionShape = body2Hull
body2.center = vector(250, 250)
layer.addChild(body2)

Game.start()

