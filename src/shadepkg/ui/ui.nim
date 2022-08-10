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

    # TODO: How do we render the root at a specific location?
    parent: UIComponent
    children: seq[UIComponent]
    width: float
    height: float
    margin*: Insets
    padding*: Insets
    alignHorizontal*: Alignment
    alignVertical*: Alignment
    stackDirection*: StackDirection
    layoutValidationStatus: ValidationStatus
    bounds: AABB
    backgroundColor*: Color
    clipToBounds*: bool

proc newUIComponent*(): UIComponent =
  return UIComponent(layoutValidationStatus: ValidationStatus.Valid)

template invalidateLayout(this: UIComponent) =
  # TODO: When should this be "Invalid" vs InvalidChild?
  this.layoutValidationStatus = Invalid

proc `width=`*(this: UIComponent, width: float) =
  this.width = width
  this.invalidateLayout()

proc `height=`*(this: UIComponent, height: float) =
  this.height = height
  this.invalidateLayout()

proc `size=`*(this: UIComponent, width, height: float) =
  this.width = width
  this.height = height
  this.invalidateLayout()

proc parent*(this: UIComponent): UIComponent =
  return this.parent

proc children*(this: UIComponent): lent seq[UIComponent] =
  return this.children

proc addChild*(this, child: UIComponent) =
  this.children.add(child)
  child.parent = this
  this.invalidateLayout()

proc layoutValidationStatus*(this: UIComponent): lent ValidationStatus =
  return this.layoutValidationStatus

proc bounds*(this: UIComponent): lent AABB =
  return this.bounds

method update*(this: UIComponent, deltaTime: float) {.base.} =
  discard

method preRender*(this: UIComponent, ctx: Target, width, height: float) {.base.} =
  discard

method postRender*(this: UIComponent, ctx: Target, width, height: float) {.base.} =
  discard

