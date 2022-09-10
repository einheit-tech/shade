import sdl2_nim/[sdl, sdl_gpu, sdl_ttf]
import
  ui,
  ../math/mathutils,
  ../math/aabb

type
  TextAlignment* = enum
    Start
    Center
    End

  UITextComponentObj = object of UIComponent
    font: Font
    text: string
    color: Color
    imageOfText: Image
    textAlignHorizontal*: TextAlignment
    textAlignVertical*: TextAlignment

  UITextComponent* = ref UITextComponentObj

proc `=destroy`(this: var UITextComponentObj) =
  if this.imageOfText != nil:
    freeImage(this.imageOfText)

proc newText*(font: Font, text: string, textColor: Color = BLACK): UITextComponent =
  result = UITextComponent(font: font, text: text)
  initUIComponent(UIComponent result)
  result.color = textColor

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
  if not this.visible:
    return

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

    this.width = float(this.imageOfText.w)
    this.height = float(this.imageOfText.h)

  # TODO: We should be able to cache all this stuff I believe?
  let
    contentArea = this.contentArea()
    scaleX = contentArea.width / float(this.imageOfText.w) 
    scaleY = contentArea.height / float(this.imageOfText.h)
    minScalar = min(scaleX, scaleY)

  let x = case this.textAlignHorizontal:
    of Start:
      contentArea.left + float(this.imageOfText.w) * minScalar / 2
    of Center:
      contentArea.center.x
    of End:
      contentArea.right - float(this.imageOfText.w) * minScalar / 2

  let y = case this.textAlignVertical:
    of Start:
      contentArea.top + float(this.imageOfText.h) * minScalar / 2
    of Center:
      contentArea.center.y
    of End:
      contentArea.bottom - float(this.imageOfText.h) * minScalar / 2

  blitScale(this.imageOfText, nil, ctx, x, y, minScalar, minScalar)

