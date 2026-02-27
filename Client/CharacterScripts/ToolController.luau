local player = game:GetService("Players").LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local character = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ToolRemotes = Remotes:WaitForChild("Tools")
local CollectionService = game:GetService("CollectionService")
local TreeVFX = require(playerScripts:WaitForChild("Controllers"):WaitForChild("Game"):WaitForChild("TreeVFX"))

local toolCooldown = false

local PlayerScripts = player:WaitForChild("PlayerScripts")
local AnimationService = require(PlayerScripts:WaitForChild("Controllers"):WaitForChild("Game"):WaitForChild("AnimationService"))


local function ToolAdded(tool)
	local holdAnimationId = tool:GetAttribute("HoldAnimationId")
	AnimationService.Play(holdAnimationId)
	
end

local function ToolRemoved(tool)
	AnimationService.Stop(tool:GetAttribute("HoldAnimationId"))
end

local function ApplyAxe(tool)
	local useAnimationId = tool:GetAttribute("UseAnimationId")
	local connection
	local once = false -- make sure hits only one time

	-- Axe delay
	local axeSwingDelay = 0.33
	task.wait(axeSwingDelay)
	
	tool.Trail.Enabled = true
	tool.Handle.swing:Play()

	connection = tool.Contact.Touched:Connect(function(hit)
		if once == true then return end
		once = true
		
		local treeModel = hit.Parent
		if not treeModel or not CollectionService:HasTag(treeModel, "Tree") then return end
		
		tool.Trail.Enabled = false
		tool.Handle.chop:Play()
		AnimationService.Stop(useAnimationId)
		TreeVFX.Chop(player, treeModel)
		ToolRemotes:WaitForChild("ChopTree"):FireServer(treeModel)

		-- Disconnect after first hit
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end)

	-- Auto-destroy after 0.5 seconds if nothing hit
	task.delay(0.14, function()
		tool.Trail.Enabled = false
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end)
end

local function ToolUsed(tool)
	local toolCategory = tool:GetAttribute("Category")
	local useCooldown = tool:GetAttribute("UseCooldown")
	local useAnimationId = tool:GetAttribute("UseAnimationId")
	
	if toolCooldown then return end
	toolCooldown = true
	
	task.spawn(function()
		task.wait(useCooldown)
		toolCooldown = false
	end)
	
	AnimationService.Play(useAnimationId)
	
	if toolCategory == "Axe" then
		ApplyAxe(tool)
	end
	
	return
end

character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		local tool = child
		ToolAdded(tool)
		
		tool.Activated:Connect(function()
			ToolUsed(tool)
		end)
	end
end)

character.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") then
		local tool = child
		ToolRemoved(tool)
	end
end)