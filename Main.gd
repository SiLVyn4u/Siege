extends Control

const MAX_DAY := 8
const DEFAULT_WINDOW_SIZE := Vector2i(1440, 900)
const MIN_WINDOW_SIZE := Vector2i(1280, 720)
const ACTION_FONT_SIZE := 12
const TITLE_FONT_SIZE := 22
const ZONE_TITLE_FONT_SIZE := 18

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

var pieces := {
	"left": [],
	"gate": [],
	"right": [],
	"tunnel": [],
	"attacker_back": [],
}

var next_piece_id := 1

var tunnel_progress := 0

var walls := {
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

# 修改点 1：
# 原来只有一个 breakthrough_zone 字符串。
# 现在每个城墙区域都可以独立拥有突破标记。
var breakthrough_zones := {
	"left": false,
	"gate": false,
	"right": false,
}

var weather_pool := ["晴朗", "暴雨", "大风", "浓雾"]

var root_box: VBoxContainer
var title_label: Label
var resource_label: Label
var zone_box: GridContainer
var action_box: VBoxContainer
var log_label: RichTextLabel


func _ready() -> void:
	setup_window()

	randomize()
	today_weather = weather_pool.pick_random()
	tomorrow_weather = weather_pool.pick_random()

	build_ui()
	refresh_ui()
	add_log("第 1 日开始。攻方先行动。")


func setup_window() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	Engine.max_fps = 60

	var window := get_window()

	if window == null:
		return

	window.min_size = Vector2i(960, 600)

	var screen_id := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen_id)

	var target_size := Vector2i(
		min(1280, usable_rect.size.x - 80),
		min(720, usable_rect.size.y - 80)
	)

	window.size = target_size
	window.move_to_center()


func build_ui() -> void:
	root_box = VBoxContainer.new()
	root_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_box.add_theme_constant_override("separation", 6)
	add_child(root_box)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	root_box.add_child(title_label)

	resource_label = Label.new()
	resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resource_label.add_theme_font_size_override("font_size", 13)
	root_box.add_child(resource_label)

	var main_box := HBoxContainer.new()
	main_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_box.add_theme_constant_override("separation", 8)
	root_box.add_child(main_box)

	var left_panel := VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(690, 0)
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_constant_override("separation", 6)
	main_box.add_child(left_panel)

	var zone_title := Label.new()
	zone_title.text = "战区状态"
	zone_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_title.add_theme_font_size_override("font_size", 16)
	left_panel.add_child(zone_title)

	var zone_scroll := ScrollContainer.new()
	zone_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(zone_scroll)

	zone_box = GridContainer.new()
	zone_box.columns = 3
	zone_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_box.add_theme_constant_override("h_separation", 8)
	zone_box.add_theme_constant_override("v_separation", 8)
	zone_scroll.add_child(zone_box)

	var right_panel := VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(420, 0)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_constant_override("separation", 6)
	main_box.add_child(right_panel)

	var action_title := Label.new()
	action_title.text = "行动区"
	action_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_title.add_theme_font_size_override("font_size", 16)
	right_panel.add_child(action_title)

	var action_scroll := ScrollContainer.new()
	action_scroll.custom_minimum_size = Vector2(0, 360)
	action_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(action_scroll)

	action_box = VBoxContainer.new()
	action_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_box.add_theme_constant_override("separation", 6)
	action_scroll.add_child(action_box)

	var log_title := Label.new()
	log_title.text = "日志"
	log_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_title.add_theme_font_size_override("font_size", 16)
	right_panel.add_child(log_title)

	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(0, 220)
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.bbcode_enabled = true
	log_label.add_theme_font_size_override("normal_font_size", 12)
	right_panel.add_child(log_label)


