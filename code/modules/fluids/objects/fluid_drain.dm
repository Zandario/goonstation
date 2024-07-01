TYPEINFO(/obj/machinery/drainage)
	mats = 8

TYPEINFO(/obj/machinery/drainage/big)
	mats = 12

/obj/machinery/drainage
	name = "drain"
	desc = "A drainage pipe embedded in the floor to prevent flooding. Where does the drain go? Nobody knows."
	anchored = ANCHORED
	density = 0
	icon = 'icons/obj/fluid.dmi'
	var/base_icon = "drain"
	icon_state = "drain"
	plane = PLANE_FLOOR //They're supposed to be embedded in the floor.
	flags = FLUID_SUBMERGE | NOSPLASH
	var/clogged = 0 //temporary block
	var/welded = 0 //permanent block
	var/drain_min = 2
	var/drain_max = 7
	deconstruct_flags = DECON_SCREWDRIVER | DECON_WRENCH | DECON_CROWBAR | DECON_WELDER

/obj/machinery/drainage/big
	base_icon = "bigdrain"
	icon_state = "bigdrain"
	drain_min = 6
	drain_max = 14


/obj/machinery/drainage/New()
	START_TRACKING
	..()


/obj/machinery/drainage/disposing()
	. = ..()
	STOP_TRACKING


/obj/machinery/drainage/process()
	var/turf/T = get_turf(src)
	if(T?.active_liquid)
		if(clogged)
			clogged--
			return
		if(welded)
			return

		var/obj/fluid/F = T.active_liquid
		if(F.group)
			F.group.queued_drains += rand(drain_min, drain_max)
			F.group.last_turf_drained = T

			if(!F.group.draining)
				F.group.add_drain_process()

			playsound(src.loc, 'sound/misc/drain_glug.ogg', 50, 1)

			//moved to fluid process
			//F.group.reagents.skip_next_update = 1
			//F.group.drain(F,rand(drain_min,drain_max)) //420 drain it



/obj/machinery/drainage/attackby(obj/item/I, mob/user)
	if(isweldingtool(I))
		if(!I:try_weld(user, 2))
			return

		if(!src.welded)
			src.welded = TRUE
			logTheThing(LOG_STATION, user, "welded [name] shut at [log_loc(user)].")
			user.show_text("You weld the drain shut.")
		else
			logTheThing(LOG_STATION, user, "un-welded [name] at [log_loc(user)].")
			src.welded = FALSE
			user.show_text("You unseal the drain with your welder.")

		if(src.clogged)
			src.clogged = FALSE
			user.show_text("The drain clog melts away.")

		src.UpdateIcon()
		return

	if(istype(I, /obj/item/material_piece/cloth))
		var/obj/item/material_piece/cloth/C = I
		src.clogged += (20 * C.amount) //One piece of cloth clogs for about 1 minute. (cause the machine loop updates ~3 second interval)
		user.show_text("You stuff [I] into the drain.")
		logTheThing(LOG_STATION, user, "clogs [name] shut temporarily at [log_loc(user)].")
		qdel(I)
		src.UpdateIcon()
		return

	if(I.is_open_container() && I.reagents)
		boutput(user, SPAN_ALERT("You dump all the reagents into the drain.")) // we add NOSPLASH so the default beaker/glass-splash doesn't occur
		I.reagents.remove_any(I.reagents.total_volume) // just dump it all out
		return

	return ..()


/obj/machinery/drainage/update_icon()
	if(clogged)
		icon_state = "[base_icon]_clogged"
	else if(welded)
		icon_state = "[base_icon]_welded"
	else
		icon_state = "[base_icon]"
