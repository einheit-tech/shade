import ../ui_component

template determineDynamicChildLenMainAxis(this: UIComponent, axis: static StackDirection): float =
  let totalAvailableLen = this.len() - this.totalPaddingAndBorders(axis)

  var
    unreservedLen = totalAvailableLen
    numChildrenWithoutFixedLen = this.children.len
    prevChild: UIComponent

  for child in this.children:
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

template determineDynamicChildLenCrossAxis(this: UIComponent, axis: static StackDirection): float =
  this.len() - this.totalPaddingAndBorders(axis)

template determineDynamicChildLen(this: UIComponent, axis: static StackDirection): float =
  ## Calculates the length of children along the axis which do not have a fixed width or height.
  ## These children have a width or height <= 0.
  ## NOTE: This does not account for margins in the axis opposite of this.stackDirection,
  ## as that is UNIQUE per child!
  if this.stackDirection == axis:
    determineDynamicChildLenMainAxis(this, axis)
  else:
    determineDynamicChildLenCrossAxis(this, axis)

template alignMainAxis(this: UIComponent, axis: static StackDirection) =
  let totalAvailableLen = this.len() - this.totalPaddingAndBorders(axis)
  let maxChildLen = determineDynamicChildLen(this, axis)

  var
    totalChildrenLen: float
    prevChild: UIComponent

  # Calculate the total length all children use up
  for child in this.children:
    let
      childPixelLen = pixelLen(this, child, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen

    totalChildrenLen += childLen + child.startMargin

    if prevChild != nil and prevChild.endMargin > child.startMargin:
      totalChildrenLen += prevChild.endMargin - child.startMargin

    prevChild = child

  # Set child positions and sizes
  prevChild = nil
  var childStart: float =
    this.start + this.startPadding + this.borderWidth + totalAvailableLen / 2 - totalChildrenLen / 2

  for child in this.children:
    let
      childPixelLen = pixelLen(this, child, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen

    child.set(childStart, childLen)

    childStart += childLen + child.startMargin

    if prevChild != nil and prevChild.endMargin > child.startMargin:
      childStart += prevChild.endMargin - child.startMargin

    prevChild = child

template alignCrossAxis(this: UIComponent, axis: static StackDirection) =
  let
    totalAvailableLen = this.len() - this.totalPaddingAndBorders(axis)
    maxChildLen: float = determineDynamicChildLen(this, axis)
    center = this.start + this.startPadding + this.borderWidth + totalAvailableLen / 2

  for child in this.children:
    let
      childPixelLen = pixelLen(child, totalAvailableLen, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen
      childStart = center - childLen / 2

    child.set(childStart, childLen)

proc alignCenter*(this: UIComponent, axis: static StackDirection) =
  ## Aligns children along the given axis with Alignment.Start
  if axis == this.stackDirection:
    this.alignMainAxis(axis)
  else:
    this.alignCrossAxis(axis)

