import shade

## Set the filters that are used to determine which objects collide and which ones don't: 
## http://chipmunk-physics.net/release/ChipmunkLatest-Docs/#cpShape-Filtering
const
  GROUND* = 0b0001
  PLAYER* = 0b0010
  BALL* = 0b0100

converter intToBitmask*(i: int): Bitmask = Bitmask i
converter intToGroup*(i: int): Group = cast[Group](i)

