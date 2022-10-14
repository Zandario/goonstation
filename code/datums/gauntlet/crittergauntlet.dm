/area/gauntlet
	name = "The Gauntlet"
	icon_state = "dk_yellow"
	virtual = 1
	dont_log_combat = TRUE

/area/gauntlet/Entered(atom/A)
	..()
	if (!ismob(A))
		return
	if (gauntlet_controller.state == 1)
		for (var/mob/living/L in gauntlet_controller.staging)
			return
		gauntlet_controller.finishStaging()

/area/gauntlet/staging
	name = "Gauntlet Staging Area"
	icon_state = "purple"
	virtual = 1
	ambient_light = "#bfbfbf"

/area/gauntlet/staging/Entered(atom/movable/A)
	..()
	if (isliving(A))
		if (gauntlet_controller.state >= 2)
			A:gib()

/area/gauntlet/viewing
	name = "Gauntlet Spectator's Area"
	icon_state = "green"
	virtual = 1
	ambient_light = "#bfbfbf"

/mob/proc/is_near_gauntlet()
	var/area/A = get_area(src)
	if (istype(A, /area/gauntlet))
		return 1
	if (ismob(eye))
		var/mob/M = eye
		if (M != src && M.is_near_gauntlet())
			return 1
	else if (istype(eye, /obj/observable/gauntlet))
		return 1
	return 0

/mob/proc/is_in_gauntlet()
	var/area/A = get_area(src)
	if (A?.type == /area/gauntlet)
		return 1
	return 0

/obj/stagebutton
	name = "Gauntlet Staging Button"
	desc = "By pressing this button, you begin the staging process. No more new attendees will be accepted."
	anchored = 1
	density = 0
	opacity = 0
	icon = 'icons/effects/VR.dmi'
	icon_state = "doorctrl0"

/obj/stagebutton/attack_hand(mob/M)
	if (gauntlet_controller.state != 0)
		return
	if (ticker.round_elapsed_ticks < 3000)
		boutput(usr, "<span class='alert'>You may not initiate the Gauntlet before 5 minutes into the round.</span>")
		return
	if (alert("Start the Gauntlet? No more players will be given admittance to the staging area!",, "Yes", "No") == "Yes")
		if (gauntlet_controller.state != 0)
			return
		gauntlet_controller.beginStaging()

/obj/adventurepuzzle/triggerable/light/gauntlet
	on_brig = 7
	on_cred = 1
	on_cgreen = 1
	on_cblue = 1

/obj/adventurepuzzle/triggerable/light/gauntlet/New()
	..()
	on()

/datum/arena/gauntletController
	var/area/gauntlet/staging/staging
	var/area/gauntlet/viewing/viewing
	var/area/gauntlet/gauntlet
	var/list/spawnturfs = list()

	var/list/possible_waves = list()
	var/list/possible_events = list()
	var/list/possible_drops = list()
	var/list/moblist = list()

	var/list/current_waves = list()
	var/datum/gauntletEvent/current_event = null
	var/datum/gauntletWave/fallback/fallback

	var/list/critters_left = list()

	var/current_match_id = 0
	var/difficulty = 0
	var/state = 0
	var/players = 0
	var/current_level = 0
	var/next_level_at = 0
	var/waiting = 0

	var/score = 0
	var/moblist_names = ""

	var/resetting = 0

/datum/arena/gauntletController/proc/announceAll(message, title = "Gauntlet update")
	var/rendered = "<span style='font-size: 1.5em; font-weight:bold'>[title]</span><br><br><span style='font-weight:bold;color:blue'>[message]<br>"
	for (var/mob/M in staging)
		boutput(M, rendered)
	for (var/mob/M in viewing)
		boutput(M, rendered)
	for (var/mob/M in gauntlet)
		boutput(M, rendered)
	for (var/mob/M in mobs)
		LAGCHECK(LAG_LOW)
		if (ismob(M.eye) && M.eye != M)
			var/mob/N = M.eye
			if (N.is_near_gauntlet())
				boutput(M, rendered)
		else if (istype(M.eye, /obj/observable/gauntlet))
			boutput(M, rendered)

