/// Handles the gauntlet
/datum/controller/process/arena
	var/list/arenas = list()

/datum/controller/process/arena/setup()
	name = "Arena"
	schedule_interval = 0.8 SECONDS

	arenas += gauntlet_controller

/datum/controller/process/arena/copyStateFrom(datum/controller/process/target)
	var/datum/controller/process/arena/old_arena = target
	src.arenas = old_arena.arenas

/datum/controller/process/arena/doWork()
	for (var/datum/arena/A in arenas)
		A.tick()
