extends MeshInstance3D

var path_to_follow = []
var current_target_index = 0
var speed = 8.0
var is_moving = false
var height_offset = Vector3(0, 0.4, 0)

func start_following(world_path: Array):
	path_to_follow = world_path
	current_target_index = 0
	is_moving = true

func _process(delta):
	if is_moving and current_target_index < path_to_follow.size():
		var target_pos = path_to_follow[current_target_index] + height_offset
		
		var dir = (target_pos - global_position).normalized()
		var dist = global_position.distance_to(target_pos)
		
		if dist < 0.1:
			current_target_index += 1
		else:
			global_position += dir * speed * delta
			if dir.length() > 0.01:
				var look_at_pos = global_position - dir
				look_at(Vector3(look_at_pos.x, global_position.y, look_at_pos.z), Vector3.UP)
	elif is_moving:
		is_moving = false
