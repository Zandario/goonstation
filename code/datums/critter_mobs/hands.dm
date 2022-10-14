/obj/item/parts/dummy
	name = "dummyholder"

/// Pun.
/datum/handHolder
	/// Designation of the hand - purely for show.
	var/name = "left hand"
	/// Used for inhand icons.
	var/suffix = "-L"
	/// Pixel offset on the x axis for inhands.
	var/offset_x = 0
	/// Pixel offset on the y axis for inhands.
	var/offset_y = 0
	/// The layer of the inhands overlay.
	var/render_layer = MOB_INHAND_LAYER
	/// If not null, will show inhands normally, otherwise they won't display at all.
	var/show_inhands = 1
	/// The item held in the hand.
	var/obj/item/item
	/// The icon of the hand UI background.
	var/icon/icon = 'icons/mob/critter_ui.dmi'
	/// The icon state of the hand UI background.
	var/icon_state = "handn"
	/// Ease of life.
	var/atom/movable/screen/hud/screenObj
	/// Name for the dummy holder.
	var/limb_name = "left arm"
	/// If not null, the special limb to use when attack_handing.
	var/datum/limb/limb
	/// Self-explanatory.
	var/can_hold_items = 1
	/// Also self-explanatory.
	var/can_attack = 1
	/// Does this limb have a special thing for attacking at a distance.
	var/can_range_attack = 0
	var/image/obscurer
	var/cooldown_overlay = 0
	var/mob/holder = null

	/// Technically a dummy, do not set.
	var/obj/item/parts/limbholder

/datum/handHolder/New()
	..()
	obscurer = image('icons/mob/critter_ui.dmi', icon_state="hand_cooldown", layer=HUD_LAYER+2)

/datum/handHolder/disposing()
	if(screenObj)
		screenObj.dispose()
		screenObj = null
	item = null
	if(limb)
		limb.dispose()
		limb = null
	if(limbholder)
		limbholder.dispose()
		limbholder = null
	holder = null
	..()

/datum/handHolder/proc/spawn_dummy_holder()
	if (!limb)
		return
	limbholder = new /obj/item/parts/dummy
	limb.holder = limbholder
	limb.holder.name = limb_name
	limb.holder.limb_data = limb
	limb.holder.holder = holder

/datum/handHolder/proc/set_cooldown_overlay()
	if (!limb || !screenObj || cooldown_overlay)
		return
	var/cd = limb.is_on_cooldown(src.holder)
	if (cd > 0)
		cooldown_overlay = 1
		screenObj.overlays += obscurer
		SPAWN(cd)
			cooldown_overlay = 0
			screenObj.overlays -= obscurer

/datum/handHolder/proc/can_special_attack()
	if (!holder || !limb)
		return 0
	.= (holder.a_intent == INTENT_DISARM && limb.disarm_special) || (holder.a_intent == INTENT_HARM && limb.harm_special)
