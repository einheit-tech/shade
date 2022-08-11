import sdl2_nim/sdl_gpu
from ../math/mathutils import CompletionRatio
import
  ../math/vector2,
  ../math/aabb,
  ../render/color

export
  CompletionRatio,
  Vector,
  Color,
  Target

type
  Size* = Vector
  PixelSize* = Size
  RatioSize* = object
    x: CompletionRatio
    y: CompletionRatio

  Insets* = AABB

  Alignment* = enum
    Start
    Center
    End
  
  StackDirection* = enum
    Vertical
    Horizontal

  ValidationStatus* = enum
    Valid
    Invalid
    InvalidChild

  UIComponent* = ref object of RootObj
    ## Top-down design: child components cannot cause their parent components to resize.
    parent: UIComponent
    children: seq[UIComponent]
    width: float
    height: float
    margin*: Insets
    padding*: Insets
    alignHorizontal*: Alignment
    alignVertical*: Alignment
    stackDirection*: StackDirection
    layoutStatus: ValidationStatus
    bounds: AABB
    backgroundColor*: Color
    clipToBounds*: bool

proc newUIComponent*(): UIComponent =
  return UIComponent(layoutStatus: Invalid)

proc layoutValidationStatus*(this: UIComponent): lent ValidationStatus =
  return this.layoutValidationStatus

proc `layoutValidationStatus=`(this: UIComponent, status: ValidationStatus) =
  this.layoutValidationStatus = status
  case status:
    of Valid:
      discard
    of Invalid:
      if this.parent != nil and this.parent.layoutValidationStatus == Valid:
        this.parent.layoutValidationStatus = InvalidChild
    of InvalidChild:
      discard

proc `width=`*(this: UIComponent, width: float) =
  this.width = width
  this.layoutValidationStatus = Invalid

proc `height=`*(this: UIComponent, height: float) =
  this.height = height
  this.layoutValidationStatus = Invalid

proc `size=`*(this: UIComponent, width, height: float) =
  this.width = width
  this.height = height
  this.layoutValidationStatus = Invalid

proc parent*(this: UIComponent): UIComponent =
  return this.parent

proc children*(this: UIComponent): lent seq[UIComponent] =
  return this.children

proc addChild*(this, child: UIComponent) =
  this.children.add(child)
  child.parent = this
  this.layoutValidationStatus = Invalid

proc bounds*(this: UIComponent): lent AABB =
  return this.bounds

method update*(this: UIComponent, deltaTime: float) {.base.} =
  discard

method preRender*(this: UIComponent, ctx: Target, width, height: float) {.base.} =
  ctx.rectangleFilled(
    this.margin.left,
    this.margin.top,
    width - this.margin.right,
    height - this.margin.bottom,
    this.backgroundColor
  )

method postRender*(this: UIComponent, ctx: Target, width, height: float) {.base.} =
  discard

