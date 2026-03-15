class_name DecayManagerAutoload
extends Node

## Orchestrates visual decay across rooms and objects.
## Timer-based: updates shaders, lights, and fog every second based on SRS decay state.

const UPDATE_INTERVAL: float = 1.0
const MIN_LIGHT_ENERGY: float = 0.15
const MAX_FOG_DENSITY: float = 0.15
const RESTORATION_TWEEN_DURATION: float = 2.5
const PARTICLE_COUNT: int = 30
const PARTICLE_LIFETIME: float = 1.5
const PARTICLE_COLOR: Color = Color("#FFD700")

var _timer: float = 0.0
var _room_materials: Dictionary = {}    # room_path: String → Array[ShaderMaterial]
var _room_lights: Dictionary = {}       # room_path: String → OmniLight3D
var _room_fog: Dictionary = {}          # room_path: String → FogVolume
var _room_base_light_energy: Dictionary = {} # room_path: String → float
var _object_materials: Dictionary = {}  # object_id: String → ShaderMaterial
var _object_nodes: Dictionary = {}      # object_id: String → MemoryObject

var _room_shader: Shader
var _object_shader: Shader
var _noise_texture: NoiseTexture2D
var _crack_texture: Texture2D


func _ready() -> void:
	_room_shader = load("res://shaders/room_decay.gdshader") as Shader
	_object_shader = load("res://shaders/object_decay.gdshader") as Shader
	_setup_noise_texture()
	_crack_texture = load("res://resources/textures/crack_overlay.png") as Texture2D
	SRSEngine.object_reviewed.connect(_on_object_reviewed)
	print("[DecayManager] Initialized")


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= UPDATE_INTERVAL:
		_timer = 0.0
		_update_all_decay()


## Register a room node for decay management.
## Finds CSG surfaces, lights, and creates fog volume.
func register_room(room: Node3D) -> void:
	var room_path: String = str(room.get_path())
	if _room_materials.has(room_path):
		return

	# Find all CSGBox3D surfaces and apply ShaderMaterial
	var materials: Array[ShaderMaterial] = []
	var csg_nodes: Array[Node] = _find_nodes_of_type(room, "CSGBox3D")
	for node: Node in csg_nodes:
		var csg: CSGBox3D = node as CSGBox3D
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = _room_shader
		mat.set_shader_parameter("base_color", Color(0.5, 0.5, 0.5, 1.0))
		mat.set_shader_parameter("dust_color", Color(0.3, 0.35, 0.4, 1.0))
		mat.set_shader_parameter("decay_amount", 0.0)
		mat.set_shader_parameter("crack_overlay", _crack_texture)
		mat.set_shader_parameter("crack_scale", 2.0)
		csg.material = mat
		materials.append(mat)
	_room_materials[room_path] = materials

	# Find OmniLight3D
	var lights: Array[Node] = _find_nodes_of_type(room, "OmniLight3D")
	if lights.size() > 0:
		var light: OmniLight3D = lights[0] as OmniLight3D
		_room_lights[room_path] = light
		_room_base_light_energy[room_path] = light.light_energy

	# Create FogVolume if not present
	var fog: FogVolume = _find_first_node_of_type(room, "FogVolume") as FogVolume
	if fog == null:
		fog = FogVolume.new()
		fog.name = "DecayFog"
		fog.size = Vector3(6.0, 3.0, 6.0)
		fog.position = Vector3(0.0, 1.5, 0.0)
		var fog_mat: FogMaterial = FogMaterial.new()
		fog_mat.density = 0.0
		fog_mat.albedo = Color(0.4, 0.4, 0.5, 1.0)
		fog.material = fog_mat
		room.add_child(fog)
	_room_fog[room_path] = fog

	print("[DecayManager] Registered room: ", room.name)


## Register a memory object for decay shader management.
## Replaces StandardMaterial3D with ShaderMaterial.
func register_object(object: MemoryObject) -> void:
	var id: String = object.object_id
	if _object_materials.has(id):
		return

	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _object_shader
	mat.set_shader_parameter("albedo_color", object.category_color)
	mat.set_shader_parameter("decay_amount", 0.0)
	mat.set_shader_parameter("noise_texture", _noise_texture)
	mat.set_shader_parameter("emission_energy", 0.3)
	object.mesh_instance.material_override = mat

	_object_materials[id] = mat
	_object_nodes[id] = object
	print("[DecayManager] Registered object: ", id)


