extends Node2D

# ─────────────────────────────────────────────
#  Turdflinger – top-down view
#  Shoot freely, hit toilets anywhere, no waiting!
# ─────────────────────────────────────────────

const POO_SCENE      = preload("res://scenes/Poo.tscn")
const TOILET_SCENE   = preload("res://scenes/Toilet.tscn")
const SPLAT_SCENE    = preload("res://scenes/Splat.tscn")
const POWERUP_SCENE  = preload("res://scenes/PowerUp.tscn")
const OBSTACLE_SCENE = preload("res://scenes/Obstacle.tscn")

const SAVE_PATH      := "user://turdflinger_hs.dat"
const LAUNCHER_POS   := Vector2(110, 360)
const LAUNCH_POWER   := 9.0
const MAX_DRAG_DIST  := 220.0
const DRAG_RADIUS    := 100.0

# ─────────────────────────────────────────────
#  Game state
# ─────────────────────────────────────────────
var wave           : int  = 1
var score          : int  = 0
var high_score     : int  = 0
var poos_remaining : int  = 0
var toilets_alive  : int  = 0
var combo          : int  = 0
var lives          : int  = 3

var is_dragging    : bool = false
var drag_start     : Vector2 = Vector2.ZERO
var game_active    : bool = false
var current_poo          = null   # the poo sitting in the slingshot
var trajectory_pts : Array = []

# ─────────────────────────────────────────────
#  Top-down floor themes
# ─────────────────────────────────────────────
const THEMES = [
	{
		"name":   "BATHROOM",
		"floor":  Color(0.94, 0.94, 0.96),
		"tile":   Color(0.82, 0.82, 0.88),
		"grout":  Color(0.70, 0.70, 0.78),
		"accent": Color(0.55, 0.75, 1.0),
	},
	{
		"name":   "SPACE STATION",
		"floor":  Color(0.14, 0.14, 0.20),
		"tile":   Color(0.20, 0.20, 0.28),
		"grout":  Color(0.08, 0.08, 0.14),
		"accent": Color(0.3, 0.9, 1.0),
	},
	{
		"name":   "LAVA TEMPLE",
		"floor":  Color(0.22, 0.08, 0.04),
		"tile":   Color(0.30, 0.10, 0.05),
		"grout":  Color(0.55, 0.18, 0.02),
		"accent": Color(1.0, 0.45, 0.0),
	},
	{
		"name":   "CANDY SHOP",
		"floor":  Color(1.0, 0.88, 0.92),
		"tile":   Color(0.96, 0.75, 0.82),
		"grout":  Color(0.88, 0.60, 0.72),
		"accent": Color(1.0, 0.4, 0.6),
	},
	{
		"name":   "JUNGLE RUINS",
		"floor":  Color(0.18, 0.28, 0.12),
		"tile":   Color(0.22, 0.34, 0.14),
		"grout":  Color(0.12, 0.20, 0.08),
		"accent": Color(0.5, 1.0, 0.3),
	},
	{
		"name":   "ICE PALACE",
		"floor":  Color(0.82, 0.92, 1.0),
		"tile":   Color(0.72, 0.85, 0.98),
		"grout":  Color(0.60, 0.75, 0.92),
		"accent": Color(0.3, 0.7, 1.0),
	},
	{
		"name":   "HAUNTED CRYPT",
		"floor":  Color(0.12, 0.12, 0.10),
		"tile":   Color(0.18, 0.17, 0.14),
		"grout":  Color(0.08, 0.08, 0.06),
		"accent": Color(0.5, 1.0, 0.2),
	},
	{
		"name":   "ROBOT FACTORY",
		"floor":  Color(0.28, 0.26, 0.24),
		"tile":   Color(0.34, 0.32, 0.28),
		"grout":  Color(0.20, 0.18, 0.16),
		"accent": Color(1.0, 0.75, 0.0),
	},
]

