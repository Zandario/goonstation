///////////////////
//////canister//////
///////////////////


TYPEINFO(/obj/machinery/fluid_canister)
	mats = 20

/obj/machinery/fluid_canister
	anchored = UNANCHORED
	density = 1
	icon = 'icons/obj/fluid.dmi'
	var/base_icon = "blue"
	icon_state = "blue0"
	name = "fluid canister"
	desc = "A canister that can drink large amounts of fluid and spit it out somewhere else. Gross."
	var/bladder = 20000 //how much I can hold
	var/slurp = 10 //tiles of fluid to drain per tick
	var/piss = 500 //volume of reagents to piss out per tick
	deconstruct_flags = DECON_CROWBAR | DECON_WELDER

	var/slurping = FALSE
	var/pissing = FALSE

	var/contained = FALSE

	var/list/datum/contextAction/contexts = list()


/obj/machinery/fluid_canister/New()
	contextLayout = new /datum/contextLayout/experimentalcircle
	..()
	for(var/actionType in childrentypesof(/datum/contextAction/fluid_canister))
		src.contexts += new actionType()

	src.reagents = new /datum/reagents(bladder)
	src.reagents.my_atom = src
	UpdateIcon()


/obj/machinery/fluid_canister/disposing()
	if(src.reagents.total_volume > 0)
		var/turf/T = get_turf(src)
		if(T.active_liquid)
			var/obj/fluid/F = T.active_liquid
			if(F.group)
				src.reagents.trans_to_direct(F.group.reagents, src.reagents.total_volume)
		else
			T.fluid_react(src.reagents,src.reagents.total_volume)
	..()


/obj/machinery/fluid_canister/ex_act(severity)
	var/turf/T = get_turf(src)
	T.fluid_react(src.reagents, src.reagents.total_volume)
	src.reagents.clear_reagents()
	..(severity)
	qdel(src)


/obj/machinery/fluid_canister/is_open_container()
	return -1



/obj/machinery/fluid_canister/process()
	if(contained)
		return

	if(slurping)
		if(src.reagents.total_volume < src.reagents.maximum_volume)
			var/turf/T = get_turf(src)
			if(T.active_liquid?.group?.reagents)
				T.active_liquid.group.drain(T.active_liquid, slurp, src)
				if(prob(80))
					playsound(src.loc, 'sound/impact_sounds/Liquid_Slosh_1.ogg', 25, 0.1, 0.7)

			UpdateIcon()

	else if(pissing)
		if(src.reagents.total_volume > 0)
			var/turf/T = get_turf(src)
			if(T.active_liquid)
				var/obj/fluid/F = T.active_liquid
				if(F.group)
					src.reagents.trans_to_direct(F.group.reagents, min(piss, src.reagents.total_volume))
			else
				if(istype(T, /turf/space/fluid))
					src.reagents.clear_reagents()
				else
					T.fluid_react(src.reagents,min(piss,src.reagents.total_volume))

			UpdateIcon()


/obj/machinery/fluid_canister/update_icon()
	var/volume = round((src.reagents.total_volume / src.reagents.maximum_volume) * 12, 1)
	icon_state = "[base_icon][volume]"

	var/overlay_istate = "w_off"
	if(slurping)
		overlay_istate = "w_2"
	else if(pissing)
		overlay_istate = "w_1"
	else
		overlay_istate = "w_off"

	AddOverlays(SafeGetOverlayImage("working", 'icons/obj/fluid.dmi', overlay_istate), "working")

	var/activetext = "OFF"
	if(slurping)
		activetext = "IN"
	if(pissing)
		activetext = "OUT"

	desc = initial(desc) + \
		" The pump is set to <em>[activetext]</em>." + \
		" It's currently holding <em>[src.reagents.total_volume] units</em>."


	for(var/datum/contextAction/fluid_canister/button in src.contexts)
		switch(button.type)
			if(/datum/contextAction/fluid_canister/off)
				button.icon_state = activetext == "OFF" ? "off" : "off_active"
			if(/datum/contextAction/fluid_canister/slurp)
				button.icon_state = activetext == "IN" ? "in_active" : "in"
			if(/datum/contextAction/fluid_canister/piss)
				button.icon_state = activetext == "OUT" ? "out_active" : "out"


/obj/machinery/fluid_canister/attack_hand(var/mob/user)
	user.showContextActions(src.contexts, src, src.contextLayout)
	return


/obj/machinery/fluid_canister/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/atmosporter))
		var/obj/item/atmosporter/porter = W
		if(length(porter.contents) >= porter.capacity)
			boutput(user, SPAN_ALERT("Your [W] is full!"))
		else
			user.visible_message(SPAN_NOTICE("[user] collects the [src]."), SPAN_NOTICE("You collect the [src]."))
			src.contained = TRUE
			src.set_loc(W)
			elecflash(user)
	..()

/obj/machinery/fluid_canister/proc/change_mode(var/mode)
	switch(mode)
		if(FLUID_CANISTER_MODE_OFF)
			slurping = FALSE
			pissing = FALSE
		if(FLUID_CANISTER_MODE_SLURP)
			slurping = TRUE
			pissing = FALSE
		if(FLUID_CANISTER_MODE_PISS)
			slurping = FALSE
			pissing = TRUE
	UpdateIcon()


/datum/contextAction/fluid_canister
	icon = 'icons/ui/context16x16.dmi'
	close_clicked = TRUE
	close_moved = TRUE
	desc = ""
	var/mode = FLUID_CANISTER_MODE_OFF

/datum/contextAction/fluid_canister/execute(var/obj/machinery/fluid_canister/fluid_canister)
	if(!istype(fluid_canister))
		return
	fluid_canister.change_mode(src.mode)

/datum/contextAction/fluid_canister/checkRequirements(obj/machinery/fluid_canister/fluid_canister, mob/user)
	. = can_act(user) && in_interact_range(fluid_canister, user)


/datum/contextAction/fluid_canister/off
	name = "OFF"
	icon_state = "off"
	mode = FLUID_CANISTER_MODE_OFF

/datum/contextAction/fluid_canister/slurp
	name = "IN"
	icon_state = "in"
	mode = FLUID_CANISTER_MODE_SLURP

/datum/contextAction/fluid_canister/piss
	name = "OUT"
	icon_state = "out"
	mode = FLUID_CANISTER_MODE_PISS
