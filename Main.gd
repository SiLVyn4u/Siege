extends Control

const SiegeStateScript := preload("res://scripts/SiegeState.gd")
const SiegeRules := preload("res://scripts/SiegeRules.gd")
const SiegeData := preload("res://scripts/SiegeData.gd")


# ============================================================
# 窗口
# ============================================================

const WINDOW_SIZE := Vector2i(1763, 992)
const MIN_WINDOW_SIZE := Vector2i(1280, 720)


# ============================================================
# 字体
# ============================================================

const FONT_TITLE := 28
const FONT_TOP := 22
const FONT_NORMAL := 20
const FONT_SMALL := 17
const FONT_CARD_TITLE := 22
const FONT_CARD_BODY := 17
const FONT_BUTTON := 20
const FONT_ZONE_TITLE := 22


# ============================================================
# 颜色
# ============================================================

const COLOR_BG := Color("18202a")
const COLOR_TOP_BAR := Color("263241")
const COLOR_PANEL := Color("f1e3cf")
const COLOR_PANEL_2 := Color("ead5bd")
const COLOR_CARD := Color("fff7e8")
const COLOR_CARD_SELECTED := Color("ffe08a")
const COLOR_ZONE := Color("e7d0b6")
const COLOR_ZONE_HOVER := Color("f0dbc4")
const COLOR_ZONE_ACTIVE := Color("ffd98e")
const COLOR_DEFENDER_AREA := Color("cad9e9")
const COLOR_ATTACKER_AREA := Color("edd1bb")
const COLOR_HEADER := Color("5c422e")
const COLOR_HEADER_TEXT := Color("fff4dc")
const COLOR_BUTTON := Color("d9e5f2")
const COLOR_BUTTON_HOVER := Color("eaf2fb")
const COLOR_BUTTON_ACTIVE := Color("ffd879")
const COLOR_BUTTON_DISABLED := Color("78818d")
const COLOR_END_BUTTON := Color("e48f6a")
const COLOR_END_BUTTON_HOVER := Color("eea27f")
const COLOR_TEXT_DARK := Color("202020")
const COLOR_TEXT_MUTED := Color("4d4d4d")
const COLOR_TEXT_LIGHT := Color("f5f1e8")
const COLOR_BORDER := Color("111820")
const COLOR_ACCENT := Color("b77d37")


# ============================================================
# 统一布局参数
# 以后如果要整体调整 UI，优先改这里。
# ============================================================

const LAYOUT_W := 1763.0
const LAYOUT_H := 992.0

const MARGIN := 22.0
const CONTENT_W := LAYOUT_W - MARGIN * 2.0

const PANEL_PADDING := 10
const TOP_PANEL_PADDING_X := 20

const TOP_X := MARGIN
const TOP_Y := 18.0
const TOP_W := CONTENT_W
const TOP_H := 64.0

const BATTLE_X := MARGIN
const BATTLE_Y := 104.0
const BATTLE_H := 380.0
const BATTLE_COLUMN_GAP := 24.0

const SPECIAL_ZONE_W := 357.0
const SPECIAL_ZONE_GAP := 14.0
const SPECIAL_ZONE_H := 117.0

const MAIN_ZONE_TOTAL_W := CONTENT_W - SPECIAL_ZONE_W - BATTLE_COLUMN_GAP
const MAIN_ZONE_GAP := 18.0
const MAIN_ZONE_W := 434.0

const MAIN_ZONE_X := BATTLE_X
const SPECIAL_ZONE_X := BATTLE_X + MAIN_ZONE_TOTAL_W + BATTLE_COLUMN_GAP

const STATUS_X := MARGIN
const STATUS_Y := 506.0
const STATUS_W := CONTENT_W
const STATUS_H := 64.0

const BOTTOM_Y := 588.0
const BOTTOM_H := 366.0
const BOTTOM_GAP := 16.0

const LEFT_X := MARGIN
const LEFT_W := 286.0

const RIGHT_W := 251.0
const RIGHT_X := MARGIN + CONTENT_W - RIGHT_W

const MID_X := LEFT_X + LEFT_W + BOTTOM_GAP
const MID_W := RIGHT_X - BOTTOM_GAP - MID_X


# ============================================================
# 节点引用
# ============================================================

var state: SiegeState

var top_left_label: Label
var top_right_label: Label
var own_status_label: Label

