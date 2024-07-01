///////////////////
////Fluid Object///
///////////////////

var/global/waterflow_enabled = TRUE

var/global/list/depth_levels = list(2, 50, 100, 200)

ADMIN_INTERACT_PROCS(/obj/fluid, proc/admin_clear_fluid)
/obj/fluid
	name = "fluid"
	desc = "It's a free-flowing liquid state of matter!"
	icon = 'icons/obj/fluid.dmi'
	icon_state = "15"
	anchored = ANCHORED_ALWAYS
	mouse_opacity = FALSE
	layer = FLUID_LAYER
	flags = UNCRUSHABLE | OPENCONTAINER

	event_handler_flags = IMMUNE_MANTA_PUSH

	var/finalcolor = "#ffffff"
	color = "#ffffff"
	var/finalalpha = 100
	alpha = 255

	var/const/max_slip_volume = 30
	var/const/max_slip_viscosity = 10
	var/const/max_reagent_volume = 300

	/// The total volume of reagents we have - should be updated mainly by the group.
	var/volume = 0 // TODO: Rename to volume?

	var/const/max_viscosity = 20
	var/avg_viscosity = 1

	/// Max slowdown we can experience per slowdown type.
	var/const/max_speed_mod = 3
	///The highest movement_speed_mod allowed.
	var/const/max_speed_mod_total = 5
	/// Scales with viscosity + depth.
	var/movement_speed_mod = 0


	// /// volume req to push an item as we spread
	// var/const/push_tiny_req = 1
	// var/const/push_small_req = 10
	// var/const/push_med_req = 25
	// var/const/push_large_req = 50

	var/datum/fluid_group/group = null
	var/obj/fluid/touched_other_group = null
	var/obj/channel/touched_channel = null

	// FLOATING ANIMATION REMOVAL
	// var/float_anim = FALSE

	/**
	 * The file path (string) of the sound to play when stepping on this fluid.
	 * For example: "sound/misc/splash_1.ogg"
	 */
	var/step_sound = ""

	var/last_spread_was_blocked = FALSE
	var/last_depth_level = 0

	/// Overlay bits onto a wall to make the water look deep. This is a cache of those overlays.
	var/list/wall_overlay_images = 0

	// /// List of atoms we triggered a float anim on (cleanup later on qdel())
	// var/list/floated_atoms = 0

	var/is_setup = FALSE

	/**
	 * The number of cardinal directions that I was blocked by in last update().
	 * Cache this to skip updates on 'inner' fluid tiles of a group.
	 */
	var/blocked_dirs = 0

	/**
	 * On our last spread, which directions were blocked by perspective objects?
	 * (This saves us from doing a dumb loop to check all neighboring turfs)
	 *
	 * This is biflags of global.cardinal
	 */
	var/blocked_perspective_dirs = 0

	//temp_removal_key : this one is dumb... When a potential split happens, all adjacent fluid tiles to the split tile will be flagged with the same key.
	//get_connected(), if it encounters all these adjacent fluid tiles, will end early so we don't waste processing time searching through a group we are 100% sure did not split.
	// This key is used so we don't need to do a (more expensive) list search each get_connected loop iteration.
	var/temp_removal_key = 0

	var/my_depth_level = 0

	// Using this as a shortcut to stop constantly checking due to oceans being jank.
	var/turf/our_turf = null

	/// Exists only to change iconstate update behavior for airborne fluids.
	var/do_iconstate_updates = TRUE


/obj/fluid/New(atom/location)
	..(location)

	//unpool starts this thing without a loc. If none is defined, don't immediate delete.
	if(location && !global.waterflow_enabled)
		src.removed()
		return

	for(var/dir in global.cardinal)
		src.blocked_perspective_dirs &= ~dir

/obj/fluid/proc/set_up(newloc, do_enters = TRUE)
	if(src.is_setup)
		CRASH("Fluid object already set up.")
	if(!newloc)
		CRASH("Fluid object set_up was called without a newloc.")

	if(isturf(newloc) && waterflow_enabled)
		var/turf/turf_loc = newloc // Just for sanity.
		src.set_loc(turf_loc)
		src.loc = turf_loc
		src.our_turf = turf_loc
		src.our_turf.active_liquid = src
		src.is_setup = TRUE
	else
		src.removed()
		src.is_setup = FALSE // Should be already false, but just in case.

	return src.is_setup


