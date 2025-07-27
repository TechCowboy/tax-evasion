class_name TerrainGeneration
extends Node

var mesh : MeshInstance3D
var size_depth : int = 100
var size_width : int = 100
var mesh_resolution : int = 2
@export var noise : FastNoiseLite
@export var max_height = 70
@export var elevation_curve : Curve
@export var use_falloff : bool = true
@export var water_level : float = 0.1

var falloff_image : Image

@onready var rng = RandomNumberGenerator.new()
var spawnable_objects: Array[SpawnableObject]
@onready var water: MeshInstance3D = get_node("water")
@onready var nav_region: NavigationRegion3D = get_node("NavigationRegion3D")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for i in get_children():
		if i is SpawnableObject:
			spawnable_objects.append(i)
			
	noise.seed = randi()
	rng.seed = noise.seed
	
	var falloff_texture = preload("res://Procedural Generation/Textures/TerrainFalloff.png")
	falloff_image = falloff_texture.get_image()
	
	generate()
	
	nav_region.bake_navigation_mesh()
	
	await nav_region.bake_finished
	
	# spawn in AI


func generate() -> void:
	var plane_mesh = PlaneMesh.new()
	
	plane_mesh.size = Vector2(size_width, size_depth)
	plane_mesh.subdivide_depth = size_depth * mesh_resolution
	plane_mesh.subdivide_width = size_width * mesh_resolution
	plane_mesh.material = preload("res://Procedural Generation/Materials/TerrainMaterial.tres")
	
	var surface = SurfaceTool.new()
	var data = MeshDataTool.new()
	surface.create_from(plane_mesh, 0)
	
	var array_plane = surface.commit()
	data.create_from_surface(array_plane, 0)
	
	for i in range(data.get_vertex_count()):
		var vertex = data.get_vertex(i)
		var y = get_noise_y(vertex.x, vertex.z)
		vertex.y = y
		data.set_vertex(i, vertex)
		
	array_plane.clear_surfaces()
	data.commit_to_surface(array_plane)
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.create_from(array_plane, 0)
	surface.generate_normals()	
	mesh = MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.create_trimesh_collision()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.add_to_group("NavSource")
	add_child(mesh)
	
	water.position.y = water_level * max_height
	
	for i in spawnable_objects:
		spawn_objects(i)
	

func get_noise_y(x, z) -> float:
	var value = noise.get_noise_2d(x,z)
	
	var x_percent = (x + (size_width / 2.0)) / size_width
	var z_percent = (z + (size_depth / 2.0)) / size_depth
	
	var remapped_value = (value + 1) / 2
	var adjusted_value = elevation_curve.sample(remapped_value)
	
	var x_pixel = int(x_percent * (falloff_image.get_width()-1))
	var y_pixel = int(z_percent * (falloff_image.get_height()-1))
		
	
	var falloff = falloff_image.get_pixel(x_pixel, y_pixel).r
	
	if not use_falloff:
		falloff = 1
		
	return adjusted_value * max_height * falloff
	
func get_random_position() -> Vector3:
	var x = rng.randf_range(-size_width / 2.0, size_width / 2.0)
	var z = rng.randf_range(-size_depth / 2.0, size_depth / 2.0)
	var y = get_noise_y(x,z)
	return Vector3(x,y,z)
	
func spawn_objects(spawnable: SpawnableObject):
	for i in range(spawnable.spawn_count):
		var obj = spawnable.scenes_to_spawn[rng.randi() % spawnable.scenes_to_spawn.size()].instantiate()
		obj.add_to_group("NavSource")
		add_child(obj)
		var random_pos = get_random_position()
		
		while random_pos.y <= water_level * max_height:
			random_pos = get_random_position()
			
		obj.position = random_pos
		obj.scale = Vector3.ONE * rng.randf_range(spawnable.min_scale, spawnable.max_scale)
		obj.rotation_degrees.y = rng.randf_range(0, 350)
		
		
	
