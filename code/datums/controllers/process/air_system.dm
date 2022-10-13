
/// handles air processing.
/datum/controller/process/air_system

/datum/controller/process/air_system/setup()
	name = "Atmos"
	schedule_interval = 2 SECONDS

	if(!air_master)
		air_master = new /datum/controller/air_system()
		air_master.setup(src)
	air_master.parent_controller = src

/datum/controller/process/air_system/doWork()
	air_master.process()

/datum/controller/process/air_system/copyStateFrom(datum/controller/process/target)
	air_master.parent_controller = src
