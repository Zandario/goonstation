
/turf/var/obj/fluid/airborne/active_airborne_liquid = null


//What follows is not for the faint of heart.
// I have done a shitton of copy paste from the base obj/fluid type.
// This is messy as fuck, but its the fastest solution i could think of CPU wise

/obj/fluid/airborne
	name = "vapor"
	desc = "It's a free-flowing airborne state of matter!"
	icon_state = "airborne"
	opacity = 0
	layer = FLUID_AIR_LAYER

	do_iconstate_updates = FALSE


/obj/fluid/airborne/set_up(newloc, do_enters = TRUE)
	if(src.is_setup)
		CRASH("Fluid object already set up.")
	if(!newloc)
		CRASH("Fluid object set_up was called without a newloc.")

	if(isturf(newloc) && waterflow_enabled)
		var/turf/turf_loc = newloc // Just for sanity.
		set_loc(turf_loc)
		src.loc = turf_loc
		src.our_turf = turf_loc
		src.our_turf.active_airborne_liquid = src
		src.is_setup = TRUE
	else
		src.removed()
		src.is_setup = FALSE // Should be already false, but just in case.

	return src.is_setup


/obj/fluid/airborne/done_init()
	var/i = 0
	for(var/atom/movable/A in range(0, src))
		if(QDELETED(src))
			return
		src.Crossed(A)
		i++
		if(i > 40)
			break


/obj/fluid/airborne/trigger_fluid_enter()
	for(var/atom/A in src.loc)
		if (src.group && !src.group.disposed && A.event_handler_flags & USE_FLUID_ENTER)
			A.EnteredAirborneFluid(src, src.loc)
	if(src.group && !src.group.disposed)
		src.loc?.EnteredAirborneFluid(src, src.loc)


/obj/fluid/airborne/turf_remove_cleanup(turf/the_turf)
	the_turf.active_airborne_liquid = null


/obj/fluid/airborne/disposing()
	//this is slow, hopefully we can do without
	//if (src.group)
		//if (src in src.group.members)
		//	src.group.members -= src

	src.group = null
	src.touched_other_group = null
	..()


//ALTERNATIVE to force ingest in life
/obj/fluid/airborne/proc/just_do_the_apply_thing(mob/M, mult = 1, hasmask = FALSE)
	if (!M) return
	if (check_target_immunity(M, TRUE))
		return
	if (!src.group || !src.group.reagents || !src.group.reagents.reagent_list) return

	var/react_volume = src.volume > 10 ? (src.volume - 10) / 3 + 10 : (src.volume)
	react_volume = min(react_volume,20) * mult
	if (M.reagents)
		react_volume = min(react_volume, abs(M.reagents.maximum_volume - M.reagents.total_volume)) //don't push out other reagents if we are full

	var/turf/T = get_turf(src)
	var/list/plist = list()
	plist["dmg_multiplier"] = 0.08
	if (T) //average that shit with the air temp
		var/turftemp = T.temperature
		plist["override_can_burn"] = (src.group.reagents.total_temperature + turftemp + turftemp) / 3

	src.group.reagents.reaction(M, TOUCH, react_volume/2, 0, paramslist = plist)

	if (!hasmask)
		src.group.reagents.reaction(M, INGEST, react_volume/2,1,src.group.members.len, paramslist = plist)
		src.group.reagents.trans_to(M, react_volume)


// Called when mob is drowning/standing in the smoke
/obj/fluid/airborne/force_mob_to_ingest(mob/M, mult = 1)
	if(!M || check_target_immunity(M, TRUE) || !src?.group?.reagents?.reagent_list)
		return

	var/react_volume = (src.volume > 10) ? ((src.volume - 10) / 3 + 10) : src.volume
	react_volume = min(react_volume, 20) * mult
	if (M.reagents)
		react_volume = min(react_volume, abs(M.reagents.maximum_volume - M.reagents.total_volume)) //don't push out other reagents if we are full

	var/turf/T = get_turf(src)
	var/list/plist = list()
	plist["dmg_multiplier"] = 0.08
	plist += "inhaled"
	if (T) //average that shit with the air temp
		var/turftemp = T.temperature
		plist["override_can_burn"] = (src.group.reagents.total_temperature + turftemp + turftemp) / 3

	src.group.reagents.reaction(M, TOUCH, react_volume/2, 0, paramslist = plist)
	src.group.reagents.reaction(M, INGEST, react_volume/2,1,src.group.members.len, paramslist = plist)
	src.group.reagents.trans_to(M, react_volume)


