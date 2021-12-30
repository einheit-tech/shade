import sdl2_nim/sdl_gpu

export sdl_gpu except Camera

template renderNodeChild*(ChildType: typedesc, ParentType: typedesc, body: untyped): untyped =
  ## Macro as a helper for the render method.
  ## `this`, `ctx`, and `callback` are all injected.
  ## All code in the macro is ran inside the parent's render callback.
  ##
  ## Example:
  ## renderNodeChild(B, A):
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

template render*(T: typedesc, body: untyped): untyped =
  proc render*(this {.inject.}: `T`, ctx {.inject.}: Target) =
    `body`

