extends Node

signal theme_changed(theme_idx)

const THEMES = [
	{
		"name": "Meadow Day",
		"bg_color": Color("76b256"),
		"grid_bg": Color("588c3e"),
		"tile_border": Color("40682c"),
		"text_color": Color("ffffff")
	},
	{
		"name": "Neon Night",
		"bg_color": Color("1e2438"),
		"grid_bg": Color("141824"),
		"tile_border": Color("3b4870"),
		"text_color": Color("00e5ff")
	},
	{
		"name": "Snowy Pine",
		"bg_color": Color("dcebf5"),
		"grid_bg": Color("b8d2e4"),
		"tile_border": Color("8faec4"),
		"text_color": Color("1b365d")
	}
]

var current_theme: int = 0

func _ready():
	current_theme = SaveManager.save_data.get("current_theme", 0)

func set_theme(idx: int):
	current_theme = idx % THEMES.size()
	SaveManager.save_data["current_theme"] = current_theme
	SaveManager.save_game()
	emit_signal("theme_changed", current_theme)

func next_theme():
	set_theme(current_theme + 1)
