/**
 *! FLUID GROUPS
 */

/datum/reagents/fluid_group
	var/datum/fluid_group/my_group = null
	var/last_reaction_loc
	var/skip_next_update = FALSE

/datum/reagents/fluid_group/covered_turf()
	var/list/covered_turfs = list()
	if (my_group)
		for (var/obj/fluid/F as anything in my_group.members)
			covered_turfs += F.loc

	return covered_turfs

/datum/reagents/fluid_group/clear_reagents()
	..()
	if (my_group)
		my_group.evaporate()

/// Handles reagent reduction -> shrinking puddle
/datum/reagents/fluid_group/update_total()
	var/prev_volume = total_volume
	..()
	if (skip_next_update) //sometimes we need to change the total without automatically draining the removed amt.
		skip_next_update = FALSE
		return
	if (my_group)
		my_group.contained_amt = total_volume

		if (total_volume <= 0 && prev_volume > 0)
			my_group.evaporate()
			return

		if (my_group.amt_per_tile >= my_group.required_to_spread)
			return
		if ((total_volume >= prev_volume))
			return

		var/member_dif = (round(total_volume / my_group.required_to_spread) - round(prev_volume / my_group.required_to_spread))
		var/fluids_to_remove = null
		if (member_dif < 0)
			fluids_to_remove = abs(member_dif)

		if (fluids_to_remove)
			var/obj/fluid/remove_source = my_group.last_reacted
			if (!remove_source)
				remove_source = my_group.spread_member
				if (!remove_source && length(my_group.members))
					remove_source = pick(my_group.members)
				if (!remove_source)
					my_group.evaporate()
					return
			skip_next_update = TRUE
			my_group.drain(remove_source, fluids_to_remove, remove_reagent = 0)

/datum/reagents/fluid_group/get_reagents_fullness()
	switch (my_group.last_depth_level)
		if(1)
			return "very shallow"
		if (2)
			return "at knee height"
		if(3)
			return "at chest height"
		if(4)
			return "very deep"
		else
			return "empty"

/datum/reagents/fluid_group/temperature_reagents(exposed_temperature, exposed_volume = 100, exposed_heat_capacity = 100, change_cap = 15, change_min = 0.0000001, loud = 0)
	..()
	update_total()

/datum/reagents/fluid_group/play_mix_sound(mix_sound) // Play sound at random locs.
	for (var/i = 0, i < length(my_group.members) / 20, i++)
		playsound(pick(my_group.members), mix_sound, 80, TRUE)
		if (i > 8)
			break

//? We use datum/controller/process/fluid_group to do evaporation.
/datum/fluid_group
	var/const/group_type = /datum/fluid_group
	// var/const/object_type = /obj/fluid

	var/base_evaporation_time = 1500

	/// Ranges from 0 to this value depending on average viscosity.
	var/bonus_evaporation_time = 9000
	var/const/max_viscosity = 20
	var/const/max_alpha = 230

	var/list/obj/fluid/members = list()

	/// Member that we want to spread from. Should be changed on add amt, displace, etc.
	var/obj/fluid/spread_member

	/// Already updating? block another loop from being started.
	var/updating = FALSE

	var/datum/reagents/fluid_group/reagents

	/// Total reagent amt including all members.
	var/contained_amt = 0

	/// Don't pull from this value for group calculations without updating it first.
	var/amt_per_tile = 0

	var/required_to_spread = 30

	var/last_add_time = 0
	var/last_temp_change = 0
	var/last_spread_member = 0
	var/last_contained_amt = -1
	var/last_members_amt = 0
	var/last_depth_level = 0
	var/avg_viscosity = 1
	var/last_update_time = 0
	var/obj/fluid/last_reacted = 0

	var/datum/color/average_color = 0
	var/master_reagent_name = 0
	var/master_reagent_id = 0

	/// Flag is set to 0 temporarily when doing a split operation.
	var/can_update = TRUE

	var/draining = FALSE

	/// How many tiles to drain on next update?
	var/queued_drains = 0

	/// Tile from which we should try to drain from.
	var/turf/last_drain = 0

	var/drains_floor = TRUE

