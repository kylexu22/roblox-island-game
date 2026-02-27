local Recipes = {
	
	["1001"] = {
		Name = "Makeshift Axe",
		Output = { itemId = 600, quantity = 1 },

		Ingredients = {
			["2"] = 3, -- 3x Stick
			["3"] = 1  -- 1x Stone
		},

		CraftTime = 1.5,
		Station = "Workbench",
		LevelRequired = 0
	},
	
}

return Recipes
