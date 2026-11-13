extends Control

const RunStateScript = preload("res://scripts/run_state.gd")
const SaveManagerScript = preload("res://scripts/save_manager.gd")
const GUARDIAN_ART = preload("res://assets/enemies/ashen_guardian.svg")
const SCRIBE_ART = preload("res://assets/enemies/drowned_scribe.svg")
const BISHOP_ART = preload("res://assets/enemies/cinder_bishop.svg")
const TITLE_ART = preload("res://assets/ui/title_ruins.svg")
const MAX_FLOOR := 3

var state: RunState
var content: VBoxContainer
var content_root: MarginContainer
var background_art: TextureRect
var hand_grid: GridContainer
var status_label: Label
var deck_button: Button
var enemy_label: Label
var enemy_portrait: TextureRect
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

    background_art = TextureRect.new()
    background_art.texture = TITLE_ART
    background_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background_art.modulate = Color(0.72, 0.67, 0.64, 0.58)
    background_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background_art)

    var shade := ColorRect.new()
    shade.color = Color(0.04, 0.035, 0.05, 0.42)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)

func _clear_content() -> void:
    if content_root != null and is_instance_valid(content_root):
        content_root.queue_free()
    content_root = null
    content = null
    hand_grid = null
    status_label = null
    deck_button = null
    enemy_label = null
    enemy_portrait = null
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
    var hover = normal.duplicate()
    hover.bg_color = Color("#403447")
    button.add_theme_stylebox_override("hover", hover)
    return button

func _make_card_button(card: Dictionary, index: int, is_reward: bool = false) -> Button:
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
    if is_reward:
        card_button.pressed.connect(_claim_reward.bind(index))
    else:
        card_button.disabled = state.phase != "player" or cost > state.energy
        card_button.pressed.connect(_on_card_pressed.bind(index))
    return card_button

func _show_title() -> void:
    background_art.visible = true
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

    if SaveManagerScript.has_save():
        var continue_button := _make_button("ПРОДОЛЖИТЬ ЗАБЕГ", 68)
        continue_button.pressed.connect(_continue_run)
        root.add_child(continue_button)

    var start := _make_button("НАЧАТЬ НОВЫЙ ЗАБЕГ", 76)
    start.pressed.connect(_start_combat)
    root.add_child(start)
    root.add_child(_make_label("Ранняя сборка • разработка продолжается", 14, MUTED))
    root.add_spacer(false)

func _start_combat() -> void:
    SaveManagerScript.delete_save()
    state = RunStateScript.new()
    state.changed.connect(_refresh_battle)
    state.start_combat()
    _show_battle()

func _continue_run() -> void:
    state = RunStateScript.new()
    if not SaveManagerScript.load_run(state):
        SaveManagerScript.delete_save()
        _show_title()
        return
    state.changed.connect(_refresh_battle)
    if state.phase == "route":
        _show_route()
    else:
        _show_battle()

func _show_battle() -> void:
    background_art.visible = false
    result_shown = false
    var root := _new_content()
    root.add_child(_make_label("ASHEN DECKS", 24, GOLD))
    root.add_child(_make_label("ЭТАЖ %d / %d" % [state.run_floor, MAX_FLOOR], 16, MUTED))

    status_label = _make_label("", 17)
    root.add_child(status_label)
    deck_button = _make_button("ПОСМОТРЕТЬ КОЛОДУ • %d КАРТ" % state.deck.size(), 48)
    deck_button.add_theme_font_size_override("font_size", 16)
    deck_button.pressed.connect(_show_deck)
    root.add_child(deck_button)

    var enemy_panel := _make_panel()
    root.add_child(enemy_panel)
    var enemy_stack := VBoxContainer.new()
    enemy_stack.add_theme_constant_override("separation", 8)
    enemy_panel.add_child(enemy_stack)

    enemy_portrait = TextureRect.new()
    enemy_portrait.custom_minimum_size = Vector2(0, 210)
    enemy_portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    enemy_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    enemy_stack.add_child(enemy_portrait)

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

    if state.phase in ["defeat", "run_victory"]:
        SaveManagerScript.delete_save()
    else:
        SaveManagerScript.save_run(state)

    status_label.text = "Здоровье %d/%d   •   Блок %d   •   Энергия %d   •   Ход %d\nКолода: %d   •   Сброс: %d" % [
        state.player_hp, state.player_max_hp, state.player_block, state.energy, state.turn,
        state.gold, state.draw_pile.size(), state.discard_pile.size()
    ]
    enemy_portrait.texture = _get_enemy_art()
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
        _show_result("ПОБЕДА", "Враг повержен. Выбери одну карту для колоды.", "ВЫБРАТЬ НАГРАДУ", _show_reward)
    elif state.phase == "run_victory" and not result_shown:
        _show_result("ЗАБЕГ ЗАВЕРШЁН", "Епископ углей пал. Руины на время умолкли.", "В ГЛАВНОЕ МЕНЮ", _show_title)
    elif state.phase == "defeat" and not result_shown:
        _show_result("ПОРАЖЕНИЕ", "Руины забрали ещё одну жизнь.", "НОВЫЙ ЗАБЕГ", _start_combat)

