extends CharacterBody3D

@export var look_sensitivity : float = 0.006
@export var jump_velocity := 6.0
@export var auto_bhop := true
@export var walk_speed := 7.0
@export var sprint_speed := 8.5

var wish_dir := Vector3.ZERO

func get_move_speed() -> float:
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed

func _ready():
	for child in %WorldModel.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(2, true)
	
func _unhandled_input(event):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * look_sensitivity)
			%Head/Camera3D.rotate_x(-event.relative.y * look_sensitivity)
			%Head/Camera3D.rotation.x = clamp(%Head/Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _process(delta):
	pass

func _handle_ground_physics(delta) -> void:
	self.velocity.x = wish_dir.x * walk_speed
	self.velocity.z = wish_dir.z * walk_speed
	
func _handle_air_physics(delta) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	print(wish_dir)
	print(is_on_floor())
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			self.velocity.y = jump_velocity
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	move_and_slide()
