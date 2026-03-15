class_name CrosshairRing
extends Control

## Draws a circle outline for the crosshair ring indicator.

const RING_RADIUS: float = 12.0
const RING_WIDTH: float = 2.0
const RING_COLOR: Color = Color.WHITE


func _ready() -> void:
	custom_minimum_size = Vector2(RING_RADIUS * 2.0, RING_RADIUS * 2.0)


func _draw() -> void:
	var center: Vector2 = size / 2.0
	draw_arc(center, RING_RADIUS, 0.0, TAU, 32, RING_COLOR, RING_WIDTH, true)