/datum/fluid_group/disposing()
	can_update = FALSE

	for (var/fluid as anything in members)
		var/obj/fluid/M = fluid
		M.group = null

	// if (src in processing_fluid_groups)
	// 	processing_fluid_groups.Remove(src)
	// if (src in processing_fluid_spreads)
	// 	processing_fluid_spreads.Remove(src)

	processing_fluid_groups -= src
	processing_fluid_spreads -= src
	processing_fluid_drains -= src

	members.Cut()

	reagents.my_group = null
	reagents = null

	spread_member = null
	updating = FALSE
	contained_amt = 0
	amt_per_tile = 0
	required_to_spread = initial(required_to_spread)
	last_add_time = world.time //fuck
	last_temp_change = 0
	last_contained_amt = 0
	avg_viscosity = 1
	last_update_time = 0
	last_members_amt = 0
	last_depth_level = 0
	last_reacted = 0
	draining = FALSE
	queued_drains = 0
	last_drain = 0
	master_reagent_id = 0
	drains_floor = TRUE
	..()

/datum/fluid_group/New()
	. = ..()
	last_add_time = world.time

	reagents = new(90000000) //high number lol.
	reagents.my_group = src

	processing_fluid_groups |= src

/datum/fluid_group/proc/update_amt_per_tile()
	contained_amt = reagents.total_volume
	amt_per_tile = length(members) ? contained_amt / length(members) : 0

/datum/fluid_group/proc/evaporate()
	//boutput(world,"IM HITTING THE VAPE!!!!!!!!!!")
	if (last_add_time == 0) //this should nOT HAPPEN
		last_add_time = world.time
		return

	for (var/obj/fluid/target_fluid as anything in members)
		if (!target_fluid)
			continue
		if (target_fluid.disposed)
			continue
		remove(target_fluid, FALSE, 0, TRUE)

	if (!disposed)
		qdel(src)

/**
 * Fluid has been added to a tile.
 *
 * Paramaters:
 * - @param target_fluid        - The fluid that was added to the group.
 * - @param gained_fluid        - If set to TRUE, we are spreading from target_fluid.
 * - @param do_update           - If set to TRUE, we will update the group.
 * - @param guarantee_is_member - If set to TRUE, we will add target_fluid to the group if it isn't already.
 *
 * @return Nothing
 */
/datum/fluid_group/proc/add(obj/fluid/target_fluid, gained_fluid = FALSE, do_update = TRUE, guarantee_is_member = FALSE)
	if(!target_fluid || disposed || !members)
		return

	if (gained_fluid)
		spread_member = target_fluid

	// if (!length(members)) // Very first member! do special stuff // We should definitely have defined before anything else can happen
	// 	contained_amt = reagents.total_volume
	// 	amt_per_tile = contained_amt

	if(!guarantee_is_member)
		if(!length(members) || !(target_fluid in members))
			members += target_fluid
			target_fluid.group = src

	if (length(members) == 1)
		target_fluid.UpdateIcon() // Update icon of the very first fluid in this group.

	last_add_time = world.time

	if (!do_update)
		return

	update_loop()

	/**
	 * Recalculate depth level based on fluid amount
	 * to account for change to fluid until fluid_core
	 * can perform spread.
	 */
	update_amt_per_tile()
	var/my_depth_level = 0
	for(var/x in depth_levels)
		if (amt_per_tile > x)
			my_depth_level++
		else
			break

	if (target_fluid.last_depth_level != my_depth_level)
		target_fluid.last_depth_level = my_depth_level

/**
 * Fluid has been removed from its tile.
 *
 * Paramaters:
 * * @param ref  target_fluid - The fluid that was added to the group.
 * * @param bool lost_fluid   - If set to TRUE, we are removing target_fluid.
 * * @param int  lightweight
 * * - Used in evaporation procedure cause we dont need icon updates / try split / update loop checks at that point
 * * - If 'lightweight' parameter is 2, invoke an update loop but still ignore icon updates.
 * * @param bool allow_zero   - If set to TRUE, we won't qdel the group, unless it's empty of course.
 *
 * Returns:
 * * @return Nothing
 */
