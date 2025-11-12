-- Hello! I don't want to leak much of the code but u can have this, if ur not from hiddendevs aplication then what u doing here?
-- Hope this is enough(it wasnt last time) so i added coments everywhere where i felt its needed
-- This is to application reader and is not in the real code
local m = {}
local loader = require(script.Parent.Loader) -- loader
local simple = require(game.ReplicatedStorage.FormatNumber.Simple) -- formater(simple)
local items = require(script.Parent.itmes) -- items module, stores information about all the items
local moneyevent = game.ReplicatedStorage.Money -- money event
local loadevent = game.ReplicatedStorage.load --  loadevent, used to load inventory
local loadframes = game.ReplicatedStorage.RemoteEvent -- load frames event, used to give the client data about the items on joining
--local htp = game.HttpService -- gets http service, was used before
local purchase = game.ReplicatedStorage.Purchaserbx -- purcase events
local inve = game.ReplicatedStorage.inv -- inventory event, tells client their inventory
local sell = game.ReplicatedStorage.sell -- sell event, client tells server they want to sell smth
local buy = game.ReplicatedStorage.buy -- buy event, tells client server they want to buy smth
local data = {} -- the data table, stores data for all players that are curently playing
local cstock = {} -- the curent stock(not per player)
local laststock = 0 -- last stock time
local ds = game:GetService("DataStoreService"):GetDataStore("main")
local dataexample = { -- just to know the data structure
	["Money"] = 2000,
	["Inv"] = {}
}
function m.Load(ply :Player) -- loads the player
	loadevent:FireClient(ply,items) -- tells player to load the items in the ui
	local playerName = ply.Name
	local playerData = m.RealLoad(playerName) -- loads the data
	data[playerName] = playerData -- gives the data to the data table
	if ply then
		local ls = Instance.new("Folder", ply) -- following lines create leaderstats
		ls.Name = "leaderstats"

		local Money = Instance.new("StringValue", ls)
		Money.Name = "Money"
		Money.Value = simple.FormatCompact(playerData.Money)
		moneyevent:FireClient(ply,Money.Value,false) -- tells player to update the money value, false meants that change didnt happen and the change meaning that the player bought or sold something
		
		local plystock = playerData.Stock -- gets player stock
		if not plystock then -- checks for the stock if none updates it
			plystock = cstock -- updates curent stock time
			playerData.LastStockTime = cstock -- updates curent stock time
		end
		local lst = if playerData.LastStockTime then playerData.LastStockTime else nil -- gets the stock time
		local sec = laststock -- updates curent stock time
		if sec == lst then
			-- no use for here right now but there could be in the feature
		else
			while true do
				if cstock ~= {} then break end
				task.wait(0.1)
			end
			data[playerName].Stock = cstock -- updates the player stock
		end
		if data[playerName].Stock == {} or data[playerName].Stock == nil then
			while true do
				if cstock ~= {} and cstock ~= nil then break end -- just wawit time till the stock doesnt exist
				task.wait(0.1)
			end
			data[playerName].Stock = cstock -- updates the player stock
		end
		loadframes:FireClient(ply,data[playerName].Stock) -- tells player to load the stock
	end
	task.wait(2) -- waits just to be sure
	inve:FireClient(ply,playerData.Inv) -- tells player to load their inv
end
function m.sellstock(ply,item) -- checks if player has the item(stock) and then gives player the money and removes one item from it
	local playerName = ply.Name
	local plydata = data[playerName] -- Gets player data
	local plystock = data[playerName].Stock
	if plydata.Inv[item] and plydata.Inv[item] > 0 then -- checks if player has the item and if it has more than 0
		m.AddStat(playerName,"Money",items[item].Price *1.5 ) --tells the module to add money to the player
		data[playerName].Inv[item] -= 1 -- removes one item from the player stock
		inve:FireClient(ply,data[playerName].Inv) -- tels the client their inventory
		return true -- tells that it happened, no use right now but if client needs to know if it happened it could be tied to a remotefunction insted of remote event
	else
		return "code_no_item" --tells that it happened, no use right now but if client needs to know if it happened it could be tied to a remotefunction insted of remote event
	end
end
sell.OnServerEvent:Connect(function(ply,name) --When sell event fired runs sellstock function, that checks if player has the stock and then gives player the money
	m.sellstock(ply,name)
end)
buy.OnServerEvent:Connect(function(ply,name)--When buy event fired runs buystock function, that checks if player has the item in stock and then give player the item and takes the money
	m.BuyStock(ply,name)
end)
function m.BuyStock(ply :Player,item :string) --checks if player has the item in stock and then give player the item and takes the money
	local playerName = ply.Name
	local plydata = data[playerName] -- gets player data
	local plystock = data[playerName].Stock -- gets player stock
	if plydata.Money >= items[item].Price then --checks if player has enough money
		if plystock[item] and plystock[item] > 0 then -- checks if the item is in stock and if it has more than 0
			m.AddStat(playerName,"Money",items[item].Price,true) --tells the module to take money from the player
			if not data[playerName].Inv[item] then -- runs check just to be sure
				data[playerName].Inv[item] = 0 -- if it does not have the item in inv then it adds it
			end
			data[playerName].Inv[item] += 1 -- adds one item to the player stock
			data[playerName].Stock[item] -= 1 -- takes one of the item from the stock
			loadframes:FireClient(ply,data[playerName].Stock,"buy") -- tells client new stock and the buy is just for the client to know that its not a stock restock but a buy
			inve:FireClient(ply,data[playerName].Inv) -- tels the client their inventory
			return true -- tells that it happened, no use right now but if client needs to know if it happened it could be tied to a remotefunction insted of remote event
		end
	else
		return "code_no_money" --tells that it happened, no use right now but if client needs to know if it happened it could be tied to a remotefunction insted of remote event
	end
