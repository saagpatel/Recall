class_name MemoryObject
extends Node3D

## Procedural memory object placed on pedestals.
## Displays a geometric mesh with category color and a fading Label3D.

const SHAPE_COUNT: int = 5
const LABEL_FADE_NEAR: float = 3.0
const LABEL_FADE_FAR: float = 8.0

var object_id: String = ""
var front_text: String = ""
var back_text: String = ""
var category: String = ""
var category_color: Color = Color.CORNFLOWER_BLUE

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var label: Label3D = $Label3D


func setup(id: String, front: String, back: String, cat: String, color: Color) -> void:
	object_id = id
	front_text = front
	back_text = back
	category = cat
	category_color = color

	# Pick mesh shape from hash of front text
	var shape_index: int = hash(front) % SHAPE_COUNT
	if shape_index < 0:
		shape_index += SHAPE_COUNT
	var mesh: Mesh = _create_mesh(shape_index)
	mesh_instance.mesh = mesh

	# Material
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.3
	mesh_instance.material_override = mat

	# Label
	label.text = front
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y


func _process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var distance: float = global_position.distance_to(camera.global_position)
	label.modulate.a = clampf(inverse_lerp(LABEL_FADE_FAR, LABEL_FADE_NEAR, distance), 0.0, 1.0)


func _create_mesh(index: int) -> Mesh:
	match index:
		0:
			var m: SphereMesh = SphereMesh.new()
			m.radius = 0.2
			m.height = 0.4
			return m
		1:
			var m: BoxMesh = BoxMesh.new()
			m.size = Vector3(0.35, 0.35, 0.35)
			return m
		2:
			var m: PrismMesh = PrismMesh.new()
			m.size = Vector3(0.35, 0.4, 0.35)
			return m
		3:
			var m: TorusMesh = TorusMesh.new()
			m.inner_radius = 0.1
			m.outer_radius = 0.2
			return m
		_:
			var m: CylinderMesh = CylinderMesh.new()
			m.top_radius = 0.15
			m.bottom_radius = 0.15
			m.height = 0.4
			return m
