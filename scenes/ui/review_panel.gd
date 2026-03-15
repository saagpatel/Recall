class_name ReviewPanel
extends CanvasLayer

## Screen-space UI panel for reviewing memory objects.
## Shows front text, reveals back text, then lets player grade recall.

signal review_completed(id: String, remembered: bool)
signal panel_closed

@onready var panel_ui: PanelContainer = $PanelUI
@onready var front_label: Label = $PanelUI/MarginContainer/VBoxContainer/FrontLabel
@onready var back_label: Label = $PanelUI/MarginContainer/VBoxContainer/BackLabel
@onready var reveal_button: Button = $PanelUI/MarginContainer/VBoxContainer/RevealButton
@onready var grade_container: HBoxContainer = $PanelUI/MarginContainer/VBoxContainer/GradeContainer
@onready var remembered_button: Button = $PanelUI/MarginContainer/VBoxContainer/GradeContainer/RememberedButton
@onready var forgot_button: Button = $PanelUI/MarginContainer/VBoxContainer/GradeContainer/ForgotButton

var _object_id: String = ""
var _revealed: bool = false
var _is_active: bool = false


func _ready() -> void:
	panel_ui.visible = false
	_is_active = false
	reveal_button.pressed.connect(_reveal)
	remembered_button.pressed.connect(_on_remembered)
	forgot_button.pressed.connect(_on_forgot)


func open_for_review(id: String, front: String, back: String) -> void:
	_object_id = id
	_revealed = false
	_is_active = true
	panel_ui.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	front_label.text = front
	back_label.text = back
	back_label.visible = false
	reveal_button.visible = true
	grade_container.visible = false
	reveal_button.grab_focus()


func close() -> void:
	panel_ui.visible = false
	_is_active = false
	_revealed = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	panel_closed.emit()


func _reveal() -> void:
	_revealed = true
	back_label.visible = true
	reveal_button.visible = false
	grade_container.visible = true
	remembered_button.grab_focus()


func _on_remembered() -> void:
	review_completed.emit(_object_id, true)
	close()


func _on_forgot() -> void:
	review_completed.emit(_object_id, false)
	close()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var key_event: InputEventKey = event as InputEventKey
		if not _revealed:
			if key_event.keycode == KEY_E or key_event.keycode == KEY_SPACE:
				_reveal()
				get_viewport().set_input_as_handled()
		else:
			if key_event.keycode == KEY_1:
				_on_remembered()
				get_viewport().set_input_as_handled()
			elif key_event.keycode == KEY_2:
				_on_forgot()
				get_viewport().set_input_as_handled()
