import ../../src/shade

const
  width = 1920
  height = 1080

initEngineSingleton("Platformer Example", width, height)
let layer = newPhysicsLayer()
Game.scene.addLayer(layer)

let bodyA = newPhysicsBody(pbDynamic)
let bodyAHull = newCircleCollisionShape(newCircle(VECTOR_ZERO, 10))
bodyAHull.mass = 10
bodyAHull.elasticity = 1.0

bodyA.collisionShape = bodyAHull
bodyA.center = vector(100, 100)
bodyA.velocity = vector(100, 100)
layer.addChild(bodyA)

let bodyB = newPhysicsBody(pbStatic)

let bodyBHull = newPolygonCollisionShape(newPolygon([
  vector(-width / 2, -10),
  vector(width / 2, -10),
  vector(width / 2, 10),
  vector(-width / 2, 10)
]))

bodyBHull.mass = Inf
bodyBHull.elasticity = 1.0

bodyB.collisionShape = bodyBHull
bodyB.center = vector(310, 200)
layer.addChild(bodyB)

Game.start()

