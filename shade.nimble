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
requires "opengl >= 1.1.0"
requires "staticglfw >= 4.1.2"
requires "pixie#122956a8930c70fe4384fb3bc743be82884612df"

