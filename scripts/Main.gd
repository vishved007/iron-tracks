extends Control

@onready var bg = $Background
@onready var view_container = $ViewContainer

func _ready():
	ThemeManager.connect("theme_changed", Callable(self, "_on_theme_changed"))
	_on_theme_changed(ThemeManager.current_theme)
	show_main_menu()

func _on_theme_changed(idx: int):
	var th = ThemeManager.THEMES[idx]
	bg.color = th["bg_color"]

func clear_views():
	for c in view_container.get_children():
		c.queue_free()

func show_main_menu():
	clear_views()
	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	view_container.add_child(menu)

func show_level_select():
	clear_views()
	var ls = load("res://scenes/LevelSelect.tscn").instantiate()
	view_container.add_child(ls)

func show_game(level_id: int):
	clear_views()
	var game = load("res://scenes/Game.tscn").instantiate()
	view_container.add_child(game)
	GameManager.start_level(level_id)
