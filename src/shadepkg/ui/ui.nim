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
        pixelValue*: float
      of Ratio:
        ratioValue*: CompletionRatio

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

  OnPressedCallback* = proc(this: UIComponent, x, y: float)

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
    ## Bounds including padding, excluding margin.
    bounds: AABB
    backgroundColor*: Color
    borderWidth: float
    borderColor*: Color
    pressedCallbacks: seq[OnPressedCallback]

  UI* = object
    root: UIComponent

template ratio*(r: CompletionRatio): Size =
  Size(kind: Ratio, ratioValue: r)

template insets*(left, top, right, bottom: float): Insets =
  Insets(aabb(left, top, right, bottom))

template margin*(left, top, right, bottom: float): Insets =
  insets(left, top, right, bottom)

template padding*(left, top, right, bottom: float): Insets =
  insets(left, top, right, bottom)

template totalPaddingAndBorders(this: UIComponent, axis: StackDirection): float =
  when axis == Horizontal:
    this.padding.left + this.padding.right + this.borderWidth * 2
  else:
    this.padding.top + this.padding.bottom + this.borderWidth * 2

template pixelSize*(size: Size, availableParentSize: float): float =
  if size.kind == Pixel:
    size.pixelValue
  else:
    size.ratioValue * availableParentSize

template contentArea*(this: UIComponent): AABB =
  aabb(
    this.bounds.left + this.padding.left + this.borderWidth,
    this.bounds.top + this.padding.top + this.borderWidth,
    this.bounds.right - this.padding.right - this.borderWidth,
    this.bounds.bottom - this.padding.bottom - this.borderWidth
  )

proc `margin=`*(this: UIComponent, margin: float|Insets)
proc `padding=`*(this: UIComponent, padding: float|Insets)
proc `alignVertical=`*(this: UIComponent, alignment: Alignment)
proc `alignHorizontal=`*(this: UIComponent, alignment: Alignment)
proc `stackDirection=`*(this: UIComponent, direction: StackDirection)
method preRender*(this: UIComponent, ctx: Target, parentRenderBounds: AABB = AABB_INF) {.base.}
method postRender*(this: UIComponent, ctx: Target, renderBounds: AABB) {.base.}
proc updateBounds*(this: UIComponent, x, y, width, height: float)

proc `==`*(s1, s2: Size): bool =
  result = s1.kind == s2.kind
  if result:
    case s1.kind:
      of Pixel:
        result = s1.pixelValue == s2.pixelValue
      of Ratio:
        result = s1.ratioValue == s2.ratioValue

template `root=`*(this: UI, root: UIComponent) =
  # Ensure the layout is performed when our root is reassigned.
  this.root = root
  this.layout(gamestate.resolution.x, gamestate.resolution.y)

proc root*(this: UI): UIComponent =
  this.root

proc newUI*(root: UIComponent): UI =
  result = UI(root: root)

proc initUIComponent*(
  this: UIComponent,
  backgroundColor = TRANSPARENT,
  borderWidth = 0.0,
  borderColor = BLACK
) =
  this.layoutStatus = Invalid
  this.backgroundColor = backgroundColor
  this.borderWidth = borderWidth
  this.borderColor = borderColor

proc newUIComponent*(backgroundColor: Color = TRANSPARENT): UIComponent =
  result = UIComponent()
  initUIComponent(result, backgroundColor)

proc layoutValidationStatus*(this: UIComponent): lent ValidationStatus =
  return this.layoutStatus

proc setLayoutValidationStatus(this: UIComponent, status: ValidationStatus) =
  this.layoutStatus = status
  if status != Valid and this.parent != nil and this.parent.layoutValidationStatus == Valid:
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

proc borderWidth*(this: UIComponent): float =
  this.borderWidth

proc `borderWidth=`*(this: UIComponent, width: float) =
  this.borderWidth = width
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
  if this.root == nil:
    return

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
  ## NOTE: This does not account for margins in the axis opposite of this.stackDirection,
  ## as that is UNIQUE per child!

  case this.stackDirection:
    of Vertical:
      result.x = this.bounds.width - this.totalPaddingAndBorders(Horizontal)

      var
        unreservedHeight = this.bounds.height - this.totalPaddingAndBorders(Vertical)
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

      unreservedHeight -= prevChild.margin.bottom

      if unreservedHeight > 0 and numChildrenWithoutFixedHeight > 0:
        result.y = unreservedHeight / float(numChildrenWithoutFixedHeight)

    of Horizontal:
      result.y = this.bounds.height - this.totalPaddingAndBorders(Vertical)

      let totalAvailableWidth = this.bounds.width - this.totalPaddingAndBorders(Horizontal)

      var
        unreservedWidth = totalAvailableWidth
        numChildrenWithoutFixedWidth = this.children.len
        prevChild: UIComponent

      for child in this.children:
        let childPixelWidth = child.width.pixelSize(totalAvailableWidth)
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

