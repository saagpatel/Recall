class_name InteractionManager
extends Node3D

## Detects what the player is looking at via RayCast3D and handles E-key interaction.
## Opens screen-space CanvasLayer panels for pedestal interaction.

signal looking_at_changed(collider: Node)

const PANEL_SCENE_PATH: String = "res://scenes/ui/panel_prototype.tscn"

@onready var raycast: RayCast3D = $RayCast3D

var _current_collider: Node = null
var _active_panel: PanelPrototype = null
var _panel_scene: PackedScene = null


func _ready() -> void:
	_panel_scene = load(PANEL_SCENE_PATH) as PackedScene


func _physics_process(_delta: float) -> void:
	if _active_panel != null:
		return

	if not raycast.is_colliding():
		if _current_collider != null:
			_current_collider = null
			looking_at_changed.emit(null)
		return

	var collider: Object = raycast.get_collider()
	if collider is Node and collider != _current_collider:
		_current_collider = collider as Node
		print("[InteractionManager] Looking at: ", _current_collider.name)
		looking_at_changed.emit(_current_collider)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if _active_panel != null:
			return
		if _current_collider != null and _current_collider.name == "Pedestal":
			_open_panel()
			get_viewport().set_input_as_handled()


func _open_panel() -> void:
	if _panel_scene == null:
		push_error("[InteractionManager] Panel scene not loaded")
		return

	_active_panel = _panel_scene.instantiate() as PanelPrototype
	get_tree().current_scene.add_child(_active_panel)
	_active_panel.panel_closed.connect(_on_panel_closed)
	_active_panel.open()

	var player: Player = get_tree().current_scene.find_child("Player", true, false) as Player
	if player != null:
		player.input_disabled = true


func _on_panel_closed() -> void:
	if _active_panel != null:
		_active_panel.queue_free()
		_active_panel = null

	var player: Player = get_tree().current_scene.find_child("Player", true, false) as Player
	if player != null:
		player.input_disabled = false
