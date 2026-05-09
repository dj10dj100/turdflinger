extends Node2D

# ─────────────────────────────────────────────
#  Toilet – top-down overhead view 🚽
#  Hit ANYWHERE on it to score. Poo dies on contact.
# ─────────────────────────────────────────────

signal poo_scored
signal hit_player

const PLAYER_POS := Vector2(120, 360)
const HIT_X      := 180.0

var wave_num   : int   = 1
var is_moving  : bool  = false
var move_speed : float = 0.0
var move_dir   : Vector2 = Vector2.ZERO
var scored     : bool  = false
var player_hit : bool  = false
var wobble     : float = 0.0


func _ready() -> void:
	add_to_group("toilets")

	if wave_num >= 4:
		is_moving  = true
		move_speed = 55.0 + (wave_num - 4) * 22.0
		var aim    = PLAYER_POS + Vector2(0, randf_range(-180, 180))
		move_dir   = (aim - position).normalized()

	_build_score_area()


func _build_score_area() -> void:
	# Single Area2D covers the whole toilet – hit anywhere!
	var area             = Area2D.new()
	area.collision_layer = 8
	area.collision_mask  = 2   # detects poo (layer 2)

	# Circle shape covering the whole toilet footprint
	var coll      = CollisionShape2D.new()
	var shape     = CircleShape2D.new()
	shape.radius  = 38.0
	coll.shape    = shape
	area.add_child(coll)
	area.connect("body_entered", _on_body_entered)
	add_child(area)


func _on_body_entered(body: Node) -> void:
	if scored:
		return
	if body.is_in_group("poo"):
		scored = true
		wobble = 0.6
		body.queue_free()   # poo dies going into the toilet!
		_show_splash()
		emit_signal("poo_scored")


func _show_splash() -> void:
	var msgs = ["FLUSH! 💦", "BULLSEYE! 🎯", "DIRECT HIT! 💥", "PERFECT! ⭐", "DOWN IT GOES! 🌀"]
	var canvas   = CanvasLayer.new()
	canvas.layer = 8
	add_child(canvas)

	var lbl = Label.new()
	lbl.text = msgs[randi() % msgs.size()]
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.9))
	lbl.position = global_position + Vector2(-55, -60)
	canvas.add_child(lbl)

	var tw = create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 55, 0.55)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.55)
	tw.tween_callback(canvas.queue_free)


func _show_hit_flash() -> void:
	var canvas     = CanvasLayer.new()
	canvas.layer   = 10
	get_tree().root.add_child(canvas)

	var flash      = ColorRect.new()
	flash.size     = Vector2(1280, 720)
	flash.color    = Color(1.0, 0.0, 0.0, 0.0)
	canvas.add_child(flash)

	var lbl = Label.new()
	lbl.text = "OUCH!"
	lbl.add_theme_font_size_override("font_size", 90)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(340, 260)
	canvas.add_child(lbl)

	var tw2 = create_tween()
	tw2.tween_property(flash, "color:a", 0.50, 0.08)
	tw2.tween_property(flash, "color:a", 0.0,  0.55)
	tw2.parallel().tween_property(lbl, "modulate:a", 0.0, 0.65)
	tw2.tween_callback(canvas.queue_free)


func die() -> void:
	is_moving = false
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "rotation", rotation + TAU * 1.5, 0.45)
	tw.tween_property(self, "scale", Vector2(1.4, 0.0), 0.45).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	if wobble > 0:
		wobble -= delta

	if is_moving and not scored and not player_hit:
		position += move_dir * move_speed * delta

		if position.x <= HIT_X:
			player_hit = true
			emit_signal("hit_player")
			_show_hit_flash()
			queue_free()
			return

		# Bounce off all four screen edges
		if position.x > 1100:
			move_dir.x *= -1.0
		if position.y < 80 or position.y > 630:
			move_dir.y *= -1.0

	queue_redraw()


func _draw() -> void:
	var w = 0.0
	if wobble > 0:
		w = sin(wobble * 35.0) * 3.0

	# ── TOP-DOWN TOILET VIEW ──

	# Drop shadow underneath
	draw_circle(Vector2(4, 4), 36, Color(0, 0, 0, 0.18))

	# Tank (cistern) – rectangle at the top
	draw_rect(Rect2(-24 + w, -62, 48, 30), Color(0.88, 0.88, 0.93))
	draw_rect(Rect2(-24 + w, -62, 48, 30), Color(0.68, 0.68, 0.78), false, 2.0)
	# Tank lid highlight
	draw_rect(Rect2(-22 + w, -60, 44, 4),  Color(1.0, 1.0, 1.0, 0.45))

	# Toilet bowl body (outer oval approximated with circle)
	draw_circle(Vector2(0, 8), 34, Color(0.90, 0.90, 0.94))

	# Seat ring
	draw_arc(Vector2(0, 8), 32, 0.0, TAU, 48, Color(0.78, 0.78, 0.86), 8.0)

	# Water in bowl (blue circle inside)
	draw_circle(Vector2(0, 10), 20, Color(0.48, 0.76, 1.0, 0.80))

	# Water shimmer
	draw_arc(Vector2(-5, 5), 8, deg_to_rad(200), deg_to_rad(320), 10, Color(1,1,1,0.35), 2.0)

	# Seat gap at top (where tank meets bowl)
	draw_rect(Rect2(-20, -28, 40, 10), Color(0.90, 0.90, 0.94))

	# Bolt dots on tank
	draw_circle(Vector2(-18 + w, -50), 3, Color(0.65, 0.65, 0.75))
	draw_circle(Vector2( 18 + w, -50), 3, Color(0.65, 0.65, 0.75))

	# Moving indicator arrows
	if is_moving and not scored:
		var col = Color(1.0, 0.3, 0.2, 0.7)
		draw_line(Vector2(-50,  0), Vector2(-62,  0), col, 3)
		draw_line(Vector2(-62,  0), Vector2(-56, -6), col, 3)
		draw_line(Vector2(-62,  0), Vector2(-56,  6), col, 3)