/datum/arena/gauntletController/proc/beginStaging()
	if (state != 0)
		return
	state = 1
	moblist.len = 0
	moblist_names = ""
	for (var/obj/machinery/door/poddoor/buff/staging/S in staging)
		SPAWN(0)
			S.close()
	var/mobcount = 0
	for (var/mob/living/M in staging)
		mobcount++
		moblist += M
		if (moblist_names != "")
			moblist_names += ", "
		var/thename = M.real_name
		if (istype(M, /mob/living/carbon/human/virtual))
			var/mob/living/L = M:body
			if (L)
				thename = L.real_name
			else
				thename = copytext(M.real_name, 9)
		moblist_names += thename
		if (M.client)
			moblist_names += " ([M.client.key])"
		for (var/obj/item/I in M)
			if (!istype(I, /obj/item/clothing/under) && !istype(I, /obj/item/clothing/shoes) && !istype(I, /obj/item/parts) && !istype(I, /obj/item/organ) && !istype(I, /obj/item/skull))
				qdel(I)
	var/default_table = null
	var/list/tables = list()
	for (var/obj/table/T in staging)
		tables += T
	if (tables.len)
		default_table = pick(tables)
	else
		default_table = locate(/turf/unsimulated/floor) in staging
	for (var/i = 1, i <= mobcount, i++)
		var/target = default_table
		if (tables.len)
			target = pick(tables)
		if (i > moblist.len)
			spawnGear(get_turf(target), null)
		else
			spawnGear(get_turf(target), moblist[i])
		tables -= target
	for (var/i = 1, i <= mobcount, i++)
		var/target = default_table
		if (tables.len)
			target = pick(tables)
		spawnMeds(get_turf(target))
		tables -= target
	announceAll("The Critter Gauntlet Arena has now entered staging phase. No more players may enter the game area. The game will start once all players enter the gauntlet chamber.")
	players = mobcount
	current_level = 1
	for (var/datum/gauntletDrop/D in possible_drops)
		D.used = 0
	current_match_id++
	var/spawned_match_id = current_match_id
	SPAWN(0)
		for (var/obj/machinery/door/poddoor/buff/gauntlet/S in gauntlet)
			SPAWN(0)
				S.open()
		for (var/obj/machinery/door/poddoor/buff/gauntlet/S in staging)
			SPAWN(0)
				S.open()
	allow_processing = 1
	SPAWN(2 MINUTES)
		if (state == 1 && current_match_id == spawned_match_id)
			announceAll("Game did not start after 2 minutes. Resetting arena.")
			resetArena()

/datum/arena/gauntletController/proc/finishStaging()
	if (state == 2)
		return
	state = 2
	SPAWN(0)
		for (var/obj/machinery/door/poddoor/buff/gauntlet/S in gauntlet)
			SPAWN(0)
				S.close()
		for (var/obj/machinery/door/poddoor/buff/gauntlet/S in staging)
			SPAWN(0)
				S.close()
		for (var/mob/living/M in gauntlet)
			if (M in moblist)
				continue
			moblist += M
			if (moblist_names != "")
				moblist_names += ", "
			var/thename = M.real_name
			if (istype(M, /mob/living/carbon/human/virtual))
				var/mob/living/L = M:body
				if (L)
					thename = L.real_name
				else
					thename = copytext(M.real_name, 9)
			moblist_names += thename
			if (M.client)
				moblist_names += " ([M.client.key])"
		logTheThing(LOG_DEBUG, null, "<b>Marquesas/Critter Gauntlet</b>: Starting arena game with players: [moblist_names]")
	announceAll("The Critter Gauntlet Arena game is now in progress. The first level will begin soon.")
	next_level_at = ticker.round_elapsed_ticks + 300

/datum/arena/gauntletController/process()
	if (state == 2)
		if (ticker.round_elapsed_ticks > next_level_at)
			startWave()
	else if (state == 3)
		if (current_event)
			current_event.process()
		if (current_waves.len)
			if (waiting <= 0)
				var/datum/gauntletWave/wave = current_waves[1]
				if (wave.spawnIn(current_event))
					current_waves.Cut(1,2)
					if (current_waves.len)
						wave = current_waves[1]
						applyDifficulty(wave)
						waiting = 8
			else
				waiting--
		else
			if (waiting <= 0)
				var/live = 0
				var/pc = 0
				for (var/obj/critter/C in gauntlet)
					if (!C.alive)
						showswirl(get_turf(C))
						qdel(C)
					else
						live++
				if (!live)
					finishWave()
				for (var/mob/living/M in gauntlet)
					if (!isdead(M) && M.client)
						pc++
				for (var/obj/O in gauntlet)
					for (var/mob/living/M in O)
						if (!isdead(M) && M.client)
							pc++
				if (!pc)
					state = 0
				waiting = 8
			else
				waiting--

	if (state == 0)
		resetArena()


/datum/arena/gauntletController/proc/resetArena()
	if (resetting)
		return
	resetting = 1
	allow_processing = 0
	announceAll("The Critter Gauntlet match concluded at level [current_level].")
	if (current_level > 50)
		var/command_report = "A Critter Gauntlet match has concluded at level [current_level]. Congratulations to: [moblist_names]."
		for_by_tcl(C, /obj/machinery/communications_dish)
			C.add_centcom_report(ALERT_GENERAL, command_report)

		command_alert(command_report, "Critter Gauntlet match finished")
	statlog_gauntlet(moblist_names, score, current_level)

	SPAWN(0)
		for (var/obj/item/I in staging)
			qdel(I)
		for (var/obj/item/I in gauntlet)
			qdel(I)
		for (var/obj/artifact/A in gauntlet)
			qdel(A)
		for (var/obj/critter/C in gauntlet)
			qdel(C)
		for (var/obj/machinery/bot/B in gauntlet)
			qdel(B)
		for (var/mob/living/M in gauntlet)
			M.gib()
		for (var/mob/living/M in staging)
			M.gib()
		for (var/obj/decal/D in gauntlet)
			if (!istype(D, /obj/decal/teleport_swirl))
				qdel(D)

		for (var/obj/machinery/door/poddoor/buff/staging/S in staging)
			SPAWN(0)
				S.open()
		for (var/obj/machinery/door/poddoor/buff/gauntlet/S in gauntlet)
			SPAWN(0)
				S.close()
		for (var/obj/machinery/door/poddoor/buff/gauntlet/S in staging)
			SPAWN(0)
				S.close()

	if (current_event)
		current_event.tearDown()
		current_event = null
	current_waves.len = 0
	current_level = 0
	moblist.len = 0
	moblist_names = ""
	score = 0
	state = 0
	players = 0
	resetting = 0

