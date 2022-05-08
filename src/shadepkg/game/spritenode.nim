import
  node,
  sprite

export node, sprite

type SpriteNode* = ref object of Node
  sprite*: Sprite

proc initSpriteNode*(spriteNode: SpriteNode, sprite: Sprite, flags = UPDATE_RENDER_FLAGS) =
  initNode(Node(spriteNode), flags)
  spriteNode.sprite = sprite

proc newSpriteNode*(sprite: Sprite, flags = UPDATE_RENDER_FLAGS): SpriteNode =
  result = SpriteNode()
  initSpriteNode(result, sprite, flags)

proc newSpriteNode*(image: Image, flags = UPDATE_RENDER_FLAGS): SpriteNode =
  result = newSpriteNode(newSprite(image), flags)

SpriteNode.renderAsNodeChild:
  this.sprite.render(ctx)

