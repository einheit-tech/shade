import ../ui_component

proc alignStartDetermineDynamicChildLen(this: UIComponent, axis: static StackDirection): float =
  ## Calculates the length of children along the axis which do not have a fixed width or height.
  ## These children have a width or height <= 0.
  ## NOTE: This does not account for margins in the axis opposite of this.stackDirection,
  ## as that is UNIQUE per child!

  # case this.stackDirection:
  #   of Vertical:
  #     result.x = this.bounds.width - this.totalPaddingAndBorders(Horizontal)

  #     var
  #       unreservedHeight = this.bounds.height - this.totalPaddingAndBorders(Vertical)
  #       numChildrenWithoutFixedHeight = this.children.len
  #       prevChild: UIComponent

  #     for child in this.children:
  #       let childPixelHeight = child.height.pixelSize(unreservedHeight)
  #       if childPixelHeight > 0.0:
  #         unreservedHeight -= childPixelHeight
  #         numChildrenWithoutFixedHeight -= 1

  #       if prevChild != nil:
  #         unreservedHeight -= max(child.margin.top, prevChild.margin.bottom)
  #       else:
  #         unreservedHeight -= child.margin.top

  #       prevChild = child

  #     unreservedHeight -= prevChild.margin.bottom

  #     if unreservedHeight > 0 and numChildrenWithoutFixedHeight > 0:
  #       result.y = unreservedHeight / float(numChildrenWithoutFixedHeight)

  #   of Horizontal:
  #     result.y = this.bounds.height - this.totalPaddingAndBorders(Vertical)

  #     let totalAvailableWidth = this.bounds.width - this.totalPaddingAndBorders(Horizontal)

  #     var
  #       unreservedWidth = totalAvailableWidth
  #       numChildrenWithoutFixedWidth = this.children.len
  #       prevChild: UIComponent

  #     for child in this.children:
  #       let childPixelWidth = child.width.pixelSize(totalAvailableWidth)
  #       if childPixelWidth > 0:
  #         unreservedWidth -= childPixelWidth
  #         numChildrenWithoutFixedWidth -= 1

  #       if prevChild != nil:
  #         unreservedWidth -= max(child.margin.left, prevChild.margin.right)
  #       else:
  #         unreservedWidth -= child.margin.left

  #       prevChild = child

  #     if prevChild != nil:
  #       unreservedWidth -= prevChild.margin.right

  #     if unreservedWidth > 0 and numChildrenWithoutFixedWidth > 0:
  #       result.x = unreservedWidth / float(numChildrenWithoutFixedWidth)

  #   of Overlap:
  #     result = this.contentArea.getSize()

proc alignStartMainAxis(this: UIComponent, axis: static StackDirection) =
  var childStart =
    when axis == Horizontal:
      this.bounds.left + this.borderWidth + this.padding.left
    else:
      this.bounds.top + this.borderWidth + this.padding.top

  let maxChildLen: float = this.alignStartDetermineDynamicChildLen(axis)

  var prevChild: UIComponent

  for child in this.children:
    let
      childPixelLen = pixelLen(this, child, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen

    childStart += child.startMargin
    child.setStart(childStart)

    childStart += child.len

    if prevChild != nil and prevChild.endMargin > child.startMargin:
      childStart += prevChild.endMargin - child.startMargin

    prevChild = child

proc alignStartCrossAxis(this: UIComponent, axis: static StackDirection) =
  let childStart =
    when axis == Horizontal:
      this.bounds.top + this.borderWidth + this.padding.top
    else:
      this.bounds.left + this.borderWidth + this.padding.left

  let maxChildLen: float = this.alignStartDetermineDynamicChildLen(axis)

  for child in this.children:
    child.setStart(childStart + child.startMargin)

    let
      childPixelLen = pixelLen(this, child, axis)
      childLen = if childPixelLen > 0: childPixelLen else: maxChildLen

    child.setLen(childLen)

proc alignStart*(this: UIComponent, axis: static StackDirection) =
  ## Aligns children along the given axis with Alignment.Start
  if axis == this.stackDirection:
    this.alignStartMainAxis(axis)
  else:
    this.alignStartCrossAxis(axis)

