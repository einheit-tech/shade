import ../ui

template start(child: UIComponent): float =
  when axis == Horizontal:
    child.bounds.left
  else:
    child.bounds.top

template setStart(child: UIComponent, value: float) =
  when axis == Horizontal:
    child.bounds.left = value
  else:
    child.bounds.top = value

template length(child: UIComponent): float =
  when axis == Horizontal:
    child.bounds.width
  else:
    child.bounds.height

template setLength(child: UIComponent, value: float) =
  when axis == Horizontal:
    child.bounds.width = value
  else:
    child.bounds.height = value

proc alignMainAxis(this: UIComponent, axis: static StackDirection) =
  var childStart =
    when axis == Horizontal:
      this.bounds.left + this.borderWidth + this.padding.left
    else:
      this.bounds.top + this.borderWidth + this.padding.top

  # TODO: Can reuse logic from ui.nim to account for margins.
  # Also will need dynamic child size.
  for child in this.children:
    child.setStart(childStart)
    childStart += child.length()

proc alignCrossAxis(this: UIComponent, axis: static StackDirection) =
  discard

proc alignStart*(this: UIComponent, axis: static StackDirection) =
  ## Aligns children along the given axis with Alignment.Start
  if axis == this.stackDirection:
    this.alignMainAxis(axis)
  else:
    this.alignCrossAxis(axis)