/obj/fluid/proc/done_init()
	if(QDELETED(src))
		return

	/* Maybe slow, it was broke in the first place so lets just comment it out
	for(var/mob/M in get_turf(src))
		src.HasEntered(M, get_turf(M))

	for(var/obj/O in get_turf(src))
		if(O.submerged_images)
			src.HasEntered(O, get_turf(O))
	*/
	return


/obj/fluid/proc/trigger_fluid_enter()
	var/atom/atom_loc = src.our_turf || get_turf(src)
	for(var/atom/A in atom_loc)
		if(!QDELETED(src.group) && A.event_handler_flags & USE_FLUID_ENTER)
			A.EnteredFluid(src, atom_loc)

	if(!QDELETED(src.group))
		// TODO: Make this sane/robust.
		atom_loc?.EnteredFluid(src, atom_loc)

	return


/obj/fluid/proc/turf_remove_cleanup(turf/the_turf)
	the_turf.active_liquid = null
	return


/obj/fluid/disposing()
	if(!QDELETED(src.group) && src.group.members)
		src.group.members -= src

	src.group = null

	// FLOATING ANIMATION REMOVAL
	// for(var/atom/A in src.floated_atoms) // ehh i dont like doing this, but I think we need it.
	// 	if(!A)
	// 		continue
	// 	animate(A)
	// 	A.pixel_y = initial(A.pixel_y)
	// src.floated_atoms.len = 0

	// We have to check this due to oceans using a infinite fluid object...
	if(src.our_turf || isturf(get_turf(src)))
		src.turf_remove_cleanup(get_turf(src))
		src.our_turf = null

	src.overlay_refs = null
	src.overlays.len = 0

	src.group = null
	src.touched_other_group = null
	src.touched_channel = null

	return ..()


/obj/fluid/get_desc(dist, mob/user)
	if(dist > 4)
		return
	if(!src.group || !src.group.reagents)
		return

	return list(
		"<br><b class='notice'>[capitalize(src.name)] analysis:</b>",
		"<br>[SPAN_NOTICE("[src.group.reagents.get_description(user, (RC_VISIBLE | RC_SPECTRO))]")]"
	)


/obj/fluid/admin_visible_name()
	return "[src.name] \[[src.group.reagents.get_master_reagent_name()]\]"


/obj/fluid/attack_hand(mob/user)
	CRASH("[identify_object(user)] hit a fluid with their hand somehow. They shouldn't be able to do that.")


/obj/fluid/attackby(obj/item/W, mob/user)
	CRASH("[identify_object(user)] hit a fluid with [identify_object(W)] somehow. They shouldn't be able to do that.")


// Should be called right after new() on inital group creation
/obj/fluid/proc/add_reagents(datum/reagents/R, volume)
	if(QDELETED(src.group))
		return

	R.trans_to(src.group.reagents,volume)

	return


// Should be called right after new() on inital group creation
/obj/fluid/proc/add_reagent(reagent_name, volume)
	if(QDELETED(src.group))
		return
	src.group.reagents.add_reagent(reagent_name, volume)

	return


// TODO: Incorporate touch_modifier?
/obj/fluid/Crossed(atom/movable/AM)
	..()
	if(QDELETED(src.group?.reagents) || istype(AM, /obj/fluid))
		return

	src.my_depth_level = src.last_depth_level

	// FLOATING ANIMATION REMOVAL
	// if(src.float_anim)
	// 	if(!isobserver(AM) && !istype(AM, /mob/living/critter/small_animal/bee) && !istype(AM, /obj/critter/domestic_bee))
	// 		if(!AM.anchored)
	// 			animate_bumble(AM, floatspeed = 8, Y1 = 3, Y2 = 0)
	// 			src.floated_atoms += AM

	if(AM.event_handler_flags & USE_FLUID_ENTER)
		AM.EnteredFluid(src, AM.last_turf)

	return


