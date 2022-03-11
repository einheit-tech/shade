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

when defined(linux):
  let
    localUsrPath = absolutePath(".usr")
    libPath = absolutePath(".usr/lib")

  putEnv("PATH", getEnv("PATH") & PathSep & libPath)
  putEnv("LD_LIBRARY_PATH", getEnv("LD_LIBRARY_PATH") & PathSep & libPath)

# Tasks
task setup, "Runs the shader example":
  when defined(linux):
    let localUsrPath = absolutePath(".usr")
    exec "git submodule update --init"
    withDir "submodules/sdl-gpu":
      exec fmt"cmake -G 'Unix Makefiles' -DCMAKE_INSTALL_PREFIX={localUsrPath}"
      exec "make"
      exec "make install"
  else:
    echo "No setup prepared for your operating system."

task shaders, "Runs the shader example":
  exec "nim r --threads:on --multimethods:on -d:inputdebug examples/shaders/simple.nim"

task animations, "Runs the animation player example":
  exec "nim r --threads:on --multimethods:on -d:inputdebug examples/basic/animationplayer_example.nim"

task physics, "Runs the physics example":
  exec "nim r -d:release --threads:on --multimethods:on -d:inputdebug examples/physics/physics_example.nim"

task physicsd, "Runs the physics example in debug mode":
  exec "nim r -d:debug --threads:on --multimethods:on -d:inputdebug examples/physics/physics_example.nim"

task platformer, "Runs the platformer example":
  exec "nim r -d:release --threads:on --multimethods:on -d:inputdebug examples/platformer/platformer_example.nim"

task platformerd, "Runs the platformer example in debug mode":
  exec "nim r -d:debug --threads:on --multimethods:on -d:inputdebug examples/platformer/platformer_example.nim"

task runtests, "Runs all tests":
  withDir "tests":
    exec "nim r -d:debug testrunner.nim"

task release, "Builds a release shade executable":
  exec "nim c -d:release --threads:on --multimethods:on src/shade.nim"

