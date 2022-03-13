import os

switch("multimethods", "on")

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
  putEnv("LD_LIBRARY_PATH", getEnv("LD_LIBRARY_PATH") & PathSep & libPath)

# Static link SDL2

--dynlibOverride:SDL2
--dynlibOverride:SDL2_gpu

# switch("passL", "-L '.usr/lib' -lSDL2 -lSDL2_gpu")

let sdl2Path = joinPath(libPath, "libSDL2.a")
let sdlgpuPath = joinPath(libPath, "libSDL2_gpu.a")

# --passL:sdl2Path
# --passL:sdlgpuPath

switch("passC", sdl2Path)
switch("passC", sdlgpuPath)
