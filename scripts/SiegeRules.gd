extends RefCounted
class_name SiegeRules

const SiegeData := preload("res://scripts/SiegeData.gd")


static func attacker_assault(state: SiegeState, zone_id: String) -> void:
	if state.game_over or state.current_side != "attacker":
		return

	if state.attacker_cp < 1:
		state.add_log("攻方指挥点不足。")
		return

	state.attacker_cp -= 1

	var damage := 2

	if state.today_weather == "暴雨":
		damage = max(1, damage - 1)

	state.walls[zone_id]["current"] = max(0, int(state.walls[zone_id]["current"]) - damage)

	state.add_log("攻方强攻%s，造成 %d 点普通破坏。" % [
		state.walls[zone_id]["name"],
		damage
	])


static func attacker_climb(state: SiegeState, zone_id: String) -> void:
	if state.game_over or state.current_side != "attacker":
		return

	var climb_cost := 2

	if has_attacker_ladder(state, zone_id):
		climb_cost = 1

	if state.attacker_cp < climb_cost:
		state.add_log("攻方指挥点不足，无法登城。")
		return

	if int(state.walls[zone_id]["current"]) > 0:
		state.add_log("%s尚未破口，不能登城。" % state.walls[zone_id]["name"])
		return

	if bool(state.breakthrough_zones[zone_id]):
		state.add_log("%s已经有突破标记。" % state.walls[zone_id]["name"])
		return

	state.attacker_cp -= climb_cost
	state.breakthrough_zones[zone_id] = true

	if climb_cost == 1:
		state.add_log("攻方借助云梯在%s登城，放置突破标记！" % state.walls[zone_id]["name"])
	else:
		state.add_log("攻方在%s登城，放置突破标记！" % state.walls[zone_id]["name"])


static func defender_repair(state: SiegeState, zone_id: String) -> void:
	if state.game_over or state.current_side != "defender":
		return

	if state.defender_cp < 1:
		state.add_log("守方指挥点不足。")
		return

	state.defender_cp -= 1

	var repair_amount := 2
	state.walls[zone_id]["current"] = min(
		int(state.walls[zone_id]["max"]),
		int(state.walls[zone_id]["current"]) + repair_amount
	)

	state.add_log("守方修补%s，恢复 %d 点当前城防。" % [
		state.walls[zone_id]["name"],
		repair_amount
	])


static func defender_counterattack(state: SiegeState, zone_id: String) -> void:
	if state.game_over or state.current_side != "defender":
		return

	if not bool(state.breakthrough_zones[zone_id]):
		state.add_log("该战区没有突破标记。")
		return

	if state.defender_cp >= 1:
		state.defender_cp -= 1
	elif state.defender_reserve >= 1:
		state.defender_reserve -= 1
	else:
		state.add_log("守方没有指挥点或预备点，无法反击。")
		return

	state.breakthrough_zones[zone_id] = false
	state.add_log("守方在%s反击成功，移除了突破标记。" % state.walls[zone_id]["name"])


static func pass_action(state: SiegeState) -> void:
	if state.game_over:
		return

	if state.current_side == "attacker":
		if state.attacker_cp > 0:
			state.attacker_cp -= 1
			state.attacker_reserve += 1
			state.add_log("攻方待机，将 1 点指挥点转为预备点。")
		else:
			state.add_log("攻方已经没有指挥点。")
	else:
		if state.defender_cp > 0:
			state.defender_cp -= 1
			state.defender_reserve += 1
			state.add_log("守方待机，将 1 点指挥点转为预备点。")
		else:
			state.add_log("守方已经没有指挥点。")


static func end_attacker_phase(state: SiegeState) -> void:
	if state.game_over:
		return

	if state.current_side != "attacker":
		return

	state.current_side = "defender"
	state.consecutive_passes = 0
	state.add_log("攻方阶段结束。守方开始应对攻势。")


