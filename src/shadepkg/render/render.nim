import sdl2_nim/sdl_gpu

export sdl_gpu except Camera

template renderAsChildOf*(ChildType, ParentType: typedesc, body: untyped): untyped =
  ## Helper for the render method.
  ## `this`, `ctx`, and `callback` are all injected.
  ## All code in the macro is ran inside the parent's render callback.
  ##
  ## Example:
  ## renderChild(B, A):
  ##   ctx.blit(...)
  ##   if callback != nil:
  ##    callback()

  method render*(
    this {.inject.}: `ChildType`,
    ctx {.inject.}: Target,
    callback {.inject.}: proc() = nil
  ) =
    procCall `ParentType`(this).render(ctx, proc =
      `body`
    )

template renderAsNodeChild*(ChildType: typedesc, body: untyped): untyped =
  ## Helper for the render method.
  ## `this`, `ctx`, and `callback` are all injected.
  ## All code in the macro is ran inside the parent's render callback.
  ##
  ## Example:
  ## renderNodeChild(T):
  ##   ctx.blit(...)
  ##   if callback != nil:
  ##    callback()
  ChildType.renderAsChildOf(Node):
    body

template renderAsParent*(T: typedesc, body: untyped): untyped =
  ## Creates a render method (for a superclass).
  method render*(
    this {.inject.}: `T`,
    ctx {.inject.}: Target,
    callback {.inject.}: proc() = nil
  ) {.base.} =
    `body`

template render*(T: typedesc, body: untyped): untyped =
  ## Creates a standalone render proc.
  proc render*(this {.inject.}: `T`, ctx {.inject.}: Target) =
    `body`

