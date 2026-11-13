extends RefCounted
class_name RunState

signal changed

const STARTING_HP := 60
const STARTING_ENERGY := 3
const HAND_SIZE := 5
const MAX_FLOOR := 3

var player_hp := STARTING_HP
var player_max_hp := STARTING_HP
var player_block := 0
var energy := STARTING_ENERGY
var turn := 1
var run_floor := 1
var gold := 0

var enemy_name := "Пепельный страж"
var enemy_hp := 42
var enemy_max_hp := 42
var enemy_block := 0
var enemy_intent := "attack"
var enemy_attack := 7
var enemy_heavy_attack := 10
var enemy_guard := 4

var deck: Array[Dictionary] = []
var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var reward_options: Array[Dictionary] = []
var route_options: Array[Dictionary] = []
var phase := "player"
var last_message := "Выбери карту, чтобы сыграть её."

func start_combat() -> void:
	player_hp = STARTING_HP
	player_max_hp = STARTING_HP
	player_block = 0
	energy = STARTING_ENERGY
	turn = 1
	run_floor = 1
	gold = 0
	phase = "player"
	deck.clear()
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	reward_options.clear()
	route_options.clear()

	var starter_deck := [
		_make_card("Удар", 1, "Наносит 6 урона.", "attack", 6, 0, 0),
		_make_card("Удар", 1, "Наносит 6 урона.", "attack", 6, 0, 0),
		_make_card("Удар", 1, "Наносит 6 урона.", "attack", 6, 0, 0),
		_make_card("Удар", 1, "Наносит 6 урона.", "attack", 6, 0, 0),
		_make_card("Защита", 1, "Даёт 5 блока до следующего хода.", "skill", 0, 5, 0),
		_make_card("Защита", 1, "Даёт 5 блока до следующего хода.", "skill", 0, 5, 0),
		_make_card("Защита", 1, "Даёт 5 блока до следующего хода.", "skill", 0, 5, 0),
		_make_card("Тяжёлый удар", 2, "Наносит 10 урона.", "attack", 10, 0, 0),
		_make_card("Искра", 0, "Наносит 4 урона.", "attack", 4, 0, 0),
		_make_card("Перевязка", 1, "Восстанавливает 3 здоровья.", "skill", 0, 0, 3)
	]
	for card in starter_deck:
		deck.append(card.duplicate(true))
	_start_encounter()

func _make_card(card_name: String, cost: int, description: String, card_type: String, damage: int, block: int, heal: int) -> Dictionary:
	return {
		"name": card_name,
		"cost": cost,
		"description": description,
		"type": card_type,
		"damage": damage,
		"block": block,
		"heal": heal
	}

func _start_encounter() -> void:
	turn = 1
	energy = STARTING_ENERGY
	player_block = 0
	enemy_block = 0
	hand.clear()
	draw_pile.clear()
	discard_pile.clear()
	reward_options.clear()
	route_options.clear()

	match run_floor:
		1:
			enemy_name = "Пепельный страж"
			enemy_max_hp = 42
			enemy_attack = 7
			enemy_heavy_attack = 10
			enemy_guard = 4
		2:
			enemy_name = "Утопленник-писец"
			enemy_max_hp = 56
			enemy_attack = 8
			enemy_heavy_attack = 12
			enemy_guard = 6
		_:
			enemy_name = "Епископ углей"
			enemy_max_hp = 78
			enemy_attack = 10
			enemy_heavy_attack = 15
			enemy_guard = 8

	enemy_hp = enemy_max_hp
	for card in deck:
		draw_pile.append(card.duplicate(true))
	draw_pile.shuffle()
	phase = "player"
	_set_enemy_intent()
	_draw_cards(HAND_SIZE)
	last_message = "%s выходит из пепельной мглы." % enemy_name
	changed.emit()

func _draw_cards(amount: int) -> void:
	for _i in range(amount):
		if hand.size() >= HAND_SIZE:
			return
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate(true)
			discard_pile.clear()
			draw_pile.shuffle()
		hand.append(draw_pile.pop_back())

