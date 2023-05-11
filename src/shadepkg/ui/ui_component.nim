# TODO: Document how the system should work
# Caveats, such as UIComponent not being clickable if not visible, etc.

import sdl2_nim/sdl_gpu

from ../math/mathutils import CompletionRatio, ceil, floor

import std/[hashes]
import safeseq

import
  ../math/vector2,
  ../math/aabb,
  ../render/color

export
  CompletionRatio,
  Vector,
  color,
  safeseq

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
    SpaceEvenly
  
  StackDirection* = enum
    Vertical
    Horizontal
    Overlap

  ValidationStatus* = enum
    Valid
    Invalid
    InvalidChild

  OnPressedCallback* = proc(x, y: float)

  UIComponent* = ref object of RootObj
    id: int
    ## Top-down design: child components cannot cause their parent components to resize.
    parent: UIComponent
    children: SafeSeq[UIComponent]
    visible: bool
    enabled: bool
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
    processInputEvents*: bool

template ratio*(r: CompletionRatio): Size =
  Size(kind: Ratio, ratioValue: r)

template insets*(left, top, right, bottom: float): Insets =
  Insets(aabb(left, top, right, bottom))

template margin*(left, top, right, bottom: float): Insets =
  insets(left, top, right, bottom)

template padding*(left, top, right, bottom: float): Insets =
  insets(left, top, right, bottom)

template totalPaddingAndBorders*(this: UIComponent, axis: StackDirection): float =
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
proc `visible=`*(this: UIComponent, visible: bool)
proc `enabled=`*(this: UIComponent, enabled: bool)
proc alignVertical*(this: UIComponent): Alignment
proc `alignVertical=`*(this: UIComponent, alignment: Alignment)
proc alignHorizontal*(this: UIComponent): Alignment
proc `alignHorizontal=`*(this: UIComponent, alignment: Alignment)
proc `stackDirection=`*(this: UIComponent, direction: StackDirection)
method preRender*(this: UIComponent, ctx: Target, clippedRenderBounds: AABB) {.base.}
method postRender*(this: UIComponent, ctx: Target) {.base.}
proc updateBounds*(this: UIComponent, x, y, width, height: float)
proc updateChildren(this: UIComponent, axis: static StackDirection)
proc addOnPressedCallback*(this: UIComponent, callback: OnPressedCallback)

template onPressed*(component: UIComponent, body: untyped) =
  ## Invokes `body` whenever the component is pressed.
  component.addOnPressedCallback(proc(x, y {.inject.}: float) = body)

proc `==`*(s1, s2: Size): bool =
  result = s1.kind == s2.kind
  if result:
    case s1.kind:
      of Pixel:
        result = s1.pixelValue == s2.pixelValue
      of Ratio:
        result = s1.ratioValue == s2.ratioValue

proc hash*(this: UIComponent): Hash =
  return hash(this.id)

var i = 0

proc initUIComponent*(
  this: UIComponent,
  backgroundColor = TRANSPARENT,
  borderWidth = 0.0,
  borderColor = BLACK
) =
  this.id = i
  this.children = newSafeSeq[UIComponent]()
  this.layoutStatus = Invalid
  this.backgroundColor = backgroundColor
  this.borderWidth = borderWidth
  this.borderColor = borderColor
  this.visible = true
  this.enabled = true
  this.processInputEvents = true

  inc i

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

proc margin*(this: UIComponent): Insets =
  return this.margin

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

proc visible*(this: UIComponent): bool =
  this.visible

proc `visible=`*(this: UIComponent, visible: bool) =
  if this.visible == visible:
    return

  this.visible = visible
  this.setLayoutValidationStatus(Invalid)

proc enabled*(this: UIComponent): bool =
  this.enabled

proc `enabled=`*(this: UIComponent, enabled: bool) =
  if this.enabled == enabled:
    return

  this.enabled = enabled
  this.setLayoutValidationStatus(Invalid)

proc enableAndSetVisible*(this: UIComponent) =
  `visible=`(this, true)
  `enabled=`(this, true)

proc disableAndHide*(this: UIComponent) =
  `visible=`(this, false)
  `enabled=`(this, false)

proc alignVertical*(this: UIComponent): Alignment =
  return this.alignVertical

proc `alignVertical=`*(this: UIComponent, alignment: Alignment) =
  this.alignVertical = alignment
  this.setLayoutValidationStatus(Invalid)

proc alignHorizontal*(this: UIComponent): Alignment =
  return this.alignHorizontal

proc `alignHorizontal=`*(this: UIComponent, alignment: Alignment) =
  this.alignHorizontal = alignment
  this.setLayoutValidationStatus(Invalid)

proc `stackDirection=`*(this: UIComponent, direction: StackDirection) =
  this.stackDirection = direction
  this.setLayoutValidationStatus(Invalid)

proc parent*(this: UIComponent): UIComponent =
  return this.parent

proc children*(this: UIComponent): lent SafeSeq[UIComponent] =
  return this.children

proc addChild*(this, child: UIComponent) =
  this.children.add(child)
  child.parent = this
  this.setLayoutValidationStatus(Invalid)

proc removeChild*(this, child: UIComponent) =
  this.children.remove(child)
  this.setLayoutValidationStatus(Invalid)

proc bounds*(this: UIComponent): lent AABB =
  return this.bounds

method update*(this: UIComponent, deltaTime: float) {.base.} =
  discard

proc updateChildrenBounds*(this: UIComponent) =
  this.updateChildren(Vertical)
  this.updateChildren(Horizontal)

  for child in this.children:
    if child.children.len > 0:
      child.updateChildrenBounds()