/datum/arena/gauntletController/proc/spawnGear(turf/target, mob/forwhom)
	new /obj/item/storage/backpack/NT(target)
	new /obj/item/clothing/suit/armor/tdome/yellow(target)
	var/list/masks = list(/obj/item/clothing/mask/batman, /obj/item/clothing/mask/clown_hat, /obj/item/clothing/mask/horse_mask, /obj/item/clothing/mask/moustache, /obj/item/clothing/mask/gas/swat, /obj/item/clothing/mask/owl_mask, /obj/item/clothing/mask/hunter, /obj/item/clothing/mask/skull, /obj/item/clothing/mask/spiderman)
	var/masktype = pick(masks)
	new masktype(target)
	new /obj/item/gun/energy/laser_gun/virtual(target)
	new /obj/item/extinguisher/virtual(target)
	new /obj/item/card/id/gauntlet(target, forwhom)
	var/obj/item/artifact/activator_key/A = new /obj/item/artifact/activator_key(target)
	SPAWN(2.5 SECONDS)
		A.name = "Artifact Activator Key"

/datum/arena/gauntletController/proc/spawnMeds(turf/target)
	for (var/medtype in list(/obj/item/storage/firstaid/vr/regular, /obj/item/storage/firstaid/vr/fire, /obj/item/storage/firstaid/vr/brute, /obj/item/storage/firstaid/vr/toxin, /obj/item/reagent_containers/pill/vr/mannitol, /obj/item/storage/box/donkpocket_w_kit/vr))
		new medtype(target)

/datum/arena/gauntletController/proc/increaseCritters(obj/critter/C)
	var/name = initial(C.name)
	if (!(name in critters_left))
		critters_left += name
		critters_left[name] = 0
	critters_left[name] += 1

/datum/arena/gauntletController/proc/decreaseCritters(obj/critter/C)
	var/name = initial(C.name)
	if (!(name in critters_left))
		return
	critters_left[name] -= 1
	if (critters_left[name] <= 0)
		critters_left -= name

/datum/arena/gauntletController/New()
	..()
	SPAWN(0.5 SECONDS)
		viewing = locate() in world
		staging = locate() in world
		for (var/area/G in world)
			LAGCHECK(LAG_LOW)
			if (G.type == /area/gauntlet)
				gauntlet = G
				break
		for (var/turf/T in gauntlet)
			if (!T.density)
				spawnturfs += T

		for (var/tp in childrentypesof(/datum/gauntletEvent))
			possible_events += new tp()

		for (var/tp in childrentypesof(/datum/gauntletDrop))
			possible_drops += new tp()

		for (var/tp in childrentypesof(/datum/gauntletWave) - /datum/gauntletWave/fallback)
			possible_waves += new tp()

		fallback = new()

/datum/arena/gauntletController/proc/dropIsPossible(datum/gauntletDrop/drop, points)
	if (drop.used)
		return 0
	if (current_level < drop.minimum_level)
		return 0
	if (current_level > drop.maximum_level)
		return 0
	if (points < drop.point_cost)
		return 0
	if (!prob(drop.probability))
		return 0
	return 1

/datum/arena/gauntletController/proc/startWave()
	if (state == 3)
		return
	state = 3

	calculateDifficulty()


	var/points = 2.5 + (round(current_level * 0.1) * 1.5) + ((current_level % 10) / 20)
	logTheThing(LOG_DEBUG, null, "<b>Marquesas/Critter Gauntlet:</b> On level [current_level]. Spending [points] points, composed of 1 base, [round(current_level * 0.1) * 1.5] major and [(current_level % 10) / 20] minor.")

	var/datum/gauntletEvent/candidate = pick(possible_events)
	if (current_level >= candidate.minimum_level && points > candidate.point_cost && prob(candidate.probability))
		current_event = candidate
		points -= candidate.point_cost
	else
		current_event = null

	var/datum/gauntletDrop/drop = pick(possible_drops)
	var/retries = 0
	while (!dropIsPossible(drop, points) && retries < 25)
		drop = pick(possible_drops)
		retries++
	if (retries < 25)
		drop.doDrop()
		points -= drop.point_cost
	else
		drop = null

	current_waves.len = 0
	var/waves_this_level = max(1, current_level + rand(-1, 1))
	for (var/i = 1, i <= waves_this_level, i++)
		var/list/choices = possible_waves.Copy()
		while (choices.len)
			var/datum/gauntletWave/wave = pick(choices)
			choices -= wave
			if (wave.point_cost < points)
				points -= wave.point_cost
				current_waves += wave
				break

	if (!current_waves.len)
		current_waves += fallback

	if (current_event)
		current_event.setUp()

	applyDifficulty(current_waves[1])

	var/announcement = "Starting level [current_level] now!"
	if (current_event)
		announcement += "<br>Special event this level: [current_event]."
	if (drop)
		announcement += "<br>Supplies this level: [drop]."
	announceAll(announcement)
	waiting = 0

