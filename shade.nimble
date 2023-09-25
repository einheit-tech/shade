import
  std/os,
  strformat

# Package

version                            = "0.1.0"
author                             = "Einheit Technologies"
description                        = "Game Engine"
license                            = "GPLv2.0"
installDirs                        = @[ "src", "examplegame" ]
namedBin["src/shadepkg/buildtool"] = "src/shade"

# Dependencies

requires "nim >= 2.0.0"
requires "zippy == 0.9.7"
requires "https://github.com/avahe-kellenberger/sdl2_nim#head"
requires "safeseq >= 0.1.0"
requires "nimtest >= 0.1.2"
requires "seq2d >= 0.1.1"

task create_deps_artifact, "Compresses contents of .usr dir needed for development":
  exec "nim r -d:release src/shade.nim --compress"

task fetch_deps, "Fetches dependencies and extracts them to .usr/lib":
  exec "nim r -d:release -d:ssl src/shade.nim --fetch"

task extract_deps, "Extracts local dependencies (deps_artifact.tar.gz) to .usr/lib":
  exec "nim r -d:release -d:ssl src/shade.nim --extract"

# Tasks
task build_deps, "Builds submodule dependencies":
  exec "git submodule update --init"
  when defined(linux):
    let localUsrPath = joinPath(thisDir(), ".usr")
    withDir "submodules/sdl":
      exec fmt"./configure --prefix={localUsrPath} --enable-hidapi-libusb"
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

task shaders, "Runs the shader example":
  exec "nim r -d:release examples/shaders/water_shader.nim"

task post_shader, "Runs the post-processing shader example":
  exec "nim r -d:release examples/shaders/postprocessing.nim"

task animations, "Runs the animation player example":
  exec "nim r examples/basic/animationplayer_example.nim"

task physics, "Runs the physics example":
  exec "nim r -d:release examples/physics/physics_example.nim"

task physicsd, "Runs the physics example in debug mode":
  exec "nim r -d:debug -d:collisionoutlines -d:spatialgrid examples/physics/physics_example.nim"

task platformer, "Runs the platformer example":
  exec "nim r -d:release examples/platformer/platformer_example.nim"

task platformerd, "Runs the platformer example in debug mode":
  exec "nim r -d:debug -d:collisionoutlines examples/platformer/platformer_example.nim"

task textbox, "Runs the textbox example":
  exec "nim r -d:release examples/textbox/textbox_example.nim"

task runtests, "Runs all tests":
  exec "nimtest"