var current_theme : Dictionary = {}

# ─────────────────────────────────────────────
#  UI node references
# ─────────────────────────────────────────────
var score_label        : Label
var high_score_label   : Label
var wave_label         : Label
var poos_label         : Label
var lives_label        : Label
var world_label        : Label
var combo_label        : Label
var announce_label     : Label
var ui_layer           : CanvasLayer
var floor_node         : Node2D   # draws the tile floor


# ═══════════════════════════════════════════════════════════════
#  SETUP
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	high_score = _load_high_score()
	_build_floor_node()
	_build_screen_walls()
	_build_ui()
	_start_wave()


func _build_floor_node() -> void:
	# A Node2D that just draws the tile floor via _draw()
	floor_node = Node2D.new()
	floor_node.z_index = -10
	add_child(floor_node)
	# We'll update its draw data via a script-less approach
	# by using a lambda / connected signal – easiest: just draw in Main's _draw()


func _build_screen_walls() -> void:
	# Poo bounces off all four screen edges
	_add_wall(Vector2(640,  -10), Vector2(1280, 20))    # top
	_add_wall(Vector2(640,  730), Vector2(1280, 20))    # bottom
	_add_wall(Vector2(1300, 360), Vector2(20, 720))     # right
	_add_wall(Vector2(-20,  360), Vector2(20, 720))     # left


func _add_wall(center: Vector2, size: Vector2) -> void:
	var body             = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask  = 0
	var mat              = PhysicsMaterial.new()
	mat.bounce           = 0.65
	mat.friction         = 0.1
	body.physics_material_override = mat
	var coll             = CollisionShape2D.new()
	var shape            = RectangleShape2D.new()
	shape.size           = size
	coll.shape           = shape
	coll.position        = center
	body.add_child(coll)
	add_child(body)


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 5
	add_child(ui_layer)

	score_label      = _make_label(Vector2(16, 12),   36, Color.WHITE)
	wave_label       = _make_label(Vector2(16, 56),   28, Color(1.0, 0.9, 0.3))
	poos_label       = _make_label(Vector2(16, 92),   28, Color(0.9, 0.7, 0.2))
	lives_label      = _make_label(Vector2(16, 130),  32, Color(1.0, 0.3, 0.3))
	high_score_label = _make_label(Vector2(1020, 12), 24, Color(1.0, 0.85, 0.2))
	world_label      = _make_label(Vector2(640, 12),  26, Color(0.8, 1.0, 0.8))
	world_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	combo_label = _make_label(Vector2(640, 260), 56, Color(1.0, 0.9, 0.0))
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.modulate.a = 0.0

	announce_label = _make_label(Vector2(640, 240), 80, Color(1.0, 1.0, 0.2))
	announce_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announce_label.modulate.a = 0.0

	var hint = _make_label(Vector2(30, 680), 18, Color(1, 1, 1, 0.50))
	hint.text = "drag & release to shoot!"


func _make_label(pos: Vector2, size: int, col: Color) -> Label:
	var l = Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	ui_layer.add_child(l)
	return l


# ═══════════════════════════════════════════════════════════════
#  WAVE MANAGEMENT
# ═══════════════════════════════════════════════════════════════

func _start_wave() -> void:
	game_active    = true
	combo          = 0
	toilets_alive  = 0
	lives          = 3
	is_dragging    = false
	trajectory_pts = []

	poos_remaining = max(3, 7 - int(wave * 0.3))

	current_theme = THEMES[randi() % THEMES.size()]

	# Clear old deco
	for child in get_children():
		if child.is_in_group("deco"):
			child.queue_free()

	# Toilet count = wave number
	var toilet_count : int = min(wave, 15)
	for _i in toilet_count:
		_spawn_toilet()
	toilets_alive = toilet_count

	# Power-ups from wave 2+
	if wave >= 2:
		for _i in min(1 + int((wave - 2) * 0.4), 3):
			_spawn_powerup()

	# Obstacles from wave 3+
	if wave >= 3:
		_spawn_obstacles()

	_spawn_poo()
	_update_ui()
	_flash_announce("WAVE  " + str(wave) + "!\n" + current_theme["name"], Color(1.0, 1.0, 0.2))
	queue_redraw()


