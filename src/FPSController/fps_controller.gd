extends CharacterBody3D

# This file has been based on this video https://www.youtube.com/watch?v=ZJr2qUrzEqg

@export var look_sensitivity : float = 0.006
@export var jump_velocity := 6.0
@export var auto_bhop := true
@export var walk_speed := 7.0
@export var sprint_speed := 8.5

# Air movement settings
@export var air_cap := 0.85
@export var air_accel := 800
@export var air_move_speed := 500

const HEADBOB_MOVE_AMOUNT = 0.01
const HEADBOB_FREQUENCY = 2.4
var headbob_time := 0.0

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
	self.velocity.x = wish_dir.x * get_move_speed()
	self.velocity.z = wish_dir.z * get_move_speed()
	
	_headbob_effect(delta)
	
func _handle_air_physics(delta) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	# Based on CSS
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	# Wish speed (if wish_dir > 0 length) capped to air_cap
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	# How much to get to the speed the player wishes (in the new direction)
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity.y = jump_velocity
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	move_and_slide()

func _headbob_effect(delta):
	headbob_time += delta * self.velocity.length()
	%Camera3D.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)
