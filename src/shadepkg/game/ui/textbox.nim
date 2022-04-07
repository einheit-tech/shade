import sdl2_nim/[sdl, sdl_ttf]

import 
  ../node,
  ../../render/color

type
  TextBoxObj = object of Node
    font: Font
    text: string
    color: Color
    imageOfText: Image

  TextBox* = ref TextBoxObj

proc `=destroy`(this: var TextBoxObj)

proc initTextBox*(textBox: TextBox, font: Font, text: string, color: Color = BLACK) =
  initNode(textBox)
  textBox.font = font
  textBox.text = text
  textBox.color = color
  textBox.imageOfText = nil

proc newTextBox*(font: Font, text: string, color: Color = BLACK): TextBox =
  result = TextBox()
  initTextBox(result, font, text, color)

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
    freeSurface(surface)

  blit(this.imageOfText, nil, ctx, 0, 0)

proc `=destroy`(this: var TextBoxObj) =
  if this.imageOfText != nil:
    freeImage(this.imageOfText)