var main_zone_box: HBoxContainer
var special_zone_box: VBoxContainer
var tab_box: HBoxContainer
var hand_area_box: VBoxContainer
var side_action_box: VBoxContainer
var log_box: RichTextLabel
var selection_label: Label
var confirm_dialog: ConfirmationDialog

var selected_base_action := ""
var selected_card: Dictionary = {}
var active_tab := "deploy"
var pending_action: Dictionary = {}


func _ready() -> void:
	setup_window()
	randomize()
	state = SiegeStateScript.new()
	build_ui()
	refresh_ui()


func setup_window() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	Engine.max_fps = 60

	var window := get_window()
	if window == null:
		return

	window.min_size = MIN_WINDOW_SIZE
	window.size = WINDOW_SIZE
	window.move_to_center()


func build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	build_top_bar()
	build_battlefield()
	build_bottom_area()
	build_confirm_dialog()


# ============================================================
# 顶部状态栏
# ============================================================

func build_top_bar() -> void:
	var top_panel := PanelContainer.new()
	set_rect(top_panel, TOP_X, TOP_Y, TOP_W, TOP_H)
	top_panel.add_theme_stylebox_override("panel", make_style(COLOR_TOP_BAR, Color("35475c"), 2, 12))
	add_child(top_panel)

	var top_margin := make_margin_container(TOP_PANEL_PADDING_X, 0, TOP_PANEL_PADDING_X, 0)
	top_panel.add_child(top_margin)

	var top_box := HBoxContainer.new()
	top_box.add_theme_constant_override("separation", 20)
	top_margin.add_child(top_box)

	top_left_label = Label.new()
	top_left_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_left_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_left_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_left_label.add_theme_font_size_override("font_size", FONT_TOP)
	top_left_label.add_theme_color_override("font_color", COLOR_TEXT_LIGHT)
	top_box.add_child(top_left_label)

	top_right_label = Label.new()
	top_right_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_right_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_right_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_right_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_right_label.add_theme_font_size_override("font_size", FONT_TOP)
	top_right_label.add_theme_color_override("font_color", COLOR_TEXT_LIGHT)
	top_box.add_child(top_right_label)


# ============================================================
# 中部战场
# ============================================================

func build_battlefield() -> void:
	main_zone_box = HBoxContainer.new()
	set_rect(main_zone_box, MAIN_ZONE_X, BATTLE_Y, MAIN_ZONE_TOTAL_W, BATTLE_H)
	main_zone_box.add_theme_constant_override("separation", int(MAIN_ZONE_GAP))
	add_child(main_zone_box)

	special_zone_box = VBoxContainer.new()
	set_rect(special_zone_box, SPECIAL_ZONE_X, BATTLE_Y, SPECIAL_ZONE_W, BATTLE_H)
	special_zone_box.add_theme_constant_override("separation", int(SPECIAL_ZONE_GAP))
	add_child(special_zone_box)


# ============================================================
# 底部区域
# ============================================================

func build_bottom_area() -> void:
	build_own_status_area()
	build_log_and_tab_area()
	build_hand_area_panel()
	build_side_action_area()


func build_own_status_area() -> void:
	var own_status_panel := PanelContainer.new()
	set_rect(own_status_panel, STATUS_X, STATUS_Y, STATUS_W, STATUS_H)
	own_status_panel.add_theme_stylebox_override("panel", make_style(COLOR_TOP_BAR, Color("35475c"), 2, 10))
	add_child(own_status_panel)

	var margin := make_margin_container(18, 0, 18, 0)
	own_status_panel.add_child(margin)

	own_status_label = Label.new()
	own_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	own_status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	own_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	own_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	own_status_label.add_theme_font_size_override("font_size", FONT_TOP)
	own_status_label.add_theme_color_override("font_color", COLOR_TEXT_LIGHT)
	margin.add_child(own_status_label)


func build_log_and_tab_area() -> void:
	var left_panel := PanelContainer.new()
	set_rect(left_panel, LEFT_X, BOTTOM_Y, LEFT_W, BOTTOM_H)
	left_panel.add_theme_stylebox_override("panel", make_style(COLOR_PANEL_2, COLOR_BORDER, 2, 10))
	add_child(left_panel)

	var margin := make_margin_container(PANEL_PADDING)
	left_panel.add_child(margin)

	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 10)
	margin.add_child(left_box)

	tab_box = HBoxContainer.new()
	tab_box.add_theme_constant_override("separation", 10)
	left_box.add_child(tab_box)

	var log_title := Label.new()
	log_title.text = "日志"
	log_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_title.add_theme_font_size_override("font_size", FONT_TOP)
	log_title.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	left_box.add_child(log_title)

	log_box = RichTextLabel.new()
	log_box.custom_minimum_size = Vector2(0, 200)
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.bbcode_enabled = true
	log_box.scroll_active = true
	log_box.add_theme_font_size_override("normal_font_size", FONT_SMALL)
	log_box.add_theme_color_override("default_color", COLOR_TEXT_DARK)
	left_box.add_child(log_box)


