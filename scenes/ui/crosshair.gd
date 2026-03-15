class_name Crosshair
extends CenterContainer

## HUD crosshair that switches between dot (default) and ring (interactable target).

@onready var dot: ColorRect = $Dot
@onready var ring: Control = $Ring

var _is_interactable: bool = false


func _ready() -> void:
	set_interactable(false)


func set_interactable(is_interactable: bool) -> void:
	_is_interactable = is_interactable
	dot.visible = not is_interactable
	ring.visible = is_interactable
