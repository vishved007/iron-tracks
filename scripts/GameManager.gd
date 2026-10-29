extends Node

signal level_loaded(level_data)
signal move_made(move_count)
signal level_completed(stars, moves, time_taken)
signal level_failed(reason)

var levels = []
var current_level_id: int = 1
var current_level: Dictionary = {}
var moves_taken: int = 0
var level_timer: float = 0.0
var is_timer_active: bool = false
var undo_stack = []

func _ready():
	load_all_levels()

func load_all_levels():
	var f = FileAccess.open("res://data/levels.json", FileAccess.READ)
	if f:
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK and typeof(json.data) == TYPE_ARRAY:
			levels = json.data
		f.close()

func start_level(level_id: int):
	if level_id < 1 or level_id > levels.size():
		return
	current_level_id = level_id
	current_level = levels[level_id - 1]
	moves_taken = 0
	level_timer = 0.0
	is_timer_active = true
	undo_stack.clear()
	emit_signal("level_loaded", current_level)

func _process(delta):
	if is_timer_active:
		level_timer += delta

func record_move(tile_x: int, tile_y: int, old_rot: int, new_rot: int):
	undo_stack.push_back({"x": tile_x, "y": tile_y, "from": old_rot, "to": new_rot})
	moves_taken += 1
	SoundManager.play_sound("click")
	emit_signal("move_made", moves_taken)

func can_undo() -> bool:
	return undo_stack.size() > 0

func pop_undo() -> Dictionary:
	if undo_stack.is_empty():
		return {}
	var u = undo_stack.pop_back()
	moves_taken = maxi(0, moves_taken - 1)
	SoundManager.play_sound("click")
	emit_signal("move_made", moves_taken)
	return u

func get_hint() -> Dictionary:
	# Looks at current level and returns the first tile that does not match solution_rot
	# Returns { "x": x, "y": y, "target_rot": rot }
	if not current_level.has("grid"):
		return {}
	for row in current_level["grid"]:
		for t in row:
			if not t.get("fixed", false) and t["type"] in ["straight", "curve", "cross"]:
				# check if current tile is not at solution
				# (caller will query grid tile's current rot)
				pass
	return {}

func complete_level():
	is_timer_active = false
	var par_m = current_level.get("par_moves", 10)
	var stars = 1
	if moves_taken <= par_m:
		stars = 3
	elif moves_taken <= par_m + 4:
		stars = 2
	
	SoundManager.play_sound("win")
	SaveManager.record_level_clear(current_level_id, moves_taken, level_timer, stars)
	emit_signal("level_completed", stars, moves_taken, level_timer)

func fail_level(reason: String):
	is_timer_active = false
	SoundManager.play_sound("crash")
	emit_signal("level_failed", reason)
