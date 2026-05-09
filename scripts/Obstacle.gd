extends Node2D

# ─────────────────────────────────────────────
#  Obstacle – things in the way! 🚧
#  Types: WALL (static block), SPINNER (rotating bar), BOUNCER (trampoline)
# ─────────────────────────────────────────────

enum Type { WALL, SPINNER, BOUNCER }

var type        : Type  = Type.WALL
var spin_speed  : float = 80.0    # degrees per second, for SPINNER
var wall_height : float = 90.0    # for WALL


func _ready() -> void:
	add_to_group("obstacles")
	match type:
		Type.WALL:
			_build_wall()
		Type.SPINNER:
			_build_spinner()
		Type.BOUNCER:
			_build_bouncer()


# ─────────────────────────────────────────────
#  Wall – static block the poo must avoid
# ─────────────────────────────────────────────
func _build_wall() -> void:
	var body             = StaticBody2D.new()
	body.collision_layer = 4
	body.collision_mask  = 2
	_add_rect_shape(body, Vector2.ZERO, Vector2(20, wall_height))
	add_child(body)


# ─────────────────────────────────────────────
#  Spinner – rotating platform
# ─────────────────────────────────────────────
func _build_spinner() -> void:
	var body             = StaticBody2D.new()
	body.collision_layer = 4
	body.collision_mask  = 2
	_add_rect_shape(body, Vector2.ZERO, Vector2(130, 14))
	add_child(body)


# ─────────────────────────────────────────────
#  Bouncer – launches poo upward on contact
# ─────────────────────────────────────────────
func _build_bouncer() -> void:
	# Visual-only static body for the platform surface
	var body             = StaticBody2D.new()
	body.collision_layer = 4
	body.collision_mask  = 2
	var mat              = PhysicsMaterial.new()
	mat.bounce           = 0.0
	body.physics_material_override = mat
	_add_rect_shape(body, Vector2.ZERO, Vector2(110, 14))
	add_child(body)

	# Area2D that detects poo and blasts it upward
	var area             = Area2D.new()
	area.collision_layer = 16
	area.collision_mask  = 2
	_add_rect_shape(area, Vector2(0, -10), Vector2(110, 24))
	area.connect("body_entered", _on_bouncer_contact)
	add_child(area)


func _add_rect_shape(parent: Node, offset: Vector2, size: Vector2) -> void:
	var coll    = CollisionShape2D.new()
	var shape   = RectangleShape2D.new()
	shape.size  = size
	coll.shape  = shape
	coll.position = offset
	parent.add_child(coll)


func _on_bouncer_contact(body: Node) -> void:
	if body.is_in_group("poo"):
		# Blast poo straight up, keep horizontal momentum
		var vel = body.linear_velocity
		body.linear_velocity = Vector2(vel.x * 0.6, -680)


# ─────────────────────────────────────────────
#  Process & Draw
# ─────────────────────────────────────────────
func _process(delta: float) -> void:
	if type == Type.SPINNER:
		rotation += deg_to_rad(spin_speed) * delta
	queue_redraw()


func _draw() -> void:
	match type:
		Type.WALL:
			var h = wall_height
			# Striped warning block
			draw_rect(Rect2(-10, -h * 0.5, 20, h), Color(0.55, 0.38, 0.18))
			draw_rect(Rect2(-10, -h * 0.5, 20, h), Color(0.78, 0.58, 0.28), false, 2.5)
			# Warning stripes
			var stripe_count = int(h / 16)
			for i in stripe_count:
				if i % 2 == 0:
					draw_rect(
						Rect2(-10, -h * 0.5 + i * 16, 20, 8),
						Color(1.0, 0.85, 0.0, 0.35)
					)

		Type.SPINNER:
			# Rotating bar – blue/white
			draw_rect(Rect2(-65, -7, 130, 14), Color(0.25, 0.55, 0.92))
			draw_rect(Rect2(-65, -7, 130, 14), Color(0.55, 0.82, 1.0), false, 2.5)
			# Center hub
			draw_circle(Vector2.ZERO, 8, Color(1.0, 0.88, 0.18))
			draw_circle(Vector2.ZERO, 5, Color(0.8, 0.65, 0.0))

		Type.BOUNCER:
			# Trampoline – green with zigzag
			draw_rect(Rect2(-55, -7, 110, 14), Color(0.18, 0.82, 0.35))
			draw_rect(Rect2(-55, -7, 110, 14), Color(0.45, 1.0, 0.58), false, 2.5)
			# Bounce zigzag arrows
			for i in 5:
				var x = -38 + i * 18
				draw_line(Vector2(x,      2), Vector2(x + 9, -5), Color(1, 1, 1, 0.65), 2)
				draw_line(Vector2(x + 9, -5), Vector2(x + 18, 2), Color(1, 1, 1, 0.65), 2)
			# Little up arrows at ends
			draw_line(Vector2(-48, 4), Vector2(-48, -8), Color(1,1,1,0.55), 2)
			draw_line(Vector2(-48,-8), Vector2(-53, -2), Color(1,1,1,0.55), 2)
			draw_line(Vector2(-48,-8), Vector2(-43, -2), Color(1,1,1,0.55), 2)
			draw_line(Vector2( 48, 4), Vector2( 48, -8), Color(1,1,1,0.55), 2)
			draw_line(Vector2( 48,-8), Vector2( 43, -2), Color(1,1,1,0.55), 2)
			draw_line(Vector2( 48,-8), Vector2( 53, -2), Color(1,1,1,0.55), 2)