func _update_all_decay() -> void:
	# Update each object's shader decay
	var room_decay_totals: Dictionary = {}  # room_path → [total_decay, count]

	for id: String in _object_materials:
		var decay: float = SRSEngine.get_decay(id)
		var mat: ShaderMaterial = _object_materials[id] as ShaderMaterial
		mat.set_shader_parameter("decay_amount", decay)

		# Accumulate for room average
		if _object_nodes.has(id):
			var obj: MemoryObject = _object_nodes[id] as MemoryObject
			var room: Node3D = _find_parent_room(obj)
			if room != null:
				var room_path: String = str(room.get_path())
				if not room_decay_totals.has(room_path):
					room_decay_totals[room_path] = [0.0, 0]
				var totals: Array = room_decay_totals[room_path] as Array
				totals[0] = (totals[0] as float) + decay
				totals[1] = (totals[1] as int) + 1

	# Update room shaders/lights/fog based on average decay
	for room_path: String in _room_materials:
		var avg_decay: float = 0.0
		if room_decay_totals.has(room_path):
			var totals: Array = room_decay_totals[room_path] as Array
			var total: float = totals[0] as float
			var count: int = totals[1] as int
			if count > 0:
				avg_decay = total / float(count)

		# Update room surface materials
		var materials: Array = _room_materials[room_path] as Array
		for mat_variant: Variant in materials:
			var mat: ShaderMaterial = mat_variant as ShaderMaterial
			mat.set_shader_parameter("decay_amount", avg_decay)

		# Update light energy
		if _room_lights.has(room_path):
			var light: OmniLight3D = _room_lights[room_path] as OmniLight3D
			var base_energy: float = _room_base_light_energy[room_path] as float
			light.light_energy = maxf(base_energy * (1.0 - avg_decay * 0.85), MIN_LIGHT_ENERGY)

		# Update fog density
		if _room_fog.has(room_path):
			var fog: FogVolume = _room_fog[room_path] as FogVolume
			if fog.material is FogMaterial:
				var fog_mat: FogMaterial = fog.material as FogMaterial
				fog_mat.density = avg_decay * MAX_FOG_DENSITY


func _on_object_reviewed(id: String, remembered: bool) -> void:
	if remembered:
		_play_restoration(id)


func _play_restoration(id: String) -> void:
	if not _object_materials.has(id):
		return

	var mat: ShaderMaterial = _object_materials[id] as ShaderMaterial
	var current_decay: float = mat.get_shader_parameter("decay_amount") as float

	# Tween decay_amount from current → 0.0
	var tween: Tween = get_tree().create_tween()
	tween.tween_method(
		func(value: float) -> void: mat.set_shader_parameter("decay_amount", value),
		current_decay,
		0.0,
		RESTORATION_TWEEN_DURATION
	)

	# Spawn gold particle burst at object location
	if _object_nodes.has(id):
		var obj: MemoryObject = _object_nodes[id] as MemoryObject
		_spawn_restoration_particles(obj.global_position, current_decay)

	# Trigger immediate room update after short delay
	tween.tween_callback(_update_all_decay)


func _spawn_restoration_particles(pos: Vector3, intensity: float) -> void:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = PARTICLE_COUNT
	particles.lifetime = PARTICLE_LIFETIME
	particles.explosiveness = 0.9
	particles.global_position = pos

	# Process material for particle behavior
	var process_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process_mat.direction = Vector3(0.0, 1.0, 0.0)
	process_mat.spread = 180.0
	process_mat.initial_velocity_min = 1.0 * intensity + 0.5
	process_mat.initial_velocity_max = 2.5 * intensity + 0.5
	process_mat.gravity = Vector3(0.0, -2.0, 0.0)
	process_mat.scale_min = 0.03
	process_mat.scale_max = 0.08
	process_mat.color = PARTICLE_COLOR

	particles.process_material = process_mat

	# Simple mesh for each particle
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.02
	mesh.height = 0.04
	particles.draw_pass_1 = mesh

	get_tree().current_scene.add_child(particles)
	particles.emitting = true

	# Auto-cleanup after lifetime
	get_tree().create_timer(PARTICLE_LIFETIME + 0.5).timeout.connect(particles.queue_free)

	# Audio placeholder — wire AudioStreamPlayer3D, play when real files exist
	var audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	audio.position = pos
	# Pitch varies based on how decayed the object was (higher pitch = more dramatic)
	audio.pitch_scale = 0.8 + intensity * 0.6
	get_tree().current_scene.add_child(audio)
	# No stream assigned — will be silent until audio assets are added in Phase 4
	get_tree().create_timer(2.0).timeout.connect(audio.queue_free)


func _setup_noise_texture() -> void:
	_noise_texture = NoiseTexture2D.new()
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	noise.seed = 42
	_noise_texture.noise = noise
	_noise_texture.width = 256
	_noise_texture.height = 256


func _find_nodes_of_type(root: Node, type_name: String) -> Array[Node]:
	var result: Array[Node] = []
	for child: Node in root.get_children():
		if child.get_class() == type_name:
			result.append(child)
		result.append_array(_find_nodes_of_type(child, type_name))
	return result


func _find_first_node_of_type(root: Node, type_name: String) -> Node:
	for child: Node in root.get_children():
		if child.get_class() == type_name:
			return child
		var found: Node = _find_first_node_of_type(child, type_name)
		if found != null:
			return found
	return null


func _find_parent_room(node: Node) -> Node3D:
	# Walk up the tree to find the room node (direct child of Main/scene root)
	var current: Node = node.get_parent()
	while current != null:
		if current.get_parent() == get_tree().current_scene:
			return current as Node3D
		current = current.get_parent()
	return null