/datum/arena/gauntletController/proc/finishWave()
	if (state == 2)
		return
	state = 2

	if (current_event)
		current_event.tearDown()

	for (var/obj/decal/D in gauntlet)
		if (!istype(D, /obj/decal/teleport_swirl))
			qdel(D)
	for (var/obj/item/parts/human_parts/P in gauntlet)
		if (isturf(P.loc))
			qdel(P)
	for (var/obj/item/electronics/E in gauntlet)
		qdel(E)

	current_level++
	current_waves.len = 0
	critters_left.len = 0
	current_event = null
	next_level_at = ticker.round_elapsed_ticks + 150
	announceAll("Level [current_level - 1] is finished. Next level starting in 15 seconds!")

/datum/arena/gauntletController/proc/calculateDifficulty()
	difficulty = 0.5 + (current_level / 20) * max(1, players / 3)

/datum/arena/gauntletController/proc/applyDifficulty(datum/gauntletWave/wave)
	wave.count = initial(wave.count)
	wave.count *= difficulty / 1.5 + rand(-10, 10) * 0.1
	wave.count = round(max(1, wave.count))
	wave.health_multiplier = max(difficulty / 1.5 + rand(-10, 10) * 0.1, 0.1)

/datum/arena/gauntletController/proc/Stat()
	stat(null, "")
	stat(null, "--- GAUNTLET ---")
	switch (state)
		if (0)
			stat(null, "No match is currently in progress.")
		if (1)
			stat(null, "Match is currently in setup stage.")
			stat(null, "Registered players: [players]")
		if (2)
			stat(null, "Next level starts in [dstohms(next_level_at - ticker.round_elapsed_ticks)].")
			stat(null, "Next level: [current_level]")
		if (3)
			stat(null, "Current difficulty: [difficulty]")
			stat(null, "Current level: [current_level]")
			if (current_event)
				stat(null, "Special event: [current_event]")
			stat(null, "")
			if (current_waves.len)
				stat(null, "Remaining waves this level: ")
				if (current_level < 50)
					for (var/i = 1, i <= current_waves.len, i++)
						var/datum/gauntletWave/W = current_waves[i]
						stat(null, "- [W.name]")
				else if (current_level < 100)
					for (var/i = 1, i <= current_waves.len, i++)
						stat(null, "- ???")
				else
					stat(null, "No information")
			else
				stat(null, "Critters in gauntlet: ")
				if (current_level < 50)
					for (var/name in critters_left)
						if (critters_left[name])
							stat(null, "- [critters_left[name]] [name][critters_left[name] > 1 ? "s" : null]")
				else if (current_level < 100)
					var/sum = 0
					for (var/name in critters_left)
						sum += critters_left[name]
					stat(null, "- [sum] critter[sum > 1 ? "" : null]")
				else
					stat(null, "No information")
	stat(null, "--- GAUNTLET ---")
	stat(null, "")


var/global/datum/arena/gauntletController/gauntlet_controller = new()

/obj/observable
	invisibility = INVIS_ALWAYS
	name = "Observable"
	desc = "observable"
	anchored = 1
	density = 0
	opacity = 0
	icon = 'icons/misc/buildmode.dmi'
	icon_state = "build" // don't judge me
	var/obj/machinery/camera/cam
	var/has_camera = 0
	var/cam_network = null

/obj/observable/New()
	..()
	if (has_camera)
		src.cam = new /obj/machinery/camera(src)
		src.cam.c_tag = src.name
		src.cam.network = cam_network
	START_TRACKING

/obj/observable/disposing()
	. = ..()
	STOP_TRACKING

/obj/observable/gauntlet
	name = "The Gauntlet Arena"
	has_camera = 1
	cam_network = "Zeta"

/datum/gauntletDrop
	var/name = "Drop"
	var/point_cost = 0
	var/minimum_level = 0
	var/maximum_level = 250
	var/probability = 45
	var/list/supplies = list()
	var/min_percent = 0.2
	var/max_percent = 0.7
	var/max_amount = -1
	var/only_once = 0
	var/used = 0

/datum/gauntletDrop/proc/doDrop()
	var/amount = max(1, rand(round(gauntlet_controller.players * min_percent), round(gauntlet_controller.players * max_percent)))
	if (max_amount > 0)
		amount = min(amount, max_amount)
	for (var/i = 1, i <= amount, i++)
		var/ST = pick(supplies)
		var/turf/T = pick(gauntlet_controller.spawnturfs)
		new ST(T)
		showswirl(T)

	if (only_once)
		used = 1

/datum/gauntletDrop/artifact
	name = "A Handheld Artifact"
	minimum_level = 35
	supplies = list(/obj/item/gun/energy/artifact)

/datum/gauntletDrop/artifact/doDrop()
	var/ST = supplies[1]
	var/T = pick(gauntlet_controller.spawnturfs)
	var/obj/O = new ST(T)
	showswirl(T)
	SPAWN(0.5 SECONDS)
		O.ArtifactActivated()

