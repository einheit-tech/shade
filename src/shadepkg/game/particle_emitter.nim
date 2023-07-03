import ../math/vector2
import node, particle

type
  ParticleEmitter* = ref object of Node
    createParticle: proc: Particle
    ## The location to spawn the next particle.
    ## If nil, ParticleEmitter.location will be used.
    getNextParticleSpawnLocation*: proc: Vector
    particlesPerSecond: float
    secondsTillParticleCreation: float
    particles: seq[Particle]
    particleIDs: seq[int]
    particleCounter: int
    firstDeadParticleIDIndex: int
    numParticlesToCreate: float

proc newParticleEmitter*(
  particlesPerSecond: float,
  createParticle: proc: Particle,
  initialNumParticles: int
): ParticleEmitter =
  ## @param particlesPerSecond:
  ##   The number of particles to emit per second.
  ##
  ## @param createParticle:
  ##   A procedure used to create a new particle.
  result = ParticleEmitter()
  initNode(Node result)
  result.createParticle = createParticle
  result.particlesPerSecond = particlesPerSecond
  result.particles = newSeq[Particle](initialNumParticles)
  result.particleIDs = newSeq[int](initialNumParticles)
  for i in 0 ..< initialNumParticles:
    result.particles[i] = createParticle()
    result.particleIDs[i] = i

  # We leave this.firstDeadParticleIDIndex at 0
  # so that particles will be set to the emitter location
  # when `recycleParticle` is invoked.
  # This means the particles are considered "dead" initially,
  # even though we've initialized their state above.

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
  p.location = 
    if this.getNextParticleSpawnLocation == nil:
      this.getLocation()
    else:
      this.getNextParticleSpawnLocation()

  this.particleIDs.add(this.particles.len())
  this.particles.add(p)
  inc this.firstDeadParticleIDIndex

template recycleParticle(this: ParticleEmitter) =
  # We have particles that can be recycled.
  let recycledParticleID = this.particleIDs[this.firstDeadParticleIDIndex]
  template recycledParticle: Particle =
    this.particles[recycledParticleID]
  recycledParticle.ttl = recycledParticle.lifetime
  recycledParticle.location = 
    if this.getNextParticleSpawnLocation == nil:
      this.getLocation()
    else:
      this.getNextParticleSpawnLocation()

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

proc setEnabled*(this: ParticleEmitter, enabled: bool) =
  if enabled:
    if UPDATE notin this.flags:
      this.flags = UPDATE_RENDER_FLAGS
  else:
    if UPDATE in this.flags:
      this.flags = { RENDER }

proc isEnabled*(this: ParticleEmitter): bool =
  return UPDATE in this.flags

method update*(this: ParticleEmitter, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  this.numParticlesToCreate += this.particlesPerSecond * deltaTime

  # Emit any new particles needed
  this.secondsTillParticleCreation -= deltaTime
  while this.numParticlesToCreate >= 1.0:
    this.emitParticle()
    this.numParticlesToCreate -= 1.0

  # Update all living particles
  for particle in this.forEachLivingParticle:
    particle.update(deltaTime)

ParticleEmitter.renderAsNodeChild:
  for particle in this.forEachLivingParticle:
    particle.render(ctx, offsetX, offsetY)

