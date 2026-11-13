extends RefCounted
class_name RunState

signal changed

const STARTING_HP := 60
const STARTING_ENERGY := 3
const HAND_SIZE := 5

var player_hp := STARTING_HP
var player_max_hp := STARTING_HP
var player_block := 0
var energy := STARTING_ENERGY
var turn := 1

var enemy_name := "Пепельный страж"
var enemy_hp := 42
var enemy_max_hp := 42
var enemy_block := 0
var enemy_intent := "attack"

var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var phase := "player"
var last_message := "Выбери карту, чтобы сыграть её."

func start_combat() -> void:
	player_hp = STARTING_HP
	player_max_hp = STARTING_HP
	player_block = 0
	energy = STARTING_ENERGY
	turn = 1
	enemy_hp = enemy_max_hp
	enemy_block = 0
	phase = "player"
	last_message = "Пепельный страж преграждает путь."
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()

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
		draw_pile.append(card.duplicate(true))
	draw_pile.shuffle()
	_set_enemy_intent()
	_draw_cards(HAND_SIZE)
	changed.emit()

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

	discard_pile.append(card)
	last_message = "%s: %s." % [card.get("name", "Карта"), ", ".join(effects)]
	if enemy_hp <= 0:
		enemy_hp = 0
		phase = "victory"
		last_message = "Пепельный страж повержен."
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
		_take_player_damage(7)
		enemy_block = 0
		last_message = "Страж атакует: 7 урона до блока."
	elif enemy_intent == "heavy_attack":
		_take_player_damage(10)
		enemy_block = 0
		last_message = "Страж наносит тяжёлый удар: 10 урона до блока."
	elif enemy_intent == "prepare":
		enemy_block += 4
		last_message = "Страж укрепляет защиту: +4 блока."

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
	match turn % 3:
		0:
			enemy_intent = "heavy_attack"
		2:
			enemy_intent = "prepare"
		_:
			enemy_intent = "attack"

func get_intent_text() -> String:
	match enemy_intent:
		"heavy_attack":
			return "Готовит мощный удар: 10 урона"
		"prepare":
			return "Собирает защиту: +4 блока"
		_:
			return "Готовится атаковать: 7 урона"
