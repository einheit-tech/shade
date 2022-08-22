import sdl2_nim/sdl_gpu
from ../math/mathutils import CompletionRatio, ceil, floor
import
  ../math/vector2,
  ../math/aabb,
  ../render/color

export
  CompletionRatio,
  Vector,
  color,
  Target

type
  SizeKind* = enum
    Pixel
    Ratio

  Size* = object
    case kind*: SizeKind
      of Pixel:
        pixelValue: float
      of Ratio:
        ratioValue: CompletionRatio

  Insets* = AABB

  Alignment* = enum
    Start
    Center
    End
  
  StackDirection* = enum
    Vertical
    Horizontal

  ValidationStatus* = enum
    Valid
    Invalid
    InvalidChild

  UIComponent* = ref object of RootObj
    ## Top-down design: child components cannot cause their parent components to resize.
    parent: UIComponent
    children: seq[UIComponent]
    # If width or height are == 0, fill out all space available in layout.
    width: Size
    height: Size
    margin: Insets
    padding: Insets
    alignHorizontal: Alignment
    alignVertical: Alignment
    stackDirection: StackDirection
    layoutStatus: ValidationStatus
    bounds: AABB
    backgroundColor*: Color
    borderWidth*: float
    borderColor*: Color

  UI* = ref object
    root: UIComponent

template ratio*(r: CompletionRatio): Size =
  Size(kind: Ratio, ratioValue: r)

template insets*(left, top, right, bottom: float): Insets =
  Insets(aabb(left, top, right, bottom))

template margin*(left, top, right, bottom: float): Insets =
  insets(left, top, right, bottom)

template padding*(left, top, right, bottom: float): Insets =
  insets(left, top, right, bottom)

template paddingMarginOffset(this: UIComponent, axis: StackDirection): float =
  when axis == Horizontal:
    this.padding.left + this.margin.left
  else:
    this.padding.top + this.margin.bottom

template totalPadding(this: UIComponent, axis: StackDirection): float =
  when axis == Horizontal:
    this.padding.left + this.padding.right
  else:
    this.padding.top + this.padding.bottom

template pixelSize*(size: Size, availableParentSize: float): float =
  if size.kind == Pixel:
    size.pixelValue
  else:
    size.ratioValue * availableParentSize

proc `margin=`*(this: UIComponent, margin: float|Insets)
proc `padding=`*(this: UIComponent, padding: float|Insets)
proc `alignVertical=`*(this: UIComponent, alignment: Alignment)
proc `alignHorizontal=`*(this: UIComponent, alignment: Alignment)
proc `stackDirection=`*(this: UIComponent, direction: StackDirection)
method preRender*(this: UIComponent, ctx: Target, parentRenderBounds: AABB = AABB_INF) {.base.}
method postRender*(this: UIComponent, ctx: Target, renderBounds: AABB) {.base.}
proc updateBounds*(this: UIComponent, x, y, width, height: float)

proc newUI*(root: UIComponent): UI =
  result = UI(root: root)

proc initUIComponent*(
  this: UIComponent,
  borderWidth = 1.0,
  borderColor = BLACK
) =
  this.layoutStatus = Invalid
  this.borderWidth = borderWidth
  this.borderColor = borderColor

proc newUIComponent*(): UIComponent =
  result = UIComponent()
  initUIComponent(result)

proc layoutValidationStatus*(this: UIComponent): lent ValidationStatus =
  return this.layoutStatus

proc setLayoutValidationStatus(this: UIComponent, status: ValidationStatus) =
  this.layoutStatus = status
  if status == Invalid and this.parent != nil and this.parent.layoutValidationStatus == Valid:
    this.parent.setLayoutValidationStatus(InvalidChild)

proc setWidth(this: UIComponent, width: float|Size): bool =
  ## Returns true if the width value was changed.
  when typeof(width) is Size:
    if width == this.width:
      return false
    this.width = width
  else:
    if this.width.kind == Pixel:
      if width == this.width.pixelValue:
        return false
      this.width.pixelValue = width
    else:
      this.width = Size(kind: Pixel, pixelValue: width)

  return true

proc setHeight(this: UIComponent, height: float|Size): bool =
  ## Returns true if the height value was changed.
  when typeof(height) is Size:
    if height == this.height:
      return false
    this.height = height
  else:
    if this.height.kind == Pixel:
      if height == this.height.pixelValue:
        return false
      this.height.pixelValue = height
    else:
      this.height = Size(kind: Pixel, pixelValue: height)

  return true

proc width*(this: UIComponent): Size =
  this.width

proc `width=`*(this: UIComponent, width: float|Size) =
  if this.setWidth(width):
    this.setLayoutValidationStatus(Invalid)

proc height*(this: UIComponent): Size =
  this.height

proc `height=`*(this: UIComponent, height: float|Size) =
  if this.setHeight(height):
    this.setLayoutValidationStatus(Invalid)

