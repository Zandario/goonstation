
/// Handles chemistry reactions
/datum/controller/process/chemistry

/datum/controller/process/chemistry/setup()
	name = "Chemistry"
	schedule_interval = 1 SECOND

/datum/controller/process/chemistry/doWork()
	for(var/datum/d in active_reagent_holders)
		d:process_reactions()
		scheck()
