import sdl2_nim/sdl_gpu
from ../math/mathutils import CompletionRatio
import
  ../math/vector2,
  ../math/aabb,
  ../render/color

export
  CompletionRatio,
  Vector,
  Color,
  Target

type
  SizeKind* = enum
    Pixel
    Ratio

  Size* = object
    case kind: SizeKind
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
    margin*: Insets
    padding*: Insets
    alignHorizontal*: Alignment
    alignVertical*: Alignment
    stackDirection*: StackDirection
    layoutStatus: ValidationStatus
    bounds: AABB
    backgroundColor*: Color
    clipToBounds*: bool

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

template totalPaddingAndMargin(this: UIComponent, axis: StackDirection): float =
  when axis == Horizontal:
    this.padding.left + this.margin.left + this.padding.right + this.margin.right
  else:
    this.padding.top + this.margin.top + this.padding.bottom + this.margin.bottom

template pixelWidth*(this: UIComponent, availableParentWidth: float): float =
  if this.width.kind == Pixel:
    this.width.pixelValue
  else:
    this.width.ratioValue * availableParentWidth

template pixelHeight*(this: UIComponent, availableParentHeight: float): float =
  if this.height.kind == Pixel:
    this.height.pixelValue
  else:
    this.height.ratioValue * availableParentHeight

method preRender*(this: UIComponent, ctx: Target, offsetX, offsetY: float) {.base.}
proc updateBounds*(this: UIComponent, x, y, width, height: float)

proc newUIComponent*(): UIComponent =
  return UIComponent(layoutStatus: Valid)

proc layoutValidationStatus*(this: UIComponent): lent ValidationStatus =
  return this.layoutStatus

proc setLayoutValidationStatus(this: UIComponent, status: ValidationStatus) =
  this.layoutStatus = status
  if status == Invalid and this.parent != nil and this.parent.layoutValidationStatus == Valid:
    this.parent.setLayoutValidationStatus(InvalidChild)

proc setWidth(this: UIComponent, width: float|Size) =
  when typeof(width) is Size:
    this.width = width
  else:
    if this.width.kind == Pixel:
      this.width.pixelValue = width
    else:
      this.width = Size(kind: Pixel, pixelValue: width)

proc setHeight(this: UIComponent, height: float|Size) =
  when typeof(height) is Size:
    this.height = height
  else:
    if this.height.kind == Pixel:
      this.height.pixelValue = height
    else:
      this.height = Size(kind: Pixel, pixelValue: height)

proc `width=`*(this: UIComponent, width: float|Size) =
  this.setWidth(width)
  this.setLayoutValidationStatus(Invalid)

proc `height=`*(this: UIComponent, height: float|Size) =
  this.setHeight(height)
  this.setLayoutValidationStatus(Invalid)

proc `size=`*(this: UIComponent, width, height: float|Size) =
  this.setWidth(width)
  this.setHeight(height)
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
  case this.layoutValidationStatus:
    of Valid:
      discard
    # TODO: Is there a better way to handle InvalidChild?
    of Invalid, InvalidChild:
      this.updateBounds(this.bounds.left, this.bounds.top, this.bounds.width, this.bounds.height)

proc determineChildrenSize(this: UIComponent): Vector =
  ## Calculates the size of children which do not have a fixed width or height.
  ## These children have a width or height <= 0.
  case this.stackDirection:
    of Vertical:
      result.x = this.bounds.width - this.totalPaddingAndMargin(Horizontal)

      var
        unreservedHeight = this.bounds.height - this.totalPaddingAndMargin(Vertical)
        numChildrenWithoutFixedHeight = this.children.len

      for child in this.children:
        let childPixelHeight = child.pixelHeight(unreservedHeight)
        if childPixelHeight > 0.0:
          unreservedHeight -= childPixelHeight
          numChildrenWithoutFixedHeight -= 1

      if unreservedHeight > 0 and numChildrenWithoutFixedHeight > 0:
        result.y = unreservedHeight / float(numChildrenWithoutFixedHeight)

    of Horizontal:
      result.y = this.bounds.height - this.totalPaddingAndMargin(Vertical)

      var
        unreservedWidth = this.bounds.width - this.totalPaddingAndMargin(Horizontal)
        numChildrenWithoutFixedWidth = this.children.len

      for child in this.children:
        let childPixelWidth = child.pixelWidth(unreservedWidth)
        if childPixelWidth > 0:
          unreservedWidth -= childPixelWidth
          numChildrenWithoutFixedWidth -= 1

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
      this.bounds.width - this.totalPaddingAndMargin(Horizontal)
    else:
      this.bounds.height - this.totalPaddingAndMargin(Vertical)

  template fixedChildLen(): float =
    when axis == Horizontal:
      child.pixelWidth(availableLen)
    else:
      child.pixelHeight(availableLen)

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

  for child in this.children:
    let
      childPixelWidth = child.pixelWidth(this.bounds.width)
      childPixelHeight = child.pixelHeight(this.bounds.height)
      width = if childPixelWidth > 0: childPixelWidth else: maxChildSize.x
      height = if childPixelHeight > 0: childPixelHeight else: maxChildSize.y

    case this.stackDirection:
      of Vertical:
        case this.alignHorizontal:
          of Start:
            discard
          of Center:
            x = startX + (this.bounds.width - width) / 2.0
          of End:
            x = startX + this.bounds.width - width

      of Horizontal:
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

proc updateChildrenBounds*(this: UIComponent) =
  let maxChildSize = this.determineChildrenSize()
  let x = this.calcChildRenderStartPosition(Horizontal, maxChildSize.x)
  let y = this.calcChildRenderStartPosition(Vertical, maxChildSize.y)

  this.updateChildrenBounds(
    x + this.bounds.left,
    y + this.bounds.top,
    maxChildSize
  )

proc updateBounds*(this: UIComponent, x, y, width, height: float) =
  ## Updates this bounds, and all children (deep).
  this.bounds.topLeft.x = x
  this.bounds.topLeft.y = y
  this.bounds.bottomRight.x = x + width
  this.bounds.bottomRight.y = y + height
  this.setLayoutValidationStatus(Valid)
  this.updateChildrenBounds()

method preRender*(this: UIComponent, ctx: Target, offsetX, offsetY: float) {.base.} =
  ctx.rectangleFilled(
    offsetX + this.bounds.left + this.margin.left,
    offsetY + this.bounds.top + this.margin.top,
    offsetX + this.bounds.right - this.margin.right,
    offsetY + this.bounds.bottom - this.margin.bottom,
    this.backgroundColor
  )

  for child in this.children:
    child.preRender(ctx, offsetX, offsetY)

method postRender*(this: UIComponent, ctx: Target, offsetX, offsetY: float) {.base.} =
  discard