func build_hand_area_panel() -> void:
	var hand_panel := PanelContainer.new()
	set_rect(hand_panel, MID_X, BOTTOM_Y, MID_W, BOTTOM_H)
	hand_panel.add_theme_stylebox_override("panel", make_style(COLOR_PANEL, COLOR_BORDER, 2, 10))
	add_child(hand_panel)

	var margin := make_margin_container(PANEL_PADDING)
	hand_panel.add_child(margin)

	var hand_scroll := ScrollContainer.new()
	hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(hand_scroll)

	hand_area_box = VBoxContainer.new()
	hand_area_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_area_box.add_theme_constant_override("separation", 14)
	hand_area_box.custom_minimum_size = Vector2(MID_W - PANEL_PADDING * 4, BOTTOM_H - PANEL_PADDING * 4)
	hand_scroll.add_child(hand_area_box)


func build_side_action_area() -> void:
	var action_panel := PanelContainer.new()
	set_rect(action_panel, RIGHT_X, BOTTOM_Y, RIGHT_W, BOTTOM_H)
	action_panel.add_theme_stylebox_override("panel", make_style(COLOR_PANEL_2, COLOR_BORDER, 2, 10))
	add_child(action_panel)

	var margin := make_margin_container(PANEL_PADDING)
	action_panel.add_child(margin)

	side_action_box = VBoxContainer.new()
	side_action_box.add_theme_constant_override("separation", 12)
	margin.add_child(side_action_box)


func build_confirm_dialog() -> void:
	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "确认操作"
	confirm_dialog.min_size = Vector2i(560, 240)
	confirm_dialog.confirmed.connect(_on_confirm_dialog_confirmed)
	add_child(confirm_dialog)

	confirm_dialog.get_ok_button().text = "确认"
	confirm_dialog.get_cancel_button().text = "取消"


# ============================================================
# 刷新 UI
# ============================================================

func refresh_ui() -> void:
	top_left_label.text = "第 %d 日｜%s｜%s" % [
		state.day,
		state.today_weather,
		get_phase_text(),
	]

	var own_side := state.current_side
	var enemy_side := "defender" if own_side == "attacker" else "attacker"

	top_right_label.text = "敌方｜%s" % get_side_status_text(enemy_side)

	if own_status_label != null:
		own_status_label.text = "我方｜%s" % get_side_status_text(own_side)

	rebuild_zones()
	rebuild_tabs()
	rebuild_hand_area()
	rebuild_side_actions()
	refresh_log()


func get_phase_text() -> String:
	return "攻方阶段" if state.current_side == "attacker" else "守方阶段"


func get_side_status_text(side: String) -> String:
	if side == "attacker":
		return "攻方：补给 %d｜士气 %d｜指挥点 %d｜预备点 %d" % [
			state.attacker_supply,
			state.attacker_morale,
			state.attacker_cp,
			state.attacker_reserve,
		]

	return "守方：粮秣 %d｜士气 %d｜指挥点 %d｜预备点 %d" % [
		state.defender_grain,
		state.defender_morale,
		state.defender_cp,
		state.defender_reserve,
	]


# ============================================================
# 战区
# ============================================================

func rebuild_zones() -> void:
	for child in main_zone_box.get_children():
		child.queue_free()

	for zone_id in SiegeData.MAIN_ZONES:
		main_zone_box.add_child(make_main_zone_button(zone_id))

	for child in special_zone_box.get_children():
		child.queue_free()

	special_zone_box.add_child(make_special_zone_button("tunnel", get_tunnel_title_text(), get_special_zone_body_text("tunnel")))
	special_zone_box.add_child(make_special_zone_button("shore", "岸防", "暂未开放"))
	special_zone_box.add_child(make_special_zone_button("attacker_back", "攻方后阵", get_special_zone_body_text("attacker_back")))


