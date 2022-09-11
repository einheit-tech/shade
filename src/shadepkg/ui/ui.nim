import sdl2_nim/sdl_gpu
from ../math/mathutils import CompletionRatio, ceil, floor

import
  ui_component,
  ../math/vector2,
  ../math/aabb,
  ../render/color,
  ../game/gamestate

export
  CompletionRatio,
  Vector,
  color,
  Target

type UI* = object
  root: UIComponent

method layout*(this: UI, width, height: float) {.base.}

proc setUIRoot*(this: var UI, root: UIComponent) =
  # Ensure the layout is performed when our root is reassigned.
  this.root = root

proc getUIRoot*(this: UI): UIComponent =
  this.root

proc newUI*(root: UIComponent): UI =
  result = UI(root: root)

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

method render*(this: UI, ctx: Target) {.base.} =
  if this.root != nil:
    this.root.preRender(ctx)

proc findLowestComponentContainingPoint*(this: UI, x, y: float): UIComponent =
  if this.root == nil:
    return nil

  result = this.root.findLowestComponentContainingPoint(x, y)
  if result == nil:
    return this.root

proc handlePress*(this: UI, x, y: float) =
  let component = this.findLowestComponentContainingPoint(x, y)
  if component != nil:
    component.handlePress(x, y)

