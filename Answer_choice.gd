extends Node2D
class_name AnswerChoice

## Value of this answer. Can be int, string, whatever your puzzle uses.
@export var answer_id: String = "2"

## Drag your PuzzleManager node here in the editor
@export var puzzle_manager: NodePath

## Optional: change color or sprite when chosen
@export var can_be_chosen_multiple_times: bool = false

var _was_chosen: bool = false


func take_damage(amount: int = 1) -> void:
	# This is called by the Player's attack when this box is hit.
	if _was_chosen and not can_be_chosen_multiple_times:
		return

	_was_chosen = true

	if puzzle_manager != NodePath():
		var pm = get_node(puzzle_manager)
		if pm and pm.has_method("submit_answer"):
			pm.submit_answer(self)
