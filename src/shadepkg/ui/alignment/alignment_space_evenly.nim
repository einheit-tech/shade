import ../ui_component

from alignment_center import alignCrossAxis

template alignMainAxis(this: UIComponent, axis: static StackDirection) =
  let totalAvailableLen = this.len() - this.totalPaddingAndBorders(axis)
  let maxChildLen = determineDynamicChildLenMainAxis(this, axis)

  var
    totalChildrenLen: float
    prevChild: UIComponent

  # Calculate the total length all children use up
  for child in this.children:
    let
      childPixelLen = pixelLen(this, child, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen

    totalChildrenLen += childLen
    prevChild = child

  # Set child positions and sizes
  prevChild = nil
  let remainingSpace = totalAvailableLen - totalChildrenLen
  # TODO: Check when remainingSpace is negative
  let gap: float = if remainingSpace < 0: 0.0 else: remainingSpace / float(this.children.len + 1)

  var childStart: float = this.boundsStart + this.startPadding + this.borderWidth

  for child in this.children:
    let
      childPixelLen = pixelLen(this, child, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen

    let maxOfGapAndStartMargin = max(gap, child.startMargin)
    childStart += maxOfGapAndStartMargin

    if prevChild != nil and prevChild.endMargin > maxOfGapAndStartMargin:
      childStart += prevChild.endMargin - maxOfGapAndStartMargin

    child.set(childStart, childLen)

    childStart += childLen
    prevChild = child

proc alignSpaceEvenly*(this: UIComponent, axis: static StackDirection) =
  ## Aligns children along the given axis with Alignment.SpaceEvenly
  if axis == this.stackDirection:
    this.alignMainAxis(axis)
  else:
    this.alignCrossAxis(axis)

