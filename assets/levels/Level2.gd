extends Node2D

func _on_PortalLevel1_body_entered(body):
	var scene = get_tree().current_scene
	scene.change_level("Level1", Vector2(0, -50))

func _on_BloodFountain_body_entered(body):
	body.heal(-1)
