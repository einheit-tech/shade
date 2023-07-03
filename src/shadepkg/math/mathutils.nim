import math
export math

type
  CompletionRatio* = 0.0 .. 1.0
  EasingFunction*[T] = proc(a, b: T, completionRatio: CompletionRatio): T

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

func toAngle*(radians: float): float =
  return (radians * 180) / PI

func toRadians*(angle: float): float =
  const piOver180 = PI / 180
  return angle * piOver180

