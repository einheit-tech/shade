import random, mathutils

type
  Vector* = object
    x*, y*: float
  IVector* = object
    x*, y*: int
  SomeVector* = Vector|IVector

func lerp*(startValue, endValue: IVector, completionRatio: CompletionRatio): IVector
func cubicBezierVector*(t: float, p0, p1, p2, p3: Vector): Vector
func cubicBezier*(t, p0, p1, p2, p3: float): float
func quadraticBezierVector*(t: float, p0, p1, p2: Vector): Vector
func quadraticBezier*(t, p0, p1, p2: float): float
func linearBezierVector*(t: float, p0, p1: Vector): Vector
func easeInExpo*(startValue, endValue: Vector, completionRatio: CompletionRatio): Vector
func easeInQuadratic*(startValue, endValue: Vector, completionRatio: CompletionRatio): Vector
func easeInAndOutQuadratic*(startValue, endValue: Vector, completionRatio: CompletionRatio): Vector
func easeOutQuadratic*(startValue, endValue: Vector, completionRatio: CompletionRatio): Vector

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

proc `*=`*(this: var SomeVector, v: SomeVector) =
  this.x *= v.x
  this.y *= v.y

proc `*=`*(this: var SomeVector, scalar: float) =
  this.x *= scalar
  this.y *= scalar

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
  ## Gets the angle of this vector to `v`.
  ## (from -179 to 179)
  this.getAngleRadiansTo(v).toAngle()

func fromRadians*(radians: float): SomeVector =
  ## Creates a new unit vector from the radian value.
  vector(cos(radians), sin(radians))

func fromAngle*(angle: float): SomeVector =
  ## Creates a new unit vector from the angle.
  let radians = toRadians(angle)
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

func lerp*(startValue, endValue: IVector, completionRatio: CompletionRatio): IVector =
  return ivector(
    lerp(startValue.x, endValue.x, completionRatio),
    lerp(startValue.y, endValue.y, completionRatio)
  )

func linearBezierVector*(t: float, p0, p1: Vector): Vector =
  ## Calculates the position between the two points at a given ratio.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vector} p0 The starting point.
  ## @param {Vector} p1 The ending point.
  return vector(linearBezier(t, p0.x, p1.x), linearBezier(t, p0.y, p1.y))

func easeInExpo*(startValue, endValue: Vector, completionRatio: CompletionRatio): Vector =
  return vector(
    easeInExpo(startValue.x, endValue.x, completionRatio),
    easeInExpo(startValue.y, endValue.y, completionRatio)
  )

func easeInQuadratic*(startValue, endValue: Vector, completionRatio: CompletionRatio): Vector =
  return vector(
    easeInQuadratic(startValue.x, endValue.x, completionRatio),
    easeInQuadratic(startValue.y, endValue.y, completionRatio)
  )

func easeInAndOutQuadratic*(startValue, endValue: Vector, completionRatio: CompletionRatio): Vector =
  return vector(
    easeInAndOutQuadratic(startValue.x, endValue.x, completionRatio),
    easeInAndOutQuadratic(startValue.y, endValue.y, completionRatio)
  )

func easeOutQuadratic*(startValue, endValue: Vector, completionRatio: CompletionRatio): Vector =
  return vector(
    easeOutQuadratic(startValue.x, endValue.x, completionRatio),
    easeOutQuadratic(startValue.y, endValue.y, completionRatio)
  )

func quadraticBezier*(t, p0, p1, p2: float): float =
  ## Calculates the quadratic Bezier curve of three values.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vector} p0 The initial value.
  ## @param {Vector} p1 The value being approached, but not reached.
  ## @param {Vector} p2 The value being reached.
  return pow(1 - t, 2) * p0 + (1 - t) * 2 * t * p1 + t * t * p2

func quadraticBezierVector*(t: float, p0, p1, p2: Vector): Vector =
  ## Calculates the quadratic Bezier curve of three points.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vector} p0 The initial point.
  ## @param {Vector} p1 The point being approached, but not reached.
  ## @param {Vector} p2 The point being reached.
  return vector(quadraticBezier(t, p0.x, p1.x, p2.x), quadraticBezier(t, p0.y, p1.y, p2.y))

func cubicBezier*(t, p0, p1, p2, p3: float): float =
  ## Calculates the cubic Bezier curve of 4 values.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vector} p0 The starting value.
  ## @param {Vector} p1 The first value to approach.
  ## @param {Vector} p2 The second value to approach.
  ## @param {Vector} p3 The end value.
  return 
    pow(1 - t, 3) * p0 +
    pow(1 - t, 2) * 3 * t * p1 +
    (1 - t) * 3 * t * t * p2 +
    pow(t, 3) * p3

func cubicBezierVector*(t: float, p0, p1, p2, p3: Vector): Vector =
  ## Calculates the cubic Bezier curve of 4 points.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vector} p0 The starting location.
  ## @param {Vector} p1 The first point to approach.
  ## @param {Vector} p2 The second point to approach.
  ## @param {Vector} p3 The end point.
  return vector(cubicBezier(t, p0.x, p1.x, p2.x, p3.x), cubicBezier(t, p0.y, p1.y, p2.y, p3.y))

# Vector

proc ease*(v1, v2: Vector, completionRatio: CompletionRatio, f: EasingFunction[float]): Vector =
  ## Applies an easing function
  ## @param {Vector} v1 The starting vector values.
  ## @param {Vector} v2 The ending vector values.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation
  ## @returns {Vector} A new vector with the lerped values.
  return vector(
    f(v1.x, v2.x, completionRatio),
    f(v1.y, v2.y, completionRatio)
  )

proc lerp*(v1, v2: Vector, completionRatio: CompletionRatio): Vector =
  ## Lerps the values between two vector (from v1 to v2).
  ## @param {Vector} v1 The starting vector values.
  ## @param {Vector} v2 The ending vector values.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation
  ## @returns {Vector} A new vector with the lerped values.
  return v1.ease(v2, completionRatio, mathutils.lerp)

