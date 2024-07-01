
/obj/fluid_pipe/source/inlet_pump
	name = "Inlet Pump"
	icon_state = "pipe-t"
	pipe_shape = "source"
	pipe_type = FLUIDPIPE_SOURCE
	//icon = 'icons/obj/atmospherics/valve.dmi'
	//icon_state = "valve0"
	color = rgb(255,0,0)

	var/open = FALSE

/obj/fluid_pipe/source/inlet_pump/New()
	START_TRACKING_CAT(TR_CAT_ATMOS_MACHINES)
	..()

/obj/fluid_pipe/source/inlet_pump/disposing()
	STOP_TRACKING_CAT(TR_CAT_ATMOS_MACHINES)
	..()

/obj/fluid_pipe/source/inlet_pump/attack_hand(mob/user)
	if(src.open)
		src.open = FALSE
		src.color = rgb(255, 0, 0)
		boutput(user, "You close the fluid pipe valve.")
	else
		src.open = TRUE
		src.color = rgb(0, 255, 0)
		boutput(user, "You open the fluid pipe valve.")

/obj/fluid_pipe/source/inlet_pump/proc/process()
	if(!src.open)
		return
	var/turf/simulated/T = get_turf(src)
	if(isnull(T.active_liquid))
		return
	var/datum/reagents/Removed = T.active_liquid.group.suck(T.active_liquid, src.used_capacity)

	DEBUG_MESSAGE_VARDBG("sucked up", Removed)

	for(var/reagent_id in Removed.reagent_list)
		var/datum/reagent/current = Removed.reagent_list[reagent_id]
		src.network.pipe_cont.add_reagent(reagent_id, current.volume, current.data)


/obj/fluid_pipe/sink/outlet_pump
	name = "Outlet Pump"
	icon_state = "pipe-t"
	pipe_shape = "sink"
	pipe_type = FLUIDPIPE_SINK
	//icon = 'icons/obj/atmospherics/valve.dmi'
	//icon_state = "valve0"
	color = rgb(255, 0, 0)

	var/open = FALSE

/obj/fluid_pipe/sink/outlet_pump/New()
	START_TRACKING_CAT(TR_CAT_ATMOS_MACHINES)
	..()

/obj/fluid_pipe/sink/outlet_pump/disposing()
	STOP_TRACKING_CAT(TR_CAT_ATMOS_MACHINES)
	..()

/obj/fluid_pipe/sink/outlet_pump/attack_hand(mob/user)
	if(src.open)
		src.open = FALSE
		src.color = rgb(255, 0, 0)
		boutput(user, "You close the fluid pipe valve.")
	else
		src.open = TRUE
		src.color = rgb(0, 255, 0)
		boutput(user, "You open the fluid pipe valve.")


/obj/fluid_pipe/sink/outlet_pump/proc/process()
	if(!src.open)
		return

	var/turf/simulated/T = get_turf(src)
	T.fluid_react(src.network.pipe_cont.reagent_list, src.used_capacity)
	src.network.pipe_cont.remove_any(src.used_capacity)