func make_main_zone_button(zone_id: String) -> Button:
	var wall: Dictionary = state.walls[zone_id]

	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(MAIN_ZONE_W, BATTLE_H)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_filter = Control.MOUSE_FILTER_STOP

	button.add_theme_stylebox_override("normal", make_style(get_zone_color(zone_id), COLOR_BORDER, 2, 10))
	button.add_theme_stylebox_override("hover", make_style(COLOR_ZONE_HOVER, COLOR_ACCENT, 3, 10))
	button.add_theme_stylebox_override("pressed", make_style(COLOR_ZONE_ACTIVE, COLOR_ACCENT, 3, 10))

	button.pressed.connect(_on_zone_clicked.bind(zone_id))

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8
	box.offset_top = 8
	box.offset_right = -8
	box.offset_bottom = -8
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)

	var header_panel := PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 48)
	header_panel.add_theme_stylebox_override("panel", make_style(COLOR_HEADER, COLOR_BORDER, 1, 8))
	header_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(header_panel)

	var header := Label.new()
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", FONT_ZONE_TITLE)
	header.add_theme_color_override("font_color", COLOR_HEADER_TEXT)
	header.text = "%s  %d/%d%s" % [
		wall["name"],
		int(wall["current"]),
		int(wall["max"]),
		get_zone_state_suffix(zone_id),
	]
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_panel.add_child(header)

	box.add_child(make_side_piece_panel(zone_id, "defender", "守方", COLOR_DEFENDER_AREA))
	box.add_child(make_side_piece_panel(zone_id, "attacker", "攻方", COLOR_ATTACKER_AREA))

	return button


func make_side_piece_panel(zone_id: String, side: String, title: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", make_style(color, Color("7e6a59"), 1, 8))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", FONT_SMALL)
	label.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	label.text = title + "：\n" + get_zone_side_pieces_text(zone_id, side)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)

	return panel


func make_special_zone_button(zone_id: String, title: String, subtext: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(SPECIAL_ZONE_W, SPECIAL_ZONE_H)
	button.text = "%s\n%s" % [title, subtext]

	button.add_theme_font_size_override("font_size", FONT_BUTTON)
	button.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT_DARK)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT_DARK)

	button.add_theme_stylebox_override("normal", make_style(Color("e6d1b7"), COLOR_BORDER, 2, 10))
	button.add_theme_stylebox_override("hover", make_style(Color("f0dec6"), COLOR_ACCENT, 3, 10))
	button.add_theme_stylebox_override("pressed", make_style(Color("ffd98e"), COLOR_ACCENT, 3, 10))

	button.pressed.connect(_on_zone_clicked.bind(zone_id))

	return button


func get_zone_color(zone_id: String) -> Color:
	if selected_base_action != "" and is_main_zone(zone_id):
		return Color("edd7b8")

	if not selected_card.is_empty() and is_zone_valid_for_selected_card(zone_id):
		return Color("edd7b8")

	return COLOR_ZONE


func get_zone_state_suffix(zone_id: String) -> String:
	if bool(state.breakthrough_zones[zone_id]):
		return "｜突破"

	if int(state.walls[zone_id]["current"]) <= 0:
		return "｜破口"

	return ""


func get_zone_side_pieces_text(zone_id: String, side: String) -> String:
	if not state.pieces.has(zone_id):
		return "无"

	var parts: Array[String] = []

	for piece in state.pieces[zone_id]:
		if String(piece["side"]) != side:
			continue

		parts.append("%s  HP%d/%d  战%d 工%d" % [
			piece["name"],
			int(piece["hp"]),
			int(piece["max_hp"]),
			int(piece["battle"]),
			int(piece["engineering"]),
		])

	if parts.is_empty():
		return "无"

	return "\n".join(parts)


func get_zone_piece_count_text(zone_id: String) -> String:
	if not state.pieces.has(zone_id) or state.pieces[zone_id].is_empty():
		return "无部署物"

	return "%d 个部署物" % state.pieces[zone_id].size()


func get_tunnel_title_text() -> String:
	if state.current_side == "defender":
		return "地道（进度？/5）"

	return "地道（进度%d/5）" % state.tunnel_progress


func get_special_zone_body_text(zone_id: String) -> String:
	if zone_id == "shore":
		return "暂未开放"

	if not state.pieces.has(zone_id) or state.pieces[zone_id].is_empty():
		return "无部署物"

	var parts: Array[String] = []

	for piece in state.pieces[zone_id]:
		var side_name := "攻" if String(piece["side"]) == "attacker" else "守"

		parts.append("%s｜%s HP%d/%d 战%d 工%d" % [
			side_name,
			piece["name"],
			int(piece["hp"]),
			int(piece["max_hp"]),
			int(piece["battle"]),
			int(piece["engineering"]),
		])

	return "\n".join(parts)