proc `margin=`*(this: UIComponent, margin: float|Insets) =
  when typeof(margin) is Insets:
    this.margin = margin
  else:
    this.margin.left = margin
    this.margin.top = margin
    this.margin.right = margin
    this.margin.bottom = margin

  this.setLayoutValidationStatus(Invalid)

proc `padding=`*(this: UIComponent, padding: float|Insets) =
  when typeof(padding) is Insets:
    this.padding = padding
  else:
    this.padding.left = padding
    this.padding.top = padding
    this.padding.right = padding
    this.padding.bottom = padding

  this.setLayoutValidationStatus(Invalid)

proc `alignVertical=`*(this: UIComponent, alignment: Alignment) =
  this.alignVertical = alignment
  this.setLayoutValidationStatus(Invalid)

proc `alignHorizontal=`*(this: UIComponent, alignment: Alignment) =
  this.alignHorizontal = alignment
  this.setLayoutValidationStatus(Invalid)

proc `stackDirection=`*(this: UIComponent, direction: StackDirection) =
  this.stackDirection = direction
  this.setLayoutValidationStatus(Invalid)

proc parent*(this: UIComponent): UIComponent =
  return this.parent

proc children*(this: UIComponent): lent seq[UIComponent] =
  return this.children

proc addChild*(this, child: UIComponent) =
  this.children.add(child)
  child.parent = this
  this.setLayoutValidationStatus(Invalid)

proc bounds*(this: UIComponent): lent AABB =
  return this.bounds

method update*(this: UIComponent, deltaTime: float) {.base.} =
  discard

method layout*(this: UI, width, height: float) {.base.} =
  let 
    w = width - (this.root.margin.left + this.root.margin.right)
    h = height - (this.root.margin.top + this.root.margin.bottom)

  `width=`(this.root, w)
  `height=`(this.root, h)

  case this.root.layoutValidationStatus:
    of Valid:
      discard
    # TODO: Is there a better way to handle InvalidChild?
    of Invalid, InvalidChild:
      this.root.updateBounds(this.root.margin.left, this.root.margin.top, w, h)

proc determineChildrenSize(this: UIComponent): Vector =
  ## Calculates the size of children which do not have a fixed width or height.
  ## These children have a width or height <= 0.
  case this.stackDirection:
    of Vertical:
      result.x = this.bounds.width - this.totalPadding(Horizontal)

      var
        unreservedHeight = this.bounds.height - this.totalPadding(Vertical)
        numChildrenWithoutFixedHeight = this.children.len
        prevChild: UIComponent

      for child in this.children:
        let childPixelHeight = child.height.pixelSize(unreservedHeight)
        if childPixelHeight > 0.0:
          unreservedHeight -= childPixelHeight
          numChildrenWithoutFixedHeight -= 1

        if prevChild != nil:
          unreservedHeight -= max(child.margin.top, prevChild.margin.bottom)
        else:
          unreservedHeight -= child.margin.top

        prevChild = child

      if prevChild != nil:
        unreservedHeight -= prevChild.margin.bottom

      if unreservedHeight > 0 and numChildrenWithoutFixedHeight > 0:
        result.y = unreservedHeight / float(numChildrenWithoutFixedHeight)

    of Horizontal:
      result.y = this.bounds.height - this.totalPadding(Vertical)

      var
        unreservedWidth = this.bounds.width - this.totalPadding(Horizontal)
        numChildrenWithoutFixedWidth = this.children.len
        prevChild: UIComponent

      for child in this.children:
        let childPixelWidth = child.width.pixelSize(unreservedWidth)
        if childPixelWidth > 0:
          unreservedWidth -= childPixelWidth
          numChildrenWithoutFixedWidth -= 1

        if prevChild != nil:
          unreservedWidth -= max(child.margin.left, prevChild.margin.right)
        else:
          unreservedWidth -= child.margin.left

        prevChild = child

      if prevChild != nil:
        unreservedWidth -= prevChild.margin.right

      if unreservedWidth > 0 and numChildrenWithoutFixedWidth > 0:
        result.x = unreservedWidth / float(numChildrenWithoutFixedWidth)

proc calcChildRenderStartPosition(
  this: UIComponent,
  axis: static StackDirection,
  maxChildLen: float
): float =
  ## Calculates the starting position to render a child along the given axis (relative to the parent).
  ## availableLen: Available space on the axis to render children.
  ## maxChildLen: Maximum length of a child along the axis that does not have a fixed width/height.
  if this.stackDirection != axis:
    return this.paddingMarginOffset(axis)

  let availableLen: float =
    when axis == Horizontal:
      this.bounds.width - this.totalPadding(Horizontal)
    else:
      this.bounds.height - this.totalPadding(Vertical)

  template fixedChildLen(): float =
    when axis == Horizontal:
      child.width.pixelSize(availableLen)
    else:
      child.height.pixelSize(availableLen)

  template axisAlignment(): Alignment =
    if axis == Horizontal:
      this.alignHorizontal
    else:
      this.alignVertical

  case axisAlignment:
    of Start:
      return this.paddingMarginOffset(axis)

    of Center:
      var totalChildrenLen = 0.0
      for child in this.children:
        if fixedChildLen > 0:
          totalChildrenLen += fixedChildLen
        else:
          totalChildrenLen += maxChildLen

      return (availableLen - totalChildrenLen) / 2.0 + this.paddingMarginOffset(axis)

    of End:
      result = availableLen + this.paddingMarginOffset(axis)
      for child in this.children:
        if fixedChildLen > 0:
          result -= fixedChildLen
        else:
          result -= maxChildLen

