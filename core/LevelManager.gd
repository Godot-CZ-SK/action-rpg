extends Node

export var _levels_dir := "res://assets/levels"

var level_name: String
var level

onready var ysort

func _ready():
	var root = get_tree().get_root()
	level = root.get_child(root.get_child_count() - 1)

func change_level(new_level_name: String, new_position = null):
	level_name = new_level_name
	call_deferred("_change_scene", _levels_dir + "/" + level_name + ".tscn", new_position)

func _change_scene(path: String, new_position = null):
	if level.get_filename() != path:
		Player.get_parent().remove_child(Player)
		# It is now safe to remove the current scene
		level.free()
		level = load(path).instance()
		get_tree().get_root().add_child(level)
		get_tree().set_current_scene(level)

	if level.has_node("YSort"):
		ysort = level.get_node("YSort")
		ysort.add_child(Player)
	else:
		ysort = null

	Player.global_position = new_position

	if level.has_node("CamLimits"):
		var top_left = level.get_node("CamLimits/TopLeft")
		var bottom_right = level.get_node("CamLimits/BottomRight")
		Cam.change_limits(top_left.position.x, top_left.position.y, bottom_right.position.x, bottom_right.position.y)
