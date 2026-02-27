local TreeService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ToolService = require(ServerScriptService.Services.ToolService)

local function getRootPart(model: Model): BasePart?
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	-- fallback: first basepart
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			return d
		end
	end
	return nil
end

local function spawnWood(player: Player, treeModel: Model)
	local template = game.Workspace:FindFirstChild("WorkingAssets")
		and game.Workspace.WorkingAssets:FindFirstChild("Wood")

	if not template or not template:IsA("Model") then
		warn("Wood template missing at Workspace.WorkingAssets.Wood")
		return
	end

	local treeRoot = getRootPart(treeModel)
	if not treeRoot then return end

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	-- Base direction: from player -> tree (i.e. opposite side of player),
	-- but flattened so it stays horizontal.
	local toTree = (treeRoot.Position - hrp.Position)
	local baseDir = Vector3.new(toTree.X, 0, toTree.Z)
	if baseDir.Magnitude < 0.001 then
		baseDir = Vector3.new(treeRoot.CFrame.LookVector.X, 0, treeRoot.CFrame.LookVector.Z)
	end
	baseDir = baseDir.Unit

	-- Randomly rotate direction by ±30 degrees
	local maxDeg = 120
	local angle = math.rad(math.random(-maxDeg, maxDeg))

	local dir = (CFrame.fromAxisAngle(Vector3.yAxis, angle)):VectorToWorldSpace(baseDir)


	-- Use model bounds so we spawn just outside the trunk/canopy footprint
	local size = treeModel.PrimaryPart.Size
	local horizontalRadius = math.max(size.X, size.Z) * 0.5
	local spawnDistance = horizontalRadius + 1.1 -- tweak this

	local cf, size = treeModel:GetBoundingBox()

	local bottomY = cf.Position.Y - (size.Y * 0.5)

	local spawnPos = Vector3.new(
		treeRoot.Position.X + dir.X * spawnDistance,
		bottomY + 5, -- tweak this number
		treeRoot.Position.Z + dir.Z * spawnDistance
	)

	local wood = template:Clone()
	wood.Parent = game.Workspace

	-- Place it
	local rng = Random.new()

	local randomYaw = math.rad(rng:NextNumber(0, 360))
	wood:PivotTo(
		CFrame.new(spawnPos) *
			CFrame.Angles(0, randomYaw, 0)
	)


	-- Make sure physics is owned by server (optional but good for consistency)
	for _, d in ipairs(wood:GetDescendants()) do
		if d:IsA("BasePart") then
			d:SetNetworkOwner(player)
		end
	end

	local woodRoot = getRootPart(wood)
	if not woodRoot then return end

	-- Give it a little pop: forward away from tree + slight up
	local popSpeed = 17.5 -- tweak
	local upSpeed = 3   -- tweak
	woodRoot.AssemblyLinearVelocity = (dir * popSpeed) + Vector3.new(0, upSpeed, 0)

	-- Optional: a tiny spin for feel
	-- woodRoot.AssemblyAngularVelocity = Vector3.new(0, math.random(-8, 8), 0)
end

local function checkDistanceBetween(character, model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart or not model.PrimaryPart then return false end
	
	local distance = (humanoidRootPart.Position - model.PrimaryPart.Position).Magnitude
	return distance
end

function TreeService.RequestChop(player: Player, treeModel: Model)
	local character = player.Character
	if not character then return end
	
	-- Check if the player is within range
	if checkDistanceBetween(character, treeModel) > 10 then return end
	
	-- Check if the player has the correct tool
	local tool = ToolService.GetEquippedTool(player)
	if not tool or tool:GetAttribute("Category") ~= "Axe" then return end
	
	local woodCount = treeModel:GetAttribute("WoodCount")
	
	if woodCount > 0 then
		treeModel:SetAttribute("WoodCount", woodCount - 1)
		spawnWood(player, treeModel)
	end

end

return TreeService
