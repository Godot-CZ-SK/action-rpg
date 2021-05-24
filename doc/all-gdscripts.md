# GDScripts

## `core/HUD.gd`
```
extends CanvasLayer

var hearts = 4 setget set_hearts
var max_hearts = 4 setget set_max_hearts
var xp = 0 setget set_xp

onready var heartUIFull = $VBoxContainer/Top/HealthUI/HeartUIFull
onready var heartUIEmpty = $VBoxContainer/Top/HealthUI/HeartUIEmpty
onready var xpLabel = $VBoxContainer/Top/XP
# progress bars
onready var health_bar = $VBoxContainer/Bottom/Health
onready var mana_bar = $VBoxContainer/Bottom/Mana
onready var xp_bar = $VBoxContainer/XP

func set_hearts(value):
	hearts = clamp(value, 0, max_hearts)
	if heartUIFull != null:
		heartUIFull.rect_size.x = hearts * 15
	health_bar.value = hearts

func set_max_hearts(value):
	max_hearts = max(value, 1)
	self.hearts = min(hearts, max_hearts)
	if heartUIEmpty != null:
		heartUIEmpty.rect_size.x = max_hearts * 15
	health_bar.max_value = max_hearts

func set_xp(value):
	xp = value
	xpLabel.text = str(xp)

func _ready():
	self.max_hearts = PlayerStats.max_health
	self.hearts = PlayerStats.health
	health_bar.max_value = PlayerStats.max_health
	health_bar.value = PlayerStats.health
	# warning-ignore:return_value_discarded
	PlayerStats.connect("health_changed", self, "set_hearts")
	# warning-ignore:return_value_discarded
	PlayerStats.connect("max_health_changed", self, "set_max_hearts")
```

## `core/Hitbox.gd`
```
extends Area2D

export var damage = 1
```

## `core/Stats.gd`
```
extends Node

export(int) var max_health = 1 setget set_max_health
var health = max_health setget set_health

signal no_health
signal health_changed(value)
signal max_health_changed(value)

func set_max_health(value):
	max_health = value
	self.health = min(health, max_health)
	emit_signal("max_health_changed", max_health)

func set_health(value):
	health = value
	emit_signal("health_changed", health)
	if health <= 0:
		emit_signal("no_health")

func _ready():
	self.health = max_health
```

## `core/Hurtbox.gd`
```
extends Area2D

const HitEffect = preload("res://assets/effects/HitEffect.tscn")

var invincible = false setget set_invincible

onready var timer = $Timer
onready var collisionShape = $CollisionShape2D

signal invincibility_started
signal invincibility_ended

func set_invincible(value):
	invincible = value
	if invincible == true:
		emit_signal("invincibility_started")
	else:
		emit_signal("invincibility_ended")

func start_invincibility(duration):
	self.invincible = true
	timer.start(duration)

func create_hit_effect():
	var effect = HitEffect.instance()
	var main = get_tree().current_scene
	main.add_child(effect)
	effect.global_position = global_position

func _on_Timer_timeout():
	self.invincible = false

func _on_Hurtbox_invincibility_started():
	print("invi started: " + str(get_parent().name))
	collisionShape.set_deferred("disabled", true)

func _on_Hurtbox_invincibility_ended():
	print("invi ended: " + str(get_parent().name))
	collisionShape.disabled = false
```

## `core/Inventory.gd`
```
extends Resource
class_name Inventory

signal item_changed(keys)

export(Array, Resource) var items = [
	null, null, null, null, null, null, null, null, null
]

func set_item(key, item):
	var previous = items[key]
	items[key] = item
	emit_signal("item_changed", [key])
	return previous

func swap_items(from_key, to_key):
	var to_item = items[to_key]
	items[to_key] = items[from_key]
	items[from_key] = to_item
	emit_signal("item_changed", [from_key, to_key])

func remove_item(key):
	var previous = items[key]
	items[key] = null
	emit_signal("item_changed", [key])
	return previous
```

## `core/SoftCollision.gd`
```
extends Area2D

func is_colliding():
	var areas = get_overlapping_areas()
	return areas.size() > 0

func get_push_vector():
	var areas = get_overlapping_areas()
	var push_vector = Vector2.ZERO
	if is_colliding():
		var area = areas[0]
		push_vector = area.global_position.direction_to(global_position)
		push_vector = push_vector.normalized()
	return push_vector
```

## `core/Camera2D.gd`
```
extends Camera2D

onready var topLeft = $Limits/TopLeft
onready var bottomRight = $Limits/BottomRight

func _ready():
	limit_top = topLeft.position.y
	limit_left = topLeft.position.x
	limit_bottom = bottomRight.position.y
	limit_right = bottomRight.position.x

```

## `core/SwordHitbox.gd`
```
extends "res://core/Hitbox.gd"

var knockback_vector = Vector2.ZERO
```

## `core/PlayerHurtSound.gd`
```
extends AudioStreamPlayer

func _ready():
	# warning-ignore:return_value_discarded
	connect("finished", self, "queue_free")
```

