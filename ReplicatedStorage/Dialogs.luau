local Dialogs = {
	
	-- dialogId (string key)
	["blacksmith_intro"] = {
		Start = "start",

		Nodes = {
			-- nodeId (string key)
			start = {
				Speaker = "Opti",
				Text = "Need something made?",

				Choices = {
					{ Text = "Craft a Makeshift Axe", Next = "craft_axe" },
					{ Text = "Who are you?", Next = "who" },
					{ Text = "Bye.", End = true },
				}
			},

			who = {
				Speaker = "Opti",
				Text = "I am the dev of the game.",
				Choices = {
					{ Text = "Back", Next = "start" },
					{ Text = "Bye.", End = true },
				}
			},

			craft_axe = {
				Speaker = "Opti",
				Text = "I can make one if you bring 3 sticks and 1 stone.",

				Choices = {
					{
						Text = "Craft it",
						Next = "crafted",

						-- Requirements are CHECKED on the server (client can hide/grey it out too)
						Requirements = {
							Items = {
								["1"] = 3, -- stick itemId (string is fine)
								["2"] = 1, -- stone itemId
							}
						},

						-- Actions are EXECUTED on the server
						Actions = {
							{
								Type = "CraftRecipe",
								RecipeId = 1001 -- or 1001 if you prefer numeric IDs
							}
						}
					},

					{ Text = "Maybe later", Next = "start" }
				}
			},

			crafted = {
				Speaker = "Blacksmith",
				Text = "Done. Try not to break it immediately.",
				Choices = {
					{ Text = "Thanks!", End = true }
				}
			},
		}
	},
	
	["experimental_intro"] = {
		Start = "intro_1",

		Nodes = {

			intro_1 = {
				Speaker = "Shedletsky",
				Text = "Welcome to the Experimental Area.",
				Next = "intro_2"  -- no choices, just continue
			},

			intro_2 = {
				Speaker = "Shedletsky",
				Text = "This is where we will test all the new stuff we make. Such as...",
				Next = "intro_3"
			},
			
			intro_3 = {
				Speaker = "Shedletsky",
				Text = "Pickup system, tool system, farming system, and more.",
				Next = "intro_4"
			},

			intro_4 = {
				Speaker = "Shedletsky",
				Text = "Thanks for reading.",
				Choices = {
					{ Text = "Keep talking", Next = "intro_5" },
					{ Text = "Np.", End = true },
					{ Text = "You're welcome.", End = true }
				}
			},
			
			intro_5 = {
				Speaker = "Shedletsky",
				Text = "No.",
				Choices = {
					{ Text = "k bye.", End = true }
				}
			},

		}
	}	
}

return Dialogs
