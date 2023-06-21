import node
import safeseq

type
  ExpirationListener* = proc()
  Particle* = ref object of Node
    ttl*: float
    maxTtl*: float
    expirationListeners: SafeSeq[ExpirationListener]

proc initParticle*(this: Particle, ttl: float) =
  initNode(Node this)
  this.ttl = ttl
  this.maxTtl = ttl

proc newParticle*(ttl: float): Particle =
  result = Particle()
  initParticle(result, ttl)

proc addExpirationListener*(this: Particle, listener: ExpirationListener) =
  this.expirationListeners.add(listener)

template onExpired*(this: Particle, body: untyped) =
  this.addExpirationListener(proc(p {.inject.}: Particle) =
    body
  )

proc expire(this: Particle) =
  for listener in this.expirationListeners:
    listener()

method update*(this: Particle, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  # TODO: Is this a convention we should adopt?
  when not defined(release):
    if this.ttl <= 0:
      raise newException(Exception, "Expired particle being used!")

  this.ttl -= deltaTime
  if this.ttl <= 0:
    this.expire()