func refresh_ui() -> void:
	title_label.text = "《围城》规则原型 v0.3｜第 %d 日｜今日：%s｜明日预报：%s" % [
		day,
		today_weather,
		tomorrow_weather
	]

	var side_name := "攻方阶段" if current_side == "attacker" else "守方阶段"

	resource_label.text = """
当前阶段：%s

攻方：补给 %d｜士气 %d｜指挥点 %d｜预备点 %d
守方：粮秣 %d｜士气 %d｜指挥点 %d｜预备点 %d

突破标记：%s
""" % [
		side_name,
		attacker_supply,
		attacker_morale,
		attacker_cp,
		attacker_reserve,
		defender_grain,
		defender_morale,
		defender_cp,
		defender_reserve,
		get_breakthrough_text()
	]

	rebuild_zones()
	rebuild_actions()


func rebuild_zones() -> void:
	for child in zone_box.get_children():
		child.queue_free()

	for zone_id in ["left", "gate", "right"]:
		var data: Dictionary = walls[zone_id]

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(210, 140)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		zone_box.add_child(panel)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		panel.add_child(box)

		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", ZONE_TITLE_FONT_SIZE)
		name_label.text = data["name"]
		box.add_child(name_label)

		var wall_label := Label.new()
		wall_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wall_label.text = "城防：%d / %d" % [
			int(data["current"]),
			int(data["max"])
		]
		box.add_child(wall_label)

		var state_label := Label.new()
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		if breakthrough_zones[zone_id]:
			state_label.text = "状态：已有突破标记！"
		elif data["current"] <= 0:
			state_label.text = "状态：破口，可登城"
		else:
			state_label.text = "状态：完整"

		box.add_child(state_label)

		var pieces_label := Label.new()
		pieces_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pieces_label.add_theme_font_size_override("font_size", 12)
		pieces_label.text = get_zone_pieces_text(zone_id)
		box.add_child(pieces_label)

	add_special_zone_panel("tunnel", "地道", "地道进度：%d / 5" % tunnel_progress)
	add_special_zone_panel("attacker_back", "攻方后阵", "远程器械区")


func add_special_zone_panel(zone_id: String, title: String, extra_text: String) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(210, 140)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_box.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", ZONE_TITLE_FONT_SIZE)
	name_label.text = title
	box.add_child(name_label)

	var info_label := Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.text = extra_text
	box.add_child(info_label)

	var pieces_label := Label.new()
	pieces_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pieces_label.add_theme_font_size_override("font_size", 12)
	pieces_label.text = get_zone_pieces_text(zone_id)
	box.add_child(pieces_label)


func get_zone_pieces_text(zone_id: String) -> String:
	var list: Array = pieces[zone_id]

	if list.is_empty():
		return "部署物：无"

	var text := "部署物：\n"

	for piece in list:
		var side_name := "攻" if piece["side"] == "attacker" else "守"
		text += "%s｜%s HP %d/%d 战%d 工%d\n" % [
			side_name,
			piece["name"],
			piece["hp"],
			piece["max_hp"],
			piece["battle"],
			piece["engineering"],
		]

	return text


func rebuild_actions() -> void:
	for child in action_box.get_children():
		child.queue_free()

	var hint := Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)

	if game_over:
		hint.text = "游戏结束。"
	else:
		hint.text = "选择行动："

	action_box.add_child(hint)

	if game_over:
		return

	if current_side == "attacker":
		add_attacker_actions()
	else:
		add_defender_actions()

	add_section_title("通用行动")

	var common_grid := make_action_grid(2)

	var reserve_button := make_action_button("待机：转 1 点预备")
	reserve_button.disabled = attacker_cp <= 0 if current_side == "attacker" else defender_cp <= 0
	reserve_button.pressed.connect(pass_action)
	common_grid.add_child(reserve_button)

	var phase_button := make_action_button("")

	if current_side == "attacker":
		phase_button.text = "结束攻方阶段"
		phase_button.pressed.connect(end_attacker_phase)
	else:
		phase_button.text = "结束本日"
		phase_button.pressed.connect(end_day)

	common_grid.add_child(phase_button)


func add_section_title(text: String) -> void:
	var title := Label.new()
	title.text = text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	action_box.add_child(title)


func make_action_grid(columns: int = 2) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	action_box.add_child(grid)
	return grid


