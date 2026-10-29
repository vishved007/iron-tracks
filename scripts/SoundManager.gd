extends Node

var sounds = {}
var sound_enabled = true

func _ready():
	sound_enabled = SaveManager.save_data.get("sound_enabled", true)
	_load_sound("whistle", "res://assets/audio/train_whistle.wav")
	_load_sound("click", "res://assets/audio/track_click.wav")
	_load_sound("chug", "res://assets/audio/train_chug.wav")
	_load_sound("win", "res://assets/audio/win_fanfare.wav")
	_load_sound("crash", "res://assets/audio/crash_derail.wav")

func _load_sound(name: String, path: String):
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		var s = AudioStreamPlayer.new()
		var res = load(path)
		if res:
			s.stream = res
			add_child(s)
			sounds[name] = s

func play_sound(name: String):
	if not sound_enabled:
		return
	if sounds.has(name) and sounds[name]:
		sounds[name].play()

func toggle_sound():
	sound_enabled = not sound_enabled
	SaveManager.save_data["sound_enabled"] = sound_enabled
	SaveManager.save_game()
	return sound_enabled
