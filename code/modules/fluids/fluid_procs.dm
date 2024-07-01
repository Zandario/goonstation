///////////////////
//Turf Procs/Vars//
///////////////////

/turf/var/tmp/obj/fluid/active_liquid

//this is messy!
//this is for turf/space/fluid oceans. Using this in place of turf/canpass() because this one can account for shitt like windows and tables.
/turf/proc/ocean_canpass()
	if(src.density)
		return FALSE
	for(var/atom/A in src.contents)
		if(IS_SOLID_TO_FLUID(A) && (A.density || A.flags & FLUID_DENSE))
			return FALSE // && !istype(thing,/obj/grille) && !istype(thing,/obj/table) && !istype(thing,/obj/structure/girder)) return 0
	return TRUE


/turf/simulated/floor/plating/airless/ocean_canpass()
	return FALSE


/turf/selftilenotify()
	if(src.active_liquid && src.active_liquid.group && !src.can_crossed_by(src.active_liquid))
		src.active_liquid.group.displace(src.active_liquid)
	else
		///HEY HEY LOOK AT ME TODO : This is kind of a band-aid. I'm not sure why, but tilenotify() doesn't trigger when it should sometimes. do this to be absolutely sure!
		for(var/dir in global.cardinal)
			var/turf/T = get_step(src, dir)
			if(QDELETED(T))
				continue

			if(T.active_liquid)
				T.active_liquid.blocked_dirs = 0
				if(T.active_liquid.group && !T.active_liquid.group.updating)
					T.active_liquid.group.add_spread_process()
					break

			if(T.active_airborne_liquid)
				T.active_airborne_liquid.blocked_dirs = 0
				if(T.active_airborne_liquid.group && !T.active_airborne_liquid.group.updating)
					T.active_airborne_liquid.group.add_spread_process()
					break

	return ..()


/turf/tilenotify()
	if(src.active_liquid)
		src.active_liquid.blocked_dirs = 0
		if (src.active_liquid.group && !src.active_liquid.group.updating)
			src.active_liquid.group.add_spread_process()
	if(src.active_airborne_liquid)
		src.active_airborne_liquid.blocked_dirs = 0
		if (src.active_airborne_liquid.group && !src.active_airborne_liquid.group.updating)
			src.active_airborne_liquid.group.add_spread_process()
	return ..()


/// this should happen whenever a liquid reagent hits a simulated tile
/turf/proc/fluid_react(datum/reagents/R, react_volume, airborne = FALSE, index = 0, processing_cleanables=FALSE)
	if((react_volume <= 0) || !IS_VALID_FLUIDREACT_TURF(src))
		return

	if(!index)
		if(airborne)
			purge_smoke_blacklist(R)
		else
			purge_fluid_blacklist(R)
	else // We only care about one chem
		var/CI = 1
		if(airborne)
			purge_smoke_blacklist(R)
		else
			for(var/reagent_id as anything in R.reagent_list)
				if (CI++ == index)
					var/datum/reagent/reagent = R.reagent_list[reagent_id]
					if(HAS_FLAG(reagent.fluid_flags, FLUID_BANNED))
						return

	var/datum/fluid_group/FG
	var/obj/fluid/F
	var/fluid_and_group_already_exist = FALSE

	if(airborne)
		if(!src.active_airborne_liquid || QDELETED(src.active_airborne_liquid) || QDELETED(src.active_airborne_liquid.group))
			FG = new /datum/fluid_group/airborne
			F = new /obj/fluid/airborne
			src.active_airborne_liquid = F
			F.set_up(src)
			if(!react_volume)
				react_volume = TRUE
		else
			F = src.active_airborne_liquid
			if(F.group)
				FG = F.group
				fluid_and_group_already_exist = TRUE
			else
				FG = new /datum/fluid_group/airborne
				if(!react_volume)
					react_volume = TRUE
	else
		if(!src.active_liquid || QDELETED(src.active_liquid) || QDELETED(src.active_liquid.group))
			FG = new
			F = new /obj/fluid
			src.active_liquid = F
			F.set_up(src)
			if(!react_volume)
				react_volume = TRUE
		else
			F = src.active_liquid
			if (F.group)
				FG = F.group
				fluid_and_group_already_exist = TRUE
			else
				FG = new
				if(!react_volume)
					react_volume = TRUE

	FG.add(F, react_volume, guarantee_is_member = fluid_and_group_already_exist)
	R.trans_to_direct(FG.reagents, react_volume, index=index)
	if(QDELETED(FG)) // if only a reagent which immediately combusts gets added we rip (see emagged firebot critter's third ability)
		return

	// Normally `volume` isn't set until the fluid group process procs, but we sometimes need it right away for mob reactions etc.
	// We know the puddle starts as a single tile, so until then just set `volume` as the total reacted reagent volume.
	F.volume = FG.reagents.total_volume
	F.UpdateIcon(FALSE, FALSE)

	if(!airborne && !processing_cleanables)
		var/turf/simulated/floor/T = src
		if(istype(T) && T.messy > 0)
			var/found_cleanable = FALSE
			for(var/obj/decal/cleanable/C in T)
				if(istype(T) && !T.cleanable_fluid_react(C, TRUE)) // Some cleanables need special treatment
					found_cleanable = TRUE //there exists a cleanable without a special case
					break
			if(found_cleanable)
				T.cleanable_fluid_react(null,TRUE)

	F.trigger_fluid_enter()

