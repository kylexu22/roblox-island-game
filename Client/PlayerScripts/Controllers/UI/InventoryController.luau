local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Items = require(ReplicatedStorage.Items)
local Remotes = ReplicatedStorage.Remotes
local player = game.Players.LocalPlayer
local AppGui = player.PlayerGui:WaitForChild("AppGui")
local UIManager = require(player.PlayerScripts:WaitForChild("Controllers").UI.UIManager)
local InventoryFrame = AppGui.InventoryFrame

local ItemsFrame = InventoryFrame.ScrollingFrame.ItemsFrame
local grid = ItemsFrame.UIGridLayout
local columns = 5
local padding = 8 -- px gap between cells (match your UIGridLayout padding)

local InventoryUpdateRemote = player.PlayerScripts:WaitForChild("Events"):WaitForChild("InventoryChanged")
local toggleToolRemote = Remotes:WaitForChild("Tools"):WaitForChild("ToggleTool")


local function clearInventory()
	for _, child in ItemsFrame:GetChildren() do
		if child:IsA("Frame") and child.Name ~= "Template" and child.Name ~= "dotFrame" then
			child:Destroy()
		end
	end
end

local function getStackList(itemId, totalQuantity)
	local stackLimit = (Items[itemId] and Items[itemId].StackLimit) or math.huge
	local stacks = {}

	while totalQuantity > 0 do
		local stackSize = math.min(totalQuantity, stackLimit)
		table.insert(stacks, stackSize)
		totalQuantity -= stackSize
	end

	return stacks
end

local function updateInventory(inventory)
	clearInventory()

	for itemId, quantity in pairs(inventory) do
		local stacks = getStackList(itemId, quantity)

		for stackIndex, stackQty in ipairs(stacks) do
			local template = ItemsFrame.Template:Clone()
			template.ItemImage.Image = Items[itemId].IconId
			
			-- if stack is 1, don't display stack number
			if stackQty > 1 then
				template.ItemQuantity.Text = stackQty
				template.ItemQuantity.Visible = true
			else
				template.ItemQuantity.Visible = false
			end
			
			template.TextButton.MouseButton1Click:Connect(function()
				toggleToolRemote:FireServer(itemId)
			end)

			template.Parent = ItemsFrame
			template.Visible = true
			template.Name = tostring(itemId)
		end
	end
end

local function addItem(payload)
	local itemId = payload.itemId
	local quantity = payload.newAmount
	
	if ItemsFrame:FindFirstChild(itemId) then
		ItemsFrame:FindFirstChild(itemId).ItemQuantity.Text = quantity 
	else
		local template = ItemsFrame.Template:Clone()
		template.ItemImage.Image = Items[itemId].IconId
		
		template.ItemQuantity.Text = quantity
		template.Parent = ItemsFrame
		template.Visible = true
		template.Name = tostring(itemId)
	end
end


local function updateCellSize()
	local w = ItemsFrame.AbsoluteSize.X
	local totalPadding = padding * (columns - 1)
	local cell = math.floor((w - totalPadding) / columns)

	grid.CellSize = UDim2.fromOffset(cell, cell)
	grid.CellPadding = UDim2.fromOffset(padding, padding)
	
end

local yer = 1


InventoryUpdateRemote.Event:Connect(function(inventory, payload)
	print(payload)
	
	if yer == 1 then
		yer = 2
		updateInventory(inventory)
	else
		addItem(payload)
	end
	--updateInventory(inventory)
end)

AppGui.toggleBackpack.MouseButton1Click:Connect(function()
	UIManager.Toggle("InventoryFrame")
end)

updateCellSize()
ItemsFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCellSize)
