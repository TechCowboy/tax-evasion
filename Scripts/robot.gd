extends CharacterBody3D


@export var  walk_speed = 2.0
@export var  run_speed = 3.0

@onready var robot_speech_audio_stream_player_3d: AudioStreamPlayer3D = %RobotSpeechAudioStreamPlayer3D
@onready var turn_movement_timer: Timer 			= %TurnMovementTimer
@onready var navigation_agent_3d: NavigationAgent3D = %NavigationAgent3D
@onready var vision_ray_cast_3d: RayCast3D 			= %VisionRayCast3D
@onready var nav_timer: Timer 						= %NavTimer
@onready var bot_name_sprite_3d: Sprite3D 			= %BotNameSprite3D
@onready var vision_timer: Timer 					= %VisionTimer
@onready var floor_ray_cast_3d: RayCast3D 			= %FloorRayCast3D
@onready var animation_tree: AnimationTree 			= %AnimationTree
@onready var vision_area_3d: Area3D 				= %VisionArea3D
@onready var bot_state_chart: StateChart 			= %BotStateChart



var detected = false
var near_robot = false

var red_colour = Color(1.0, 0.0, 0.0, 0.0)

var anim_walking:float 	= 0.0
var anim_turn:float		= 0.0
var anim_pursue:float	= 0.0
var anim_search:float	= 0.0
var anim_attack:float	= 0.0
var blend_speed:float	= 15.0

var random_position:Vector3 = Vector3(0,0,0)

const MIN_FIELD_OF_VIEW 	= deg_to_rad(92) 
const MAX_FIELD_OF_VIEW 	= deg_to_rad(102) 
const VISION_DISTANCE 		= 5.0
const target_body: 						String = "PlayerBody"

var sentence_index = -1
var word_index = -1
	


#####################################################################
# This routine smooths the poses between two animations
# Making the transitions appear more natural
#####################################################################
			


func _ready() -> void:

	# Set the label over top of Bot to it's name
	
	%BotName.text = Globals.taxes[Globals.robot_index]
	Globals.robot_index += 1
	
	# this movement timer is normally used to
	# smooth the transition of the enemy 
	# while he turns, but here I'm using it to
	# allow the bots to start their movement at a random
	# time
		
	bot_state_chart.set_expression_property("player_seen", false)
	
	
	

		
func _physics_process(_delta: float) -> void:
	#print(velocity)
	pass	

	
	
#####################################################################
# if you've been detected,
# then the robot will say
# various phrases spaced out
# at the end of the speech_timer interval
#####################################################################

	
		
#####################################################################
# for each robot, if the player has 
# been detected, path find him,
# otherwise, turn off the path finding
# Call this (at time of writing) every 1/4 second
#####################################################################
				
func _on_nav_timer_timeout() -> void:

	pass	
	#if detected:
	#	# set our target location to be where the player is
	#	navigation_agent_3d.set_target_position(Globals.player_instance.global_transform.origin)
	#	look_at(Vector3(Globals.player_instance.global_position.x, global_position.y, Globals.player_instance.global_position.z), Vector3.UP)
	#else:
	#	look_at(random_position, Vector3.UP)


	# get the latest path to the player
	#var next_location = navigation_agent_3d.get_next_path_position()
	# we'll move faster towards the player, the farther we are
	#velocity  = (next_location - global_transform.origin).normalized() * walk_speed
	# and we'll turn to look at the player

	#nav_timer.start()


#####################################################################
# send out a raycast and see if it is colliding with
# anything. 
# if it does, return the distance to the object and
# it's name
#####################################################################
func can_see_target() -> bool:
	# Get the sight transform and target position
	var sight_transform := vision_ray_cast_3d.global_transform
	var target_position = Globals.camera_instance.global_position

	# Calculate the forwards and to-target vectors
	var forwards := -sight_transform.basis.z
	var to_target = target_position - sight_transform.origin

	var angle = forwards.angle_to(to_target.normalized())
	var seen = (angle <= MAX_FIELD_OF_VIEW) and (angle >= MIN_FIELD_OF_VIEW)
	if not seen:
		return false

	vision_ray_cast_3d.target_position = vision_ray_cast_3d.to_local(target_position)
	vision_ray_cast_3d.force_raycast_update()
	var object = vision_ray_cast_3d.get_collider() 
	
	if object.name != target_body:
		return false
	
	var collision_point = vision_ray_cast_3d.get_collision_point()
		
	var distance = global_position.distance_to(collision_point)
	
	if distance >= VISION_DISTANCE:
		return false
	
	return true