/datum/fluid_group/proc/remove(obj/fluid/target_fluid, lost_fluid = TRUE, lightweight = 0, allow_zero = FALSE)
	if (!target_fluid || target_fluid.disposed || disposed)
		return FALSE
	if (!members || !length(members) || !(target_fluid in members))
		return FALSE

	if (!lightweight)
		var/turf/t
		for(var/dir in cardinal)
			t = get_step(target_fluid, dir)
			if (t?.active_liquid)
				t.active_liquid.blocked_dirs = 0
				t.active_liquid.UpdateIcon(TRUE)
	else
		var/turf/t
		for(var/dir in cardinal)
			t = get_step(target_fluid, dir)
			if (t?.active_liquid)
				t.active_liquid.blocked_dirs = 0

	if(disposed || target_fluid.disposed)
		return FALSE // UpdateIcon lagchecks, rip.

	amt_per_tile = length(members) ? contained_amt / length(members) : 0
	members -= target_fluid // Remove after amt per tile ok? otherwise bad thing could happen.
	if (lost_fluid)
		reagents.skip_next_update = TRUE
		reagents.remove_any(amt_per_tile)
		contained_amt = reagents.total_volume

	target_fluid.group = null
	var/turf/removed_loc = target_fluid.loc
	if(removed_loc)
		target_fluid.turf_remove_cleanup(target_fluid.loc)

	qdel(target_fluid)

	if(!lightweight || lightweight == 2)
		if(!try_split(removed_loc))
			update_loop()

	if((!members || length(members) == 0) && !allow_zero)
		qdel(src)

	return TRUE

/**
 * Identical to remove, except this proc returns the reagents removed.
 *
 * Paramaters:
 * * @param ref  target_fluid - The fluid that was added to the group.
 * * @param int  vol_max      - Sets upper limit for fluid volume to be removed.
 * * @param bool lost_fluid   - If set to TRUE, we are removing target_fluid.
 * * @param int  lightweight
 * * - Used in evaporation procedure cause we dont need icon updates / try split / update loop checks at that point
 * * - If 'lightweight' parameter is 2, invoke an update loop but still ignore icon updates.
 * * @param bool allow_zero   - If set to TRUE, we won't qdel the group, unless it's empty of course.
 *
 * Returns:
 * * @return removed_reagents - The reagents removed from the group.
 */
/datum/fluid_group/proc/suck(obj/fluid/target_fluid, vol_max, lost_fluid = TRUE, lightweight = 0, allow_zero = TRUE)
	if (!target_fluid || target_fluid.disposed)
		return FALSE
	if (!members || !length(members) || !(target_fluid in members))
		return FALSE

	var/datum/reagents/removed_reagents = null

	if (!lightweight)
		var/turf/target_turf
		for(var/dir in cardinal)
			target_turf = get_step(target_fluid, dir)
			if (target_turf?.active_liquid)
				target_turf.active_liquid.blocked_dirs = 0
				target_turf.active_liquid.UpdateIcon(TRUE)
	else
		var/turf/target_turf
		for(var/dir in cardinal)
			target_turf = get_step(target_fluid, dir)
			if (target_turf?.active_liquid)
				target_turf.active_liquid.blocked_dirs = 0

	amt_per_tile = length(members) ? contained_amt / length(members) : 0
	var/amt_to_remove = min(amt_per_tile, vol_max)

	if(amt_to_remove == amt_per_tile)
		members -= target_fluid // Remove after amt per tile ok? otherwise bad thing could happen.
		if (lost_fluid)
			reagents.skip_next_update = TRUE
			removed_reagents = reagents.remove_any_to(amt_to_remove)
			contained_amt = reagents.total_volume

		target_fluid.group = null
		var/turf/removed_loc = target_fluid.loc
		if (removed_loc)
			target_fluid.turf_remove_cleanup(target_fluid.loc)
	else if (lost_fluid)
		reagents.skip_next_update = TRUE
		removed_reagents = reagents.remove_any_to(amt_to_remove)
		contained_amt = reagents.total_volume
	qdel(target_fluid)

	/*
	if(!lightweight || lightweight == 2)
		if(!try_split(removed_loc))
			update_loop()
	*/

	if((!members || length(members) == 0) && !allow_zero)
		qdel(src)

	return removed_reagents

/// Fluid has been displaced from its tile - delete this object and try to move my contents to adjacent tiles.
/datum/fluid_group/proc/displace(obj/fluid/target_fluid)
	if(!members || !target_fluid)
		return
	if (length(members) == 1)
		var/turf/target_turf
		var/blocked
		for(var/dir in cardinal)
			target_turf = get_step(target_fluid, dir)
			if(!(istype(target_turf, /turf/simulated/floor) || istype (target_turf, /turf/unsimulated/floor)))
				blocked++
				continue
			if (target_turf.Enter(src))
				if (target_turf.active_liquid && target_turf.active_liquid.group)
					target_turf.active_liquid.group.join(src)
				else
					target_fluid.turf_remove_cleanup(target_fluid.loc)
					target_fluid.set_loc(target_turf)
					target_turf.active_liquid = target_fluid
				break
			else
				blocked++
		if(blocked == length(cardinal)) // failed
			remove(target_fluid, 0, 2)
	else
		var/turf/target_turf
		for(var/dir in cardinal)
			target_turf = get_step(target_fluid, dir)
			if (target_turf.active_liquid && target_turf.active_liquid.group == src)
				spread_member = target_turf.active_liquid
				break
		remove(target_fluid, 0, 2)

