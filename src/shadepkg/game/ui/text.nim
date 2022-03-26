import ../node

type TextBox* = ref object of Node
  text*: string
  width*: float
  height*: float

proc initTextBox*(textbox: TextBox, text: string, width, height: float) =
  initNode(textbox)

proc newTextBox*(text: string, width, height: float): TextBox =
  result = TextBox()
  initTextBox(result, text, width, height)

TextBox.renderAsNodeChild:
  discard