// TODO: Incorporate touch_modifier?
/obj/fluid/airborne/Crossed(atom/movable/AM)
	..()

	if((QDELETED(src.group?.reagents) || istype(AM, /obj/fluid)))
		return
	else
		AM.EnteredAirborneFluid(src, AM.last_turf)
	return


/obj/fluid/airborne/add_tracked_blood(atom/movable/AM)
	return FALSE


/obj/fluid/airborne/update()
	if(!waterflow_enabled)
		return
	if(QDELETED(src.group)) //uh oh
		src.removed()
		return

	var/spawned_any = FALSE
	var/list/obj/fluid/Flist = list()

	// Reset some vars.
	src.last_spread_was_blocked = TRUE
	src.touched_channel = null
	src.blocked_dirs = 0

	purge_smoke_blacklist(src.group.reagents)

	var/turf/neighbor

	for(var/dir in global.cardinal)
		blocked_perspective_dirs &= ~dir
		neighbor = get_step(src, dir)
		if(QDELETED(neighbor)) //the fuck? how
			continue // Actually this is probably because of oceans :)

		if(!IS_VALID_FLUID_TURF(neighbor))
			src.blocked_dirs++
			if(IS_PERSPECTIVE_WALL(neighbor))
				src.blocked_perspective_dirs |= dir
			continue

		if(!QDELETED(neighbor.active_airborne_liquid))
			src.blocked_dirs++
			if(neighbor.active_airborne_liquid?.group != src.group)
				src.touched_other_group = neighbor.active_airborne_liquid.group
				neighbor.active_airborne_liquid.set_icon_state("airborne")
			continue

		if(neighbor.gas_cross(src))
			var/can_flow_to = TRUE
			var/obj/pushable_obj = null

			// HEY maybe do item pushing here since you're looping thru turf contents anyway??
			for(var/obj/thing in neighbor.contents)
				var/found = FALSE
				if(IS_SOLID_TO_FLUID(thing))
					found = TRUE
				else if(isnull(pushable_obj) && !thing.anchored)
					pushable_obj = thing

				// for(var/type_string in solid_to_fluid)
				// 	if(istype(thing, text2path(type_string)))
				// 		found = TRUE
				// 		break

				if(!found)
					continue

				if(thing.density)
					can_flow_to = FALSE
					blocked_dirs++
					if(IS_PERSPECTIVE_BLOCK(thing))
					// for(var/type_string in perspective_blocks)
					// 	if (istype(thing,text2path(type_string)))
						src.blocked_perspective_dirs |= dir
					break

				if(istype(thing, /obj/channel))
					src.touched_channel = thing //Save this for later, we can't make use of it yet
					can_flow_to = FALSE
					break

			// If we can flow to the neighbor, and our group is still valid.
			if(can_flow_to && !QDELETED(src.group))
				spawned_any = TRUE
				src.set_icon_state("airborne")

				var/obj/fluid/airborne/AF = new(neighbor)
				AF.set_up(neighbor, FALSE)

				if(QDELETED(AF) || QDELETED(src.group))
					continue //set_up may decide to remove F

				AF.volume = src.group.volume_per_tile
				AF.color = src.finalcolor
				AF.finalcolor = src.finalcolor
				AF.alpha = src.finalalpha
				AF.finalalpha = src.finalalpha
				AF.avg_viscosity = src.avg_viscosity
				AF.last_depth_level = src.last_depth_level
				AF.step_sound = src.step_sound
				AF.movement_speed_mod = src.movement_speed_mod

				if(src.group)
					src.group.add(AF, src.group.volume_per_tile)
					AF.group = src.group
				else
					var/datum/fluid_group/FG = new
					FG.add(AF, src.group.volume_per_tile)
					AF.group = FG

				Flist.Add(AF)

				AF.done_init()
				src.last_spread_was_blocked = FALSE

				if(pushable_obj && prob(50))
					if(src.last_depth_level <= 3)
						if(isitem(pushable_obj))
							var/obj/item/I = pushable_obj
							if(I.w_class <= src.last_depth_level)
								step_away(I, src)
					else
						step_away(pushable_obj, src)

				AF.trigger_fluid_enter()

	if(spawned_any && prob(40))
		playsound(our_turf || src.loc, 'sound/effects/smoke_tile_spread.ogg', 30, 1, 7)

	return Flist


