/atom/EnteredAirborneFluid(obj/fluid/F)
	F.group.reagents.reaction(src, TOUCH, 0, 0)

/obj/particle/EnteredAirborneFluid(obj/fluid/F)
	return FALSE

/obj/overlay/EnteredAirborneFluid(obj/fluid/F)
	return FALSE

/obj/effects/EnteredAirborneFluid(obj/fluid/F)
	return FALSE

/obj/blob/EnteredAirborneFluid(obj/fluid/F)
	F.group.reagents.reaction(src, TOUCH, F.volume, TRUE)

/mob/EnteredAirborneFluid(obj/fluid/airborne/F, atom/oldloc)
	/// Did the entering atom cross from a non-fluid to a fluid tile?
	var/entered_group = TRUE

	var/turf/T = get_turf(oldloc)
	var/turf/currentloc = get_turf(src)
	if(currentloc != T && T?.active_airborne_liquid)
		entered_group = FALSE

	if(entered_group && !src.clothing_protects_from_chems())
		F.just_do_the_apply_thing(src, hasmask = issmokeimmune(src))
	return FALSE

/mob/living/silicon/EnteredAirborneFluid(obj/fluid/airborne/F, atom/oldloc)
	return FALSE

/obj/fluid/airborne/EnteredAirborneFluid(obj/fluid/F)
	return FALSE

// /mob/EnteredAirborneFluid(obj/fluid/F as obj, atom/oldloc)
// 	return FALSE
