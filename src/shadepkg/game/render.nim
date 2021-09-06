import macros
import pixie

macro render*(this: typedesc, parent: typedesc, body: untyped): untyped =
  ## Macro as a helper for the render method.
  ## `this`, `ctx`, and `callback` are all injected.
  ## All code in the macro is ran inside the parent's render callback.
  ##
  ## Example:
  ## render(B, A):
  ##   ctx.fillStyle = rgba(255, 0, 0, 255)
  ##   let
  ##     pos = vec2(50, 50)
  ##     wh = vec2(100, 100)
  ##   ctx.fillRect(rect(pos, wh))
  ##   if callback != nil:
  ##    callback()

  quote do:
    method render*(
      this {.inject.}: `this`,
      ctx {.inject.}: Context,
      callback {.inject.}: proc() = nil
    ) =
      procCall `parent`(this).render(ctx, proc =
        `body`
      )

