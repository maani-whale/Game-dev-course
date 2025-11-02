extends Node2D

# We need a reference to our platform.
# Drag your MovablePlatform node from the Scene panel
# onto this @export var in the Inspector!
# OR, just make sure its name is "MovablePlatform" and use %
@onready var _movable_platform: MovablePlatform = %MovablePlatform


# This is the "listener" function.
# We will connect all our blocks' signals to this.
func _on_operation_block_activated(type: String):
	print("Main level heard signal: ", type)
	
	# Now, tell the platform to do the thing.
	if _movable_platform:
		_movable_platform.execute_operation(type)
	else:
		print("MainLevel script can't find MovablePlatform!")


# You DO NOT need to add this code. This is just
# to show you what "connecting a signal" means.
func _ready():
	# You can do this step in the editor, which is easier!
	# $Block1.operation_activated.connect(_on_operation_block_activated)
	# $Block2.operation_activated.connect(_on_operation_block_activated)
	# $Block3.operation_activated.connect(_on_operation_block_activated)
	pass




func _on_operation_block_operation_activated(operation_type: String) -> void:
	pass # Replace with function body.


func _on_operation_block_2_operation_activated(operation_type: String) -> void:
	pass # Replace with function body.


func _on_operation_block_3_operation_activated(operation_type: String) -> void:
	pass # Replace with function body.
