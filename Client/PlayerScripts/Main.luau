local StarterGui = game:GetService("StarterGui")

local success, errors = pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)
if not success then
	print(errors)
end