# ═══════════════════════════════════════════════════════════════
#  SPAWNING
# ═══════════════════════════════════════════════════════════════

func _spawn_toilet() -> void:
	var toilet      = TOILET_SCENE.instantiate()
	toilet.position = Vector2(randf_range(380, 1080), randf_range(80, 640))
	toilet.wave_num = wave
	toilet.add_to_group("toilets")
	add_child(toilet)
	toilet.connect("poo_scored",  _on_poo_scored.bind(toilet))
	toilet.connect("hit_player",  _on_toilet_hit_player.bind(toilet))


func _spawn_poo() -> void:
	if poos_remaining <= 0:
		return
	current_poo          = POO_SCENE.instantiate()
	current_poo.position = LAUNCHER_POS
	current_poo.freeze   = true
	add_child(current_poo)


func _spawn_powerup() -> void:
	var pu      = POWERUP_SCENE.instantiate()
	pu.type     = randi() % 3
	pu.position = Vector2(randf_range(310, 820), randf_range(100, 600))
	add_child(pu)


func _spawn_obstacles() -> void:
	var count = min(1 + int((wave - 3) * 0.5), 5)
	for _i in count:
		var obs         = OBSTACLE_SCENE.instantiate()
		if wave >= 8 and randf() < 0.35:
			obs.type = 2
		elif wave >= 5 and randf() < 0.45:
			obs.type = 1
		else:
			obs.type = 0
			obs.wall_height = randf_range(60, 130)
		obs.spin_speed  = randf_range(55, 120) * (1.0 if randf() > 0.5 else -1.0)
		obs.position    = Vector2(randf_range(350, 1000), randf_range(100, 620))
		add_child(obs)


# ═══════════════════════════════════════════════════════════════
#  INPUT – shoot any time, no waiting!
# ═══════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not game_active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.position.distance_to(LAUNCHER_POS) <= DRAG_RADIUS:
				is_dragging = true
				drag_start  = event.position
		else:
			if is_dragging:
				_launch_poo(event.position)
			is_dragging    = false
			trajectory_pts = []
			queue_redraw()

	if event is InputEventMouseMotion and is_dragging:
		_calc_trajectory(event.position)
		queue_redraw()


func _launch_poo(release_pos: Vector2) -> void:
	is_dragging    = false
	trajectory_pts = []

	if current_poo == null or not is_instance_valid(current_poo):
		return
	if poos_remaining <= 0:
		return

	var drag_vec = (drag_start - release_pos).limit_length(MAX_DRAG_DIST)
	if drag_vec.length() < 10:
		return

	var impulse  = drag_vec * LAUNCH_POWER
	current_poo.freeze = false
	current_poo.apply_central_impulse(impulse)
	current_poo.apply_torque_impulse(randf_range(-30, 30))

	poos_remaining -= 1
	current_poo    = null

	# Immediately ready the next poo if we have ammo
	if poos_remaining > 0:
		_spawn_poo()

	_update_ui()
	queue_redraw()


# ═══════════════════════════════════════════════════════════════
#  WAVE EVALUATION
# ═══════════════════════════════════════════════════════════════

func _evaluate_wave() -> void:
	if toilets_alive <= 0:
		await get_tree().create_timer(1.2).timeout
		_complete_wave()
	elif poos_remaining <= 0:
		_fail_wave()


