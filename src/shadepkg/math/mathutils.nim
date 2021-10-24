# Common math functions
import math, vmath
export math, vmath

type
  NumberKind* = enum
    Int,
    Float
  IntOrFloat* = object
    case kind: NumberKind:
      of Int:
        intVal: int
      of Float:
        floatVal: float
  CompletionRatio* = 0.0 .. 1.0
  EasingFunction*[T] = proc(a, b: T, completionRatio: CompletionRatio): T

func cubicBezierVector*(t: float, p0, p1, p2, p3: DVec2): DVec2
func cubicBezier*(t, p0, p1, p2, p3: float): float
func quadraticBezierVector*(t: float, p0, p1, p2: DVec2): DVec2
func quadraticBezier*(t, p0, p1, p2: float): float
func linearBezierVector*(t: float, p0, p1: DVec2): DVec2
func easeInExpo*(startValue, endValue: DVec2, completionRatio: CompletionRatio): DVec2
func easeInQuadratic*(startValue, endValue: DVec2, completionRatio: CompletionRatio): DVec2
func easeInAndOutQuadratic*(startValue, endValue: DVec2, completionRatio: CompletionRatio): DVec2

func linearBezier*(t, p0, p1: float): float
func easeInExpo*(startValue, endValue: float, completionRatio: CompletionRatio): float
func easeInQuadratic*(startValue, endValue: float, completionRatio: CompletionRatio): float
func easeInAndOutQuadratic*(startValue, endValue: float, completionRatio: CompletionRatio): float
func easeOutQuadratic*(startValue, endValue: float, completionRatio: CompletionRatio): float
func smootherStep*(x: float): float
func smoothStep*(x: float): float
func lerp*(startValue, endValue: float, completionRatio: CompletionRatio): float
func lerp*(startValue, endValue: int, completionRatio: CompletionRatio): int
func lerpDiscrete[T: SomeNumber](startValue, endValue: T, completionRatio: CompletionRatio): T
func lerpDiscrete*(startValue, endValue: int, completionRatio: CompletionRatio): int
func lerpDiscrete*(startValue, endValue: float, completionRatio: CompletionRatio): float
func minUnsignedAngle*(a1, a2, halfRange: float): float
func minUnsignedDegreeAngle*(d1, d2: float): float
func minUnsignedRadianAngle*(r1, r2: float): float
func minSignedAngle*(a1, a2, halfRange: float): float
func minSignedDegreeAngle*(d1, d2: float): float
func minSignedRadianAngle*(r1, r2: float): float
func clamp*(min, value, max: float): float

func almostEquals*(x, y: float; unitsInLastPlace: Natural = MaxFloatPrecision): bool =
  # Can use https://github.com/nim-lang/Nim/blob/devel/lib/pure/math.nim#L262
  # once this is in Nim stable.
  runnableExamples:
    doAssert almostEqual(PI, 3.14159265358979)
    doAssert almostEqual(Inf, Inf)
    doAssert not almostEqual(NaN, NaN)

  if x == y:
    # short circuit exact equality -- needed to catch two infinities of
    # the same sign. And perhaps speeds things up a bit sometimes.
    return true
  let
    diff = abs(x - y)
    decimal = 1 / (10 ^ unitsInLastPlace)
  return diff <= decimal

# Vectors
func cross*(v1, v2: DVec2): float

func clamp*(min, value, max: float): float =
  ## Clamps the value between a min and max value.
  ## The value returned will not be less than the min, or more than the max.
  ## @param min The minimum value returned.
  ## @param value The value being checked.
  ## @param max The maximum value returned.
  if value < min:
    return min
  elif value > max:
    return max
  else:
    return value

func minSignedRadianAngle*(r1, r2: float): float =
  ## Calculates minimum signed difference between the two angles (in radians).
  ## @param {float} r1
  ## @param {float} r2
  ## @return {float}
  return minSignedAngle(r1, r2, PI)

func minSignedDegreeAngle*(d1, d2: float): float =
  ## Calculates minimum signed difference between the two angles (in degrees).
  ## @param {float} d1
  ## @param {float} d2
  ## @return {float}
  return minSignedAngle(d1, d2, 180)

func minSignedAngle*(a1, a2, halfRange: float): float =
  ##
  ## @param {float} a1
  ## @param {float} a2
  ## @param {float} halfRange
  ## @return {float}
  return (((a2 - a1) + halfRange) mod halfRange * 2) - halfRange

