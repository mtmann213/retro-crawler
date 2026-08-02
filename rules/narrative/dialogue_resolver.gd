class_name DialogueResolver
extends RefCounted


static func resolve(
	events: Array[DialogueEventDefinition],
	trigger_id: StringName,
	flags: Dictionary[StringName, bool],
	state: DialogueState,
) -> Array[DialogueEventDefinition]:
	var matches: Array[DialogueEventDefinition] = []
	for event: DialogueEventDefinition in events:
		if event == null or event.trigger_id != trigger_id:
			continue
		if event.once_only and state.shown_events.get(event.content_id, false):
			continue
		if not event.conditions_match(flags):
			continue
		matches.append(event)
		if event.once_only:
			state.shown_events[event.content_id] = true
	return matches
