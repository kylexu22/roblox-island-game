local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Remotes = ReplicatedStorage.Remotes
local BuildRequest = Remotes.Building.BuildRequest

local Island = Workspace:WaitForChild("Island")
local WorldEntities = Island:WaitForChild("WorldEntities")
local BuildingsPlaced = WorldEntities:WaitForChild("BuildingsPlaced")

local function overlapsWorldEntities(testModel: Model, pivot: CFrame): boolean
	testModel:PivotTo(pivot)

	local boxCF, boxSize = testModel:GetBoundingBox()

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { WorldEntities }
	params.MaxParts = 200

	local parts = Workspace:GetPartBoundsInBox(boxCF, boxSize, params)

	return #parts > 0
end


BuildRequest.OnServerInvoke = function(player: Player, itemId: string, requestedPivot: CFrame)
	if typeof(itemId) ~= "string" then return false end
	if typeof(requestedPivot) ~= "CFrame" then return false end

	local template = ReplicatedStorage.Assets.Placeables:FindFirstChild(itemId)
	if not template or not template:IsA("Model") then
		return false
	end

	-- Clone into nil (not in workspace), test collision there
	local testClone = template:Clone()

	local blocked = overlapsWorldEntities(testClone, requestedPivot)
	testClone:Destroy()

	if blocked then
		return false
	end

	-- Passed collision check, actually place it
	local placed = template:Clone()
	placed:PivotTo(requestedPivot)
	placed.Parent = BuildingsPlaced

	return true
end