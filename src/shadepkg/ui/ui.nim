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
  Size* = float
  PixelSize* = Size
  RatioSize* = CompletionRatio

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

method preRender*(this: UIComponent, ctx: Target, offsetX, offsetY: float) {.base.}
proc updateBounds*(this: UIComponent, x, y, width, height: float)

proc newUIComponent*(): UIComponent =
  return UIComponent(layoutStatus: Valid)

proc layoutValidationStatus*(this: UIComponent): lent ValidationStatus =
  return this.layoutStatus

proc `layoutValidationStatus=`(this: UIComponent, status: ValidationStatus) =
  this.layoutStatus = status
  if status == Invalid and this.parent != nil and this.parent.layoutValidationStatus == Valid:
    this.parent.layoutValidationStatus = InvalidChild

proc `width=`*(this: UIComponent, width: float) =
  this.width = width
  this.layoutValidationStatus = Invalid

proc `height=`*(this: UIComponent, height: float) =
  this.height = height
  this.layoutValidationStatus = Invalid

proc `size=`*(this: UIComponent, width, height: float) =
  this.width = width
  this.height = height
  this.layoutValidationStatus = Invalid

proc parent*(this: UIComponent): UIComponent =
  return this.parent

proc children*(this: UIComponent): lent seq[UIComponent] =
  return this.children

proc addChild*(this, child: UIComponent) =
  this.children.add(child)
  child.parent = this
  this.layoutValidationStatus = Invalid

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
  ## These children have a width and height <= 0.
  case this.stackDirection:
    of Vertical:
      result.x = this.bounds.width - this.totalPaddingAndMargin(Horizontal)

      var
        unreservedHeight = this.bounds.height - this.totalPaddingAndMargin(Vertical)
        numChildrenWithoutFixedHeight = this.children.len

      for child in this.children:
        if child.height > 0:
          unreservedHeight -= child.height
          numChildrenWithoutFixedHeight -= 1

      if unreservedHeight > 0 and numChildrenWithoutFixedHeight > 0:
        result.y = unreservedHeight / float(numChildrenWithoutFixedHeight)

    of Horizontal:
      result.y = this.bounds.height - this.totalPaddingAndMargin(Vertical)

      var
        unreservedWidth = this.bounds.width - this.totalPaddingAndMargin(Horizontal)
        numChildrenWithoutFixedWidth = this.children.len

      for child in this.children:
        if child.width > 0:
          unreservedWidth -= child.width
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
  ## maxChildWidth: Maximum length of a child along the axis that does not have a fixed width/height.
  if this.stackDirection != axis:
    return this.paddingMarginOffset(axis)

  template fixedChildLen(): Size =
    when axis == Horizontal:
      child.width
    else:
      child.height

  let availableLen: float =
    when axis == Horizontal:
      this.bounds.width - this.totalPaddingAndMargin(Horizontal)
    else:
      this.bounds.height - this.totalPaddingAndMargin(Vertical)

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

      return (availableLen - totalChildrenLen) / 2.0

    of End:
      result = availableLen
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
    let width = if child.width > 0: child.width else: maxChildSize.x
    let height = if child.height > 0: child.height else: maxChildSize.y
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
  this.layoutValidationStatus = Valid
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

