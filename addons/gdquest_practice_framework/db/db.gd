## Keeps track of the student's progress. Most importantly which practices have been completed.
const Progress := preload("progress.gd")
const Metadata := preload("../metadata.gd")
const Paths := preload("../paths.gd")

const PracticeMetadata := Metadata.PracticeMetadata

var progress: Progress = null


func _init(metadata: Metadata) -> void:
	if not ResourceLoader.exists(Progress.PATH):
		progress = Progress.new()
		for practice_metadata: PracticeMetadata in metadata.list:
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
