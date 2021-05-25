# Package

version       = "0.1.0"
author        = "Einheit Technologies"
description   = "Game Engine"
license       = "GPLv2.0"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["engine"]


# Dependencies

requires "nim >= 1.4.6"
requires "opengl >= 1.1.0"
requires "staticglfw >= 4.1.2"
requires "pixie >= 2.0.0"

