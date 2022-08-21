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

proc `=destroy`(this: var UITextComponentObj) =
  if this.imageOfText != nil:
    freeImage(this.imageOfText)

proc newText*(font: Font, text: string, color: Color = BLACK): UITextComponent =
  result = UITextComponent(font: font, text: text, color: color)
  initUIComponent(UIComponent result, borderWidth = 0.0)

proc text*(this: UITextComponent): string =
  return this.text

proc `text=`*(this: UITextComponent, text: string) =
  this.text = text
  if this.imageOfText != nil:
    freeImage(this.imageOfText)
    this.imageOfText = nil

proc color*(this: UITextComponent): Color =
  return this.color

proc `color=`*(this: UITextComponent, color: Color) =
  this.color = color
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

  let x = case this.textAlignHorizontal:
    of Start:
      renderBounds.left + float(this.imageOfText.w) / 2
    of Center:
      renderBounds.center.x
    of End:
      renderBounds.right - float(this.imageOfText.w) / 2

  let y = case this.textAlignVertical:
    of Start:
      renderBounds.top + float(this.imageOfText.h) / 2
    of Center:
      renderBounds.center.y
    of End:
      renderBounds.bottom - float(this.imageOfText.h) / 2

  blit(this.imageOfText, nil, ctx, x, y)

