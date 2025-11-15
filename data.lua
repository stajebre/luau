--!nonstrict
--[[ 

Description:

	This code handles player data and stock data.
	Is ment to be called by other scripts and has the needed event calls in it.
	The idea: Use tables to store data insted of instances.
	Note: Some functions have returns that go to nowhere, this is so if in the feautre if it needs to know if it failed or it didnt and for what reason, its an option that has a tought for thoos who will be adding on the script.

	DOCUMENTATION:

	m.Load:
	Sets up player data that it gets from m.RealLoad.

	m.RealLoad:
	Gets data from the datastore, trys more times just to be sure.

	m.Save:
	Calls m.RealSave function and removes the player data from the table afterwards.

	m.RealSave:
	Saves data and trys a few times to save it just in case

	m.sellstock:
	Sells player stock by removing one stock(only if the player has it) in the inventory and awaring the money.

	m.BuyStock:
	Buys player stuck by adding one stock of the player and removing the money, also checks if it can do that like if there is stock of the item and if the player has money.
	
	m.GetData
	Returns player data of the agrs, if agrs is all returns all the data.

	m.Change:
	changes agrs player data of the player to a value.

	m.Add:
	Inserts value to the agrs of player data.

	m.Remove:
	Removes value from player agrs table.

	m.ChgeStats:
	Changes value player data of the player to a agrs(money,rebirth,killcounter,level what ever), changes the learderstats value to formated version of the value.

	m.AddStat:
	Adds agrs player data of the player to a value, changes the learderstats value to formated version of the value. Negative is for if to add or remove.

	m.stockupdate:
	Updates stock per player, updates the current stock.

]]
local m = {}

-----------------------------
-- SERVICES --
-----------------------------

local ds = game:GetService("DataStoreService"):GetDataStore("main")

-----------------------------
-- MODULES  --
-----------------------------

local Modules = script.Parent
local loader = require(Modules.Loader)
local items = require(Modules.itmes)
local RepStrg = game:GetService("ReplicatedStorage")
local formater = RepStrg.FormatNumber
local simple = require(formater.Simple)

-----------------------------
-- EVENTS --
-----------------------------

local moneyevent = RepStrg.Money
local loadevent = RepStrg.load
local loadframes = RepStrg.RemoteEvent
local purchase = RepStrg.Purchaserbx
local inve = RepStrg.inv
local sell = RepStrg.sell
local buy = RepStrg.buy

-----------------------------
-- VARIABLES
-----------------------------

local data = {} 
-- the curent stock(not per player)
local cstock = {} 
local laststock = 0 
local dataexample = { 
	["Money"] = 2000,
	["Inv"] = {},
	["Stock"] = {},
	["LastStockTime"] = nil
}

-----------------------------
 -- FUNCTIONS --
-----------------------------

-- loading
function m.Load(player: Player)

	loadevent:FireClient(player, items)

	local playerName = player.Name
	local playerData = m.RealLoad(playerName)
	data[playerName] = playerData

	if player then
		local leaderstats = Instance.new("Folder")
		leaderstats.Parent = player 
		leaderstats.Name = "leaderstats"

		local Money = Instance.new("StringValue")
		money.Parent = leaderstats
		Money.Name = "Money"
		Money.Value = simple.FormatCompact(playerData.Money)
		moneyevent:FireClient(player,Money.Value,false)
		
		local plystock = playerData.Stock
		if not plystock then

			plystock = cstock
			playerData.LastStockTime = cstock 

		end
		local last_stock_time = if playerData.LastStockTime then playerData.LastStockTime else nil
		local sec = laststock 
		if sec == last_stock_time then
			-- no use for here right now but there could be in the feature
		else
			data[playerName].Stock = cstock 
		end
		-- checking for player stock
		if data[playerName].Stock == {} or data[playerName].Stock == nil then
			data[playerName].Stock = cstock
		end
		-- tell player to load the stock
		loadframes:FireClient(player, data[playerName].Stock) 
	end
	-- waits just in case and then tells player to load their inv
	task.wait(0.1)
	inve:FireClient(player, playerData.Inv)
end

-- load from datastore function 
function m.RealLoad(playername: string)

	local n = 0
	-- loads 7 times just to be sure
	while true do
		local sucsess,data = pcall(function()
			return ds:GetAsync(playername)
		end)
		n += 1
		if sucsess and data then
			return data
		end
		if n >= 7 then
			return sucsess and data or dataexample
		end
	end
	task.wait(0.1)
end
-- save function withoud the dataastore
function m.Save(PlayerName)
	m.RealSave(PlayerName,data[PlayerName])
	print(data[PlayerName])
	-- waits for player to 
	task.wait(0.5)
	data[PlayerName] = nil
