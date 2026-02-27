local InventoryService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Remotes = ReplicatedStorage.Remotes
local DataDelta = Remotes.Data.DataDelta

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)

-- Player quantity of items to a players inventory
function InventoryService.AddItem(player, itemId, quantity)
	quantity = quantity or 1
	itemId = tostring(itemId)

	if not itemId or quantity <= 0 then
		return false
	end

	print("Adding item:", itemId, "Quantity:", quantity, "Previous quantity:", InventoryService.GetItemQuantity(player, itemId), "New quantity:", InventoryService.GetItemQuantity(player, itemId) + quantity)

	PlayerDataService.Update(player, function(data)
		local inventory = data.Inventory
		local current = inventory[itemId]
		inventory[itemId] = (inventory[itemId] or 0) + quantity
		
		-- Send data to client
		DataDelta:FireClient(player, "InventoryItem", {
			itemId = itemId,
			newAmount = inventory[itemId],
			oldAmount = current
		})
	end)

	return true
end

-- Player quantity of items to a players inventory
function InventoryService.RemoveItem(player, itemId, quantity)
	quantity = quantity or 1
	local success = false

	PlayerDataService.Update(player, function(data)
		local inventory = data.Inventory
		local current = inventory[itemId]

		if not current or current < quantity then
			return
		end

		local newAmount = current - quantity
		if newAmount > 0 then
			inventory[itemId] = newAmount
		else
			inventory[itemId] = nil
		end
		
		-- Send data to client
		DataDelta:FireClient(player, "InventoryItem", {
			itemId = itemId,
			newAmount = inventory[itemId],
			oldAmount = current
		})

		success = true
	end)

	return success
end

function InventoryService.GetItemQuantity(player, itemId)
	local inventory = InventoryService.GetInventory(player)
	if not inventory then return 0 end
	return inventory[itemId] or 0
end

-- Return inventory of given player
function InventoryService.GetInventory(player)
	return PlayerDataService.GetInventory(player)
end

return InventoryService
