import ../render/[render, color]
import ../math/vector2

type
  Particle* = object
    location*: Vector
    velocity*: Vector
    color*: Color
    size*: float
    ttl*: float
    lifetime: float
    onUpdate*: proc(p: var Particle, deltaTime: float)

proc newParticle*(color: Color, size, lifetime: float): Particle =
  ## @param color:
  ##   The color to render the particle.
  ##
  ## @param size:
  ##   The size of the particle in pixels.
  ##
  ## @param lifetime:
  ##   The number of seconds the particle should live
  result = Particle()
  result.color = color
  result.size = size
  result.ttl = lifetime
  result.lifetime = lifetime

template x*(this: Particle): float =
  this.location.x

template y*(this: Particle): float =
  this.location.y

proc lifetime*(this: Particle): float =
  ## The entire amount of time in seconds the particle lives.
  return this.lifetime

proc update*(this: var Particle, deltaTime: float) =
  if this.ttl <= 0:
    return

  this.location += this.velocity * deltaTime
  this.ttl -= deltaTime

  if this.onUpdate != nil:
    this.onUpdate(this, deltaTime)

proc render*(this: var Particle, ctx: Target, offsetX: float = 0, offsetY: float = 0) =
  if this.ttl <= 0:
    return

  let halfSize = this.size * 0.5
  ctx.rectangleFilled(
    offsetX + this.x - halfSize,
    offsetY + this.y - halfSize,
    offsetX + this.x + halfSize,
    offsetY + this.y + halfSize,
    this.color
  )

