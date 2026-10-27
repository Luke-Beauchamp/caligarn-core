extends Node

# Caligarn Central Data Tables
var blueprints: Dictionary = {}
var crew_units: Dictionary = {}
var behavior_codex: Dictionary = {}
var site_encounters: Dictionary = {}

func _ready() -> void:
	load_all_databases()

func load_all_databases() -> void:
	blueprints = load_json_indexed("res://data/db_blueprints.json", "blueprint_id")
	crew_units = load_json_indexed("res://data/db_crew_units.json", "unit_id")
	site_encounters = load_json_indexed("res://data/db_site_encounters.json", "site_id")
	behavior_codex = load_raw_json("res://data/db_behavior_codex.json")
	
	print("--- CALIGARN DATA LOAD COMPLETE ---")
	print("Blueprints Loaded: ", blueprints.keys())
	print("Crew Units Loaded: ", crew_units.keys())

func load_json_indexed(file_path: String, primary_key: String) -> Dictionary:
	var raw_data = load_raw_json(file_path)
	var indexed_dict: Dictionary = {}
	if raw_data is Array:
		for item in raw_data:
			if item.has(primary_key):
				indexed_dict[item[primary_key]] = item
	return indexed_dict

func load_raw_json(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		push_error("Failed to find file at: " + file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		return json.data
	else:
		push_error("JSON Parse Error in " + file_path + " at line " + str(json.get_error_line()))
		return {}
# Add these to res://scripts/DataManager.gd:

func get_crew_unit(id: String) -> Dictionary:
	# Check if crew data is stored under crew_units or a similar variable
	var source = get("crew_units")
	if source == null:
		source = get("db_crew_units")
	
	if source is Array:
		for unit in source:
			if unit.get("unit_id") == id:
				return unit
	elif source is Dictionary:
		return source.get(id, {})

	return {}

func get_stance_data(id: String) -> Dictionary:
	var codex: Dictionary = {}
	var source = get("behavior_codex")
	if source == null:
		source = get("db_behavior_codex")
	if source is Dictionary:
		codex = source

	var stances: Array = codex.get("stances", [])
	for s in stances:
		if s.get("stance_id") == id:
			return s
	return {}

func get_directive_data(id: String) -> Dictionary:
	var codex: Dictionary = {}
	var source = get("behavior_codex")
	if source == null:
		source = get("db_behavior_codex")
	if source is Dictionary:
		codex = source

	var directives: Array = codex.get("directives", [])
	for d in directives:
		if d.get("directive_id") == id:
			return d
	return {}
