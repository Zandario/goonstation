/datum/tag/select

/datum/tag/select/New()
	..("select")

/datum/tag/select/proc/setName(name as text)
	setAttribute("name", name)

/datum/tag/select/proc/addOption(value as text, txt as text, selected = 0)
	var/datum/tag/option/opt = new
	opt.setValue(value)
	opt.setText(txt)
	if(selected)
		opt.setAttribute("selected", "selected")
	addChildElement(opt)
