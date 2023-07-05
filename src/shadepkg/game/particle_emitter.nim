import ../math/vector2
import node, particle
import std/decls

type
  ParticleEmitter* = ref object of Node
    createParticle: proc: Particle
    onParticleEmission*: proc(p: var Particle)
    particlesPerSecond: float
    secondsTillParticleCreation: float
    particles: seq[Particle]
    particleIDs: seq[int]
    particleCounter: int
    firstDeadParticleIDIndex: int
    numParticlesToCreate: float
    enabled*: bool

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

  result.enabled = true

  # We leave this.firstDeadParticleIDIndex at 0
  # so that particles will be set to the emitter location
  # when `recycleParticle` is invoked.
  # This means the particles are considered "dead" initially,
  # even though we've initialized their state above.

proc len*(this: ParticleEmitter): int =
  return this.particles.len()

template numDeadParticles*(this: ParticleEmitter): int =
  this.particles.len() - this.firstDeadParticleIDIndex

template numLivingParticles*(this: ParticleEmitter): int =
  this.particles.len() - this.numDeadParticles()

template hasDeadParticles*(this: ParticleEmitter): bool =
  this.firstDeadParticleIDIndex < this.particles.len()

template emitNewParticle(this: ParticleEmitter) =
  # This means we have no particles to recycle,
  # so we just add a new particle to the end of the array.
  this.particleIDs.add(this.particles.len())
  this.particles.add(this.createParticle())
  inc this.firstDeadParticleIDIndex
  template p: Particle = this.particles[this.firstDeadParticleIDIndex - 1]
  p.location = this.getLocation()

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

  if this.onParticleEmission != nil:
    var p {.byaddr.} = this.particles[this.firstDeadParticleIDIndex - 1]
    this.onParticleEmission(p)

iterator forEachLivingParticle(this: ParticleEmitter): var Particle =
  for i in 0 ..< this.firstDeadParticleIDIndex:
    let id = this.particleIDs[i]
    yield this.particles[id]

method update*(this: ParticleEmitter, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  if this.enabled:
    this.numParticlesToCreate += this.particlesPerSecond * deltaTime

    # Emit any new particles needed
    this.secondsTillParticleCreation -= deltaTime
    while this.numParticlesToCreate >= 1.0:
      this.emitParticle()
      this.numParticlesToCreate -= 1.0

  # Update all living particles
  var expiredParticleIDIdices: seq[int]
  for i in 0 ..< this.firstDeadParticleIDIndex:
    let id = this.particleIDs[i]
    this.particles[id].update(deltaTime)
    if this.particles[id].ttl <= 0:
      expiredParticleIDIdices.add(i)

  for i in expiredParticleIDIdices:
    let id = this.particleIDs[i]
    this.particleIDs[i] = this.particleIDs[this.firstDeadParticleIDIndex - 1]
    this.particleIDs[this.firstDeadParticleIDIndex - 1] = id
    dec this.firstDeadParticleIDIndex
    # E.g.
    #   0        1      2      3      4       ]
    # [ expired, alive, alive, alive, expired ]
    # Swap index 0 and 3:
    #   0        1      2      3      4       ]
    # [ alive, alive, alive, expired, expired ]
    # NOTE: this.firstDeadParticleIDIndex was 4, now it is 3.

ParticleEmitter.renderAsNodeChild:
  for particle in this.forEachLivingParticle:
    particle.render(ctx, offsetX, offsetY)

