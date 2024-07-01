///////////////////
////Fluid Group////
///////////////////

//We use datum/controller/process/fluid_group to do evaporation

/datum/fluid_group

	var/group_type = /datum/fluid_group
	// var/const/object_type = /obj/fluid

	var/base_evaporation_time = 1500
	/// Ranges from 0 to this value depending on average viscosity.
	var/bonus_evaporation_time = 9000

	var/const/max_viscosity = 20
	var/avg_viscosity = 1

	var/const/max_alpha = 230

	var/list/obj/fluid/members = list()

	/// Member that we want to spread from. Should be changed on add volume, displace, etc.
	var/obj/fluid/spread_member = null
	/// Flag is set to FALSE temporarily when doing a split operation.
	var/can_update = TRUE

	// Already updating? block another loop from being started.
	var/updating = FALSE

	var/draining = FALSE
	var/drains_floor = TRUE // Only changes for airborne fluids...
	/// How many tiles to drain on next update?
	var/queued_drains = 0

	var/datum/reagents/fluid_group/reagents = null
	/// Total reagent volume including all members.
	var/contained_volume = 0

	/// Don't pull from this value for group calculations without updating it first.
	var/volume_per_tile = 0

	var/required_to_spread = 30

	// Some for diagnostics, some for optimization.
	/// Last time we added fluid.
	var/last_add_time = 0
	/// Last time we removed fluid.
	var/last_remove_time = 0
	/// Last time we changed temperature.
	var/last_temp_time = 0
	/// Last member we spread from.
	var/obj/fluid/last_spread_member = null
	/// How much fluid we had last update.
	var/last_contained_volume = 0
	/// How many members we had last update.
	var/last_members_length = 0
	/// Our depth level last update.
	var/last_depth_level = 0
	/// When our last update was.
	var/last_update_time = 0

	/// The last /obj/fluid we reacted with.
	var/obj/fluid/last_reacted = 0
	/// Tile from which we should try to drain from.
	var/turf/last_turf_drained = null

	var/datum/color/average_color = 0
	var/master_reagent_id = 0


/datum/fluid_group/New()
	..()
	src.last_add_time = world.time

	reagents = new /datum/reagents/fluid_group(90000000) //high number lol.
	reagents.my_group = src

	processing_fluid_groups |= src


/datum/fluid_group/disposing()
	src.can_update = FALSE

	for(var/obj/fluid/fluid as anything in src.members)
		fluid.group = null

	//if (src in processing_fluid_groups)
	//	processing_fluid_groups.Remove(src)
	//if (src in processing_fluid_spreads)
	//	processing_fluid_spreads.Remove(src)

	global.processing_fluid_groups -= src
	global.processing_fluid_spreads -= src
	global.processing_fluid_drains -= src

	src.members.Cut()

	src.reagents.my_group = null
	src.reagents = null

	src.spread_member = null

	src.last_reacted = null
	src.last_turf_drained = null

	..()


/datum/fluid_group/proc/update_volume_per_tile()
	src.contained_volume = src.reagents.total_volume

	if(length(members))
		src.volume_per_tile = src.contained_volume / length(src.members)
	else
		src.volume_per_tile = 0


/datum/fluid_group/proc/evaporate()
	//boutput(world,"IM HITTING THE VAPE!!!!!!!!!!")
	if(src.last_add_time == 0) //this should nOT HAPPEN
		src.last_add_time = world.time
		return

	for(var/obj/fluid/F as anything in src.members)
		if(QDELETED(F))
			continue
		src.remove(F, 0, 1, 1)

	if(!QDELETED(src))
		qdel(src)


/datum/fluid_group/proc/add(obj/fluid/F, gained_fluid = 0, do_update = TRUE, guarantee_is_member = 0)
	if(QDELETED(F) || QDELETED(src) || !src.members)
		return

	if(gained_fluid)
		src.spread_member = F

	// if(!length(src.members)) //very first member! do special stuff	we should def. have defined before anything else can happen
	// 	src.contained_volume = src.reagents.total_volume
	// 	src.volume_per_tile = src.contained_volume

	if(!guarantee_is_member)
		if(!length(src.members) || !(F in src.members))
			src.members.Add(F)
			F.group = src

	// This makes no sense?
	if(length(src.members) == 1)
		F.UpdateIcon() //update icon of the very first fluid in this group

	src.last_add_time = world.time

	if(!do_update)
		return

	src.update_loop()

	// recalculate depth level based on fluid amount
	// to account for change to fluid until fluid_core
	// can perform spread
	update_volume_per_tile()
	var/my_depth_level = 0
	for(var/x in global.depth_levels)
		if(src.volume_per_tile > x)
			my_depth_level++
		else
			break

	if(F.last_depth_level != my_depth_level)
		F.last_depth_level = my_depth_level


