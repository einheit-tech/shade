import ui

type UI* = object
  root*: UIComponent

proc update*(this: UI, deltaTime: float) =
  discard

proc preRender*(this: UI, ctx: Target, width, height: float) =
  discard

proc postRender*(this: UI, ctx: Target, width, height: float) =
  discard

