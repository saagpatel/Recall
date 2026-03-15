class_name CreationPanel
extends CanvasLayer

## Screen-space UI panel for creating memory objects on pedestals.

signal object_created(id: String, front: String, back: String, category: String, color: Color)
signal panel_closed

const PRESET_COLORS: Array[Color] = [
	Color.INDIAN_RED,
	Color.CORNFLOWER_BLUE,
	Color.MEDIUM_SEA_GREEN,
	Color.ORANGE,
	Color.MEDIUM_PURPLE,
	Color.DARK_CYAN,
]

@onready var panel_ui: PanelContainer = $PanelUI
@onready var front_edit: TextEdit = $PanelUI/MarginContainer/VBoxContainer/FrontEdit
@onready var back_edit: TextEdit = $PanelUI/MarginContainer/VBoxContainer/BackEdit
@onready var category_edit: LineEdit = $PanelUI/MarginContainer/VBoxContainer/CategoryEdit
@onready var color_container: HBoxContainer = $PanelUI/MarginContainer/VBoxContainer/ColorContainer
@onready var create_button: Button = $PanelUI/MarginContainer/VBoxContainer/ButtonContainer/CreateButton
@onready var cancel_button: Button = $PanelUI/MarginContainer/VBoxContainer/ButtonContainer/CancelButton

var _selected_color: Color = Color.CORNFLOWER_BLUE
var _is_active: bool = false


func _ready() -> void:
	panel_ui.visible = false
	_is_active = false
	create_button.pressed.connect(_on_create_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	_setup_color_buttons()


func open() -> void:
	panel_ui.visible = true
	_is_active = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	front_edit.text = ""
	back_edit.text = ""
	category_edit.text = ""
	_selected_color = PRESET_COLORS[1]
	_update_color_selection()
	front_edit.grab_focus()


func close() -> void:
	panel_ui.visible = false
	_is_active = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	panel_closed.emit()


func _setup_color_buttons() -> void:
	for i: int in range(PRESET_COLORS.size()):
		var btn: Button = Button.new()
		var rect: ColorRect = ColorRect.new()
		rect.custom_minimum_size = Vector2(32, 32)
		rect.color = PRESET_COLORS[i]
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(rect)
		btn.custom_minimum_size = Vector2(40, 40)
		var color_index: int = i
		btn.pressed.connect(func() -> void: _on_color_selected(color_index))
		color_container.add_child(btn)


func _update_color_selection() -> void:
	for i: int in range(color_container.get_child_count()):
		var btn: Button = color_container.get_child(i) as Button
		if btn == null:
			continue
		if i < PRESET_COLORS.size() and PRESET_COLORS[i] == _selected_color:
			btn.modulate = Color(1.5, 1.5, 1.5, 1.0)
		else:
			btn.modulate = Color(0.7, 0.7, 0.7, 1.0)


func _on_color_selected(index: int) -> void:
	if index >= 0 and index < PRESET_COLORS.size():
		_selected_color = PRESET_COLORS[index]
		_update_color_selection()


func _on_create_pressed() -> void:
	var front: String = front_edit.text.strip_edges()
	if front.is_empty():
		return
	var back: String = back_edit.text.strip_edges()
	var cat: String = category_edit.text.strip_edges()
	var id: String = str(hash(front + str(Time.get_unix_time_from_system())))
	object_created.emit(id, front, back, cat, _selected_color)
	close()


func _on_cancel_pressed() -> void:
	close()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