// Called when mob is drowning
/obj/fluid/proc/force_mob_to_ingest(mob/M, mult = 1)
	if(!M)
		CRASH("force_mob_to_ingest() called with no mob.")
	if(!src.group?.reagents?.reagent_list)
		return

	var/react_volume = (src.volume > 10) ? (src.volume / 2) : (src.volume)
	react_volume = min(react_volume, 20) * mult

	if(M.reagents)
		//don't push out other reagents if we are full
		react_volume = min(react_volume, abs(M.reagents.maximum_volume - M.reagents.total_volume))

	src.group.reagents.reaction(M, INGEST, react_volume, TRUE, src.group.members.len)
	src.group.reagents.trans_to(M, react_volume)

	return


/obj/fluid/Uncrossed(atom/movable/AM)
	// FLOATING ANIMATION REMOVAL
	// var/cancel_float = FALSE
	// if(get_turf(AM) == newloc)
	// 	cancel_float = TRUE

	..()

	// FLOATING ANIMATION REMOVAL
	// if(src.float_anim && isturf(newloc))
	// 	var/turf/T = newloc
	// 	if(!T.active_liquid || (T.active_liquid && T.active_liquid.volume < depth_levels[depth_levels.len-1]))
	// 		cancel_float = TRUE
	// else
	// 	cancel_float = TRUE

	// if(src.float_anim && cancel_float)
	// 	if(ismovable(AM) && !isobserver(AM) && !istype(AM, /mob/living/critter/small_animal/bee) && !istype(AM, /obj/critter/domestic_bee))
	// 		animate(AM)
	// 		AM.pixel_y = initial(AM.pixel_y)
	// 		floated_atoms -= AM


	if((AM.event_handler_flags & USE_FLUID_ENTER) && !istype(src, /obj/fluid/airborne))
		AM.ExitedFluid(src)

	return


/obj/fluid/proc/add_tracked_blood(atom/movable/AM)
	AM.tracked_blood = list(
		"bDNA" = src.blood_DNA,
		"btype" = src.blood_type,
		"color" = src.color,
		"count" = rand(2,6),
		"sample_reagent" = src.group?.master_reagent_id,
	)

	if(ismob(AM))
		var/mob/M = AM
		M.set_clothing_icon_dirty()

	return


/obj/fluid/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume, cannot_be_cooled = FALSE)
	..()
	if(QDELETED(src.group?.reagents) || !length(src.group.members))
		return FALSE

	src.group.last_temp_time = world.time
	// Reduce exposed temperature by volume of members in the group
	src.group.reagents.temperature_reagents(exposed_temperature, exposed_volume, 100, 15, 1)

	return


/obj/fluid/ex_act()
	src.removed()
	return


/obj/fluid/proc/removed(sfx = FALSE)
	if(QDELETED(src))
		return

	if(sfx)
		playsound(get_turf(src), 'sound/impact_sounds/Liquid_Slosh_1.ogg', 25, 1)

	if(src.group)
		if(!src.group.remove(src))
			qdel(src)
	else
		qdel(src)



	for(var/atom/A as anything in (our_turf || get_turf(src)))
		if(A?.flags & FLUID_SUBMERGE)
			var/mob/living/M = A
			var/obj/O = A
			if(istype(M))
				src.Uncrossed(M)
				M.show_submerged_image(depth = 0)
			else if(istype(O))
				if(O.submerged_images)
					src.Uncrossed(O)
					if((O.submerged_images && length(O.submerged_images)) && (O.is_submerged != 0))
						O.show_submerged_image(depth = 0)

	return