/**
 * Use this to fake height levels.
 * Result can either block a spread or 'jump' the channel by carrying over some fluid.
 */
/datum/fluid_group/proc/displace_channel(obj/fluid/target_fluid, spread_dir, obj/channel/target_channel)
	if(!(target_channel && target_fluid))
		return FALSE
	LAGCHECK(LAG_HIGH)
	var/turf/jump_turf = 0
	var/amt_per_tile_added = length(members) ? (contained_amt + 1) / length(members) : 0

	if (amt_per_tile_added <= target_channel.required_to_pass && spread_dir != target_channel.dir)
		return FALSE
	else
		jump_turf = get_step(target_channel.loc, spread_dir)
		if (spread_dir == target_channel.dir)
			if (jump_turf.active_liquid && jump_turf.active_liquid.group)
				if (jump_turf.active_liquid.group.amt_per_tile > target_channel.required_to_pass) //don't flow back in if its 'full'
					return FALSE


	if (!istype(jump_turf))
		return FALSE

	LAGCHECK(LAG_MED)
	var/loss = amt_per_tile_added - target_channel.required_to_pass
	if (jump_turf.active_liquid)
		if(!jump_turf.active_liquid.group)
			var/datum/reagents/new_reagent = new(amt_per_tile_added)
			reagents.copy_to(new_reagent)
			jump_turf.fluid_react(new_reagent, amt_per_tile_added)
		else
			var/datum/reagents/new_reagent = new(amt_per_tile_added)
			reagents.copy_to(new_reagent)
			jump_turf.fluid_react(new_reagent, amt_per_tile_added)
	else
		var/datum/reagents/new_reagent = new(amt_per_tile_added)
		reagents.copy_to(new_reagent)
		jump_turf.fluid_react(new_reagent, amt_per_tile_added)

	reagents.skip_next_update = TRUE
	reagents.remove_any(loss)

	return TRUE

/datum/fluid_group/proc/update_viscosity()
	var/avg = 0
	var/our_reagents

	for(var/reagent_id in reagents.reagent_list)
		if (QDELETED(reagents))
			return
		var/datum/reagent/current_reagent = reagents.reagent_list[reagent_id]

		if (isnull(current_reagent))
			continue

		avg += current_reagent.viscosity
		our_reagents++
		LAGCHECK(LAG_HIGH)

	if (our_reagents && avg)
		avg = avg / our_reagents
		avg_viscosity = 1 + (avg * max_viscosity)
	else
		avg_viscosity = 1

	avg_viscosity = min(avg_viscosity, max_viscosity)

/datum/fluid_group/proc/add_drain_process()
	if (qdeled)
		return

	draining = TRUE
	processing_fluid_drains |= src

/datum/fluid_group/proc/update_loop()
	if (qdeled)
		return

	updating = TRUE
	processing_fluid_spreads |= src

/datum/fluid_group/proc/update_required_to_spread()
	return