end
-- saves the data to the datastore
function m.RealSave(playerName: string, data)
	-- Basic validation
	if not playerName or type(playerName) ~= "string" or playerName == "" then
		warn("Invalid playerName for save: must be a non-empty string")
		return false 
	end

	if not value then
		warn("Invalid value for save: cannot be nil")
		return false
	end
	-- settings
	local n = 0
	local maxRetries = 7
	local baseWait = 0.1
	-- trys to load player data with the settings above
	while n < maxRetries do
		local success, err = pcall(function()
			ds:SetAsync(playerName, value)
		end)
		if success then
			print("saved player: " .. playerName) 
			return true
		else
			n = n + 1
			warn("Save attempt " .. n .. " failed for player " .. playerName .. ": " .. tostring(err))
			if n < maxRetries then
				local waitTime = baseWait * (2 ^ (n - 1)) 
				task.wait(waitTime)
			end
		end
	end
	warn("Failed to save data for player " .. playerName .. " after " .. maxRetries .. " attempts")
	return false
end

sell.OnServerEvent:Connect(function(player, name) 
	m.sellstock(player, name)
end)
-- if player has the stock gives player the money and removes the stock
function m.sellstock(player, item)
	local playerName = player.Name
	local plydata = data[playerName]
	local plystock = data[playerName].Stock
	if plydata.Inv[item] and plydata.Inv[item] > 0 then
		m.AddStat(playerName,"Money",items[item].Price *1.5 ) 
		data[playerName].Inv[item] -= 1 
		inve:FireClient(player,data[playerName].Inv)
		return true
	else
		return "code_no_item"
	end
end

buy.OnServerEvent:Connect(function(player, name)
	m.BuyStock(player, name)
end)
--checks if player has the item in stock and then give player the item and takes the money
function m.BuyStock(player: Player,item: string)
	-- player stuff
	local playerName = player.Name
	local plydata = data[playerName] 
	local plystock = data[playerName].Stock

	if plydata.Money >= items[item].Price then
		if plystock[item] and plystock[item] > 0 then
			m.AddStat(playerName,"Money",items[item].Price,true)
			if not data[playerName].Inv[item] then
				data[playerName].Inv[item] = 0
			end
			data[playerName].Inv[item] += 1
			data[playerName].Stock[item] -= 1
			loadframes:FireClient(player,data[playerName].Stock,"buy")
			inve:FireClient(player,data[playerName].Inv)
			return true
		end
	else
		return "code_no_money"
	end
end
-- Player data Related stuff
-- returns data of the player
function m.GetData(PlayerName: Player, agrs: string)
	if agrs == "all" then 
		return data[PlayerName]
	end	
	print(data[PlayerName])
	return data[PlayerName][agrs]
end
 -- changes player agrs to value
function m.Change(PlayerName: string, agrs: string, value: number)
	data[PlayerName][agrs] = value
	print(data[PlayerName])
end
 -- adds value to player agrs, used to add some item or stat to the player if it didnt exist before
function m.Add(PlayerName: string, agrs: string, value: number)
	table.insert(data[PlayerName][agrs],value)
	print(data[PlayerName])
end
-- removes value from player agrs
function m.Remove(PlayerName: string,agrs: string,value: number)
	table.remove(data[PlayerName][agrs],table.find(data[PlayerName][agrs],value))
	print(data[PlayerName]) -- prints the data
end 
-- changes stats to value and also updates the player leaderstats
function m.ChangeStats(PlayerName: string, agrs: string, value: number)
	-- player stuff
	local player = game.Players:FindFirstChild(PlayerName)
	local plydata = data[playerName] 

	if player then
		player.leaderstats[agrs].Value = simple.FormatCompact(data[PlayerName][agrs])
	end
	data[PlayerName][agrs] = value 
	print(data[PlayerName])
end
-- adds value to player data and leaderstats, formats the leaderstats value too, tells the player if the money changed and by how much
function m.AddStat(PlayerName: string, agrs: string, value: number, negative: BoolValue)

	local player = game.Players:FindFirstChild(PlayerName) 

	if negative then
		data[PlayerName][agrs] -= value
	else
		data[PlayerName][agrs] += value
	end

	if agrs == "money" then
	moneyevent:FireClient(player,simple.FormatCompact(data[PlayerName][agrs]),simple.FormatCompact(value),not negative)
	end

	if player then
		player.leaderstats[agrs].Value = simple.FormatCompact(data[PlayerName][agrs]) -- updates the leaderstats
	end

	print(data[PlayerName])
end
 -- updates stock
function m.stockupdate(stck, lasttime: number)
	-- updates the stock variables
	warn(stck)
	cstock = stck
	laststock = laststock
	-- updatest he stock to each player
	for _, player in pairs(game.Players:GetChildren()) do
		-- spawn function so that it doesnt make the others wait while waiting for player data to loaad
		spawn(function() 
			if data[player.Name] ~= {} and data[player.Name] ~= nil and data[player.Name] then
				task.wait(2) 
			end
			data[player.Name].Stock = stck
			data[player.Name].LastStockTime = lasttime
			loadframes:FireClient(player,stck) 
		end)
	end
end

return m