proc updateChildrenBounds(
  this: UIComponent,
  startX: float,
  startY: float,
  maxChildSize: Vector
) =
  ## startX: Starting x position (relative to parent).
  ## startY: Starting y position (relative to parent).
  var
    x = startX
    y = startY
    prevChild: UIComponent

  for child in this.children:
    let
      childPixelWidth = child.width.pixelSize(this.bounds.width)
      childPixelHeight = child.height.pixelSize(this.bounds.height)
      width = if childPixelWidth > 0: childPixelWidth else: maxChildSize.x
      height = if childPixelHeight > 0: childPixelHeight else: maxChildSize.y

    case this.stackDirection:
      of Vertical:
        y += child.margin.top

        if prevChild != nil and prevChild.margin.bottom > child.margin.top:
          y += prevChild.margin.bottom - child.margin.top

        case this.alignHorizontal:
          of Start:
            discard
          of Center:
            x = startX + (this.bounds.width - width) / 2.0
          of End:
            x = startX + this.bounds.width - width

      of Horizontal:
        x += child.margin.left

        if prevChild != nil and prevChild.margin.right > child.margin.left:
          x += prevChild.margin.right - child.margin.left

        case this.alignVertical:
          of Start:
            discard
          of Center:
            y = startY + (this.bounds.height - height) / 2.0
          of End:
            y = startY + this.bounds.height - height

    child.updateBounds(x, y, width, height)

    case this.stackDirection:
      of Vertical:
        y += height
      of Horizontal:
        x += width

    prevChild = child

proc updateChildrenBounds*(this: UIComponent) =
  let maxChildSize = this.determineChildrenSize()
  let x = this.calcChildRenderStartPosition(Horizontal, maxChildSize.x)
  let y = this.calcChildRenderStartPosition(Vertical, maxChildSize.y)

  this.updateChildrenBounds(
    x + this.bounds.left,
    y + this.bounds.top,
    maxChildSize
  )

proc updateBounds(this: UIComponent, x, y, width, height: float) =
  ## Updates this bounds, and all children (deep).
  this.bounds.topLeft.x = x
  this.bounds.topLeft.y = y
  this.bounds.bottomRight.x = x + width
  this.bounds.bottomRight.y = y + height
  this.setLayoutValidationStatus(Valid)
  this.updateChildrenBounds()

method preRender*(this: UIComponent, ctx: Target, parentRenderBounds: AABB = AABB_INF) {.base.} =
  # TODO: We should be able to cache the renderBounds
  # and provide an offset for the actual rendering.
  # This means we wouldn't be reallocating the same shit every frame,
  # and only need to do it after a layout invalidation.
  let renderArea = aabb(
    this.bounds.left + this.margin.left,
    this.bounds.top + this.margin.top,
    this.bounds.right - this.margin.right,
    this.bounds.bottom - this.margin.bottom
  )

  if renderArea.left >= parentRenderBounds.right or
     renderArea.top >= parentRenderBounds.bottom or
     renderArea.width <= 0 or renderArea.height <= 0:
       # Prevents rendering outside parentRenderBounds.
       # Maybe can be optimized.
       return

  let clippedRenderBounds = aabb(
    max(parentRenderBounds.left, renderArea.left),
    max(parentRenderBounds.top, renderArea.top),
    min(parentRenderBounds.right, renderArea.right),
    min(parentRenderBounds.bottom, renderArea.bottom)
  )

  discard ctx.setClip(
    int16(clippedRenderBounds.left),
    int16(clippedRenderBounds.top),
    uint16(clippedRenderBounds.width),
    uint16(clippedRenderBounds.height)
  )

  ctx.rectangleFilled(
    clippedRenderBounds.left,
    clippedRenderBounds.top,
    clippedRenderBounds.right,
    clippedRenderBounds.bottom,
    this.backgroundColor
  )

  if this.borderWidth > 0.0:
    discard setLineThickness(this.borderWidth)
    ctx.rectangle(
      this.bounds.left + this.margin.left,
      this.bounds.top + this.margin.top,
      this.bounds.right - this.margin.right,
      this.bounds.bottom - this.margin.bottom,
      this.borderColor
    )

  this.postRender(ctx, clippedRenderBounds)

  for child in this.children:
    child.preRender(ctx, clippedRenderBounds)

  ctx.unsetClip()

method postRender*(this: UIComponent, ctx: Target, renderBounds: AABB) {.base.} =
  discard

