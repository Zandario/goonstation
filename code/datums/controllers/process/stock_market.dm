
var/global/datum/stock/market/stockExchange

/// Handles updating the stock exchange
/datum/controller/process/stock_market

/datum/controller/process/stock_market/setup()
	name = "Stock Market"
	schedule_interval = 1.5 SECONDS
	stockExchange = new

/datum/controller/process/stock_market/doWork()
	if (stockExchange)
		stockExchange.process()
