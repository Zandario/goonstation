/datum/tag/cssinclude

/datum/tag/cssinclude/New()
	..("link")
	setAttribute("rel", "stylesheet")
	setAttribute("type", "text/css")
	selfCloses = 1

/datum/tag/cssinclude/proc/setHref(href as text)
	setAttribute("href", href)
