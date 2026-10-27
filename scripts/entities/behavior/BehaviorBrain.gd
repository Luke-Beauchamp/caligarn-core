# res://scripts/entities/behavior/BehaviorBrain.gd
class_name BehaviorBrain
extends Node

enum State { IDLE, MOVING_TO_LEASH, EXECUTING_DIRECTIVE, ENGAGED_COMBAT, RETREATING }

@onready var stance_ctrl = $"../StanceController"
@onready var directive_eval = $"../DirectiveEvaluator"
@onready var eval_timer = $"../EvaluationTimer"

var host
var current_state: State = State.IDLE
var active_target_node: Node2D = null
var active_action: Dictionary = {}

func initialize(actor, unit_config: Dictionary) -> void:
	host = actor
	var defaults = unit_config.get("behavior_defaults", {})
	stance_ctrl.initialize(host, defaults.get("locked_stance", "stance_bulwark"))
	directive_eval.initialize(host, defaults.get("default_directives", []))
	
	eval_timer.timeout.connect(_on_evaluation_tick)
	print("[BehaviorBrain] Initialized for: ", host.unit_id, " | Stance: ", stance_ctrl.stance_id)

func _on_evaluation_tick() -> void:
	if host.current_hp / host.max_hp <= stance_ctrl.fallback_threshold:
		_transition_to(State.RETREATING)
		_execute_retreat()
		return

	var best_directive = directive_eval.find_highest_priority_directive()
	if not best_directive.is_empty():
		_transition_to(State.EXECUTING_DIRECTIVE)
		_execute_directive(best_directive)
		return

	_evaluate_stance_positioning()

func _evaluate_stance_positioning() -> void:
	var anchor_pos = stance_ctrl.get_anchor_position()
	var dist_tiles = host.global_position.distance_to(anchor_pos) / 32.0

	if dist_tiles > stance_ctrl.max_leash_tiles:
		_transition_to(State.MOVING_TO_LEASH)
		print("[BehaviorBrain] Outside leash (", snapped(dist_tiles, 0.1), " tiles > ", stance_ctrl.max_leash_tiles, "). Moving to anchor.")
		host.set_destination(anchor_pos)
	elif current_state == State.MOVING_TO_LEASH and dist_tiles <= 1.0:
		_transition_to(State.IDLE)
		print("[BehaviorBrain] Inside anchor boundary. Holding position.")

func _transition_to(new_state: State) -> void:
	if current_state != new_state:
		current_state = new_state
		var state_names = ["IDLE", "MOVING_TO_LEASH", "EXECUTING_DIRECTIVE", "ENGAGED_COMBAT", "RETREATING"]
		print("[BehaviorBrain State Change] -> ", state_names[current_state])

func _execute_directive(directive: Dictionary) -> void:
	active_action = directive.get("action_payload", {})
	var target = directive.get("resolved_target")
	if is_instance_valid(target):
		active_target_node = target
		host.set_destination(target.global_position)

func _execute_retreat() -> void:
	var fallback_pos = stance_ctrl.get_anchor_position()
	host.set_destination(fallback_pos)
