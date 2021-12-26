import
  math,
  random

type
  Vector* = object
    x*, y*: float

proc vector*(x, y: float): Vector =
  Vector(x: x, y: y)

proc vector*(x, y: int): Vector =
  Vector(x: x.float, y: y.float)

template toVector*(v: (int, int)): Vector = vector(v[0], v[1])

template VectorZero*: Vector = vector(0.0, 0.0)

template `$`*(this: Vector): string =
  "(x: " & $this.x & ", y: " & $this.y & ")"

# Add

proc `+=`*(this: var Vector, v: Vector) =
  this.x += v.x
  this.y += v.y

func `+`*(this, v: Vector): Vector =
  vector(this.x + v.x, this.y + v.y)

func add*(this: Vector, x, y: float): Vector =
  vector(this.x + x, this.y + y)

# Subtract

proc `-=`*(this: var Vector, v: Vector) =
  this.x -= v.x
  this.y -= v.y

func `-`*(this, v: Vector): Vector =
  vector(this.x - v.x, this.y - v.y)

func subtract*(this: Vector, x, y: float): Vector =
  vector(this.x - x, this.y - y)

# Multiply

func `*`*(this, v: Vector): Vector =
  vector(this.x * v.x, this.y * v.y)

func `*`*(this: Vector, scalar: float): Vector =
  vector(this.x * scalar, this.y * scalar)

func multiply*(this: Vector, x, y: float): Vector =
  vector(this.x * x, this.y * y)

# Divide

func `/`*(this, v: Vector): Vector =
  vector(this.x / v.x, this.y / v.y)

func `/`*(this: Vector, scalar: float): Vector =
  vector(this.x / scalar, this.y / scalar)

func divide*(this: Vector, x, y: float): Vector =
  vector(this.x / x, this.y / y)

func `==`*(this, v: Vector): bool =
  return this.x == v.x and this.y == v.y

func getMagnitudeSquared*(this: Vector): float =
  return
    pow(this.x, 2) +
    pow(this.y, 2)

func getMagnitude*(this: Vector): float =
  sqrt(this.getMagnitudeSquared())

func maxMagnitude*(this: Vector, magnitude: float): Vector =
  let currMagnitude = this.getMagnitude()
  if currMagnitude <= magnitude:
    return this
  return this * (magnitude / currMagnitude)

func normalize*(this: Vector, magnitude: float = 1.0): Vector =
  let scale = magnitude / this.getMagnitude()
  return vector(this.x * scale, this.y * scale)

func distanceSquared*(this: Vector, point: Vector): float =
  return
    pow(this.x - point.x, 2) +
    pow(this.y - point.y, 2)

func distance*(this: Vector, point: Vector): float =
  sqrt(this.distanceSquared(point))

func dotProduct*(this: Vector, v: Vector): float =
  return
    this.x * v.x +
    this.y * v.y

func crossProduct*(this: Vector, v: Vector): float =
  return
    this.x * v.y -
    this.y * v.x

func reflect*(this: Vector, normal: Vector): Vector =
  let scalar = 2.0 * this.dotProduct(normal)
  return this - normal * scalar

func negate*(this: Vector): Vector =
  vector(-this.x, -this.y)

func inverse*(this: Vector): Vector =
  vector(1.0 / this.x, 1.0 / this.y)

func round*(this: Vector): Vector =
  vector(this.x.round, this.y.round)

func abs*(this: Vector): Vector =
  vector(this.x.abs, this.y.abs)

func min*(this: Vector): float =
  min(this.x, this.y)

func max*(this: Vector): float =
  max(this.x, this.y)

func getAngleRadians*(this: Vector): float =
  ## Gets the angle of this vector, in radians.
  ## (from -pi to pi)
  arctan2(this.y, this.x)

func getAngleRadiansTo*(this, v: Vector): float =
  ## Gets the angle of this vector to `v`, in radians.
  ## (from -pi to pi)
  arctan2(
    v.y - this.y,
    v.x - this.x
  )

func getAngleTo*(this, v: Vector): float =
  ## Gets the angle of this vector to `v`, in radians.
  ## (from -179 to 179)
  abs(
    (this.getAngleRadiansTo(v) * 180) / PI
  )

func fromRadians*(radians: float): Vector =
  ## Creates a new unit vector from the radian value.
  vector(cos(radians), sin(radians))

func rotate*(this: Vector, rotation: float): Vector =
  ## Gets a copy of this vector rotated around its origin by the given amount.
  ## @param rotation the number of radians to rotate the vector by.
  let
    sin = sin(rotation)
    cos = cos(rotation)
  return vector(this.x * cos - this.y * sin, this.x * sin + this.y * cos)

func rotateAround*(this: Vector, theta: float, anchorPoint: Vector): Vector =
  ## Rotates counter-clockwise around the given anchor point.
  ## @param theta The radians to rotate.
  ## @param anchorPoint The anchor point to rotate around.
  ## @return {Vector} A rotated point around the anchor point.
  let
    anchorX = anchorPoint.x
    anchorY = anchorPoint.y
    cos = cos(theta)
    sin = sin(theta)
    newX = anchorX + (cos * (this.x - anchorX) - sin * (this.y - anchorY))
    newY = anchorY + (sin * (this.x - anchorX) + cos * (this.y - anchorY))
  return vector(newX, newY)

func perpendicular*(this: Vector): Vector =
  ## Gets a perpendicular vector to this vector.
  ## This perpendicular vector faces to the right of this vector.
  ## @return {Vector}
  return vector(-this.y, this.x)

proc random*(this: Vector): float =
  rand(this.y - this.x) + this.x