/datum/gauntletDrop/artifact/forcewall
	minimum_level = 25
	supplies = list(/obj/item/artifact/forcewall_wand)

/datum/gauntletDrop/artifact/melee
	minimum_level = 15
	supplies = list(/obj/item/artifact/melee_weapon)

/datum/gauntletDrop/inactive_artifact
	name = "An Artifact"
	minimum_level = 20
	supplies = list(/obj/machinery/artifact/bomb, /obj/artifact/darkness_field, /obj/artifact/healer_bio, /obj/artifact/forcefield_generator, /obj/artifact/power_giver)
	max_amount = 1

/datum/gauntletDrop/hamburgers
	name = "Hamburgers"
	minimum_level = 0
	maximum_level = 5
	min_percent = 0.5
	max_percent = 1
	supplies = list(/obj/item/reagent_containers/food/snacks/burger/vr)

/datum/gauntletDrop/tinfoil
	name = "A Tinfoil Hat"
	minimum_level = 5
	max_amount = 1
	supplies = list(/obj/item/clothing/head/tinfoil_hat)

/datum/gauntletDrop/incendiary
	name = "A High Range Incendiary Grenade"
	minimum_level = 5
	max_amount = 1
	supplies = list(/obj/item/chem_grenade/very_incendiary/vr)

/datum/gauntletDrop/weapon_cache
	name = "Pile o' Weapons"
	min_percent = 0.6
	max_percent = 1.5
	point_cost = -3
	minimum_level = 20
	probability =  20
	supplies = list(/obj/item/chem_grenade/very_incendiary/vr, /obj/item/gun/kinetic/spes, /obj/item/gun/energy/laser_gun/virtual)

/datum/gauntletDrop/welding
	name = "Welders"
	point_cost = -1
	minimum_level = 5
	min_percent = 0.25
	max_percent = 0.75
	supplies = list(/obj/item/weldingtool/vr)

/datum/gauntletDrop/revolver
	name = "Revolvers"
	point_cost = -2
	minimum_level = 15
	min_percent = 0.25
	max_percent = 0.5
	supplies = list(/obj/item/gun/kinetic/revolver/vr)

/datum/gauntletDrop/spes
	name = "SPES-12s"
	point_cost = -2
	minimum_level = 25
	min_percent = 0.25
	max_percent = 0.5
	supplies = list(/obj/item/gun/kinetic/spes)

/datum/gauntletDrop/rifle
	name = "Hunting Rifles"
	point_cost = -2
	minimum_level = 25
	min_percent = 0.25
	max_percent = 0.5
	supplies = list(/obj/item/gun/kinetic/hunting_rifle)

/datum/gauntletDrop/ak47
	name = "An AKM"
	point_cost = -2
	minimum_level = 45
	min_percent = 0.25
	max_percent = 0.5
	max_amount = 1
	supplies = list(/obj/item/gun/kinetic/akm)

/datum/gauntletDrop/bfg
	name = "The BFG"
	point_cost = -3
	minimum_level = 45
	min_percent = 0.25
	max_percent = 0.5
	max_amount = 1
	only_once = 1
	supplies = list(/obj/item/gun/energy/bfg/vr)

/datum/gauntletDrop/laser
	name = "Laser Guns"
	point_cost = -2
	probability = 100
	minimum_level = 15
	min_percent = 0.25
	max_percent = 0.5
	supplies = list(/obj/item/gun/energy/laser_gun/virtual)

/datum/gauntletDrop/predlaser
	name = "Advanced Laser Guns"
	point_cost = -3
	minimum_level = 25
	min_percent = 0.25
	max_percent = 0.5
	supplies = list(/obj/item/gun/energy/plasma_gun/vr)

/datum/gauntletDrop/axe
	name = "Energy Axes"
	point_cost = -2.5
	minimum_level = 35
	min_percent = 0.25
	max_percent = 0.5
	probability = 10
	supplies = list(/obj/item/axe/vr)

/datum/gauntletDrop/sword
	name = "Energy Swords"
	point_cost = -2.5
	minimum_level = 25
	min_percent = 0.25
	max_percent = 0.5
	supplies = list(/obj/item/sword/vr)

/datum/gauntletDrop/saw
	name = "Red Chainsaws"
	point_cost = -2.5
	minimum_level = 25
	min_percent = 0.25
	max_percent = 0.5
	supplies = list(/obj/item/saw/syndie/vr)

/datum/gauntletDrop/defib
	name = "Defibrillator"
	point_cost = -1
	minimum_level = 10
	max_amount = 1
	supplies = list(/obj/item/robodefibrillator/vr)
	only_once = 1

/datum/gauntletDrop/surgical
	name = "Surgical Tools"
	minimum_level = 15
	point_cost = -1
	supplies = list(/obj/item/reagent_containers/iv_drip/blood/vr, /obj/item/suture/vr, /obj/item/scalpel/vr, /obj/item/reagent_containers/food/drinks/bottle/vodka/vr)

/datum/gauntletDrop/medkits
	name = "Medkits"
	point_cost = -2
	minimum_level = 15
	supplies = list(/obj/item/storage/firstaid/vr/regular)

