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
requires "sdl2_nim >= 2.0.14.2"

# Tasks
task example, "Runs the basic example":
  exec "nim -d:collisionoutlines -d:inputdebug r examples/basic/basic_game.nim"