#####################################################################
# see if the robot is going to walk off an edge	
# or we're going to walk into a wall
# or we're going to walk into another robot
#####################################################################
func is_turn_necessary() -> bool:
	floor_ray_cast_3d.force_raycast_update()
	
	# no floor ahead!
	if not floor_ray_cast_3d.is_colliding():
		return true

	var hit = floor_ray_cast_3d.get_collider()	
		
	#print("is turn necessary-"+name + ": " + hit.name)
	# are we about to walk into a wall or bot?
	if (hit.name.find("Body")>=0) or (hit.name.find("Tree") >=0) or (hit.name.find("Rock") >=0)or (hit.name.find("Tax") >=0):
		#print(name+ ": "+hit.name)
		return true
		
	return false
		


#####################################################################
# this routine checks periodically what the
# robot is seeing.
# if it sees the player:
#   is it close enough to attack, then do so
#   otherwise run towards him
#####################################################################
		
func _on_vision_timer_timeout() -> void:
	
	bot_state_chart.set_expression_property("player_seen", can_see_target())
		

#####################################################################
# A body has entered our immediate area
# can_see_target checks to see if the player is in front of us
#####################################################################
func _on_vision_area_3d_body_entered(body: Node3D) -> void:
	print("Body: "+body.name)
	if body.name == target_body:
		near_robot = true
		# if we see the player
		vision_timer.start()
	else:
		bot_state_chart.send_event("turn_required")

#####################################################################
# the player has moved outside our immediate area
#####################################################################
func _on_vision_area_3d_body_exited(body: Node3D) -> void:
	if body.name == target_body:
		bot_state_chart.set_expression_property("player_seen", false)
	else:
		bot_state_chart.send_event("turn_required")

func _on_hands_area_3d_body_exited(body: Node3D) -> void:
	if body.name == target_body:
		Globals.debug.emit(name + ": hands exited: " + body.name)

#####################################################################
# get the intruder if he's close enough
#####################################################################
func _on_attack_area_3d_body_entered(body: Node3D) -> void:
	# if the player had entered our field of view
	if body.name == target_body:
		bot_state_chart.send_event("player_entered_attack_range")
	else:
		bot_state_chart.send_event("turn_required")

#####################################################################
# go after him if he's too far away to punch
#####################################################################

func _on_attack_area_3d_body_exited(body: Node3D) -> void:
	# if the player has left our attack range
	if body.name == target_body:
		bot_state_chart.send_event("player_exited_attack_range")

#####################################################################
# Allow blending between animation states
#####################################################################
func update_animation():
	animation_tree["parameters/attack/blend_amount"]	= anim_attack
	animation_tree["parameters/pursue/blend_amount"] 	= anim_pursue
	animation_tree["parameters/search/blend_amount"] 	= anim_search
	animation_tree["parameters/turn/blend_amount"] 		= anim_turn
	animation_tree["parameters/walk/blend_amount"] 		= anim_walking

#####################################################################
# Stay still and blend animation to the IDLE state
#####################################################################
func _on_idle_state_processing(delta: float) -> void:
	anim_attack = lerp(anim_attack, 0.0, blend_speed*delta)
	anim_pursue = lerp(anim_pursue, 0.0, blend_speed*delta)
	anim_search = lerp(anim_search, 0.0, blend_speed*delta)
	anim_turn	= lerp(anim_turn, 	0.0, blend_speed*delta)
	anim_walking= lerp(anim_walking,0.0, blend_speed*delta)
			
	update_animation()
	
	velocity.x = 0.0
	velocity.z = 0.0
		
	velocity += get_gravity() * delta
				
	move_and_slide()	


#####################################################################
# start walking  and blend animation to the IDLE state
# if we're about to walk into another robot or off the edge
# of a cliff, then turn around
#####################################################################
func _on_walk_state_processing(delta: float) -> void:
	
	anim_attack = lerp(anim_attack, 0.0, blend_speed*delta)
	anim_pursue = lerp(anim_pursue, 0.0, blend_speed*delta)
	anim_search = lerp(anim_search, 0.0, blend_speed*delta)
	anim_turn	= lerp(anim_turn, 	0.0, blend_speed*delta)
	anim_walking= lerp(anim_walking,1.0, blend_speed*delta)
	
	var current_position = global_transform.origin
	var next_position = navigation_agent_3d.get_next_path_position()
	var move_direction = (next_position - current_position).normalized()
	look_at(Vector3(next_position.x, 0, next_position.z), Vector3.UP)
	
	#var move_direction = -transform.basis.z
	velocity.x = move_direction.x * walk_speed
	velocity.z = move_direction.z * walk_speed
		
	velocity += get_gravity() * delta
	
	update_animation()
				
	move_and_slide()


