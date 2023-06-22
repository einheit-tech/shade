import safeseq
import node
import ../render/render
import ../math/vector2

type
  ExpirationListener* = proc()
  Particle* = ref object of Node
    velocity*: Vector
    ttl*: float
    maxTtl*: float
    expirationListeners: SafeSeq[ExpirationListener]

proc initParticle*(this: Particle, ttl: float) =
  initNode(Node this)
  this.ttl = ttl
  this.maxTtl = ttl
  this.expirationListeners = newSafeSeq[ExpirationListener]()

proc newParticle*(ttl: float): Particle =
  result = Particle()
  initParticle(result, ttl)

proc addExpirationListener*(this: Particle, listener: ExpirationListener) =
  this.expirationListeners.add(listener)

template onExpired*(this: Particle, body: untyped) =
  this.addExpirationListener(proc() =
    body
  )

proc expire(this: Particle) =
  for listener in this.expirationListeners:
    listener()

method update*(this: Particle, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  this.ttl -= deltaTime
  if this.ttl <= 0:
    this.expire()

  this.move(this.velocity.x * deltaTime, this.velocity.y * deltaTime)

