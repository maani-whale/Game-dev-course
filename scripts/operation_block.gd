class_name OperationBlock
extends Area2D

## This is the "channel" the block will shout on when hit.
signal operation_activated(operation_type: String)

## We can set this in the Godot editor for each block!
## (e.g., "plus_two", "times", "invert")
@export var operation_type: String = "plus_two"

@onready var _label: Label = $Label
@onready var _cooldown_timer: Timer = $CooldownTimer

func _ready():
	# Set the label text based on our exported variable
	if _label:
		## NEW: Use a match statement to set a friendly display text
		match operation_type:
			"plus_two":
				_label.text = "+2"
			"times":
				_label.text = "x"  # As you requested!
			"invert":
				_label.text = "-1"
			_:
				# As a fallback, just show the operation type
				_label.text = operation_type

func _on_area_entered(area):
	# This function will be triggered when an Area hits us.
	# We only care if the cooldown is over.
	if not _cooldown_timer.is_stopped():
		return # Still on cooldown, do nothing.
		
	# Start the cooldown so we can't be spammed
	_cooldown_timer.start()
	
	# Emit the signal and send our operation type with it!
	# (Notice this still sends the "plus_two", "times", etc.)
	print("Block hit! Emitting: ", operation_type)
	emit_signal("operation_activated", operation_type)
