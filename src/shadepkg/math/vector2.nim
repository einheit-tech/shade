import
  math,
  random

type
  Vector* = object
    x*, y*: float
  IVector* = object
    x*, y*: int
  SomeVector* = Vector|IVector

proc vector*(x, y: float): Vector =
  Vector(x: x, y: y)

proc vector*(x, y: int): Vector =
  Vector(x: x.float, y: y.float)

proc ivector*(x, y: int): IVector =
  IVector(x: x, y: y)

const
  VECTOR_ZERO* = vector(0, 0)
  VECTOR_ONE* = vector(1.0, 1.0)
  IVECTOR_ZERO* = ivector(0, 0)
  IVECTOR_ONE* = ivector(1, 1)

template `$`*(this: SomeVector): string =
  "(x: " & $this.x & ", y: " & $this.y & ")"

# Add

proc `+=`*(this: var SomeVector, v: SomeVector) =
  this.x += v.x
  this.y += v.y

func `+`*(this, v: SomeVector): SomeVector =
  vector(this.x + v.x, this.y + v.y)

func add*(this: SomeVector, x, y: float): SomeVector =
  vector(this.x + x, this.y + y)

# Subtract

proc `-=`*(this: var SomeVector, v: SomeVector) =
  this.x -= v.x
  this.y -= v.y

func `-`*(this, v: SomeVector): SomeVector =
  vector(this.x - v.x, this.y - v.y)

func subtract*(this: SomeVector, x, y: float): SomeVector =
  vector(this.x - x, this.y - y)

# Multiply

func `*`*(this, v: SomeVector): SomeVector =
  vector(this.x * v.x, this.y * v.y)

func `*`*(this: SomeVector, scalar: float): SomeVector =
  vector(this.x * scalar, this.y * scalar)

func multiply*(this: SomeVector, x, y: float): SomeVector =
  vector(this.x * x, this.y * y)

# Divide

func `/`*(this, v: SomeVector): SomeVector =
  vector(this.x / v.x, this.y / v.y)

func `/`*(this: SomeVector, scalar: float): SomeVector =
  vector(this.x / scalar, this.y / scalar)

func divide*(this: SomeVector, x, y: float): SomeVector =
  vector(this.x / x, this.y / y)

func `==`*(this, v: SomeVector): bool =
  return this.x == v.x and this.y == v.y

func getMagnitudeSquared*(this: SomeVector): float =
  return float(this.x ^ 2 + this.y ^ 2)

func getMagnitude*(this: SomeVector): float =
  sqrt(this.getMagnitudeSquared())

func maxMagnitude*(this: SomeVector, magnitude: float): SomeVector =
  let currMagnitude = this.getMagnitude()
  if currMagnitude <= magnitude:
    return this
  return this * (magnitude / currMagnitude)

func normalize*(this: SomeVector, magnitude: float = 1.0): Vector =
  let scale = magnitude / this.getMagnitude()
  return vector(float(this.x) * scale, float(this.y) * scale)

func distanceSquared*(this: SomeVector, point: SomeVector): float =
  return
    (this.x - point.x) ^ 2 +
    (this.y - point.y) ^ 2

func distance*(this: SomeVector, point: SomeVector): float =
  sqrt(this.distanceSquared(point))

func dotProduct*(this: SomeVector, v: SomeVector): float =
  return
    this.x * v.x +
    this.y * v.y

func crossProduct*(this: SomeVector, v: SomeVector): float =
  return
    this.x * v.y -
    this.y * v.x

func reflect*(this: SomeVector, normal: SomeVector): SomeVector =
  let scalar = 2.0 * this.dotProduct(normal)
  return this - normal * scalar

func negate*(this: SomeVector): SomeVector =
  vector(-this.x, -this.y)

func inverse*(this: SomeVector): SomeVector =
  vector(1.0 / this.x, 1.0 / this.y)

func round*(this: SomeVector): SomeVector =
  vector(this.x.round, this.y.round)

func abs*(this: SomeVector): SomeVector =
  vector(this.x.abs, this.y.abs)

func min*(this: SomeVector): float =
  min(this.x, this.y)

func max*(this: SomeVector): float =
  max(this.x, this.y)

func getAngleRadians*(this: SomeVector): float =
  ## Gets the angle of this vector, in radians.
  ## (from -pi to pi)
  arctan2(this.y, this.x)

func getAngleRadiansTo*(this, v: SomeVector): float =
  ## Gets the angle of this vector to `v`, in radians.
  ## (from -pi to pi)
  arctan2(
    v.y - this.y,
    v.x - this.x
  )

func getAngleTo*(this, v: SomeVector): float =
  ## Gets the angle of this vector to `v`, in radians.
  ## (from -179 to 179)
  abs(
    (this.getAngleRadiansTo(v) * 180) / PI
  )

func fromRadians*(radians: float): SomeVector =
  ## Creates a new unit vector from the radian value.
  vector(cos(radians), sin(radians))

func rotate*(this: SomeVector, rotation: float): SomeVector =
  ## Gets a copy of this vector rotated around its origin by the given amount.
  ## @param rotation the number of radians to rotate the vector by.
  let
    sin = sin(rotation)
    cos = cos(rotation)
  return vector(this.x * cos - this.y * sin, this.x * sin + this.y * cos)

func rotateAround*(this: SomeVector, theta: float, anchorPoint: SomeVector): SomeVector =
  ## Rotates counter-clockwise around the given anchor point.
  ## @param theta The radians to rotate.
  ## @param anchorPoint The anchor point to rotate around.
  ## @return {SomeVector} A rotated point around the anchor point.
  let
    anchorX = anchorPoint.x
    anchorY = anchorPoint.y
    cos = cos(theta)
    sin = sin(theta)
    newX = anchorX + (cos * (this.x - anchorX) - sin * (this.y - anchorY))
    newY = anchorY + (sin * (this.x - anchorX) + cos * (this.y - anchorY))
  return vector(newX, newY)

func perpendicular*(this: SomeVector): SomeVector =
  ## Gets a perpendicular vector to this vector.
  ## This perpendicular vector faces to the right of this vector.
  ## @return {SomeVector}
  return vector(-this.y, this.x)

proc random*(this: SomeVector): float =
  rand(this.y - this.x) + this.x
