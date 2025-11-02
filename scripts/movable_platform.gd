class_name MovablePlatform
extends AnimatableBody2D

## How far one "unit" of movement is (in pixels)
@export var move_distance: float = 128.0

## Tracks the '*-1' block
var is_inverted: bool = false

# This is a public function that our Main level script will call
func execute_operation(type: String):
	print("Platform received operation: ", type)
	
	# Handle the 'invert' logic first
	if type == "invert":
		is_inverted = not is_inverted
		print("Platform is now inverted: ", is_inverted)
		return # Invert doesn't move, so we're done

	# Calculate our movement vector
	var move_vector = Vector2.ZERO
	
	match type:
		"plus_two":
			move_vector = Vector2(0, -move_distance) # Move up
		"times":
			move_vector = Vector2(move_distance, -move_distance) # Move diagonally up-right

	# Apply the 'invert' state
	if is_inverted:
		move_vector *= -1
		
	# Calculate our new target position
	var target_position = global_position + move_vector
	
	# Use a Tween to move smoothly
	# A "Tween" animates a property over time
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_position, 1.0).set_trans(Tween.TRANS_SINE)
	# This line says: "Animate 'self' (the platform), change its 'global_position'
	# to 'target_position', take '1.0' second, and use the 'Sine' easing curve."
