local Players = game:GetService("Players")

local PlayerDataService = {}

-- internal cache
local dataByUserId = {}

-- default template for new players
local function defaultData()
	return {
		Currency = {
			Tix = 0,
		},

		Inventory = {},

		Recipes = {"1001"},
		
		Settings = {
			Music = true,
		},
		
		ProgressionFlags = {},
		
		IslandData = {},
		
	}
end

local function deepApplyDefaults(target, defaults)
	-- Ensures every key in defaults exists in target.
	-- Does NOT overwrite existing target values.
	for k, defaultVal in pairs(defaults) do
		local curVal = target[k]

		if curVal == nil then
			-- missing -> copy default
			if type(defaultVal) == "table" then
				local copy = {}
				deepApplyDefaults(copy, defaultVal)
				target[k] = copy
			else
				target[k] = defaultVal
			end

		elseif type(curVal) == "table" and type(defaultVal) == "table" then
			-- both tables -> recurse
			deepApplyDefaults(curVal, defaultVal)
		end
	end

	return target
end


-- called by Main when player joins
function PlayerDataService.LoadPlayer(player, loadedData)
	local defaults = defaultData()
	local data = loadedData or {}

	deepApplyDefaults(data, defaults)

	dataByUserId[player.UserId] = data
end


-- called by Main when player leaves
function PlayerDataService.UnloadPlayer(player)
	dataByUserId[player.UserId] = nil
end

-- read-only access (do NOT mutate directly outside Update)
function PlayerDataService.Get(player)
	return dataByUserId[player.UserId]
end

-- safe mutation entry point
function PlayerDataService.Update(player, mutatorFn)
	local data = dataByUserId[player.UserId]
	if not data then
		warn("PlayerDataService.Update called before data loaded:", player)
		return nil
	end

	mutatorFn(data)
	return data
end

-- convenience getters
function PlayerDataService.GetInventory(player)
	local data = dataByUserId[player.UserId]
	return data and data.Inventory
end

function PlayerDataService.GetCurrency(player)
	local data = dataByUserId[player.UserId]
	return data and data.Currency
end

function PlayerDataService.GetRecipes(player)
	local data = dataByUserId[player.UserId]
	return data and data.UnlockedRecipes
end

return PlayerDataService
