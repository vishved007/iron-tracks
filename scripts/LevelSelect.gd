extends Control

var current_page: int = 0
const LEVELS_PER_PAGE: int = 20
const TOTAL_LEVELS: int = 200

@onready var grid = $Scroll/Grid
@onready var page_label = $Footer/PageLabel
@onready var btn_back = $Header/BtnBack
@onready var btn_prev = $Footer/BtnPrevPage
@onready var btn_next = $Footer/BtnNextPage

func _ready():
	btn_back.pressed.connect(_on_back)
	btn_prev.pressed.connect(_on_prev_page)
	btn_next.pressed.connect(_on_next_page)
	_render_page()

func _render_page():
	for c in grid.get_children():
		c.queue_free()
	
	var total_pages = int(ceil(float(TOTAL_LEVELS) / float(LEVELS_PER_PAGE)))
	page_label.text = "Page %d / %d" % [current_page + 1, total_pages]
	
	var start_lvl = current_page * LEVELS_PER_PAGE + 1
	var end_lvl = mini(start_lvl + LEVELS_PER_PAGE - 1, TOTAL_LEVELS)
	
	for lvl in range(start_lvl, end_lvl + 1):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(140, 140)
		var is_unl = SaveManager.is_level_unlocked(lvl)
		var stars = SaveManager.get_level_stars(lvl)
		
		if is_unl:
			var star_str = ""
			for s in range(stars): star_str += "★"
			for s in range(3 - stars): star_str += "☆"
			btn.text = "Level %d\n%s" % [lvl, star_str]
			btn.pressed.connect(Callable(self, "_on_level_selected").bind(lvl))
		else:
			btn.text = "Level %d\n🔒" % lvl
			btn.disabled = true
		grid.add_child(btn)

func _on_prev_page():
	if current_page > 0:
		current_page -= 1
		_render_page()

func _on_next_page():
	var total_pages = int(ceil(float(TOTAL_LEVELS) / float(LEVELS_PER_PAGE)))
	if current_page < total_pages - 1:
		current_page += 1
		_render_page()

func _on_back():
	get_parent().get_parent().show_main_menu()

func _on_level_selected(lvl: int):
	get_parent().get_parent().show_game(lvl)
