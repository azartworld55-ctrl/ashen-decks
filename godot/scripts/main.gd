extends Control

const RunStateScript = preload("res://scripts/run_state.gd")

var state: RunState
var content: VBoxContainer
var content_root: MarginContainer
var hand_grid: GridContainer
var status_label: Label
var enemy_label: Label
var intent_label: Label
var log_label: Label
var end_turn_button: Button
var result_shown := false

const BG := Color("#17141b")
const PANEL := Color("#26212b")
const PANEL_LIGHT := Color("#332b38")
const GOLD := Color("#d5ad70")
const TEXT := Color("#eee5d8")
const MUTED := Color("#b6a99a")
const RED := Color("#b85d5d")
const BLUE := Color("#7898b8")

func _ready() -> void:
	_build_background()
	_show_title()

func _build_background() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

func _clear_content() -> void:
	if content_root != null and is_instance_valid(content_root):
		content_root.queue_free()
	content_root = null
	content = null
	hand_grid = null
	status_label = null
	enemy_label = null
	intent_label = null
	log_label = null
	end_turn_button = null

func _new_content() -> VBoxContainer:
	_clear_content()
	content_root = MarginContainer.new()
	content_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.add_theme_constant_override("margin_left", 22)
	content_root.add_theme_constant_override("margin_top", 24)
	content_root.add_theme_constant_override("margin_right", 22)
	content_root.add_theme_constant_override("margin_bottom", 24)
	add_child(content_root)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_root.add_child(content)
	return content

func _make_label(value: String, font_size: int, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color("#514252")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_top = 14
	style.content_margin_right = 16
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return panel

func _make_button(value: String, minimum_height: int = 64) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, minimum_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", GOLD)
	var normal := StyleBoxFlat.new()
	normal.bg_color = PANEL_LIGHT
	normal.border_color = GOLD.darkened(0.45)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color("#403447")
	button.add_theme_stylebox_override("hover", hover)
	return button

func _make_card_button(card: Dictionary, index: int) -> Button:
	var title := str(card.get("name", "Карта"))
	var cost := int(card.get("cost", 0))
	var description := str(card.get("description", ""))
	var card_button := _make_button("%s\n✦ %d энергии\n\n%s" % [
		title, cost, description
	], 156)
	card_button.add_theme_font_size_override("font_size", 17)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_LIGHT
	style.border_color = RED if card.get("type", "attack") == "attack" else BLUE
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 8
	style.content_margin_right = 8
	card_button.add_theme_stylebox_override("normal", style)
	card_button.disabled = state.phase != "player" or cost > state.energy
	card_button.pressed.connect(_on_card_pressed.bind(index))
	return card_button

func _show_title() -> void:
	var root := _new_content()
	root.add_spacer(false)
	root.add_child(_make_label("ASHEN DECKS", 42, GOLD))
	root.add_child(_make_label("ПЕПЕЛ ПОМНИТ ВСЁ", 18, MUTED))
	root.add_spacer(false)

	var panel := _make_panel()
	root.add_child(panel)
	var intro := VBoxContainer.new()
	intro.add_theme_constant_override("separation", 10)
	panel.add_child(intro)
	intro.add_child(_make_label("Путь начинается среди руин.", 24))
	intro.add_child(_make_label("Собирай колоду. Переживи встречу. Не доверяй пеплу.", 17, MUTED))

	var start := _make_button("НАЧАТЬ ЗАБЕГ", 76)
	start.pressed.connect(_start_combat)
	root.add_child(start)
	root.add_child(_make_label("Ранняя сборка • разработка продолжается", 14, MUTED))
	root.add_spacer(false)

func _start_combat() -> void:
	state = RunStateScript.new()
	state.changed.connect(_refresh_battle)
	state.start_combat()
	_show_battle()

func _show_battle() -> void:
	result_shown = false
	var root := _new_content()
	root.add_child(_make_label("ASHEN DECKS", 24, GOLD))

	status_label = _make_label("", 17)
	root.add_child(status_label)

	var enemy_panel := _make_panel()
	root.add_child(enemy_panel)
	var enemy_stack := VBoxContainer.new()
	enemy_stack.add_theme_constant_override("separation", 8)
	enemy_panel.add_child(enemy_stack)
	enemy_label = _make_label("", 25, RED)
	enemy_stack.add_child(enemy_label)
	intent_label = _make_label("", 17, GOLD)
	enemy_stack.add_child(intent_label)

	root.add_child(_make_label("ТВОЯ РУКА", 18, MUTED))
	hand_grid = GridContainer.new()
	hand_grid.columns = 2
	hand_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_grid.add_theme_constant_override("h_separation", 10)
	hand_grid.add_theme_constant_override("v_separation", 10)
	root.add_child(hand_grid)

	log_label = _make_label("", 15, MUTED)
	root.add_child(log_label)

	end_turn_button = _make_button("ЗАВЕРШИТЬ ХОД", 68)
	end_turn_button.pressed.connect(_on_end_turn)
	root.add_child(end_turn_button)

	_refresh_battle()

func _refresh_battle() -> void:
	if state == null or hand_grid == null or not is_instance_valid(hand_grid):
		return

	status_label.text = "Здоровье %d/%d   •   Блок %d   •   Энергия %d   •   Ход %d\nКолода: %d   •   Сброс: %d" % [
		state.player_hp, state.player_max_hp, state.player_block, state.energy, state.turn,
		state.draw_pile.size(), state.discard_pile.size()
	]
	enemy_label.text = "%s\nЗдоровье: %d / %d   •   Блок: %d" % [
		state.enemy_name, state.enemy_hp, state.enemy_max_hp, state.enemy_block
	]
	intent_label.text = state.get_intent_text()

	for child in hand_grid.get_children():
		child.queue_free()

	for i in range(state.hand.size()):
		hand_grid.add_child(_make_card_button(state.hand[i], i))

	log_label.text = state.last_message
	end_turn_button.disabled = state.phase != "player"

	if state.phase == "victory" and not result_shown:
		_show_result("ПОБЕДА", "Ты пережил первую встречу.")
	elif state.phase == "defeat" and not result_shown:
		_show_result("ПОРАЖЕНИЕ", "Руины забрали ещё одну жизнь.")

func _on_card_pressed(index: int) -> void:
	if state == null:
		return
	state.play_card(index)

func _on_end_turn() -> void:
	if state == null:
		return
	state.end_turn()

func _show_result(heading: String, description: String) -> void:
	if result_shown or content == null:
		return
	result_shown = true
	for child in hand_grid.get_children():
		child.queue_free()
	var result_panel := _make_panel()
	content.add_child(result_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	result_panel.add_child(stack)
	stack.add_child(_make_label(heading, 26, GOLD))
	stack.add_child(_make_label(description, 17, MUTED))
	var again := _make_button("НОВЫЙ БОЙ", 64)
	again.pressed.connect(_start_combat)
	content.add_child(again)
