extends CharacterBody3D

const SPEED = 5

@export var player_peer_id:= 1 :
	set(id):
		player_peer_id = id
		$PlayerInput.set_multiplayer_authority(id)
@export var username := ""

@onready var input = $PlayerInput

func _physics_process(delta):
	# Handle movement.
	var direction = (transform.basis * Vector3(input.direction.x, 0, input.direction.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