func minUnsignedRadianAngle*(r1, r2: float): float =
  ## Calculates minimum unsigned difference between the two angles (in radians).
  ## @param {float} r1
  ## @param {float} r2
  ## @return {float}
  return minUnsignedAngle(r1, r2, PI)

func minUnsignedDegreeAngle*(d1, d2: float): float =
  ## Calculates minimum unsigned difference between the two angles (in degrees).
  ## @param {float} d1
  ## @param {float} d2
  ## @return {float}
  return minUnsignedAngle(d1, d2, 180)

func minUnsignedAngle*(a1, a2, halfRange: float): float =
  ## Calculates minimum unsigned difference between the two angles.
  ## @param {float} a1
  ## @param {float} a2
  ## @param {float} halfRange
  ## @return {float}
  return halfRange - abs(halfRange - abs(a1 - a2))

func lerp*(startValue, endValue: float, completionRatio: CompletionRatio): float =
  ## Returns a value linearly interpolated between two values based on a ration of completion.
  ## @param {float} startValue The starting value.
  ## @param {float} endValue The ending value.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation
  ## between startValue and endValue.
  ## @return {float}
  return startValue + (endValue - startValue) * completionRatio

func lerp*(startValue, endValue: int, completionRatio: CompletionRatio): int =
  let f = lerp(startValue.float, endValue.float, completionRatio)
  return 
    if startValue < endValue:
      int floor(f)
    else:
      int ceil(f)

func lerpDiscrete[T: SomeNumber](startValue, endValue: T, completionRatio: CompletionRatio): T =
  ## Returns the endValue when completionRatio reaches 1.0.
  ## Otherwise, startValue is returned.
  return 
    if completionRatio == 1.0:
      endValue
    else:
      startValue

func lerpDiscrete*(startValue, endValue: int, completionRatio: CompletionRatio): int =
  lerpDiscrete[int](startValue, endValue, completionRatio)

func lerpDiscrete*(startValue, endValue: float, completionRatio: CompletionRatio): float =
  lerpDiscrete[float](startValue, endValue, completionRatio)

func smoothStep*(x: float): float =
  ## @param {float} x The value to process through the step equation.
  ## @return {float}
  return x * x * (3 - 2 * x)

func smootherStep*(x: float): float =
  ## @param {float} x The value to process through the step equation.
  ## @return {float}
  return x * x * x * (x * (x * 6 - 15) + 10)

func easeInExpo*(startValue, endValue: float, completionRatio: CompletionRatio): float =
  ## Returns a value exponentially accelerating from the start value until reaching the end value.
  ##
  ## @param {float} startValue The starting value.
  ## @param {float} endValue The ending value.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation.
  # return startValue + (completionRatio * 2 * (endValue - startValue))
  let eased =  
    if completionRatio == 0:
      0.0
    else:
      pow(2, 10 * completionRatio - 10)
  return lerp(startValue, endValue, eased)

func easeInQuadratic*(startValue, endValue: float, completionRatio: CompletionRatio): float =
  ## Returns a value quadratically accelerating from the start value until reaching the end value.
  ##
  ## @param {float} startValue The starting value.
  ## @param {float} endValue The ending value.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation.
  return lerp(startValue, endValue, completionRatio * completionRatio)

func easeOutQuadratic*(startValue, endValue: float, completionRatio: CompletionRatio): float =
  ## Returns a value quadratically decelerating from the start value until reaching the end value.
  ##
  ## @param {float} startValue The starting value.
  ## @param {float} endValue The ending value.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation.
  # return startValue + (-(endValue - startValue) * completionRatio * (completionRatio - 2))
  let eased = 1 - (1 - completionRatio) * (1 - completionRatio)
  return lerp(startValue, endValue, eased)

func easeInAndOutQuadratic*(startValue, endValue: float, completionRatio: CompletionRatio): float =
  ## Returns a value quadratically accelerating from the start value
  ## until reaching average of startValue and endValue,
  ## then quadratically decreases until reaching the end value.
  ##
  ## @param {float} startValue The starting value.
  ## @param {float} endValue The ending value.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation.
  let eased =
    if completionRatio < 0.5:
      2 * completionRatio * completionRatio
    else:
      1 - pow(-2 * completionRatio + 2, 2) / 2

  return lerp(startValue, endValue, eased)

