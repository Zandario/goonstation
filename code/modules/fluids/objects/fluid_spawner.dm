/**
 * Use these to have fluids be built into areas of a map on load.
 * Spawn fluid, then delete self.
 */
/obj/fluid_spawner // TODO: convert to a map helper.
	icon = 'icons/effects/mapeditor.dmi'
	icon_state = "fluid_spawn"
	invisibility = INVIS_ADVENTURE
	event_handler_flags = IMMUNE_MANTA_PUSH

	var/reagent_id = "water"
	var/amount = 10
	var/delay = 600
	var/datum/reagents/R


/obj/fluid_spawner/New()
	..()
	SPAWN(delay)
		R = new /datum/reagents(amount)
		R.add_reagent(reagent_id, amount)

		var/turf/T = get_turf(src)
		if(isturf(T))
			T.fluid_react(R,amount)
			R.clear_reagents()
			qdel(src)

/obj/fluid_spawner/shortdelay
	amount = 50
	delay = 10

/obj/fluid_spawner/shortdelaybig
	amount = 5000
	delay = 10

/obj/fluid_spawner/wine
	amount = 330
	reagent_id = "wine"



// Polluted filth

/obj/fluid_spawner/polluted_filth
	delay = 35
	amount = 1250
	reagent_id = "sewage"

/obj/fluid_spawner/polluted_filth/madness
	amount = 166
	reagent_id = "madness_toxin"

/obj/fluid_spawner/polluted_filth/blood
	amount = 175
	reagent_id = "blood"

/obj/fluid_spawner/polluted_filth/black_goop
	amount = 148
	reagent_id = "black_goop"

/obj/fluid_spawner/polluted_filth/green_goop
	amount = 143
	reagent_id = "green_goop"

/obj/fluid_spawner/polluted_filth/yuck
	amount = 150
	reagent_id = "yuck"

/obj/fluid_spawner/polluted_filth/salmonella
	amount = 135
	reagent_id = "salmonella"

/obj/fluid_spawner/polluted_filth/bathsalts
	amount = 130
	reagent_id = "bathsalts"

/obj/fluid_spawner/polluted_filth/ecoli
	amount = 136
	reagent_id = "e.coli"

/obj/fluid_spawner/polluted_filth/crank
	amount = 145
	reagent_id = "crank"
