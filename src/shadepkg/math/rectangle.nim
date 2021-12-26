import
  mathutils,
  ../render/render,
  ../render/color

type Rectangle* = ref object
  left*: float
  top*: float
  right*: float
  bottom*: float

proc initRectangle*(rect: Rectangle, left, top, right, bottom: float) =
  rect.left = left
  rect.top = top
  rect.right = right
  rect.bottom = bottom

proc newRectangle*(left, top, right, bottom: float): Rectangle =
  result = Rectangle()
  initRectangle(result, left, top, right, bottom)

template width*(this: Rectangle): float =
  this.right - this.left

template height*(this: Rectangle): float =
  this.bottom - this.top

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

proc stroke*(this: Rectangle, ctx: Target, color: Color = RED) =
  ctx.rectangle(
    this.left,
    this.top,
    this.right,
    this.bottom,
    color
  )

