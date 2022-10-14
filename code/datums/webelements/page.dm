/datum/tag/page
	var/tmp/datum/tag/doctype/dt = new
	var/tmp/datum/tag/head = new /datum/tag("head")
	var/tmp/datum/tag/body = new /datum/tag("body")

/datum/tag/page/New()
	..("html")

	addChildElement(head)
	addChildElement(body)

/datum/tag/page/toHtml()
	return dt.toHtml() + ..()

/datum/tag/page/proc/addToHead(datum/tag/child)
	head.addChildElement(child)

/datum/tag/page/proc/addToBody(datum/tag/child)
	body.addChildElement(child)
