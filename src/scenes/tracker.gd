extends Node2D

onready var enemy_ship = $"../enemy_ship"

func _ready():
	$weapon.connect("volley_fired", self, "set_targets")

func set_targets(bullets):
	for bullet in bullets:
		bullet.set_target(enemy_ship)