/**
 * Fluid has been removed from its tile.
 *
 * Use 'lightweight' in evaporation procedure cause we dont need icon updates / try split / update loop checks at that point.
 * If 'lightweight' parameter is 2, invoke an update loop but still ignore icon updates.
 */
/datum/fluid_group/proc/remove(obj/fluid/F, lost_fluid = 1, lightweight = 0, allow_zero = FALSE)
	if(QDELETED(F))
		return FALSE

	if(!members || !length(src.members) || !(F in src.members))
		return FALSE

	var/turf/neighbor
	for(var/dir in global.cardinal)
		neighbor = get_step(F, dir)
		if(neighbor?.active_liquid)
			neighbor.active_liquid.blocked_dirs = 0

			if(lightweight)
				continue

			neighbor.active_liquid.UpdateIcon(TRUE, FALSE)

	src.volume_per_tile = length(src.members) ? (src.contained_volume / length(src.members)) : 0
	src.members.Remove(F) //remove after volume per tile ok? otherwise bad thing could happen

	if(lost_fluid)
		src.reagents.skip_next_update = TRUE
		src.reagents.remove_any(volume_per_tile)
		src.contained_volume = src.reagents.total_volume

	F.group = null

	var/turf/removed_loc = F.our_turf || F.loc
	if(removed_loc)
		F.turf_remove_cleanup(removed_loc)

	qdel(F)

	if(lightweight == 2)
		if(!src.try_split(removed_loc))
			src.update_loop()

	if((length(src.members) == 0) && !allow_zero)
		qdel(src)

	return TRUE


/**
 * Identical to remove, except this proc returns the fluids removed.
 * vol_max sets upper limit for fluid volume to be removed.
 */
/datum/fluid_group/proc/suck(obj/fluid/F, vol_max, lost_fluid = 1, lightweight = 0, allow_zero = TRUE)
	if(QDELETED(F))
		return FALSE

	if(!members || !length(src.members) || !(F in src.members))
		return FALSE

	var/datum/reagents/R = null

	var/turf/neighbor
	for(var/dir in global.cardinal)
		neighbor = get_step(F, dir)
		if(neighbor?.active_liquid)
			neighbor.active_liquid.blocked_dirs = 0

			if(lightweight)
				continue

			neighbor.active_liquid.UpdateIcon(TRUE)

	src.volume_per_tile = length(src.members) ? (src.contained_volume / length(src.members)) : 0
	var/volume_to_remove = min(src.volume_per_tile, vol_max)

	if(volume_to_remove == src.volume_per_tile)
		src.members.Remove(F) //remove after volume per tile ok? otherwise bad thing could happen
		if(lost_fluid)
			src.reagents.skip_next_update = TRUE
			R = src.reagents.remove_any_to(volume_to_remove)
			src.contained_volume = src.reagents.total_volume

		F.group = null

		var/turf/removed_loc = F.our_turf || get_turf(F) || F.loc
		if(removed_loc)
			F.turf_remove_cleanup(removed_loc)
	else
		if(lost_fluid)
			src.reagents.skip_next_update = TRUE
			R = src.reagents.remove_any_to(volume_to_remove)
			src.contained_volume = src.reagents.total_volume
	qdel(F)

	if(!lightweight || lightweight == 2)
		if(!src.try_split(F.our_turf || get_turf(F)))
			src.update_loop()

	if((length(src.members) == 0) && !allow_zero)
		qdel(src)

	return R


/// Fluid has been displaced from its tile - delete this object and try to move my contents to adjacent tiles.
/datum/fluid_group/proc/displace(obj/fluid/F)
	if(QDELETED(F) || !length(src.members))
		return

	if(length(src.members) == 1)
		var/turf/T
		var/blocked
		for(var/dir in global.cardinal)
			T = get_step(F, dir)
			if(!(istype(T, /turf/simulated/floor) || istype(T, /turf/unsimulated/floor)))
				blocked++
				continue

			if(T.Enter(src))
				if(T.active_liquid && T.active_liquid.group)
					T.active_liquid.group.join(src)
				else
					F.turf_remove_cleanup(F.loc)
					F.set_loc(T)
					T.active_liquid = F
				break
			else
				blocked++

		if(blocked == length(global.cardinal)) // failed
			src.remove(F, 0, 2)
	else
		var/turf/T
		for(var/dir in global.cardinal)
			T = get_step(F, dir)
			if (T.active_liquid && T.active_liquid.group == src)
				src.spread_member = T.active_liquid
				break

		src.remove(F,0,2)
	return


