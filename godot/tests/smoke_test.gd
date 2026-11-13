extends SceneTree

const RunStateScript = preload("res://scripts/run_state.gd")

func _initialize() -> void:
	var state = RunStateScript.new()
	state.start_combat()

	assert(state.player_hp == 60, "Player should start with 60 HP")
	assert(state.energy == 3, "Player should start with 3 energy")
	assert(state.hand.size() == 5, "Opening hand should contain five cards")
	assert(state.enemy_hp == 42, "Test enemy should start with 42 HP")

	var playable_index := -1
	for i in range(state.hand.size()):
		if int(state.hand[i]["cost"]) <= state.energy:
			playable_index = i
			break

	assert(playable_index >= 0, "Opening hand should contain a playable card")
	assert(state.play_card(playable_index), "A playable card should resolve")
	assert(state.hand.size() == 4, "Played card should leave the hand")

	state.end_turn()
	assert(state.turn == 2, "Turn counter should advance")
	assert(state.hand.size() == 5, "Next turn should draw a new hand")
	assert(state.phase == "player", "Player should regain control after enemy turn")

	print("Godot combat smoke test passed.")
	quit()
