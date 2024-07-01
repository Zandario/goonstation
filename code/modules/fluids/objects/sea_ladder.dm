/obj/sea_ladder_deployed
	name = "deployed sea ladder"
	desc = "A deployable sea ladder that will allow you to descend to and ascend from the trench."
	icon = 'icons/obj/fluid.dmi'
	icon_state = "ladder_on"
	event_handler_flags = IMMUNE_TRENCH_WARP

	var/obj/sea_ladder_deployed/linked_ladder
	var/obj/item/sea_ladder/og_ladder_item = 0
	anchored = ANCHORED

/obj/sea_ladder_deployed/verb/fold_up()
	set name = "Fold Up"
	set src in oview(1)
	set category = "Local"

	if (!og_ladder_item)
		if (linked_ladder?.og_ladder_item)
			og_ladder_item = linked_ladder.og_ladder_item
		else
			og_ladder_item = new /obj/item/sea_ladder(src.loc)
	og_ladder_item.set_loc(usr.loc)

	if (linked_ladder)
		qdel(linked_ladder)
	qdel(src)


/obj/sea_ladder_deployed/attack_hand(mob/user)
	if(!linked_ladder)
		return
	var/turf/target = 0

	for(var/turf/T in orange(1, linked_ladder))
		if(!istype(T, /turf/space/fluid/warp_z5))
			target = T
			break

	if(!target)
		user.show_text("This ladder does not lead to solid flooring!")
	else
		user.set_loc(target)
		user.show_text("You climb [src].")


/obj/sea_ladder_deployed/Click(location, control, params)
	if(isobserver(usr))
		return src.attack_hand(usr)
	..()


/obj/sea_ladder_deployed/attack_ai(mob/user)
	if(can_act(user) && in_interact_range(src, usr))
		return src.attack_hand(user)
	. = ..()



TYPEINFO(/obj/item/sea_ladder)
	mats = 7

/obj/item/sea_ladder
	name = "sea ladder"
	desc = "A deployable sea ladder that will allow you to descend to and ascend from the trench."
	icon = 'icons/obj/fluid.dmi'
	icon_state = "ladder_off"
	item_state = "sea_ladder"
	w_class = W_CLASS_NORMAL
	throwforce = 10
	flags = TABLEPASS | CONDUCT
	force = 9
	stamina_damage = 30
	stamina_cost = 20
	stamina_crit_chance = 6
	var/c_color = null


/obj/item/sea_ladder/New()
	..()
	src.setItemSpecial(/datum/item_special/swipe)
	BLOCK_SETUP(BLOCK_LARGE)


/obj/item/sea_ladder/afterattack(atom/target, mob/user)
	. = ..()
	if(istype(target, /turf/space/fluid/warp_z5/realwarp))
		var/turf/space/fluid/warp_z5/realwarp/hole = target
		var/datum/component/pitfall/target_coordinates/targetzcomp = hole.GetComponent(/datum/component/pitfall/target_coordinates)
		targetzcomp.update_targets()
		deploy_ladder(hole, pick(targetzcomp.TargetList), user)

	else if(istype(target, /turf/space/fluid/warp_z5))
		var/turf/space/fluid/warp_z5/hole = target
		var/datum/component/pitfall/target_area/targetacomp = hole.GetComponent(/datum/component/pitfall/target_area)
		deploy_ladder(hole, pick(get_area_turfs(targetacomp.TargetArea)), user)

	else if(istype(target, /turf/space/fluid))
		var/turf/space/fluid/T = target
		if(T.linked_hole)
			deploy_ladder(T, T.linked_hole, user)
		else if(istype(T.loc, /area/trench_landing))
			deploy_ladder(T, pick(by_type[/turf/space/fluid/warp_z5/edge]), user)


/obj/item/sea_ladder/proc/deploy_ladder(turf/source, turf/dest, mob/user)
	user.show_text("You deploy [src].")
	playsound(src.loc, 'sound/effects/airbridge_dpl.ogg', 60, 1)

	var/obj/sea_ladder_deployed/L = new /obj/sea_ladder_deployed(source)
	L.linked_ladder = new /obj/sea_ladder_deployed(dest)
	L.linked_ladder.linked_ladder = L

	user.drop_item()
	src.set_loc(L)
	L.og_ladder_item = src
	L.linked_ladder.og_ladder_item = src
