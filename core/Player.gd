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
onready var stats = $PlayerStats

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
	# Add RemoteTransform2D and attach it's remote_path to Cam
	var remoteTransform = RemoteTransform2D.new()
	remoteTransform.name = str(remoteTransform.get_class())
	remoteTransform.remote_path = "/root/Cam"
	add_child(remoteTransform)
	call_deferred("init_in_level")

func init_in_level():
	var ysort = get_tree().current_scene.get_node("YSort")
	get_parent().remove_child(self)
	ysort.add_child(self)
	global_position = Vector2(0, 0)

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
