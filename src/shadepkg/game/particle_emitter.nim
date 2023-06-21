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

proc initParticleEmitter*[P: Particle](
  this: ParticleEmitter[P],
  creationRate: Vector,
  createParticle: proc: P,
  resetParticle: proc(p: P) = nil
) =
  ## creationRate: The min and max time to spawn the next particle.
  initNode(Node this)
  this.creationRate = creationRate
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
  resetParticle: proc(p: P) = nil
): ParticleEmitter[P] =
  result = ParticleEmitter[P]()
  initParticleEmitter[P](result, creationRate, createParticle, resetParticle)

proc shouldCreateParticle(this: ParticleEmitter): bool =
  return this.secondsTillParticleCreation <= 0

method update*(this: ParticleEmitter, deltaTime: float) =
  procCall Particle(this).update(deltaTime)

  this.secondsTillParticleCreation -= deltaTime
  while this.shouldCreateParticle():
    let particle = this.particlePool.get()
    particle.onExpired:
      this.particlePool.recycle(particle)

    this.secondsTillParticleCreation += this.creationRate.random()

