local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local Island = Workspace:WaitForChild("Island")
local WorldEntities = Island:WaitForChild("WorldEntities")

-- Ignore clicking / hovering dynamic world entities when using mouse.Hit
mouse.TargetFilter = WorldEntities

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuildRequest = Remotes:WaitForChild("Building"):WaitForChild("BuildRequest")

local GridUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GridUtil"))
local Placeables = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Placeables")

local GridIncrement = 1
local YLevel = 0

-- MAX placement range (studs)
local MAX_PLACE_DISTANCE = 40

local PlacementToggled = false
local currentGhostModel: Model? = nil
local currentSelectionBox: SelectionBox? = nil
local selectedModelName: string? = nil
local placementConnection: RBXScriptConnection? = nil
local isBlocked = false
local isInRange = false

-- rotation tween state (unwrapped degrees)
local targetRot = 0
local rotationTween: Tween? = nil
local rotValue: NumberValue? = nil
local ROTATE_TIME = 0.12

-- overlap params (include anything under WorldEntities)
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = { WorldEntities }
overlapParams.MaxParts = 200

local GREEN = Color3.fromRGB(0, 255, 17)
local RED = Color3.fromRGB(255, 60, 60)

local function createSelectionBox()
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.LineThickness = 0.025
	selectionBox.Transparency = 0
	selectionBox.Color3 = GREEN
	selectionBox.SurfaceColor3 = GREEN
	selectionBox.SurfaceTransparency = 0.75
	return selectionBox
end

local function setGhostVisible(visible: boolean)
	if not currentGhostModel then return end
	for _, d in ipairs(currentGhostModel:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = visible and 0 or 1
		elseif d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = visible and 0 or 1
		end
	end
	if currentSelectionBox then
		currentSelectionBox.Visible = visible
	end
end

local function getGhostModel(model: Model): (Model, SelectionBox)
	local ghostModel = model:Clone()
	ghostModel.Parent = Workspace.TargetFilter -- assumes you have Workspace.TargetFilter folder for client visuals

	local selectionBox = createSelectionBox()
	selectionBox.Adornee = ghostModel
	selectionBox.Parent = ghostModel

	-- Make ghost non-interactive
	for _, child in ipairs(ghostModel:GetDescendants()) do
		if child:IsA("BasePart") then
			child.CastShadow = false
			child.CanCollide = false
			child.CanTouch = false
			child.CanQuery = false -- don't let the ghost appear in overlap results
			child.Anchored = true
		end
	end

	return ghostModel, selectionBox
end

local function cleanupPlacement()
	PlacementToggled = false
	selectedModelName = nil
	isBlocked = false
	isInRange = false

	if placementConnection then
		placementConnection:Disconnect()
		placementConnection = nil
	end

	if rotationTween then
		rotationTween:Cancel()
		rotationTween = nil
	end

	if rotValue then
		rotValue:Destroy()
		rotValue = nil
	end

	if currentGhostModel then
		currentGhostModel:Destroy()
		currentGhostModel = nil
	end

	currentSelectionBox = nil
end

local function computeBlockedAtPivot(pivot: CFrame): boolean
	if not currentGhostModel then return false end

	-- Ensure bounding box matches the exact spot/rotation we're testing
	currentGhostModel:PivotTo(pivot)

	local boxCF, boxSize = currentGhostModel:GetBoundingBox()
	local parts = Workspace:GetPartBoundsInBox(boxCF, boxSize, overlapParams)

	return #parts > 0
end

local function getPlayerPivotPosition(): Vector3?
	local character = player.Character
	if not character then return nil end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then return nil end

	return hrp.Position
end

local function togglePlacement()
	if PlacementToggled then
		cleanupPlacement()
		return
	end

	PlacementToggled = true

	-- Pick the model you want to place here
	local model = Placeables:WaitForChild("Hut") :: Model
	selectedModelName = model.Name

	currentGhostModel, currentSelectionBox = getGhostModel(model)

	-- rotation state
	targetRot = 0
	if rotValue then rotValue:Destroy() end
	rotValue = Instance.new("NumberValue")
	rotValue.Value = 0
	rotValue.Parent = script

	placementConnection = RunService.Stepped:Connect(function()
		if not currentGhostModel or not rotValue then return end

		local snappedPos = GridUtil.snapVectorXZ(mouse.Hit.Position, GridIncrement, YLevel)

		-- range check
		local originPos = getPlayerPivotPosition()
		if not originPos then
			isInRange = false
		else
			local delta = (snappedPos - originPos)
			isInRange = (delta.Magnitude <= MAX_PLACE_DISTANCE)
		end

		if not isInRange then
			-- Hide ghost when too far, don't update collision color
			setGhostVisible(false)
			isBlocked = true
			return
		end

		setGhostVisible(true)

		local yDeg = rotValue.Value % 360
		local rotationCF = CFrame.Angles(0, math.rad(yDeg), 0)
		local pivot = CFrame.new(snappedPos) * rotationCF

		isBlocked = computeBlockedAtPivot(pivot)

		if currentSelectionBox then
			currentSelectionBox.Color3 = isBlocked and RED or GREEN
			currentSelectionBox.SurfaceColor3 = isBlocked and RED or GREEN
		end
	end)
end

local function rotateModel()
	if not PlacementToggled or not rotValue then return end

	targetRot += 90 -- unwrapped

	if rotationTween then
		rotationTween:Cancel()
		rotationTween = nil
	end

	rotationTween = TweenService:Create(
		rotValue,
		TweenInfo.new(ROTATE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = targetRot }
	)

	rotationTween:Play()
end

local function placeModel()
	if not PlacementToggled or not currentGhostModel or not selectedModelName then return end
	if not isInRange then return end
	if isBlocked then return end

	local pivot = currentGhostModel:GetPivot()
	BuildRequest:InvokeServer(selectedModelName, pivot)
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	if input.KeyCode == Enum.KeyCode.B then
		togglePlacement()

	elseif input.KeyCode == Enum.KeyCode.R and PlacementToggled then
		rotateModel()

	elseif input.UserInputType == Enum.UserInputType.MouseButton1 and PlacementToggled then
		placeModel()
	end
end)