/// This would be called every time the fluid.dm process procs.
/datum/fluid_group/proc/update_once(force = 0)
	if (qdeled || !can_update)
		return TRUE
	if (!members || !length(members))
		evaporate()
		return TRUE

	/// Try to create X amount of new tiles based on how much fluid and tiles we currently hold.
	var/fluids_to_create = 0

	update_viscosity()
	update_required_to_spread()
	if (SPREAD_CHECK(src) || force)
		LAGCHECK(LAG_HIGH)
		if (qdeled)
			return TRUE
		updating = TRUE

		if (spread_member != last_spread_member)
			if(!spread_member)
				spread_member = pick(members)
				if(!spread_member)
					updating = FALSE
					return TRUE

			last_spread_member = spread_member

		fluids_to_create = (contained_amt/required_to_spread) - length(members)

		if (force)
			fluids_to_create = force

		var/created = spread(fluids_to_create)
		if (created && !qdeled)
			return

	LAGCHECK(LAG_HIGH)

	if (last_contained_amt == contained_amt && length(members) == last_members_amt && !force)
		updating = FALSE
		return TRUE

	amt_per_tile = length(members) ? contained_amt / length(members) : 0
	var/my_depth_level = 0
	for(var/x in depth_levels)
		if (amt_per_tile > x)
			my_depth_level++
		else
			break

	LAGCHECK(LAG_MED)
	if (qdeled)
		return TRUE

	var/datum/color/last_color = average_color
	average_color = reagents?.get_average_color()
	var/color_dif = 0
	if (!last_color)
		color_dif = 999
	else
		color_dif = abs(average_color.r - last_color.r) + abs(average_color.g - last_color.g) + abs(average_color.b - last_color.b)
	var/color_changed = (color_dif > 10)

	if (my_depth_level == last_depth_level && !color_changed && length(members) == last_members_amt) //saves cycles for stuff like an ocean flooding into a pretty-much-aready-filled room
		updating = FALSE
		return TRUE

	LAGCHECK(LAG_MED)
	if (qdeled)
		return TRUE

	var/targetalpha = max(25, (average_color.a / 255) * max_alpha)
	var/targetcolor = rgb(average_color.r, average_color.g, average_color.b)

	master_reagent_name = reagents?.get_master_reagent_name()
	master_reagent_id = reagents?.get_master_reagent_id()

	var/master_opacity = !drains_floor && reagents?.get_master_reagent_gas_opaque()

	/// Force icon update later in the proc if fluid member depth changed.
	var/depth_changed = FALSE
	var/last_icon = 0

	for (var/obj/fluid/target_fluid as anything in members)
		LAGCHECK(LAG_HIGH)
		if (!target_fluid || target_fluid.disposed || qdeled)
			continue

		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//Set_amt gets called a lot. Let's reduce proc call overhead : by being stupid and pasting the whole thing in this fuckin loop ugh
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		target_fluid.amt = amt_per_tile

		if (target_fluid.touched_channel)
			displace_channel(target_fluid, get_dir(target_fluid, target_fluid.touched_channel), target_fluid.touched_channel)
			target_fluid.touched_channel = 0
			if (!target_fluid || target_fluid.disposed || qdeled)
				continue

		//We update objects manually here because they don't move. A mob that moves around will call HasEntered on its own, so let that case happen naturally

		depth_changed = FALSE
		if (target_fluid.last_depth_level != my_depth_level)
			target_fluid.last_depth_level = my_depth_level
			for(var/obj/O in target_fluid.loc)
				LAGCHECK(LAG_MED)
				if (O?.submerged_images)
					target_fluid.Crossed(O)

			depth_changed = TRUE

		if (my_depth_level)
			var/splash_level = clamp(my_depth_level, 1, 3)
			target_fluid.step_sound = "sound/misc/splash_[splash_level].ogg"

		// Expanded the function here to make it more readable. @Zandario
		var/fluid_viscosity_mod = VISCOSITY_SLOW_COMPONENT(target_fluid.avg_viscosity, target_fluid.max_viscosity, target_fluid.max_speed_mod)
		var/fluid_depth_mod = DEPTH_SLOW_COMPONENT(target_fluid.amt, target_fluid.max_reagent_volume, target_fluid.max_speed_mod)

		target_fluid.movement_speed_mod = (target_fluid.last_depth_level <= 1) ? 0 : (fluid_viscosity_mod + fluid_depth_mod)

		// End.

	fluid_ma.color = targetcolor
	fluid_ma.alpha = targetalpha

	for (var/obj/fluid/target_fluid as anything in members)
		if(!target_fluid || target_fluid.disposed || qdeled)
			continue

		// Same shit here with UpdateIcon

		fluid_ma.name = master_reagent_name //TODO: Maybe obscure later?

		target_fluid.finalalpha = targetalpha
		target_fluid.finalcolor = targetcolor


		if (target_fluid.do_iconstate_updates)
			last_icon = target_fluid.icon_state

			if (target_fluid.last_spread_was_blocked || (amt_per_tile > required_to_spread))
				fluid_ma.icon_state = "15"
			else
				var/dirs = 0
				for (var/dir in cardinal)
					var/turf/simulated/target_turf = get_step(target_fluid, dir)
					if (target_turf && target_turf.active_liquid && target_turf.active_liquid.group == target_fluid.group)
						dirs |= dir
				fluid_ma.icon_state = num2text(dirs)

				if (target_fluid.overlay_refs && length(target_fluid.overlay_refs))
					if (target_fluid)
						target_fluid.ClearAllOverlays()

			if (((color_changed || last_icon != target_fluid.icon_state) && target_fluid.last_spread_was_blocked) || depth_changed)
				target_fluid.update_perspective_overlays()
		else
			fluid_ma.icon_state = "airborne" //HACKY! BAD! BAD! WARNING!

		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//end
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		//air specific (messy)
		fluid_ma.opacity = master_opacity
		fluid_ma.overlays = target_fluid.overlays // gross, needed because of perspective overlays
		target_fluid.appearance = fluid_ma

	if(disposed)
		return TRUE

	last_contained_amt = contained_amt
	last_members_amt = length(members)
	last_depth_level = my_depth_level

	updating = FALSE
	return TRUE

