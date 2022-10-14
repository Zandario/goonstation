/datum/tag/anchor

/datum/tag/anchor/New()
	..("a")

/datum/tag/anchor/proc/setHref(href as text)
	setAttribute("href", href)

/datum/tag/anchor/proc/setText(txt as text)
	innerHtml = txt
