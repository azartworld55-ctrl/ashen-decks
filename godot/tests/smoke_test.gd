extends SceneTree

const RunStateScript = preload("res://scripts/run_state.gd")

func _initialize() -> void:
	var state = RunStateScript.new()
	state.start_combat()

	assert(state.player_hp == 60, "Player should start with 60 HP")
	assert(state.energy == 3, "Player should start with 3 energy")
	assert(state.hand.size() == 5, "Opening hand should contain five cards")
	assert(state.enemy_hp == 42, "First enemy should start with 42 HP")
	assert(state.deck.size() == 10, "Starter deck should contain ten cards")

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

	state.enemy_hp = 6
	state.hand.append({
		"name": "Последний удар",
		"cost": 0,
		"description": "Проверка победы.",
		"type": "attack",
		"damage": 6,
		"block": 0,
		"heal": 0
	})
	assert(state.play_card(0), "Finishing attack should resolve")
	assert(state.phase == "victory", "First floor should lead to reward phase")
	assert(state.reward_options.size() == 3, "Victory should offer three rewards")

	var hp_before_reward: int = state.player_hp
	assert(state.claim_reward(0), "Claiming a reward should advance the run")
	assert(state.run_floor == 2, "Run should advance to floor two")
	assert(state.deck.size() == 11, "Claimed reward should be added to the deck")
	assert(state.player_hp == hp_before_reward, "Player health should carry between floors")
	assert(state.enemy_name == "Утопленник-писец", "Second floor should load its enemy")
	assert(state.enemy_hp == 56, "Second enemy should have its configured health")
	assert(state.hand.size() == 5, "New encounter should draw a fresh hand")

	state.enemy_hp = 1
	state.hand.clear()
	state.hand.append({
		"name": "Тестовый удар",
		"cost": 0,
		"description": "Проверка перехода.",
		"type": "attack",
		"damage": 1,
		"block": 0,
		"heal": 0
	})
	assert(state.play_card(0), "Second-floor finishing attack should resolve")
	assert(state.phase == "victory", "Second floor should also award a reward")
	assert(state.claim_reward(-1), "Skipping a reward should be allowed")
	assert(state.run_floor == 3, "Run should advance to the final floor")
	assert(state.enemy_name == "Епископ углей", "Final boss should load")
	assert(state.enemy_hp == 78, "Final boss should have configured health")

	state.enemy_hp = 1
	state.hand.clear()
	state.hand.append({
		"name": "Последний удар",
		"cost": 0,
		"description": "Проверка финала.",
		"type": "attack",
		"damage": 1,
		"block": 0,
		"heal": 0
	})
	assert(state.play_card(0), "Final attack should resolve")
	assert(state.phase == "run_victory", "Final boss victory should finish the run")

	print("Godot run progression smoke test passed.")
	quit()
