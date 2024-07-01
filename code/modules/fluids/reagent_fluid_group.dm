/datum/reagents/fluid_group
	var/datum/fluid_group/my_group = null
	// var/last_reaction_loc = 0
	var/skip_next_update = FALSE


/datum/reagents/fluid_group/covered_turf()
	var/atom/our_locs = list()
	if(my_group)
		for(var/obj/fluid/F as anything in my_group.members)
			our_locs += F.loc

	return our_locs


/datum/reagents/fluid_group/clear_reagents()
	..()
	if (my_group)
		my_group.evaporate()


/// Handles reagent reduction -> shrinking puddle
/datum/reagents/fluid_group/update_total()
	var/prev_volume = src.total_volume

	..()

	if(skip_next_update) //sometimes we need to change the total without automatically draining the removed volume.
		skip_next_update = FALSE
		return

	if(my_group)
		my_group.contained_volume = src.total_volume

		if(src.total_volume <= 0 && prev_volume > 0)
			my_group.evaporate()
			return

		if(src.my_group.volume_per_tile >= src.my_group.required_to_spread)
			return

		if((src.total_volume >= prev_volume))
			return

		var/member_dif = (round(src.total_volume / my_group.required_to_spread) - round(prev_volume / my_group.required_to_spread ))
		var/fluids_to_remove = 0
		if(member_dif < 0)
			fluids_to_remove = abs(member_dif)

		if(fluids_to_remove)
			var/obj/fluid/remove_source = my_group.last_reacted
			if (!remove_source)
				remove_source = my_group.spread_member
				if(!remove_source && length(my_group.members))
					remove_source = pick(my_group.members)

				if(!remove_source)
					my_group.evaporate()
					return

			src.skip_next_update = TRUE
			my_group.drain(remove_source, fluids_to_remove, null, FALSE)


/datum/reagents/fluid_group/get_reagents_fullness()
	switch(my_group?.last_depth_level)
		if(1) return "very shallow"
		if(2) return "knee height"
		if(3) return "chest height"
		if(4) return "very deep"
		else  return "unknown depth" // shouldn't happen but just in case.


/datum/reagents/fluid_group/temperature_reagents(exposed_temperature, exposed_volume = 100, exposed_heat_capacity = 100, change_cap = 15, change_min = 0.0000001, loud = 0, cannot_be_cooled = FALSE)
	..()
	src.update_total()


/datum/reagents/fluid_group/play_mix_sound(mix_sound) // play sound at random locs
	for(var/i = 0, i < length(my_group.members) / 20, i++)
		playsound(pick(my_group.members), mix_sound, 80, 1)

		if(i > 8)
			break


/datum/reagents/fluid_group/get_state_description()
	if(istype(src.my_group, /datum/fluid_group/airborne))
		return "vapor"
	else
		return "fluid"


/datum/reagents/fluid_group/is_airborne()
	return istype(src.my_group, /datum/fluid_group/airborne)
