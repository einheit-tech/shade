import
  mathutils,
  ../render/render,
  ../render/color

type
  Rectangle* = ref object
    x: float
    y: float
    width: float
    height: float
    topLeft: DVec2
    center: DVec2
    bottomRight: DVec2

proc newRectangle*(x, y, width, height: float): Rectangle =
  result = Rectangle(
    x: x,
    y: y,
    width: width,
    height: height
  )
  result.topLeft = dvec2(result.x, result.y)
  result.center = dvec2(
    result.x + result.width / 2,
    result.y + result.height / 2
  )
  result.bottomRight = dvec2(
    result.x + result.width,
    result.y + result.height
  )

template x*(this: Rectangle): float = this.x
template y*(this: Rectangle): float = this.y
template width*(this: Rectangle): float = this.width
template height*(this: Rectangle): float = this.height

template topLeft*(this: Rectangle): DVec2 = this.topLeft
template center*(this: Rectangle): DVec2 = this.center
template bottomRight*(this: Rectangle): DVec2 = this.bottomRight
template halfSize*(this: Rectangle): DVec2 = this.center - this.topLeft

proc getScaledInstance*(this: Rectangle, scale: DVec2): Rectangle =
  if scale.x == 0 or scale.y == 0:
    raise newException(Exception, "Scaled size cannot be 0!")
  newRectangle(
    this.x * scale.x,
    this.y * scale.y,
    this.width * scale.x,
    this.height * scale.y
  )

template `$`*(this: Rectangle): string =
  "x: " & $this.x & ", y: " & $this.y &
  ", width: " & $this.width & ", height: " & $this.height

proc stroke*(this: Rectangle, ctx: Target, color: Color = RED) =
  ctx.rectangle(
    cfloat this.x,
    cfloat this.y,
    cfloat this.x + this.width,
    cfloat this.y + this.height,
    color
  )

