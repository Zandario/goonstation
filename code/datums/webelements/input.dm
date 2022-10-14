/datum/tag/input

/datum/tag/input/New(type as text)
	..("input")
	selfCloses = 1

/datum/tag/input/proc/setType(type as text)
	setAttribute("type", type)

/datum/tag/input/proc/setValue(value as text)
	setAttribute("value", value)

/datum/tag/input/proc/setName(name as text)
	setAttribute("name", name)
