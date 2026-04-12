class_name PalaceManagerAutoload
extends Node

# Spacing and geometry constants
const GRID_SPACING: float = 14.0
const ROOM_SIZE: float = 8.0
const ROOM_HEIGHT: float = 3.0
const HALLWAY_LENGTH: float = 6.0
const HALLWAY_WIDTH: float = 2.0
const HALLWAY_HEIGHT: float = 3.0

const TEMPLATES: Dictionary = {
	"atrium": "res://scenes/rooms/atrium.tscn",
	"study": "res://scenes/rooms/study.tscn",
	"gallery": "res://scenes/rooms/gallery.tscn",
	"workshop": "res://scenes/rooms/workshop.tscn",
	"garden": "res://scenes/rooms/garden.tscn",
	"vault": "res://scenes/rooms/vault.tscn",
}
const HALLWAY_PATH: String = "res://scenes/hallway/hallway.tscn"

# State
var _grid: Dictionary = {}            # Vector2i → room_id (String)
var _rooms: Dictionary = {}           # room_id (String) → Dictionary
var _hallways: Dictionary = {}        # connection_key (String) → Node3D
var _next_id: int = 0

# Loaded packed scenes — lazy-loaded on first use
var _loaded_templates: Dictionary = {} # String → PackedScene
var _hallway_scene: PackedScene = null

signal room_placed(room_id: String, grid_pos: Vector2i)
signal room_removed(room_id: String)


func _ready() -> void:
	_hallway_scene = load(HALLWAY_PATH) as PackedScene
	print("[PalaceManager] Initialized")


# ── Public API ──────────────────────────────────────────────────────────────

## Place the atrium at grid origin (0,0). Called once by main.gd on startup.
func initialize_atrium() -> String:
	return place_room("atrium", "Atrium", Vector2i.ZERO)


## Place a room of the given template at grid_pos.
## Returns the new room_id on success, "" on failure.
func place_room(template: String, name: String, grid_pos: Vector2i) -> String:
	# Validate template exists
	if not TEMPLATES.has(template):
		push_error("[PalaceManager] Unknown template: " + template)
		return ""

	# Validate cell is unoccupied
	if _grid.has(grid_pos):
		push_error("[PalaceManager] Cell already occupied: " + str(grid_pos))
		return ""

	# Validate adjacency — skip for first room (atrium)
	if _grid.size() > 0 and not _is_adjacent_to_existing(grid_pos):
		push_error("[PalaceManager] " + str(grid_pos) + " is not adjacent to any existing room")
		return ""

	# Generate ID
	var room_id: String = "room_" + str(_next_id)
	_next_id += 1

	# Load and instance scene
	var packed: PackedScene = _load_template(template)
	if packed == null:
		push_error("[PalaceManager] Failed to load template: " + TEMPLATES[template])
		return ""

	var instance: Node3D = packed.instantiate() as Node3D
	var world_pos: Vector3 = Vector3(grid_pos.x * GRID_SPACING, 0.0, grid_pos.y * GRID_SPACING)
	instance.position = world_pos
	get_tree().current_scene.add_child(instance)

	# Store data
	var room_data: Dictionary = {
		"id": room_id,
		"template": template,
		"name": name,
		"grid_pos": grid_pos,
		"instance": instance,
	}
	_grid[grid_pos] = room_id
	_rooms[room_id] = room_data

	# Connect hallways to neighbours
	_connect_hallways(grid_pos)

	room_placed.emit(room_id, grid_pos)
	return room_id


## Remove a room by ID. The atrium (origin) cannot be removed.
func remove_room(room_id: String) -> void:
	if not _rooms.has(room_id):
		push_error("[PalaceManager] Unknown room_id: " + room_id)
		return

	var room_data: Dictionary = _rooms[room_id] as Dictionary
	var grid_pos: Vector2i = room_data["grid_pos"] as Vector2i

	if grid_pos == Vector2i.ZERO:
		push_error("[PalaceManager] Cannot remove the atrium")
		return

	# Remove all hallways touching this room
	var directions: Array[String] = ["North", "South", "East", "West"]
	var offsets: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
	for i: int in range(4):
		var neighbour: Vector2i = grid_pos + offsets[i]
		if _grid.has(neighbour):
			var key: String = _get_connection_key(grid_pos, neighbour)
			if _hallways.has(key):
				_remove_hallway(key)

	# Free the room instance
	var instance: Node3D = room_data["instance"] as Node3D
	instance.queue_free()

	_grid.erase(grid_pos)
	_rooms.erase(room_id)

	room_removed.emit(room_id)


