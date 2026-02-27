local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataSnapshot = Remotes:WaitForChild("Data"):WaitForChild("DataSnapshot")
local DataDelta = Remotes:WaitForChild("Data"):WaitForChild("DataDelta")

local Events = game.Players.LocalPlayer.PlayerScripts:WaitForChild("Events")
local InventoryChanged = Events:WaitForChild("InventoryChanged")
local CurrencyChanged = Events:WaitForChild("CurrencyChanged")

local clientCache = {}

DataSnapshot.OnClientEvent:Connect(function(snapshot)
	clientCache = snapshot
	InventoryChanged:Fire(clientCache.Inventory)
	CurrencyChanged:Fire(clientCache.Currency)
end)

DataDelta.OnClientEvent:Connect(function(kind, payload)
	if kind == "InventoryItem" then
		clientCache.Inventory[payload.itemId] = payload.newAmount
		InventoryChanged:Fire(clientCache.Inventory, payload)
	elseif kind == "Currency" then
		clientCache.Currency = payload
		CurrencyChanged:Fire(clientCache.Currency)
	end
end)
