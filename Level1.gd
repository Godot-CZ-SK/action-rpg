extends Node2D

func _on_PortalLevel2_body_entered(body):
	var scene = get_tree().current_scene
	scene.change_level("Level2")
	scene.player.position = Vector2(0, 0)