## Return array of empty adjacent cells (N/S/E/W) around grid_pos.
func get_adjacent_positions(grid_pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
	for offset: Vector2i in offsets:
		var candidate: Vector2i = grid_pos + offset
		if not _grid.has(candidate):
			result.append(candidate)
	return result


## Return room data dict for grid_pos, or empty dict if unoccupied.
func get_room_at(grid_pos: Vector2i) -> Dictionary:
	if not _grid.has(grid_pos):
		return {}
	var room_id: String = _grid[grid_pos] as String
	return _rooms[room_id] as Dictionary


## Return the room_id at grid_pos, or "" if empty.
func get_room_id_at(grid_pos: Vector2i) -> String:
	if not _grid.has(grid_pos):
		return ""
	return _grid[grid_pos] as String


## Return the full rooms dictionary.
func get_all_rooms() -> Dictionary:
	return _rooms


## Return the grid dictionary.
func get_grid() -> Dictionary:
	return _grid


# ── Internal helpers ────────────────────────────────────────────────────────

func _is_adjacent_to_existing(grid_pos: Vector2i) -> bool:
	var offsets: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
	for offset: Vector2i in offsets:
		if _grid.has(grid_pos + offset):
			return true
	return false


func _load_template(template: String) -> PackedScene:
	if _loaded_templates.has(template):
		return _loaded_templates[template] as PackedScene
	var path: String = TEMPLATES[template] as String
	var packed: PackedScene = load(path) as PackedScene
	if packed != null:
		_loaded_templates[template] = packed
	return packed


## Spawn hallways between grid_pos and every occupied cardinal neighbour that
## does not already have a hallway connecting them.
func _connect_hallways(grid_pos: Vector2i) -> void:
	var offsets: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]

	for offset: Vector2i in offsets:
		var neighbour: Vector2i = grid_pos + offset
		if not _grid.has(neighbour):
			continue

		var key: String = _get_connection_key(grid_pos, neighbour)
		if _hallways.has(key):
			continue

		if _hallway_scene == null:
			push_error("[PalaceManager] Hallway scene not loaded")
			continue

		# Compute world-space midpoint
		var pos_a: Vector3 = Vector3(grid_pos.x * GRID_SPACING, 0.0, grid_pos.y * GRID_SPACING)
		var pos_b: Vector3 = Vector3(neighbour.x * GRID_SPACING, 0.0, neighbour.y * GRID_SPACING)
		var midpoint: Vector3 = (pos_a + pos_b) * 0.5

		# Instance and position hallway
		var hallway: Node3D = _hallway_scene.instantiate() as Node3D
		hallway.position = midpoint

		# Hallway scene is oriented along the X axis by default.
		# For a north-south connection (same X, different Y) we rotate 90° around Y.
		if grid_pos.x == neighbour.x:
			hallway.rotation.y = PI / 2.0

		get_tree().current_scene.add_child(hallway)
		_hallways[key] = hallway

		# Remove door blockers on both rooms so players can walk through
		var room_a_id: String = _grid[grid_pos] as String
		var room_b_id: String = _grid[neighbour] as String
		var room_a_instance: Node3D = (_rooms[room_a_id] as Dictionary)["instance"] as Node3D
		var room_b_instance: Node3D = (_rooms[room_b_id] as Dictionary)["instance"] as Node3D

		var dir_a_to_b: String = _get_direction_between(grid_pos, neighbour)
		var dir_b_to_a: String = _get_opposite_direction(dir_a_to_b)

		_remove_door_blocker(room_a_instance, dir_a_to_b)
		_remove_door_blocker(room_b_instance, dir_b_to_a)


func _remove_hallway(connection_key: String) -> void:
	if not _hallways.has(connection_key):
		return
	var hallway: Node3D = _hallways[connection_key] as Node3D
	hallway.queue_free()
	_hallways.erase(connection_key)


func _remove_door_blocker(room_instance: Node3D, direction: String) -> void:
	var blocker_name: String = "DoorBlocker" + direction
	var blocker: Node = room_instance.find_child(blocker_name, true, false)
	if blocker != null:
		blocker.queue_free()


## Return a canonical connection key sorted by (x, then y) so that
## _get_connection_key(a, b) == _get_connection_key(b, a).
func _get_connection_key(pos_a: Vector2i, pos_b: Vector2i) -> String:
	var first: Vector2i
	var second: Vector2i
	if pos_a.x < pos_b.x or (pos_a.x == pos_b.x and pos_a.y < pos_b.y):
		first = pos_a
		second = pos_b
	else:
		first = pos_b
		second = pos_a
	return str(first.x) + "," + str(first.y) + ">" + str(second.x) + "," + str(second.y)


## Return cardinal direction from from_pos to to_pos.
## Grid Y increases southward (positive Z in 3D).
func _get_direction_between(from_pos: Vector2i, to_pos: Vector2i) -> String:
	if to_pos.y < from_pos.y:
		return "North"
	elif to_pos.y > from_pos.y:
		return "South"
	elif to_pos.x > from_pos.x:
		return "East"
	else:
		return "West"


func _get_opposite_direction(direction: String) -> String:
	match direction:
		"North":
			return "South"
		"South":
			return "North"
		"East":
			return "West"
		"West":
			return "East"
	push_error("[PalaceManager] Unknown direction: " + direction)
	return ""
