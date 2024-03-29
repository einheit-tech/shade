import sdl2_nim/sdl_mixer as mixer
import sdl2_nim/sdl

const DEFAULT_AUDIO_FREQUENCY* {.intdefine.} = mixer.DEFAULT_FREQUENCY

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

# TODO: Allow audio settings to be passed in via compiler flags.
proc initAudioPlayerSingleton*(
  initFlags: int = INIT_OGG,
  frequency: int = DEFAULT_AUDIO_FREQUENCY,
  format: int = mixer.DEFAULT_FORMAT,
  channels: int = mixer.DEFAULT_CHANNELS,
  chunksize: int = 1024
) =
  ## Initializes the AudioPlayer singleton (Audio).
  ## SDL must be initialized with `sdl.INIT_AUDIO` before this call.
  ##
  ## @see sdl_mixer.init for `flags`.
  ## @see sdl_mixer.openAudio for `frequency`, `format`, `channels`, and `chunksize`.
  if Audio != nil:
    raise newException(Exception, "AudioPlayer singleton already active!")

  let initializedFlags = int mixer.init(cint initFlags)
  if initializedFlags == 0:
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
  when defined(debug):
    if result == nil:
      echo "loadMusic failed: " & $mixer.getError()

proc loadSoundEffect*(filePath: string): SoundEffect =
  result = mixer.loadWAV(filePath)
  when defined(debug):
    if result == nil:
      echo "loadSound failed: " & $mixer.getError()

proc playMusic*(music: Music, volume: float = 1.0, numLoops: int = -1) =
  ## music {Music} The music to play.
  ## volume {float} Volume (0.0 - 1.0) to play the music.
  ## numLoops {int} The number of times to loop the music.
  ##   -1 will cause the music to loop forever.
  discard mixer.volumeMusic(cint(volume * mixer.MAX_VOLUME))
  if mixer.playMusic(music, cint numLoops) != 0:
    echo "Failed to play music: " & $mixer.getError()

proc isMusicPlaying*(): bool =
  ##  Tells you if music is actively playing, or not.
  return playingMusic() == 1

template play*(music: Music, volume: float = 1.0, numLoops: int = -1) =
  music.playMusic(volume, numLoops)

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
    echo "Failed to fade in music: " & $mixer.getError()

proc fadeOutMusic*(timeInSeconds: float = 1.0) =
  ## Fades out music over the given duration.
  discard mixer.fadeOutMusic(cint(timeInSeconds * 1000))

proc playSoundEffect*(sound: SoundEffect, volume: float = 1.0) =
  ## sound {SoundEffect} The sound effect to play.
  ## volume {float} Volume (0.0 - 1.0) to play the music.
  discard mixer.volumeChunk(sound, cint(volume * mixer.MAX_VOLUME))
  when defined(debug):
    if mixer.playChannel(-1, sound, 0) == -1:
      echo "Failed to play sound effect: " & $mixer.getError()
  else:
    discard mixer.playChannel(-1, sound, 0)

template play*(sound: SoundEffect, volume: float = 1.0) =
  sound.playSoundEffect(volume)

proc fadeOutSoundEffect*(timeInSeconds: float = 1.0) =
  ## Fades out all sound effects over the given duration.
  discard mixer.fadeOutChannel(cint -1, cint(timeInSeconds * 1000))

# TODO: freeChunk and freeMusic must be called to free.
