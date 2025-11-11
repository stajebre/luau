-- Hello! I don't want to leak much of the code but u can have this, if ur not from hiddendevs aplication then what u doing here?
-- Hope this is enough

local m = {}

local loader = require(script.Parent.Loader)
local simple = require(game.ReplicatedStorage.FormatNumber.Simple)
local items = require(script.Parent.itmes)
local moneyevent = game.ReplicatedStorage.Money
local loadevent = game.ReplicatedStorage.load
local loadframes = game.ReplicatedStorage.RemoteEvent
local htp = game.HttpService
local purchase = game.ReplicatedStorage.Purchaserbx
local inve = game.ReplicatedStorage.inv
local sell = game.ReplicatedStorage.sell

local buy = game.ReplicatedStorage.buy
buy.OnServerEvent:Connect(function(ply,name)
	m.BuyStock(ply,name)
end)

local data = {}
local cstock = {}
local laststock = 0

function m.Load(ply,cstock)
	loadevent:FireClient(ply,items)
	local playerName = ply.Name
	local playerData = loader.Load(playerName)
	data[playerName] = playerData

	if ply then
		local ls = Instance.new("Folder", ply)
		ls.Name = "leaderstats"

		local Money = Instance.new("StringValue", ls)
		Money.Name = "Money"
		Money.Value = simple.FormatCompact(playerData.Money)
		moneyevent:FireClient(ply,Money.Value,false)
		
		local plystock = playerData.Stock
		if not plystock then
			plystock = cstock
			playerData.LastStockTime = cstock
		end
		local lst = if playerData.LastStockTime then plystock.LastStockTime else nil
		local sec = laststock
		if sec == lst then
			
		else
			while true do
				if cstock ~= {} then break end
				task.wait(0.1)
			end
			data[playerName].Stock = cstock
		end
		if data[playerName].Stock == {} or data[playerName].Stock == nil then
			while true do
				if cstock ~= {} and cstock ~= nil then break end
				print(1311621652312165)
				task.wait(0.1)
			end
			data[playerName].Stock = cstock
		end
		loadframes:FireClient(ply,data[playerName].Stock)
	end
	task.wait(2)
	inve:FireClient(ply,playerData.Inv)
end

function m.sellstock(ply,item)
	local playerName = ply.Name
	local plydata = data[playerName]
	local plystock = data[playerName].Stock
	if plydata.Inv[item] and plydata.Inv[item] > 0 then
		m.AddStat(playerName,"Money",items[item].Price *1.5 )
		data[playerName].Inv[item] -= 1
		inve:FireClient(ply,data[playerName].Inv)
		return true
	else
		return "code_no_item"
	end
end

sell.OnServerEvent:Connect(function(ply,name)
	m.sellstock(ply,name)
end)

function m.BuyStock(ply,item)
	local playerName = ply.Name
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
			loadframes:FireClient(ply,data[playerName].Stock,"buy")
			inve:FireClient(ply,data[playerName].Inv)
			return true
		end
	else
		return "code_no_money"
	end
end

function m.Change(PlayerName,agrs,value)
	data[PlayerName][agrs] = value
	print(data[PlayerName])
end

function m.Add(PlayerName,agrs,value)
	table.insert(data[PlayerName][agrs],value)
	print(data[PlayerName])
end

function m.Remove(PlayerName,agrs,value)
	table.remove(data[PlayerName][agrs],table.find(data[PlayerName][agrs],value))
	print(data[PlayerName])
end

function m.ChangeStats(PlayerName,agrs,value)
	local ply = game.Players:FindFirstChild(PlayerName)
	if ply then
		ply.leaderstats[agrs].Value = simple.FormatCompact(data[PlayerName][agrs])
	end
	data[PlayerName][agrs] = value
	print(data[PlayerName])
end

function m.AddStat(PlayerName,agrs,value,negative)
	local ply = game.Players:FindFirstChild(PlayerName)
	if negative then
		data[PlayerName][agrs] -= value
	else
	data[PlayerName][agrs] += value
	end
	moneyevent:FireClient(ply,simple.FormatCompact(data[PlayerName][agrs]),simple.FormatCompact(value),not negative)
	if ply then
		ply.leaderstats[agrs].Value = simple.FormatCompact(data[PlayerName][agrs])
	end
	print(data[PlayerName])
end

function m.stockupdate(stck,lasttime)
	warn(stck)
	cstock = stck
	laststock = laststock
	for _, ply in pairs(game.Players:GetChildren()) do
		loadframes:FireClient(ply,stck)
		if data[ply.Name] ~= {} and data[ply.Name] ~= nil and data[ply.Name] then task.wait(1) end
		data[ply.Name].Stock = stck
		data[ply.Name].LastStockTime = lasttime
	end
end

function m.GetData(PlayerName,agrs)
	if agrs == "all" then
		return data[PlayerName]
	end	print(data[PlayerName])
	return data[PlayerName][agrs]
end

function m.Save(PlayerName)
	loader.Save(PlayerName,data[PlayerName])
	print(data[PlayerName])
	task.wait()
	task.wait(0.5)
	data[PlayerName] = nil
end

return m