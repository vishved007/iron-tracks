extends VBoxContainer

@onready var btn_play = $BtnPlay
@onready var btn_levels = $BtnLevels
@onready var btn_how = $BtnHowToPlay
@onready var btn_settings = $BtnSettings

func _ready():
	btn_play.pressed.connect(_on_play_pressed)
	btn_levels.pressed.connect(_on_levels_pressed)
	btn_how.pressed.connect(_on_how_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)

func _on_play_pressed():
	var unl = SaveManager.save_data.get("unlocked_level", 1)
	get_parent().get_parent().show_game(unl)

func _on_levels_pressed():
	get_parent().get_parent().show_level_select()

func _on_how_pressed():
	OS.alert("HOW TO PLAY:\n\n1. Tap track tiles on the grid to rotate them.\n2. Connect the green start station to the red destination.\n3. Tap 'Run Train' to travel the tracks.\n4. Reach the station without derailment to win!", "Rules")

func _on_settings_pressed():
	ThemeManager.next_theme()
