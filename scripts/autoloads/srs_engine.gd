class_name SRSEngineAutoload
extends Node

## SM-2 spaced repetition engine.
## Manages memory object data, interval scheduling, and decay calculation.

signal object_created(id: String)
signal object_reviewed(id: String, remembered: bool)

const DEFAULT_EASE: float = 2.5
const MIN_EASE: float = 1.3
const EASE_PENALTY: float = 0.2
const EASE_BONUS: float = 0.1
const FIRST_INTERVAL_DAYS: float = 1.0
const SECOND_INTERVAL_DAYS: float = 6.0
const SECONDS_PER_DAY: float = 86400.0

# Dictionary[String, Dictionary] — keyed by object ID
var _objects: Dictionary = {}


func _ready() -> void:
	print("[SRSEngine] Initialized")


func create_object(id: String, front: String, back: String, category: String) -> Dictionary:
	var now: float = Time.get_unix_time_from_system()
	var data: Dictionary = {
		"id": id,
		"front": front,
		"back": back,
		"category": category,
		"ease": DEFAULT_EASE,
		"interval_days": 0.0,
		"repetitions": 0,
		"last_review_time": now,
		"next_review_time": now,
		"created_time": now,
	}
	_objects[id] = data
	object_created.emit(id)
	return data


func review(id: String, remembered: bool) -> void:
	if not _objects.has(id):
		push_error("[SRSEngine] Unknown object ID: " + id)
		return

	var data: Dictionary = _objects[id]
	var now: float = Time.get_unix_time_from_system()
	data["last_review_time"] = now

	if remembered:
		data["repetitions"] = (data["repetitions"] as int) + 1
		var reps: int = data["repetitions"] as int
		if reps == 1:
			data["interval_days"] = FIRST_INTERVAL_DAYS
		elif reps == 2:
			data["interval_days"] = SECOND_INTERVAL_DAYS
		else:
			data["interval_days"] = (data["interval_days"] as float) * (data["ease"] as float)
		data["ease"] = maxf((data["ease"] as float) + EASE_BONUS, MIN_EASE)
	else:
		data["repetitions"] = 0
		data["interval_days"] = FIRST_INTERVAL_DAYS
		data["ease"] = maxf((data["ease"] as float) - EASE_PENALTY, MIN_EASE)

	data["next_review_time"] = now + (data["interval_days"] as float) * SECONDS_PER_DAY
	object_reviewed.emit(id, remembered)


func get_decay(id: String) -> float:
	if not _objects.has(id):
		return 0.0

	var data: Dictionary = _objects[id]
	var interval_days: float = data["interval_days"] as float
	if interval_days <= 0.0:
		# Never reviewed — fully due
		return 1.0

	var now: float = Time.get_unix_time_from_system()
	var elapsed: float = now - (data["last_review_time"] as float)
	var interval_seconds: float = interval_days * SECONDS_PER_DAY
	var progress: float = elapsed / interval_seconds
	return clampf(progress, 0.0, 1.0)


func get_due_objects() -> Array[String]:
	var due: Array[String] = []
	var now: float = Time.get_unix_time_from_system()
	for id: String in _objects:
		var data: Dictionary = _objects[id]
		if now >= (data["next_review_time"] as float):
			due.append(id)
	return due


func get_object(id: String) -> Dictionary:
	if not _objects.has(id):
		return {}
	return _objects[id]


func get_all_objects() -> Dictionary:
	return _objects


func has_object(id: String) -> bool:
	return _objects.has(id)


func get_object_count() -> int:
	return _objects.size()
