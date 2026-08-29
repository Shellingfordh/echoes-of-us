extends Node

signal chapter_entered(previous_chapter: int, current_chapter: int)
signal chapter_completed(chapter: int)
signal flag_changed(flag_name: StringName, value: bool)

const FIRST_CHAPTER := 1
const LAST_CHAPTER := 3

var current_chapter := FIRST_CHAPTER
var completed_chapters: Array[int] = []
var story_flags: Dictionary[StringName, bool] = {}


func enter_chapter(chapter: int) -> void:
	assert(chapter >= FIRST_CHAPTER and chapter <= LAST_CHAPTER, "invalid chapter: %d" % chapter)
	if chapter == current_chapter:
		return
	var previous_chapter := current_chapter
	current_chapter = chapter
	chapter_entered.emit(previous_chapter, current_chapter)


func complete_chapter(chapter: int) -> void:
	assert(chapter >= FIRST_CHAPTER and chapter <= LAST_CHAPTER, "invalid chapter: %d" % chapter)
	if chapter in completed_chapters:
		return
	completed_chapters.append(chapter)
	completed_chapters.sort()
	chapter_completed.emit(chapter)


func is_chapter_completed(chapter: int) -> bool:
	return chapter in completed_chapters


func set_flag(flag_name: StringName, value := true) -> void:
	if story_flags.get(flag_name, false) == value:
		return
	story_flags[flag_name] = value
	flag_changed.emit(flag_name, value)


func has_flag(flag_name: StringName) -> bool:
	return story_flags.get(flag_name, false)


func reset() -> void:
	current_chapter = FIRST_CHAPTER
	completed_chapters.clear()
	story_flags.clear()
