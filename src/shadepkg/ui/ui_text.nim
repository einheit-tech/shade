import sdl2_nim/[sdl, sdl_gpu, sdl_ttf]
import
  ui_component,
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
    imageFilter*: Filter

  UITextComponent* = ref UITextComponentObj

proc determineWidthAndHeight*(this: UITextComponent)
proc `=destroy`(this: var UITextComponentObj) =
  if this.imageOfText != nil:
    freeImage(this.imageOfText)

proc newText*(
  font: Font,
  text: string,
  textColor: Color = BLACK,
  imageFilter: Filter = FILTER_LINEAR
): UITextComponent =
  result = UITextComponent(font: font, text: text)
  initUIComponent(UIComponent result)
  result.color = textColor
  result.imageFilter = imageFilter

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

proc determineWidthAndHeight*(this: UITextComponent) =
  ## Sets the width and height of the text based on text, font, and color.
  ## This is an expensive operation!
  ## Only use it when needed.
  if this.text.len == 0:
    this.imageOfText = nil
    return

  let surface = renderText_Blended_Wrapped(
    this.font,
    cstring this.text,
    this.color,
    # Passing in 0 means lines only wrap on newline chars.
    0
  )
  this.imageOfText = copyImageFromSurface(surface)
  this.imageOfText.setImageFilter(this.imageFilter)
  freeSurface(surface)

  this.width = float(this.imageOfText.w)
  this.height = float(this.imageOfText.h)

method preRender*(this: UITextComponent, ctx: Target, clippedRenderBounds: AABB) =
  if this.text.len == 0:
    return

  procCall preRender(UIComponent this, ctx, clippedRenderBounds)

  if this.imageOfText == nil:
    this.determineWidthAndHeight()

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