func _on_card_pressed(index: int) -> void:
    if state == null:
        return
    state.play_card(index)

func _on_end_turn() -> void:
    if state == null:
        return
    state.end_turn()

func _show_result(heading: String, description: String, button_text: String, callback: Callable) -> void:
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
    var action := _make_button(button_text, 64)
    action.pressed.connect(callback)
    content.add_child(action)


func _show_deck() -> void:
    background_art.visible = false
    var root := _new_content()
    root.add_child(_make_label("ТВОЯ КОЛОДА", 30, GOLD))
    root.add_child(_make_label("Карт: %d   •   Золото: %d" % [state.deck.size(), state.gold], 16, MUTED))

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.add_child(scroll)

    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 10)
    scroll.add_child(list)

    for card in state.deck:
        var panel := _make_panel()
        list.add_child(panel)
        var stack := VBoxContainer.new()
        stack.add_theme_constant_override("separation", 5)
        panel.add_child(stack)
        var card_title := "%s   •   %d энергии" % [card.get("name", "Карта"), int(card.get("cost", 0))]
        stack.add_child(_make_label(card_title, 18, GOLD))
        stack.add_child(_make_label(str(card.get("description", "")), 15, MUTED))

    var back := _make_button("ВЕРНУТЬСЯ К БОЮ", 64)
    back.pressed.connect(_show_battle)
    root.add_child(back)

func _show_reward() -> void:
    background_art.visible = false
    var root := _new_content()
    root.add_spacer(false)
    root.add_child(_make_label("НАГРАДА", 34, GOLD))
    root.add_child(_make_label("Выбери одну карту. Она останется в колоде до конца забега.", 17, MUTED))
    root.add_spacer(false)

    for i in range(state.reward_options.size()):
        var card: Dictionary = state.reward_options[i]
        var reward_button := _make_card_button(card, i, true)
        reward_button.custom_minimum_size = Vector2(0, 120)
        root.add_child(reward_button)

    var skip := _make_button("ПРОПУСТИТЬ НАГРАДУ", 58)
    skip.pressed.connect(_claim_reward.bind(-1))
    root.add_child(skip)
    root.add_spacer(false)

func _claim_reward(index: int) -> void:
    if state == null or not state.claim_reward(index):
        return
    SaveManagerScript.save_run(state)
    if state.phase == "route":
        _show_route()
    else:
        _show_battle()

func _show_route() -> void:
    background_art.visible = false
    var root := _new_content()
    root.add_spacer(false)
    root.add_child(_make_label("ВЫБОР ПУТИ", 34, GOLD))
    root.add_child(_make_label("До следующего этажа можно сделать только одну остановку.", 17, MUTED))
    root.add_spacer(false)
    for i in range(state.route_options.size()):
        var route: Dictionary = state.route_options[i]
        var route_button := _make_button("%s\\n%s" % [route.get("name", "Путь"), route.get("description", "")], 112)
        route_button.add_theme_font_size_override("font_size", 18)
        route_button.pressed.connect(_choose_route.bind(i))
        root.add_child(route_button)
    root.add_spacer(false)

func _choose_route(index: int) -> void:
    if state == null or not state.choose_route(index):
        return
    SaveManagerScript.save_run(state)
    _show_battle()

func _get_enemy_art() -> Texture2D:
    match state.run_floor:
        1:
            return GUARDIAN_ART
        2:
            return SCRIBE_ART
        _:
            return BISHOP_ART
