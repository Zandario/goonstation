// ----------------------
// Fade into invisibility
// ----------------------
/datum/action/invisibility
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "invisibility"
	var/icon = 'icons/mob/critter_ui.dmi'
	var/icon_state = "invisible_over"
	var/obj/overlay/iicon = null
	var/datum/targetable/critter/fadeout/ability = null
	var/did_fadein = 0

/datum/action/invisibility/onUpdate()
	..()
	if (ability && owner && state == ACTIONSTATE_RUNNING)
		var/mob/M = owner
		APPLY_ATOM_PROPERTY(M, PROP_MOB_INVISIBILITY, ability, ability.inv_level)

/datum/action/invisibility/onInterrupt(var/flag = 0)
	..()
	if (did_fadein)
		return
	did_fadein = 1
	var/atom/movable/A = owner
	if (owner && islist(A.attached_objs))
		A.attached_objs -= iicon
	if (ability)
		ability.fade_in()
	else if (owner)
		var/mob/M = owner
		REMOVE_ATOM_PROPERTY(M, PROP_MOB_INVISIBILITY, ability)
	if (iicon)
		del iicon
	qdel(src)

/datum/action/invisibility/onStart()
	..()
	state = ACTIONSTATE_INFINITE
	if (!owner || !ability)
		interrupt(INTERRUPT_ALWAYS)
		return
	ability.last_action = src
	if (!iicon)
		iicon = new
		iicon.mouse_opacity = 0
		iicon.name = null
		iicon.icon = icon
		iicon.icon_state = icon_state
		iicon.pixel_y = 5
		owner << iicon

/datum/action/invisibility/onDelete()
	..()
	if (iicon)
		del iicon
	return

/datum/targetable/critter/fadeout
	name = "Fade Out"
	desc = "Become invisible until you move. Invisibility lingers for a few seconds after moving or acting."
	var/inv_level = INVIS_SPOOKY
	var/fade_out_icon_state = null
	var/fade_in_icon_state = null
	var/fade_anim_length = 3
	var/linger_time = 30
	var/datum/action/invisibility/last_action
	cooldown = 300
	icon_state = "invisibility"

/datum/targetable/critter/fadeout/cast(atom/target)
	if (disabled)
		return TRUE
	if (..())
		return TRUE
	disabled = TRUE
	boutput(holder.owner, "<span class='notice'>You fade out of sight.</span>")
	var/datum/action/invisibility/I = new
	I.owner = holder.owner
	I.ability = src
	var/wait = 5
	if (fade_out_icon_state)
		flick(fade_out_icon_state, holder.owner)
		wait = fade_anim_length
	else
		animate(holder.owner, alpha=64, time=5)
	SPAWN(wait)
		APPLY_ATOM_PROPERTY(holder.owner, PROP_MOB_INVISIBILITY, src, inv_level)
		holder.owner.alpha = 64
		actions.start(I, holder.owner)
	return FALSE

/datum/targetable/critter/fadeout/proc/fade_in()
	if (holder.owner)
		boutput(holder.owner, "<span class='alert'>You fade back into sight!</span>")
		disabled = FALSE
		doCooldown()
		SPAWN(linger_time)
			REMOVE_ATOM_PROPERTY(holder.owner, PROP_MOB_INVISIBILITY, src)
			if (fade_in_icon_state)
				flick(fade_in_icon_state, holder.owner)
				holder.owner.alpha = 255
			else
				holder.owner.alpha = 64
				animate(holder.owner, alpha=255, time=5)

/datum/targetable/critter/fadeout/brullbar
	fade_in_icon_state = "brullbar_appear"
	fade_out_icon_state = "brullbar_melt"
	fade_anim_length = 12
