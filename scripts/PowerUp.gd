extends Node2D

# ─────────────────────────────────────────────
#  PowerUp – fly the poo through it to transform! 🌟
#  Types: MEGA (grow huge), BOUNCY (super bounce), SPEEDY (zoom!)
# ─────────────────────────────────────────────

enum Type { MEGA, BOUNCY, SPEEDY }

var type      : Type  = Type.MEGA
var bob_time  : float = 0.0
var collected : bool  = false

const TYPE_COLOR := {
	Type.MEGA:   Color(1.0, 0.35, 0.1),
	Type.BOUNCY: Color(0.25, 0.75, 1.0),
	Type.SPEEDY: Color(0.9,  1.0,  0.15),
}

const TYPE_LABEL := {
	Type.MEGA:   "MEGA!",
	Type.BOUNCY: "BOUNCE!",
	Type.SPEEDY: "ZOOM!",
}


func _ready() -> void:
	add_to_group("powerups")
	_build_detection_area()


func _build_detection_area() -> void:
	var area             = Area2D.new()
	area.collision_layer = 32
	area.collision_mask  = 2    # detect poo (layer 2)
	var coll             = CollisionShape2D.new()
	var shape            = CircleShape2D.new()
	shape.radius         = 28.0
	coll.shape           = shape
	area.add_child(coll)
	area.connect("body_entered", _on_poo_entered)
	add_child(area)


func _on_poo_entered(body: Node) -> void:
	if collected:
		return
	if not body.is_in_group("poo"):
		return
	collected = true

	# Transform the poo!
	match type:
		Type.MEGA:
			body.apply_mega()
		Type.BOUNCY:
			body.apply_bouncy()
		Type.SPEEDY:
			body.apply_speedy()

	_collect_flash()


func _collect_flash() -> void:
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(2.2, 2.2), 0.18)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.set_parallel(false)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	if collected:
		return
	bob_time += delta
	# Gentle float up and down
	position.y += sin(bob_time * 3.2) * 0.6
	queue_redraw()


func _draw() -> void:
	if collected:
		return
	var col    : Color = TYPE_COLOR[type]
	var pulse  : float = 0.5 + sin(bob_time * 5.0) * 0.5

	# Outer glow ring
	draw_arc(Vector2.ZERO, 32, 0.0, TAU, 40, Color(col.r, col.g, col.b, pulse * 0.55), 3.0)

	# Background circle
	draw_circle(Vector2.ZERO, 24, Color(col.r * 0.35, col.g * 0.35, col.b * 0.35))
	draw_circle(Vector2.ZERO, 22, col)

	# Inner highlight
	draw_circle(Vector2(-6, -6), 7.0, Color(1, 1, 1, 0.28))

	# Star shape (4-point)
	for i in 4:
		var angle = i * PI * 0.5 - PI * 0.25
		var tip   = Vector2(cos(angle), sin(angle)) * 18
		draw_line(Vector2.ZERO, tip, Color(1, 1, 1, 0.5), 2.5)

	# Label drawn as a floating text above
	# (Godot _draw doesn't support text natively, so we use a small indicator)
	# Draw the first letter as a colored block hint instead
	match type:
		Type.MEGA:
			# Big M shape
			draw_line(Vector2(-7, 8), Vector2(-7, -8),  Color(1, 1, 1, 0.9), 3)
			draw_line(Vector2(-7, -8), Vector2(0,  0),  Color(1, 1, 1, 0.9), 3)
			draw_line(Vector2(0,   0), Vector2(7, -8),  Color(1, 1, 1, 0.9), 3)
			draw_line(Vector2(7,  -8), Vector2(7,  8),  Color(1, 1, 1, 0.9), 3)
		Type.BOUNCY:
			# B shape (simplified arc)
			draw_arc(Vector2(0, 0), 8, deg_to_rad(-90), deg_to_rad(90), 12, Color(1,1,1,0.9), 3)
			draw_line(Vector2(0, -8), Vector2(0, 8), Color(1,1,1,0.9), 3)
		Type.SPEEDY:
			# Lightning bolt Z
			draw_line(Vector2(-6, -8), Vector2(6, -8), Color(1,1,1,0.9), 3)
			draw_line(Vector2(6, -8),  Vector2(-6, 8), Color(1,1,1,0.9), 3)
			draw_line(Vector2(-6, 8),  Vector2(6,  8), Color(1,1,1,0.9), 3)
