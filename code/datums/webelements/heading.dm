/datum/tag/heading

/datum/tag/heading/New(level = 1)
	..("h[level]")

/datum/tag/heading/proc/setText(txt as text)
	innerHtml = txt
