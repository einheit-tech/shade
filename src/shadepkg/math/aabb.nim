import
  vector2,
  ../render/render,
  ../render/color

import std/random

type AABB* = object
  topLeft*: Vector
  bottomRight*: Vector

template aabb*(left, top, right, bottom: float): AABB =
  AABB(topLeft: vector(left, top), bottomRight: vector(right, bottom))

const
  AABB_ZERO* = aabb(0, 0, 0, 0)
  AABB_INF* = aabb(NegInf, NegInf, Inf, Inf)

template left*(this: AABB): float =
  this.topLeft.x

template `left=`*(this: AABB, left: float) =
  this.topLeft.x = left

template top*(this: AABB): float =
  this.topLeft.y

template `top=`*(this: AABB, top: float) =
  this.topLeft.y = top

template right*(this: AABB): float =
  this.bottomRight.x

template `right=`*(this: AABB, right: float) =
  this.bottomRight.x = right

template bottom*(this: AABB): float =
  this.bottomRight.y

template `bottom=`*(this: AABB, bottom: float) =
  this.bottomRight.y = bottom

template width*(this: AABB): float =
  this.right - this.left

template height*(this: AABB): float =
  this.bottom - this.top

template getArea*(this: AABB): float =
  this.width * this.height

template getSize*(this: AABB): Vector =
  this.bottomRight - this.topLeft

template center*(this: AABB): Vector =
  (this.topLeft + this.bottomRight) * 0.5

proc getTranslatedInstance*(this: AABB, offset: Vector): AABB =
  aabb(
    this.left + offset.x,
    this.top + offset.y,
    this.right + offset.x,
    this.bottom + offset.y
  )

proc getScaledInstance*(this: AABB, scale: Vector): AABB =
  if scale.x == 0 or scale.y == 0:
    raise newException(Exception, "Scaled size cannot be 0!")
  return aabb(this.left * scale.x, this.top * scale.y, this.right * scale.x, this.bottom * scale.y)

proc getScaledInstance*(this: AABB, scale: float): AABB =
  if scale == 0.0:
    raise newException(Exception, "Scaled size cannot be 0!")
  return aabb(this.left * scale, this.top * scale, this.right * scale, this.bottom * scale)

template contains*(this: AABB, x, y: float): bool =
  x >= this.left and x <= this.right and
  y >= this.top and y <= this.bottom

template contains*(this: AABB, v: Vector): bool =
  this.contains(v.x, v.y)

template contains*(this, aabb: AABB): bool =
  this.contains(aabb.topLeft) and this.contains(aabb.bottomRight)

template overlaps*(this, aabb: AABB): bool =
  # One aabb is left of the other
  if this.topLeft.x >= aabb.bottomRight.x or aabb.topLeft.x >= this.bottomRight.x:
    false
  # One aabb is above the other
  elif this.topLeft.y <= aabb.bottomRight.y or aabb.topLeft.y <= this.bottomRight.y:
    false
  else:
    true

template intersects*(this: AABB, aabb: AABB): bool =
  not (
    aabb.left > this.right or
    aabb.right < this.left or
    aabb.top > this.bottom or
    aabb.bottom < this.top
  )

template createBoundsAround*(r1, r2: AABB): AABB =
  aabb(
    min(r1.topLeft.x, r2.topLeft.x),
    min(r1.topLeft.y, r2.topLeft.y),
    max(r1.bottomRight.x, r2.bottomRight.x),
    max(r1.bottomRight.y, r2.bottomRight.y)
  )

proc getRandomPoint*(this: AABB): Vector =
  return this.topLeft + vector(rand(this.width), rand(this.height))

proc vertices*(this: AABB): array[4, Vector] =
  [
    this.topLeft,
    vector(this.right, this.top),
    this.bottomRight,
    vector(this.left, this.bottom)
  ]

iterator items*(this: AABB): Vector =
  for v in this.vertices():
    yield v

proc `$`*(this: AABB): string =
  return "(" & $this.left & ", " & $this.top & ", " & $this.right & ", " & $this.bottom & ")"

proc stroke*(
  this: AABB,
  ctx: Target,
  offsetX: float = 0,
  offsetY: float = 0,
  color: Color = RED
) =
  ctx.rectangle(
    this.left + offsetX,
    this.top + offsetY,
    this.right + offsetX,
    this.bottom + offsetY,
    color
  )

proc fill*(
  this: AABB,
  ctx: Target,
  offsetX: float = 0,
  offsetY: float = 0,
  color: Color = RED
) =
  ctx.rectangleFilled(
    this.left + offsetX,
    this.top + offsetY,
    this.right + offsetX,
    this.bottom + offsetY,
    color
  )

