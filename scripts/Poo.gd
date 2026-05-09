extends RigidBody2D

# ─────────────────────────────────────────────
#  Poo – top-down sliding character 💩
#  No gravity. Slides across the floor.
#  Bounces off walls. Dies when it hits a toilet.
# ─────────────────────────────────────────────

const RADIUS        = 28.0
const MAX_LIFETIME  = 5.0    # auto-destroy after this many seconds

var _trail        : Array = []
var _powerup_tint : Color = Color(1, 1, 1, 0)
var _sprite       : Sprite2D
var _age          : float = 0.0


func apply_mega() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(2.5, 2.5), 0.22)
	_powerup_tint = Color(1.0, 0.35, 0.1, 0.65)


func apply_bouncy() -> void:
	physics_material_override.bounce   = 0.95
	physics_material_override.friction = 0.0
	_powerup_tint = Color(0.25, 0.75, 1.0, 0.65)


func apply_speedy() -> void:
	linear_velocity = linear_velocity.normalized() * linear_velocity.length() * 2.0
	_powerup_tint = Color(0.9, 1.0, 0.15, 0.65)


func _ready() -> void:
	add_to_group("poo")

	# No gravity – top-down view
	gravity_scale = 0.0
	linear_damp   = 0.4     # gentle friction so poo slows on the floor
	angular_damp  = 5.0

	var mat               = PhysicsMaterial.new()
	mat.bounce            = 0.55
	mat.friction          = 0.2
	physics_material_override = mat

	# Collision circle
	var coll     = CollisionShape2D.new()
	var shape    = CircleShape2D.new()
	shape.radius = RADIUS
	coll.shape   = shape
	add_child(coll)

	# turd.PNG as the character sprite
	_sprite          = Sprite2D.new()
	_sprite.texture  = load("res://turd.PNG")
	_sprite.centered = true
	_sprite.hframes  = 1
	_sprite.vframes  = 1
	_sprite.frame    = 0

	if _sprite.texture:
		var longest   = max(_sprite.texture.get_size().x, _sprite.texture.get_size().y)
		_sprite.scale = Vector2((RADIUS * 2.2) / longest, (RADIUS * 2.2) / longest)

	add_child(_sprite)


func _physics_process(delta: float) -> void:
	_age += delta

	# Rotate sprite to face the direction of travel – looks great top-down!
	if linear_velocity.length() > 30:
		rotation = linear_velocity.angle()

	# Record trail
	_trail.append(global_position)
	if _trail.size() > 10:
		_trail.pop_front()

	# Die if very slow or too old
	if _age > MAX_LIFETIME or (linear_velocity.length() < 20 and _age > 0.5):
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	# Fading shadow trail
	var n = _trail.size()
	for i in n:
		var p     = _trail[i] - global_position
		var alpha = float(i) / n * 0.35
		var r     = lerp(2.0, RADIUS * 0.4, float(i) / n)
		draw_circle(p, r, Color(0.2, 0.12, 0.02, alpha))

	# Power-up glow ring
	if _powerup_tint.a > 0.0:
		draw_arc(Vector2.ZERO, RADIUS + 8, 0.0, TAU, 36, _powerup_tint, 5.0)