//s/ ame as the above, but using a reagent_id instead of a datum
/turf/proc/fluid_react_single(reagent_name, react_volume, airborne = 0, processing_cleanables=FALSE)
	if((react_volume <= 0) || !IS_VALID_FLUIDREACT_TURF(src))
		return

	var/datum/reagent/cached = reagents_cache[reagent_name]
	if((airborne && HAS_FLAG(cached.fluid_flags, FLUID_SMOKE_BANNED)) || HAS_FLAG(cached.fluid_flags, FLUID_BANNED))
		return

	var/datum/fluid_group/FG
	var/obj/fluid/F
	var/fluid_and_group_already_exist = FALSE


	if(airborne)
		if(!src.active_airborne_liquid)
			FG = new /datum/fluid_group/airborne
			F = new /obj/fluid/airborne
			src.active_airborne_liquid = F
			F.set_up(src)
			if(!react_volume)
				react_volume = TRUE
		else
			F = src.active_airborne_liquid
			if(F.group)
				FG = F.group
				fluid_and_group_already_exist = 1
			else
				FG = new /datum/fluid_group/airborne
				if(!react_volume)
					react_volume = TRUE
	else
		if(!src.active_liquid)
			FG = new
			F = new /obj/fluid
			src.active_liquid = F
			F.set_up(src)
			if(!react_volume)
				react_volume = TRUE
		else
			F = src.active_liquid
			if(F.group)
				FG = F.group
				fluid_and_group_already_exist = 1
			else
				FG = new
				if(!react_volume)
					react_volume = TRUE


	FG.reagents.add_reagent(reagent_name, react_volume)
	FG.add(F, react_volume, guarantee_is_member = fluid_and_group_already_exist)
	F.done_init()
	. = F

	if(!airborne && !processing_cleanables)
		var/turf/simulated/floor/T = src
		if(istype(T) && T.messy > 0)
			var/found_cleanable = FALSE
			for(var/obj/decal/cleanable/C in T)
				if(istype(T) && !T.cleanable_fluid_react(C, TRUE))
					found_cleanable = TRUE
					break

			if(found_cleanable)
				T.cleanable_fluid_react(null,TRUE)

	F.trigger_fluid_enter()


/turf/proc/react_all_cleanables() //Same procedure called in fluid_react and fluid_react_single. copypasted cause i dont wanna proc call overhead up in hea

/turf/simulated/floor/react_all_cleanables() //Same procedure called in fluid_react and fluid_react_single. copypasted cause i dont wanna proc call overhead up in hea
	if(src.messy <= 0)
		return //hey this is CLEAN so don't even bother looping through contents, thanks!!

	var/found_cleanable = FALSE
	for(var/obj/decal/cleanable/C in src)
		if(!src.cleanable_fluid_react(C, TRUE)) // Some cleanables need special treatment
			found_cleanable = TRUE //there exists a cleanable without a special case

	if (found_cleanable)
		src.cleanable_fluid_react(null,TRUE)