# ============================================================
# 标签页与手牌区
# ============================================================

func rebuild_tabs() -> void:
	for child in tab_box.get_children():
		child.queue_free()

	tab_box.add_child(make_tab_button("部署", "deploy"))
	tab_box.add_child(make_tab_button("命令", "command"))


func make_tab_button(text: String, tab_id: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 64)

	button.add_theme_font_size_override("font_size", FONT_BUTTON)
	button.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT_DARK)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT_DARK)

	var color := COLOR_BUTTON_ACTIVE if active_tab == tab_id else Color("efe1cb")

	button.add_theme_stylebox_override("normal", make_style(color, COLOR_BORDER, 1, 8))
	button.add_theme_stylebox_override("hover", make_style(Color("fff0cf"), COLOR_ACCENT, 2, 8))

	button.pressed.connect(_on_tab_pressed.bind(tab_id))

	return button


func _on_tab_pressed(tab_id: String) -> void:
	active_tab = tab_id
	selected_base_action = ""
	selected_card.clear()
	pending_action.clear()
	refresh_ui()


func rebuild_hand_area() -> void:
	for child in hand_area_box.get_children():
		child.queue_free()

	if active_tab == "deploy":
		build_deploy_area()
	else:
		build_command_area()


func build_deploy_area() -> void:
	add_hand_title("部署牌｜选择卡牌，再点击可部署区域")

	selection_label = make_selection_label()
	hand_area_box.add_child(selection_label)

	var grid := make_card_grid(5)

	for card in get_deploy_cards_for_current_side():
		grid.add_child(make_deploy_card_button(card))


func build_command_area() -> void:
	add_hand_title("命令牌｜当前为占位卡牌，后续接入真实效果")

	selection_label = make_selection_label()
	hand_area_box.add_child(selection_label)

	var grid := make_card_grid(5)

	for card in get_command_cards_for_current_side():
		grid.add_child(make_command_card_button(card))


func add_hand_title(text: String) -> void:
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", FONT_TOP)
	title.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	title.text = text
	hand_area_box.add_child(title)


func make_selection_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", FONT_NORMAL)
	label.add_theme_color_override("font_color", Color("5b3b1f"))

	if selected_base_action != "":
		label.text = "已选择基础行动：%s。请点击战区，然后确认。" % get_selected_action_text()
	elif not selected_card.is_empty():
		label.text = "已选择卡牌：%s。可放置区域：%s。" % [
			selected_card["name"],
			get_card_zone_names(selected_card),
		]
	else:
		label.text = "未选择。"

	return label


func make_card_grid(columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	hand_area_box.add_child(grid)

	return grid


func make_deploy_card_button(card: Dictionary) -> Button:
	var disabled := not can_pay_card(card)
	var selected := is_selected_card(card)

	var button := make_card_button(card, disabled, selected)
	button.pressed.connect(_on_deploy_card_pressed.bind(card.duplicate(true)))

	return button


func make_command_card_button(card: Dictionary) -> Button:
	var button := make_card_button(card, true, false)
	button.tooltip_text = "命令牌系统还未接入。"
	return button


func make_card_button(card: Dictionary, disabled: bool, selected: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(205, 178)
	button.disabled = disabled

	button.text = "%s\n\n费用：%s\n%s\n\n%s" % [
		card.get("name", "未知"),
		get_cost_text(card),
		card.get("type_text", "部署"),
		card.get("desc", ""),
	]

	button.add_theme_font_size_override("font_size", FONT_CARD_BODY)
	button.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT_DARK)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT_DARK)
	button.add_theme_color_override("font_disabled_color", Color("545454"))

	var bg := COLOR_CARD_SELECTED if selected else COLOR_CARD

	button.add_theme_stylebox_override("normal", make_style(bg, COLOR_BORDER, 2, 12))
	button.add_theme_stylebox_override("hover", make_style(Color("fff0c2"), COLOR_ACCENT, 3, 12))
	button.add_theme_stylebox_override("pressed", make_style(Color("ffd879"), COLOR_ACCENT, 3, 12))
	button.add_theme_stylebox_override("disabled", make_style(Color("c7c0b5"), Color("6a635b"), 1, 12))

	return button


