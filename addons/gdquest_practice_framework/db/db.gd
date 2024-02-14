## Keeps track of the student's progress. Most importantly which practices have been completed.
extends RefCounted

const Progress := preload("progress.gd")
const Metadata := preload("../metadata.gd")
const Paths := preload("../paths.gd")

var progress: Progress = null


func _init() -> void:
	var metadata := Metadata.load()
	if not ResourceLoader.exists(Progress.PATH):
		progress = Progress.new()
		for practice_metadata: Metadata.PracticeMetadata in metadata:
			progress.state[practice_metadata.id] = {completion = 0, tries = 0}
		save()
	reload()


func reload() -> void:
	progress = ResourceLoader.load(Progress.PATH, "", ResourceLoader.CACHE_MODE_IGNORE)


func save() -> void:
	ResourceSaver.save(progress)


func update(dict: Dictionary) -> void:
	for id in dict:
		for key in dict[id]:
			if (
				key == "completion"
				and progress.state.has(id)
				and progress.state[id].completion == 1
			):
				continue
			if not progress.state.has(id):
				progress.state[id] = {}
			progress.state[id][key] = dict[id][key]
	progress.emit_changed()
