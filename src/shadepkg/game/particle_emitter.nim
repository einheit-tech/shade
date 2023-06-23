import ../util/objectpool
import ../math/vector2
import node, particle

type
  ParticleParent = concept p
    p of Particle
  ParticleEmitter*[P: ParticleParent] = ref object of Node
    creationRate: Vector
    particlePool: ObjectPool[P]
    secondsTillParticleCreation: float
    onParticleCreated: proc(p: P, isNewParticle: bool)

proc initParticleEmitter*[P: Particle](
  this: ParticleEmitter[P],
  creationRate: Vector,
  createParticle: proc: P,
  onParticleCreated: proc(p: P, isNewParticle: bool),
  resetParticle: proc(p: P) = nil
) =
  ## @param creationRate:
  ##   The min and max time in seconds to spawn the next particle.
  ##
  ## @param createParticle:
  ##   A procedure used to create a new particle.
  ##
  ## @param onParticleCreated:
  ##   A callback invoked when a particle is created.
  ##   `isNewParticle` is true if a new particle was created,
  ##   and false if the particle was recycled.
  ##
  ## @param resetParticle:
  ##   A function invoked to reset some state of each particle after it's been recycled.
  initNode(Node this, {LayerObjectFlags.UPDATE})
  this.creationRate = creationRate
  this.onParticleCreated = onParticleCreated
  this.particlePool = newObjectPool[P](
    createParticle,
    proc(p: var P) =
      if resetParticle != nil:
        resetParticle(p)
      p.ttl = p.maxTtl
      p.setLocation(this.getLocation())
  )

  this.secondsTillParticleCreation = this.creationRate.random()

proc newParticleEmitter*[P: Particle](
  creationRate: Vector,
  createParticle: proc: P,
  onParticleCreated: proc(p: P, isNewParticle: bool),
  resetParticle: proc(p: P) = nil
): ParticleEmitter[P] =
  ## @param creationRate:
  ##   The min and max time in seconds to spawn the next particle.
  ##
  ## @param createParticle:
  ##   A procedure used to create a new particle.
  ##
  ## @param onParticleCreated:
  ##   A callback invoked when a particle is created.
  ##   `isNewParticle` is true if a new particle was created,
  ##   and false if the particle was recycled.
  ##
  ## @param resetParticle:
  ##   A function invoked to reset some state of each particle after it's been recycled.
  result = ParticleEmitter[P]()
  initParticleEmitter[P](result, creationRate, createParticle, onParticleCreated, resetParticle)

proc shouldCreateParticle(this: ParticleEmitter): bool =
  return this.secondsTillParticleCreation <= 0

method update*[P: Particle](this: ParticleEmitter[P], deltaTime: float) =
  procCall Node(this).update(deltaTime)

  this.secondsTillParticleCreation -= deltaTime
  while this.shouldCreateParticle():
    this.secondsTillParticleCreation += this.creationRate.random()

    let (particle, isNewParticle) = this.particlePool.getWithInfo()
    particle.ttl = particle.maxTtl

    particle.flags = UPDATE_RENDER_FLAGS
    particle.setLocation(this.getLocation())
    this.onParticleCreated(particle, isNewParticle)

    # Add an expiration listener if it's a newly created particle.
    if isNewParticle:
      particle.onExpired:
        if this.particlePool.recycle(particle):
          particle.ttl = particle.maxTtl
          particle.flags = {}