func make_action_button(text: String, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.custom_minimum_size = Vector2(118, 30)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", ACTION_FONT_SIZE)
	return button


func add_attacker_actions() -> void:
	add_section_title("攻方攻击")

	var attack_grid := make_action_grid(3)

	for zone_id in ["left", "gate", "right"]:
		var z: String = String(zone_id)

		var button := make_action_button(
			"强攻%s｜1 指挥" % walls[z]["name"],
			attacker_cp < 1
		)
		button.pressed.connect(attacker_assault.bind(z))
		attack_grid.add_child(button)

	for zone_id in ["left", "gate", "right"]:
		var z: String = String(zone_id)

		var button := make_action_button(
			"登城%s｜2 指挥" % walls[z]["name"],
			attacker_cp < 2 or walls[z]["current"] > 0 or breakthrough_zones[z]
		)
		button.pressed.connect(attacker_climb.bind(z))
		attack_grid.add_child(button)

	add_section_title("攻方部署：兵力")

	var deploy_grid1 := make_action_grid(3)

	for zone_id in ["left", "gate", "right"]:
		var z: String = String(zone_id)

		var infantry_button := make_action_button(
			"步兵到%s｜1 指挥" % walls[z]["name"],
			attacker_cp < 1
		)
		infantry_button.pressed.connect(deploy_piece.bind(z, "attacker", "attacker_infantry", 1, 0, 0))
		deploy_grid1.add_child(infantry_button)

	add_section_title("攻方部署：工程")

	var deploy_grid2 := make_action_grid(2)

	var engineer_gate_button := make_action_button("工兵到主门｜1 指挥", attacker_cp < 1)
	engineer_gate_button.pressed.connect(deploy_piece.bind("gate", "attacker", "attacker_engineer", 1, 0, 0))
	deploy_grid2.add_child(engineer_gate_button)

	var engineer_tunnel_button := make_action_button("工兵到地道｜1 指挥", attacker_cp < 1)
	engineer_tunnel_button.pressed.connect(deploy_piece.bind("tunnel", "attacker", "attacker_engineer", 1, 0, 0))
	deploy_grid2.add_child(engineer_tunnel_button)

	var ladder_left_button := make_action_button("云梯到左墙｜1 指挥", attacker_cp < 1)
	ladder_left_button.pressed.connect(deploy_piece.bind("left", "attacker", "ladder", 1, 0, 0))
	deploy_grid2.add_child(ladder_left_button)

	var ladder_right_button := make_action_button("云梯到右墙｜1 指挥", attacker_cp < 1)
	ladder_right_button.pressed.connect(deploy_piece.bind("right", "attacker", "ladder", 1, 0, 0))
	deploy_grid2.add_child(ladder_right_button)

	add_section_title("攻方部署：器械")

	var deploy_grid3 := make_action_grid(2)

	var ram_button := make_action_button("冲车到主门｜2 指挥 +1 补给", attacker_cp < 2 or attacker_supply < 1)
	ram_button.pressed.connect(deploy_piece.bind("gate", "attacker", "ram", 2, 1, 0))
	deploy_grid3.add_child(ram_button)

	var cannon_button := make_action_button("炮队到后阵｜2 指挥 +1 补给", attacker_cp < 2 or attacker_supply < 1)
	cannon_button.pressed.connect(deploy_piece.bind("attacker_back", "attacker", "cannon", 2, 1, 0))
	deploy_grid3.add_child(cannon_button)


func add_defender_actions() -> void:
	add_section_title("守方应对")

	var action_grid := make_action_grid(3)

	for zone_id in ["left", "gate", "right"]:
		var z: String = String(zone_id)

		var button := make_action_button(
			"修补%s｜1 指挥" % walls[z]["name"],
			defender_cp < 1 or walls[z]["current"] >= walls[z]["max"]
		)
		button.pressed.connect(defender_repair.bind(z))
		action_grid.add_child(button)

	for zone_id in ["left", "gate", "right"]:
		var z: String = String(zone_id)

		var button := make_action_button(
			"反击%s｜1 指挥/预备" % walls[z]["name"],
			not breakthrough_zones[z] or (defender_cp < 1 and defender_reserve < 1)
		)
		button.pressed.connect(defender_counterattack.bind(z))
		action_grid.add_child(button)

	add_section_title("守方部署：守军")

	var deploy_grid1 := make_action_grid(3)

	for zone_id in ["left", "gate", "right"]:
		var z: String = String(zone_id)

		var guard_button := make_action_button(
			"守军到%s｜1 指挥" % walls[z]["name"],
			defender_cp < 1
		)
		guard_button.pressed.connect(deploy_piece.bind(z, "defender", "defender_guard", 1, 0, 0))
		deploy_grid1.add_child(guard_button)

	add_section_title("守方部署：工匠")

	var deploy_grid2 := make_action_grid(2)

	for zone_id in ["left", "gate", "right"]:
		var z: String = String(zone_id)

		var worker_button := make_action_button(
			"工匠到%s｜1 指挥" % walls[z]["name"],
			defender_cp < 1
		)
		worker_button.pressed.connect(deploy_piece.bind(z, "defender", "defender_worker", 1, 0, 0))
		deploy_grid2.add_child(worker_button)

	var worker_tunnel_button := make_action_button("工匠到地道｜1 指挥", defender_cp < 1)
	worker_tunnel_button.pressed.connect(deploy_piece.bind("tunnel", "defender", "defender_worker", 1, 0, 0))
	deploy_grid2.add_child(worker_tunnel_button)

	add_section_title("守方部署：防御器械")

	var deploy_grid3 := make_action_grid(2)

	var archer_left_button := make_action_button("弓手到左墙｜1 指挥", defender_cp < 1)
	archer_left_button.pressed.connect(deploy_piece.bind("left", "defender", "tower_archer", 1, 0, 0))
	deploy_grid3.add_child(archer_left_button)

	var archer_right_button := make_action_button("弓手到右墙｜1 指挥", defender_cp < 1)
	archer_right_button.pressed.connect(deploy_piece.bind("right", "defender", "tower_archer", 1, 0, 0))
	deploy_grid3.add_child(archer_right_button)

	var logs_left_button := make_action_button("滚木到左墙｜1 指挥", defender_cp < 1)
	logs_left_button.pressed.connect(deploy_piece.bind("left", "defender", "rolling_logs", 1, 0, 0))
	deploy_grid3.add_child(logs_left_button)

	var logs_gate_button := make_action_button("滚木到主门｜1 指挥", defender_cp < 1)
	logs_gate_button.pressed.connect(deploy_piece.bind("gate", "defender", "rolling_logs", 1, 0, 0))
	deploy_grid3.add_child(logs_gate_button)

	var logs_right_button := make_action_button("滚木到右墙｜1 指挥", defender_cp < 1)
	logs_right_button.pressed.connect(deploy_piece.bind("right", "defender", "rolling_logs", 1, 0, 0))
	deploy_grid3.add_child(logs_right_button)


func attacker_assault(zone_id: String) -> void:
	if game_over or current_side != "attacker":
		return

	if attacker_cp < 1:
		add_log("攻方指挥点不足。")
		return

	attacker_cp -= 1

	var damage := 2

	if today_weather == "暴雨":
		damage = max(1, damage - 1)

	walls[zone_id]["current"] = max(0, walls[zone_id]["current"] - damage)

	add_log("攻方强攻%s，造成 %d 点普通破坏。" % [
		walls[zone_id]["name"],
		damage
	])

	refresh_ui()


func attacker_climb(zone_id: String) -> void:
	if game_over or current_side != "attacker":
		return

	if attacker_cp < 2:
		add_log("攻方指挥点不足，无法登城。")
		return

	if walls[zone_id]["current"] > 0:
		add_log("%s尚未破口，不能登城。" % walls[zone_id]["name"])
		return

	if breakthrough_zones[zone_id]:
		add_log("%s已经有突破标记。" % walls[zone_id]["name"])
		return

	attacker_cp -= 2
	breakthrough_zones[zone_id] = true

	add_log("攻方在%s登城，放置突破标记！守方将在守方阶段尝试清除。" % walls[zone_id]["name"])

	refresh_ui()


func defender_repair(zone_id: String) -> void:
	if game_over or current_side != "defender":
		return

	if defender_cp < 1:
		add_log("守方指挥点不足。")
		return

	defender_cp -= 1

	var repair_amount := 2
	walls[zone_id]["current"] = min(
		walls[zone_id]["max"],
		walls[zone_id]["current"] + repair_amount
	)

	add_log("守方修补%s，恢复 %d 点当前城防。" % [
		walls[zone_id]["name"],
		repair_amount
	])

	refresh_ui()


func defender_counterattack(zone_id: String) -> void:
	if game_over or current_side != "defender":
		return

	if not breakthrough_zones[zone_id]:
		add_log("该战区没有突破标记。")
		return

	if defender_cp >= 1:
		defender_cp -= 1
	elif defender_reserve >= 1:
		defender_reserve -= 1
	else:
		add_log("守方没有指挥点或预备点，无法反击。")
		return

	breakthrough_zones[zone_id] = false

	add_log("守方在%s反击成功，移除了突破标记。" % walls[zone_id]["name"])

	refresh_ui()


func pass_action() -> void:
	if game_over:
		return

	if current_side == "attacker":
		if attacker_cp > 0:
			attacker_cp -= 1
			attacker_reserve += 1
			add_log("攻方待机，将 1 点指挥点转为预备点。")
		else:
			add_log("攻方已经没有指挥点。")
	else:
		if defender_cp > 0:
			defender_cp -= 1
			defender_reserve += 1
			add_log("守方待机，将 1 点指挥点转为预备点。")
		else:
			add_log("守方已经没有指挥点。")

	refresh_ui()


func both_sides_out_of_cp() -> bool:
	return attacker_cp <= 0 and defender_cp <= 0


func switch_side() -> void:
	if current_side == "attacker":
		current_side = "defender"
	else:
		current_side = "attacker"


func end_day() -> void:
	if game_over:
		return

	add_log("第 %d 日进入结算。" % day)

	if has_any_breakthrough():
		game_over = true
		add_log("[color=red]攻方胜利！以下突破标记未被清除：%s。城池陷落。[/color]" % get_breakthrough_text())
		refresh_ui()
		return

	consume_long_term_resources()

	if attacker_morale <= 0:
		game_over = true
		add_log("[color=blue]守方胜利！攻方士气崩溃。[/color]")
		refresh_ui()
		return

	if defender_morale <= 0:
		game_over = true
		add_log("[color=red]攻方胜利！守方士气崩溃。[/color]")
		refresh_ui()
		return

	if day >= MAX_DAY:
		game_over = true
		add_log("[color=blue]守方胜利！援军抵达，城池守住。[/color]")
		refresh_ui()
		return

	day += 1
	begin_next_day()


func end_attacker_phase() -> void:
	if game_over:
		return

	if current_side != "attacker":
		return

	current_side = "defender"
	consecutive_passes = 0

	add_log("攻方阶段结束。守方开始应对攻势。")
	refresh_ui()


func consume_long_term_resources() -> void:
	if attacker_supply > 0:
		attacker_supply -= 1
		add_log("攻方消耗 1 补给。")
	else:
		attacker_morale -= 1
		add_log("攻方补给耗尽，士气 -1。")

	if defender_grain > 0:
		defender_grain -= 1
		add_log("守方消耗 1 粮秣。")
	else:
		defender_morale -= 1
		add_log("守方粮秣耗尽，士气 -1。")


func begin_next_day() -> void:
	today_weather = tomorrow_weather
	tomorrow_weather = weather_pool.pick_random()

	attacker_cp = 4
	defender_cp = 3
	attacker_reserve = 0
	defender_reserve = 0
	consecutive_passes = 0
	current_side = "attacker"

	add_log("第 %d 日开始。今日天气：%s。攻方阶段开始。" % [day, today_weather])
	refresh_ui()


func has_any_breakthrough() -> bool:
	for zone_id in ["left", "gate", "right"]:
		if breakthrough_zones[zone_id]:
			return true

	return false


func get_breakthrough_text() -> String:
	var names := PackedStringArray()

	for zone_id in ["left", "gate", "right"]:
		if breakthrough_zones[zone_id]:
			names.append(String(walls[zone_id]["name"]))

	if names.is_empty():
		return "无"

	return "、".join(names)


func create_piece(side: String, kind: String) -> Dictionary:
	var piece := {
		"id": next_piece_id,
		"side": side,
		"kind": kind,
		"name": "",
		"battle": 0,
		"engineering": 0,
		"hp": 1,
		"max_hp": 1,
		"is_equipment": false,
	}

	next_piece_id += 1

	match kind:
		"attacker_infantry":
			piece["name"] = "步兵队"
			piece["battle"] = 2
			piece["engineering"] = 0
			piece["hp"] = 2
			piece["max_hp"] = 2

		"attacker_engineer":
			piece["name"] = "工兵"
			piece["battle"] = 1
			piece["engineering"] = 2
			piece["hp"] = 1
			piece["max_hp"] = 1

		"ladder":
			piece["name"] = "云梯"
			piece["battle"] = 0
			piece["engineering"] = 0
			piece["hp"] = 2
			piece["max_hp"] = 2
			piece["is_equipment"] = true

		"ram":
			piece["name"] = "冲车"
			piece["battle"] = 0
			piece["engineering"] = 3
			piece["hp"] = 3
			piece["max_hp"] = 3
			piece["is_equipment"] = true

		"cannon":
			piece["name"] = "炮队"
			piece["battle"] = 0
			piece["engineering"] = 2
			piece["hp"] = 2
			piece["max_hp"] = 2
			piece["is_equipment"] = true

		"defender_guard":
			piece["name"] = "守军"
			piece["battle"] = 2
			piece["engineering"] = 0
			piece["hp"] = 2
			piece["max_hp"] = 2

		"defender_worker":
			piece["name"] = "工匠"
			piece["battle"] = 0
			piece["engineering"] = 2
			piece["hp"] = 1
			piece["max_hp"] = 1

		"tower_archer":
			piece["name"] = "塔楼弓手"
			piece["battle"] = 1
			piece["engineering"] = 0
			piece["hp"] = 2
			piece["max_hp"] = 2
			piece["is_equipment"] = true

		"rolling_logs":
			piece["name"] = "滚木擂石"
			piece["battle"] = 0
			piece["engineering"] = 0
			piece["hp"] = 1
			piece["max_hp"] = 1
			piece["is_equipment"] = true

	return piece


func deploy_piece(
	zone_id: String,
	side: String,
	kind: String,
	cp_cost: int,
	supply_cost: int = 0,
	grain_cost: int = 0
) -> void:
	if game_over:
		return

	if side == "attacker":
		if current_side != "attacker":
			return

		if attacker_cp < cp_cost:
			add_log("攻方指挥点不足，无法部署。")
			return

		if attacker_supply < supply_cost:
			add_log("攻方补给不足，无法部署。")
			return

		attacker_cp -= cp_cost
		attacker_supply -= supply_cost

	else:
		if current_side != "defender":
			return

		if defender_cp < cp_cost:
			add_log("守方指挥点不足，无法部署。")
			return

		if defender_grain < grain_cost:
			add_log("守方粮秣不足，无法部署。")
			return

		defender_cp -= cp_cost
		defender_grain -= grain_cost

	var piece := create_piece(side, kind)
	pieces[zone_id].append(piece)

	add_log("%s在%s部署了%s。" % [
		"攻方" if side == "attacker" else "守方",
		get_zone_name(zone_id),
		piece["name"]
	])

	refresh_ui()


func get_zone_name(zone_id: String) -> String:
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


func add_log(text: String) -> void:
	log_label.append_text(text + "\n")
	log_label.scroll_to_line(log_label.get_line_count())
