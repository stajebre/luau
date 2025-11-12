-- Hello! I don't want to leak much of the code but u can have this, if ur not from hiddendevs aplication then what u doing here?
-- is this enough comments
-- if ur reading this first check out data.lua too
local m = {}
local ds = game:GetService("DataStoreService"):GetDataStore("main")
local dataexample = { -- just to know the data structure
	["Money"] = 2000,
	["Inv"] = {}
}
local function load(playername :string) -- loading the player
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
function m.Load(playername :string)
	local data = load(playername)
	return data
end
function m.Save(playerName :string, value) -- function to save data
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
return m