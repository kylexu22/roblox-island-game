local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local ToolService = require(ServerScriptService.Services.ToolService)
local InventoryService = require(ServerScriptService.Services.InventoryService)
local TreeChopService = require(ServerScriptService.Services.TreeChopService)
--local TreeService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("TreeService"))
local Items = require(ReplicatedStorage:WaitForChild("Items"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")


Remotes.Tools:WaitForChild("ToggleTool").OnServerEvent:Connect(function(player, itemId)
	
	local character = player.Character
	if not character then return end
	
	if InventoryService.GetItemQuantity(player, itemId) <= 0 then return end
	
	local toolId = Items[itemId].ToolId
	if toolId == nil then return end
	
	if character:FindFirstChildWhichIsA("Tool") then
		ToolService.RemoveTool(player)
	else
		ToolService.GiveTool(player, toolId)
	end
end)


--[[local function playerRequestTreeChop(player, treeModel)
	TreeChopService.RequestChop(player, treeModel)
end]]

Remotes.Tools.ChopTree.OnServerEvent:Connect(function(player, treeModel)
	TreeChopService.RequestChop(player, treeModel)
end)
