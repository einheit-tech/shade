import pixie/context
import mathutils

import options

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

proc render*(this: Circle, ctx: Context, offset: Vec2 = VEC2_ZERO) =
  ctx.fillCircle(this.center + offset, this.radius)