func _complete_wave() -> void:
	var poo_bonus = poos_remaining * 75 * wave
	score        += poo_bonus
	_flash_announce("WAVE CLEAR!\n+" + str(poo_bonus) + " BONUS!", Color(0.3, 1.0, 0.3))
	if current_poo and is_instance_valid(current_poo):
		current_poo.queue_free()
		current_poo = null
	wave += 1
	_update_ui()
	await get_tree().create_timer(2.5).timeout
	_clear_all()
	_start_wave()


func _fail_wave() -> void:
	combo = 0
	_flash_announce("OUT OF AMMO!\nWave retry...", Color(1.0, 0.35, 0.2))
	if current_poo and is_instance_valid(current_poo):
		current_poo.queue_free()
		current_poo = null
	await get_tree().create_timer(2.0).timeout
	_clear_all()
	_start_wave()


func _restart_wave() -> void:
	lives = 3
	combo = 0
	_flash_announce("RESTARTING\nWAVE " + str(wave) + "!", Color(1.0, 0.35, 0.2))
	if current_poo and is_instance_valid(current_poo):
		current_poo.queue_free()
		current_poo = null
	await get_tree().create_timer(1.8).timeout
	_clear_all()
	_start_wave()


func _clear_all() -> void:
	for t in get_tree().get_nodes_in_group("toilets"):
		t.queue_free()
	for o in get_tree().get_nodes_in_group("obstacles"):
		o.queue_free()
	for p in get_tree().get_nodes_in_group("powerups"):
		p.queue_free()
	# Also free any stray flying poos
	for p2 in get_tree().get_nodes_in_group("poo"):
		p2.queue_free()
	toilets_alive = 0
	current_poo   = null


# ═══════════════════════════════════════════════════════════════
#  SCORING
# ═══════════════════════════════════════════════════════════════

func _on_poo_scored(toilet: Node) -> void:
	combo         += 1
	var pts : int  = 100 * wave
	if combo > 1:
		pts = int(pts * (1.0 + combo * 0.6))
		_show_combo(combo, pts)

	score         += pts
	toilets_alive -= 1

	var splat               = SPLAT_SCENE.instantiate()
	splat.global_position   = toilet.global_position
	add_child(splat)

	toilet.die()

	if score > high_score:
		high_score = score
		_save_high_score()

	_update_ui()
	_evaluate_wave()


func _on_toilet_hit_player(toilet: Node) -> void:
	toilets_alive -= 1
	lives         -= 1
	_update_ui()

	if lives <= 0:
		await get_tree().create_timer(1.0).timeout
		_restart_wave()
	else:
		_evaluate_wave()


# ═══════════════════════════════════════════════════════════════
#  UI
# ═══════════════════════════════════════════════════════════════

func _update_ui() -> void:
	score_label.text      = "SCORE: " + str(score)
	high_score_label.text = "BEST: "  + str(high_score)
	wave_label.text       = "WAVE:  " + str(wave)

	var poo_str = ""
	for _i in poos_remaining:
		poo_str += "[#] "
	poos_label.text = "AMMO: " + poo_str.strip_edges()

	var hearts = ""
	for _i in lives:
		hearts += "<3 "
	for _i in (3 - lives):
		hearts += "-- "
	lives_label.text = hearts.strip_edges()

	world_label.text = "[ " + current_theme.get("name", "???") + " ]"


func _flash_announce(msg: String, col: Color) -> void:
	announce_label.text      = msg
	announce_label.modulate  = col
	announce_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(announce_label, "modulate:a", 0.0, 0.9)


func _show_combo(c: int, pts: int) -> void:
	combo_label.text       = "COMBO x" + str(c) + "!\n+" + str(pts)
	combo_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(combo_label, "modulate:a", 0.0, 0.7)


# ═══════════════════════════════════════════════════════════════
#  TRAJECTORY – straight line (top-down, no gravity)
# ═══════════════════════════════════════════════════════════════

