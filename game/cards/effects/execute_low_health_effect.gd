class_name ExecuteLowHealthEffect
extends CardEffect

@export_range(1, 99, 1) var health_threshold := 2
@export var flash_color := Color("ab1010")


func get_execute_health_threshold(_source: BattleCardState) -> int:
	return health_threshold


func get_flash_color_hex() -> String:
	return flash_color.to_html(false)
