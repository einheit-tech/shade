import os
import strformat

# NOTE: Must copy or symlink dependencies into ./.modules
const deps = [
  "safeseq",
  "nimtest",
  "sdl2_nim",
  "seq2d",
  "zippy"
]

for dep in deps:
  switch("path", fmt"./.modules/{dep}")
  switch("path", fmt"./.modules/{dep}/src")

switch("gc", "orc")
switch("multimethods", "on")
switch("define", "ssl")

var
  path = getEnv("PATH")
  libPath = joinPath(thisDir(), ".usr", "lib")
  endSep = getEnv("PATH")[^1] == PathSep

if not endSep:
  path &= PathSep
path &= libPath
if endSep:
  path &= PathSep

putEnv("PATH", path)

when defined(linux):
  let ldLibPath = getEnv("LD_LIBRARY_PATH")
  if ldLibPath.len > 0:
    putEnv("LD_LIBRARY_PATH", ldLibPath & PathSep & libPath)
    putEnv("LIBRARY_PATH", ldLibPath & PathSep & libPath)
  else:
    putEnv("LD_LIBRARY_PATH", libPath)
    putEnv("LIBRARY_PATH", libPath)

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

task particles, "Runs the particles example":
  exec "nim r -d:release examples/particles/particles_example.nim"

task particlesd, "Runs the particles example in debug mode":
  exec "nim r -d:debug examples/particles/particles_example.nim"

task textbox, "Runs the textbox example":
  exec "nim r -d:release examples/textbox/textbox_example.nim"

task runtests, "Runs all tests":
  exec "nimtest"

