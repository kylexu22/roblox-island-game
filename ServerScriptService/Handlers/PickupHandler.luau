local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")

local InventoryService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("InventoryService"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local interactRemote = remotes:WaitForChild("Interact")

interactRemote.OnServerEvent:Connect(function(player, prompt)
	
	-- picking up resource
	if CollectionService:HasTag(prompt.Parent.Parent, "Resource") then
		local itemInstance = prompt.Parent.Parent
		prompt.Enabled = false
		local itemId = prompt.Parent.Parent:GetAttribute("ItemId")
		InventoryService.AddItem(player, itemId)
		
		prompt:Destroy()
		itemInstance:Destroy()
	end
	
end)