// Read the proc's definition for more info
/obj/fluid/airborne/get_connected_fluids(adjacent_match_quit = 0)
	if(!src.group)
		return list(src)

	var/list/obj/fluid/airborne/Flist = list()
	var/list/obj/fluid/airborne/Fqueue = list(src)
	var/list/visited = list()

	var/turf/neighbor
	var/obj/fluid/airborne/neighbor_fluid

	var/obj/fluid/airborne/current_fluid = null
	var/visited_changed = FALSE

	while(Fqueue.len)
		current_fluid = Fqueue[1]
		Fqueue.Cut(1, 2)

		for(var/dir in global.cardinal)
			neighbor = get_step(current_fluid, dir)
			if(!VALID_FLUID_CONNECTION(current_fluid, neighbor))
				continue

			if(!neighbor.active_airborne_liquid.group)
				neighbor.active_airborne_liquid.removed()
				continue

			neighbor_fluid = neighbor.active_liquid

			//Old method : search through 'visited' for 'neighbor_fluid'. Probably slow when you have big groups!!
			//if(neighbor_fluid in visited) continue
			//visited += neighbor_fluid

			// New method : Add the liquid at a specific index.
			// To check whether the node has already been visited,
			// just compare the len of the visited group from before + after the index has been set.
			//
			// Probably slower for small groups and much faster for large groups.
			visited_changed = length(visited)
			visited["[neighbor_fluid.x]_[neighbor_fluid.y]_[neighbor_fluid.z]"] = neighbor_fluid
			visited_changed = (visited.len != visited_changed)

			if (visited_changed)
				Fqueue.Add(neighbor_fluid)
				Flist.Add(neighbor_fluid)

				if(adjacent_match_quit)
					if(src.temp_removal_key && src != neighbor_fluid && src.temp_removal_key == neighbor_fluid.temp_removal_key)
						adjacent_match_quit--
						if(adjacent_match_quit <= 0)
							return null //bud nippin


/obj/fluid/airborne/try_connect_to_adjacent()
	var/turf/neighbor
	var/obj/fluid/airborne/neighbor_fluid

	for(var/dir in global.cardinal)
		neighbor = get_step(src, dir)

		if(QDELETED(neighbor?.active_airborne_liquid))
			continue

		neighbor_fluid = neighbor.active_airborne_liquid

		if(neighbor_fluid?.group && src.group != neighbor_fluid.group)
			neighbor_fluid.group.join(src.group)

	return


//BE WARNED THIS PROC HAS A REPLICA UP ABOVE IN FLUID GROUP UPDATE_LOOP. DO NOT CHANGE THIS ONE WITHOUT MAKING THE SAME CHANGES UP THERE OH GOD I HATE THIS
/obj/fluid/airborne/update_icon(neighbor_was_removed = FALSE)
	if(QDELETED(src.group?.reagents))
		return

	var/datum/color/average = src.group.average_color ? src.group.average_color : src.group.reagents.get_average_color()
	src.finalalpha = max(25, (average.a / 255) * src.group.max_alpha)
	src.finalcolor = rgb(average.r, average.g, average.b)

	animate(src, color = src.finalcolor, alpha = finalalpha, time = 5)

	if(neighbor_was_removed)
		src.last_spread_was_blocked = FALSE

	//air specific:
	src.set_opacity(src.group.reagents.get_master_reagent_gas_opaque())

	return


/obj/fluid/airborne/update_perspective_overlays() // fancy perspective overlaying
	return FALSE


/obj/fluid/airborne/display_overlay(overlay_key, pox, poy)
	return FALSE


/obj/fluid/airborne/clear_overlay(key = 0)
	return FALSE
