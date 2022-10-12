// ------
// Tackle
// ------
/datum/targetable/critter/tackle
	name = "Tackle"
	desc = "Tackle a mob, making them fall over."
	cooldown = 150
	icon_state = "tackle"
	targeted = 1
	target_anything = 1

	var/datum/projectile/slam/proj = new

/datum/targetable/critter/tackle/cast(atom/target)
	if (..())
		return TRUE
	if (isobj(target))
		target = get_turf(target)
	if (isturf(target))
		target = locate(/mob/living) in target
		if (!target)
			boutput(holder.owner, "<span class='alert'>Nothing to tackle there.</span>")
			return TRUE
	if (target == holder.owner)
		return TRUE
	if (BOUNDS_DIST(holder.owner, target) > 0)
		boutput(holder.owner, "<span class='alert'>That is too far away to tackle.</span>")
		return TRUE
	playsound(target, 'sound/impact_sounds/Generic_Hit_1.ogg', 50, TRUE, -1)
	var/mob/MT = target
	MT.changeStatus("weakened", 3 SECONDS)
	holder.owner.visible_message("<span class='alert'><b>[holder.owner] tackles [MT]!</b></span>", "<span class='alert'>You tackle [MT]!</span>")
	return FALSE
