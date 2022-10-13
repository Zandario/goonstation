/datum/controller/process/precipitation
	var/tmp/list/datum/precipitation_controller/controllers
	var/tmp/ticker = 0

/datum/controller/process/precipitation/setup()
	name = "Precipitation"
	schedule_interval = 6 SECONDS

/datum/controller/process/precipitation/copyStateFrom(datum/controller/process/target)
	var/datum/controller/process/precipitation/old_process = target
	src.controllers = old_process.controllers
	src.ticker = old_process.ticker

/datum/controller/process/precipitation/doWork()
	for_by_tcl(PC, /datum/precipitation_controller)
		if(PC.reagents.total_volume && length(PC.effects))
			PC.process()
	ticker++
