class_name BgmPlayer
extends Node
## Plays background music by key. The key-to-file mapping comes from assets/data/audio/bgm.json
## through setup(), so tests can inject their own tracks. A missing or empty track stops the
## music instead of failing, so the game keeps running while music is still being produced.

var _player: AudioStreamPlayer
var _tracks: Dictionary = {}
var _current_key: String = ""


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)


## Sets the key-to-path mapping and the volume in decibels. Call before play_key().
func setup(tracks: Dictionary, volume_db: float) -> void:
	_tracks = tracks
	if _player == null:
		_player = AudioStreamPlayer.new()
		add_child(_player)
	_player.volume_db = volume_db


## Plays the track for the key. Does nothing when the key is already playing.
func play_key(key: String) -> void:
	if key == _current_key:
		return
	_current_key = key
	var path: String = str(_tracks.get(key, ""))
	if path == "" or not ResourceLoader.exists(path):
		_player.stop()
		return
	var stream := load(path) as AudioStream
	if stream == null:
		_player.stop()
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_player.stream = stream
	_player.play()


## True while a track is audible.
func is_playing() -> bool:
	return _player != null and _player.playing
