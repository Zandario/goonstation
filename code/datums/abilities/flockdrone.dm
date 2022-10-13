/datum/abilityHolder/critter/flockdrone
	usesPoints = TRUE

/datum/abilityHolder/critter/flockdrone/New()
	. = ..()
	if (!istype(owner, /mob/living/critter/flock/drone))
		stack_trace("Flockdrone abilityHolder initialized on non-flockdrone [src] (\ref[src])")

/datum/abilityHolder/critter/flockdrone/onAbilityStat()
	..()
	. = list()
	.["Resources:"] = src.points

/datum/abilityHolder/critter/flockdrone/proc/updateResources(resources)
	src.points = resources
	src.updateText(0, src.x_occupied, src.y_occupied)
