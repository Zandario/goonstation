/datum/equipmentHolder
	/// Designation of the equipment holder.
	var/name = "head"
	/// Pixel offset on the x axis for mob overlays.
	var/offset_x = 0
	/// Pixel offset on the x axis for mob overlays.
	var/offset_y = 0
	/// Should this be displayed on the mob?
	var/show_on_holder = 1
	var/armor_coverage = 0
	/// The icon of the HUD object.
	var/icon/icon = 'icons/mob/hud_human.dmi'
	/// The icon state of the HUD object.
	var/icon_state = "hair"
	/// The item being worn in this slot.
	var/obj/item/item

	/// A list of parent types whose subtypes are equippable.
	var/list/type_filters = list()
	/// Ease of life.
	var/atom/movable/screen/hud/screenObj

	var/mob/holder = null

	var/equipment_layer = MOB_CLOTHING_LAYER

/datum/equipmentHolder/New(mob/M)
	..()
	holder = M

/datum/equipmentHolder/disposing()
	if(screenObj)
		screenObj.dispose()
		screenObj = null
	item = null
	holder = null
	..()


/datum/equipmentHolder/proc/can_equip(obj/item/I)
	for (var/T in type_filters)
		if (istype(I, T))
			return 1
	return 0

/datum/equipmentHolder/proc/equip(obj/item/I)
	if (item || !can_equip(I))
		return 0
	if (screenObj)
		I.screen_loc = screenObj.screen_loc
	item = I
	item.set_loc(holder)
	holder.update_clothing()
	on_equip()
	return 1

/datum/equipmentHolder/proc/drop(force = 0)
	if (!item)
		return 0
	if ((item.cant_drop || item.cant_other_remove) && !force)
		return 0
	item.set_loc(get_turf(holder))
	item.master = null
	item.layer = initial(item.layer)
	on_unequip()
	item = null
	holder.update_clothing()
	return 1

/datum/equipmentHolder/proc/remove()
	if (!item)
		return 0
	if (item.cant_self_remove)
		return 0
	if (!holder.put_in_hand(item))
		return 0
	on_unequip()
	item = null
	return 1

/datum/equipmentHolder/proc/on_update()

/datum/equipmentHolder/proc/on_equip()

/datum/equipmentHolder/proc/on_unequip()

/datum/equipmentHolder/proc/after_setup(datum/hud)


/datum/equipmentHolder/head
	name = "head"
	type_filters = list(/obj/item/clothing/head)
	icon = 'icons/mob/hud_human.dmi'
	icon_state = "hair"
	armor_coverage = HEAD

/datum/equipmentHolder/head/skeleton/
	var/datum/equipmentHolder/head/skeleton/next
	var/datum/equipmentHolder/head/skeleton/prev

/datum/equipmentHolder/head/skeleton/on_update()
	var/o = 0
	var/datum/equipmentHolder/head/skeleton/c = prev
	while (c)
		if (c.item)
			o += 3
		c = c.prev
	offset_y = o

/datum/equipmentHolder/head/skeleton/proc/spawn_next()
	next = new /datum/equipmentHolder/head/skeleton(holder)
	next.prev = src
	return next

/datum/equipmentHolder/head/bird
	offset_y = -5

/datum/equipmentHolder/head/on_update()
	if (istype(holder, /mob/living/critter/small_animal/bird))
		var/mob/living/critter/small_animal/bird/B = holder
		offset_y = B.hat_offset_y
		offset_x = B.hat_offset_x


/datum/equipmentHolder/head/bee
	offset_y = -6

/datum/equipmentHolder/head/slime
	offset_y = -15

/datum/equipmentHolder/suit
	name = "suit"
	type_filters = list(/obj/item/clothing/suit)
	icon = 'icons/mob/hud_human.dmi'
	icon_state = "armor"
	armor_coverage = TORSO

/datum/equipmentHolder/ears
	name = "ears"
	type_filters = list(/obj/item/device/radio)
	icon = 'icons/mob/hud_human.dmi'
	icon_state = "ears"

/datum/equipmentHolder/ears/on_equip()
	holder.ears = item

/datum/equipmentHolder/ears/on_unequip()
	holder.ears = null


/datum/equipmentHolder/ears/intercom/after_setup(datum/hud/hud)
	var/obj/item/device/radio/intercom/O = new(holder)
	equip(O)
	// it's a built in radio, they can't take it off.
	O.cant_self_remove = TRUE
	O.cant_other_remove = TRUE

/datum/equipmentHolder/ears/intercom/syndicate/after_setup(datum/hud/hud)
	var/obj/item/device/radio/intercom/syndicate/S = new(holder)
	equip(S)
	// it's a built in radio, they can't take it off.
	S.cant_self_remove = TRUE
	S.cant_other_remove = TRUE
