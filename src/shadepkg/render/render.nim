import sdl2_nim/sdl_gpu

export sdl_gpu except Camera

template renderAsChildOf*(ChildType, ParentType: typedesc, body: untyped): untyped =
  ## Helper for the render method.
  ##
  ## Example:
  ## renderChild(B, A):
  ##   ctx.blit(image, this.x + offsetX, this.y + offsetY)

  method render*(
    this {.inject.}: `ChildType`,
    ctx {.inject.}: Target,
    offsetX {.inject.}: float = 0,
    offsetY {.inject.}: float = 0
  ) =
    procCall `ParentType`(this).render(ctx, offsetX, offsetY)
    `body`

template renderAsNodeChild*(ChildType: typedesc, body: untyped): untyped =
  ## Helper for the render method.
  ##
  ## Example:
  ## renderNodeChild(T):
  ##   ctx.blit(image, this.x + offsetX, this.y + offsetY)
  ChildType.renderAsChildOf(Node):
    body

template renderAsParent*(T: typedesc, body: untyped): untyped =
  ## Creates a render method (for a superclass).
  method render*(
    this {.inject.}: `T`,
    ctx {.inject.}: Target,
    offsetX {.inject.}: float = 0,
    offsetY {.inject.}: float = 0
  ) {.base.} =
    `body`

template render*(T: typedesc, body: untyped): untyped =
  ## Creates a standalone render proc.
  proc render*(
    this {.inject.}: `T`,
    ctx {.inject.}: Target,
    offsetX {.inject.}: float = 0,
    offsetY {.inject.}: float = 0,
  ) =
    `body`

