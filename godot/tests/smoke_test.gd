extends SceneTree

const RunStateScript = preload("res://scripts/run_state.gd")
const SaveManagerScript = preload("res://scripts/save_manager.gd")

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

    state.player_hp = 40
    assert(state.claim_reward(0), "Claiming a reward should advance to route choice")
    assert(state.run_floor == 2, "Run should advance to floor two")
    assert(state.deck.size() == 11, "Claimed reward should be added to the deck")
    assert(state.phase == "route", "Reward should lead to route selection")

    assert(SaveManagerScript.save_run(state), "Route state should save")
    var restored = RunStateScript.new()
    assert(SaveManagerScript.load_run(restored), "Saved route should load")
    assert(restored.phase == "route", "Route choice should survive save/load")
    assert(restored.route_options.size() == 3, "All route options should survive save/load")
    assert(restored.deck.size() == state.deck.size(), "Deck should survive save/load")
    assert(SaveManagerScript.delete_save(), "Test save should be removable")

    assert(state.choose_route(0), "Campfire route should resolve")
    assert(state.player_hp == 50, "Campfire should restore ten health")
    assert(state.enemy_name == "Утопленник-писец", "Second floor should load its enemy")
    assert(state.enemy_hp == 56, "Second enemy should have configured health")

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
    assert(state.choose_route(1), "Treasure route should resolve")
    assert(state.gold == 20, "Treasure route should award twenty gold")
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

    var altar_probe = RunStateScript.new()
    altar_probe.start_combat()
    altar_probe.enemy_hp = 1
    altar_probe.hand.clear()
    altar_probe.hand.append({
        "name": "Проверка алтаря",
        "cost": 0,
        "description": "Проверка усиления.",
        "type": "attack",
        "damage": 1,
        "block": 0,
        "heal": 0
    })
    assert(altar_probe.play_card(0), "Altar test encounter should be winnable")
    assert(altar_probe.claim_reward(-1), "Altar test should reach route selection")
    var power_before := 0
    for card in altar_probe.deck:
        power_before += int(card.get("damage", 0)) + int(card.get("block", 0)) + int(card.get("heal", 0))
    assert(not altar_probe.choose_route(99), "Invalid route index should be rejected")
    assert(altar_probe.choose_route(2), "Ash altar route should resolve")
    var power_after := 0
    for card in altar_probe.deck:
        power_after += int(card.get("damage", 0)) + int(card.get("block", 0)) + int(card.get("heal", 0))
    assert(power_after > power_before, "Ash altar should improve one card")

    var energy_probe = RunStateScript.new()
    energy_probe.start_combat()
    energy_probe.hand.clear()
    energy_probe.hand.append({
        "name": "Пепельный импульс",
        "cost": 0,
        "description": "Тест дополнительной энергии.",
        "type": "skill",
        "damage": 0,
        "block": 0,
        "heal": 0,
        "energy_gain": 1
    })
    energy_probe.energy = 2
    assert(energy_probe.play_card(0), "Energy card should resolve")
    assert(energy_probe.energy == 3, "Energy card should grant one energy")
    assert(energy_probe.discard_pile.size() == 1, "Energy card should enter discard pile")
    energy_probe.energy = 5
    energy_probe.hand.append(energy_probe.discard_pile[0].duplicate(true))
    assert(energy_probe.play_card(0), "Energy card should still resolve at the cap")
    assert(energy_probe.energy == 5, "Energy card should not exceed the five-energy cap")

    print("Godot route, run progression, energy cap and save tests passed.")
    quit()
