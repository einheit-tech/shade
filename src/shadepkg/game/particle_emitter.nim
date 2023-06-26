import ../math/vector2
import node, particle

type
  ParticleEmitter* = ref object of Node
    createParticle: proc: Particle
    creationRate: Vector
    secondsTillParticleCreation: float
    particles: seq[Particle]
    particleIDs: seq[int]
    particleCounter: int
    firstDeadParticleIDIndex: int

proc initParticleEmitter*(
  this: ParticleEmitter,
  creationRate: Vector,
  createParticle: proc: Particle,
  initialNumParticles: int
) =
  ## @param creationRate:
  ##   The min and max time in seconds to spawn the next particle.
  ##
  ## @param createParticle:
  ##   A procedure used to create a new particle.
  initNode(Node this)
  this.createParticle = createParticle
  this.creationRate = creationRate
  this.secondsTillParticleCreation = this.creationRate.random()
  this.particles = newSeq[Particle](initialNumParticles)
  this.particleIDs = newSeq[int](initialNumParticles)
  for i in 0 ..< initialNumParticles:
    this.particles[i] = createParticle()
    this.particleIDs[i] = i

  # We leave this.firstDeadParticleIDIndex at 0
  # so that particles will be set to the emitter location
  # when `recycleParticle` is invoked.
  # This means the particles are considered "dead" initially,
  # even though we've initialized their state above.

proc newParticleEmitter*(
  creationRate: Vector,
  createParticle: proc: Particle,
  initialNumParticles: int
): ParticleEmitter =
  ## @param creationRate:
  ##   The min and max time in seconds to spawn the next particle.
  ##
  ## @param createParticle:
  ##   A procedure used to create a new particle.
  result = ParticleEmitter()
  initParticleEmitter(result, creationRate, createParticle, initialNumParticles)

proc shouldCreateParticle(this: ParticleEmitter): bool =
  return this.secondsTillParticleCreation <= 0

template numDeadParticles*(this: ParticleEmitter): int =
  this.particles.len() - this.firstDeadParticleIDIndex

template numLivingParticles*(this: ParticleEmitter): int =
  this.particles.len() - this.numDeadParticles()

template hasDeadParticles*(this: ParticleEmitter): bool =
  this.firstDeadParticleIDIndex < this.particles.len()

template emitNewParticle(this: ParticleEmitter) =
  # This means we have no particles to recycle,
  # so we just add a new particle to the end of the array.
  var p = this.createParticle()
  p.location = this.getLocation()
  this.particleIDs.add(this.particles.len())
  this.particles.add(p)
  inc this.firstDeadParticleIDIndex

template recycleParticle(this: ParticleEmitter) =
  # We have particles that can be recycled.
  let recycledParticleID = this.particleIDs[this.firstDeadParticleIDIndex]
  template recycledParticle: Particle =
    this.particles[recycledParticleID]
  recycledParticle.ttl = recycledParticle.lifetime
  recycledParticle.location = this.getLocation()
  inc this.firstDeadParticleIDIndex

template emitParticle(this: ParticleEmitter) =
  if this.hasDeadParticles():
    this.recycleParticle()
  else:
    this.emitNewParticle()

iterator forEachLivingParticle(this: ParticleEmitter): var Particle =
  for i in 0 ..< this.firstDeadParticleIDIndex:
    let id = this.particleIDs[i]
    yield this.particles[id]

method update*(this: ParticleEmitter, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  # Emit any new particles needed
  this.secondsTillParticleCreation -= deltaTime
  while this.shouldCreateParticle():
    this.secondsTillParticleCreation += this.creationRate.random()
    this.emitParticle()

  # Update all living particles
  for particle in this.forEachLivingParticle:
    particle.update(deltaTime)

ParticleEmitter.renderAsNodeChild:
  for particle in this.forEachLivingParticle:
    particle.render(ctx, offsetX, offsetY)

