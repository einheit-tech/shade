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
  particleLifespan = 3.0
  particlesPerSecond = 500.0
  screenCenter = vector(width / 2, height / 2)

proc createRandomParticle(): Particle =
  result = newParticle(RED, 4.0, rand(1.0 .. 1.8))
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
  (proc(): Particle = createRandomParticle()),
  1000
)

emitter.setLocation(screenCenter)

layer.addChild(emitter)

Input.onKeyEvent:
  if key == K_ESCAPE:
    Game.stop()

Game.start()

