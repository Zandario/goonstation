/datum/targetable/werewolf/werewolf_transform
	name = "Transform"
	desc = "Switch between human and wolf form, Takes a couple seconds to complete."
	icon_state = "transform"  // No custom sprites yet.
	targeted = 0
	target_nodamage_check = 0
	max_range = 0
	cooldown = 900
	pointCost = 0
	when_stunned = 1
	not_when_handcuffed = 0
	werewolf_only = 0

/datum/targetable/werewolf/werewolf_transform/cast(mob/target)
	if (!holder)
		return TRUE

	var/mob/living/M = holder.owner

	if (!M)
		return TRUE

	actions.start(new/datum/action/bar/private/icon/werewolf_transform(src), M)
	return FALSE

/datum/action/bar/private/icon/werewolf_transform
	duration = 50
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_ACTION
	id = "werewolf_transform"
	icon = 'icons/mob/screen1.dmi'
	icon_state = "grabbed"
	var/datum/targetable/werewolf/werewolf_transform/transform

/datum/action/bar/private/icon/werewolf_transform/New(Transform)
	transform = Transform
	..()

/datum/action/bar/private/icon/werewolf_transform/onStart()
	..()

	var/mob/living/M = owner

	if (M == null || !ishuman(M) || M.stat != 0 || M.getStatusDuration("paralysis") || !transform)
		interrupt(INTERRUPT_ALWAYS)
		return

	boutput(M, "<span class='alert'><B>You feel a strong burning sensation all over your body!</B></span>")

/datum/action/bar/private/icon/werewolf_transform/onUpdate()
	..()

	var/mob/living/M = owner

	if (M == null || !ishuman(M) || M.stat != 0 || M.getStatusDuration("paralysis") || !transform)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/private/icon/werewolf_transform/onEnd()
	..()

	var/mob/living/M = owner
	M.werewolf_transform()

/datum/action/bar/private/icon/werewolf_transform/onInterrupt()
	..()

	var/mob/living/M = owner
	boutput(M, "<span class='alert'>Your transformation was interrupted!</span>")
	transform.last_cast = 0 //reset cooldown