/datum/gauntletDrop/bb_medkits
	name = "Common Medkits"
	point_cost = -2
	minimum_level = 15
	supplies = list(/obj/item/storage/firstaid/vr/brute, /obj/item/storage/firstaid/vr/fire)

/datum/gauntletDrop/special_medkits
	name = "Special Medkits"
	point_cost = -2
	minimum_level = 15
	supplies = list(/obj/item/storage/firstaid/vr/toxin, /obj/item/storage/firstaid/vr/oxygen, /obj/item/storage/firstaid/vr/brain, /obj/item/reagent_containers/emergency_injector/vr/calomel)

/datum/gauntletEvent
	var/name = "Event"
	var/point_cost = 0.5
	var/minimum_level = 0
	var/probability = 60

/datum/gauntletEvent/proc/setUp()
/datum/gauntletEvent/proc/process()
/datum/gauntletEvent/proc/onSpawn(obj/critter/C)
/datum/gauntletEvent/proc/tearDown()

/datum/gauntletEvent/barricade
	name = "Maze"
	point_cost = 0
	minimum_level = 0

/datum/gauntletEvent/setUp()
	var/list/q = gauntlet_controller.spawnturfs.Copy()
	shuffle_list(q)
	var/percentage = rand(25, 45) * 0.01
	q.len = round(q.len * percentage)
	for (var/turf/T in q)
		new /obj/structure/woodwall/virtual(T)

/datum/gauntletEvent/tearDown()
	for (var/obj/structure/woodwall/virtual/W in gauntlet_controller.gauntlet)
		qdel(W)

/datum/gauntletEvent/regeneration
	name = "Heal Zone"
	point_cost = -1
	minimum_level = 10
	var/counter = 10

/datum/gauntletEvent/regeneration/setUp()
	for (var/turf/T in gauntlet_controller.gauntlet)
		if (!T.density)
			T.icon_state = "gauntfloorHearts"
			T.color = "#FF0000"
	counter = 10

/datum/gauntletEvent/regeneration/process()
	if (counter)
		counter--
	else
		for (var/mob/living/M in gauntlet_controller.gauntlet)
			M.HealDamage("All", 5, 5)
			//boutput(M, "<span class='notice'>A soothing wave of energy washes over you!</span>")
		counter = 10

/datum/gauntletEvent/regeneration/tearDown()
	for (var/turf/T in gauntlet_controller.gauntlet)
		T.icon_state = initial(T.icon_state)
		T.color = "#FFFFFF"

/datum/gauntletEvent/chill
	name = "Cold Zone"
	point_cost = 2
	minimum_level = 25

/datum/gauntletEvent/chill/setUp()
	for (var/turf/T in gauntlet_controller.gauntlet)
		if (!T.density)
			T.icon_state = "gauntfloorSnow"
			T.color = "#00FFFF"

/datum/gauntletEvent/chill/process()
	for (var/mob/living/M in gauntlet_controller.gauntlet)
		M.bodytemperature = T0C - 100

/datum/gauntletEvent/chill/tearDown()
	for (var/turf/T in gauntlet_controller.gauntlet)
		T.icon_state = initial(T.icon_state)
		T.color = "#FFFFFF"

	for (var/mob/living/M in gauntlet_controller.gauntlet)
		M.bodytemperature = M.base_body_temp

/datum/gauntletEvent/hot
	name = "Fire Zone"
	point_cost = 2
	minimum_level = 30

/datum/gauntletEvent/hot/setUp()
	for (var/turf/T in gauntlet_controller.gauntlet)
		if (!T.density)
			T.icon_state = "gauntfloorHeat"
			T.color = "#FF8800"

/datum/gauntletEvent/hot/process()
	for (var/mob/living/M in gauntlet_controller.gauntlet)
		M.bodytemperature = T0C + 120
		if (prob(10))
			if (!M.getStatusDuration("burning"))
				boutput(M, "<span class='alert'>You spontaneously combust!</span>")
			M.changeStatus("burning", 7 SECONDS)

/datum/gauntletEvent/hot/tearDown()
	for (var/turf/T in gauntlet_controller.gauntlet)
		T.icon_state = initial(T.icon_state)
		T.color = "#FFFFFF"

	for (var/mob/living/M in gauntlet_controller.gauntlet)
		M.bodytemperature = M.base_body_temp
		M.set_burning(0)

/datum/gauntletEvent/void
	name = "Toxic Zone"
	point_cost = 0
	minimum_level = 0

/datum/gauntletEvent/void/setUp()
	for (var/turf/T in gauntlet_controller.gauntlet)
		if (!T.density)
			T.icon_state = "gauntfloorSkulls"
			T.color = "#FF00FF"

/datum/gauntletEvent/void/process()
	if (prob(20))
		for (var/mob/living/M in gauntlet_controller.gauntlet)
			M.TakeDamage("chest", 1, 0, 0, DAMAGE_CUT)
			//boutput(M, "<span class='alert'>The void tears at you!</span>")
			// making the zone name a bit more obvious and making its spam chatbox less - ISN

/datum/gauntletEvent/void/tearDown()
	for (var/turf/T in gauntlet_controller.gauntlet)
		T.icon_state = initial(T.icon_state)
		T.color = "#FFFFFF"

