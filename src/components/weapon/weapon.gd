extends Node2D

const BULLET_OWNER_NODE = "/root/main/bullets"
const CHILD_BULLETS_NAME = "ChildBullets"
const SPRITE_NODE_NAME = "sprite"

var can_fire = true setget set_can_fire

export(bool) var auto_fire = true
export(float) var fire_delay = 1.0
export(float) var reload_delay = 2.0
export(int) var ammo = -1 setget set_ammo
export(int) var clip_size = 1 setget set_clip_size
#export var shots = ["res://components/bullet/bullet.tscn"]
export(String) var shots = "res://components/bullet/bullet.tscn"

onready var sprite = get_node(SPRITE_NODE_NAME)

var _ammo_left_in_clip = 1
var _timer_node = null

signal volley_fired
signal out_of_ammo
signal clip_empty
signal can_fire_again

func _ready():
	# setup nodes
	var child_bullets = Node2D.new()
	child_bullets.set_name(CHILD_BULLETS_NAME)
	add_child(child_bullets)
	child_bullets.set_owner(get_node(BULLET_OWNER_NODE))

	_timer_node = Timer.new()
	add_child(_timer_node)
	_timer_node.set_wait_time(fire_delay)
	_timer_node.start()
	_ammo_left_in_clip = clip_size

	_timer_node.connect("timeout", self, "set_can_fire", [true])

	if auto_fire:
		call_deferred("fire")

func set_clip_size(val):
	clip_size = val
	if val < _ammo_left_in_clip:
		_ammo_left_in_clip = val

func set_can_fire(val):
	can_fire = val
	if val:
		emit_signal("can_fire_again")
		if auto_fire:
			fire()

func reload():
	_ammo_left_in_clip = clip_size
	can_fire = false
	_timer_node.set_wait_time(reload_delay)
	_timer_node.start()

func set_ammo(val):
	ammo = val
	if ammo < _ammo_left_in_clip:
		_ammo_left_in_clip = ammo

func fire():
	if !can_fire:
		return

	var bullets = []

#	for bullet_scene in shots:
#		#print("bullet_scene:", bullet_scene)
#		var bullet = load(bullet_scene).instance()
#		bullet.setup(self)
#		bullets.append(bullet)

	var bullet = load(shots).instance()
	bullet.setup(self)
	#bullet.set_kill_after_time(2)
	#bullet.set_kill_travel_dist(2000)
	bullets.append(bullet)

	emit_signal("volley_fired", bullets)

	set_can_fire(false)
	_ammo_left_in_clip -= 1
	if ammo > 0:
		ammo -= 1

	# prepare to fire again if possible
	if ammo + 1 > 0 and ammo <= 0:
		emit_signal("out_of_ammo")
		_timer_node.stop()
	else:
		_timer_node.stop()

		if _ammo_left_in_clip <= 0:
			emit_signal("clip_empty")
			if auto_fire:
				reload()
		else:
			_timer_node.set_wait_time(fire_delay)
			_timer_node.start()

func get_bullet_start_pos():
	return sprite.global_position
