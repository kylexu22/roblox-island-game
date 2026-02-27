local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Dialogs = require(ReplicatedStorage:WaitForChild("Dialogs"))
local ChooseChoice = ReplicatedStorage.Remotes.Dialog:WaitForChild("ChooseChoice")

-- TODO: plug your real services here
local InventoryService = require(game.ServerScriptService.Services:WaitForChild("InventoryService"))

local function hasItems(player, itemsReq)
	local inv = InventoryService.GetInventory(player) -- should return table keyed by string or number consistently
	if not inv then return false end

	for itemId, amount in pairs(itemsReq or {}) do
		local have = inv[itemId] or inv[tostring(itemId)] or 0
		if have < amount then return false end
	end
	return true
end

local function runActions(player, actions)
	for _, action in ipairs(actions or {}) do
		if action.Type == "CraftRecipe" then
			-- CraftRecipe should do all checks/removals server-side
			--RecipeService.Craft(player, action.RecipeId)
		elseif action.Type == "GiveItem" then
			InventoryService.AddItem(player, action.ItemId, action.Amount or 1)
		end
	end
end

ChooseChoice.OnServerInvoke = function(player, dialogId, nodeId, choiceIndex)
	local dialog = Dialogs[dialogId]
	if not dialog then return false, "BadDialog" end

	local node = dialog.Nodes[nodeId]
	if not node then return false, "BadNode" end

	local choice

	-- Case 1: Normal choice node
	if node.Choices and choiceIndex and choiceIndex > 0 then
		choice = node.Choices[choiceIndex]

		-- Case 2: No-choice node (monologue / continue)
	elseif choiceIndex == 0 and node.Next then
		choice = { Next = node.Next }

	else
		return false, "BadChoice"
	end


	-- validate requirements
	if choice.Requirements and choice.Requirements.Items then
		if not hasItems(player, choice.Requirements.Items) then
			return false, "MissingItems"
		end
	end

	-- run actions (server authoritative)
	if choice.Actions then
		runActions(player, choice.Actions)
	end

	-- decide next
	if choice.End then
		return true, { End = true }
	end

	local nextId = choice.Next
	if not nextId or not dialog.Nodes[nextId] then
		return false, "BadNext"
	end

	return true, { Next = nextId }
end
