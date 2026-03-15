class_name InteractionManager
extends Node3D

@onready var raycast: RayCast3D = $RayCast3D

var _current_collider: Object = null


func _physics_process(_delta: float) -> void:
	if not raycast.is_colliding():
		if _current_collider != null:
			_current_collider = null
		return

	var collider: Object = raycast.get_collider()
	if collider != _current_collider:
		_current_collider = collider
		if collider is Node:
			var node: Node = collider as Node
			print("[InteractionManager] Looking at: ", node.name)
