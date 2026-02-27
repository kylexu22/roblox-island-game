local player = game.Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ProxmityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationService = require(player.PlayerScripts:WaitForChild("Controllers"):WaitForChild("Game"):WaitForChild("AnimationService"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local interactRemote = remotes:WaitForChild("Interact")
local playerScripts = player.PlayerScripts


local highlight = game:GetService("Lighting"):WaitForChild("Highlight")
local pulseTween

local prompts = {}

local function addHighlight(prompt)
	local parent = prompt.Parent.Parent
	highlight.Adornee = parent
	highlight.Enabled = true
	
	-- stop any existing pulse
	if pulseTween then
		pulseTween:Cancel()
		pulseTween = nil
	end

	-- set starting value (optional)
	highlight.OutlineTransparency = 0.45

	-- pulse 0.45 -> 0.7 -> 0.45 -> ...
	local info = TweenInfo.new(
		0.6, -- seconds (speed)
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1,   -- repeat forever
		true  -- reverses (so it goes back and forth)
	)

	pulseTween = TweenService:Create(highlight, info, { OutlineTransparency = 0.7 })
	pulseTween:Play()
end

local function removeHighlight()
	highlight.Adornee = nil
	highlight.Enabled = false
	
	if pulseTween then
		pulseTween:Cancel()
		pulseTween = nil
	end
end

local function showDialogUi(prompt)
	print(prompt)
	local gui = prompt.Parent.Parent:FindFirstChildWhichIsA("BillboardGui")
	gui.Enabled = true
end

local function hideDialogUi(prompt)
	local gui = prompt.Parent.Parent:FindFirstChildWhichIsA("BillboardGui")
	gui.Enabled = false
end


local function promptTriggered(prompt)
	if prompt.ActionText == "Pick Up" then
		AnimationService.Play("PickupLeft", nil, nil, 1)
		playerScripts.Events.Pickup:Fire(prompt.Parent.Parent)
	elseif prompt.ActionText == "Talk" then
		local baseModel = prompt.Parent.Parent
		local dialogId = baseModel:GetAttribute("DialogId")
		player.PlayerScripts.Events.OpenDialog:Fire(dialogId)
	end
	
	interactRemote:FireServer(prompt)
	script.pickup:Play()
end

-- useless rn
local function registerInteractable(obj)
	local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		table.insert(prompts, prompt)
		
	end
end


-- existing ones
for _, obj in ipairs(CollectionService:GetTagged("Interactable")) do
	registerInteractable(obj)
end

-- new ones
CollectionService:GetInstanceAddedSignal("Interactable"):Connect(registerInteractable)
ProxmityPromptService.PromptShown:Connect(function(prompt)
	addHighlight(prompt)
	
	--if CollectionService:HasTag(prompt.Parent.Parent, "NPC") then showDialogUi(prompt) end 
end)


ProxmityPromptService.PromptHidden:Connect(function(prompt)
	removeHighlight()
	
	--if CollectionService:HasTag(prompt.Parent.Parent, "NPC") then hideDialogUi(prompt) end 
end)

ProxmityPromptService.PromptTriggered:Connect(promptTriggered)