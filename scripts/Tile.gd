extends Area2D

signal tile_clicked(x, y)

@export var grid_x: int = 0
@export var grid_y: int = 0
@export var tile_type: String = "empty"
@export var current_rot: int = 0
@export var is_fixed: bool = false

@onready var sprite = $Sprite2D
@onready var bg_sprite = $BgSprite

static var texture_cache = {}

func setup(x: int, y: int, t_type: String, rot: int, fixed: bool, _theme_idx: int):
	grid_x = x
	grid_y = y
	tile_type = t_type
	current_rot = rot
	is_fixed = fixed
	_update_appearance()

func rotate_tile(clockwise: bool = true):
	if is_fixed or tile_type in ["empty", "obstacle"]:
		return
	var old = current_rot
	current_rot = (current_rot + 1) % 4 if clockwise else (current_rot + 3) % 4
	var tween = create_tween()
	var target_ang = current_rot * (PI / 2.0)
	tween.tween_property(sprite, "rotation", target_ang, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return {"old": old, "new": current_rot}

func set_rotation_immediate(r: int):
	current_rot = r % 4
	if sprite:
		sprite.rotation = current_rot * (PI / 2.0)

func _update_appearance():
	if not sprite:
		return
	sprite.rotation = current_rot * (PI / 2.0)
	
	if tile_type == "empty":
		sprite.texture = null
		return
		
	var path_map = {
		"straight": "res://assets/sprites/track_straight.png",
		"curve": "res://assets/sprites/track_curve.png",
		"cross": "res://assets/sprites/track_cross.png",
		"obstacle": "res://assets/sprites/track_obstacle.png"
	}
	
	if path_map.has(tile_type):
		var p = path_map[tile_type]
		if ResourceLoader.exists(p):
			sprite.texture = load(p)
			return
			
	# Procedural fallback texture generation if file is missing
	sprite.texture = _get_or_create_procedural_texture(tile_type)

func _get_or_create_procedural_texture(type_name: String) -> Texture2D:
	if texture_cache.has(type_name):
		return texture_cache[type_name]
		
	var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var rail_color = Color("464b55")
	var tie_color = Color("78502d")
	
	if type_name == "straight":
		# Ties
		for ox in [20, 50, 78, 108]:
			for ty in range(32, 96):
				for tx in range(ox - 6, ox + 6):
					img.set_pixel(tx, ty, tie_color)
		# Rails
		for tx in range(0, 128):
			for ty in range(40, 48): img.set_pixel(tx, ty, rail_color)
			for ty in range(80, 88): img.set_pixel(tx, ty, rail_color)
	elif type_name == "cross":
		for ox in [20, 108]:
			for ty in range(32, 96):
				for tx in range(ox - 6, ox + 6): img.set_pixel(tx, ty, tie_color)
				for tx in range(32, 96): img.set_pixel(ty, tx, tie_color)
		for t in range(0, 128):
			for w in range(40, 48):
				img.set_pixel(t, w, rail_color)
				img.set_pixel(t, w + 40, rail_color)
				img.set_pixel(w, t, rail_color)
				img.set_pixel(w + 40, t, rail_color)
	elif type_name == "obstacle":
		for x in range(30, 98):
			for y in range(30, 98):
				var dx = x - 64
				var dy = y - 64
				if dx*dx + dy*dy < 1200:
					img.set_pixel(x, y, Color("5f646e"))
	else:
		# Generic curve / track
		for x in range(0, 128):
			for y in range(0, 128):
				var d = Vector2(x - 128, y).length()
				if abs(d - 64) < 20:
					img.set_pixel(x, y, tie_color)
				if abs(d - 44) < 4 or abs(d - 84) < 4:
					img.set_pixel(x, y, rail_color)
					
	var tex = ImageTexture.create_from_image(img)
	texture_cache[type_name] = tex
	return tex

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("tile_clicked", grid_x, grid_y)
