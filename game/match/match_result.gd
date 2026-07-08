class_name MatchResult
extends RefCounted

var winner_team: int = -1
var winner_name: String = ""
var is_local_winner: bool = false


func _init(new_winner_team: int = -1, new_winner_name: String = "", new_is_local_winner: bool = false) -> void:
	winner_team = new_winner_team
	winner_name = new_winner_name
	is_local_winner = new_is_local_winner


func has_winner() -> bool:
	return winner_team >= 0 and not winner_name.is_empty()
