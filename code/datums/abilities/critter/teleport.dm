// ---------------------
// Martian teleportation
// ---------------------
/datum/targetable/critter/teleport
	name = "Teleport"
	desc = "Phase yourself to a nearby visible spot."
	cooldown = 300
	targeted = 1
	target_anything = 1
	restricted_area_check = 1

/datum/targetable/critter/teleport/cast(atom/target)
	if (..())
		return TRUE
	if (!isturf(target))
		target = get_turf(target)
	if (target == get_turf(holder.owner))
		return TRUE
	var/turf/T = target
	holder.owner.set_loc(T)
	elecflash(T)
	playsound(T, 'sound/effects/ghost2.ogg', 100, TRUE)
	holder.owner.say("TELEPORT!", 1)
	return FALSE