/datum/gauntletEvent/darkness
	name = "Total Darkness"
	point_cost = 3
	minimum_level = 20

/datum/gauntletEvent/darkness/setUp()
	for (var/obj/adventurepuzzle/triggerable/light/gauntlet/G in gauntlet_controller.gauntlet)
		G.off()

/datum/gauntletEvent/darkness/onSpawn(obj/critter/C)
	var/datum/light/light = new /datum/light/point
	light.set_brightness(0.4)
	light.set_height(0.5)
	light.attach(C)
	light.enable()

/datum/gauntletEvent/darkness/tearDown()
	for (var/obj/adventurepuzzle/triggerable/light/gauntlet/G in gauntlet_controller.gauntlet)
		G.on()

/datum/gauntletEvent/flicker
	name = "Flickering Lights"
	point_cost = 1
	minimum_level = 20

/datum/gauntletEvent/flicker/process()
	for (var/obj/adventurepuzzle/triggerable/light/gauntlet/G in gauntlet_controller.gauntlet)
		if (prob(15))
			G.toggle()

/datum/gauntletEvent/flicker/tearDown()
	for (var/obj/adventurepuzzle/triggerable/light/gauntlet/G in gauntlet_controller.gauntlet)
		G.on()

/datum/gauntletEvent/redlights
	name = "Red Light District"
	point_cost = 0.5
	minimum_level = 10

/datum/gauntletEvent/redlights/setUp()
	for (var/obj/adventurepuzzle/triggerable/light/gauntlet/G in gauntlet_controller.gauntlet)
		G.off()
		G.on_cblue = 0
		G.on_cgreen = 0
		G.on()

/datum/gauntletEvent/redlights/tearDown()
	for (var/obj/adventurepuzzle/triggerable/light/gauntlet/G in gauntlet_controller.gauntlet)
		G.off()
		G.on_cblue = 1
		G.on_cgreen = 1
		G.on()

/datum/gauntletEvent/lightningstrikes
	name = "Lightning Strikes"
	point_cost = 1
	minimum_level = 15
	var/image/marker = null
	var/obj/zapdummy/D1
	var/obj/zapdummy/D2

/datum/gauntletEvent/lightningstrikes/setUp()
	var/turf/T

	for (var/turf/Q in gauntlet_controller.gauntlet)
		if (!T)
			T = Q
		if (Q.x < T.x || Q.y < T.y)
			T = Q

	marker = image('icons/effects/VR.dmi', "lightning_marker")
	if (!T)
		logTheThing(LOG_DEBUG, null, "Gauntlet event Lightning Strikes failed setup.")
	D1 = new(T)
	D2 = new()

/datum/gauntletEvent/lightningstrikes/process()
	if (D1)
		if (prob(round(20 * gauntlet_controller.difficulty)))
			var/turf/target = pick(gauntlet_controller.spawnturfs)
			target.overlays += marker

			SPAWN(2 SECONDS)
				if (!D2)
					return
				D2.set_loc(target)
				arcFlash(D1, D2, 5000)
				target.overlays -= marker

/datum/gauntletEvent/lightningstrikes/tearDown()
	qdel(D1)
	qdel(D2)
	for (var/turf/T in gauntlet_controller.gauntlet)
		T.overlays.len = 0

/obj/zapdummy
	invisibility = INVIS_ALWAYS
	anchored = 1
	density = 0

/datum/gauntletWave
	var/name = "Wave"
	var/point_cost = 1
	var/count = 5
	var/health_multiplier = 1
	var/list/types = list()

/datum/gauntletWave/proc/spawnIn(datum/gauntletEvent/ev)
	if (count)
		var/turf/T = pick(gauntlet_controller.spawnturfs)
		var/crit_type = pick(types)
		showswirl(T)
		var/obj/critter/C = new crit_type(T)
		C.health *= health_multiplier
		C.aggressive = 1
		C.defensive = 1
		C.opensdoors = OBJ_CRITTER_OPENS_DOORS_NONE
		if (ev)
			ev.onSpawn(C)
		count--
	if (count < 1)
		count = initial(count)
		return 1
	return 0

/datum/gauntletWave/mimic
	name = "Mimic"
	point_cost = 1
	count = 6
	types = list(/obj/critter/mimic)

/datum/gauntletWave/meaty
	name = "Meat Thing"
	point_cost = 1
	count = 2
	types = list(/obj/critter/blobman/meaty_martha)

/datum/gauntletWave/martian
	name = "Martian"
	point_cost = 1
	count = 6
	types = list(/obj/critter/martian)

/datum/gauntletWave/soldier
	name = "Martian Soldier"
	point_cost = 3
	count = 4
	types = list(/obj/critter/martian/soldier)

/datum/gauntletWave/warrior
	name = "Martian Warrior"
	point_cost = 3
	count = 2
	types = list(/obj/critter/martian/warrior)

/datum/gauntletWave/mutant
	name = "Martian Mutant"
	point_cost = 5
	count = 0.05
	types = list(/obj/critter/martian/psychic)

