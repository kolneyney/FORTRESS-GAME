extends CharacterBody2D

const TYPES = {
	"malware": {"hp": 30, "speed": 40.0, "damage": 10, "scale": 1.0, "color": Color(0.6, 1.0, 0.4)},
	"ddos": {"hp": 15, "speed": 70.0, "damage": 5, "scale": 0.8, "color": Color(1.0, 0.65, 0.2)},
	"brute_force": {"hp": 50, "speed": 30.0, "damage": 10, "scale": 1.2, "color": Color(1.0, 1.0, 0.3)},
	"phishing": {"hp": 25, "speed": 50.0, "damage": 10, "scale": 1.0, "color": Color(0.4, 0.9, 1.0)},
	"ransomware": {"hp": 120, "speed": 25.0, "damage": 25, "scale": 1.5, "color": Color(1.0, 0.3, 0.3)},
}

var threat_type = "malware"
var hp_mult = 1.0
var waypoints = []
var target_position = Vector2.ZERO

var speed = 40.0
var hp = 30.0
var max_hp = 30.0
var damage = 10
var base_color = Color.WHITE
var dying = false
var time = 0.0

var burn_time = 0.0
var burn_dps = 0.0
var burn_tick = 0.0
var slow_time = 0.0
var slow_factor = 1.0
var stun_time = 0.0

@onready var sprite = $Sprite2D


func _ready():
	add_to_group("enemies")
	var t = TYPES[threat_type]
	speed = t["speed"]
	hp = float(t["hp"]) * hp_mult
	max_hp = hp
	damage = t["damage"]
	base_color = t["color"]
	sprite.modulate = base_color
	sprite.scale = Vector2(t["scale"], t["scale"])
	time = randf() * 6.0


func _physics_process(delta):
	if dying:
		return
	time += delta
	sprite.position.y = sin(time * 10.0) * 1.5

	_update_status(delta)
	if dying:
		return
	if stun_time > 0.0:
		return

	var goal = target_position
	if waypoints.size() > 0:
		goal = waypoints[0]
		if global_position.distance_to(goal) < 6.0:
			waypoints.pop_front()
			return

	var current_speed = speed
	if slow_time > 0.0:
		current_speed = speed * slow_factor
	velocity = global_position.direction_to(goal) * current_speed
	move_and_slide()


func _update_status(delta):
	if stun_time > 0.0:
		stun_time -= delta
	if slow_time > 0.0:
		slow_time -= delta
	if burn_time > 0.0:
		burn_time -= delta
		burn_tick -= delta
		if burn_tick <= 0.0:
			burn_tick = 0.5
			take_damage(burn_dps * 0.5, Color(1.0, 0.5, 0.1))


func take_damage(amount, flash_color = Color.WHITE):
	if dying:
		return
	hp -= amount
	queue_redraw()
	sprite.modulate = flash_color
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", base_color, 0.12)
	if hp <= 0.0:
		die()


func apply_burn(duration, dps):
	if dying:
		return
	burn_time = maxf(burn_time, duration)
	burn_dps = maxf(burn_dps, dps)


func apply_slow(duration, factor):
	if dying:
		return
	slow_time = maxf(slow_time, duration)
	slow_factor = factor


func apply_stun(duration):
	if dying:
		return
	stun_time = maxf(stun_time, duration)


func die():
	dying = true
	remove_from_group("enemies")
	$CollisionShape2D.set_deferred("disabled", true)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", sprite.scale * 1.6, 0.25)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)


func _draw():
	if hp >= max_hp or dying:
		return
	var w = 16.0
	draw_rect(Rect2(-w / 2.0, -14, w, 3), Color(0.15, 0.1, 0.15))
	draw_rect(Rect2(-w / 2.0, -14, w * hp / max_hp, 3), Color(0.3, 1.0, 0.4))
