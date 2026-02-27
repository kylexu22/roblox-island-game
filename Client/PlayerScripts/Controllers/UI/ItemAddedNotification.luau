local TweenService = game:GetService("TweenService")
local Items = require(game:GetService("ReplicatedStorage"):WaitForChild("Items"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local InventoryUpdateEvent = player.PlayerScripts:WaitForChild("Events"):WaitForChild("InventoryChanged")

local AppGui = player.PlayerGui:WaitForChild("AppGui")
local ItemNotifcationFrame = AppGui:WaitForChild("ItemNotificationFrame")

-- notification stack (toasts)
local activeNotifs = {}
local MAX_NOTIFS = 4

local IN_TIME = 0.12
local HOLD_TIME = 0.55
local OUT_TIME = 0.12

local function tweenTransparency(frame, textLabel, bg, text, info)
	local tweens = {}
	if frame then
		table.insert(tweens, TweenService:Create(frame, info, { BackgroundTransparency = bg }))
	end
	if textLabel then
		table.insert(tweens, TweenService:Create(textLabel, info, { TextTransparency = text }))
	end
	for _, t in ipairs(tweens) do t:Play() end
	return tweens
end

local function pushUpExisting(basePos, stepY)
	for i, f in ipairs(activeNotifs) do
		if f and f.Parent then
			local target = basePos - UDim2.new(0, 0, 0, stepY * i)
			TweenService:Create(
				f,
				TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = target }
			):Play()
		end
	end
end

local function showNotifcation(payload)
	if not payload then return end
	local itemId = payload.itemId
	local delta = payload.newAmount - payload.oldAmount
	if not itemId or not delta or delta == 0 then return end

	local notif = ItemNotifcationFrame:Clone()
	notif.Visible = true
	notif.Parent = AppGui

	local textLabel = notif:FindFirstChild("TextLabel")
	if not textLabel then
		notif:Destroy()
		return
	end

	local itemName = (Items[itemId] and Items[itemId].Name) or ("Item " .. tostring(itemId))
	local sign = delta > 0 and "+" or "-"
	textLabel.Text = string.format("%s %d %s", sign, math.abs(delta), itemName)

	-- Base position (where newest toast sits)
	local basePos = ItemNotifcationFrame.Position
	local stepY = notif.AbsoluteSize.Y + 8 -- spacing between toasts

	-- Push existing ones up immediately
	pushUpExisting(basePos, stepY)

	-- Insert newest at the front of active list
	table.insert(activeNotifs, 1, notif)

	-- If too many, fade out the oldest and remove it
	if #activeNotifs > MAX_NOTIFS then
		local oldest = table.remove(activeNotifs, #activeNotifs)
		if oldest and oldest.Parent then
			local oldText = oldest:FindFirstChild("TextLabel")
			local outInfo = TweenInfo.new(OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tweenTransparency(oldest, oldText, 1, 1, outInfo)
			task.delay(OUT_TIME, function()
				if oldest and oldest.Parent then oldest:Destroy() end
			end)
		end
	end

	-- Place new notif slightly below base and fade in fast
	notif.Position = basePos + UDim2.new(0, 0, 0, 16)
	notif.BackgroundTransparency = 1
	textLabel.TextTransparency = 1

	local inInfo = TweenInfo.new(IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(notif, inInfo, { Position = basePos }):Play()
	TweenService:Create(textLabel, inInfo, { TextTransparency = 0 }):Play()

	-- After hold, fade out + remove from active list, then reflow
	task.delay(IN_TIME + HOLD_TIME, function()
		if not notif or not notif.Parent then return end

		local outInfo = TweenInfo.new(OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(notif, outInfo, { Position = notif.Position - UDim2.new(0, 0, 0, 16)}):Play()
		TweenService:Create(textLabel, outInfo, { TextTransparency = 1 }):Play()

		task.delay(OUT_TIME, function()
			-- remove from active list
			for i = #activeNotifs, 1, -1 do
				if activeNotifs[i] == notif then
					table.remove(activeNotifs, i)
					break
				end
			end

			if notif and notif.Parent then notif:Destroy() end

			-- reflow remaining toasts down to fill gaps
			for i, f in ipairs(activeNotifs) do
				if f and f.Parent then
					local target = basePos - UDim2.new(0, 0, 0, stepY * (i - 1))
					TweenService:Create(
						f,
						TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Position = target }
					):Play()
				end
			end
		end)
	end)
end

InventoryUpdateEvent.Event:Connect(function(inventory, payload)
	showNotifcation(payload)
end)