/**
 * Use this to fake height levels.
 *
 * Result can either block a spread or 'jump' the channel by carrying over some fluid.
 */
/datum/fluid_group/proc/displace_channel(spread_dir, obj/fluid/F, obj/channel/channel)
	if(!(channel && F))
		return FALSE

	var/turf/jump_turf
	var/volume_per_tile_added = length(src.members) ? ((src.contained_volume + 1) / length(src.members)) : 0

	if((volume_per_tile_added <= channel.required_to_pass) && (spread_dir != channel.dir))
		return FALSE
	else
		jump_turf = get_step(channel.loc, spread_dir)
		if((spread_dir == channel.dir) && (jump_turf?.active_liquid?.group?.volume_per_tile > channel.required_to_pass))
			return FALSE //don't flow back in if its 'full'

	if(!isturf(jump_turf))
		return FALSE

	var/loss = volume_per_tile_added - channel.required_to_pass // Is thi-

	var/datum/reagents/R = new /datum/reagents(volume_per_tile_added)
	src.reagents.copy_to(R)
	jump_turf.fluid_react(R, volume_per_tile_added)

	src.reagents.skip_next_update = TRUE
	src.reagents.remove_any(loss)

	return TRUE


/datum/fluid_group/proc/update_viscosity()
	var/avg = 0
	var/reagents = 0

	for(var/reagent_id in src.reagents.reagent_list)
		var/datum/reagent/current_reagent = src.reagents.reagent_list[reagent_id]

		if(isnull(current_reagent))
			continue

		avg += current_reagent.viscosity
		reagents++

	if(reagents && avg)
		avg /= reagents
		src.avg_viscosity = 1 + (avg * src.max_viscosity)
	else
		src.avg_viscosity = 1

	src.avg_viscosity = min(src.avg_viscosity, src.max_viscosity)

	return


/datum/fluid_group/proc/add_drain_process()
	if(QDELETED(src))
		return

	src.draining = TRUE
	global.processing_fluid_drains |= src
	return

/datum/fluid_group/proc/update_loop()
	if(QDELETED(src))
		return

	src.updating = TRUE
	global.processing_fluid_spreads |= src
	return


/datum/fluid_group/proc/update_required_to_spread()
	return


