import
  entity,
  sprite

export entity, sprite

type SpriteEntity* = ref object of Entity
  sprite*: Sprite

proc initSpriteEntity*(spriteEntity: SpriteEntity, sprite: Sprite, flags = UPDATE_AND_RENDER) =
  initEntity(Entity(spriteEntity), flags)
  spriteEntity.sprite = sprite

proc newSpriteEntity*(sprite: Sprite, flags = UPDATE_AND_RENDER): SpriteEntity =
  result = SpriteEntity()
  initSpriteEntity(result, sprite, flags)

proc newSpriteEntity*(image: Image, flags = UPDATE_AND_RENDER): SpriteEntity =
  result = newSpriteEntity(newSprite(image), flags)

SpriteEntity.renderAsEntityChild:
  this.sprite.render(ctx, this.x + offsetX, this.y + offsetY)

