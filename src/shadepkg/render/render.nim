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

template translate*(ctx: Target, x, y, z: float, body: untyped) =
  ## Translate the given context, executes the body,
  ## then translates the context back to its starting position.
  translate(x, y, z)
  body
  translate(-x, -y, -z)

template translate*(ctx: Target, x, y: float, body: untyped) =
  ## Translate the given context, executes the body,
  ## then translates the context back to its starting position.
  ##
  ## `z` defaults to 1, which is what most 2D games would utilize.
  translate(ctx, x, y, 1, body)

template rotate*(ctx: Target, degrees, x, y, z: float, body: untyped) =
  ## Rotates the given context, executes the body,
  ## then rotates the context back to its starting position.
  rotate(degrees, x, y, z)
  body
  rotate(degrees, -x, -y, -z)

template rotate*(ctx: Target, degrees: float, body: untyped) =
  ## Rotates the given context, executes the body,
  ## then rotates the context back to its starting position.
  ##
  ## The x, y, and z values default to 0, 0, and 1 respectively.
  ## This is what most 2D games would use.
  rotate(ctx, degrees, 0, 0, 1, body)

template scale*(ctx: Target, x, y, z: float, body: untyped) =
  ## Scales the given context, executes the body,
  ## then scales the context back to its starting size.
  scale(x, y, z)
  body
  scale(1 / x, 1 / y, 1 / z)

template scale*(ctx: Target, x, y: float, body: untyped) =
  ## Scales the given context, executes the body,
  ## then scales the context back to its starting size.
  ##
  ## `z` defaults to 1, which is what most 2D games would utilize.
  scale(ctx, x, y, 1, body)

