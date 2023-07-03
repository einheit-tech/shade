import sdl2_nim/[sdl, sdl_ttf]

import 
  ../node,
  ../../render/color,
  ../../math/vector2

export vector2

type
  TextBoxObj = object of Node
    font: Font
    text: string
    color: Color
    imageOfText: Image
    filter: Filter
    scale*: Vector

  TextBox* = ref TextBoxObj

proc `=destroy`(this: var TextBoxObj)

proc initTextBox*(
  textBox: TextBox,
  font: Font,
  text: string,
  color: Color = BLACK,
  renderFilter: Filter = FILTER_LINEAR_MIPMAP,
  scale: Vector = VECTOR_ONE
) =
  initNode(textBox)
  textBox.font = font
  textBox.text = text
  textBox.color = color
  textBox.imageOfText = nil
  textBox.filter = renderFilter
  textBox.scale = scale

proc newTextBox*(
  font: Font,
  text: string,
  color: Color = BLACK,
  renderFilter: Filter = FILTER_LINEAR_MIPMAP,
  scale: Vector = VECTOR_ONE
): TextBox =
  result = TextBox()
  initTextBox(result, font, text, color, renderFilter, scale)

proc setText*(this: TextBox, text: string) =
  this.text = text
  if this.imageOfText != nil:
    freeImage(this.imageOfText)
    this.imageOfText = nil

proc setRenderFilter*(this: TextBox, filter: Filter) =
  this.filter = filter
  if this.imageOfText != nil:
    this.imageOfText.setImageFilter(this.filter)

TextBox.renderAsNodeChild:
  if this.imageOfText == nil:
    let surface = renderText_Blended_Wrapped(
      this.font,
      cstring this.text,
      this.color,
      # Passing in 0 means lines only wrap on newline chars.
      0
    )
    this.imageOfText = copyImageFromSurface(surface)
    this.imageOfText.setImageFilter(this.filter)
    freeSurface(surface)

  blitScale(
    this.imageOfText,
    nil,
    ctx,
    this.x + offsetX,
    this.y + offsetY,
    this.scale.x,
    this.scale.y
  )

proc `=destroy`(this: var TextBoxObj) =
  if this.imageOfText != nil:
    freeImage(this.imageOfText)

