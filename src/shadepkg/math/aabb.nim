import
  mathutils,
  ../render/render,
  ../render/color

type
  Boundable* = concept b
    b is ref object
    getBounds(b) is AABB
  AABB* = ref object
    topLeft*: Vector
    bottomRight*: Vector

proc initAABB*(aabb: AABB, left, top, right, bottom: float) =
  aabb.topLeft = vector(left, top)
  aabb.bottomRight = vector(right, bottom)

proc newAABB*(left, top, right, bottom: float): AABB =
  result = AABB()
  initAABB(result, left, top, right, bottom)

template left*(this: AABB): float =
  this.topLeft.x

template top*(this: AABB): float =
  this.topLeft.y

template right*(this: AABB): float =
  this.bottomRight.x

template bottom*(this: AABB): float =
  this.bottomRight.y

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
  newAABB(
    this.left + offset.x,
    this.top + offset.y,
    this.right + offset.x,
    this.bottom + offset.y
  )

proc getScaledInstance*(this: AABB, scale: Vector): AABB =
  if scale.x == 0 or scale.y == 0:
    raise newException(Exception, "Scaled size cannot be 0!")
  newAABB(
    this.left * scale.x,
    this.top * scale.y,
    this.right * scale.x,
    this.bottom * scale.y
  )

template contains*(this: AABB, v: Vector): bool =
  v.x >= this.left and v.x <= this.right and
  v.y >= this.top and v.y <= this.bottom

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
  newAABB(
    min(r1.topLeft.x, r2.topLeft.x),
    min(r1.topLeft.y, r2.topLeft.y),
    max(r1.bottomRight.x, r2.bottomRight.x),
    max(r1.bottomRight.y, r2.bottomRight.y)
  )

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
  return
    "Top Left: (" & $this.left & ", " & $this.top & ")" & "\n" &
    "Bottom Right: (" & $this.right & ", " & $this.bottom & ")"

proc stroke*(this: AABB, ctx: Target, color: Color = RED) =
  ctx.rectangle(
    this.left,
    this.top,
    this.right,
    this.bottom,
    color
  )

proc fill*(this: AABB, ctx: Target, color: Color = RED) =
  ctx.rectangleFilled(
    this.left,
    this.top,
    this.right,
    this.bottom,
    color
  )