func get_deploy_cards_for_current_side() -> Array[Dictionary]:
	if state.current_side == "attacker":
		return [
			make_card("步兵队", "attacker", "attacker_infantry", 1, 0, 0, ["left", "gate", "right"], "部署攻方步兵。\n战2｜工0｜耐2"),
			make_card("工兵", "attacker", "attacker_engineer", 1, 0, 0, ["gate", "tunnel"], "主门作业或挖地道。\n战1｜工2｜耐1"),
			make_card("云梯", "attacker", "ladder", 1, 0, 0, ["left", "right"], "所在战区登城费用 -1。"),
			make_card("冲车", "attacker", "ram", 2, 1, 0, ["gate"], "主门攻城器械。\n部署额外消耗补给。"),
			make_card("炮队", "attacker", "cannon", 2, 1, 0, ["attacker_back"], "远程攻城器械。\n部署到攻方后阵。"),
		]

	return [
		make_card("守军", "defender", "defender_guard", 1, 0, 0, ["left", "gate", "right"], "部署守方战斗单位。\n战2｜工0｜耐2"),
		make_card("工匠", "defender", "defender_worker", 1, 0, 0, ["left", "gate", "right", "tunnel"], "修补城防或封堵地道。\n战0｜工2｜耐1"),
		make_card("塔楼弓手", "defender", "tower_archer", 1, 0, 0, ["left", "right"], "部署在墙段。\n可射击同战区目标。"),
		make_card("滚木擂石", "defender", "rolling_logs", 1, 0, 0, ["left", "gate", "right"], "登城时触发的防御器械。"),
	]


func get_command_cards_for_current_side() -> Array[Dictionary]:
	if state.current_side == "attacker":
		return [
			make_command_placeholder("集中强攻", "选择有攻方单位的主战区，造成普通破坏。"),
			make_command_placeholder("掘进", "如果地道有工兵，推进地道。"),
			make_command_placeholder("炮火校准", "强化下一次炮击。"),
			make_command_placeholder("护卫器械", "减少下一次器械受到的伤害。"),
			make_command_placeholder("声东击西", "移动守方单位，制造空档。"),
		]

	return [
		make_command_placeholder("修补城防", "有工匠时高效修补城防。"),
		make_command_placeholder("封堵地道", "有工匠时降低地道进度。"),
		make_command_placeholder("齐射", "对同战区攻方单位造成伤害。"),
		make_command_placeholder("预备队", "在破口处部署守军并清除突破。"),
		make_command_placeholder("坚壁清野", "牺牲守方士气，削弱攻方补给。"),
	]


func make_card(
	name: String,
	side: String,
	kind: String,
	cp_cost: int,
	supply_cost: int,
	grain_cost: int,
	zones: Array,
	desc: String
) -> Dictionary:
	return {
		"name": name,
		"type": "deploy",
		"type_text": "部署牌",
		"side": side,
		"kind": kind,
		"cp_cost": cp_cost,
		"supply_cost": supply_cost,
		"grain_cost": grain_cost,
		"zones": zones,
		"desc": desc,
	}


func make_command_placeholder(name: String, desc: String) -> Dictionary:
	return {
		"name": name,
		"type": "command",
		"type_text": "命令牌｜未接入",
		"cp_cost": 1,
		"supply_cost": 0,
		"grain_cost": 0,
		"zones": [],
		"desc": desc,
	}


func can_pay_card(card: Dictionary) -> bool:
	if state.game_over:
		return false

	if String(card["side"]) == "attacker":
		return state.current_side == "attacker" \
			and state.attacker_cp >= int(card["cp_cost"]) \
			and state.attacker_supply >= int(card["supply_cost"])

	return state.current_side == "defender" \
		and state.defender_cp >= int(card["cp_cost"]) \
		and state.defender_grain >= int(card["grain_cost"])


func get_cost_text(card: Dictionary) -> String:
	var parts: Array[String] = []

	var cp_cost := int(card.get("cp_cost", 0))
	var supply_cost := int(card.get("supply_cost", 0))
	var grain_cost := int(card.get("grain_cost", 0))

	if cp_cost > 0:
		parts.append("%d 指挥" % cp_cost)

	if supply_cost > 0:
		parts.append("%d 补给" % supply_cost)

	if grain_cost > 0:
		parts.append("%d 粮秣" % grain_cost)

	if parts.is_empty():
		return "0"

	return " + ".join(parts)


func _on_deploy_card_pressed(card: Dictionary) -> void:
	selected_base_action = ""
	selected_card = card
	pending_action.clear()
	refresh_ui()


func is_selected_card(card: Dictionary) -> bool:
	if selected_card.is_empty():
		return false

	return String(selected_card.get("name", "")) == String(card.get("name", "")) \
		and String(selected_card.get("side", "")) == String(card.get("side", ""))


