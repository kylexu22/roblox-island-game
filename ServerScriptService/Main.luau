local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local database = DataStoreService:GetDataStore("data")
local SERVICES = ServerScriptService.Services
local HANDLERS = ServerScriptService.Handlers
local REMOTES = ReplicatedStorage.Remotes

-- Require Services
local PlayerDataService = require(SERVICES.PlayerDataService)
local InventoryService = require(SERVICES.InventoryService)
local CurrencyService = require(SERVICES.CurrencyService)
local CraftingService = require(SERVICES.CraftingService)

-- Remotes
local DataSnapshot = REMOTES.Data.DataSnapshot

-- Player states
local playerStates = {}

local DEFAULT_PLAYER_STATE = {
	
}

local function makeClientView(data)
	-- IMPORTANT: only send what UI needs
	return {
		Currency = { Tix = data.Currency.Tix },
		Inventory = data.Inventory,
	}
end


function playerJoining(player)
	print(player.Name .. " has joined the game.")
	local playerDataStore = getDataStoreData(player)
	PlayerDataService.LoadPlayer(player, playerDataStore)
	
	-- Send Initial data to player
	DataSnapshot:FireClient(player, makeClientView(PlayerDataService.Get(player)))
end

function getDataStoreData(player)
	local success = nil
	local playerData = nil
	local attempt = 1

	repeat 
		success, playerData = pcall(function()
			return database:GetAsync(player.UserId)
		end)

		attempt += 1

		if not success then
			warn(playerData)
			task.wait(3)
		end
	until success or attempt >= 5

	if success then
		print("Connected to database")	
		return playerData
		
	end
end

function playerLeaving(player)
	handleSavingData(player)
	PlayerDataService.UnloadPlayer(player)
	print(player.Name .. " is leaving the game.")
end

-- Handles saving players data
function handleSavingData(player)
	local data = PlayerDataService.Get(player)
	
	local success = nil
	local errorMsg = nil
	local attempt = 1
	

	repeat 
		success, errorMsg = pcall(function()
			database:SetAsync(player.UserId, data)
		end)
		
		attempt += 1
		
		if not success then
			warn(errorMsg)
			task.wait(3)
		end
	until success or attempt >= 5
	
	if success then 
		print(player.Name, "'s data has been saved")
	else
		warn("Could not save data for " .. player.Name)
	end
end



game.Players.PlayerAdded:Connect(playerJoining)
game.Players.PlayerRemoving:Connect(playerLeaving)

REMOTES.Testing.SaveData.OnServerEvent:Connect(function(player)
	handleSavingData(player)
end)

-- Other Game Logic

