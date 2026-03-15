extends Node3D

## Main scene script — registers rooms with DecayManager on startup.


func _ready() -> void:
	# Register all rooms with DecayManager
	var test_room: Node3D = $TestRoom as Node3D
	if test_room != null:
		DecayManager.register_room(test_room)
