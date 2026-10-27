# res://scripts/entities/CrewMember.gd
class_name CrewMember
extends CharacterBody2D

signal health_changed(current: float, max: float)
signal stress_changed(current: float)

@export var unit_id: String = "crew_lead_kaelen"

@onready var brain = $BehaviorBrain
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

var unit_data: Dictionary = {}
var max_hp: float = 100.0
var current_hp: float = 100.0
var move_speed_px: float = 64.0 # (tiles_per_sec * 32.0)
var current_stress: float = 0.0

var nav_path: PackedVector2Array = PackedVector2Array()
var nav_index: int = 0
var grid_manager: Node2D

func _ready() -> void:
	grid_manager = get_tree().get_first_node_in_group("GridManager")
	_load_unit_manifest()

func _load_unit_manifest() -> void:
	if DataManager.has_method("get_crew_unit"):
		unit_data = DataManager.get_crew_unit(unit_id)

	if unit_data.is_empty():
		push_error("Failed to load unit config for: %s" % unit_id)
		return

	var stats: Dictionary = unit_data.get("base_stats", {})
	max_hp = stats.get("max_health", 650.0)
	current_hp = max_hp
	move_speed_px = stats.get("move_speed_tiles_per_sec", 1.8) * 32.0

	brain.initialize(self, unit_data)
	
func _physics_process(delta: float) -> void:
	if nav_path.is_empty() or nav_index >= nav_path.size():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target_pos = nav_path[nav_index]
	var dist = global_position.distance_to(target_pos)

	if dist < 2.0:
		nav_index += 1
		if nav_index >= nav_path.size():
			nav_path.clear()
			velocity = Vector2.ZERO
			move_and_slide()
			return
		target_pos = nav_path[nav_index]

	var move_dir = (target_pos - global_position).normalized()
	velocity = move_dir * move_speed_px
	move_and_slide()

	# Snap facing direction
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func set_destination(target_world_pos: Vector2) -> void:
	if not grid_manager:
		grid_manager = get_tree().get_first_node_in_group("GridManager")
	if not grid_manager:
		return

	nav_path = grid_manager.get_tile_path(global_position, target_world_pos)
	nav_index = 0

func take_damage(amount: float) -> void:
	current_hp = max(0.0, current_hp - amount)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		_on_death()

func _on_death() -> void:
	set_physics_process(false)
	brain.set_process(false)
	queue_free()