/// Returns list of created fluid tiles. Null if none were created.
/obj/fluid/proc/update()
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

	var/turf/neighbor

	for(var/dir in global.cardinal)
		src.blocked_perspective_dirs &= ~dir
		neighbor = get_step(src, dir)
		if(QDELETED(neighbor)) //the fuck? how
			continue // Actually this is probably because of oceans :)

		if(!IS_VALID_FLUID_TURF(neighbor))
			src.blocked_dirs++
			if(IS_PERSPECTIVE_WALL(neighbor))
				src.blocked_perspective_dirs |= dir
			continue

		if(!QDELETED(neighbor.active_liquid))
			src.blocked_dirs++
			if(neighbor.active_liquid?.group != src.group)
				src.touched_other_group = neighbor.active_liquid.group
				neighbor.active_liquid.set_icon_state("15")
			continue

		if(neighbor.density)
			continue

		var/can_flow_to = TRUE
		var/obj/pushable_obj = null
		for(var/obj/thing in neighbor.contents)
			var/found = FALSE

			if(IS_SOLID_TO_FLUID(thing))
				found = TRUE
			else if(isnull(pushable_obj) && !thing.anchored)
				pushable_obj = thing

			if(!found)
				continue

			if(thing.density || (thing.flags & FLUID_DENSE))
				can_flow_to = FALSE
				src.blocked_dirs++
				if(IS_PERSPECTIVE_BLOCK(thing))
					src.blocked_perspective_dirs |= dir
				break

			if(istype(thing, /obj/channel))
				src.touched_channel = thing //Save this for later, we can't make use of it yet
				can_flow_to = FALSE
				break

		// If we can flow to the neighbor, and our group is still valid.
		if(can_flow_to && !QDELETED(src.group))
			spawned_any = TRUE
			src.set_icon_state("15")

			var/obj/fluid/F = new(neighbor)
			F.set_up(neighbor, FALSE)

			if(QDELETED(F) || QDELETED(src.group))
				continue //set_up may decide to remove F

			F.volume = src.group.volume_per_tile
			F.color = src.finalcolor
			F.finalcolor = src.finalcolor
			F.alpha = src.finalalpha
			F.finalalpha = src.finalalpha
			F.avg_viscosity = src.avg_viscosity
			F.last_depth_level = src.last_depth_level
			F.my_depth_level = src.last_depth_level
			F.step_sound = src.step_sound
			F.movement_speed_mod = src.movement_speed_mod

			if(src.group)
				src.group.add(F, src.group.volume_per_tile)
				F.group = src.group
			else
				var/datum/fluid_group/FG = new
				FG.add(F, src.group.volume_per_tile)
				F.group = FG

			Flist.Add(F)

			F.done_init()

			src.last_spread_was_blocked = FALSE

			if(pushable_obj && prob(50))
				if(src.last_depth_level <= 3)
					if(isitem(pushable_obj))
						var/obj/item/I = pushable_obj
						if(I.w_class <= src.last_depth_level)
							step_away(I, src)
				else
					step_away(pushable_obj, src)

			F.trigger_fluid_enter()
			src.UpdateIcon(FALSE, TRUE)

	if(spawned_any && prob(40))
		playsound(our_turf || get_turf(src), 'sound/misc/waterflow.ogg', 30, 0.7, 7)

	return Flist



/**
 * Kind of like a breadth-first search.
 * Return all fluids connected to src.
 *
 * * If adjacent_match_quit > 0
 * * * Check fluids for a temp_removal_key that matches our own.
 * * * * Subtract 1 when we do find one.
 * * * * * If adjacent_match_quit reaches 0, abort the search.
 *
 * (Used to early detect when a split fails)
 */
/obj/fluid/proc/get_connected_fluids(adjacent_match_quit = 0) as /list // We can't do /list/obj/fluid atm :(
	if(!src.group)
		return list(src)

	var/list/obj/fluid/Flist = list()
	var/list/obj/fluid/Fqueue = list(src)
	var/list/visited = list()

	var/turf/neighbor
	var/obj/fluid/neighbor_fluid

	var/obj/fluid/current_fluid = null
	var/visited_changed = FALSE

	// TODO: Completely refactor this loop.
	while(Fqueue.len)
		current_fluid = Fqueue[1]
		Fqueue.Cut(1, 2)

		for(var/dir in global.cardinal)
			neighbor = get_step(current_fluid, dir)
			if(!VALID_FLUID_CONNECTION(current_fluid, neighbor))
				continue

			if(isnull(neighbor.active_liquid.group))
				neighbor.active_liquid.removed()
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

			if(visited_changed)
				Fqueue.Add(neighbor_fluid)
				Flist.Add(neighbor_fluid)

				if(adjacent_match_quit)
					if(src.temp_removal_key && src != neighbor_fluid && src.temp_removal_key == neighbor_fluid.temp_removal_key)
						adjacent_match_quit--
						if(adjacent_match_quit <= 0)
							return list() //bud nippin

	return Flist


