/datum/tag/span

/datum/tag/span/New(type as text)
	..("span")

/datum/tag/span/proc/setText(txt as text)
	src.innerHtml = txt