func play_card(index: int) -> bool:
	if phase != "player" or index < 0 or index >= hand.size():
		return false

	var card: Dictionary = hand[index]
	var cost: int = int(card.get("cost", 0))
	if cost > energy:
		return false

	energy -= cost
	hand.remove_at(index)

	var effects: Array[String] = []
	var damage: int = int(card.get("damage", 0))
	if damage > 0:
		var blocked: int = mini(enemy_block, damage)
		enemy_block -= blocked
		var remaining: int = damage - blocked
		var dealt: int = mini(remaining, enemy_hp)
		enemy_hp -= dealt
		if blocked > 0:
			effects.append("блок врага поглотил %d" % blocked)
		if dealt > 0:
			effects.append("нанесено %d урона" % dealt)

	var block_gain: int = int(card.get("block", 0))
	if block_gain > 0:
		player_block += block_gain
		effects.append("+%d блока" % block_gain)

	var heal_amount: int = int(card.get("heal", 0))
	if heal_amount > 0:
		var actual_heal: int = mini(heal_amount, player_max_hp - player_hp)
		player_hp += actual_heal
		if actual_heal > 0:
			effects.append("восстановлено %d здоровья" % actual_heal)
		else:
			effects.append("здоровье уже полное")

	var energy_gain: int = int(card.get("energy_gain", 0))
	if energy_gain > 0:
		var actual_energy: int = mini(energy_gain, 5 - energy)
		energy += actual_energy
		if actual_energy > 0:
			effects.append("+%d энергии" % actual_energy)
		else:
			effects.append("запас энергии уже максимален")

	var draw_amount: int = int(card.get("draw", 0))
	if draw_amount > 0:
		var hand_before_draw := hand.size()
		_draw_cards(draw_amount)
		var cards_drawn := hand.size() - hand_before_draw
		effects.append("добрано карт: %d" % cards_drawn)

	discard_pile.append(card)
	last_message = "%s: %s." % [card.get("name", "Карта"), ", ".join(effects)]
	if enemy_hp <= 0:
		enemy_hp = 0
		phase = "run_victory" if run_floor >= MAX_FLOOR else "victory"
		if phase == "run_victory":
			last_message = "Епископ углей повержен. Забег завершён."
		else:
			_build_reward_options()
			last_message = "%s повержен. Выбери награду." % enemy_name
	changed.emit()
	return true

func end_turn() -> void:
	if phase != "player":
		return

	for card in hand:
		discard_pile.append(card)
	hand.clear()

	phase = "enemy"
	if enemy_intent == "attack":
		_take_player_damage(enemy_attack)
		enemy_block = 0
		last_message = "%s атакует: %d урона до блока." % [enemy_name, enemy_attack]
	elif enemy_intent == "heavy_attack":
		_take_player_damage(enemy_heavy_attack)
		enemy_block = 0
		last_message = "%s наносит тяжёлый удар: %d урона до блока." % [enemy_name, enemy_heavy_attack]
	elif enemy_intent == "prepare":
		enemy_block += enemy_guard
		last_message = "%s укрепляет защиту: +%d блока." % [enemy_name, enemy_guard]

	if player_hp <= 0:
		player_hp = 0
		phase = "defeat"
		last_message = "Ты пал в руинах."
		changed.emit()
		return

	turn += 1
	player_block = 0
	energy = STARTING_ENERGY
	phase = "player"
	_set_enemy_intent()
	_draw_cards(HAND_SIZE)
	changed.emit()

func _take_player_damage(amount: int) -> void:
	var blocked: int = mini(player_block, amount)
	player_block -= blocked
	var remaining: int = amount - blocked
	player_hp = maxi(0, player_hp - remaining)

func _set_enemy_intent() -> void:
	if run_floor == 1:
		match turn % 3:
			0:
				enemy_intent = "heavy_attack"
			2:
				enemy_intent = "prepare"
			_:
				enemy_intent = "attack"
	elif run_floor == 2:
		match turn % 4:
			2:
				enemy_intent = "heavy_attack"
			3:
				enemy_intent = "prepare"
			_:
				enemy_intent = "attack"
	else:
		match turn % 4:
			2:
				enemy_intent = "prepare"
			3:
				enemy_intent = "heavy_attack"
			_:
				enemy_intent = "attack"

