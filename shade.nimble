# Package

version       = "0.1.0"
author        = "Einheit Technologies"
description   = "Game Engine"
license       = "GPLv2.0"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["shade"]


# Dependencies

requires "nim >= 1.6.2"
requires "sdl2_nim >= 2.0.14.3"

# Tasks
task shaders, "Runs the shader example":
  exec "nim r --threads:on --multimethods:on -d:inputdebug examples/shaders/simple.nim"

task animations, "Runs the animation player example":
  exec "nim r --threads:on --multimethods:on -d:inputdebug examples/basic/animationplayer_example.nim"

task physics, "Runs the physics example":
  exec "nim r -d:release --threads:on --multimethods:on -d:collisionoutlines -d:inputdebug examples/physics/physics_example.nim"

task platformer, "Runs the plateformer example":
  exec "nim r --threads:on --multimethods:on -d:collisionoutlines -d:inputdebug examples/physics/platformer_example.nim"

task runtests, "Runs all tests":
  exec "cd tests && nim r --hints:off testrunner.nim"

task release, "Builds a release shade executable":
  exec "nim c -d:release --threads:on --multimethods:on src/shade.nim"

