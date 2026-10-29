extends Node

const SAVE_PATH = "user://iron_tracks_save.json"

var save_data = {
	"unlocked_level": 1,
	"sound_enabled": true,
	"music_enabled": true,
	"current_theme": 0, # 0: Day, 1: Night, 2: Snow
	"levels": {} # level_id: {"stars": 3, "best_moves": 4, "best_time": 12.5}
}

func _ready():
	load_game()

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
			for k in json.data:
				save_data[k] = json.data[k]

func is_level_unlocked(level_id: int) -> bool:
	return level_id <= int(save_data.get("unlocked_level", 1))

func unlock_level(level_id: int):
	if level_id > int(save_data.get("unlocked_level", 1)):
		save_data["unlocked_level"] = level_id
		save_game()

func record_level_clear(level_id: int, moves: int, time_taken: float, stars: int):
	var str_id = str(level_id)
	var prev = save_data["levels"].get(str_id, {})
	var prev_stars = prev.get("stars", 0)
	var best_moves = prev.get("best_moves", 9999)
	var best_time = prev.get("best_time", 9999.0)

	save_data["levels"][str_id] = {
		"stars": maxi(stars, prev_stars),
		"best_moves": mini(moves, best_moves),
		"best_time": minf(time_taken, best_time)
	}
	unlock_level(level_id + 1)
	save_game()

func get_level_stars(level_id: int) -> int:
	var str_id = str(level_id)
	if save_data["levels"].has(str_id):
		return save_data["levels"][str_id].get("stars", 0)
	return 0
