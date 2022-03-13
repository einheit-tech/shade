import
  std/os,
  strformat

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
task setup, "Runs the shader example":
  exec "git submodule update --init"
  when defined(linux):
    let localUsrPath = joinPath(thisDir(), ".usr")
    withDir "submodules/sdl":
      mkDir "build"
      withDir "build":
        exec fmt"cmake -B . -S .. -G 'Unix Makefiles' -DEMSCRIPTEN=on -DCMAKE_INSTALL_PREFIX={localUsrPath} -DSDL_STATIC=on -DSDL_SHARED=off" 
        exec "make -j install"
    withDir "submodules/sdl-gpu":
      mkDir "build"
      withDir "build":
        exec fmt"cmake -B . -S .. -G 'Unix Makefiles' -DEMSCRIPTEN=on -DCMAKE_INSTALL_PREFIX={localUsrPath} -DBUILD_STATIC=on -DBUILD_SHARED=off"
        exec "make -j install"
  exec "nimble install -dy"

task shaders, "Runs the shader example":
  exec "nim r --multimethods:on -d:inputdebug examples/shaders/simple.nim"

task animations, "Runs the animation player example":
  exec "nim r --multimethods:on -d:inputdebug examples/basic/animationplayer_example.nim"

task physics, "Runs the physics example":
  exec "nim r -d:release --multimethods:on -d:inputdebug examples/physics/physics_example.nim"

task physicsd, "Runs the physics example in debug mode":
  exec "nim r -d:debug --multimethods:on -d:inputdebug examples/physics/physics_example.nim"

task platformer, "Runs the platformer example":
  exec "nim r -d:release --multimethods:on -d:inputdebug examples/platformer/platformer_example.nim"

task platformerd, "Runs the platformer example in debug mode":
  exec "nim r -d:debug --multimethods:on -d:inputdebug examples/platformer/platformer_example.nim"

task runtests, "Runs all tests":
  withDir "tests":
    exec "nim r -d:debug testrunner.nim"

task release, "Builds a release shade executable":
  exec "nim c -d:release --multimethods:on src/shade.nim"

