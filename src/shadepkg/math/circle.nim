import
  options,
  sdl2_nim/sdl,
  sdl2_nim/sdl_gpu

import
  mathutils,
  ../render/color

type Circle* = ref object
  center*: Vec2
  radius*: float
  area*: Option[float]

proc newCircle*(center: Vec2, radius: float): Circle =
  Circle(
    center: center,
    radius: radius
  )

proc newCircle*(centerX, centerY, radius: float): Circle =
  return newCircle(vec2(centerX, centerY), radius)

func project*(this: Circle, location, axis: Vec2): Vec2 =
  let
    newLoc = this.center + location
    centerDot = axis.dot(newLoc)
  return vec2(centerDot - this.radius, centerDot + this.radius)

proc getArea*(this: Circle): float =
  if this.area.isNone:
    this.area = (PI * this.radius * this.radius).option
  return this.area.get

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

