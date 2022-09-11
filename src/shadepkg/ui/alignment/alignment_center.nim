import ../ui_component

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

  if prevChild != nil:
    totalChildrenLen += prevChild.endMargin

  # Set child positions and sizes
  prevChild = nil
  var childStart: float =
    this.boundsStart + this.startPadding + this.borderWidth + totalAvailableLen / 2 - totalChildrenLen / 2

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
    totalAvailableLen = this.len() - this.totalPaddingAndBorders(axis)
    maxChildLen: float = determineDynamicChildLen(this, axis)
    center = this.boundsStart + this.startPadding + this.borderWidth + totalAvailableLen / 2

  for child in this.children:
    let
      childPixelLen = pixelLen(child, totalAvailableLen, axis)
      childLen = if childPixelLen > 0: childPixelLen else: (maxChildLen - child.startMargin - child.endMargin)
    
    var childStart: float = center - childLen / 2

    if childLen >= totalAvailableLen:
      # Center the child with margins added to its lengnth
      childStart = center - (childLen + child.startMargin + child.endMargin) / 2
    else:
      # Check if child needs to be pushed away from parent start (top or left)
      let parentStart = this.boundsStart + this.borderWidth + this.startPadding 
      if parentStart > childStart:
        childStart = parentStart + child.startMargin
      else:
        # Check if child needs to be pushed away from parent end (bottom or right)
        let
          parentEnd = this.boundsEnd - this.borderWidth - this.endPadding 
          childEnd = childStart + childLen + child.endMargin

        if parentEnd < childEnd:
          childStart = parentEnd - childLen

    child.set(childStart, childLen)

proc alignCenter*(this: UIComponent, axis: static StackDirection) =
  ## Aligns children along the given axis with Alignment.Center
  if axis == this.stackDirection:
    this.alignMainAxis(axis)
  else:
    this.alignCrossAxis(axis)