#####################################################################
# as soon as we go into the turn state, rotate the player
#####################################################################
func _on_turn_state_entered() -> void:
	var turn_amount = randf_range(0.0, PI)
	rotate_y(turn_amount)

#####################################################################
# blend the turn animation from whatever state we were previously in
#####################################################################
func _on_turn_state_processing(delta: float) -> void:
	anim_attack = lerp(anim_attack, 0.0, blend_speed*delta)
	anim_pursue = lerp(anim_pursue, 0.0, blend_speed*delta)
	anim_search = lerp(anim_search, 0.0, blend_speed*delta)
	anim_turn	= lerp(anim_turn, 	1.0, blend_speed*delta)
	anim_walking= lerp(anim_walking,0.0, blend_speed*delta)

	update_animation()
	
	move_and_slide()
	
	
#####################################################################
# Blend the animation to the RUNNING state
#####################################################################
func _on_pursue_state_processing(delta: float) -> void:
	anim_attack = lerp(anim_attack, 0.0, blend_speed*delta)
	anim_pursue = lerp(anim_pursue, 1.0, blend_speed*delta)
	anim_search = lerp(anim_search, 0.0, blend_speed*delta)
	anim_turn	= lerp(anim_turn, 	0.0, blend_speed*delta)
	anim_walking= lerp(anim_walking,0.0, blend_speed*delta)

	update_animation()
	
	var move_direction = -transform.basis.z
	velocity.x = move_direction.x * run_speed
	velocity.z = move_direction.z * run_speed
		
	velocity += get_gravity() * delta

	if navigation_agent_3d.is_target_reachable():
		var _target = navigation_agent_3d.get_next_path_position()
	else:
		bot_state_chart.send_event("Bot_Navigation_Ended")
						
	move_and_slide()	

#####################################################################
# Blend the animation to the ATTACK (punching) state
#####################################################################
func _on_attack_state_processing(delta: float) -> void:
	anim_attack = lerp(anim_attack, 1.0, blend_speed*delta)
	anim_pursue = lerp(anim_pursue, 0.0, blend_speed*delta)
	anim_search = lerp(anim_search, 0.0, blend_speed*delta)
	anim_turn	= lerp(anim_turn, 	0.0, blend_speed*delta)
	anim_walking= lerp(anim_walking,0.0, blend_speed*delta)

	update_animation()
	
	velocity.x = 0.0
	velocity.z = 0.0
	
	velocity += get_gravity() * delta
				
	move_and_slide()	

#####################################################################
# Stop pathfind when we're searching
#####################################################################

func _on_search_state_entered() -> void:
	pass	

#####################################################################
# Blend the animation to the SEARCH state
#####################################################################
func _on_search_state_processing(delta: float) -> void:
	anim_attack = lerp(anim_attack, 0.0, blend_speed*delta)
	anim_pursue = lerp(anim_pursue, 1.0, blend_speed*delta)
	anim_search = lerp(anim_search, 0.0, blend_speed*delta)
	anim_turn	= lerp(anim_turn, 	0.0, blend_speed*delta)
	anim_walking= lerp(anim_walking,0.0, blend_speed*delta)

	update_animation()
	
	velocity.x = 0.0
	velocity.z = 0.0
	
	velocity += get_gravity() * delta
				
	move_and_slide()	

func _on_walk_state_entered() -> void:
	#navigation_agent_3d.target_position = global_position
	pass
	
func _on_idle_state_entered() -> void:
	random_position = Globals.terrain_generation.get_random_position()
	print(random_position)
	navigation_agent_3d.set_target_position(random_position)
	look_at(random_position, Vector3.UP)

#####################################################################
# When an intruder is first detected
# Yell 'Intruder Alert'
# delay saying the next word until
# 'speech timer' period has finished
#####################################################################
func _on_attack_state_entered() -> void:
	if not detected:
		pass
				
	detected = true


func _on_pursue_state_entered() -> void:
	navigation_agent_3d.set_target_position(Globals.player_instance.global_transform.origin)
		


func _on_hands_area_3d_body_entered(_body: Node3D) -> void:
	pass # Replace with function body.


func _on_navigation_agent_3d_target_reached() -> void:
	bot_state_chart.send_event("Bot_Navigation_Ended")
