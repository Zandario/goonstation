
/// Controls railway movement
/datum/controller/process/railway
	var/tmp/list/vehicles

/datum/controller/process/railway/setup()
	name = "Railways"
	schedule_interval = 0.5 SECONDS
	vehicles = global.railway_vehicles

/datum/controller/process/railway/copyStateFrom(datum/controller/process/target)
	var/datum/controller/process/railway/old_railway = target
	src.vehicles = old_railway.vehicles

/datum/controller/process/railway/doWork()
	var/c
	for(var/obj/railway_vehicle/v in global.railway_vehicles)
		v.process()
		if (!(c++ % 10))
			scheck()
