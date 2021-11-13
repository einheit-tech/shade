# Package

version       = "0.1.0"
author        = "Einheit Technologies"
description   = "Game Engine"
license       = "GPLv2.0"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["shade"]


# Dependencies

requires "nim >= 1.4.6"
requires "sdl2_nim >= 2.0.14.3"
requires "chipmunk7 >= 7.0.3"
requires "vmath >= 1.1.0"

# Tasks
task example, "Runs the basic example":
  exec "nim -d:collisionoutlines -d:checkSafeCollisionShapes -d:inputdebug r examples/basic/basic_game.nim"

task physics, "Runs the physics example":
  exec "nim -d:collisionoutlines -d:checkSafeCollisionShapes -d:inputdebug r examples/physics/physics_example.nim"

task platformer, "Runs the platformer example":
  exec "nim r examples/platformer/platformer_example.nim"

task platformerd, "Runs the platformer example with debug options enabled":
  exec "nim -d:debug -d:collisionoutlines -d:spriteBounds r examples/platformer/platformer_example.nim"

task runtests, "Runs all tests":
  exec "cd tests && nim r --hints:off testrunner.nim"

task release, "Builds a release shade executable":
  exec "nim c -d:release --opt:speed --multimethods:on src/shade.nim"

