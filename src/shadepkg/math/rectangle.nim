import vmath

type
  Rectangle* = ref RectangleObj
  RectangleObj* = object
    x, y, width, height: float
    topLeft, center, bottomRight: Vec2

proc newRectangle*(x, y, width, height: float): Rectangle =
  result = Rectangle(
    x: x,
    y: y,
    width: width,
    height: height
  )
  result.topLeft = vec2(result.x, result.y)
  result.center = vec2(
    result.x + result.width / 2,
    result.y + result.height / 2
  )
  result.bottomRight = vec2(
    result.x + result.width,
    result.y + result.height
  )

template x*(this: Rectangle): float = this.x
template y*(this: Rectangle): float = this.y
template width*(this: Rectangle): float = this.width
template height*(this: Rectangle): float = this.height

template topLeft*(this: Rectangle): Vec2 = this.topLeft
template center*(this: Rectangle): Vec2 = this.center
template bottomRight*(this: Rectangle): Vec2 = this.bottomRight
template halfSize*(this: Rectangle): Vec2 = this.center - this.topLeft

proc getScaledInstance*(this: Rectangle, scalar: float): Rectangle =
  newRectangle(
    this.x * scalar,
    this.y * scalar,
    this.width * scalar,
    this.height * scalar
  )

template `$`*(this: Rectangle): string =
  "x: " & $this.x & ", y: " & $this.y &
  ", width: " & $this.width & ", height: " & $this.height

