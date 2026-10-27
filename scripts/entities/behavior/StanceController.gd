# res://scripts/entities/behavior/StanceController.gd
class_name StanceController
extends Node

var host: Node2D
var stance_id: String
var max_leash_tiles: float = 3.5
var fallback_threshold: float = 0.15
var anchor_type: String = ""

func initialize(actor, initial_stance_id: String) -> void:
	host = actor
	set_stance(initial_stance_id)

func set_stance(id: String) -> void:
	stance_id = id
	var stance_db = DataManager.get_stance_data(stance_id)
	if stance_db.is_empty():
		return

	max_leash_tiles = stance_db.get("max_leash_distance_tiles", 4.0)
	fallback_threshold = stance_db.get("fallback_threshold_hp", 0.20)
	anchor_type = stance_db.get("leash_anchor_target", "")

func get_anchor_position() -> Vector2:
	match anchor_type:
		"Faevalcade_Ramp_Or_Highest_Tier_Wall":
			var ramp = get_tree().get_first_node_in_group("Faevalcade_Ramp")
			if ramp:
				return ramp.global_position
			var wall = _get_nearest_wall()
			return wall.global_position if wall else host.global_position

		"Dynamic_Loose_Resource_Clusters":
			var nearest_drop = _get_nearest_resource_drop()
			return nearest_drop.global_position if nearest_drop else host.global_position

		_:
			return host.global_position

func _get_nearest_wall() -> Node2D:
	var walls = get_tree().get_nodes_in_group("Structure_Wall")
	return _find_closest(walls)

func _get_nearest_resource_drop() -> Node2D:
	var drops = get_tree().get_nodes_in_group("Ground_Drop_Resource")
	return _find_closest(drops)

func _find_closest(nodes: Array) -> Node2D:
	var closest: Node2D = null
	var min_dist = INF
	for n in nodes:
		if not is_instance_valid(n):
			continue
		var dist = host.global_position.distance_squared_to(n.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = n
	return closest