/**
 * Spread in respect to members.
 *
 * @param - fluids_to_create - Number of fluids to create.
 *
 * @returns List of created fluids.
 */
/datum/fluid_group/proc/spread(fluids_to_create)
	var/list/created_fluids = list()
	var/obj/fluid/target_fluid
	var/membercount = length(members)

	for (var/i = 1, i <= membercount, i++)
		LAGCHECK(LAG_HIGH)
		if (qdeled)
			return
		if (i > membercount)
			continue
		target_fluid = members[i]
		if (!target_fluid || target_fluid.group != src)
			continue // This can happen if a fluid is deleted/caught with its pants down during an update loop.

		if (target_fluid.blocked_dirs < 4) // Skip that update if we were blocked (not an edge tile)
			amt_per_tile = contained_amt / (membercount + created_fluids.len)

			for (var/obj/fluid/C as anything in target_fluid.update())
				LAGCHECK(LAG_HIGH)
				if (!C || C.disposed || disposed)
					continue
				var/turf/simulated/floor/target_floor = C.loc
				if (istype(target_floor) && drains_floor)
					target_floor.react_all_cleanables() // bug here regarding fluids doing their whole spread immediately if they're in a patch of cleanables. can't figure it out and its not TERRIBLE, fix later!!!
				C.amt = amt_per_tile

				//copy blood stuff
				if (target_fluid.blood_DNA && !C.blood_DNA)
					C.blood_DNA = target_fluid.blood_DNA
				if (target_fluid.blood_type && !C.blood_type)
					C.blood_type = target_fluid.blood_type

				members |= C
				created_fluids += target_fluid

			if ((membercount + created_fluids.len) <= 0) //this can happen somehow
				continue

			amt_per_tile = contained_amt / (membercount + created_fluids.len)

		if (target_fluid.touched_other_group && src != target_fluid.touched_other_group)
			if (join(target_fluid.touched_other_group))
				target_fluid.touched_other_group = 0
				break
			target_fluid.touched_other_group = 0

		if (created_fluids.len >= fluids_to_create)
			break

	return created_fluids

/// Basically a reverse spread with drain_source as the center.
/datum/fluid_group/proc/drain(obj/fluid/drain_source, fluids_to_remove, atom/transfer_to, remove_reagent = TRUE)
	if (!drain_source || drain_source.group != src)
		return

	// Don't delete tiles if we can just drain existing deep fluid.
	amt_per_tile = length(members) ? contained_amt / length(members) : 0

	if (amt_per_tile > required_to_spread)
		if (transfer_to && transfer_to.reagents && reagents)
			reagents.trans_to_direct(transfer_to.reagents,min(fluids_to_remove * amt_per_tile, reagents.total_volume))
			contained_amt = reagents.total_volume
		else if(remove_reagent)
			reagents.remove_any(fluids_to_remove * amt_per_tile)

		update_loop()
		return avg_viscosity

	if (length(members) && members[1] != drain_source)
		if (length(members) <= 30)
			var/list/L = drain_source.get_connected_fluids()
			if (L.len == length(members))
				members = L.Copy()// this is a bit of an ouch, but drains need to be able to finish off smallish puddles properly

	var/list/fluids_removed = list()
	var/fluids_removed_avg_viscosity = 0

	for (var/i = length(members), i > 0, i--)
		if (qdeled)
			return
		if (i > length(members))
			continue
		if (!members[i])
			continue
		var/obj/fluid/target_fluid = members[i] // todo fix error
		if (!target_fluid || target_fluid.group != src)
			continue

		fluids_removed += target_fluid
		fluids_removed_avg_viscosity += target_fluid.avg_viscosity

		if (fluids_removed.len >= fluids_to_remove)
			break

	var/removed_len = length(fluids_removed)

	if (transfer_to && transfer_to.reagents && reagents)
		reagents.skip_next_update = 1
		reagents.trans_to_direct(transfer_to.reagents,amt_per_tile * removed_len)
		contained_amt = reagents.total_volume
	else if (reagents && remove_reagent)
		reagents.skip_next_update = 1
		reagents.remove_any(amt_per_tile * removed_len)
		contained_amt = reagents.total_volume

	for (var/obj/fluid/F as anything in fluids_removed)
		remove(F,0,updating)

	//fluids_removed_avg_viscosity = fluids_removed ? (fluids_removed_avg_viscosity / fluids_removed) : 1
	return avg_viscosity

