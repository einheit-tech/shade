# Common math functions
import math, vmath
export math, vmath

func cubicBezierVector*(t: float, p0, p1, p2, p3: Vec2): Vec2
func cubicBezier*(t, p0, p1, p2, p3: float): float
func quadraticBezierVector*(t: float, p0, p1, p2: Vec2): Vec2
func quadraticBezier*(t, p0, p1, p2: float): float
func linearBezierVector*(t: float, p0, p1: Vec2): Vec2
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

# Vectors
func cross*(v1, v2: Vec2): float

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

func linearBezierVector*(t: float, p0, p1: Vec2): Vec2 =
  ## Calculates the position between the two points at a given ratio.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vec2} p0 The starting point.
  ## @param {Vec2} p1 The ending point.
  return vec2(linearBezier(t, p0.x, p1.x), linearBezier(t, p0.y, p1.y))

func quadraticBezier*(t, p0, p1, p2: float): float =
  ## Calculates the quadratic Bezier curve of three values.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vec2} p0 The initial value.
  ## @param {Vec2} p1 The value being approached, but not reached.
  ## @param {Vec2} p2 The value being reached.
  return pow(1 - t, 2) * p0 + (1 - t) * 2 * t * p1 + t * t * p2

func quadraticBezierVector*(t: float, p0, p1, p2: Vec2): Vec2 =
  ## Calculates the quadratic Bezier curve of three points.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vec2} p0 The initial point.
  ## @param {Vec2} p1 The point being approached, but not reached.
  ## @param {Vec2} p2 The point being reached.
  return vec2(quadraticBezier(t, p0.x, p1.x, p2.x), quadraticBezier(t, p0.y, p1.y, p2.y))

func cubicBezier*(t, p0, p1, p2, p3: float): float =
  ## Calculates the cubic Bezier curve of 4 values.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vec2} p0 The starting value.
  ## @param {Vec2} p1 The first value to approach.
  ## @param {Vec2} p2 The second value to approach.
  ## @param {Vec2} p3 The end value.
  return 
    pow(1 - t, 3) * p0 +
    pow(1 - t, 2) * 3 * t * p1 +
    (1 - t) * 3 * t * t * p2 +
    pow(t, 3) * p3

func cubicBezierVector*(t: float, p0, p1, p2, p3: Vec2): Vec2 =
  ## Calculates the cubic Bezier curve of 4 points.
  ##
  ## @param {float} t The ratio of completion (0.0 starting point, 1.0 finishing point).
  ## @param {Vec2} p0 The starting location.
  ## @param {Vec2} p1 The first point to approach.
  ## @param {Vec2} p2 The second point to approach.
  ## @param {Vec2} p3 The end point.
  return vec2(cubicBezier(t, p0.x, p1.x, p2.x, p3.x), cubicBezier(t, p0.y, p1.y, p2.y, p3.y))

# Vectors

func cross*(v1, v2: Vec2): float =
  return
    v1.x * v2.y -
    v1.y * v2.x

func rotate*(v: Vec2, rotation: float): Vec2 =
  ## Gets a copy of v vector rotated around its origin by the given amount.
  ## @param rotation the number of radians to rotate the vector by.
  let
    sin = sin(rotation)
    cos = cos(rotation)
  return vec2(v.x * cos - v.y * sin, v.x * sin + v.y * cos)

func rotateAround*(v: Vec2, theta: float, anchorPoint: Vec2): Vec2 =
  ## Rotates counter-clockwise around the given anchor point.
  ## @param theta The radians to rotate.
  ## @param anchorPoint The anchor point to rotate around.
  ## @return {Vec2} A rotated point around the anchor point.
  let
    anchorX = anchorPoint.x
    anchorY = anchorPoint.y
    cos = cos(theta)
    sin = sin(theta)
    newX = anchorX + (cos * (v.x - anchorX) - sin * (v.y - anchorY))
    newY = anchorY + (sin * (v.x - anchorX) + cos * (v.y - anchorY))
  return vec2(newX, newY)

func perpendicular*(v: Vec2): Vec2 =
  ## Gets a perpendicular vector to v vector.
  ## v perpendicular vector faces to the right of v vector.
  ## @return {Vec2}
  return vec2(-v.y, v.x)

func negate*(v: Vec2): Vec2 =
  vec2(-v.x, -v.y)

func normalize*(v: Vec2, magnitude: float = 1.0): Vec2 =
  let scale = magnitude / v.length()
  return vec2(v.x * scale, v.y * scale)

