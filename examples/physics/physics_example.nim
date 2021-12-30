import ../../src/shade

const
  width = 1920
  height = 1080

initEngineSingleton("Animation Player Example", width, height)
let layer = newPhysicsLayer()
Game.scene.addLayer(layer)

# TODO: Generate shapes, add them to the layer.

Game.start()

