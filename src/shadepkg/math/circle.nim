import
  options,
  sdl2_nim/sdl,
  sdl2_nim/sdl_gpu

import
  mathutils,
  vector2,
  aabb,
  ../render/color

export vector2

type Circle* = object
  center*: Vector
  radius*: float
  area: Option[float]

proc newCircle*(center: Vector, radius: float): Circle =
  Circle(
    center: center,
    radius: radius
  )

proc newCircle*(centerX, centerY, radius: float): Circle =
  return newCircle(vector(centerX, centerY), radius)

proc area*(this: var Circle): float =
  if this.area.isNone:
    this.area = (PI * this.radius * this.radius).option
  return this.area.get

proc getScaledInstance*(this: Circle, scale: Vector): Circle =
  if scale.x == 0 or scale.y == 0:
    raise newException(Exception, "Scaled size cannot be 0!")
  return newCircle(this.center, this.radius * max(scale.x, scale.y))

func calcBounds*(circ: Circle): AABB =
  return aabb(
    circ.center.x - circ.radius,
    circ.center.y - circ.radius,
    circ.radius * 2,
    circ.radius * 2
  )

proc stroke*(
  this: Circle,
  ctx: Target,
  offsetX: float = 0,
  offsetY: float = 0,
  color: Color = RED
) =
  ctx.circle(
    cfloat this.center.x + offsetX,
    cfloat this.center.y + offsetY,
    cfloat this.radius,
    color
  )

proc fill*(
  this: Circle,
  ctx: Target,
  offsetX: float = 0,
  offsetY: float = 0,
  color: Color = RED
) =
  ctx.circleFilled(
    cfloat this.center.x + offsetX,
    cfloat this.center.y + offsetY,
    cfloat this.radius,
    color
  )