end
function m.Change(PlayerName :string,agrs :string,value :number) -- changes player agrs to value
	data[PlayerName][agrs] = value
	print(data[PlayerName]) -- prints the data
end
function m.Add(PlayerName :string,agrs :string,value :number) -- adds value to player agrs, used to add some item or stat to the player if it didnt exist before
	table.insert(data[PlayerName][agrs],value)
	print(data[PlayerName]) -- prints the data
end
function m.Remove(PlayerName :string,agrs :string,value :number) -- removes value from player agrs
	table.remove(data[PlayerName][agrs],table.find(data[PlayerName][agrs],value))
	print(data[PlayerName]) -- prints the data
end
function m.ChangeStats(PlayerName :string,agrs :string,value :number) -- changes stats to value and also updates the player leaderstats
	local ply = game.Players:FindFirstChild(PlayerName)
	if ply then
		ply.leaderstats[agrs].Value = simple.FormatCompact(data[PlayerName][agrs]) -- formats the stats so that its a string saying like 10k instead of 10000
	end
	data[PlayerName][agrs] = value -- changes the data of the player
	print(data[PlayerName]) -- prints the data
end
function m.AddStat(PlayerName :string,agrs :string,value :number,negative :BoolValue)
	local ply = game.Players:FindFirstChild(PlayerName) -- gets the player
	if negative then --checsk if its negative or positive
		data[PlayerName][agrs] -= value -- removes value from the stats
	else
		data[PlayerName][agrs] += value -- adds value to the stats
	end
	moneyevent:FireClient(ply,simple.FormatCompact(data[PlayerName][agrs]),simple.FormatCompact(value),not negative) -- tells client that the stats changed and also tells client by how much it changed, negative tells client if its taken or given
	if ply then
		ply.leaderstats[agrs].Value = simple.FormatCompact(data[PlayerName][agrs]) -- updates the leaderstats
	end
	print(data[PlayerName]) -- prints the data
end
function m.stockupdate(stck,lasttime :number) -- updates stock
	warn(stck) -- warns the stock for testing purposes
	cstock = stck -- updats the stock
	laststock = laststock -- updates the latest stock time
	for _, ply in pairs(game.Players:GetChildren()) do -- for every player, tell them the stock has updated
		spawn(function() -- spawns function so that if there is delay it can go to the next player without wwaiting
		loadframes:FireClient(ply,stck) -- tell the player new stock
		if data[ply.Name] ~= {} and data[ply.Name] ~= nil and data[ply.Name] then task.wait(2) end -- checks for data just to be sure
		data[ply.Name].Stock = stck -- updates the stock
		data[ply.Name].LastStockTime = lasttime -- stores the last stock update time
		end)
	end
end
function m.GetData(PlayerName :Player,agrs :string)
	if agrs == "all" then -- if all is given then return all data
		return data[PlayerName]
	end	print(data[PlayerName])-- prints the data just for testing
	return data[PlayerName][agrs] -- returns the data requested
end
function m.Save(PlayerName) -- saves the data
	loader.Save(PlayerName,data[PlayerName]) -- tells loader to save
	print(data[PlayerName]) -- pritns whats saved just for testing
	task.wait() -- wwaits
	task.wait(0.5) -- waits again(dont ask me why 2 times)
	data[PlayerName] = nil -- removes the data
end
return m

-- Loading/saving
function m.RealLoad(playername :string) -- load
	local n = 0
	while true do -- like for loob but works better than for loop learned this in c++, loads the data 7 times on succses returns the data if it didnt load in thoos 7 trys then returns dataexample
	local sucsess,data = pcall(function()
		return ds:GetAsync(playername) -- trys to load
	end)
	n += 1 -- updates n
	if sucsess and data then
		return data -- returns data if loaded
	end
	if n >= 7 then -- checks if it loaded 7 times or more
		return sucsess and data or dataexample -- if its not loaded returns data examople
	end
	end
	task.wait(0.1)
end

function m.RealSave(player :string, data)
	-- Basic validation
	if not playerName or type(playerName) ~= "string" or playerName == "" then -- makes sure that player name is string
		warn("Invalid playerName for save: must be a non-empty string")
		return false -- tells that it didnt load, could be useful for debugging
	end
	if not value then -- checks for value
		warn("Invalid value for save: cannot be nil")
		return false -- tells that it didnt load, could be useful for debugging
	end
	local n = 0
	local maxRetries = 7
	local baseWait = 0.1  -- Starting wait time
	while n < maxRetries do
		local success, err = pcall(function()
			ds:SetAsync(playerName, value)
		end)

		if success then
			print("saved player: " .. playerName)  -- Optional success log
			return true -- tells that it loaded, could be useful for debugging
		else
			n = n + 1
			warn("Save attempt " .. n .. " failed for player " .. playerName .. ": " .. tostring(err))
			if n < maxRetries then
				local waitTime = baseWait * (2 ^ (n - 1))  -- Exponential backoff: 0.1, 0.2, 0.4, 0.8, 1.6, 3.2, 6.4s
				task.wait(waitTime)
			end
		end
	end
	warn("Failed to save data for player " .. playerName .. " after " .. maxRetries .. " attempts")
	return false -- tells that it didnt load, could be useful for debugging
end