import ../../src/shade
import std/random

randomize()

const
  width = 800
  height = 600

initEngineSingleton("Particle Emitter Example", width, height)
let layer = newLayer()
Game.scene.addLayer(layer)

const
  # Particles will live for 3 seconds
  particleLifespan = 1.0
  creationRate = vector(0.005, 0.005)
  screenCenter = vector(width / 2, height / 2)

proc createRandomParticle(): Particle =
  result = newParticle(RED, 4.0, rand(1.0 .. 1.8))
  result.velocity = vector(rand(-20.0 .. 20.0), rand(100.0 .. 180.0))

# Create our particle emitter
let emitter = newParticleEmitter(
  creationRate,
  (proc(): Particle = createRandomParticle()),
  1000
)

emitter.setLocation(screenCenter)

layer.addChild(emitter)

Input.onKeyEvent:
  if key == K_ESCAPE:
    Game.stop()

Game.start()

