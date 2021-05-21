extends Node2D

onready var ysort = $YSort
onready var player = $YSort/Player

var level_name: String
var level

func _ready():
#	level = preload("res://Level1.tscn").instance()
	change_level("Level1")

	#player = preload("res://Player/Player.tscn").instance()
	#player.translate(Vector2(120,100))
	#level.get_node("YSort").add_child(player)
	#get_node("YSort").add_child(player)

func change_level(new_level_name: String):
	free_level()
	level_name = new_level_name
	level = load("res://" + level_name + ".tscn").instance()
	for node in level.get_children():
		# Reparent level YSort nodes to World's YSort
		if node is YSort:
			call_deferred("reparent", node)
			#node.visible = true
	get_node("Background").add_child(level)

func free_level():
	if level:
		level.queue_free()
	for node in ysort.get_children():
		if !node is KinematicBody2D:
			node.queue_free()

func reparent(node: YSort):
	node.get_parent().remove_child(node)
	ysort.add_child(node)

#func _process(delta):
#	if Input.is_action_just_pressed("next_level"):
#		if level_name == "Level2":
#			change_level("Level1")
#		else:
#			change_level("Level2")
