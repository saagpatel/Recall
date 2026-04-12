extends Node3D

## Main scene script — initializes palace and registers rooms with DecayManager.


func _ready() -> void:
	# Initialize atrium at grid origin
	var atrium_id: String = PalaceManager.initialize_atrium()
	if atrium_id == "":
		push_error("[Main] Failed to initialize atrium")
		return

	# Register atrium with DecayManager
	var atrium_data: Dictionary = PalaceManager.get_room_at(Vector2i.ZERO)
	if not atrium_data.is_empty():
		DecayManager.register_room(atrium_data["instance"] as Node3D)

	# Place demo rooms for testing (3 rooms in L-shape around atrium)
	_place_demo_room("study", "Study Hall", Vector2i(1, 0))
	_place_demo_room("gallery", "Art Gallery", Vector2i(0, 1))
	_place_demo_room("workshop", "Workshop", Vector2i(1, 1))

	# Connect to PalaceManager signals for future room registrations
	PalaceManager.room_placed.connect(_on_room_placed)


func _place_demo_room(template: String, room_name: String, grid_pos: Vector2i) -> void:
	var room_id: String = PalaceManager.place_room(template, room_name, grid_pos)
	if room_id == "":
		push_error("[Main] Failed to place " + template + " at " + str(grid_pos))
		return
	var room_data: Dictionary = PalaceManager.get_room_at(grid_pos)
	if not room_data.is_empty():
		DecayManager.register_room(room_data["instance"] as Node3D)


func _on_room_placed(room_id: String, grid_pos: Vector2i) -> void:
	var room_data: Dictionary = PalaceManager.get_room_at(grid_pos)
	if not room_data.is_empty():
		DecayManager.register_room(room_data["instance"] as Node3D)
