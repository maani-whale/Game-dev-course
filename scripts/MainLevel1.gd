extends Node2D
class_name LevelRoot

# Reference to your PuzzleManager node
@onready var _puzzle_manager: PuzzleManager = %PuzzleManager

# Reference to the moving platform (if you only have one)
@onready var _movable_platform: MovingPlatform = %MovingPlatform

func _ready() -> void:
	# Connect signals from the PuzzleManager
	if _puzzle_manager:
		_puzzle_manager.puzzle_solved.connect(_on_puzzle_solved)
		_puzzle_manager.puzzle_failed.connect(_on_puzzle_failed)
	else:
		push_error("LevelRoot couldn't find PuzzleManager!")

	# Optional: ensure we found the platform too
	if not _movable_platform:
		push_warning("LevelRoot couldn't find MovingPlatform!")

# Called when the correct answer is chosen
func _on_puzzle_solved() -> void:
	print("✅ Puzzle solved! Platform moving!")
	if _movable_platform:
		_movable_platform.start_moving()

# Called when a wrong answer is chosen
func _on_puzzle_failed(answer_id: String) -> void:
	print("❌ Wrong answer chosen: ", answer_id)
