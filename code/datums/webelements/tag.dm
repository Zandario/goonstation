/datum/tag
	var/tmp/list/attributes = list()
	var/tmp/list/styles = list()
	var/tmp/list/classes = list()
	var/tmp/list/children = list()
	var/tmp/tagName = ""
	var/tmp/selfCloses = 0
	var/tmp/innerHtml

/datum/tag/New(_tagName as text)
	..()
	tagName = _tagName

/datum/tag/proc/addChildElement(datum/tag/child)
	children.Add(child)
	return src

/datum/tag/proc/addClass(class as text)
	var/list/classlist = kText.text2list(class, " ")

	for(var/cls in classlist)
		if(!classes.Find(cls))
			classes.Add(cls)

/datum/tag/proc/setAttribute(attribute as text, value as text)
	attributes[attribute] = "[attribute]=\"[value]\""

/datum/tag/proc/setStyle(attribute as text, value as text)
	styles[attribute] = "[attribute]:[value];"

/datum/tag/proc/toHtml()
	beforeToHtmlHook()
	var/html = "";

	html = "<[tagName]"

	if(classes.len)
		var/cls = kText.list2text(classes, " ")
		setAttribute("class", cls)

	if(styles.len)
		var/st = ""
		for(var/atr in styles)
			st += styles[atr]
		setAttribute("style", st)

	if(attributes.len)
		for(var/atr in attributes)
			html += " "
			html += attributes[atr]

	if(!selfCloses)
		html += ">"

		for(var/datum/tag/child in children)
			html += child.toHtml()

		if(innerHtml)
			html += "[innerHtml]"

		html += "</[tagName]>"
	else
		html += "/>"

	return html

/datum/tag/proc/beforeToHtmlHook()
	return

/datum/tag/proc/setId(id as text)
	setAttribute("id", id)

/datum/tag/proc/addJavascriptEvent(event as text, js as text)
	setAttribute(event, js)

/datum/tag/proc/sendAssets()
	for(var/datum/tag/child in children)
		child.sendAssets()
