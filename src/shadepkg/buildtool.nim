import
  std/httpclient,
  zippy/[tarballs, tarballs_v1],
  parseopt,
  strformat,
  strutils,
  os,
  re

const
  usrDir = ".usr"
  usrLibDir = fmt"{usrDir}/lib"
  artifactFilename = "deps_artifact.tar.gz"
  artifactDownloadLink = fmt"https://github.com/avahe-kellenberger/shade/raw/master/{artifactFilename}"

proc fetchAndExtractDependencies()
proc cleanup()

template withDir(dir: string, body: untyped) =
  let startingDir = getCurrentDir()
  setCurrentDir(dir)
  body
  setCurrentDir(startingDir)

proc printHelp() =
  echo fmt"""
    Options:
      --help
        Prints this help message

      --init directory
        Initializes a new shade project at the given directory.

      --compress
        Compresses the contents of "{usrLibDir}"

      --fetch
        Fetches and extracts an archive to "{usrLibDir}"
  """.dedent()

proc init(dir: string) =
  ## Creates a new project with a given name, fetches deps, extracts, nimble install -dy etc.

  # Copy the example game to the new project dir.
  let exampleGamePath = joinPath(parentDir(getAppDir()), "examplegame")
  echo fmt"exampleGamePath: {exampleGamePath}"
  copyDir(exampleGamePath, dir)

  withDir(dir):
    fetchAndExtractDependencies()
    discard execShellCmd "nimble install -dy"

proc cleanup() =
  withDir(usrLibDir):
    # Delete symlinks
    for (pathComponentKind, path) in walkDir("."):
      if pathComponentKind == pcLinkToFile:
        removeFile path

    # Rename files to be the proper foo.so names
    for (pathComponentKind, path) in walkDir("."):
      if pathComponentKind == pcFile and path =~ re"\.\/(.*)\-.*\.so.*":
        moveFile(path, fmt"{matches[0]}.so")

proc compress() =
  cleanup()
  createTarball(usrLibDir, artifactFilename)

proc fetchAndExtractDependencies() =
  let client = newHttpClient()
  client.downloadFile(artifactDownloadLink, artifactFilename)
  # NOTE: extractAll requires the destination to NOT exist.
  removeDir(usrLibDir)
  extractAll(artifactFilename, usrDir)

when isMainModule:
  var optParser = initOptParser()
  let remainingArgs = optParser.remainingArgs()
  # Only supporting one option at a time, currently.
  if remainingArgs.len == 0:
    printHelp()
    quit()

  let command = remainingArgs[0]
  case command:
    of "--init":
      if remainingArgs.len >= 2:
        init(remainingArgs[1])
      else:
        echo "--init must be given a destination directory."
    of "--compress":
      compress()
    of "--fetch":
      fetchAndExtractDependencies()
    else:
      printHelp()