func linearBezier*(t, p0, p1: float): float =
  ## Calculates the position between the two values at a given ratio.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {float} p0 The starting value.
  ## @param {float} p1 The ending value.
  return (p1 - p0) * t

func linearBezierVector*(t: float, p0, p1: DVec2): DVec2 =
  ## Calculates the position between the two points at a given ratio.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {DVec2} p0 The starting point.
  ## @param {DVec2} p1 The ending point.
  return dvec2(linearBezier(t, p0.x, p1.x), linearBezier(t, p0.y, p1.y))

func easeInExpo*(startValue, endValue: DVec2, completionRatio: CompletionRatio): DVec2 =
  return dvec2(
    easeInExpo(startValue.x, endValue.x, completionRatio),
    easeInExpo(startValue.y, endValue.y, completionRatio)
  )

func easeInQuadratic*(startValue, endValue: DVec2, completionRatio: CompletionRatio): DVec2 =
  return dvec2(
    easeInQuadratic(startValue.x, endValue.x, completionRatio),
    easeInQuadratic(startValue.y, endValue.y, completionRatio)
  )

func easeInAndOutQuadratic*(startValue, endValue: DVec2, completionRatio: CompletionRatio): DVec2 =
  return dvec2(
    easeInAndOutQuadratic(startValue.x, endValue.x, completionRatio),
    easeInAndOutQuadratic(startValue.y, endValue.y, completionRatio)
  )

func quadraticBezier*(t, p0, p1, p2: float): float =
  ## Calculates the quadratic Bezier curve of three values.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {DVec2} p0 The initial value.
  ## @param {DVec2} p1 The value being approached, but not reached.
  ## @param {DVec2} p2 The value being reached.
  return pow(1 - t, 2) * p0 + (1 - t) * 2 * t * p1 + t * t * p2

func quadraticBezierVector*(t: float, p0, p1, p2: DVec2): DVec2 =
  ## Calculates the quadratic Bezier curve of three points.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {DVec2} p0 The initial point.
  ## @param {DVec2} p1 The point being approached, but not reached.
  ## @param {DVec2} p2 The point being reached.
  return dvec2(quadraticBezier(t, p0.x, p1.x, p2.x), quadraticBezier(t, p0.y, p1.y, p2.y))

func cubicBezier*(t, p0, p1, p2, p3: float): float =
  ## Calculates the cubic Bezier curve of 4 values.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {DVec2} p0 The starting value.
  ## @param {DVec2} p1 The first value to approach.
  ## @param {DVec2} p2 The second value to approach.
  ## @param {DVec2} p3 The end value.
  return 
    pow(1 - t, 3) * p0 +
    pow(1 - t, 2) * 3 * t * p1 +
    (1 - t) * 3 * t * t * p2 +
    pow(t, 3) * p3

func cubicBezierVector*(t: float, p0, p1, p2, p3: DVec2): DVec2 =
  ## Calculates the cubic Bezier curve of 4 points.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {DVec2} p0 The starting location.
  ## @param {DVec2} p1 The first point to approach.
  ## @param {DVec2} p2 The second point to approach.
  ## @param {DVec2} p3 The end point.
  return dvec2(cubicBezier(t, p0.x, p1.x, p2.x, p3.x), cubicBezier(t, p0.y, p1.y, p2.y, p3.y))

# DVec2

const
  VEC2_ZERO* = dvec2()
  VEC2_ONE* = dvec2(1.0, 1.0)

func cross*(v1, v2: DVec2): float =
  return
    v1.x * v2.y -
    v1.y * v2.x

func rotate*(v: DVec2, rotation: float): DVec2 =
  ## Gets a copy of v vector rotated around its origin by the given amount.
  ## @param rotation the number of radians to rotate the vector by.
  let
    sin = sin(rotation)
    cos = cos(rotation)
  return dvec2(v.x * cos - v.y * sin, v.x * sin + v.y * cos)

