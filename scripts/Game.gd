extends Control

@onready var level_title = $HUD/TopRow/LevelTitle
@onready var moves_label = $HUD/StatsRow/MovesLabel
@onready var timer_label = $HUD/StatsRow/TimerLabel
@onready var tiles_root = $BoardContainer/TilesRoot
@onready var trains_root = $BoardContainer/TrainsRoot

@onready var btn_menu = $HUD/TopRow/BtnMenu
@onready var btn_sound = $HUD/TopRow/BtnSound
@onready var btn_undo = $BottomHUD/BtnUndo
@onready var btn_restart = $BottomHUD/BtnRestart
@onready var btn_hint = $BottomHUD/BtnHint
@onready var btn_run = $BottomHUD/BtnRun

var tile_nodes = {}
var level_data = {}
var is_train_running = false

func _ready():
	btn_menu.pressed.connect(_on_menu)
	btn_sound.pressed.connect(_on_sound)
	btn_undo.pressed.connect(_on_undo)
	btn_restart.pressed.connect(_on_restart)
	btn_hint.pressed.connect(_on_hint)
	btn_run.pressed.connect(_on_run_train)
	
	GameManager.level_loaded.connect(_on_level_loaded)
	GameManager.move_made.connect(_on_move_made)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.level_failed.connect(_on_level_failed)

func _process(_delta):
	var sec = int(GameManager.level_timer)
	timer_label.text = "Time: %02d:%02d" % [sec / 60, sec % 60]

func _on_level_loaded(ld: Dictionary):
	level_data = ld
	level_title.text = "Level %d: %s" % [ld["id"], ld["name"]]
	moves_label.text = "Moves: 0 (Par: %d)" % ld["par_moves"]
	_build_board()

func _build_board():
	for c in tiles_root.get_children(): c.queue_free()
	for c in trains_root.get_children(): c.queue_free()
	tile_nodes.clear()
	is_train_running = false
	btn_run.disabled = false
	
	var w = level_data["width"]
	var h = level_data["height"]
	var tile_size = mini(600 / w, 600 / h)
	var offset_x = (660 - (w * tile_size)) / 2.0
	var offset_y = (660 - (h * tile_size)) / 2.0
	
	var tile_scene = load("res://scenes/Tile.tscn")
	for row in level_data["grid"]:
		for t in row:
			var node = tile_scene.instantiate()
			node.position = Vector2(offset_x + t["x"] * tile_size + tile_size/2.0, offset_y + t["y"] * tile_size + tile_size/2.0)
			node.scale = Vector2(tile_size / 128.0, tile_size / 128.0)
			tiles_root.add_child(node)
			node.setup(t["x"], t["y"], t["type"], t["initial_rot"], t["fixed"], level_data["theme"])
			node.tile_clicked.connect(_on_tile_clicked)
			tile_nodes[Vector2i(t["x"], t["y"])] = node

func _on_tile_clicked(x: int, y: int):
	if is_train_running:
		return
	var key = Vector2i(x, y)
	if tile_nodes.has(key):
		var node = tile_nodes[key]
		var res = node.rotate_tile()
		if res:
			GameManager.record_move(x, y, res["old"], res["new"])

func _on_move_made(count: int):
	moves_label.text = "Moves: %d (Par: %d)" % [count, level_data.get("par_moves", 4)]

func _on_undo():
	if is_train_running:
		return
	var u = GameManager.pop_undo()
	if u.has("x"):
		var key = Vector2i(u["x"], u["y"])
		if tile_nodes.has(key):
			tile_nodes[key].set_rotation_immediate(u["from"])

func _on_restart():
	if is_train_running:
		return
	GameManager.start_level(GameManager.current_level_id)

func _on_hint():
	# Finds first rotatable tile that is not at solution_rot and rotates it towards solution
	for row in level_data["grid"]:
		for t in row:
			if not t.get("fixed", false) and t["type"] in ["straight", "curve"]:
				var key = Vector2i(t["x"], t["y"])
				var cur = tile_nodes[key].current_rot
				var sol = t["solution_rot"]
				if t["type"] == "straight":
					if cur % 2 != sol % 2:
						_on_tile_clicked(t["x"], t["y"])
						return
				elif cur != sol:
					_on_tile_clicked(t["x"], t["y"])
					return

func _on_run_train():
	if is_train_running:
		return
	is_train_running = true
	btn_run.disabled = true
	
	# Simulate and collect path points
	var w = level_data["width"]
	var h = level_data["height"]
	var cur_x = level_data["start"]["x"]
	var cur_y = level_data["start"]["y"]
	var cur_dir = level_data["start"]["dir"]
	var target_x = level_data["target"]["x"]
	var target_y = level_data["target"]["y"]
	
	var pts = []
	var success = false
	var steps = 0
	
	while steps < w * h * 4:
		steps += 1
		var key = Vector2i(cur_x, cur_y)
		if not tile_nodes.has(key):
			break
		var t_node = tile_nodes[key]
		pts.append(t_node.global_position)
		
		if cur_x == target_x and cur_y == target_y:
			success = true
			break
		
		# calculate exit
		var conns = _get_conns(t_node.tile_type, t_node.current_rot)
		var opp = [2, 3, 0, 1]
		var entry_side = opp[cur_dir]
		if not conns.has(entry_side):
			break
		var exit_side = conns[entry_side]
		var dirs = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
		var nxt = Vector2i(cur_x, cur_y) + dirs[exit_side]
		cur_x = nxt.x
		cur_y = nxt.y
		cur_dir = exit_side
	
	# Spawn train
	var train_scene = load("res://scenes/Train.tscn")
	var train = train_scene.instantiate()
	trains_root.add_child(train)
	train.start_run(pts, Vector2.ZERO)
	
	if success:
		train.reached_target.connect(func(): GameManager.complete_level())
	else:
		train.reached_target.connect(func(): GameManager.fail_level("Broken connection or dead end!"))

func _get_conns(tt: String, rot: int) -> Dictionary:
	if tt == "straight":
		return {1: 3, 3: 1} if (rot % 2 == 0) else {0: 2, 2: 0}
	elif tt == "curve":
		var pairs = [[0, 1], [1, 2], [2, 3], [3, 0]]
		var p = pairs[rot % 4]
		return {p[0]: p[1], p[1]: p[0]}
	elif tt == "cross":
		return {0: 2, 2: 0, 1: 3, 3: 1}
	return {}

func _on_level_completed(stars: int, moves: int, _time_taken: float):
	var star_str = ""
	for s in range(stars): star_str += "★"
	for s in range(3 - stars): star_str += "☆"
	OS.alert("LEVEL COMPLETE!\n\nRating: %s\nMoves: %d\n\nAdvancing to next level..." % [star_str, moves], "Victory!")
	var next_lvl = GameManager.current_level_id + 1
	if next_lvl <= 200:
		GameManager.start_level(next_lvl)
	else:
		_on_menu()

func _on_level_failed(reason: String):
	OS.alert("DERAILMENT!\n\n%s\n\nTry rearranging the tracks." % reason, "Oops!")
	_build_board()

func _on_sound():
	var on = SoundManager.toggle_sound()
	btn_sound.text = "🔊" if on else "🔇"

func _on_menu():
	get_parent().get_parent().show_main_menu()
