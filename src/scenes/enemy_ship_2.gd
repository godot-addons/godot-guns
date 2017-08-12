extends RigidBody2D

onready var enemy_ship = $"../enemy_ship"

func _ready():
	$weapon_1.connect("volley_fired", self, "set_targets")
	#$weapon_2.connect("volley_fired", self, "set_targets")
	#$weapon_2.connect("volley_fired", self, "set_targets")

func _process(delta):
	$weapon_1.look_at(enemy_ship.global_position)
	$weapon_2.look_at(enemy_ship.global_position)
	$weapon_3.look_at(enemy_ship.global_position)

func set_targets(bullets):
	for bullet in bullets:
		bullet.set_target(enemy_ship)
