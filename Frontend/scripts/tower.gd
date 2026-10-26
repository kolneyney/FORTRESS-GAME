extends Node2D

@export var defense_name = "firewall"

# each tower deals double damage to the threat it counters
const COUNTERS = {
	"firewall": "ddos",
	"antivirus": "malware",
	"mfa": "brute_force",
	"backup": "ransomware",
}

const COLORS = {
	"firewall": Color(1.0, 0.5, 0.1),
	"antivirus": Color(0.4, 1.0, 0.4),
	"mfa": Color(1.0, 0.9, 0.3),
	"backup": Color(1.0, 0.3, 0.3),
}

@onready var sprite = $Sprite2D

var cooldown = 0.0
var shown_level = -1
var base_scale = 1.0


class Bolt extends Node2D:
	var color = Color.WHITE

	func _draw():
		draw_circle(Vector2.ZERO, 3.0, color)


class Ring extends Node2D:
	var color = Color.WHITE
	var radius = 4.0:
		set(value):
			radius = value
			queue_redraw()

	func _draw():
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, 2.0)


class Slash extends Node2D:
	var color = Color.WHITE

	func _draw():
		draw_arc(Vector2.ZERO, 10.0, -1.0, 1.0, 12, color, 3.0)


func level():
	return GameState.levels[defense_name]


func tower_range():
	match defense_name:
		"firewall":
			return 80.0 + level() * 12.0
		"antivirus":
			return 55.0 + level() * 8.0
		"mfa":
			return 34.0 + level() * 4.0
	return 90.0 + level() * 10.0


func interval():
	match defense_name:
		"firewall":
			return maxf(0.5, 1.4 - level() * 0.15)
		"antivirus":
			return maxf(1.2, 3.0 - level() * 0.3)
		"mfa":
			return maxf(0.5, 1.2 - level() * 0.1)
	return maxf(1.0, 2.4 - level() * 0.2)


func dmg_vs(target, base):
	if target.threat_type == COUNTERS[defense_name]:
		return base * 2.0
	return float(base)


func _process(delta):
	if level() != shown_level:
		shown_level = level()
		queue_redraw()
		base_scale = 1.0 + shown_level * 0.12
		sprite.scale = Vector2(base_scale, base_scale)
		if shown_level == 0:
			sprite.modulate = Color(1, 1, 1, 0.35)
		else:
			var tint = clampf(shown_level * 0.08, 0.0, 0.4)
			sprite.modulate = Color(1, 1, 1, 1).lerp(COLORS[defense_name], tint)
	if level() == 0:
		return

	cooldown -= delta
	if cooldown > 0.0:
		return
	var targets = _enemies_in_range()
	if targets.is_empty():
		return

	match defense_name:
		"firewall":
			_fire(targets[0])
		"antivirus":
			_pulse(targets)
		"mfa":
			_slash(targets[0])
		"backup":
			_volley(targets[0])
	cooldown = interval()


func _enemies_in_range():
	var list = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(e.global_position) <= tower_range():
			list.append(e)
	list.sort_custom(_closer)
	return list


func _closer(a, b):
	return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)


func _enemies_near(pos, radius):
	var list = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if pos.distance_to(e.global_position) <= radius:
			list.append(e)
	return list


func _pop():
	sprite.scale = Vector2(base_scale * 1.3, base_scale * 1.3)
	var tw = create_tween()
	tw.tween_property(sprite, "scale", Vector2(base_scale, base_scale), 0.15)


func _show_bolt(to_pos, color):
	var b = Bolt.new()
	b.color = color
	b.z_index = 10
	get_parent().add_child(b)
	b.global_position = global_position
	var tw = b.create_tween()
	tw.tween_property(b, "global_position", to_pos, 0.1)
	tw.tween_callback(b.queue_free)


# FIREWALL: fireball + burning
func _fire(target):
	var pos = target.global_position
	target.take_damage(dmg_vs(target, 6 + level() * 3))
	for e in _enemies_near(pos, 28.0):
		e.apply_burn(3.0, 3.0 + level() * 2.0)
	_show_bolt(pos, COLORS["firewall"])
	_pop()


# ANTIVIRUS: scan pulse, damages and slows everything in range
func _pulse(targets):
	for e in targets:
		e.take_damage(dmg_vs(e, 5 + level() * 3))
		e.apply_slow(2.0, 0.5)
	var r = Ring.new()
	r.color = COLORS["antivirus"]
	r.z_index = 10
	add_child(r)
	var tw = r.create_tween()
	tw.set_parallel(true)
	tw.tween_property(r, "radius", tower_range(), 0.4)
	tw.tween_property(r, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(r.queue_free)
	_pop()


# MFA KNIGHT: sword slash + stun
func _slash(target):
	target.take_damage(dmg_vs(target, 16 + level() * 8))
	target.apply_stun(0.5)
	var dir = (target.global_position - global_position).normalized()

	var s = Slash.new()
	s.color = COLORS["mfa"]
	s.z_index = 10
	s.rotation = dir.angle()
	s.position = dir * 12.0
	add_child(s)
	var tw = s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, 0.2)
	tw.tween_callback(s.queue_free)

	var lunge = create_tween()
	lunge.tween_property(sprite, "position", dir * 6.0, 0.06)
	lunge.tween_property(sprite, "position", Vector2.ZERO, 0.12)


# BACKUP: bundle of all four attacks on one enemy
func _volley(target):
	var cols = [COLORS["firewall"], COLORS["antivirus"], COLORS["mfa"], COLORS["backup"]]
	var base = 3 + level() * 2
	_pop()
	for i in 4:
		if not is_instance_valid(target) or target.dying:
			break
		target.take_damage(dmg_vs(target, base))
		_show_bolt(target.global_position, cols[i])
		if i == 0:
			target.apply_burn(3.0, 3.0 + level() * 2.0)
		elif i == 1:
			target.apply_slow(2.0, 0.5)
		elif i == 2:
			target.apply_stun(0.3)
		await get_tree().create_timer(0.08, false).timeout


func _draw():
	if level() > 0:
		draw_arc(Vector2.ZERO, tower_range(), 0.0, TAU, 48, Color(1, 1, 1, 0.12), 1.0)
	if level() >= 3:
		var glow = COLORS[defense_name]
		glow.a = 0.15 + (level() - 3) * 0.1
		draw_circle(Vector2.ZERO, 11.0 + level(), glow)
	for i in level():
		draw_rect(Rect2(-8 + i * 4, 12, 3, 3), COLORS[defense_name])
