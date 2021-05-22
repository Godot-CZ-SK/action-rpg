extends Node2D

func _on_BloodFountain_body_entered(body):
	body.heal(-1)