func rotateAround*(v: DVec2, theta: float, anchorPoint: DVec2): DVec2 =
  ## Rotates counter-clockwise around the given anchor point.
  ## @param theta The radians to rotate.
  ## @param anchorPoint The anchor point to rotate around.
  ## @return {DVec2} A rotated point around the anchor point.
  let
    anchorX = anchorPoint.x
    anchorY = anchorPoint.y
    cos = cos(theta)
    sin = sin(theta)
    newX = anchorX + (cos * (v.x - anchorX) - sin * (v.y - anchorY))
    newY = anchorY + (sin * (v.x - anchorX) + cos * (v.y - anchorY))
  return dvec2(newX, newY)

func perpendicular*(v: DVec2): DVec2 =
  ## Gets a perpendicular vector to v vector.
  ## v perpendicular vector faces to the right of v vector.
  ## @return {DVec2}
  return dvec2(-v.y, v.x)

func isPerpendicular*(v1, v2: DVec2): bool =
  return perpendicular(v1.normalize().abs()) == v2.normalize().abs()

func negate*(v: DVec2): DVec2 = -v

func normalize*(v: DVec2, magnitude: float = 1.0): DVec2 =
  let scale = magnitude / v.length()
  return v * scale

func reflect*(this, normal: DVec2): DVec2 =
  let scalar = 2 * this.dot(normal)
  return this - normal * scalar

proc ease*(v1, v2: DVec2, completionRatio: CompletionRatio, f: EasingFunction[float]): DVec2 =
  ## Applies an easing function
  ## @param {DVec2} v1 The starting vector values.
  ## @param {DVec2} v2 The ending vector values.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation
  ## @returns {Vector} A new vector with the lerped values.
  return dvec2(
    f(v1.x, v2.x, completionRatio),
    f(v1.y, v2.y, completionRatio)
  )

proc lerp*(v1, v2: DVec2, completionRatio: CompletionRatio): DVec2 =
  ## Lerps the values between two vector (from v1 to v2).
  ## @param {DVec2} v1 The starting vector values.
  ## @param {DVec2} v2 The ending vector values.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation
  ## @returns {DVec2} A new vector with the lerped values.
  return v1.ease(v2, completionRatio, mathutils.lerp)

# IVec2

const
  IVEC2_ZERO* = ivec2()
  IVEC2_ONE* = ivec2(1, 1)

proc ease*(v1, v2: IVec2, completionRatio: CompletionRatio, f: EasingFunction[int]): IVec2 =
  ## Applies an easing function
  ## @param {IVec2} v1 The starting vector values.
  ## @param {IVec2} v2 The ending vector values.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation
  ## @returns {IVec2} A new vector with the lerped values.
  return ivec2(
    int32 f(v1.x, v2.x, completionRatio),
    int32 f(v1.y, v2.y, completionRatio)
  )

func lerpDiscrete*(v1, v2: IVec2, completionRatio: CompletionRatio): IVec2 =
  ## Will return v2 when the completionRatio reaches 1.0.
  ## Otherwise, v1 is returned.
  return v1.ease(v2, completionRatio, lerpDiscrete)

proc lerp*(v1, v2: IVec2, completionRatio: CompletionRatio): IVec2 =
  ## Lerps the values between two vector (from v1 to v2).
  ## @param {IVec2} v1 The starting vector values.
  ## @param {IVec2} v2 The ending vector values.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation
  ## @returns {IVec2} A new vector with the lerped values.
  return v1.ease(v2, completionRatio, lerp)

# DVec3

const
  VEC3_ZERO* = dvec3()
  VEC3_ONE* = dvec3(1.0, 1.0, 1.0)

proc ease*(v1, v2: DVec3, completionRatio: CompletionRatio, f: EasingFunction[float]): DVec3 =
  ## Applies an easing function
  ## @param {DVec3} v1 The starting vector values.
  ## @param {DVec3} v2 The ending vector values.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation
  ## @returns {Vector} A new vector with the lerped values.
  return dvec3(
    f(v1.x, v2.x, completionRatio),
    f(v1.y, v2.y, completionRatio),
    f(v1.z, v2.z, completionRatio)
  )

proc lerp*(v1, v2: DVec3, completionRatio: CompletionRatio): DVec3 =
  ## Lerps the values between two vector (from v1 to v2).
  ## @param {DVec3} v1 The starting vector values.
  ## @param {DVec3} v2 The ending vector values.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation
  ## @returns {Vector} A new vector with the lerped values.
  return v1.ease(v2, completionRatio, mathutils.lerp)

