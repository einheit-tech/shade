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

method preRender*(this: UIComponent, ctx: Target, offsetX, offsetY, width, height: float) {.base.}

proc newUIComponent*(): UIComponent =
  return UIComponent(layoutStatus: Invalid)

proc layoutValidationStatus*(this: UIComponent): lent ValidationStatus =
  return this.layoutValidationStatus

proc `layoutValidationStatus=`(this: UIComponent, status: ValidationStatus) =
  this.layoutStatus = status
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

proc renderChildren*(this: UIComponent, ctx: Target, offsetX, offsetY, width, height: float) =
  let
    left = offsetX + this.margin.left + this.padding.left
    right = width + offsetX - this.margin.right - this.padding.right
    top = offsetY + this.margin.top + this.padding.top
    bottom = height + offsetY - this.margin.bottom - this.padding.bottom

  let (childWidth, childHeight) =
    case this.stackDirection:
      of Vertical:
        (right - left, (bottom - top) / float(this.children.len))
      of Horizontal:
        ((right - left) / float(this.children.len), bottom - top)

  case this.stackDirection:
    of Vertical:
      for i, child in this.children:
        child.preRender(
          ctx, 
          left,
          top + childHeight * float i,
          childWidth,
          childHeight
        )
    of Horizontal:
      for i, child in this.children:
        child.preRender(
          ctx, 
          left + childWidth * float i,
          top,
          childWidth,
          childHeight
        )

method preRender*(this: UIComponent, ctx: Target, offsetX, offsetY, width, height: float) {.base.} =
  ctx.rectangleFilled(
    offsetX + this.margin.left,
    offsetY + this.margin.top,
    offsetX + width - this.margin.right,
    offsetY + height - this.margin.bottom,
    this.backgroundColor
  )

  if this.children.len > 0:
    this.renderChildren(ctx, offsetX, offsetY, width, height)

method postRender*(this: UIComponent, ctx: Target, offsetX, offsetY, width, height: float) {.base.} =
  discard