//sorry for copy paste, this ones a bit diff. return the turfs of members nearby, stop at a number
/obj/fluid/proc/get_connected_fluid_members(stop_at = 0)
	if(!src.group)
		return list(src)

	var/list/obj/fluid/Flist = list()
	var/list/obj/fluid/Fqueue = list(src)
	var/list/visited = list()

	var/turf/neighbor
	var/obj/fluid/neighbor_fluid

	var/obj/fluid/current_fluid = 0
	var/visited_changed = 0
	while(Fqueue.len)
		current_fluid = Fqueue[1]
		Fqueue.Cut(1, 2)

		for(var/dir in global.cardinal)
			neighbor = get_step(current_fluid, dir)
			if(!VALID_FLUID_CONNECTION(current_fluid, neighbor))
				continue

			if(neighbor.active_liquid.group != src.group)
				continue

			neighbor_fluid = neighbor.active_liquid

			//Old method : search through 'visited' for 'neighbor_fluid'. Probably slow when you have big groups!!
			//if(neighbor_fluid in visited) continue
			//visited += neighbor_fluid

			//New method : Add the liquid at a specific index. To check whether the node has already been visited, just compare the len of the visited group from before + after the index has been set.
			//Probably slower for small groups and much faster for large groups.
			visited_changed = length(visited)
			visited["[neighbor_fluid.x]_[neighbor_fluid.y]_[neighbor_fluid.z]"] = neighbor_fluid
			visited_changed = (visited.len != visited_changed)

			if (visited_changed)
				Fqueue.Add(neighbor_fluid)
				Flist.Add(neighbor)

				if (stop_at > 0 && length(.) >= stop_at)
					return Flist
	return Flist


/obj/fluid/proc/try_connect_to_adjacent()
	var/turf/neighbor
	var/obj/fluid/neighbor_fluid

	for(var/dir in global.cardinal)
		neighbor = get_step(src, dir)

		if(QDELETED(neighbor?.active_liquid))
			continue

		neighbor_fluid = neighbor.active_liquid

		if(neighbor_fluid?.group && src.group != neighbor_fluid?.group)
			neighbor_fluid.group.join(src.group)

	return


// Hey this isn't being called at all right now.
// Moved its blood spread shit up into spread() so we don't call this function that basically does nothing.
/*/obj/fluid/proc/flow_towards(list/obj/Flist, push_stuff = TRUE)
	if (!length(Flist)) return
	if (!src.group || !src.group.reagents) return

	var/push_class = 0
	if (push_stuff)
		if (src.volume >= push_tiny_req)
			push_class = 1
		if (src.volume >= push_small_req)
			push_class = 2
		if (src.volume >= push_med_req)
			push_class = 3
		if (src.volume >= push_large_req)
			push_class = 4

	for (var/obj/fluid/F in Flist)
		if (!F) continue

		//copy blood stuff
		if (src.blood_DNA && !F.blood_DNA)
			F.blood_DNA = src.blood_DNA
		if (src.blood_type && !F.blood_type)
			F.blood_type = src.blood_type

		continue

		if (push_class)
			for (var/obj/item/I in get_turf(src))
				if (prob(15) && !I.anchored && I.w_class <= push_class)
					step_towards(I, get_turf(F))
					break
			if (push_class >= 4 && prob(30))
				for (var/mob/living/M in get_turf(src))
					step_towards(M, get_turf(F))
					break
*/

/obj/fluid/update_icon(neighbor_was_removed = FALSE, depth_changed = FALSE)
	if(QDELETED(src.group?.reagents))
		return