/datum/fluid_group/proc/update_once(force = FALSE) //this would be called every time the fluid.dm process procs.
	if(QDELETED(src) || !src.can_update)
		return TRUE

	if(!src.members || !length(src.members))
		src.evaporate()
		return TRUE

	/// Try to create X amount of new tiles (based on how much fluid and tiles we currently hold)
	var/fluids_to_create = 0

	src.update_viscosity()
	src.update_required_to_spread()
	if(SPREAD_CHECK(src) || force)
		src.updating = TRUE

		if(src.spread_member != src.last_spread_member)
			if(!src.spread_member)
				src.spread_member = pick(src.members)
				if(!src.spread_member)
					src.updating = FALSE
					return TRUE

			src.last_spread_member = src.spread_member

		fluids_to_create = (src.contained_volume / src.required_to_spread) - length(src.members)

		if(force)
			fluids_to_create = force

		var/created = src.spread(fluids_to_create)
		if(created && !QDELETED(src))
			return

	if((src.last_contained_volume == src.contained_volume) && (length(src.members) == src.last_members_length) && !force)
		src.updating = FALSE
		return TRUE

	src.volume_per_tile = length(src.members) ? (src.contained_volume / length(src.members)) : 0
	var/my_depth_level = 0
	for(var/x in global.depth_levels)
		if(src.volume_per_tile > x)
			my_depth_level++
		else
			break

	var/datum/color/last_color = src.average_color
	src.average_color = src.reagents?.get_average_color()
	var/color_dif = 0
	if(!last_color)
		color_dif = 999
	else
		color_dif = abs(average_color.r - last_color.r) + abs(average_color.g - last_color.g) + abs(average_color.b - last_color.b)
	var/color_changed = (color_dif > 10)

	if(my_depth_level == src.last_depth_level && !color_changed && length(src.members) == src.last_members_length) //saves cycles for stuff like an ocean flooding into a pretty-much-aready-filled room
		src.updating = FALSE
		return TRUE

	src.master_reagent_id = src.reagents?.get_master_reagent_id()

	/// Force icon update later in the proc if fluid member depth changed.
	var/depth_changed = FALSE

	for(var/obj/fluid/F as anything in src.members)
		if(QDELETED(F) || QDELETED(src))
			continue

		// Beginning of ancient inline.
		F.volume = src.volume_per_tile

		if(F.touched_channel)
			src.displace_channel(get_dir(F, F.touched_channel), F, F.touched_channel)
			F.touched_channel = null

		//We update objects manually here because they don't move. A mob that moves around will call HasEntered on its own, so let that case happen naturally

		depth_changed = FALSE
		if(F.last_depth_level != my_depth_level)
			F.last_depth_level = my_depth_level
			for(var/obj/O in F.loc)
				if(O?.submerged_images)
					F.Crossed(O)

			depth_changed = TRUE

		if(my_depth_level)
			F.step_sound = "sound/misc/splash_[clamp(my_depth_level, 1, 3)].ogg"

		if(F.last_depth_level <= 1)
			F.movement_speed_mod = 0
		else
			F.movement_speed_mod = (viscosity_SLOW_COMPONENT(F.avg_viscosity, F.max_viscosity, F.max_speed_mod) + DEPTH_SLOW_COMPONENT(F.volume, F.max_reagent_volume, F.max_speed_mod))

		//end of ancient inline.

	for(var/obj/fluid/F as anything in src.members)
		F.UpdateIcon(TRUE, depth_changed)

	if(QDELETED(src))
		return TRUE

	src.last_contained_volume = src.contained_volume
	src.last_members_length = length(src.members)
	src.last_depth_level = my_depth_level

	src.updating = FALSE
	return TRUE


/datum/fluid_group/proc/spread(fluids_to_create) //spread in respect to members

	var/fluids_created = 0

	var/obj/fluid/F
	var/membercount = length(src.members)

	// TODO: redo this whole loop.
	for(var/i = 1, i <= membercount, i++)
		if(i > membercount)
			continue

		F = src.members[i]
		if(F?.group != src)
			continue //This can happen if a fluid is deleted/caught with its pants down during an update loop.

		if (F.blocked_dirs < 4) //skip that update if we were blocked (not an edge tile)
			volume_per_tile = src.contained_volume / (membercount + fluids_created)

			for(var/obj/fluid/C as anything in F.update())
				var/turf/T = C.loc
				if(isturf(T) && src.drains_floor)
					// bug here regarding fluids doing their whole spread immediately if they're in a patch of cleanables.
					// Can't figure it out and its not TERRIBLE, fix later!!!
					// TODO: Need confirmation if this bug is still present. - 2024-06-30
					T.react_all_cleanables()
				C.volume = src.volume_per_tile

				//copy blood stuff
				if(F.blood_DNA && !C.blood_DNA)
					C.blood_DNA = F.blood_DNA
				if(F.blood_type && !C.blood_type)
					C.blood_type = F.blood_type

				src.members |= C
				fluids_created++

			if((membercount + fluids_created) <= 0) //this can happen somehow
				continue

			 src.volume_per_tile = src.contained_volume / (membercount + fluids_created)

		if(F?.touched_other_group != src)
			if(src.join(F.touched_other_group))
				F.touched_other_group = null
				break
			F.touched_other_group = null

		if(fluids_created >= fluids_to_create)
			break

	return fluids_created