func is_zone_valid_for_selected_card(zone_id: String) -> bool:
	if selected_card.is_empty():
		return false

	var zones: Array = selected_card.get("zones", [])
	return zones.has(zone_id)


func get_card_zone_names(card: Dictionary) -> String:
	var zones: Array = card.get("zones", [])
	var names: Array[String] = []

	for zone_id in zones:
		if String(zone_id) == "shore":
			names.append("岸防")
		else:
			names.append(SiegeData.get_zone_name(String(zone_id)))

	return "、".join(names)


# ============================================================
# 右侧基础行动
# ============================================================

func rebuild_side_actions() -> void:
	for child in side_action_box.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "基础行动"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", FONT_TOP)
	title.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	side_action_box.add_child(title)

	if state.game_over:
		var label := Label.new()
		label.text = "游戏结束"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", FONT_BUTTON)
		label.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		side_action_box.add_child(label)
		return

	if state.current_side == "attacker":
		side_action_box.add_child(make_mode_button("强攻", "assault", state.attacker_cp < 1))
		side_action_box.add_child(make_mode_button("登城", "climb", state.attacker_cp < 1))
		side_action_box.add_child(make_reserve_button())
		side_action_box.add_child(make_end_button("结束攻方阶段"))
	else:
		side_action_box.add_child(make_mode_button("修补", "repair", state.defender_cp < 1))
		side_action_box.add_child(make_mode_button("反击", "counter", state.defender_cp < 1 and state.defender_reserve < 1))
		side_action_box.add_child(make_reserve_button())
		side_action_box.add_child(make_end_button("结束本日"))


func make_mode_button(text: String, action_id: String, disabled: bool) -> Button:
	var button := make_large_button(text, disabled)

	if selected_base_action == action_id:
		button.add_theme_stylebox_override("normal", make_style(COLOR_BUTTON_ACTIVE, COLOR_BORDER, 2, 10))

	button.pressed.connect(_on_action_mode_pressed.bind(action_id))

	return button


func make_reserve_button() -> Button:
	var disabled := false

	if state.current_side == "attacker":
		disabled = state.attacker_cp < 1
	else:
		disabled = state.defender_cp < 1

	var button := make_large_button("待机\n转 1 预备", disabled)
	button.pressed.connect(_on_reserve_pressed)

	return button


func make_end_button(text: String) -> Button:
	var button := make_large_button(text, false)

	button.add_theme_stylebox_override("normal", make_style(COLOR_END_BUTTON, COLOR_BORDER, 1, 10))
	button.add_theme_stylebox_override("hover", make_style(COLOR_END_BUTTON_HOVER, COLOR_ACCENT, 2, 10))
	button.add_theme_stylebox_override("pressed", make_style(Color("d67d58"), COLOR_ACCENT, 2, 10))

	button.pressed.connect(_on_end_pressed)

	return button


func make_large_button(text: String, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.custom_minimum_size = Vector2(210, 60)

	button.add_theme_font_size_override("font_size", FONT_BUTTON)

	button.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT_DARK)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT_DARK)
	button.add_theme_color_override("font_disabled_color", Color("505050"))

	button.add_theme_stylebox_override("normal", make_style(COLOR_BUTTON, COLOR_BORDER, 1, 10))
	button.add_theme_stylebox_override("hover", make_style(COLOR_BUTTON_HOVER, COLOR_ACCENT, 2, 10))
	button.add_theme_stylebox_override("pressed", make_style(Color("c8d8ed"), COLOR_ACCENT, 2, 10))
	button.add_theme_stylebox_override("disabled", make_style(Color("b8c0ca"), Color("7a8490"), 1, 10))

	return button


func _on_action_mode_pressed(action_id: String) -> void:
	selected_card.clear()
	pending_action.clear()

	if selected_base_action == action_id:
		selected_base_action = ""
	else:
		selected_base_action = action_id

	refresh_ui()


func _on_reserve_pressed() -> void:
	pending_action = {
		"type": "reserve",
	}

	confirm_dialog.dialog_text = "确认将当前阶段的 1 点指挥点转为 1 点预备点？"
	confirm_dialog.popup_centered(Vector2i(560, 220))


