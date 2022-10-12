// --------------------
// Brullbar style frenzy
// --------------------
/datum/targetable/critter/frenzy
	name = "Frenzy"
	desc = "Go into a bloody frenzy on a weakened target and rip them to shreds."
	cooldown = 350
	targeted = 1
	target_anything = 1
	icon_state = "frenzy"

	var/datum/projectile/slam/proj = new

/datum/targetable/critter/frenzy/cast(atom/target)
	if (disabled && world.time > last_cast)
		disabled = FALSE // break the deadlock
	if (disabled)
		return TRUE
	if (..())
		return TRUE
	if (isobj(target))
		target = get_turf(target)
	if (isturf(target))
		for (var/mob/living/M in target)
			if (is_incapacitated(M))
				target = M
				break
	if (target == holder.owner)
		return TRUE
	if (!ismob(target))
		boutput(holder.owner, "<span class='alert'>Nothing to frenzy at there.</span>")
		return TRUE
	if (BOUNDS_DIST(holder.owner, target) > 0)
		boutput(holder.owner, "<span class='alert'>That is too far away to frenzy.</span>")
		return TRUE
	var/mob/MT = target
	if (!is_incapacitated(MT))
		boutput(holder.owner, "<span class='alert'>That is moving around far too much to pounce.</span>")
		return TRUE
	playsound(holder.owner, 'sound/voice/animal/brullbar_roar.ogg', 80, 1)
	disabled = TRUE
	SPAWN(0)
		var/frenz = rand(10, 20)
		holder.owner.canmove = FALSE
		while (frenz > 0 && MT && !MT.disposed)
			MT.changeStatus("weakened", 2 SECONDS)
			MT.canmove = FALSE
			if (MT.loc)
				holder.owner.set_loc(MT.loc)
			if (is_incapacitated(holder?.owner))
				break
			playsound(holder.owner, 'sound/voice/animal/brullbar_maul.ogg', 80, TRUE)
			holder.owner.visible_message("<span class='alert'><b>[holder.owner] [pick("mauls", "claws", "slashes", "tears at", "lacerates", "mangles")] [MT]!</b></span>")
			holder.owner.set_dir((cardinal))
			holder.owner.pixel_x = rand(-5, 5)
			holder.owner.pixel_y = rand(-5, 5)
			random_brute_damage(MT, 10,1)
			take_bleeding_damage(MT, null, 5, DAMAGE_CUT, 0, get_turf(MT))
			if(prob(33)) // don't make quite so much mess
				bleed(MT, 5, 5, get_step(get_turf(MT), pick(alldirs)), 1)
			sleep(0.4 SECONDS)
			frenz--
		if (MT)
			MT.canmove = TRUE
		doCooldown()
		disabled = FALSE
		holder.owner.pixel_x = 0
		holder.owner.pixel_y = 0
		holder.owner.canmove = 1

	return FALSE

/datum/targetable/critter/crabmaul
	name = "Crustaceous Frenzy"
	desc = "Go into a primal rage, snipping a weakened target to ribbons with your claws."
	cooldown = 1 MINUTE
	targeted = 1
	target_anything = 1
	icon_state = "claw_maul"

	var/datum/projectile/slam/proj = new

/datum/targetable/critter/crabmaul/cast(atom/target)
	if (disabled && world.time > last_cast)
		disabled = FALSE // break the deadlock
	if (disabled)
		return TRUE
	if (..())
		return TRUE
	if (isobj(target))
		target = get_turf(target)
	if (isturf(target))
		for (var/mob/living/M in target)
			if (is_incapacitated(M))
				target = M
				break
	if (target == holder.owner)
		return TRUE
	if (!ismob(target))
		boutput(holder.owner, "<span class='alert'>Nothing to snip apart there.</span>")
		return TRUE
	if (BOUNDS_DIST(holder.owner, target) > 0)
		boutput(holder.owner, "<span class='alert'>That is too far away to pinch.</span>")
		return TRUE
	var/mob/MT = target
	if (!is_incapacitated(MT))
		boutput(holder.owner, "<span class='alert'>That is far too tall to pounce on.</span>")
		return TRUE
	playsound(holder.owner, 'sound/items/Scissor.ogg', 100, TRUE, 0, 3)
	disabled = TRUE
	SPAWN(0)
		var/frenz = rand(10, 20)
		holder.owner.canmove = FALSE
		while (frenz > 0 && MT && !MT.disposed)
			MT.changeStatus("weakened", 1 SECONDS)
			MT.canmove = FALSE
			if (MT.loc)
				holder.owner.set_loc(MT.loc)
			if (is_incapacitated(holder?.owner))
				break
			playsound(holder.owner, 'sound/items/Scissor.ogg', 90, TRUE, 1, 2)
			holder.owner.visible_message("<span class='alert'><b>[holder.owner] [pick("mauls", "claws", "slashes", "tears at", "lacerates", "mangles")] [MT]!</b></span>")
			holder.owner.set_dir((cardinal))
			holder.owner.pixel_x = rand(-5, 5)
			holder.owner.pixel_y = rand(-5, 5)
			random_brute_damage(MT, 4,1)
			take_bleeding_damage(MT, null, 3, DAMAGE_CUT, 3, get_turf(MT))
			if(prob(20)) // don't make quite so much mess
				bleed(MT, 2, 2, get_step(get_turf(MT), pick(alldirs)), 1)
			sleep(0.4 SECONDS)
			frenz--
		if (MT)
			MT.canmove = TRUE
		doCooldown()
		disabled = FALSE
		holder.owner.pixel_x = 0
		holder.owner.pixel_y = 0
		holder.owner.canmove = 1

	return FALSE
