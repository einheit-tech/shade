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
  creationRate = vector(0.001, 0.001)
  screenCenter = vector(width / 2, height / 2)

# Create our particle
type SquareParticle* = ref object of Particle
  color: Color
  size: Vector

proc newSquareParticle(color: Color, size: Vector): SquareParticle =
  result = SquareParticle(color: color, size: size)
  initParticle(result, particleLifespan)

SquareParticle.renderAsChildOf(Particle):
  if this.ttl <= 0:
    return

  this.color.a = uint8 easeOutQuadratic(255, 0, 1.0 - max(0, this.ttl / this.maxTtl))
  ctx.rectangleFilled(
    offsetX + this.x - this.size.x / 2,
    offsetY + this.y - this.size.y / 2,
    offsetX + this.x + this.size.x / 2,
    offsetY + this.y + this.size.y / 2,
    this.color
  )

proc createRandomParticle(): SquareParticle =
  result = newSquareParticle(RED, vector(4.0, 4.0))
  result.velocity = vector(rand(-20.0 .. 20.0), rand(100.0 .. 180.0))

# Create our particle emitter
let emitter = newParticleEmitter[SquareParticle](
  creationRate,
  (proc(): SquareParticle = createRandomParticle()),
  (proc(p: SquareParticle, isNewParticle: bool) =
    if isNewParticle:
      layer.addChild(p)
  )
)

emitter.setLocation(screenCenter)

layer.addChild(emitter)

emitter.onUpdate = proc(this: Node, deltaTime: float) =
  this.setLocation(Input.mouseLocation)

Input.onKeyEvent:
  if key == K_ESCAPE:
    Game.stop()

Game.start()