func _on_end_pressed() -> void:
	if state.current_side == "attacker":
		pending_action = {
			"type": "end_attacker_phase",
		}

		confirm_dialog.dialog_text = "确认结束攻方阶段？\n结束后将进入守方阶段。"
	else:
		pending_action = {
			"type": "end_day",
		}

		confirm_dialog.dialog_text = "确认结束本日？\n若存在突破标记，攻方将在结算中获胜。"

	confirm_dialog.popup_centered(Vector2i(560, 240))


# ============================================================
# 点击战区后的确认
# ============================================================

func _on_zone_clicked(zone_id: String) -> void:
	if selected_base_action == "" and selected_card.is_empty():
		return

	if selected_base_action != "":
		if not is_main_zone(zone_id):
			return

		prepare_base_action_confirmation(zone_id)
		return

	if not selected_card.is_empty():
		if not is_zone_valid_for_selected_card(zone_id):
			add_state_log("%s不能部署到%s。" % [
				selected_card["name"],
				get_display_zone_name(zone_id),
			])
			refresh_ui()
			return

		prepare_deploy_confirmation(zone_id)


func prepare_base_action_confirmation(zone_id: String) -> void:
	pending_action = {
		"type": "base_action",
		"action": selected_base_action,
		"zone_id": zone_id,
	}

	confirm_dialog.dialog_text = "确认执行：%s → %s？" % [
		get_selected_action_text(),
		get_display_zone_name(zone_id),
	]

	confirm_dialog.popup_centered(Vector2i(560, 220))


func prepare_deploy_confirmation(zone_id: String) -> void:
	pending_action = {
		"type": "deploy",
		"zone_id": zone_id,
		"card": selected_card.duplicate(true),
	}

	confirm_dialog.dialog_text = "确认部署：%s → %s？\n费用：%s" % [
		selected_card["name"],
		get_display_zone_name(zone_id),
		get_cost_text(selected_card),
	]

	confirm_dialog.popup_centered(Vector2i(560, 240))


func _on_confirm_dialog_confirmed() -> void:
	if pending_action.is_empty():
		return

	var action_type := String(pending_action.get("type", ""))

	match action_type:
		"base_action":
			resolve_base_action(
				String(pending_action["action"]),
				String(pending_action["zone_id"])
			)

		"deploy":
			var card: Dictionary = pending_action["card"]

			SiegeRules.deploy_piece(
				state,
				String(pending_action["zone_id"]),
				String(card["side"]),
				String(card["kind"]),
				int(card["cp_cost"]),
				int(card["supply_cost"]),
				int(card["grain_cost"])
			)

		"reserve":
			SiegeRules.pass_action(state)

		"end_attacker_phase":
			SiegeRules.end_attacker_phase(state)

		"end_day":
			SiegeRules.end_day(state)

	pending_action.clear()
	selected_base_action = ""
	selected_card.clear()

	refresh_ui()


func resolve_base_action(action_id: String, zone_id: String) -> void:
	match action_id:
		"assault":
			SiegeRules.attacker_assault(state, zone_id)

		"climb":
			SiegeRules.attacker_climb(state, zone_id)

		"repair":
			SiegeRules.defender_repair(state, zone_id)

		"counter":
			SiegeRules.defender_counterattack(state, zone_id)


func get_selected_action_text() -> String:
	match selected_base_action:
		"assault":
			return "强攻"

		"climb":
			return "登城"

		"repair":
			return "修补"

		"counter":
			return "反击"

		_:
			return "无"


func get_display_zone_name(zone_id: String) -> String:
	if zone_id == "shore":
		return "岸防"

	return SiegeData.get_zone_name(zone_id)


func is_main_zone(zone_id: String) -> bool:
	return SiegeData.MAIN_ZONES.has(zone_id)


# ============================================================
# 日志
# ============================================================

func refresh_log() -> void:
	log_box.clear()
	log_box.append_text(state.get_log_text())
	log_box.scroll_to_line(log_box.get_line_count())


func add_state_log(text: String) -> void:
	if state == null:
		return

	if state.has_method("add_log"):
		state.call("add_log", text)
	elif state.has_method("log"):
		state.call("log", text)


# ============================================================
# 布局工具函数
# ============================================================

func set_rect(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.position = Vector2(x, y)
	node.size = Vector2(w, h)


func make_margin_container(
	left: int = PANEL_PADDING,
	top: int = PANEL_PADDING,
	right: int = PANEL_PADDING,
	bottom: int = PANEL_PADDING
) -> MarginContainer:
	var margin := MarginContainer.new()

	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)

	return margin


func make_style(
	bg: Color,
	border: Color,
	border_width: int = 1,
	radius: int = 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)

	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius

	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	return style