/// Join a fluid group into this one.
/datum/fluid_group/proc/join(datum/fluid_group/join_with)
	if (src == join_with || qdeled || !join_with || join_with.qdeled)
		return FALSE

	join_with.qdeled = TRUE // Hacky but stop updating.

	for (var/obj/fluid/target_fluid as anything in join_with.members)
		if(!target_fluid)
			continue
		target_fluid.group = src
		members += target_fluid
		join_with.members -= target_fluid

	join_with.reagents.copy_to(reagents)

	join_with.evaporate()
	join_with = 0

	update_loop() // Just in case one wasn't running already.
	// last_add_time = world.time
	amt_per_tile = length(members) ? contained_amt / length(members) : 0

	return TRUE

/**
 * Called when a fluid is removed.
 * Check if the removal causes a split, and proceed from there.
 */
/datum/fluid_group/proc/try_split(turf/removed_loc)
	if (!removed_loc || qdeled)
		return FALSE
	var/list/connected = list()

	var/turf/target_turf
	var/obj/fluid/split_liq = 0
	var/removal_key = "[world.time]_[removed_loc.x]_[removed_loc.y]"
	var/adjacent_amt = -1
	for(var/dir in cardinal)
		target_turf = get_step(removed_loc, dir)
		if (target_turf.active_liquid && target_turf.active_liquid.group == src)
			target_turf.active_liquid.temp_removal_key = removal_key
			adjacent_amt++
			split_liq = target_turf.active_liquid

	// (adjacent_amt > 0) means that we won't even try searching if the removal point is only connected to 1 fluid (could not possibly be a split).
	if (split_liq && adjacent_amt > 0)
		// Pass in adjacent_amt: get_connected will check the removal_key of each fluid, which will trigger an early abort if we determine no split is necessary.
		connected = split_liq.get_connected_fluids(adjacent_amt)

	if (!connected || connected.len == length(members))
		return FALSE

	// Trying to stop the weird bug were a bunch of simultaneous splits removes all reagents.
	if (!removed_loc || qdeled || !reagents || !reagents.total_volume)
		return FALSE
	contained_amt = reagents.total_volume

	// Remove some of contained_amt from src and add it to new_fluid_grop.
	can_update = FALSE
	amt_per_tile = length(members) ? contained_amt / length(members) : 0
	var/datum/fluid_group/new_fluid_grop = new group_type
	new_fluid_grop.can_update = FALSE
	// Add members to new_fluid_grop, remove them from src.
	for (var/obj/fluid/target_fluid as anything in connected)
		if(!new_fluid_grop)
			return FALSE
		new_fluid_grop.members += target_fluid
		target_fluid.group = new_fluid_grop
		target_fluid.last_spread_was_blocked = FALSE
	members -= new_fluid_grop.members

	if (new_fluid_grop)
		reagents.skip_next_update = TRUE
		reagents.trans_to_direct(new_fluid_grop.reagents, amt_per_tile * connected.len)
		contained_amt = reagents.total_volume

		new_fluid_grop.can_update = TRUE
		new_fluid_grop.last_contained_amt = 0
		new_fluid_grop.last_members_amt = 0
		if (length(new_fluid_grop.members))
			new_fluid_grop.last_spread_member = new_fluid_grop.members[1]
		new_fluid_grop.update_loop()

	can_update = TRUE
	last_contained_amt = 0
	last_members_amt = 0
	update_loop()

	//last_add_time = world.time

	return TRUE
