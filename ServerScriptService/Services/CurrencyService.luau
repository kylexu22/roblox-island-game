local CurrencyService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Remotes = ReplicatedStorage.Remotes

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)

local DataDelta = Remotes.Data.DataDelta

function CurrencyService.getCurrency(player)
	return PlayerDataService.GetCurrency(player)
end

function CurrencyService.IncrementTix(player, amount)
	PlayerDataService.Update(player, function(data)
		data.Currency.Tix = data.Currency.Tix + amount
		DataDelta:FireClient(player, "Currency", { Tix = data.Currency.Tix })
	end)
end

function CurrencyService.DecrementTix(player, amount) 
	PlayerDataService.Update(player, function(data)
		data.Currency.Tix = data.Currency.Tix + (-amount)
		DataDelta:FireClient(player, "Currency", { Tix = data.Currency.Tix })
	end)
end


return CurrencyService
