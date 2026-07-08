class_name ShopWallet
extends Control

const MONEY_COLOR := Color("de9e41")
const LIGHT_COLOR := Color("ebede9")
const DARK_COLOR := Color("151d28")
const ERROR_COLOR := Color("a53030")

@export var buff_effect_path: NodePath = ^"../../../EffectsLayer/BuffEffect"
@export_range(0, 9999, 1) var starting_money := 10
@export_range(0.05, 0.5, 0.01) var zoom_duration := 0.14
@export_range(0.5, 1.0, 0.01) var zoom_start_scale := 0.75
@export_range(0.0, 1.0, 0.05) var purchase_finish_delay := 0.2
@export_range(0.0, 24.0, 1.0) var shake_distance := 8.0
@export_range(0.2, 2.0, 0.05) var failure_duration := 1.0

var balance := 0
var _motion_tween: Tween
var _flash_tween: Tween
var _shake_tween: Tween
var _shake_target_visual: Control
var _shake_start_position := Vector2.ZERO
var _spending := false

@onready var money_stat: StatCircle = $MoneyStat
@onready var buff_effect: BattleBuffEffect = get_node(buff_effect_path) as BattleBuffEffect


func _ready() -> void:
	add_to_group("shop_wallets")
	hide()
	balance = starting_money
	money_stat.fill_color = MONEY_COLOR
	money_stat.value = balance


func play_shop_open() -> void:
	_kill_motion_tween()
	pivot_offset = size * 0.5
	scale = Vector2.ONE * zoom_start_scale
	modulate.a = 0.0
	show()
	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", Vector2.ONE, zoom_duration)
	_motion_tween.tween_property(self, "modulate:a", 1.0, zoom_duration)


func play_shop_close() -> void:
	_kill_motion_tween()
	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_motion_tween.tween_property(self, "scale", Vector2.ONE * zoom_start_scale, zoom_duration)
	_motion_tween.tween_property(self, "modulate:a", 0.0, zoom_duration)
	_motion_tween.finished.connect(_finish_shop_close)


func can_afford(price: int) -> bool:
	return balance >= price


func add_coins(amount: int) -> void:
	balance = max(0, balance + amount)
	money_stat.value = balance


func reset_wallet() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_finish_shake_target()
	_spending = false
	balance = starting_money
	money_stat.value = balance
	_set_money_style(MONEY_COLOR, LIGHT_COLOR)


func is_busy() -> bool:
	return _spending or _is_failure_animating()


func try_spend(price: int, target_stat: Control, target_visual: Control) -> bool:
	if _spending:
		return false
	if not can_afford(price):
		if not _is_failure_animating():
			play_insufficient(target_visual)
		return false
	_spending = true
	if buff_effect:
		await buff_effect.play_ui_stat_to_stat(money_stat, target_stat, price, MONEY_COLOR)
	await _empty_price_stat(target_stat, price)
	balance -= price
	money_stat.value = balance
	_spending = false
	return true


func _empty_price_stat(target_stat: Control, price: int) -> void:
	var stat: StatCircle = target_stat as StatCircle
	if not stat or purchase_finish_delay <= 0.0:
		return
	var tween: Tween = create_tween()
	tween.tween_method(
		_set_stat_value.bind(stat),
		float(price),
		0.0,
		purchase_finish_delay
	)
	await tween.finished


func _set_stat_value(value: float, stat: StatCircle) -> void:
	if is_instance_valid(stat):
		stat.value = roundi(value)


func play_insufficient(target_visual: Control) -> void:
	_flash_money()
	_shake_target(target_visual)


func _flash_money() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_set_money_style(MONEY_COLOR, LIGHT_COLOR)
	_flash_tween = create_tween()
	var step_duration: float = failure_duration / 8.0
	for _flash_index in range(4):
		_flash_tween.tween_callback(_set_money_style.bind(ERROR_COLOR, LIGHT_COLOR))
		_flash_tween.tween_interval(step_duration)
		_flash_tween.tween_callback(_set_money_style.bind(LIGHT_COLOR, DARK_COLOR))
		_flash_tween.tween_interval(step_duration)
	_flash_tween.tween_callback(_set_money_style.bind(MONEY_COLOR, LIGHT_COLOR))


func _shake_target(target_visual: Control) -> void:
	if not is_instance_valid(target_visual):
		return
	if _shake_tween and _shake_tween.is_valid():
		return
	_shake_target_visual = target_visual
	_shake_start_position = target_visual.position
	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for shake_index in range(6):
		var direction: float = -1.0 if shake_index % 2 == 0 else 1.0
		_shake_tween.tween_property(
			target_visual,
			"position:x",
			_shake_start_position.x + shake_distance * direction,
			failure_duration / 7.0
		)
	_shake_tween.tween_property(target_visual, "position:x", _shake_start_position.x, failure_duration / 7.0)
	_shake_tween.tween_callback(_finish_shake_target)


func _finish_shake_target() -> void:
	if is_instance_valid(_shake_target_visual):
		_shake_target_visual.position = _shake_start_position
	_shake_target_visual = null


func _is_failure_animating() -> bool:
	return _shake_tween != null and _shake_tween.is_valid()


func _set_money_style(fill_color: Color, text_color: Color) -> void:
	money_stat.fill_color = fill_color
	money_stat.value_label.add_theme_color_override("font_color", text_color)


func _kill_motion_tween() -> void:
	if _motion_tween and _motion_tween.is_valid():
		_motion_tween.kill()


func _finish_shop_close() -> void:
	hide()