//called whenever a cleanable is spawned. Returns 1 on success
//grab_any_amount will be True when a fluid spreads onto a tile that may have cleanables on it
/turf/simulated/proc/cleanable_fluid_react(obj/decal/cleanable/possible_cleanable, grab_any_amount = FALSE)
	if(!IS_VALID_FLUIDREACT_TURF(src))
		return FALSE
	//if possible_cleanable has a value, handle exclusively this decal. don't search thru the turf.
	if(possible_cleanable)
		if(possible_cleanable.qdeled || possible_cleanable.disposed)
			return FALSE

		if(istype(possible_cleanable, /obj/decal/cleanable/blood/dynamic))
			var/obj/decal/cleanable/blood/dynamic/blood = possible_cleanable
			var/blood_dna = blood.blood_DNA
			var/blood_type = blood.blood_type
			var/is_tracks = istype(possible_cleanable,/obj/decal/cleanable/blood/dynamic/tracks)
			if(is_tracks && !grab_any_amount)
				return FALSE

			if(blood?.reagents.total_volume >= 13 || src.active_liquid || grab_any_amount)
				if(blood.reagents)
					var/datum/reagents/R = new(blood.reagents.maximum_volume) //Store reagents, delete cleanable, and then fluid react. prevents recursion
					blood.reagents.copy_to(R)
					var/blood_volume = blood.reagents.total_volume
					blood.clean_forensic()
					src.fluid_react(R, is_tracks ? 0 : blood_volume)
				else
					var/reagent = blood.sample_reagent
					var/blood_volume = blood.reagents.total_volume
					blood.clean_forensic()
					src.fluid_react_single(reagent, is_tracks ? 0 : blood_volume)

				if(src.active_liquid)
					src.active_liquid.blood_DNA = blood_dna
					src.active_liquid.blood_type = blood_type

				return TRUE

		return FALSE

	//all right, tally up the cleanables and attempt to call fluid_reacts on them
	var/list/obj/decal/cleanable/cleanables = list()
	for(var/obj/decal/cleanable/C in src)
		if(QDELETED(C))
			continue
		//if (C.dry) continue
		if(istype(C, /obj/decal/cleanable/blood/dynamic) || !C.can_fluid_absorb)
			continue // handled above

		cleanables += C

	if(!src.active_liquid && (length(cleanables) < 3 && !grab_any_amount))
		return FALSE //If the tile has an active liquid already, there is no requirement

	// count actually valid cleanables
	var/valid_cleanables = 0
	for(var/obj/decal/cleanable/C as anything in cleanables)
		if(C.reagents || C.can_sample && C.sample_reagent)
			valid_cleanables++

	if(valid_cleanables < 3 && !grab_any_amount)
		return FALSE

	for(var/obj/decal/cleanable/C as anything in cleanables)
		var/datum/reagent/cached = reagents_cache[C.sample_reagent]
		if(C?.reagents)
			for(var/reagent_id in C.reagents.reagent_list)
				if(cached.fluid_flags & FLUID_STACKING_BANNED)
					return FALSE

			var/datum/reagents/R = new(C.reagents.maximum_volume) //Store reagents, delete cleanable, and then fluid react. prevents recursion
			C.reagents.copy_to(R)
			C.clean_forensic()
			src.fluid_react(R, R.total_volume, processing_cleanables = TRUE)

		else if(C?.can_sample && C.sample_reagent)
			if((!grab_any_amount && HAS_FLAG(cached.fluid_flags, FLUID_STACKING_BANNED)) || HAS_FLAG(cached.fluid_flags, FLUID_BANNED))
				return FALSE

			var/sample = C.sample_reagent
			var/volume = C.sample_volume
			C.clean_forensic()
			src.fluid_react_single(sample, volume, processing_cleanables = TRUE)
	return TRUE
