import ../ui_component

template alignMainAxis(this: UIComponent, axis: static StackDirection) =
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

  if prevChild != nil:
    totalChildrenLen += prevChild.endMargin

  # Set child positions and sizes
  prevChild = nil
  var childStart: float =
    this.boundsEnd - this.endPadding - this.borderWidth - totalChildrenLen

  for child in this.children:
    let
      childPixelLen = pixelLen(this, child, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen

    childStart += child.startMargin

    child.set(childStart, childLen)

    childStart += childLen

    if prevChild != nil and prevChild.endMargin > child.startMargin:
      childStart += prevChild.endMargin - child.startMargin

    prevChild = child

template alignCrossAxis(this: UIComponent, axis: static StackDirection) =
  let
    maxChildLen: float = determineDynamicChildLen(this, axis)
    endPosition = this.boundsEnd - this.endPadding - this.borderWidth
    totalAvailableLen = this.len() - this.totalPaddingAndBorders(axis)

  for child in this.children:
    let
      childPixelLen = pixelLen(child, totalAvailableLen, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen
      childStart = endPosition - childLen

    child.set(childStart, childLen)

proc alignEnd*(this: UIComponent, axis: static StackDirection) =
  ## Aligns children along the given axis with Alignment.End
  if axis == this.stackDirection:
    this.alignMainAxis(axis)
  else:
    this.alignCrossAxis(axis)

