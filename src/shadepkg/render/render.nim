import 
  macros,
  sdl2_nim/sdl_gpu

export sdl_gpu except Camera

macro render*(ChildType: typedesc, ParentType: typedesc, body: untyped): untyped =
  ## Macro as a helper for the render method.
  ## `this`, `ctx`, and `callback` are all injected.
  ## All code in the macro is ran inside the parent's render callback.
  ##
  ## Example:
  ## render(B, A):
  ##   ctx.blit(...)
  ##   if callback != nil:
  ##    callback()

  quote do:
    method render*(
      this {.inject.}: `ChildType`,
      ctx {.inject.}: Target,
      callback {.inject.}: proc() = nil
    ) =
      procCall `ParentType`(this).render(ctx, proc =
        `body`
      )

