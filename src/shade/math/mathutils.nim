# Common math functions
import math
import vector2

func cubicBezierVector*(t: float, p0, p1, p2, p3: Vector2): Vector2
func cubicBezier*(t, p0, p1, p2, p3: float): float
func quadraticBezierVector*(t: float, p0, p1, p2: Vector2): Vector2
func quadraticBezier*(t, p0, p1, p2: float): float
func linearBezierVector*(t: float, p0, p1: Vector2): Vector2
func linearBezier*(t, p0, p1: float): float
func easeInAndOutQuadratic*(startValue, endValue, completionRatio: float): float
func easeOutQuadratic*(startValue, endValue, completionRatio: float): float
func easeInQuadratic*(startValue, endValue, completionRatio: float): float
func smootherStep*(x: float): float
func smoothStep*(x: float): float
func lerp*(startValue, endValue, completionRatio: float): float
func minUnsignedAngle*(a1, a2, halfRange: float): float
func minUnsignedDegreeAngle*(d1, d2: float): float
func minUnsignedRadianAngle*(r1, r2: float): float
func minSignedAngle*(a1, a2, halfRange: float): float
func minSignedDegreeAngle*(d1, d2: float): float
func minSignedRadianAngle*(r1, r2: float): float
func clamp*(min, value, max: float): float

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

func lerp*(startValue, endValue, completionRatio: float): float =
  ## Returns a value linearly interpolated between two values based on a ration of completion.
  ## @param {float} startValue The starting value.
  ## @param {float} endValue The ending value.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation
  ## between startValue and endValue.
  ## @return {float}
  return startValue + (endValue - startValue) * completionRatio

func smoothStep*(x: float): float =
  ## @param {float} x The value to process through the step equation.
  ## @return {float}
  return x * x * (3 - 2 * x)

func smootherStep*(x: float): float =
  ## @param {float} x The value to process through the step equation.
  ## @return {float}
  return x * x * x * (x * (x * 6 - 15) + 10)

func easeInQuadratic*(startValue, endValue, completionRatio: float): float =
  ## Returns a value quadratically accelerating from the start value until reaching the end value.
  ##
  ## @param {float} startValue The starting value.
  ## @param {float} endValue The ending value.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation.
  return startValue + (completionRatio * 2 * (endValue - startValue))

func easeOutQuadratic*(startValue, endValue, completionRatio: float): float =
  ## Returns a value quadratically decelerating from the start value until reaching the end value.
  ##
  ## @param {float} startValue The starting value.
  ## @param {float} endValue The ending value.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation.
  return startValue + (-(endValue - startValue) * completionRatio * (completionRatio - 2))

func easeInAndOutQuadratic*(startValue, endValue, completionRatio: float): float =
  ## Returns a value quadratically accelerating from the start value until reaching average of startValue and endValue,
  ## then quadratically decreases until reaching the end value.
  ##
  ## @param {float} startValue The starting value.
  ## @param {float} endValue The ending value.
  ## @param {float} completionRatio A value between 0.0 and 1.0 indicating the percent of interpolation.
  var ratio = completionRatio
  ratio *= 2f
  let totalChange = endValue - startValue
  if ratio < 1:
    return startValue + totalChange / 2 * pow(ratio, 2)
  ratio -= 1
  return startValue + (-totalChange / 2 * (ratio * (ratio - 2) - 1))

func linearBezier*(t, p0, p1: float): float =
  ## Calculates the position between the two values at a given ratio.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {float} p0 The starting value.
  ## @param {float} p1 The ending value.
  return (p1 - p0) * t

func linearBezierVector*(t: float, p0, p1: Vector2): Vector2 =
  ## Calculates the position between the two points at a given ratio.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vector2} p0 The starting point.
  ## @param {Vector2} p1 The ending point.
  return initVector2(linearBezier(t, p0.x, p1.x), linearBezier(t, p0.y, p1.y))

func quadraticBezier*(t, p0, p1, p2: float): float =
  ## Calculates the quadratic Bezier curve of three values.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vector2} p0 The initial value.
  ## @param {Vector2} p1 The value being approached, but not reached.
  ## @param {Vector2} p2 The value being reached.
  return pow(1 - t, 2) * p0 + (1 - t) * 2 * t * p1 + t * t * p2

func quadraticBezierVector*(t: float, p0, p1, p2: Vector2): Vector2 =
  ## Calculates the quadratic Bezier curve of three points.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vector2} p0 The initial point.
  ## @param {Vector2} p1 The point being approached, but not reached.
  ## @param {Vector2} p2 The point being reached.
  return initVector2(quadraticBezier(t, p0.x, p1.x, p2.x), quadraticBezier(t, p0.y, p1.y, p2.y))

func cubicBezier*(t, p0, p1, p2, p3: float): float =
  ## Calculates the cubic Bezier curve of 4 values.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vector2} p0 The starting value.
  ## @param {Vector2} p1 The first value to approach.
  ## @param {Vector2} p2 The second value to approach.
  ## @param {Vector2} p3 The end value.
  return 
    pow(1 - t, 3) * p0 +
    pow(1 - t, 2) * 3 * t * p1 +
    (1 - t) * 3 * t * t * p2 +
    pow(t, 3) * p3

func cubicBezierVector*(t: float, p0, p1, p2, p3: Vector2): Vector2 =
  ## Calculates the cubic Bezier curve of 4 points.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vector2} p0 The starting location.
  ## @param {Vector2} p1 The first point to approach.
  ## @param {Vector2} p2 The second point to approach.
  ## @param {Vector2} p3 The end point.
  return initVector2(cubicBezier(t, p0.x, p1.x, p2.x, p3.x), cubicBezier(t, p0.y, p1.y, p2.y, p3.y))

