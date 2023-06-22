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
  ## creationRate: The min and max time to spawn the next particle.
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
  result = ParticleEmitter[P]()
  initParticleEmitter[P](result, creationRate, createParticle, onParticleCreated, resetParticle)

proc shouldCreateParticle(this: ParticleEmitter): bool =
  return this.secondsTillParticleCreation <= 0

method update*[P: Particle](this: ParticleEmitter[P], deltaTime: float) =
  procCall Node(this).update(deltaTime)

  this.secondsTillParticleCreation -= deltaTime
  while this.shouldCreateParticle():
    let (particle, isNewParticle) = this.particlePool.getWithInfo()
    particle.onExpired:
      discard this.particlePool.recycle(particle)

    particle.setLocation(this.getLocation())
    this.onParticleCreated(particle, isNewParticle)
    this.secondsTillParticleCreation += this.creationRate.random()

