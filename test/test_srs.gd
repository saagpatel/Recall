class_name TestSRS
extends Node

## Unit tests for SRSEngine SM-2 implementation.
## Run this scene to verify SRS logic — check console for PASS/FAIL.

var _pass_count: int = 0
var _fail_count: int = 0


func _ready() -> void:
	print("\n=== SRS Engine Tests ===\n")
	test_create_object()
	test_initial_decay_is_one()
	test_review_remembered_first()
	test_review_remembered_second()
	test_review_remembered_third()
	test_review_forgot_resets()
	test_ease_decreases_on_forget()
	test_ease_increases_on_remember()
	test_ease_never_below_minimum()
	test_get_due_objects()
	print("\n=== Results: %d passed, %d failed ===" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")


func test_create_object() -> void:
	var data: Dictionary = SRSEngine.create_object("test_1", "Hello", "World", "vocab")
	_assert_eq(data["id"], "test_1", "create_object sets id")
	_assert_eq(data["front"], "Hello", "create_object sets front")
	_assert_eq(data["back"], "World", "create_object sets back")
	_assert_eq(data["category"], "vocab", "create_object sets category")
	_assert_eq(data["repetitions"], 0, "create_object starts at 0 reps")
	_assert_true(SRSEngine.has_object("test_1"), "has_object returns true after create")


func test_initial_decay_is_one() -> void:
	SRSEngine.create_object("decay_init", "A", "B", "test")
	var decay: float = SRSEngine.get_decay("decay_init")
	_assert_eq(decay, 1.0, "initial decay is 1.0 (never reviewed)")


func test_review_remembered_first() -> void:
	SRSEngine.create_object("rem_1", "A", "B", "test")
	SRSEngine.review("rem_1", true)
	var data: Dictionary = SRSEngine.get_object("rem_1")
	_assert_eq(data["repetitions"], 1, "first review sets reps to 1")
	_assert_float_eq(data["interval_days"] as float, 1.0, "first correct → 1 day interval")


func test_review_remembered_second() -> void:
	SRSEngine.create_object("rem_2", "A", "B", "test")
	SRSEngine.review("rem_2", true)
	SRSEngine.review("rem_2", true)
	var data: Dictionary = SRSEngine.get_object("rem_2")
	_assert_eq(data["repetitions"], 2, "second review sets reps to 2")
	_assert_float_eq(data["interval_days"] as float, 6.0, "second correct → 6 day interval")


func test_review_remembered_third() -> void:
	SRSEngine.create_object("rem_3", "A", "B", "test")
	SRSEngine.review("rem_3", true)
	SRSEngine.review("rem_3", true)
	SRSEngine.review("rem_3", true)
	var data: Dictionary = SRSEngine.get_object("rem_3")
	_assert_eq(data["repetitions"], 3, "third review sets reps to 3")
	# After 3 correct: ease at time of 3rd calc = 2.7 (bonus applied after), interval = 6.0 * 2.7 = 16.2
	_assert_float_eq(data["interval_days"] as float, 16.2, "third correct → interval * ease")


func test_review_forgot_resets() -> void:
	SRSEngine.create_object("forgot_1", "A", "B", "test")
	SRSEngine.review("forgot_1", true)
	SRSEngine.review("forgot_1", true)
	SRSEngine.review("forgot_1", false)
	var data: Dictionary = SRSEngine.get_object("forgot_1")
	_assert_eq(data["repetitions"], 0, "forgot resets reps to 0")
	_assert_float_eq(data["interval_days"] as float, 1.0, "forgot resets interval to 1 day")


func test_ease_decreases_on_forget() -> void:
	SRSEngine.create_object("ease_dec", "A", "B", "test")
	SRSEngine.review("ease_dec", false)
	var data: Dictionary = SRSEngine.get_object("ease_dec")
	_assert_float_eq(data["ease"] as float, 2.3, "ease decreases by 0.2 on forget")


func test_ease_increases_on_remember() -> void:
	SRSEngine.create_object("ease_inc", "A", "B", "test")
	SRSEngine.review("ease_inc", true)
	var data: Dictionary = SRSEngine.get_object("ease_inc")
	_assert_float_eq(data["ease"] as float, 2.6, "ease increases by 0.1 on remember")


func test_ease_never_below_minimum() -> void:
	SRSEngine.create_object("ease_min", "A", "B", "test")
	# Forget many times to drive ease down
	for i: int in range(20):
		SRSEngine.review("ease_min", false)
	var data: Dictionary = SRSEngine.get_object("ease_min")
	_assert_float_eq(data["ease"] as float, 1.3, "ease never drops below 1.3")


func test_get_due_objects() -> void:
	# All objects created in these tests have next_review_time = now (after review)
	# or next_review_time = creation time (never reviewed), so they should be due
	var due: Array[String] = SRSEngine.get_due_objects()
	_assert_true(due.size() > 0, "get_due_objects returns non-empty for due items")


func _assert_eq(actual: Variant, expected: Variant, description: String) -> void:
	if actual == expected:
		_pass_count += 1
		print("  PASS: ", description)
	else:
		_fail_count += 1
		print("  FAIL: ", description, " — expected ", expected, " got ", actual)


func _assert_float_eq(actual: float, expected: float, description: String) -> void:
	if absf(actual - expected) < 0.001:
		_pass_count += 1
		print("  PASS: ", description)
	else:
		_fail_count += 1
		print("  FAIL: ", description, " — expected ", expected, " got ", actual)


func _assert_true(condition: bool, description: String) -> void:
	if condition:
		_pass_count += 1
		print("  PASS: ", description)
	else:
		_fail_count += 1
		print("  FAIL: ", description)
