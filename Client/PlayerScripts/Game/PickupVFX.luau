local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local pickupEvent = player.PlayerScripts.Events:WaitForChild("Pickup")

local function clearHeldPropR6(character: Model)
	local prop = character:FindFirstChild("HeldProp")
	if prop then prop:Destroy() end
	local leftArm = character:FindFirstChild("Left Arm")
	if leftArm then
		local weld = leftArm:FindFirstChild("HeldPropWeld")
		if weld then weld:Destroy() end
	end
end

local function holdPropR6(character: Model, propModel: Model, gripOffset: CFrame?)
	gripOffset = gripOffset or CFrame.new(0, -0.9, -0.2) * CFrame.Angles(0, math.rad(90), math.rad(90))
	propModel = propModel:Clone()
	local modelScale = propModel:GetScale()
	propModel:ScaleTo(modelScale*.5)
	--character:FindFirstChild("Humanoid").WalkSpeed = 0
	
	if propModel:FindFirstChildWhichIsA("ProximityPrompt", true) then
		propModel:FindFirstChildWhichIsA("ProximityPrompt", true):Destroy()
	end

	local arm = character:FindFirstChild("Left Arm")
	if not arm then return nil end

	local handle = propModel:FindFirstChild("Handle")
		or propModel.PrimaryPart
		or propModel:FindFirstChildWhichIsA("BasePart", true)
	if not handle then return nil end

	propModel.PrimaryPart = handle

	-- prep physics
	for _, d in ipairs(propModel:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("MeshPart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		end
	end
	
	local tweak = CFrame.Angles(math.rad(90), 0, 0)

	propModel:PivotTo(arm.CFrame * gripOffset * tweak)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = arm
	weld.Part1 = handle
	weld.Parent = arm
	weld.Name = "HeldPropWeld"

	-- store reference so you can clean up easily
	propModel.Name = "HeldProp"
	propModel.Parent = character

	task.spawn(function()
		task.wait(0.67)
		clearHeldPropR6(character)
		
		
		--[[local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end

		local tweenTime = 0.3
		local startSpeed = humanoid.WalkSpeed
		local targetSpeed = 16

		local proxy = Instance.new("NumberValue")
		proxy.Value = startSpeed

		proxy:GetPropertyChangedSignal("Value"):Connect(function()
			humanoid.WalkSpeed = proxy.Value
		end)

		local tween = game:GetService("TweenService"):Create(
			proxy,
			TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Value = targetSpeed }
		)

		tween:Play()

		tween.Completed:Connect(function()
			proxy:Destroy()
		end)]]
	end)
	
	return propModel
end

local function facePrompt(itemInstance)
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Get the position of the item
	local itemPosition = itemInstance:GetPivot().Position
	
	-- Make the character face the item while keeping the same height
	local currentPos = humanoidRootPart.Position
	local lookAtCFrame = CFrame.lookAt(currentPos, Vector3.new(itemPosition.X, currentPos.Y, itemPosition.Z))
	
	humanoidRootPart.CFrame = lookAtCFrame
end


pickupEvent.Event:Connect(function(itemInstance)
	holdPropR6(player.Character, itemInstance, CFrame.new(0.0303888321, -1.16960621, -0.150306702, -1, 2.44929371e-16, 1.8863111e-23, 2.44929371e-16, 1, 1.62920685e-07, 1.88631252e-23, 1.62920685e-07, -1))
	facePrompt(itemInstance)
end)