func get_intent_text() -> String:
	match enemy_intent:
		"heavy_attack":
			return "Готовит мощный удар: %d урона" % enemy_heavy_attack
		"prepare":
			return "Собирает защиту: +%d блока" % enemy_guard
		_:
			return "Готовится атаковать: %d урона" % enemy_attack

func _build_reward_options() -> void:
	var pool := [
		_make_card("Рассечение", 1, "Наносит 9 урона.", "attack", 9, 0, 0),
		_make_card("Каменная кожа", 1, "Даёт 9 блока.", "skill", 0, 9, 0),
		_make_card("Пепельный ритуал", 1, "Восстанавливает 6 здоровья.", "skill", 0, 0, 6),
		_make_card("Кровавый долг", 2, "Наносит 15 урона.", "attack", 15, 0, 0),
		_make_card("Последняя искра", 0, "Наносит 5 урона.", "attack", 5, 0, 0),
		_make_card("Железная воля", 1, "Даёт 6 блока и лечит на 2.", "skill", 0, 6, 2),
		{
			"name": "Пепельный импульс",
			"cost": 0,
			"description": "Даёт 1 дополнительную энергию в этом ходу.",
			"type": "skill",
			"damage": 0,
			"block": 0,
			"heal": 0,
			"energy_gain": 1
		},
		{
			"name": "Шёпот колодца",
			"cost": 1,
			"description": "Добирает 2 карты.",
			"type": "skill",
			"damage": 0,
			"block": 0,
			"heal": 0,
			"draw": 2
		},
		{
			"name": "Пепельная стена",
			"cost": 2,
			"description": "Даёт 12 блока.",
			"type": "skill",
			"damage": 0,
			"block": 12,
			"heal": 0
		},
		{
			"name": "Тихий обмен",
			"cost": 1,
			"description": "Добирает 1 карту и возвращает 1 энергию.",
			"type": "skill",
			"damage": 0,
			"block": 0,
			"heal": 0,
			"draw": 1,
			"energy_gain": 1
		}
	]
	pool.shuffle()
	reward_options.clear()
	for i in range(3):
		reward_options.append(pool[i].duplicate(true))

func claim_reward(index: int) -> bool:
	if phase != "victory":
		return false
	if index < -1 or index >= reward_options.size():
		return false
	if index >= 0:
		deck.append(reward_options[index].duplicate(true))
	run_floor += 1
	_build_route_options()
	phase = "route"
	last_message = "Выбери путь к следующему этажу."
	changed.emit()
	return true

func _build_route_options() -> void:
	route_options = [
		{"name": "Костёр", "description": "Восстановить до 10 здоровья."},
		{"name": "Забытый тайник", "description": "Найти 20 золотых монет."},
		{"name": "Алтарь пепла", "description": "Усилить одну карту в колоде."}
	]

func choose_route(index: int) -> bool:
	if phase != "route" or index < 0 or index >= route_options.size():
		return false

	var route_message := ""
	match index:
		0:
			var restored_hp: int = mini(10, player_max_hp - player_hp)
			player_hp += restored_hp
			route_message = "У костра восстановлено %d здоровья." % restored_hp
		1:
			gold += 20
			route_message = "В тайнике найдено 20 золотых."
		2:
			var candidates: Array[int] = []
			for i in range(deck.size()):
				var card: Dictionary = deck[i]
				if int(card.get("damage", 0)) > 0 or int(card.get("block", 0)) > 0 or int(card.get("heal", 0)) > 0:
					candidates.append(i)
			if not candidates.is_empty():
				var chosen_index: int = candidates[randi_range(0, candidates.size() - 1)]
				var upgraded: Dictionary = deck[chosen_index]
				if int(upgraded.get("damage", 0)) > 0:
					upgraded["damage"] = int(upgraded["damage"]) + 2
				elif int(upgraded.get("block", 0)) > 0:
					upgraded["block"] = int(upgraded["block"]) + 2
				else:
					upgraded["heal"] = int(upgraded["heal"]) + 1
				upgraded["description"] = str(upgraded.get("description", "")) + " Усилена у алтаря."
				deck[chosen_index] = upgraded
				route_message = "Алтарь усилил карту «%s»." % upgraded.get("name", "Безымянная карта")
			else:
				gold += 10
				route_message = "Алтарь пуст. Найдено 10 золотых."
	_start_encounter()
	last_message = route_message + "\n" + last_message
	changed.emit()
	return true

