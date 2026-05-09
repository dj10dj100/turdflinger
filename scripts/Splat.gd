extends Node2D

# ─────────────────────────────────────────────
#  Splat – brown poo explosion when toilet dies 💥
# ─────────────────────────────────────────────

const LIFETIME := 1.4

var drops    : Array  = []
var elapsed  : float  = 0.0


func _ready() -> void:
	# Spawn 10-16 drops flying outward
	for _i in randi_range(10, 16):
		var angle  = randf() * TAU
		var speed  = randf_range(90, 310)
		var sz     = randf_range(5, 16)
		drops.append({
			"pos":   Vector2.ZERO,
			"vel":   Vector2(cos(angle), sin(angle)) * speed,
			"size":  sz,
			"alpha": 1.0,
		})

	# A few extra smaller drops for richness
	for _i in 6:
		var angle  = randf() * TAU
		drops.append({
			"pos":   Vector2.ZERO,
			"vel":   Vector2(cos(angle), sin(angle)) * randf_range(200, 450),
			"size":  randf_range(3, 7),
			"alpha": 1.0,
		})


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= LIFETIME:
		queue_free()
		return

	for d in drops:
		d["vel"] += Vector2(0, 520) * delta   # gravity pulls drops down
		d["vel"].x *= 0.97                     # slight air resistance
		d["pos"]   += d["vel"] * delta
		d["alpha"]  = max(0.0, 1.0 - elapsed / LIFETIME)

	queue_redraw()


func _draw() -> void:
	for d in drops:
		if d["alpha"] <= 0.0:
			continue
		var col  = Color(0.40, 0.22, 0.04, d["alpha"])
		var col2 = Color(0.55, 0.30, 0.08, d["alpha"] * 0.6)
		var pos  : Vector2 = d["pos"]
		var sz   : float   = d["size"]

		# Main blob
		draw_circle(pos, sz, col)

		# Tail stretched behind the velocity
		if d["vel"].length() > 20:
			var tail = pos - d["vel"].normalized() * sz * 1.8
			draw_line(pos, tail, col2, sz * 0.55)
