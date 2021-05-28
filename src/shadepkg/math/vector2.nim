import
  math,
  random

type
  Vector2* = object
    x*, y*: float

proc initVector2*(x, y: float): Vector2 =
  Vector2(x: x, y: y)

proc initVector2*(x, y: int): Vector2 =
  Vector2(x: x.float, y: y.float)

template toVector2*(v: (int, int)): Vector2 = initVector2(v[0], v[1])

template VectorZero*: Vector2 = initVector2(0.0, 0.0)

template `$`*(this: Vector2): string =
  "(x: " & $this.x & ", y: " & $this.y & ")"

# Add

proc `+=`*(this: var Vector2, v: Vector2) =
  this.x += v.x
  this.y += v.y

func `+`*(this, v: Vector2): Vector2 =
  initVector2(this.x + v.x, this.y + v.y)

func add*(this: Vector2, x, y: float): Vector2 =
  initVector2(this.x + x, this.y + y)

# Subtract

proc `-=`*(this: var Vector2, v: Vector2) =
  this.x -= v.x
  this.y -= v.y

func `-`*(this, v: Vector2): Vector2 =
  initVector2(this.x - v.x, this.y - v.y)

func subtract*(this: Vector2, x, y: float): Vector2 =
  initVector2(this.x - x, this.y - y)

# Multiply

func `*`*(this, v: Vector2): Vector2 =
  initVector2(this.x * v.x, this.y * v.y)

func `*`*(this: Vector2, scalar: float): Vector2 =
  initVector2(this.x * scalar, this.y * scalar)

func multiply*(this: Vector2, x, y: float): Vector2 =
  initVector2(this.x * x, this.y * y)

# Divide

func `/`*(this, v: Vector2): Vector2 =
  initVector2(this.x / v.x, this.y / v.y)

func `/`*(this: Vector2, scalar: float): Vector2 =
  initVector2(this.x / scalar, this.y / scalar)

func divide*(this: Vector2, x, y: float): Vector2 =
  initVector2(this.x / x, this.y / y)

func `==`*(this, v: Vector2): bool =
  return this.x == v.x and this.y == v.y

func getMagnitudeSquared*(this: Vector2): float =
  return
    pow(this.x, 2) +
    pow(this.y, 2)

func getMagnitude*(this: Vector2): float =
  sqrt(this.getMagnitudeSquared())

func maxMagnitude*(this: Vector2, magnitude: float): Vector2 =
  let currMagnitude = this.getMagnitude()
  if currMagnitude <= magnitude:
    return this
  return this * (magnitude / currMagnitude)

func normalize*(this: Vector2, magnitude: float = 1.0): Vector2 =
  let scale = magnitude / this.getMagnitude()
  return initVector2(this.x * scale, this.y * scale)

func distanceSquared*(this: Vector2, point: Vector2): float =
  return
    pow(this.x - point.x, 2) +
    pow(this.y - point.y, 2)

func distance*(this: Vector2, point: Vector2): float =
  sqrt(this.distanceSquared(point))

func dotProduct*(this: Vector2, v: Vector2): float =
  return
    this.x * v.x +
    this.y * v.y

func crossProduct*(this: Vector2, v: Vector2): float =
  return
    this.x * v.y -
    this.y * v.x

func reflect*(this: Vector2, normal: Vector2): Vector2 =
  let scalar = 2.0 * this.dotProduct(normal)
  return this - normal * scalar

func negate*(this: Vector2): Vector2 =
  initVector2(-this.x, -this.y)

func inverse*(this: Vector2): Vector2 =
  initVector2(1.0 / this.x, 1.0 / this.y)

func round*(this: Vector2): Vector2 =
  initVector2(this.x.round, this.y.round)

func abs*(this: Vector2): Vector2 =
  initVector2(this.x.abs, this.y.abs)

func min*(this: Vector2): float =
  min(this.x, this.y)

func max*(this: Vector2): float =
  max(this.x, this.y)

func getAngleRadians*(this: Vector2): float =
  ## Gets the angle of this vector, in radians.
  ## (from -pi to pi)
  arctan2(this.y, this.x)

func getAngleRadiansTo*(this, v: Vector2): float =
  ## Gets the angle of this vector to `v`, in radians.
  ## (from -pi to pi)
  arctan2(
    v.y - this.y,
    v.x - this.x
  )

func getAngleTo*(this, v: Vector2): float =
  ## Gets the angle of this vector to `v`, in radians.
  ## (from -179 to 179)
  abs(
    (this.getAngleRadiansTo(v) * 180) / PI
  )

func fromRadians*(radians: float): Vector2 =
  ## Creates a new unit vector from the radian value.
  initVector2(cos(radians), sin(radians))

func rotate*(this: Vector2, rotation: float): Vector2 =
  ## Gets a copy of this vector rotated around its origin by the given amount.
  ## @param rotation the number of radians to rotate the vector by.
  let
    sin = sin(rotation)
    cos = cos(rotation)
  return initVector2(this.x * cos - this.y * sin, this.x * sin + this.y * cos)

func rotateAround*(this: Vector2, theta: float, anchorPoint: Vector2): Vector2 =
  ## Rotates counter-clockwise around the given anchor point.
  ## @param theta The radians to rotate.
  ## @param anchorPoint The anchor point to rotate around.
  ## @return {Vector2} A rotated point around the anchor point.
  let
    anchorX = anchorPoint.x
    anchorY = anchorPoint.y
    cos = cos(theta)
    sin = sin(theta)
    newX = anchorX + (cos * (this.x - anchorX) - sin * (this.y - anchorY))
    newY = anchorY + (sin * (this.x - anchorX) + cos * (this.y - anchorY))
  return initVector2(newX, newY)

func perpendicular*(this: Vector2): Vector2 =
  ## Gets a perpendicular vector to this vector.
  ## This perpendicular vector faces to the right of this vector.
  ## @return {Vector2}
  return initVector2(-this.y, this.x)

proc random*(this: Vector2): float =
  rand(this.y - this.x) + this.x
