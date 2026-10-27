# res://scripts/entities/behavior/DirectiveEvaluator.gd
class_name DirectiveEvaluator
extends Node

var host: CrewMember
var active_directives: Array = []

func initialize(actor: CrewMember, directive_ids: Array) -> void:
	host = actor
	active_directives.clear()
	for d_id in directive_ids:
		var d_data = DataManager.get_directive_data(d_id)
		if not d_data.is_empty():
			active_directives.append(d_data)

func find_highest_priority_directive() -> Dictionary:
	for directive in active_directives:
		var cond = directive.get("trigger_condition", {})
		var target = _evaluate_condition(cond)
		if target != null:
			var result = directive.duplicate(true)
			result["resolved_target"] = target
			return result
	return {}

func _evaluate_condition(cond: Dictionary) -> Node2D:
	var target_group = cond.get("target_entity", "")
	var param = cond.get("eval_parameter", "")
	var op = cond.get("comparison_operator", "")
	var threshold = cond.get("threshold_value", 0.0)

	var candidates = get_tree().get_nodes_in_group(target_group)
	if candidates.is_empty():
		return null

	match param:
		"HP_Percentage":
			for c in candidates:
				if "current_hp" in c and "max_hp" in c:
					var pct = float(c.current_hp) / float(c.max_hp)
					if _compare(pct, op, threshold):
						return c
		"Map_Count":
			var count = candidates.size()
			if _compare(float(count), op, threshold):
				return _get_nearest(candidates)
	return null

func _compare(val: float, op: String, threshold: float) -> bool:
	match op:
		"LESS_THAN": return val < threshold
		"GREATER_THAN": return val > threshold
		"EQUALS": return is_equal_approx(val, threshold)
		_: return false

func _get_nearest(nodes: Array) -> Node2D:
	var closest: Node2D = null
	var min_dist = INF
	for n in nodes:
		var dist = host.global_position.distance_squared_to(n.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = n
	return closest
