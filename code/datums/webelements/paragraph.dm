/datum/tag/paragraph

/datum/tag/paragraph/New()
	..("p")

/datum/tag/paragraph/proc/setText(txt as text)
	innerHtml = txt
