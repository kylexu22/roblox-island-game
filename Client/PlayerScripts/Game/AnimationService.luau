local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Animations = require(ReplicatedStorage:WaitForChild("Animations"))
local player = Players.LocalPlayer

local AnimationService = {}
local cache = {} -- cache[humanoid][key] = 


local function preloadAllAnimations(catalog)
	local anims = {}

	local function walk(t)
		for _, v in pairs(t) do
			if type(v) == "table" and v.Id then
				local a = Instance.new("Animation")
				a.AnimationId = v.Id
				table.insert(anims, a)
			elseif type(v) == "table" then
				walk(v)
			end
		end
	end

	walk(catalog)

	-- This yields until the assets are loaded
	ContentProvider:PreloadAsync(anims)
end


local function getHumanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function resolveKey(key)
	-- supports "Tool.AxeSwing"
	local t = Animations
	for part in string.gmatch(key, "[^%.]+") do
		t = t[part]
		if not t then return nil end
	end
	return t
end

local function getTrack(humanoid, key)
	cache[humanoid] = cache[humanoid] or {}
	if cache[humanoid][key] then
		return cache[humanoid][key]
	end

	local info = resolveKey(key)
	if not info then return nil end

	local anim = Instance.new("Animation")
	anim.AnimationId = info.Id

	local track = humanoid:LoadAnimation(anim)
	track.Priority = info.Priority or Enum.AnimationPriority.Action
	track.Looped = info.Loop or false

	cache[humanoid][key] = track
	return track
end

function AnimationService.Play(key, fadeTime, weight, speed)
	local character = player.Character
	local humanoid = getHumanoid(character)
	if not humanoid then return end

	local track = getTrack(humanoid, key)
	if not track then return end

	track:Play(fadeTime or 0.1, weight or 1, speed or 1)
	return track
end

function AnimationService.Stop(key, fadeTime)
	local character = player.Character
	local humanoid = getHumanoid(character)
	if not humanoid then return end

	local track = cache[humanoid] and cache[humanoid][key]
	if track then
		track:Stop(fadeTime or 0.1)
	end
end

preloadAllAnimations(Animations)

return AnimationService