## `core/Player.gd`
```
extends KinematicBody2D

const PlayerHurtSound = preload("res://core/PlayerHurtSound.tscn")

export var ACCELERATION = 500
export var MAX_SPEED = 80
export var ROLL_SPEED = 120
export var FRICTION = 500

enum {
	DEAD,
	MOVE,
	ROLL,
	ATTACK
}

var state = MOVE
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var stats = PlayerStats

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAnimationPlayer

func _ready():
	randomize()
	stats.connect("no_health", self, "die")
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector

func _physics_process(delta):
	match state:
		DEAD:
			if Input.is_action_just_pressed("resurrect"):
				visible = true
				state = MOVE
				stats.health = 10
				stats.max_health = 10
				# Enable hurtbox
				hurtbox.timer.set_paused(false)
				#collision_layer = 2 # Player layer

		MOVE:
			move_state(delta)

		ROLL:
			roll_state()

		ATTACK:
			attack_state()

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		swordHitbox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move()

	if Input.is_action_just_pressed("roll"):
		state = ROLL

	if Input.is_action_just_pressed("attack"):
		state = ATTACK

func roll_state():
	velocity = roll_vector * ROLL_SPEED
	animationState.travel("Roll")
	move()

func attack_state():
	velocity = Vector2.ZERO
	animationState.travel("Attack")

func move():
	velocity = move_and_slide(velocity)

func roll_animation_finished():
	velocity = velocity * 0.8
	state = MOVE

func attack_animation_finished():
	state = MOVE

func _on_Hurtbox_area_entered(area):
	damage(area.damage)
	hurtbox.start_invincibility(0.6)
	hurtbox.create_hit_effect()
	var playerHurtSound = PlayerHurtSound.instance()
	get_tree().current_scene.add_child(playerHurtSound)

func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")

func damage(amount):
	stats.health -= amount

func heal(amount):
	if (amount < 0):
		stats.health = stats.max_health
	else:
		stats.health += amount

func die():
	#queue_free()
	visible = false
	state = DEAD

	# Disable hurtbox
	hurtbox.timer.set_paused(true)
	hurtbox.collisionShape.set_deferred("disabled", true)
	#collision_layer = 0
```

## `Game.gd`
```
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

func change_level(new_level_name: String, new_position := Vector2(0, 0)):
	free_level()
	player.position = new_position
	level_name = new_level_name
	level = load("res://assets/levels/" + level_name + ".tscn").instance()
	for node in level.get_children():
		# Reparent level YSort nodes to World's YSort
		if node is YSort:
			call_deferred("reparent", node)
			#node.visible = true
	get_node("Background").call_deferred("add_child", level)

func free_level():
	if level:
		level.queue_free()
	for node in ysort.get_children():
		if !node is KinematicBody2D:
			node.queue_free()

func reparent(node: YSort):
	node.get_parent().remove_child(node)
	ysort.add_child(node)
```

## `assets/enemies/WanderController.gd`
```
extends Node2D

export(int) var wander_range = 32

onready var start_position = global_position
onready var target_position = global_position

onready var timer = $Timer

func _ready():
	update_target_position()

func update_target_position():
	var target_vector = Vector2(rand_range(-wander_range, wander_range), rand_range(-wander_range, wander_range))
	target_position = start_position + target_vector

func get_time_left():
	return timer.time_left

func start_wander_timer(duration):
	timer.start(duration)

func _on_Timer_timeout():
	update_target_position()
```

## `assets/enemies/bat/Bat.gd`
```
extends KinematicBody2D

const EnemyDeathEffect = preload("res://assets/effects/EnemyDeathEffect.tscn")

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200
export var WANDER_TARGET_RANGE = 4

enum {
	IDLE,
	WANDER,
	CHASE
}

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO

var state = CHASE
export var xp = 5

onready var sprite = $AnimatedSprite
onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var animationPlayer = $AnimationPlayer

func _ready():
	state = pick_random_state([IDLE, WANDER])

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	knockback = move_and_slide(knockback)

	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander()

		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander()
			accelerate_towards_point(wanderController.target_position, delta)
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				update_wander()

		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				accelerate_towards_point(player.global_position, delta)
			else:
				state = IDLE

	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400
	velocity = move_and_slide(velocity)

func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 150
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)

func _on_Stats_no_health():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position
	HUD.xp += xp

func _on_Hurtbox_invincibility_started():
	animationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	animationPlayer.play("Stop")
```

## `assets/enemies/PlayerDetectionZone.gd`
```
extends Area2D

var player = null

func can_see_player():
	return player != null

func _on_PlayerDetectionZone_body_entered(body):
	player = body

func _on_PlayerDetectionZone_body_exited(_body):
	player = null
```

## `assets/world/Portal.gd`
```
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
```

## `assets/world/grass/Grass.gd`
```
extends Node2D

const GrassEffect = preload("res://assets/effects/GrassEffect.tscn")

func create_grass_effect():
	var grassEffect = GrassEffect.instance()
	get_parent().add_child(grassEffect)
	grassEffect.global_position = global_position

func _on_Hurtbox_area_entered(_area):
	create_grass_effect()
	queue_free()
```

## `assets/levels/Level1.gd`
```
extends Node2D

onready var game = get_tree().current_scene

func _ready():
	print(game.player)

func _on_PortalLevel2_body_entered(body):
	game.change_level("Level2", Vector2(200, -120))
```

## `assets/levels/Level2.gd`
```
extends Node2D

func _on_BloodFountain_body_entered(body):
	body.heal(-1)
```

## `assets/items/Item.gd`
```
extends Resource
class_name Item

export(String) var name := ""
export(Texture) var texture: Texture
```

## `assets/effects/Effect.gd`
```
extends AnimatedSprite

func _ready():
	# warning-ignore:return_value_discarded
	connect("animation_finished", self, "_on_animation_finished")
	play("Animate")

func _on_animation_finished():
	queue_free()
```

