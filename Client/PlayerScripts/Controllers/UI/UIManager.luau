local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local AppGui = playerGui:WaitForChild("AppGui")

local openedFrames = {}

local UIService = {}

-- helper: get or create UIScale
local function getScale(uiFrame)
	local scale = uiFrame:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = uiFrame
	end
	return scale
end


function UIService.PlayOpenAnimation(uiFrame)
	uiFrame.Visible = true
	local scale = getScale(uiFrame)

	-- start small
	scale.Scale = 0.5

	local tween = TweenService:Create(
		scale,
		TweenInfo.new(
			0.15, -- duration
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{ Scale = 1 }
	)

	tween:Play()
end

function UIService.PlayCloseAnimation(uiFrame)
	local scale = getScale(uiFrame)

	local tween = TweenService:Create(
		scale,
		TweenInfo.new(
			0.15,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		),
		{ Scale = 0.5 }
	)

	tween:Play()

	-- wait before disabling so animation finishes
	tween.Completed:Once(function()
		if uiFrame then
			uiFrame.Visible = false
		end
	end)
end

function UIService.Toggle(uiName)
	local uiFrame = AppGui:FindFirstChild(uiName)
	local enabled = false
	
	if table.find(openedFrames, uiFrame) then
		enabled = true
	end
	
	
	
	if uiFrame then
		if enabled then
			table.remove(openedFrames, table.find(openedFrames, uiFrame))
			UIService.PlayCloseAnimation(uiFrame)
		else
			table.insert(openedFrames, uiFrame)
			UIService.PlayOpenAnimation(uiFrame)
		end
		
	end
end

return UIService