/datum/gauntletWave/martian_assorted
	name = "Martian Assortment"
	point_cost = 6
	count = 12
	types = list(/obj/critter/martian/soldier, /obj/critter/martian/soldier, /obj/critter/martian/soldier, /obj/critter/martian/warrior)

/datum/gauntletWave/bear
	name = "Bear"
	point_cost = 4
	count = 2
	types = list(/obj/critter/bear)

/datum/gauntletWave/tomato
	name = "Killer Tomato"
	point_cost = 2
	count = 8
	types = list(/obj/critter/killertomato)

/datum/gauntletWave/scdrone
	name = "SC Drone"
	point_cost = 4
	count = 4
	types = list(/obj/critter/gunbot/drone)

/datum/gauntletWave/crdrone
	name = "CR Drone"
	point_cost = 6
	count = 2
	types = list(/obj/critter/gunbot/drone/buzzdrone)

/datum/gauntletWave/hkdrone
	name = "HK Drone"
	point_cost = 8
	count = 1
	types = list(/obj/critter/gunbot/drone/heavydrone)

/datum/gauntletWave/xdrone
	name = "X Drone"
	point_cost = 10
	count = 0.05
	types = list(/obj/critter/gunbot/drone/raildrone)

/datum/gauntletWave/cannondrone
	name = "AR Drone"
	point_cost = 16
	count = 0.05
	types = list(/obj/critter/gunbot/drone/cannondrone)

/datum/gauntletWave/skeleton
	name = "Skeleton"
	point_cost = 3
	count = 5
	types = list(/obj/critter/magiczombie)

/datum/gauntletWave/zombie
	name = "Zombie"
	point_cost = 4
	count = 2
	types = list(/obj/critter/zombie)

/datum/gauntletWave/micromen
	name = "Micro Man"
	point_cost = 3
	count = 0.1
	types = list(/obj/critter/microman)

/datum/gauntletWave/spiderbaby
	name = "Spider Baby"
	point_cost = 5
	count = 3
	types = list(/obj/critter/spider/baby)

/datum/gauntletWave/spidericebaby
	name = "Ice Spider Baby"
	point_cost = 5
	count = 3
	types = list(/obj/critter/spider/ice/baby)

/datum/gauntletWave/spider
	name = "Spider"
	point_cost = 5
	count = 3
	types = list(/obj/critter/spider)

/datum/gauntletWave/spiderice
	name = "Ice Spider"
	point_cost = 5
	count = 3
	types = list(/obj/critter/spider/ice)

/datum/gauntletWave/spiderqueen
	name = "Ice Spider Queen"
	point_cost = 8
	count = 0.05
	types = list(/obj/critter/spider/ice/queen)

/datum/gauntletWave/spacerachnid
	name = "Space Arachnid"
	point_cost = 3
	count = 2
	types = list(/obj/critter/spider/spacerachnid)

/datum/gauntletWave/ohfuckspiders
	name = "OH FUCK SPIDERS"
	point_cost = 8
	count = 7
	types = list(/obj/critter/spider,/obj/critter/spider/baby,/obj/critter/spider/ice,/obj/critter/spider/ice/baby)

/datum/gauntletWave/brullbar
	name = "Brullbar"
	point_cost = 4
	count = 2
	types = list(/obj/critter/brullbar)

/datum/gauntletWave/brullbarking
	name = "Brullbar King"
	point_cost = 6
	count = 0.05
	types = list(/obj/critter/brullbar/king)

/datum/gauntletWave/badbot
	name = "Security Zapbot"
	point_cost = 2
	count = 2
	types = list(/obj/critter/ancient_repairbot/grumpy)

/datum/gauntletWave/fermid
	name = "Fermid"
	point_cost = 3
	count = 3
	types = list(/obj/critter/fermid)

/datum/gauntletWave/lion
	name = "Lion"
	point_cost = 5
	count = 2
	types = list(/obj/critter/lion)

/datum/gauntletWave/maneater
	name = "Man Eater"
	point_cost = 5
	count = 2
	types = list(/obj/critter/maneater)

/datum/gauntletWave/fallback
	name = "Floating Eyes"
	point_cost = 0.01
	count = 10
	types = list(/obj/critter/floateye)

/proc/queryGauntletMatches(data)
	if (islist(data) && data["data_hub_callback"])
		logTheThing(LOG_DEBUG, null, "<b>Marquesas/Gauntlet Query:</b> Invoked (data is [data])")
		for (var/userkey in data["keys"])
			logTheThing(LOG_DEBUG, null, "<b>Marquesas/Gauntlet Query:</b> Got key [userkey].")
			var/matches = data[userkey]
			logTheThing(LOG_DEBUG, null, "<b>Marquesas/Gauntlet Query:</b> Matches for [userkey]: [matches].")
			var/obj/item/card/id/gauntlet/G = locate("gauntlet-id-[userkey]") in world
			if (G && istype(G))
				G.SetMatchCount(text2num(matches))
			else
				logTheThing(LOG_DEBUG, null, "<b>Marquesas/Gauntlet Query:</b> Could not locate ID 'gauntlet-id-[userkey]'.")
				return 1

	else
		var/list/query = list()
		query["key"] = data
		apiHandler.queryAPI("gauntlet/getPrevious", query)
