class_name MatchScoreState
extends RefCounted

var max_rounds: int = 15
var wins_to_match: int = 8
var local_score: int = 0
var enemy_score: int = 0
var round_number: int = 1


func _init(new_max_rounds: int = 15, new_wins_to_match: int = 8) -> void:
	configure(new_max_rounds, new_wins_to_match)


func configure(new_max_rounds: int, new_wins_to_match: int) -> void:
	max_rounds = maxi(1, new_max_rounds)
	wins_to_match = maxi(1, new_wins_to_match)
	local_score = mini(local_score, wins_to_match)
	enemy_score = mini(enemy_score, wins_to_match)


func reset() -> void:
	local_score = 0
	enemy_score = 0
	round_number = 1


func add_win(team: int) -> int:
	var won_index: int = get_score(team)
	if team == CardSlot.TEAM_PLAYER:
		local_score = mini(local_score + 1, wins_to_match)
	elif team == CardSlot.TEAM_ENEMY:
		enemy_score = mini(enemy_score + 1, wins_to_match)
	else:
		return -1
	round_number += 1
	return won_index


func get_score(team: int) -> int:
	if team == CardSlot.TEAM_PLAYER:
		return local_score
	if team == CardSlot.TEAM_ENEMY:
		return enemy_score
	return 0


func get_next_marker_index(team: int) -> int:
	return clampi(get_score(team), 0, wins_to_match - 1)


func is_match_over() -> bool:
	if local_score >= wins_to_match or enemy_score >= wins_to_match:
		return true
	if round_number > max_rounds and local_score != enemy_score:
		return true
	return false
