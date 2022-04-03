import
  std/os,
  strformat

# Package

version               = "0.1.0"
author                = "Einheit Technologies"
description           = "Game Engine"
license               = "GPLv2.0"
srcDir                = "src"
installExt            = @["nim"]
skipDirs              = @[".github", "examples", "tests", "submodules"]
namedBin["buildtool"] = "shade"

# Dependencies

requires "nim == 1.6.4"
requires "sdl2_nim == 2.0.14.3"
requires "zippy == 0.9.7"
requires "https://github.com/avahe-kellenberger/safeset"
requires "https://github.com/avahe-kellenberger/nimtest"

task create_deps_artifact, "Compresses contents of .usr dir needed for development":
  exec "nim r -d:release src/shade.nim --compress"

# Tasks
task build_deps, "Runs the shader example":
  exec "git submodule update --init"
  when defined(linux):
    let localUsrPath = joinPath(thisDir(), ".usr")
    withDir "submodules/sdl":
      exec fmt"./configure --prefix={localUsrPath}"
      exec "make -j install"

    withDir "submodules/sdl-gpu":
      mkDir "build"
      withDir "build":
        exec fmt"cmake -B . -S .. -G 'Unix Makefiles' -DCMAKE_INSTALL_PREFIX={localUsrPath}"
        exec "make -j install"

    withDir "submodules/sdl_ttf":
      exec fmt"./configure --prefix={localUsrPath}"
      exec "make -j install"

    withDir "submodules/sdl_mixer":
      mkDir "build"
      withDir "build":
        exec fmt"../configure --prefix={localUsrPath}"
        exec "make -j"
        exec "make install"

    withDir fmt"{localUsrPath}/lib":
      exec "rm -r *.a *.la cmake pkgconfig"

  exec "nimble install -dy"

task shaders, "Runs the shader example":
  exec "nim r examples/shaders/simple.nim"

task animations, "Runs the animation player example":
  exec "nim r examples/basic/animationplayer_example.nim"

task physics, "Runs the physics example":
  exec "nim r -d:release examples/physics/physics_example.nim"

task physicsd, "Runs the physics example in debug mode":
  exec "nim r -d:debug examples/physics/physics_example.nim"

task platformer, "Runs the platformer example":
  exec "nim r -d:release examples/platformer/platformer_example.nim"

task platformerd, "Runs the platformer example in debug mode":
  exec "nim r -d:debug examples/platformer/platformer_example.nim"

task textbox, "Runs the textbox example":
  exec "nim r -d:release examples/textbox/textbox_example.nim"

task runtests, "Runs all tests":
  exec "nimtest"


