extends CanvasLayer

var hearts = 4 setget set_hearts
var max_hearts = 4 setget set_max_hearts
var xp = 0 setget set_xp

onready var heartUIFull = $VBoxContainer/Top/HealthUI/HeartUIFull
onready var heartUIEmpty = $VBoxContainer/Top/HealthUI/HeartUIEmpty
onready var xpLabel = $VBoxContainer/Top/XP
onready var inventoryContainer = $VBoxContainer/Middle/CenterContainer
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
	self.max_hearts = Player.stats.max_health
	self.hearts = Player.stats.health
	health_bar.max_value = Player.stats.max_health
	health_bar.value = Player.stats.health
	# warning-ignore:return_value_discarded
	Player.stats.connect("health_changed", self, "set_hearts")
	# warning-ignore:return_value_discarded
	Player.stats.connect("max_health_changed", self, "set_max_hearts")
	inventoryContainer.visible = false

func _physics_process(delta):
	if Input.is_action_just_pressed("inventory"):
		inventoryContainer.visible = !inventoryContainer.visible
