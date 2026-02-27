local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InventoryService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("InventoryService"))
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local Recipes = require(ReplicatedStorage:WaitForChild("Recipes"))

local CraftingService = {}

function CraftingService.GetRecipes(player)
	print(PlayerDataService.GetRecipes(player))
	return PlayerDataService.GetRecipes(player)
end

function CraftingService.AddNewRecipe(player, recipeId)
	PlayerDataService.Update(player, function(data)
		local playerRecipes = data.Recipes
		playerRecipes[recipeId] = true
	end)
end

function CraftingService.CheckIfPlayerHasRecipe(player, recipeId)
	local playerRecipes = CraftingService.GetRecipes(player)
	return playerRecipes[recipeId] ~= nil
end


function CraftingService.CraftItem(player, recipeId)
	recipeId = tostring(recipeId)
	local playerInventory = InventoryService.GetInventory(player)
	local recipe = Recipes[recipeId]
	if not recipe then return "Recipe does not exist" end
	
	if not CraftingService.CheckIfPlayerHasRecipe(player, recipeId) then return "player does not have recipe" end

	for itemId, quantity in pairs(recipe.Ingredients) do
		if playerInventory[itemId] == nil or playerInventory[itemId] < quantity then
			print(itemId, playerInventory, playerInventory[itemId])
			return "Not enough materials needed"
		end
	end

	for itemId, quantity in pairs(recipe.Ingredients) do
		InventoryService.RemoveItem(player, itemId, quantity)
	end
	
	InventoryService.AddItem(player, recipe.Output.itemId, recipe.Output.quantity)
	
	return true
end

return CraftingService
