tool
extends Area2D

export(bool) var active := false setget set_active
export(String) var level := "Level1"
export(Vector2) var coords := Vector2(0, 0)

func is_active():
	return active

func set_active(new_value: bool):
	active = new_value
	if active:
		$Portal.set_animation("enabled")
	else:
		$Portal.set_animation("disabled")

func _on_Portal_body_entered(body):
	if not active:
		return
	var scene = get_tree().current_scene
	#scene.change_level("Level2", Vector2(200, -120))
	scene.change_level(level, coords)
