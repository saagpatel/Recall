class_name InteractionManager
extends Node3D

## Detects what the player is looking at via RayCast3D and handles E-key interaction.
## Routes to creation panel (empty pedestal) or review panel (populated pedestal).

signal looking_at_changed(collider: Node)

const CREATION_PANEL_PATH: String = "res://scenes/ui/creation_panel.tscn"
const REVIEW_PANEL_PATH: String = "res://scenes/ui/review_panel.tscn"
const MEMORY_OBJECT_PATH: String = "res://scenes/objects/memory_object.tscn"
const OBJECT_OFFSET: Vector3 = Vector3(0.0, 0.7, 0.0)

@onready var raycast: RayCast3D = $RayCast3D

var _current_collider: Node = null
var _active_panel: CanvasLayer = null
var _creation_scene: PackedScene = null
var _review_scene: PackedScene = null
var _object_scene: PackedScene = null

# Pedestal node path → object ID
var _pedestal_objects: Dictionary = {}
# Pedestal node path → MemoryObject node
var _pedestal_nodes: Dictionary = {}

var crosshair: Crosshair = null


func _ready() -> void:
	_creation_scene = load(CREATION_PANEL_PATH) as PackedScene
	_review_scene = load(REVIEW_PANEL_PATH) as PackedScene
	_object_scene = load(MEMORY_OBJECT_PATH) as PackedScene


func _physics_process(_delta: float) -> void:
	if _active_panel != null:
		return

	if not raycast.is_colliding():
		if _current_collider != null:
			_current_collider = null
			looking_at_changed.emit(null)
			_update_crosshair(false)
		return

	var collider: Object = raycast.get_collider()
	if collider is Node and collider != _current_collider:
		_current_collider = collider as Node
		looking_at_changed.emit(_current_collider)
		var is_pedestal: bool = _current_collider is StaticBody3D and _current_collider.name == "Pedestal"
		_update_crosshair(is_pedestal)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if _active_panel != null:
			return
		if _current_collider != null and _current_collider is StaticBody3D and _current_collider.name == "Pedestal":
			var pedestal_path: String = str(_current_collider.get_path())
			if _pedestal_objects.has(pedestal_path):
				_open_review_panel(pedestal_path)
			else:
				_open_creation_panel(pedestal_path)
			get_viewport().set_input_as_handled()


func _open_creation_panel(pedestal_path: String) -> void:
	if _creation_scene == null:
		push_error("[InteractionManager] Creation panel scene not loaded")
		return

	var panel: CreationPanel = _creation_scene.instantiate() as CreationPanel
	get_tree().current_scene.add_child(panel)
	_active_panel = panel

	var captured_path: String = pedestal_path
	panel.object_created.connect(func(id: String, front: String, back: String, category: String, color: Color) -> void:
		_on_object_created(captured_path, id, front, back, category, color)
	)
	panel.panel_closed.connect(_on_panel_closed)
	panel.open()
	_set_player_input(true)


func _open_review_panel(pedestal_path: String) -> void:
	if _review_scene == null:
		push_error("[InteractionManager] Review panel scene not loaded")
		return

	var object_id: String = _pedestal_objects[pedestal_path] as String
	var data: Dictionary = SRSEngine.get_object(object_id)
	if data.is_empty():
		push_error("[InteractionManager] Object not found in SRSEngine: " + object_id)
		return

	var panel: ReviewPanel = _review_scene.instantiate() as ReviewPanel
	get_tree().current_scene.add_child(panel)
	_active_panel = panel

	panel.review_completed.connect(func(id: String, remembered: bool) -> void:
		SRSEngine.review(id, remembered)
	)
	panel.panel_closed.connect(_on_panel_closed)
	panel.open_for_review(object_id, data["front"] as String, data["back"] as String)
	_set_player_input(true)


func _on_object_created(pedestal_path: String, id: String, front: String, back: String, category: String, color: Color) -> void:
	SRSEngine.create_object(id, front, back, category)

	if _object_scene == null:
		push_error("[InteractionManager] Memory object scene not loaded")
		return

	var obj: MemoryObject = _object_scene.instantiate() as MemoryObject
	var pedestal_node: Node = get_node_or_null(pedestal_path)
	if pedestal_node == null:
		push_error("[InteractionManager] Pedestal node not found: " + pedestal_path)
		obj.queue_free()
		return

	get_tree().current_scene.add_child(obj)
	obj.global_position = (pedestal_node as Node3D).global_position + OBJECT_OFFSET
	obj.setup(id, front, back, category, color)

	_pedestal_objects[pedestal_path] = id
	_pedestal_nodes[pedestal_path] = obj


func _on_panel_closed() -> void:
	if _active_panel != null:
		_active_panel.queue_free()
		_active_panel = null
	_set_player_input(false)


func _set_player_input(disabled: bool) -> void:
	var player: Player = get_tree().current_scene.find_child("Player", true, false) as Player
	if player != null:
		player.input_disabled = disabled


func _update_crosshair(is_interactable: bool) -> void:
	if crosshair != null:
		crosshair.set_interactable(is_interactable)
