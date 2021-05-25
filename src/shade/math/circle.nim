import nico
import options
import vector2

type Circle* = ref object
  center*: Vector2
  radius*: float
  area*: Option[float]

proc newCircle*(center: Vector2, radius: float): Circle =
  Circle(
    center: center,
    radius: radius
  )

proc newCircle*(centerX, centerY, radius: float): Circle =
  return newCircle(initVector2(centerX, centerY), radius)

func project*(this: Circle, location, axis: Vector2): Vector2 =
  let
    newLoc = this.center + location
    centerDot = axis.dotProduct(newLoc)
  return initVector2(centerDot - this.radius, centerDot + this.radius)

proc getArea*(this: Circle): float =
  if this.area.isNone:
    this.area = (PI * this.radius * this.radius).option
  return this.area.get

proc render*(this: Circle, offset: Vector2 = VectorZero) =
  circ(offset.x + this.center.x, offset.y + this.center.y, this.radius)

