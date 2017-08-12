extends Node2D

const BULLET_OWNER_NODE = "/root/main/bullets"
const CHILD_BULLETS_NAME = "ChildBullets"
const SPRITE_NODE_NAME = "Sprite"
const COLLIDER_NODE_NAME = "collision"

# misc vars
export var fire_pos_offset = [0.0, 0.0]
export(bool) var follow_gun = false
export(bool) var fit_collider_to_sprite = true setget set_fit_collider_to_sprite

# scaling change related vars
export var size_scaling_velocity = [0.0, 0.0]
export var max_size_scale = [0.0, 0.0]

# death/kill/free() related vars
export(bool) var kill_on_collide = false setget set_kill_on_collide
export(bool) var kill_viewport_exit = true setget set_kill_viewport_exit
export(int) var kill_travel_dist = -1 setget set_kill_travel_dist
export(int) var kill_after_time = -1 setget set_kill_after_time

var gun_shot_from = null
var deleted = false
var target = null setget set_target

# PID controller vars for torque value when bullet is tracking an object
var _prev_error = 0
var _P = 0
var _I = 0
var _D = 0

# PID controller gain values
var _PID_Kp = 1000.0
var _PID_Ki = 100.0
var _PID_Kd = 1000.0
#var _PID_Kp = 2000.0
#var _PID_Ki = 1000.0
#var _PID_Kd = 100.0

var _traveled_dist = 0
var _prev_pos = null
var _vis_notifier = null

signal bullet_killed

func _ready():
	#set_process(true)
	#set_fixed_process(true)

	if fit_collider_to_sprite:
		resize_to(get_node(SPRITE_NODE_NAME), get_node(COLLIDER_NODE_NAME))

func _process(delta):
	if target:
		_track_target(delta)

func _fixed_process(delta):
	#increment travel distance if that is a death param
	if _prev_pos != null and !deleted:
		_traveled_dist += global_position.distance_to(_prev_pos)

		if _traveled_dist >= kill_travel_dist:
			kill()
		else:
			_prev_pos = global_position

func _integrate_forces(state):
	if size_scaling_velocity[0] != 0 and size_scaling_velocity[1] != 0:
		_scale_bullet()

func setup(shooting_gun):
	gun_shot_from = shooting_gun
	set_z(min(get_z(), gun_shot_from.get_z() - 1)) #ensure behind gun
	#z = min(z, gun_shot_from.z - 1) #ensure behind gun

	#choose parent
	var node_parent
	#var root_node = gun_shot_from.get_node("/root")
	var root_node = gun_shot_from.get_node(BULLET_OWNER_NODE)

	if follow_gun:
		node_parent = gun_shot_from.get_node(CHILD_BULLETS_NAME)
	else:
		node_parent = root_node

	node_parent.add_child(self)

	#set bullet position
	var offset = Vector2(fire_pos_offset[0], fire_pos_offset[1])
	if node_parent == root_node:
		offset += gun_shot_from.get_bullet_start_pos()

	#set_pos(offset)
	position = offset

	#set_global_rot(gun_shot_from.get_global_rot())
	global_rotation = gun_shot_from.global_rotation

	#_set_vel_from_angle(get_global_rot())
	_set_vel_from_angle(global_rotation)

func _set_vel_from_angle(angle):
	#magnitude of rigid body's linear velocity
	var speed = sqrt(get_linear_velocity().length_squared())
	#var vx = speed * cos(-angle) #idk why this is negative?
	var vx = speed * cos(angle)
	var vy = speed * sin(angle)
	set_linear_velocity(Vector2(vx, vy))

#requires rigid_body to be in Kinematic mode
func _scale_bullet():
	#var size = get_scale()
	#var size = scale
	var new_x = scale.x + size_scaling_velocity[0]
	var new_y = scale.y + size_scaling_velocity[1]

	if max_size_scale != null:
		if new_x > max_size_scale[0]:
			new_x = scale.x

		if new_y > max_size_scale[1]:
			new_y = scale.y

	#set_scale(Vector2(new_x, new_y))
	scale = Vector2(new_x, new_y)

func _get_PID_output(current_error, delta):
	_P = current_error
	_I += _P * delta
	_D = (_P - _prev_error) / delta
	_prev_error = current_error

	return _I * _PID_Ki + _D * _PID_Kd
	#return _P * _PID_Kp + _D * _PID_Kd
	#return _P * _PID_Kp + _I * _PID_Ki
	#return _P * _PID_Kp + _I * _PID_Ki + _D * _PID_Kd

# Something in this function needs some fixing
func _track_target(delta):
	var angle_btw = global_position.angle_to_point(target.global_position) - PI / 2
	var error = global_rotation - angle_btw
	#error = rad2deg(error)

	#deal with angle discontinuity
	#https://stackoverflow.com/questions/10697844/how-to-deal-with-the-discontinuity-of-yaw-angle-at-180-degree
	if error > PI:
		 error = error - PI * 2
	elif error < -PI:
		 error = error + PI * 2

	#if error >= 180:
	#	error = error - 360 * delta
	#elif error <= -180:
	#	error = error + 360 * delta

	var torque = _get_PID_output(error, delta)
	set_applied_torque(torque)
	_set_vel_from_angle(global_rotation)

func set_fit_collider_to_sprite(val):
	fit_collider_to_sprite = val
	if fit_collider_to_sprite and has_node(SPRITE_NODE_NAME) and has_node(COLLIDER_NODE_NAME):
		resize_to(get_node(SPRITE_NODE_NAME), get_node(COLLIDER_NODE_NAME))

func set_target(target_node, PID_Kp = -1, PID_Ki = -1, PID_Kd = -1):
	target = target_node
	if PID_Kp >= 0:
		_PID_Kp = PID_Kp

	if PID_Ki >= 0:
		_PID_Ki = PID_Ki

	if PID_Kd >= 0:
		_PID_Kd = PID_Kd

func set_kill_after_time(val):
	kill_after_time = val
	if val > 0:
		var timer = Timer.new()
		timer.connect("timeout", self, "kill")
		timer.set_one_shot(true)
		timer.set_wait_time(kill_after_time)
		add_child(timer)
		timer.start()

func set_kill_on_collide(val):
	kill_on_collide = val
	if val:
		connect("body_entered", self, "kill")

func set_kill_travel_dist(val):
	kill_travel_dist = val
	if kill_travel_dist > 0:
		_prev_pos = global_position

func set_kill_viewport_exit(val):
	kill_viewport_exit = val
	if val:
		if !_vis_notifier:
			_vis_notifier = VisibilityNotifier2D.new()
			add_child(_vis_notifier)
		_vis_notifier.connect("screen_exited", self, "kill")
	else:
		if _vis_notifier:
			_vis_notifier.disconnect("screen_exited", self, "kill")

func resize_to(ref, resizable):
	var size = ref.get_item_rect().size
	var pos = -size / 2
	resizable.edit_set_rect(Rect2(pos, size))

func kill(arg = null):
	#ensure freeing/signal only done once if multiple kill conditions are set up
	if deleted :
		return

	deleted = true

	emit_signal("bullet_killed", self)
	queue_free()
