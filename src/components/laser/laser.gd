extends Line2D

const BULLET_OWNER_NODE = "/root/main/bullets"

var target
var gun_shot_from
var deleted = false

signal bullet_killed

func _process(delta):
	if target:
		_track_target(delta)
#	else:
#		kill()

func setup(shooting_gun):
	gun_shot_from = shooting_gun

	# choose parent
	var node_parent = gun_shot_from.get_node(BULLET_OWNER_NODE)
	node_parent.add_child(self)

func set_target(target):
	self.target = target

func _track_target(delta):
	set_point_pos(0, gun_shot_from.global_position)
	set_point_pos(1, target.global_position)

	#draw_line(gun_shot_from.global_position, target.global_position, Color("667fff"), 4.0, true)
	#pass

func kill(arg = null):
	#ensure freeing/signal only done once if multiple kill conditions are set up
	if deleted:
		return

	deleted = true

	emit_signal("bullet_killed", self)
	queue_free()