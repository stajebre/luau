--!nonstrict
--[[ 

Description:

	This modlue handles player data and stock data.
	It is ment to be called by other scripts and has the needed event calls in it.
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
	
	isEmptyTable:
	Checks if table is empty.

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
local RepStrg = game:GetService('ReplicatedStorage')
local formater = RepStrg:WaitForChild('FormatNumber')
local simple = require(formater.Simple)

-----------------------------
-- EVENTS --
-----------------------------

local MoneyEvent = RepStrg:WaitForChild('Money')
local LoadEvent = RepStrg:WaitForChild('load')
local LoadFramesEvent = RepStrg:WaitForChild('RemoteEvent')
local PurchaseEvent = RepStrg:WaitForChild('Purchaserbx')
local InventoryEvent = RepStrg:WaitForChild('inv')
local SellEvent = RepStrg:WaitForChild('sell')
local BuyEvent = RepStrg:WaitForChild('buy')

-----------------------------
-- VARIABLES
-----------------------------

-- Stores all active player data
local data = {} 
-- Stores the curent stock(not per player)
local curentStock = {} 
local lastStockTime = 0 
local DATA_EXAMPLE = { 
	["Money"] = 2000,
	["Inv"] = {},
	["Stock"] = {},
	["LastStockTime"] = nil
}

-----------------------------
-- FUNCTIONS --
-----------------------------

local function isEmptyTable(t)
	return type(t) == "table" and next(t) == nil
end

-- Loading
function m.Load(player: Player)

	LoadEvent:FireClient(player, items)

	local playerName = player.Name
	data[playerName] = m.RealLoad(playerName)
	print(data[playerName])

	if player then
		local leaderstats = Instance.new("Folder")
		leaderstats.Parent = player 
		leaderstats.Name = "leaderstats"

		local moneyInstance = Instance.new("StringValue")
		moneyInstance.Parent = leaderstats
		moneyInstance.Name = "Money"
		moneyInstance.Value = simple.FormatCompact(data[playerName].Money)
		MoneyEvent:FireClient(player, Money.Value, false)

		if not data[playerName].Stock then
			data[playerName].Stock = curentStock
			data[playerName].LastStockTime = curentStock 
		end

		-- fallback if empty or nil
		
		local lastStockTime = if data[playerName].LastStockTime then data[playerName].LastStockTime else nil
		local sec = lastStockTime
		if sec == lastStockTime then
			-- no use for here right now but there could be in the feature
		else
			data[playerName].Stock = curentStock 
		end
		--Checking for player stock
		if not data[playerName].Stock or next(data[playerName].Stock) == nil then
			data[playerName].Stock = curentStock
		end
		-- tell player to load the stock
		LoadFramesEvent:FireClient(player, data[playerName].Stock)
	end
	task.wait(0.1)
	InventoryEvent:FireClient(player, data[playerName].Inv)
end

-- load from datastore function 
function m.RealLoad(playername: string)

	local timesTryed = 0
	-- loads 7 times just to be sure
	while true do
		local sucsess,data = pcall(function()
			return ds:GetAsync(playername)
		end)
		timesTryed += 1
		if sucsess and data then
			return data
		end
		if timesTryed >= 7 then
			return sucsess and data or DATA_EXAMPLE
		end
	end
	task.wait(0.1)
end
-- Save function withoud the dataastore
function m.Save(PlayerName)
	m.RealSave(PlayerName,data[PlayerName])
	print(data[PlayerName])
	-- waits for player to 
	task.wait(0.5)
	data[PlayerName] = nil
end
-- Saves the data to the datastore
function m.RealSave(playerName: string, data)
	-- Basic validation
	if not playerName or type(playerName) ~= "string" or playerName == "" then
		warn("Invalid playerName for save: must be a non-empty string")
		return false 
	end

	if not data then
		warn("Invalid value for save: cannot be nil")
		return false
	end
	-- Settings
	local timesTryed = 0
	local maxRetries = 7
	local baseWait = 0.1
	-- Trys to load player data with the settings above
	while timesTryed < maxRetries do
		local success, err = pcall(function()
			ds:SetAsync(playerName, data)
		end)
		if success then
			print("saved player: " .. playerName) 
			return true
		else
			timesTryed = timesTryed + 1
			warn("Save attempt " .. timesTryed .. " failed for player " .. playerName .. ": " .. tostring(err))
			if timesTryed < maxRetries then
				local waitTime = baseWait * (2 ^ (timesTryed - 1)) 
				task.wait(waitTime)
			end
		end
	end
	warn("Failed to save data for player " .. playerName .. " after " .. maxRetries .. " attempts")
	return false
end

SellEvent.OnServerEvent:Connect(function(player, name) 
	m.sellstock(player, name)
end)
-- if player has the stock gives player the money and removes the stock
function m.sellstock(player, item)
	local playerName = player.Name
	local playerData = data[playerName]
	local playerstock = data[playerName].Stock
	if playerData.Inv[item] and playerData.Inv[item] > 0 then
		m.AddStat(playerName,"Money",items[item].Price *1.5 ) 
		data[playerName].Inv[item] -= 1 
		InventoryEvent:FireClient(player, data[playerName].Inv)
		return true
	else
		return "code_no_item"
	end
end

BuyEvent.OnServerEvent:Connect(function(player, name)
	m.BuyStock(player, name)
end)
--checks if player has the item in stock and then give player the item and takes the money
function m.BuyStock(player: Player,item: string)
	-- player stuff
	local playerName = player.Name
	
	if not data[playerName].Inv[item] then	
		data[playerName].Inv[item] = 0
	end

	local playerName = player.Name
	local playerData = data[playerName] 
	local playerStock = data[playerName].Stock

	if playerData.Money >= items[item].Price then
		if playerStock[item] and playerStock[item] > 0 then
			m.AddStat(playerName,"Money",items[item].Price,true)

			data[playerName].Inv[item] += 1
			data[playerName].Stock[item] -= 1
			LoadFramesEvent:FireClient(player, data[playerName].Stock,"Event")
			InventoryEvent:FireClient(player, data[playerName].Inv)
			return true
		end
	else
		return "code_no_money"
	end
end
-- Player data Related stuff
-- Returns data of the player
function m.GetData(PlayerName: Player, agrs: string)
	if agrs == "all" then 
		return data[PlayerName]
	end	
	print(data[PlayerName])
	return data[PlayerName][agrs]
end
-- Changes player agrs to value
function m.Change(PlayerName: string, agrs: string, value: number)
	data[PlayerName][agrs] = value
	print(data[PlayerName])
end
-- Adds value to player agrs, used to add some item or stat to the player if it didnt exist before
function m.Add(PlayerName: string, agrs: string, value: number)
	table.insert(data[PlayerName][agrs],value)
	print(data[PlayerName])
end
-- Removes value from player agrs
function m.Remove(PlayerName: string,agrs: string,value: number)
	table.remove(data[PlayerName][agrs],table.find(data[PlayerName][agrs],value))
	print(data[PlayerName]) -- prints the data
end 
-- Changes stats to value and also updates the player leaderstats
function m.ChangeStats(PlayerName: string, agrs: string, value: number)
	-- Player stuff
	local player = game.Players:FindFirstChild(PlayerName)
	local playerData = data[PlayerName] 

	if player then
		player.leaderstats[agrs].Value = simple.FormatCompact(data[PlayerName][agrs])
	end
	data[PlayerName][agrs] = value 
	print(data[PlayerName])
end
-- Adds value to player data and leaderstats, formats the leaderstats value too, tells the player if the money changed and by how much
function m.AddStat(PlayerName: string, agrs: string, value: number, negative: BoolValue)

	local player = game.Players:FindFirstChild(PlayerName) 

	if negative then
		data[PlayerName][agrs] -= value
	else
		data[PlayerName][agrs] += value
	end

	if agrs == "money" then
		MoneyEvent:FireClient(player,simple.FormatCompact(data[PlayerName][agrs]),simple.FormatCompact(value),not negative)
	end

	if player then
		player.leaderstats[agrs].Value = simple.FormatCompact(data[PlayerName][agrs]) -- updates the leaderstats
	end

	print(data[PlayerName])
end
-- Updates stock
function m.stockupdate(localStock, lastTime: number)
	-- Updates the stock variables
	warn(localStock)
	curentStock = localStock
	lastStockTime = lastTime
	-- Updatest he stock to each player
	for _, player in pairs(game.Players:GetChildren()) do
		if data[player.Name] and next(data[player.Name]) ~= nil then
			data[player.Name].Stock = localStock
			data[player.Name].LastStockTime = lastTime
			LoadFramesEvent:FireClient(player, localStock) 
			print(1412515)
		end
	end
end

return m