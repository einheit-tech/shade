We are giving CollisionShapes to the AABBTree,
but their positions are relative to the parent and not the game world.

As a temp work around,
PhysicsBody needs a getBounds() function that will be the offset bounds of the CollisionShape.

The collisionshape should be non-changing for now, right?

