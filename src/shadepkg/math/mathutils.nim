# Common math functions
import
  math,
  vector2

export math, vector2

type
  CompletionRatio* = 0.0 .. 1.0
  EasingFunction*[T] = proc(a, b: T, completionRatio: CompletionRatio): T

func cubicBezierVector*(t: float, p0, p1, p2, p3: Vector): Vector
func cubicBezier*(t, p0, p1, p2, p3: float): float
func quadraticBezierVector*(t: float, p0, p1, p2: Vector): Vector
func quadraticBezier*(t, p0, p1, p2: float): float
func linearBezierVector*(t: float, p0, p1: Vector): Vector
func easeInExpo*(startValue, endValue: Vector, completionRatio: CompletionRatio): Vector
func easeInQuadratic*(startValue, endValue: Vector, completionRatio: CompletionRatio): Vector
func easeInAndOutQuadratic*(startValue, endValue: Vector, completionRatio: CompletionRatio): Vector
func easeOutQuadratic*(startValue, endValue: Vector, completionRatio: CompletionRatio): Vector

func linearBezier*(t, p0, p1: float): float
func easeInExpo*(startValue, endValue: float, completionRatio: CompletionRatio): float
func easeInQuadratic*(startValue, endValue: float, completionRatio: CompletionRatio): float
func easeInAndOutQuadratic*(startValue, endValue: float, completionRatio: CompletionRatio): float
func easeOutQuadratic*(startValue, endValue: float, completionRatio: CompletionRatio): float
func smootherStep*(x: float): float
func smoothStep*(x: float): float
func lerp*(startValue, endValue: bool, completionRatio: CompletionRatio): bool
func lerp*(startValue, endValue: float, completionRatio: CompletionRatio): float
func lerp*(startValue, endValue: int, completionRatio: CompletionRatio): int
func lerp*(startValue, endValue: IVector, completionRatio: CompletionRatio): IVector
func lerpDiscrete*[T](startValue, endValue: T, completionRatio: CompletionRatio): T
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

func lerp*(startValue, endValue: bool, completionRatio: CompletionRatio): bool =
  if completionRatio == 1.0:
    return endValue
  else:
    return startValue

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

func lerp*(startValue, endValue: IVector, completionRatio: CompletionRatio): IVector =
  return ivector(
    lerp(startValue.x, endValue.x, completionRatio),
    lerp(startValue.y, endValue.y, completionRatio)
  )

func lerpDiscrete*[T](startValue, endValue: T, completionRatio: CompletionRatio): T =
  ## Returns the endValue when completionRatio reaches 1.0.
  ## Otherwise, startValue is returned.
  return 
    if completionRatio == 1.0:
      endValue
    else:
      startValue

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
  let eased: CompletionRatio =
    if completionRatio < 0.5:
      2 * float(completionRatio) * float(completionRatio)
    else:
      1 - pow(-2 * float(completionRatio) + 2, 2) / 2

  return lerp(startValue, endValue, eased)

func linearBezier*(t, p0, p1: float): float =
  ## Calculates the position between the two values at a given ratio.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {float} p0 The starting value.
  ## @param {float} p1 The ending value.
  return (p1 - p0) * t

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

func toAngle*(radians: float): float =
  return (radians * 180) / PI

func toRadians*(angle: float): float =
  const piOver180 = PI / 180
  return angle * piOver180

