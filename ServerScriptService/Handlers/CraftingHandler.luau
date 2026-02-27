local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CraftingService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("CraftingService"))
local Recipes = require(ReplicatedStorage:WaitForChild("Recipes"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local craftRemoteFunction = remotes:WaitForChild("Craft")

remotes:WaitForChild("Craft").OnServerInvoke = function(player, recipeId)
	return CraftingService.CraftItem(player, recipeId)
end
