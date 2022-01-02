import ../../src/shade

const
  width = 1920
  height = 1080

initEngineSingleton("Platformer Example", width, height)
let layer = newPhysicsLayer()
Game.scene.addLayer(layer)

let bodyA = newPhysicsBody(pbDynamic)
let bodyAHull = newCircleCollisionShape(newCircle(VECTOR_ZERO, 10))

bodyA.collisionShape = bodyAHull
bodyA.center = vector(100, 100)
bodyA.velocity = vector(100, 100)
layer.addChild(bodyA)

let bodyB = newPhysicsBody(pbStatic)

let bodyBHull = newPolygonCollisionShape(newPolygon([
  vector(-width / 2, -100),
  vector(width / 2, -100),
  vector(width / 2, 100),
  vector(-width / 2, 100)
]))

bodyB.collisionShape = bodyBHull
bodyB.center = vector(width / 2, 900)
layer.addChild(bodyB)

Game.start()

