import sdl2_nim/[sdl, sdl_gpu, sdl_ttf]
import
  ui,
  ../math/mathutils,
  ../math/aabb

type
  UITextComponentObj = object of UIComponent
    font: Font
    text: string
    color: Color
    imageOfText: Image
    textAlignHorizontal*: Alignment
    textAlignVertical*: Alignment

  UITextComponent* = ref UITextComponentObj

proc `=destroy`(this: var UITextComponentObj)

proc newText*(font: Font, text: string, color: Color = BLACK): UITextComponent =
  result = UITextComponent(font: font, text: text, color: color)

proc text*(this: UITextComponent): string =
  return this.text

proc `text=`*(this: UITextComponent, text: string) =
  this.text = text
  if this.imageOfText != nil:
    freeImage(this.imageOfText)
    this.imageOfText = nil

method postRender*(this: UITextComponent, ctx: Target, renderBounds: AABB) =
  procCall postRender(UIComponent this, ctx, renderBounds)

  if this.imageOfText == nil:
    let surface = renderText_Blended_Wrapped(
      this.font,
      cstring this.text,
      this.color,
      # Passing in 0 means lines only wrap on newline chars.
      0
    )
    this.imageOfText = copyImageFromSurface(surface)
    freeSurface(surface)

  blit(this.imageOfText, nil, ctx, renderBounds.center.x, renderBounds.center.y)

proc `=destroy`(this: var UITextComponentObj) =
  if this.imageOfText != nil:
    freeImage(this.imageOfText)

