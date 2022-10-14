/datum/tag/option

/datum/tag/option/New()
	..("option")

/datum/tag/option/proc/setValue(val as text)
	setAttribute("value", val)

/datum/tag/option/proc/setText(txt as text)
	innerHtml = txt
