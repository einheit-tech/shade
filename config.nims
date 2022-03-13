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

  switch("passL", joinPath(libPath, "libSDL2.a"))
  switch("passL", joinPath(libPath, "libSDL2_gpu.a"))

when defined(emscripten):
  import std/compilesettings
  import strformat

  # This path will only run if -d:emscripten is passed to nim.
  --nimcache:tmp # Store intermediate files close by in the ./tmp dir.

  --os:linux # Emscripten pretends to be linux.
  --cpu:wasm32 # Emscripten is 32bits.
  --cc:clang # Emscripten is very close to clang, so we ill replace it.
  when defined(windows):
    --clang.exe:emcc.bat  # Replace C
    --clang.linkerexe:emcc.bat # Replace C linker
    --clang.cpp.exe:emcc.bat # Replace C++
    --clang.cpp.linkerexe:emcc.bat # Replace C++ linker.
  else:
    --clang.exe:emcc  # Replace C
    --clang.linkerexe:emcc # Replace C linker
    --clang.cpp.exe:emcc # Replace C++
    --clang.cpp.linkerexe:emcc # Replace C++ linker.
  --listCmd # List what commands we are running so that we can debug them.

  --gc:orc # GC:arc is friendlier with crazy platforms.
  --exceptions:goto # Goto exceptions are friendlier with crazy platforms.
  --define:noSignalHandler # Emscripten doesn't support signal handlers.

  --dynlibOverride:SDL2
  --dynlibOverride:SDL2_gpu

  switch("passL", joinPath(libPath, "libSDL2.a"))
  switch("passL", joinPath(libPath, "libSDL2_gpu.a"))

  when defined(opengl):
    --dynlibOverride:opengl

  --define:emscripten

  switch("passL", "-o shade.html --shell-file shell_minimal.html")
