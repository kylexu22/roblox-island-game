local player = game.Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Dialogs = require(ReplicatedStorage:WaitForChild("Dialogs"))
local UIService = require(player.PlayerScripts.Controllers.UI.UIManager)
local ChooseChoice = ReplicatedStorage.Remotes.Dialog:WaitForChild("ChooseChoice")

local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local AppGui = playerGui:WaitForChild("AppGui")
local frame = AppGui:WaitForChild("DialogFrame")

local speakerLabel = frame:WaitForChild("Speaker")
local bodyLabel = frame:WaitForChild("Body")
local choicesFrame = frame:WaitForChild("Choices"):WaitForChild("ButtonsFrame")
local choiceTemplate = frame:WaitForChild("ChoiceTemplate")
local continueButton = frame:WaitForChild("ContinueButton")

local currentDialogId
local currentNodeId

local player = game.Players.LocalPlayer

-- typing state
local typing = false
local skipTyping = false
local typingToken = 0
local pendingAutoNext = nil -- function to call when "Continue" is pressed

-- start hidden
choicesFrame.Parent.Visible = false
continueButton.Visible = true

local function clearChoices()
	for _, child in ipairs(choicesFrame:GetChildren()) do
		if child:IsA("TextButton") and child ~= choiceTemplate then
			child:Destroy()
		end
	end
end

local function typewriter(text, cps)
	typingToken += 1
	local myToken = typingToken

	typing = true
	skipTyping = false
	bodyLabel.Text = ""

	cps = cps or 35
	for i = 1, #text do
		-- canceled / moved to another node
		if myToken ~= typingToken then
			return false
		end

		-- skip requested
		if skipTyping then
			bodyLabel.Text = text
			break
		end

		bodyLabel.Text = string.sub(text, 1, i)
		task.wait(1 / cps)
	end

	typing = false
	return myToken == typingToken
end

local function renderNode(dialogId, nodeId)
	local dialog = Dialogs[dialogId]
	local node = dialog and dialog.Nodes and dialog.Nodes[nodeId]
	if not node then return end

	-- cancel any active typing when switching nodes
	typingToken += 1
	typing = false
	skipTyping = false

	currentDialogId = dialogId
	currentNodeId = nodeId

	speakerLabel.Text = node.Speaker or ""
	bodyLabel.Text = ""

	clearChoices()
	pendingAutoNext = nil

	-- hide UI elements until typing completes (or skip)
	choicesFrame.Parent.Visible = false

	-- pre-create choice buttons (but keep frame hidden until typing done)
	if node.Choices and #node.Choices > 0 then
		for i, choice in ipairs(node.Choices) do
			local btn = choiceTemplate:Clone()
			btn.Visible = true
			btn.Parent = choicesFrame
			btn.Text = choice.Text

			btn.MouseButton1Click:Connect(function()
				-- hide choices right away after a selection
				choicesFrame.Parent.Visible = false

				-- if typing, click = skip first (common UX)
				if typing then
					skipTyping = true
					return
				end

				local ok, result = ChooseChoice:InvokeServer(currentDialogId, currentNodeId, i)
				if not ok then
					-- show them back if server rejects
					choicesFrame.Parent.Visible = true
					return
				end

				if result.End then
					UIService.Toggle("DialogFrame")
					return
				end

				if result.Next then
					renderNode(currentDialogId, result.Next)
				end
			end)
		end
	elseif node.Next then
		-- No-choice nodes use full-frame continue button
		pendingAutoNext = function()
			local ok, result = ChooseChoice:InvokeServer(currentDialogId, currentNodeId, 0)
			if ok and result.Next then
				renderNode(currentDialogId, result.Next)
			end
		end
	end

	-- start typewriter, then reveal choices/continue
	task.spawn(function()
		local ok = typewriter(node.Text or "", 35)
		if not ok then return end -- node changed mid-type

		-- show choices or continue after typing finishes (or after skip completes)
		if node.Choices and #node.Choices > 0 then
			choicesFrame.Parent.Visible = true
		elseif node.Next then
			continueButton.Visible = true
		end
	end)
end

-- ContinueButton behavior:
-- 1) If typing: skip to full text (button will still stay visible and can be clicked again to advance)
-- 2) Else if no-choice node: advance
continueButton.MouseButton1Click:Connect(function()
	if typing then
		skipTyping = true
		return
	end
	if pendingAutoNext then
		pendingAutoNext()
	end
end)

-- Call this when player talks to NPC
local function openDialog(dialogId)
	local dialog = Dialogs[dialogId]
	if not dialog then return end
	UIService.Toggle("DialogFrame")
	renderNode(dialogId, dialog.Start)
end

player.PlayerScripts.Events.OpenDialog.Event:Connect(function(dialogId)
	openDialog(dialogId)
end)
