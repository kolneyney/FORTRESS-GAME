extends Area2D

signal health_changed(new_health)
signal castle_destroyed

var health = 100


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("enemies"):
		take_damage(body.damage)
		body.queue_free()


func take_damage(amount):
	health = max(health - amount, 0)
	health_changed.emit(health)
	if health == 0:
		castle_destroyed.emit()
