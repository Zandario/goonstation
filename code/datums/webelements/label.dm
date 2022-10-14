/datum/tag/label

/datum/tag/label/New(type as text)
	..("label")

/datum/tag/label/proc/setText(txt as text)
	var/datum/tag/span/txtSpan = new
	txtSpan.setText(txt)
	addChildElement(txtSpan)
