import
  mathutils,
  ../render/render,
  ../render/color

type
  Boundable* = concept b
    getBounds(b) is Rectangle
  Rectangle* = ref object
    topLeft*: Vector
    bottomRight*: Vector

proc initRectangle*(rect: Rectangle, left, top, right, bottom: float) =
  rect.topLeft = vector(left, top)
  rect.bottomRight = vector(right, bottom)

proc newRectangle*(left, top, right, bottom: float): Rectangle =
  result = Rectangle()
  initRectangle(result, left, top, right, bottom)

template left*(this: Rectangle): float =
  this.topLeft.x

template top*(this: Rectangle): float =
  this.topLeft.y

template right*(this: Rectangle): float =
  this.bottomRight.x

template bottom*(this: Rectangle): float =
  this.bottomRight.y

template width*(this: Rectangle): float =
  this.right - this.left

template height*(this: Rectangle): float =
  this.bottom - this.top

template area*(this: Rectangle): float =
  this.width * this.height

proc getTranslatedInstance*(this: Rectangle, offset: Vector): Rectangle =
  newRectangle(
    this.left + offset.x,
    this.top + offset.y,
    this.right + offset.x,
    this.bottom + offset.y
  )

proc getScaledInstance*(this: Rectangle, scale: Vector): Rectangle =
  if scale.x == 0 or scale.y == 0:
    raise newException(Exception, "Scaled size cannot be 0!")
  newRectangle(
    this.left * scale.x,
    this.top * scale.y,
    this.right * scale.x,
    this.bottom * scale.y
  )

template contains*(this: Rectangle, v: Vector): bool =
  return
    v.x >= this.left and v.x <= this.right and
    v.y >= this.top and v.y <= this.bottom

template intersects*(this: Rectangle, rect: Rectangle): bool =
  return
    this.left <= rect.right and
    rect.left <= this.right and
    this.top <= rect.right and
    rect.top <= this.right

template `+`*(r1, r2: Rectangle): Rectangle =
  newRectangle(
    min(r1.topLeft.x, r2.topLeft.x),
    min(r1.topLeft.y, r2.topLeft.y),
    max(r1.bottomRight.x, r2.bottomRight.x),
    max(r1.bottomRight.y, r2.bottomRight.y)
  )


proc stroke*(this: Rectangle, ctx: Target, color: Color = RED) =
  ctx.rectangle(
    this.left,
    this.top,
    this.right,
    this.bottom,
    color
  )