func _calc_trajectory(mouse_pos: Vector2) -> void:
	var drag = (drag_start - mouse_pos).limit_length(MAX_DRAG_DIST)
	var dir  = drag.normalized()
	var spd  = drag.length() * LAUNCH_POWER * 0.05  # visual preview length

	trajectory_pts = []
	for i in 30:
		trajectory_pts.append(LAUNCHER_POS + dir * (i * spd))


# ═══════════════════════════════════════════════════════════════
#  DRAWING – tile floor + slingshot
# ═══════════════════════════════════════════════════════════════

func _process(_delta: float) -> void:
	# Web: mouseup events can be swallowed by the browser during a drag.
	# Poll the button state each frame so we never get stuck in is_dragging.
	if is_dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_launch_poo(get_viewport().get_mouse_position())
	queue_redraw()


func _draw() -> void:
	_draw_floor()
	_draw_launcher()

	if is_dragging and trajectory_pts.size() > 0:
		draw_line(LAUNCHER_POS, drag_start, Color(1, 1, 1, 0.35), 2)
		for i in trajectory_pts.size():
			var alpha = 1.0 - float(i) / trajectory_pts.size()
			draw_circle(trajectory_pts[i], lerp(5.0, 2.0, float(i) / trajectory_pts.size()),
				Color(0.9, 0.65, 0.15, alpha * 0.8))


func _draw_floor() -> void:
	if current_theme.is_empty():
		return
	var floor_col  : Color = current_theme["floor"]
	var tile_col   : Color = current_theme["tile"]
	var grout_col  : Color = current_theme["grout"]

	# Base floor colour
	draw_rect(Rect2(0, 0, 1280, 720), floor_col)

	# Tile grid
	var ts = 80   # tile size
	for row in range(0, 720, ts):
		for col in range(0, 1280, ts):
			var is_alt = ((row / ts) + (col / ts)) % 2 == 1
			if is_alt:
				draw_rect(Rect2(col, row, ts, ts), tile_col)
			# Grout lines
			draw_line(Vector2(col, row), Vector2(col + ts, row), grout_col, 1.0)
			draw_line(Vector2(col, row), Vector2(col, row + ts), grout_col, 1.0)


func _draw_launcher() -> void:
	var lp = LAUNCHER_POS

	# Base post shadow
	draw_rect(Rect2(lp.x - 6, lp.y - 55, 12, 75), Color(0, 0, 0, 0.2))

	# Base post
	draw_rect(Rect2(lp.x - 6, lp.y - 55, 12, 75), Color(0.45, 0.30, 0.14))

	# Left fork arm
	draw_line(lp, lp + Vector2(-40, -52), Color(0.50, 0.32, 0.14), 10)
	draw_circle(lp + Vector2(-40, -52), 7, Color(0.30, 0.18, 0.08))

	# Right fork arm
	draw_line(lp, lp + Vector2(40, -52), Color(0.50, 0.32, 0.14), 10)
	draw_circle(lp + Vector2(40, -52), 7, Color(0.30, 0.18, 0.08))

	# Elastic bands
	if is_dragging:
		draw_line(lp + Vector2(-40, -52), drag_start, Color(0.85, 0.72, 0.22, 0.95), 3)
		draw_line(lp + Vector2(40,  -52), drag_start, Color(0.85, 0.72, 0.22, 0.95), 3)
	else:
		var mid = lp + Vector2(0, -46)
		draw_line(lp + Vector2(-40, -52), mid, Color(0.75, 0.62, 0.18, 0.65), 2)
		draw_line(lp + Vector2(40,  -52), mid, Color(0.75, 0.62, 0.18, 0.65), 2)


# ═══════════════════════════════════════════════════════════════
#  HIGH SCORE SAVE / LOAD
# ═══════════════════════════════════════════════════════════════

func _save_high_score() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_32(high_score)
		f.close()


func _load_high_score() -> int:
	if not FileAccess.file_exists(SAVE_PATH):
		return 0
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var hs = f.get_32()
		f.close()
		return hs
	return 0