proc calcChildRenderStartPosition(this: UIComponent, maxChildSize: Vector): Vector =
  ## Calculates the starting position to render a child along the given axisAlignment,
  ## relative to the parent's bounds.topLeft.
  ## maxChildSize: Maximum length of a child along the axis that does not have a fixed width/height.

  let contentArea = this.contentArea()

  result.x = this.padding.left + this.borderWidth
  result.y = this.padding.top + this.borderWidth

  if this.stackDirection == Horizontal:
    case this.alignHorizontal:
      of Start:
        result.x = this.padding.left + this.borderWidth

      of Center:
        var
          totalChildrenWidth: float
          prevChild: UIComponent

        for child in this.children:
          let size = child.width.pixelSize(contentArea.width)
          if size > 0:
            totalChildrenWidth += size
          else:
            totalChildrenWidth += maxChildSize.x

          totalChildrenWidth += child.margin.left

          if prevChild != nil:
            totalChildrenWidth += prevChild.margin.right - child.margin.left

          prevChild = child

        totalChildrenWidth += prevChild.margin.right

        result.x += (contentArea.width - totalChildrenWidth) / 2.0

      of End:
        result.x = this.bounds.width - this.padding.right - this.borderWidth

        var prevChild: UIComponent

        for child in this.children:
          let size = child.width.pixelSize(contentArea.width)
          if size > 0:
            result.x -= size
          else:
            result.x -= maxChildSize.x

          result.x -= child.margin.right

          if prevChild != nil:
            result.x -= (child.margin.left - prevChild.margin.right)

          prevChild = child

  else:

    case this.alignVertical:
      of Start:
        result.y = this.padding.top + this.borderWidth

      of Center:
        var
          totalChildrenHeight: float
          prevChild: UIComponent

        for child in this.children:
          let size = child.height.pixelSize(contentArea.height)
          if size > 0:
            totalChildrenHeight += size
          else:
            totalChildrenHeight += maxChildSize.y

          totalChildrenHeight += child.margin.top

          if prevChild != nil:
            totalChildrenHeight += prevChild.margin.bottom - child.margin.top

          prevChild = child

        totalChildrenHeight += prevChild.margin.bottom

        result.y = (contentArea.height - totalChildrenHeight) / 2.0

      of End:
        result.y = this.bounds.height - this.padding.bottom - this.borderWidth

        var prevChild: UIComponent

        for child in this.children:
          let size = child.height.pixelSize(contentArea.height)
          if size > 0:
            result.y -= size
          else:
            result.y -= maxChildSize.y

          result.y -= child.margin.bottom

          if prevChild != nil:
            result.y -= (child.margin.top - prevChild.margin.bottom)

          prevChild = child

proc updateChildrenBounds(this: UIComponent, startPosition: Vector, maxChildSize: Vector) =
  ## startX: Absolute starting x position
  ## startY: Absolute starting y position
  var
    x = startPosition.x
    y = startPosition.y
    prevChild: UIComponent

  for child in this.children:
    let
      childPixelWidth = child.width.pixelSize(this.bounds.width - this.totalPaddingAndBorders(Horizontal))
      childPixelHeight = child.height.pixelSize(this.bounds.height - this.totalPaddingAndBorders(Vertical))

    var
      width = if childPixelWidth > 0: childPixelWidth else: maxChildSize.x
      height = if childPixelHeight > 0: childPixelHeight else: maxChildSize.y

    case this.stackDirection:
      of Vertical:
        # Child designated to fill as much space as possible.
        if childPixelWidth <= 0:
          # Reduce size by margins in direction opposite of the stackDirection.
          width -= (child.margin.left + child.margin.right)

        case this.alignHorizontal:
          of Start:
            x = startPosition.x + child.margin.left
            y += child.margin.top
            if prevChild != nil and prevChild.margin.bottom > child.margin.top:
              y += prevChild.margin.bottom - child.margin.top

          of Center:
            x = startPosition.x + (this.bounds.width - width) / 2.0
            y += child.margin.top
            if prevChild != nil and prevChild.margin.bottom > child.margin.top:
              y += prevChild.margin.bottom - child.margin.top

          of End:
            x = this.bounds.right - this.padding.right - width - child.margin.right
            if prevChild != nil:
              y += max(child.margin.top, prevChild.margin.bottom)

      of Horizontal:

        # Child designated to fill as much space as possible.
        if childPixelHeight <= 0:
          # Reduce size by margins in direct asyncCheck ion opposite of the stackDirection.
          height -= (child.margin.top + child.margin.bottom)

        case this.alignVertical:
          of Start:
            x += child.margin.left
            y = startPosition.y + child.margin.top
            if prevChild != nil and prevChild.margin.right > child.margin.left:
              x += prevChild.margin.right - child.margin.left

          of Center:
            x += child.margin.left
            y = (this.bounds.height - height) / 2.0
            if prevChild != nil and prevChild.margin.right > child.margin.left:
              x += prevChild.margin.right - child.margin.left

          of End:
            y = this.bounds.bottom - this.padding.bottom - height - child.margin.bottom

            if prevChild != nil:
              x += max(child.margin.left, prevChild.margin.right)

    child.updateBounds(x, y, width, height)

    case this.stackDirection:
      of Vertical:
        y += height
      of Horizontal:
        x += width

    prevChild = child

