extends Node
class_name PuzzleManager

@export var correct_answer_id: String = "A"
@export var platforms_to_activate: Array[NodePath] = []
@export var player_path: NodePath
@export var wrong_answer_damage: int = 1
@export var damage_on_wrong: bool = true   # <— NEW

var _is_solved: bool = false

signal puzzle_solved
signal puzzle_failed(answer_id: String)


func submit_answer(answer_choice: AnswerChoice) -> void:
	if _is_solved:
		return

	if answer_choice.answer_id == correct_answer_id:
		_is_solved = true
		_activate_platforms()
		emit_signal("puzzle_solved")
	else:
		if damage_on_wrong:
			_damage_player()
		emit_signal("puzzle_failed", answer_choice.answer_id)


func _activate_platforms() -> void:
	for path in platforms_to_activate:
		if path == NodePath():
			continue
		var p = get_node(path)
		if p and p.has_method("start_moving"):
			p.start_moving()


func _damage_player() -> void:
	if player_path == NodePath():
		return
	var player = get_node(player_path)
	if player and player.has_method("take_damage"):
		player.take_damage(wrong_answer_damage)
