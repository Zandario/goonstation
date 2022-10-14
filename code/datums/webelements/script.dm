/datum/tag/script

/datum/tag/script/New()
	..("script")
	setAttribute("type", "text/javascript")

/datum/tag/script/proc/setContent(content as text)
	innerHtml = content
