/datum/tag/textarea

/datum/tag/textarea/New(type as text)
	..("textarea")

/datum/tag/textarea/proc/setName(name as text)
	setAttribute("name", name)

/datum/tag/textarea/proc/setValue(txt as text)
	innerHtml = txt