proc updateBounds(this: UIComponent, x, y, width, height: float) =
  ## Updates this bounds, and all children (deep).
  this.bounds.topLeft.x = x
  this.bounds.topLeft.y = y
  this.bounds.bottomRight.x = x + width
  this.bounds.bottomRight.y = y + height
  this.setLayoutValidationStatus(Valid)

  if this.children.len > 0:
    this.updateChildrenBounds()

method preRender*(this: UIComponent, ctx: Target, clippedRenderBounds: AABB) {.base.} =
  if this.backgroundColor.a != 0:
    ctx.rectangleFilled(
      this.bounds.left,
      this.bounds.top,
      this.bounds.right,
      this.bounds.bottom,
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

method postRender*(this: UIComponent, ctx: Target) {.base.} =
  discard

proc render*(this: UIComponent, ctx: Target, parentRenderBounds: AABB = AABB_INF) =
  if not this.visible:
    return

  if this.bounds.left >= parentRenderBounds.right or
     this.bounds.top >= parentRenderBounds.bottom or
     this.bounds.width <= 0 or this.bounds.height <= 0:
       # Prevents rendering outside parentRenderBounds.
       # Maybe can be optimized.
       return

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

  this.preRender(ctx, clippedRenderBounds)

  for child in this.children:
    child.render(ctx, clippedRenderBounds)

  this.postRender(ctx)

  ctx.unsetClip()

# Touch/click event handling

proc findLowestComponentContainingPoint*(this: UIComponent, x, y: float): UIComponent =
  ## Finds the deepest (lowest) component that contains the given point.
  ## The component must be visible, enabled, and processing input events.
  if this == nil or not (this.enabled and this.processInputEvents and this.visible):
    return nil

  for child in this.children:
    if child != nil and
       child.enabled and child.processInputEvents and child.visible and
       child.bounds.contains(x, y):
         let nextLowest = child.findLowestComponentContainingPoint(x, y)
         if nextLowest == nil:
           return child
         result = nextLowest

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

proc handlePress*(this: UIComponent, x, y: float) =
  for callback in this.pressedCallbacks:
    callback(x, y)

#### Alignment

template layout*(this: UIComponent, start, length: float) =
  when axis == Horizontal:
    this.bounds.left = start
    this.bounds.right = start + length
  else:
    this.bounds.top = start
    this.bounds.bottom = start + length

template boundsStart*(this: UIComponent): float =
  when axis == Horizontal:
    this.bounds.left
  else:
    this.bounds.top

template boundsEnd*(this: UIComponent): float =
  when axis == Horizontal:
    this.bounds.right
  else:
    this.bounds.bottom

template len*(this: UIComponent): float =
  when axis == Horizontal:
    this.bounds.width
  else:
    this.bounds.height

template startPadding*(this: UIComponent): float =
  when axis == Horizontal:
    this.padding.left
  else:
    this.padding.top

template endPadding*(this: UIComponent): float =
  when axis == Horizontal:
    this.padding.right
  else:
    this.padding.bottom

template startMargin*(this: UIComponent): float =
  when axis == Horizontal:
    this.margin.left
  else:
    this.margin.top

template endMargin*(this: UIComponent): float =
  when axis == Horizontal:
    this.margin.right
  else:
    this.margin.bottom

template pixelLen*(parent, child: UIComponent, axis: static StackDirection): float =
  let parentLen = parent.len - parent.totalPaddingAndBorders(axis)
  when axis == Horizontal:
    pixelSize(child.width, parentLen)
  else:
    pixelSize(child.height, parentLen)

template pixelLen*(this: UIComponent, axisLen: float, axis: static StackDirection): float =
  when axis == Horizontal:
    pixelSize(this.width, axisLen)
  else:
    pixelSize(this.height, axisLen)

template determineDynamicChildLenMainAxis*(this: UIComponent, axis: static StackDirection): float =
  let totalAvailableLen = this.len() - this.totalPaddingAndBorders(axis)

  var
    unreservedLen = totalAvailableLen
    prevChild: UIComponent
    numChildrenWithoutFixedLen = this.children.len

  for child in this.children:
    if not child.visible and not child.enabled:
      numChildrenWithoutFixedLen -= 1
      continue

    let childPixelLen = child.pixelLen(totalAvailableLen, axis)
    if childPixelLen > 0:
      unreservedLen -= childPixelLen
      numChildrenWithoutFixedLen -= 1

    if prevChild != nil:
      unreservedLen -= max(child.startMargin, prevChild.endMargin)
    else:
      unreservedLen -= child.startMargin

    prevChild = child

  if prevChild != nil:
    unreservedLen -= prevChild.endMargin

  if unreservedLen > 0 and numChildrenWithoutFixedLen > 0:
    unreservedLen / float(numChildrenWithoutFixedLen)
  else:
    0.0

template determineDynamicChildLenCrossAxis*(this: UIComponent, axis: static StackDirection): float =
  this.len() - this.totalPaddingAndBorders(axis)

from alignment/alignment_start import alignStart
from alignment/alignment_center import alignCenter
from alignment/alignment_end import alignEnd
from alignment/alignment_space_evenly import alignSpaceEvenly

proc updateChildren(this: UIComponent, axis: static StackDirection) =
  let alignment =
    when axis == Horizontal:
      this.alignHorizontal
    else:
      this.alignVertical

  case alignment:
    of Start:
      this.alignStart(axis)
    of Center:
      this.alignCenter(axis)
    of End:
      this.alignEnd(axis)
    of SpaceEvenly:
      this.alignSpaceEvenly(axis)

  for child in this.children:
    child.setLayoutValidationStatus(Valid)

