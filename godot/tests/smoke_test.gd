extends SceneTree

const RunStateScript = preload("res://scripts/run_state.gd")
const SaveManagerScript = preload("res://scripts/save_manager.gd")

var failures := 0

func _initialize() -> void:
    var state = RunStateScript.new()
    state.start_combat()

    _check(state.player_hp == 60, "Player should start with 60 HP")
    _check(state.energy == 3, "Player should start with 3 energy")
    _check(state.hand.size() == 5, "Opening hand should contain five cards")
    _check(state.enemy_hp == 42, "First enemy should start with 42 HP")
    _check(state.deck.size() == 10, "Starter deck should contain ten cards")

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

    _check(state.play_card(0), "Test attack should resolve")
    _check(state.enemy_hp == 40, "Enemy block should absorb four of six damage")
    _check(state.enemy_block == 0, "Enemy block should be consumed")

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
    _check(state.play_card(0), "Finishing attack should resolve")
    _check(state.phase == "victory", "First floor should lead to reward phase")
    _check(state.reward_options.size() == 3, "Victory should offer three rewards")

    state.player_hp = 40
    _check(state.claim_reward(0), "Claiming a reward should advance to route choice")
    _check(state.run_floor == 2, "Run should advance to floor two")
    _check(state.deck.size() == 11, "Claimed reward should be added to the deck")
    _check(state.phase == "route", "Reward should lead to route selection")

    _check(SaveManagerScript.save_run(state), "Route state should save")
    var restored = RunStateScript.new()
    _check(SaveManagerScript.load_run(restored), "Saved route should load")
    _check(restored.phase == "route", "Route choice should survive save/load")
    _check(restored.route_options.size() == 3, "All route options should survive save/load")
    _check(restored.deck.size() == state.deck.size(), "Deck should survive save/load")
    _check(SaveManagerScript.delete_save(), "Test save should be removable")

    _check(state.choose_route(0), "Campfire route should resolve")
    _check(state.player_hp == 50, "Campfire should restore ten health")
    _check(state.phase == "event", "Route choice should lead to a random event")
    _check(state.event_options.size() == 3, "Random event should offer three choices")
    _check(SaveManagerScript.save_run(state), "Event state should save")
    var event_restored = RunStateScript.new()
    _check(SaveManagerScript.load_run(event_restored), "Saved event should load")
    _check(event_restored.phase == "event", "Event phase should survive save/load")
    _check(event_restored.event_options.size() == 3, "Event choices should survive save/load")
    _check(state.choose_event(0), "First event choice should resolve")
    _check(state.phase == "player", "Event choice should start the next floor")
    _check(state.relics.size() == 1, "Relic choice should add one relic to the run")
    _check(state.player_block == 3 or state.player_hp == 53, "Starting relic should apply its combat bonus")
    _check(state.enemy_name == "Утопленник-писец", "Second floor should load its enemy")
    _check(state.enemy_hp == 56, "Second enemy should have configured health")
    _check(SaveManagerScript.save_run(state), "Run with relic should save")
    var relic_restored = RunStateScript.new()
    _check(SaveManagerScript.load_run(relic_restored), "Run with relic should load")
    _check(relic_restored.relics.size() == 1, "Relic collection should survive save/load")
    _check(SaveManagerScript.delete_save(), "Relic save should be removable")

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
    _check(state.play_card(0), "Second-floor finishing attack should resolve")
    _check(state.phase == "victory", "Second floor should also award a reward")
    _check(state.claim_reward(-1), "Skipping a reward should be allowed")
    _check(state.choose_route(1), "Treasure route should resolve")
    _check(state.gold == 20, "Treasure route should award twenty gold")
    _check(state.run_floor == 3, "Run should advance to the final floor")
    _check(state.phase == "event", "Second route should also lead to an event")
    _check(state.choose_event(2), "Second event choice should resolve")
    _check(state.enemy_name == "Епископ углей", "Final boss should load")
    _check(state.enemy_hp == 78, "Final boss should have configured health")

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
    _check(state.play_card(0), "Final attack should resolve")
    _check(state.phase == "run_victory", "Final boss victory should finish the run")

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
    _check(altar_probe.play_card(0), "Altar test encounter should be winnable")
    _check(altar_probe.claim_reward(-1), "Altar test should reach route selection")
    var power_before := 0
    for card in altar_probe.deck:
        power_before += int(card.get("damage", 0)) + int(card.get("block", 0)) + int(card.get("heal", 0))
    _check(not altar_probe.choose_route(99), "Invalid route index should be rejected")
    _check(altar_probe.choose_route(2), "Ash altar route should resolve")
    var power_after := 0
    for card in altar_probe.deck:
        power_after += int(card.get("damage", 0)) + int(card.get("block", 0)) + int(card.get("heal", 0))
    _check(power_after > power_before, "Ash altar should improve one card")

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
    _check(energy_probe.play_card(0), "Energy card should resolve")
    _check(energy_probe.energy == 3, "Energy card should grant one energy")
    _check(energy_probe.discard_pile.size() == 1, "Energy card should enter discard pile")
    energy_probe.energy = 5
    energy_probe.hand.append(energy_probe.discard_pile[0].duplicate(true))
    _check(energy_probe.play_card(0), "Energy card should still resolve at the cap")
    _check(energy_probe.energy == 5, "Energy card should not exceed the five-energy cap")

    var draw_probe = RunStateScript.new()
    draw_probe.start_combat()
    draw_probe.hand.clear()
    draw_probe.draw_pile.clear()
    draw_probe.draw_pile.append({"name": "Карта А", "cost": 0, "damage": 0, "block": 0, "heal": 0})
    draw_probe.draw_pile.append({"name": "Карта Б", "cost": 0, "damage": 0, "block": 0, "heal": 0})
    draw_probe.hand.append({
        "name": "Шёпот колодца",
        "cost": 1,
        "description": "Добирает две карты.",
        "type": "skill",
        "damage": 0,
        "block": 0,
        "heal": 0,
        "draw": 2
    })
    _check(draw_probe.play_card(0), "Draw card should resolve")
    _check(draw_probe.hand.size() == 2, "Draw effect should add two cards to hand")
    _check(draw_probe.discard_pile.size() == 1, "Draw card itself should enter discard pile")

    draw_probe.hand.clear()
    for i in range(4):
        draw_probe.hand.append({"name": "Рука %d" % i, "cost": 0, "damage": 0, "block": 0, "heal": 0})
    draw_probe.hand.append({
        "name": "Переполнение",
        "cost": 0,
        "description": "Проверка лимита руки.",
        "type": "skill",
        "damage": 0,
        "block": 0,
        "heal": 0,
        "draw": 2
    })
    draw_probe.draw_pile.clear()
    draw_probe.draw_pile.append({"name": "Добор 1", "cost": 0, "damage": 0, "block": 0, "heal": 0})
    draw_probe.draw_pile.append({"name": "Добор 2", "cost": 0, "damage": 0, "block": 0, "heal": 0})
    _check(draw_probe.play_card(4), "Draw card should resolve near hand limit")
    _check(draw_probe.hand.size() == 5, "Draw effect must respect the hand-size limit")

    var hybrid_probe = RunStateScript.new()
    hybrid_probe.start_combat()
    hybrid_probe.hand.clear()
    hybrid_probe.draw_pile.clear()
    hybrid_probe.draw_pile.append({"name": "Добранная карта", "cost": 0, "damage": 0, "block": 0, "heal": 0})
    hybrid_probe.hand.append({
        "name": "Тихий обмен",
        "cost": 1,
        "description": "Добирает карту и возвращает энергию.",
        "type": "skill",
        "damage": 0,
        "block": 0,
        "heal": 0,
        "draw": 1,
        "energy_gain": 1
    })
    hybrid_probe.energy = 2
    _check(hybrid_probe.play_card(0), "Combined draw and energy card should resolve")
    _check(hybrid_probe.hand.size() == 1, "Combined card should draw one card")
    _check(hybrid_probe.energy == 2, "Combined card should refund its one energy cost")

    var intent_probe = RunStateScript.new()
    intent_probe.start_combat()
    intent_probe.turn = 2
    intent_probe._set_enemy_intent()
    _check(intent_probe.enemy_intent == "prepare", "First-floor intent cycle should prepare on turn two")
    intent_probe.turn = 3
    intent_probe._set_enemy_intent()
    _check(intent_probe.enemy_intent == "heavy_attack", "First-floor intent cycle should use a heavy attack on turn three")
    intent_probe.run_floor = 2
    intent_probe.turn = 2
    intent_probe._set_enemy_intent()
    _check(intent_probe.enemy_intent == "heavy_attack", "Second-floor enemy should use its own intent pattern")
    intent_probe.run_floor = 3
    intent_probe.turn = 2
    intent_probe._set_enemy_intent()
    _check(intent_probe.enemy_intent == "prepare", "Boss should prepare on turn two")
    intent_probe.turn = 3
    intent_probe._set_enemy_intent()
    _check(intent_probe.enemy_intent == "heavy_attack", "Boss should use a heavy attack on turn three")

    if failures > 0:
        push_error("Godot smoke tests failed: %d" % failures)
        quit(1)
    else:
        print("Godot combat, rewards, routes, random events, relics, card effects, enemy intents and save tests passed.")
        quit(0)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("FAIL: " + message)
