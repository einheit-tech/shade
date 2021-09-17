import
  ../errors,
  sdl2_nim/sdl_mixer as mixer

type
  Music* = mixer.Music
  SoundEffect* = mixer.Chunk
  AudioPlayer* = ref object

# AudioPlayer singleton
var Audio*: AudioPlayer

proc quitSdlMixer() =
  ## See sdl_mixer.quit
  while mixer.init(0) != 0:
    mixer.quit()

proc destroyAudioPlayerSingleton*() =
  # Should only need to call `closeAudio` once,
  # since we disallow multiple calls to `openAudio`.
  mixer.closeAudio()
  quitSdlMixer()
  Audio = nil

proc initAudioPlayerSingleton*(
  initFlags: int = INIT_OGG and INIT_MP3,
  frequency: int = mixer.DEFAULT_FREQUENCY,
  format: int = mixer.DEFAULT_FORMAT,
  channels: int = 2,
  chunksize: int = 2048
) =
  ## Initializes the AudioPlayer singleton (Audio).
  ## SDL must be initialized with `sdl.INIT_AUDIO` before this call.
  ##
  ## @see sdl_mixer.init for `flags`.
  ## @see sdl_mixer.openAudio for `frequency`, `format`, `channels`, and `chunksize`.
  if Audio != nil:
    raise newException(Exception, "AudioPlayer singleton already active!")

  let 
    initializedFlags = int mixer.init(cint initFlags)
    initSuccessful = (initializedFlags and initFlags) == initFlags

  if not initSuccessful:
    raise newException(Exception, "sdl_mixer.init() failed!")

  let openSuccessful: bool = mixer.openAudio(
    cint frequency,
    uint16 format,
    cint channels,
    cint chunksize
  ) == 0

  if not openSuccessful:
    raise newException(Exception, "sdl_mixer.openAudio() failed: " & $mixer.getError())

  Audio = AudioPlayer()

proc loadMusic*(filePath: string): Music =
  result = mixer.loadMUS(filePath)
  if result == nil:
    raise newException(Exception, "loadMusic: " & $mixer.getError())

proc loadSound*(filePath: string): SoundEffect =
  result = mixer.loadWAV(filePath)
  if result == nil:
    raise newException(Exception, "loadSound: " & $mixer.getError())

proc playMusic*(
  music: Music,
  volume: float = 1.0,
  numLoops: int = -1
) =
  ## music {Music} The music to play.
  ## volume {float} Volume (0.0 - 1.0) to play the music.
  ## numLoops {int} The number of times to loop the music.
  ##   -1 will cause the music to loop forever.
  ## @returns {bool} If the music playing was successful.
  discard mixer.volumeMusic(cint(volume * mixer.MAX_VOLUME))
  if mixer.playMusic(music, cint numLoops) != 0:
    raise newException(Exception, "Failed to play music: " & $mixer.getError())

proc getMusicVolume*(): float =
  ## @returns {float} Volume (0.0 - 1.0) of the music.
  return mixer.volumeMusic(-1) / MAX_VOLUME

proc setMusicVolume*(volume: float) =
  ## volume {float} Volume (0.0 - 1.0) to play the music.
  discard mixer.volumeMusic(cint (volume * mixer.MAX_VOLUME))

proc pauseMusic*() =
  mixer.pauseMusic()

proc resumeMusic*() =
  mixer.resumeMusic()

proc stopMusic*() =
  discard mixer.haltMusic()

proc fadeInMusic*(
  music: Music,
  timeInSeconds: float = 1.0,
  volume: float = 1.0,
  numLoops: int = -1
) =
  ## Fades out music over the given duration.
  ## music {Music} The music to play.
  ## volume {float} Volume (0.0 - 1.0) to play the music.
  ## numLoops {int} The number of times to loop the music.
  ##   -1 will cause the music to loop forever.
  discard mixer.volumeMusic(cint(volume * mixer.MAX_VOLUME))
  if mixer.fadeInMusic(music, cint numLoops, cint(timeInSeconds * 1000)) != 0:
    raise newException(Exception, "Failed to fade in music: " & $mixer.getError())

proc fadeOutMusic*(timeInSeconds: float = 1.0) =
  ## Fades out music over the given duration.
  discard mixer.fadeOutMusic(cint(timeInSeconds * 1000))

proc fadeOutSfx*(timeInSeconds: float = 1.0) =
  ## Fades out all sound effects over the given duration.
  discard mixer.fadeOutChannel(cint -1, cint(timeInSeconds * 1000))

# TODO: freeChunk and freeMusic must be called to free.