/// Basically a reverse spread with drain_source as the center.
/datum/fluid_group/proc/drain(obj/fluid/drain_source, fluids_to_remove, atom/transfer_to, remove_reagent = TRUE)
	if(drain_source?.group != src)
		return 0

	//Don't delete tiles if we can just drain existing deep fluid
	src.volume_per_tile = length(src.members) ? (src.contained_volume / length(src.members)) : 0

	if(src.volume_per_tile > src.required_to_spread)
		if(transfer_to?.reagents && src.reagents)
			src.reagents.trans_to_direct(transfer_to.reagents, min(fluids_to_remove * src.volume_per_tile, src.reagents.total_volume))
			src.contained_volume = src.reagents.total_volume
		else if(remove_reagent)
			src.reagents.remove_any(fluids_to_remove * src.volume_per_tile)

		src.update_loop()
		return src.avg_viscosity

	if (length(members) && src.members[1] != drain_source)
		if(length(src.members) <= 30)
			var/list/L = drain_source.get_connected_fluids()
			if(length(L) == length(src.members))
				// This is a bit of an ouch, but drains need to be able to finish off smallish puddles properly.
				src.members = L.Copy()

	var/list/obj/fluid/fluids_removed = list()
	var/fluids_removed_avg_viscosity = 0

	if(QDELETED(src))
		return

	for(var/obj/fluid/F as anything in src.members)
		if(QDELETED(F) || F.group != src)
			continue

		fluids_removed.Add(F)
		fluids_removed_avg_viscosity += F.avg_viscosity

		if(length(fluids_removed) >= fluids_to_remove)
			break

	var/removed_len = length(fluids_removed)

	src.reagents.skip_next_update = TRUE

	if(transfer_to?.reagents && src.reagents)
		src.reagents.trans_to_direct(transfer_to.reagents,src.volume_per_tile * removed_len)
	else if(src.reagents && remove_reagent)
		src.reagents.remove_any(src.volume_per_tile * removed_len)

	src.contained_volume = src.reagents.total_volume

	for(var/obj/fluid/F as anything in fluids_removed)
		src.remove(F, 0, src.updating)

	//fluids_removed_avg_viscosity = fluids_removed ? (fluids_removed_avg_viscosity / fluids_removed) : 1
	return src.avg_viscosity


/datum/fluid_group/proc/join(datum/fluid_group/join_with) //join a fluid group into this one
	if(src == join_with || QDELETED(src) || QDELETED(join_with))
		return FALSE

	for(var/obj/fluid/F as anything in join_with.members)
		if(QDELETED(F))
			continue
		F.group = src
		src.members += F
		join_with.members -= F

	join_with.reagents.copy_to(src.reagents)

	join_with.evaporate()
	join_with = null

	src.update_loop() //just in case one wasn't running already
	//src.last_add_time = world.time
	volume_per_tile = length(members) ? contained_volume / length(members) : 0
	return TRUE


/**
 * Called when a fluid is removed.
 * Check if the removal causes a split, and proceed from there.
 */
/datum/fluid_group/proc/try_split(turf/removed_loc)
	if(!removed_loc || QDELETED(src))
		return FALSE
	var/list/obj/fluid/connected

	var/turf/neighbor

	var/removal_key = "[world.time]_[removed_loc.x]_[removed_loc.y]"
	var/adjacent_volume = -1

	for(var/dir in global.cardinal)
		neighbor = get_step( removed_loc, dir )
		if(neighbor?.active_liquid?.group == src)
			neighbor.active_liquid.temp_removal_key = removal_key
			adjacent_volume++

	// (adjacent_volume > 0) means that we won't even try searching if the removal point is only connected to 1 fluid (could not possibly be a split)
	if(neighbor.active_liquid && adjacent_volume > 0)
		// Pass in adjacent_volume: get_connected will check the removal_key of each fluid, which will trigger an early abort if we determine no split is necessary
		connected = neighbor.active_liquid.get_connected_fluids(adjacent_volume)

	if(length(connected) == length(src.members))
		return FALSE

	// Trying to stop the weird bug were a bunch of simultaneous splits removes all reagents.
	if(!removed_loc || QDELETED(src) || !src.reagents?.total_volume)
		return FALSE

	contained_volume = src.reagents.total_volume

	// Remove some of contained_volume from src and add it to FG.
	src.can_update = FALSE
	src.volume_per_tile = length(src.members) ? src.contained_volume / length(src.members) : 0
	var/datum/fluid_group/FG = new group_type
	FG.can_update = FALSE

	// Add members to FG, remove them from src.
	for(var/obj/fluid/F as anything in connected)
		if(QDELETED(FG))
			return FALSE

		FG.members.Add(F)
		F.group = FG
		F.last_spread_was_blocked = FALSE

	src.members.Remove(FG.members)

	if(FG)
		src.reagents.skip_next_update = TRUE
		src.reagents.trans_to_direct(FG.reagents, volume_per_tile * connected.len)
		src.contained_volume = src.reagents.total_volume

		FG.can_update = TRUE
		FG.last_contained_volume = 0
		FG.last_members_length = 0

		if(length(FG.members))
			FG.last_spread_member = FG.members[1]

		FG.update_loop()

	src.can_update = TRUE
	src.last_contained_volume = 0
	src.last_members_length = 0

	src.update_loop()

	// src.last_add_time = world.time

	return TRUE
