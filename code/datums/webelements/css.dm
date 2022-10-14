/datum/tag/css

/datum/tag/css/New()
	..("style")
	setAttribute("type", "text/css")

/datum/tag/css/proc/setContent(content as text)
	innerHtml = content
