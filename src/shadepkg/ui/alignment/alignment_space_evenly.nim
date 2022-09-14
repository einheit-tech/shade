import ../ui_component

from alignment_center import alignCrossAxis

import std/heapqueue

template alignMainAxis(this: UIComponent, axis: static StackDirection) =
  mixin push

  let totalAvailableLen = this.len() - this.totalPaddingAndBorders(axis)
  let maxChildLen = determineDynamicChildLenMainAxis(this, axis)

  var
    totalChildrenLen: float
    margins = initHeapQueue[float]()
    prevChild: UIComponent

  # Calculate the total length all children use up
  for child in this.children:
    let
      childPixelLen = pixelLen(this, child, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen

    if prevChild == nil:
      margins.push(-child.startMargin)
    else:
      margins.push(-max(child.startMargin, prevChild.endMargin))

    totalChildrenLen += childLen
    prevChild = child

  if prevChild != nil:
    margins.push(-prevChild.endMargin)

  # Set child positions and sizes
  prevChild = nil

  # Calculate the gap size and remaining space in the parent
  var
    remainingSpace = totalAvailableLen - totalChildrenLen
    i = this.children.len + 1
    gap =
      if remainingSpace < 0:
        0.0
      else:
        remainingSpace / float(i)

  while margins.len > 0:
    let margin = -margins.pop()
    if margin <= gap:
      break

    remainingSpace -= margin
    i -= 1
    gap =
      if remainingSpace < 0:
        0.0
      else:
        remainingSpace / float(i)

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