proc updateChildrenBounds*(this: UIComponent) =
  let maxChildSize = this.determineChildrenSize()
  let startPosition = this.calcChildRenderStartPosition(maxChildSize)
  this.updateChildrenBounds(startPosition + this.bounds.topLeft, maxChildSize)

proc updateBounds(this: UIComponent, x, y, width, height: float) =
  ## Updates this bounds, and all children (deep).
  this.bounds.topLeft.x = x
  this.bounds.topLeft.y = y
  this.bounds.bottomRight.x = x + width
  this.bounds.bottomRight.y = y + height
  this.setLayoutValidationStatus(Valid)

  if this.children.len > 0:
    this.updateChildrenBounds()

method render*(this: UI, ctx: Target) {.base.} =
  if this.root != nil:
    this.root.preRender(ctx)

method preRender*(this: UIComponent, ctx: Target, parentRenderBounds: AABB = AABB_INF) {.base.} =
  if this.bounds.left >= parentRenderBounds.right or
     this.bounds.top >= parentRenderBounds.bottom or
     this.bounds.width <= 0 or this.bounds.height <= 0:
       # Prevents rendering outside parentRenderBounds.
       # Maybe can be optimized.
       return

  # TODO: Clip at content area (padding)
  let clippedRenderBounds = aabb(
    max(parentRenderBounds.left, this.bounds.left),
    max(parentRenderBounds.top, this.bounds.top),
    min(parentRenderBounds.right, this.bounds.right),
    min(parentRenderBounds.bottom, this.bounds.bottom)
  )

  block:
    let
      flooredLeft = floor clippedRenderBounds.left
      flooredTop = floor clippedRenderBounds.top

    discard ctx.setClip(
      int16 flooredLeft,
      int16 flooredTop,
      uint16(ceil(clippedRenderBounds.left + clippedRenderBounds.width) - flooredLeft),
      uint16(ceil(clippedRenderBounds.top + clippedRenderBounds.height) - flooredTop)
    )

  if this.backgroundColor.a != 0:
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
      this.bounds.left,
      this.bounds.top,
      this.bounds.right,
      this.bounds.bottom,
      this.borderColor
    )

  this.postRender(ctx, clippedRenderBounds)

  for child in this.children:
    child.preRender(ctx, clippedRenderBounds)

  ctx.unsetClip()

method postRender*(this: UIComponent, ctx: Target, renderBounds: AABB) {.base.} =
  discard

# Touch/click event handling

proc findLowestComponentContainingPoint*(this: UIComponent, x, y: float): UIComponent =
  for child in this.children:
    if child != nil and child.bounds.contains(x, y):
      let nextLowest = child.findLowestComponentContainingPoint(x, y)
      if nextLowest == nil:
        return child
      result = nextLowest

proc findLowestComponentContainingPoint*(this: UI, x, y: float): UIComponent =
  if this.root == nil:
    return nil

  result = this.root.findLowestComponentContainingPoint(x, y)
  if result == nil:
    return this.root

proc handlePress*(this: UI, x, y: float) =
  let component = this.findLowestComponentContainingPoint(x, y)
  if component != nil:
    for callback in component.pressedCallbacks:
      component.callback(x, y)

proc onPressedCallbacks*(this: UIComponent): lent seq[OnPressedCallback] =
  return this.pressedCallbacks

proc addOnPressedCallback*(this: UIComponent, callback: OnPressedCallback) =
  this.pressedCallbacks.add(callback)

proc removeOnPressedCallback*(this: UIComponent, callback: OnPressedCallback) =
  var callbackIndex = -1
  for i, cb in this.pressedCallbacks:
    if cb == callback:
      callbackIndex = i
      break

  if callbackIndex != -1:
    this.pressedCallbacks.del(callbackIndex)

template onPressed*(component: UIComponent, body: untyped) =
  ## Invokes `body` whenever the component is pressed.
  component.addOnPressedCallback(proc(this {.inject.}: UIComponent, x, y {.inject.}: float) = body)

