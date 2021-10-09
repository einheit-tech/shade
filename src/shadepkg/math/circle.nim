import
  options,
  sdl2_nim/sdl,
  sdl2_nim/sdl_gpu

import
  mathutils,
  rectangle,
  ../render/color

type Circle* = ref object
  center*: DVec2
  radius*: float
  area*: Option[float]

proc newCircle*(center: DVec2, radius: float): Circle =
  Circle(
    center: center,
    radius: radius
  )

proc newCircle*(centerX, centerY, radius: float): Circle =
  return newCircle(dvec2(centerX, centerY), radius)

func project*(this: Circle, location, axis: DVec2): DVec2 =
  let
    newLoc = this.center + location
    centerDot = axis.dot(newLoc)
  return dvec2(centerDot - this.radius, centerDot + this.radius)

proc getArea*(this: Circle): float =
  if this.area.isNone:
    this.area = (PI * this.radius * this.radius).option
  return this.area.get

proc getScaledInstance*(this: Circle, scale: DVec2): Circle =
  if scale.x == 0 or scale.y == 0:
    raise newException(Exception, "Scaled size cannot be 0!")
  return newCircle(this.center, this.radius * max(scale.x, scale.y))

func calcBounds*(circ: Circle): Rectangle =
  return newRectangle(
    circ.center.x - circ.radius,
    circ.center.y - circ.radius,
    circ.radius * 2,
    circ.radius * 2
  )

proc stroke*(this: Circle, ctx: Target, color: Color = RED) =
  ctx.circle(
    cfloat this.center.x,
    cfloat this.center.y,
    cfloat this.radius,
    color
  )

proc fill*(this: Circle, ctx: Target, color: Color = RED) =
  ctx.circleFilled(
    cfloat this.center.x,
    cfloat this.center.y,
    cfloat this.radius,
    color
  )