func to_save_data() -> Dictionary:
	return {
		"save_version": 2,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"player_block": player_block,
		"energy": energy,
		"turn": turn,
		"run_floor": run_floor,
		"gold": gold,
		"enemy_name": enemy_name,
		"enemy_hp": enemy_hp,
		"enemy_max_hp": enemy_max_hp,
		"enemy_block": enemy_block,
		"enemy_intent": enemy_intent,
		"enemy_attack": enemy_attack,
		"enemy_heavy_attack": enemy_heavy_attack,
		"enemy_guard": enemy_guard,
		"deck": deck.duplicate(true),
		"draw_pile": draw_pile.duplicate(true),
		"discard_pile": discard_pile.duplicate(true),
		"hand": hand.duplicate(true),
		"reward_options": reward_options.duplicate(true),
		"route_options": route_options.duplicate(true),
		"phase": phase,
		"last_message": last_message
	}

func load_save_data(data: Dictionary) -> bool:
	if int(data.get("save_version", 0)) != 2:
		return false

	var saved_deck: Variant = data.get("deck", [])
	if not (saved_deck is Array) or saved_deck.is_empty() or saved_deck.size() > 100:
		return false

	var loaded_floor := int(data.get("run_floor", 0))
	var loaded_max_hp := int(data.get("player_max_hp", 0))
	var loaded_hp := int(data.get("player_hp", -1))
	var loaded_enemy_max_hp := int(data.get("enemy_max_hp", 0))
	var loaded_enemy_hp := int(data.get("enemy_hp", -1))
	var loaded_phase := str(data.get("phase", ""))
	if loaded_floor < 1 or loaded_floor > MAX_FLOOR:
		return false
	if loaded_max_hp < 1 or loaded_hp < 1 or loaded_hp > loaded_max_hp:
		return false
	if loaded_enemy_max_hp < 1 or loaded_enemy_hp < 0 or loaded_enemy_hp > loaded_enemy_max_hp:
		return false
	if loaded_phase not in ["player", "victory", "route"]:
		return false

	var loaded_deck := _copy_card_array(saved_deck)
	if loaded_deck.is_empty():
		return false

	deck = loaded_deck
	draw_pile = _copy_card_array(data.get("draw_pile", []))
	discard_pile = _copy_card_array(data.get("discard_pile", []))
	hand = _copy_card_array(data.get("hand", []))
	reward_options = _copy_card_array(data.get("reward_options", []))
	route_options = _copy_card_array(data.get("route_options", []))
	if hand.size() > HAND_SIZE or reward_options.size() > 3 or route_options.size() > 3:
		return false
	if loaded_phase == "route" and route_options.size() != 3:
		return false
	if loaded_phase == "victory" and reward_options.size() != 3:
		return false

	player_hp = loaded_hp
	player_max_hp = loaded_max_hp
	gold = maxi(0, int(data.get("gold", 0)))
	player_block = maxi(0, int(data.get("player_block", 0)))
	energy = clampi(int(data.get("energy", STARTING_ENERGY)), 0, 10)
	turn = maxi(1, int(data.get("turn", 1)))
	run_floor = loaded_floor
	enemy_name = str(data.get("enemy_name", "Неизвестный противник"))
	enemy_hp = loaded_enemy_hp
	enemy_max_hp = loaded_enemy_max_hp
	enemy_block = maxi(0, int(data.get("enemy_block", 0)))
	enemy_intent = str(data.get("enemy_intent", "attack"))
	enemy_attack = maxi(1, int(data.get("enemy_attack", 7)))
	enemy_heavy_attack = maxi(1, int(data.get("enemy_heavy_attack", 10)))
	enemy_guard = maxi(0, int(data.get("enemy_guard", 4)))
	phase = loaded_phase
	last_message = str(data.get("last_message", "Забег восстановлен."))
	return true

func _copy_card_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not (value is Array):
		return result
	for card in value:
		if card is Dictionary:
			result.append(card.duplicate(true))
	return result
