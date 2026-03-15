class_name PanelPrototype
extends CanvasLayer

## Screen-space UI panel for interacting with pedestals.
## CanvasLayer fallback — SubViewport 3D panels had text input focus issues.

signal panel_opened
signal panel_closed

@onready var panel_ui: PanelContainer = $PanelUI
@onready var text_edit: TextEdit = $PanelUI/MarginContainer/VBoxContainer/TextEdit
@onready var close_button: Button = $PanelUI/MarginContainer/VBoxContainer/CloseButton

var _is_active: bool = false


func _ready() -> void:
	panel_ui.visible = false
	_is_active = false
	close_button.pressed.connect(_on_close_pressed)


func open() -> void:
	panel_ui.visible = true
	_is_active = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	text_edit.text = ""
	text_edit.grab_focus()
	panel_opened.emit()


func close() -> void:
	panel_ui.visible = false
	_is_active = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	panel_closed.emit()


func is_active() -> bool:
	return _is_active


func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_close_pressed() -> void:
	close()
