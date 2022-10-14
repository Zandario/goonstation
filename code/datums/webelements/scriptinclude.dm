/datum/tag/scriptinclude

/datum/tag/scriptinclude/New()
	..("script")
	setAttribute("type", "text/javascript")

/datum/tag/scriptinclude/proc/setSrc(source as text)
	setAttribute("src", source)
