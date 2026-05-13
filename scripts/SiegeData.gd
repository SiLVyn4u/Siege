extends RefCounted
class_name SiegeData

const VERSION_TEXT := "《围城》规则原型 v0.2｜拆分版"
const MAX_DAY := 8

const DEFAULT_WINDOW_SIZE := Vector2i(1440, 900)
const MIN_WINDOW_SIZE := Vector2i(960, 600)
const ACTION_FONT_SIZE := 12
const TITLE_FONT_SIZE := 22
const ZONE_TITLE_FONT_SIZE := 18

const MAIN_ZONES := ["left", "gate", "right"]
const ALL_ZONES := ["left", "gate", "right", "tunnel", "attacker_back"]

const WEATHER_POOL := ["晴朗", "暴雨", "大风", "浓雾"]

const INITIAL_WALLS := {
	"left": {
		"name": "左墙",
		"current": 10,
		"max": 10,
	},
	"gate": {
		"name": "主门",
		"current": 14,
		"max": 14,
	},
	"right": {
		"name": "右墙",
		"current": 10,
		"max": 10,
	},
}

const PIECE_TEMPLATES := {
	"attacker_infantry": {
		"name": "步兵队",
		"battle": 2,
		"engineering": 0,
		"hp": 2,
		"max_hp": 2,
		"is_equipment": false,
	},
	"attacker_engineer": {
		"name": "工兵",
		"battle": 1,
		"engineering": 2,
		"hp": 1,
		"max_hp": 1,
		"is_equipment": false,
	},
	"ladder": {
		"name": "云梯",
		"battle": 0,
		"engineering": 0,
		"hp": 2,
		"max_hp": 2,
		"is_equipment": true,
	},
	"ram": {
		"name": "冲车",
		"battle": 0,
		"engineering": 3,
		"hp": 3,
		"max_hp": 3,
		"is_equipment": true,
	},
	"cannon": {
		"name": "炮队",
		"battle": 0,
		"engineering": 2,
		"hp": 2,
		"max_hp": 2,
		"is_equipment": true,
	},
	"defender_guard": {
		"name": "守军",
		"battle": 2,
		"engineering": 0,
		"hp": 2,
		"max_hp": 2,
		"is_equipment": false,
	},
	"defender_worker": {
		"name": "工匠",
		"battle": 0,
		"engineering": 2,
		"hp": 1,
		"max_hp": 1,
		"is_equipment": false,
	},
	"tower_archer": {
		"name": "塔楼弓手",
		"battle": 1,
		"engineering": 0,
		"hp": 2,
		"max_hp": 2,
		"is_equipment": true,
	},
	"rolling_logs": {
		"name": "滚木擂石",
		"battle": 0,
		"engineering": 0,
		"hp": 1,
		"max_hp": 1,
		"is_equipment": true,
	},
}

static func get_zone_name(zone_id: String) -> String:
	match zone_id:
		"left":
			return "左墙"
		"gate":
			return "主门"
		"right":
			return "右墙"
		"tunnel":
			return "地道"
		"attacker_back":
			return "攻方后阵"
		_:
			return zone_id
