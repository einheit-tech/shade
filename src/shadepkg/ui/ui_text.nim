import ui

type UITextComponent* = ref object of UIComponent
  text*: string
  color*: Color
  textAlignHorizontal*: Alignment
  textAlignVertical*: Alignment

