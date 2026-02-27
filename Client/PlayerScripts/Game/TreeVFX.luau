local TreeService = {}

local SHAKE_DISTANCE = 0.1 -- studs
local SHAKE_STEPS = 3
local STEP_TIME = 0.06

function TreeService.Chop(player, treeModel: Model)
	if not treeModel or not treeModel:IsA("Model") then return end

	if treeModel:GetAttribute("Shaking") then return end
	treeModel:SetAttribute("Shaking", true)

	local basePivot = treeModel:GetPivot()

	for i = 1, SHAKE_STEPS do
		local dir = (i % 2 == 0) and 1 or -1

		treeModel:PivotTo(
			basePivot * CFrame.new(
				dir * SHAKE_DISTANCE, -- X only
				0,                    -- Y stays fixed
				-dir * SHAKE_DISTANCE -- Z only
			)
		)

		task.wait(STEP_TIME)
	end

	-- snap back exactly
	treeModel:PivotTo(basePivot)
	treeModel:SetAttribute("Shaking", false)
end

return TreeService
