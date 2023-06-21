import ../../src/shade

const
  width = 400
  height = 300

initEngineSingleton("Particle Emitter Example", width, height)
let layer = newLayer()
Game.scene.addLayer(layer)

const
  # Particles will live for 3 seconds
  particleLifespan = 3.0
  creationRate = vector(0.1, 0.5)

# Create our particle
type SquareParticle* = ref object of Particle
  color: Color
  size: Vector

proc newSquareParticle(color: Color, size: Vector): SquareParticle =
  result = SquareParticle(color: color, size: size)
  initParticle(result, particleLifespan)

SquareParticle.renderAsChildOf(Particle):
  ctx.rectangleFilled(
    offsetX + this.x - this.size.x / 2,
    offsetY + this.y - this.size.y / 2,
    offsetX + this.x + this.size.x / 2,
    offsetY + this.y + this.size.y / 2,
    this.color
  )

# Create our particle emitter
let emitter = newParticleEmitter[SquareParticle](
  creationRate,
  (proc(): SquareParticle = newSquareParticle(RED, vector(4, 4)))
)

Game.start()

