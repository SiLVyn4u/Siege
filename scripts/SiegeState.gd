extends RefCounted
class_name SiegeState

const SiegeData := preload("res://scripts/SiegeData.gd")

var day := 1
var game_over := false
var current_side := "attacker"

var today_weather := "晴朗"
var tomorrow_weather := "暴雨"

var attacker_supply := 8
var attacker_morale := 8
var attacker_cp := 4
var attacker_reserve := 0

var defender_grain := 6
var defender_morale := 10
var defender_cp := 3
var defender_reserve := 0

var consecutive_passes := 0

var walls := {}
var pieces := {}
var breakthrough_zones := {}

var next_piece_id := 1
var tunnel_progress := 0

var log_entries: Array[String] = []


func _init() -> void:
	reset()


func reset() -> void:
	day = 1
	game_over = false
	current_side = "attacker"

	attacker_supply = 8
	attacker_morale = 8
	attacker_cp = 4
	attacker_reserve = 0

	defender_grain = 6
	defender_morale = 10
	defender_cp = 3
	defender_reserve = 0

	consecutive_passes = 0
	next_piece_id = 1
	tunnel_progress = 0

	today_weather = SiegeData.WEATHER_POOL.pick_random()
	tomorrow_weather = SiegeData.WEATHER_POOL.pick_random()

	walls = _duplicate_dictionary(SiegeData.INITIAL_WALLS)

	pieces = {
		"left": [],
		"gate": [],
		"right": [],
		"tunnel": [],
		"attacker_back": [],
	}

	breakthrough_zones = {
		"left": false,
		"gate": false,
		"right": false,
	}

	log_entries.clear()
	add_log("第 1 日开始。攻方阶段开始。")


func add_log(text: String) -> void:
	log_entries.append(text)

	# 防止日志无限增长。
	if log_entries.size() > 200:
		log_entries.pop_front()


func get_log_text() -> String:
	return "\n".join(log_entries)


func get_breakthrough_text() -> String:
	var names := PackedStringArray()

	for zone_id in SiegeData.MAIN_ZONES:
		if bool(breakthrough_zones[zone_id]):
			names.append(String(walls[zone_id]["name"]))

	if names.is_empty():
		return "无"

	return "、".join(names)


func has_any_breakthrough() -> bool:
	for zone_id in SiegeData.MAIN_ZONES:
		if bool(breakthrough_zones[zone_id]):
			return true

	return false


func _duplicate_dictionary(source: Dictionary) -> Dictionary:
	var result := {}

	for key in source.keys():
		var value = source[key]
		if value is Dictionary:
			result[key] = _duplicate_dictionary(value)
		elif value is Array:
			result[key] = value.duplicate(true)
		else:
			result[key] = value

	return result
