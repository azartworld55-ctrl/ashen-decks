extends RefCounted
class_name SaveManager

const SAVE_PATH := "user://ashen_decks_run.cfg"

static func has_save() -> bool:
	var config := ConfigFile.new()
	return config.load(SAVE_PATH) == OK

static func save_run(state: RunState) -> bool:
	var config := ConfigFile.new()
	var data := state.to_save_data()
	for key in data.keys():
		config.set_value("run", str(key), data[key])
	return config.save(SAVE_PATH) == OK

static func load_run(state: RunState) -> bool:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	var data: Dictionary = {}
	for key in config.get_section_keys("run"):
		data[key] = config.get_value("run", key)
	return state.load_save_data(data)

static func delete_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH)) == OK
