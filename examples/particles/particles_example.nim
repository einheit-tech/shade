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
  # Particles will live for 1.5 seconds
  particleLifespan = 1.5
  particlesPerSecond = 500.0
  screenCenter = vector(width / 2, height / 2)

proc createRandomParticle(): Particle =
  result = newParticle(RED, 4.0, particleLifespan)
  result.velocity = vector(rand(-40.0 .. 40.0), rand(100.0 .. 180.0))
  result.onUpdate = proc(p: var Particle, deltaTime: float) =
    let
      t = max(0, p.ttl / p.lifetime)
      t1 = easeOutQuadratic(0, 1.0, 1.0 - t)
    p.color.g = uint8 easeInQuadratic(0, 122, t1)
    p.color.b = uint8 easeInQuadratic(0, 28, t1)
    p.color.a = uint8(t * 255)

# Create our particle emitter
let emitter = newParticleEmitter(
  particlesPerSecond,
  createRandomParticle,
  1000
)

# Particles will be emitted at the location of the emitter.
emitter.setLocation(screenCenter)

# You can further customize the particle spawn locations by providing a function.
# emitter.getNextParticleSpawnLocation = proc(): Vector =
#   vector(width / 2 + rand(-100.0 .. 100.0), height / 2 + rand(-100.0 .. 100.0))

layer.addChild(emitter)

Input.onKeyEvent(K_ESCAPE):
  Game.stop()

Game.start()

