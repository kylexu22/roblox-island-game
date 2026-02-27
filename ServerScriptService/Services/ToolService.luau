local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local InventoryService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("InventoryService"))
local ItemModels = ServerStorage:WaitForChild("ItemModels")
local Tools = ItemModels:WaitForChild("Tools")
local Recipes = require(ReplicatedStorage:WaitForChild("Recipes"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local ToolService = {}

function ToolService.GiveTool(player, toolId)
	local tool = Tools:FindFirstChild(toolId):Clone()
	if not player.Character then return end
	
	tool.Parent = player.Character
end

function ToolService.RemoveTool(player)
	local character = player.Character
	if not character then return end
	
	for i,v in pairs(character:GetChildren()) do
		if v:IsA("Tool") then
			v:Destroy()
		end
	end
end

function ToolService.GetEquippedTool(player)
	local character = player.Character
	if not character then return end
	
	for i,v in pairs(character:GetChildren()) do
		if v:IsA("Tool") then
			return v
		end
	end
end



return ToolService
