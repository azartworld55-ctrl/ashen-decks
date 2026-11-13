extends SceneTree

const RunStateScript = preload("res://scripts/run_state.gd")

func _initialize() -> void:
	var state = RunStateScript.new()
	state.start_combat()

	assert(state.player_hp == 60, "Player should start with 60 HP")
	assert(state.energy == 3, "Player should start with 3 energy")
	assert(state.hand.size() == 5, "Opening hand should contain five cards")
	assert(state.enemy_hp == 42, "Test enemy should start with 42 HP")

	state.hand.clear()
	state.hand.append({
		"name": "Проверочный удар",
		"cost": 1,
		"description": "Проверка блока.",
		"type": "attack",
		"damage": 6,
		"block": 0,
		"heal": 0
	})
	state.enemy_block = 4
	state.energy = 3

	assert(state.play_card(0), "Test attack should resolve")
	assert(state.enemy_hp == 40, "Enemy block should absorb four of six damage")
	assert(state.enemy_block == 0, "Enemy block should be consumed")
	assert(state.hand.is_empty(), "Played card should leave the hand")

	state.end_turn()
	assert(state.turn == 2, "Turn counter should advance")
	assert(state.hand.size() == 5, "Next turn should draw a new hand")
	assert(state.phase == "player", "Player should regain control after enemy turn")

	print("Godot combat smoke test passed.")
	quit()