/obj/fluid/update_icon(neighbor_was_removed = FALSE, depth_changed = FALSE)
	if(QDELETED(src.group?.reagents))
		return

	var/color_changed = FALSE
	var/datum/color/average = src.group.average_color ? src.group.average_color : src.group.reagents.get_average_color()

	src.finalalpha = max(25, (average.a / 255) * src.group.max_alpha)
	src.finalcolor = rgb(average.r, average.g, average.b)

	if(src.color != src.finalcolor)
		color_changed = TRUE
	animate(src, color = src.finalcolor, alpha = src.finalalpha, time = 5)

	if(neighbor_was_removed)
		src.last_spread_was_blocked = FALSE
		src.clear_overlay()

	var/last_icon = src.icon_state

	if(last_spread_was_blocked || (src.group?.volume_per_tile > src.group?.required_to_spread))
		src.set_icon_state("15")
	else
		var/dirs = 0
		for(var/dir in global.cardinal)
			var/turf/simulated/T = get_step(src, dir)
			if(T?.active_liquid?.group == src.group)
				dirs |= dir

		src.set_icon_state(num2text(dirs))

		if(src.overlay_refs && length(src.overlay_refs))
			src.ClearAllOverlays()

	if((color_changed || last_icon != src.icon_state) && src.last_spread_was_blocked || depth_changed || src.blocked_perspective_dirs)
		src.update_perspective_overlays()

	return


/obj/fluid/proc/update_perspective_overlays() // fancy perspective overlaying
	if(src.icon_state != "15")
		return

	var/blocked = FALSE
	for(var/dir in global.cardinal)
		if(dir == SOUTH) //No south perspective
			continue

		if(blocked_perspective_dirs & dir)
			blocked = TRUE
			if (dir == NORTH)
				display_overlay("[dir]", 0, 32)
			else
				display_overlay("[dir]", (dir == EAST) ? 32 : -32, 0)
		else
			clear_overlay("[dir]")

	if(!blocked) //Nothing adjacent!
		clear_overlay()

	if(src.overlay_refs && length(src.overlay_refs))
		if(src.overlay_refs["1"] && src.overlay_refs["8"]) //north, east
			display_overlay("9", -32, 32) //northeast
		else
			clear_overlay("9") //northeast
		if (src.overlay_refs["1"] && src.overlay_refs["4"]) //north, west
			display_overlay("5", 32, 32) //northwest
		else
			clear_overlay("5") //northwest

	return


//perspective overlays
/obj/fluid/proc/display_overlay(overlay_key, pox, poy)
	var/image/new_overlay
	if(!src.wall_overlay_images)
		src.wall_overlay_images = list()

	if (src.wall_overlay_images[overlay_key])
		new_overlay = src.wall_overlay_images[overlay_key]
	else
		new_overlay = image('icons/obj/fluid.dmi', "blank")

	var/over_obj = !(istype(get_turf(src), /turf/simulated/wall) || istype(get_turf(src), /turf/unsimulated/wall/)) //HEY HEY MBC THIS SMELLS THINK ABOUT IT LATER
	new_overlay.layer = over_obj ? 4 : src.layer
	new_overlay.icon_state = "wall_[overlay_key]_[last_depth_level]"
	new_overlay.pixel_x = pox
	new_overlay.pixel_y = poy
	src.wall_overlay_images[overlay_key] = new_overlay

	src.AddOverlays(new_overlay, overlay_key)

	return


/obj/fluid/proc/clear_overlay(key)
	if (!key)
		src.ClearAllOverlays()
	else if(key && src.wall_overlay_images && src.wall_overlay_images[key])
		src.ClearSpecificOverlays(key)

	return


/obj/fluid/proc/debug_search()
	var/list/connected_fluids = src.get_connected_fluids()
	var/obj/fluid/F
	var/debug_colors = pick("#0099ff", "#dddddd", "#ff7700")

	for(var/i = 1, i <= length(connected_fluids), i++)
		F = connected_fluids[i]
		F.finalcolor = debug_colors
		animate(F, color = F.finalcolor, alpha = src.finalalpha, time = 5)
		sleep(0.1 SECONDS)


/obj/fluid/proc/admin_clear_fluid()
	set name = "Clear Fluid"
	if(src.group)
		src.group.evaporate()
	else
		qdel(src)

	return