static func end_day(state: SiegeState) -> void:
	if state.game_over:
		return

	state.add_log("第 %d 日进入结算。" % state.day)

	if state.has_any_breakthrough():
		state.game_over = true
		state.add_log("[color=red]攻方胜利！以下突破标记未被清除：%s。城池陷落。[/color]" % state.get_breakthrough_text())
		return

	consume_long_term_resources(state)

	if state.attacker_morale <= 0:
		state.game_over = true
		state.add_log("[color=blue]守方胜利！攻方士气崩溃。[/color]")
		return

	if state.defender_morale <= 0:
		state.game_over = true
		state.add_log("[color=red]攻方胜利！守方士气崩溃。[/color]")
		return

	if state.day >= SiegeData.MAX_DAY:
		state.game_over = true
		state.add_log("[color=blue]守方胜利！援军抵达，城池守住。[/color]")
		return

	state.day += 1
	begin_next_day(state)


static func consume_long_term_resources(state: SiegeState) -> void:
	if state.attacker_supply > 0:
		state.attacker_supply -= 1
		state.add_log("攻方消耗 1 补给。")
	else:
		state.attacker_morale -= 1
		state.add_log("攻方补给耗尽，士气 -1。")

	if state.defender_grain > 0:
		state.defender_grain -= 1
		state.add_log("守方消耗 1 粮秣。")
	else:
		state.defender_morale -= 1
		state.add_log("守方粮秣耗尽，士气 -1。")


static func begin_next_day(state: SiegeState) -> void:
	state.today_weather = state.tomorrow_weather
	state.tomorrow_weather = SiegeData.WEATHER_POOL.pick_random()

	state.attacker_cp = 4
	state.defender_cp = 3
	state.attacker_reserve = 0
	state.defender_reserve = 0
	state.consecutive_passes = 0
	state.current_side = "attacker"

	state.add_log("第 %d 日开始。今日天气：%s。攻方阶段开始。" % [state.day, state.today_weather])


static func create_piece(state: SiegeState, side: String, kind: String) -> Dictionary:
	if not SiegeData.PIECE_TEMPLATES.has(kind):
		push_error("未知部署物类型：" + kind)
		return {}

	var template: Dictionary = SiegeData.PIECE_TEMPLATES[kind]

	var piece := {
		"id": state.next_piece_id,
		"side": side,
		"kind": kind,
		"name": template["name"],
		"battle": template["battle"],
		"engineering": template["engineering"],
		"hp": template["hp"],
		"max_hp": template["max_hp"],
		"is_equipment": template["is_equipment"],
	}

	state.next_piece_id += 1
	return piece


static func deploy_piece(
	state: SiegeState,
	zone_id: String,
	side: String,
	kind: String,
	cp_cost: int,
	supply_cost: int = 0,
	grain_cost: int = 0
) -> void:
	if state.game_over:
		return

	if side == "attacker":
		if state.current_side != "attacker":
			return

		if state.attacker_cp < cp_cost:
			state.add_log("攻方指挥点不足，无法部署。")
			return

		if state.attacker_supply < supply_cost:
			state.add_log("攻方补给不足，无法部署。")
			return

		state.attacker_cp -= cp_cost
		state.attacker_supply -= supply_cost
	else:
		if state.current_side != "defender":
			return

		if state.defender_cp < cp_cost:
			state.add_log("守方指挥点不足，无法部署。")
			return

		if state.defender_grain < grain_cost:
			state.add_log("守方粮秣不足，无法部署。")
			return

		state.defender_cp -= cp_cost
		state.defender_grain -= grain_cost

	var piece := create_piece(state, side, kind)
	state.pieces[zone_id].append(piece)

	state.add_log("%s在%s部署了%s。" % [
		"攻方" if side == "attacker" else "守方",
		SiegeData.get_zone_name(zone_id),
		piece["name"]
	])


static func has_attacker_ladder(state: SiegeState, zone_id: String) -> bool:
	if not state.pieces.has(zone_id):
		return false

	for piece in state.pieces[zone_id]:
		if piece["side"] == "attacker" and piece["kind"] == "ladder":
			return true

	return false
