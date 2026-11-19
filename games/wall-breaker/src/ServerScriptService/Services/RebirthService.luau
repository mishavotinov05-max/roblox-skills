--[[
	RebirthService — перерождение (настройки в RebirthConfig).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("GameSettings"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Formulas = require(Shared:WaitForChild("Formulas"))
local Format = require(Shared:WaitForChild("Format"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RequestService = require(Services:WaitForChild("RequestService"))
local PickaxeService = require(Services:WaitForChild("PickaxeService"))
local WallService = require(Services:WaitForChild("WallService"))

local RebirthService = {}

function RebirthService.Init()
	RequestService.Register("Rebirth", function(player)
		local data = DataService.Get(player)
		local needLevel = Formulas.RebirthLevel(data.Rebirths)
		if data.PlayerLevel < needLevel then
			return { ok = false, msg = ("Нужен уровень %d (сейчас %d). Качайся в ямах!"):format(needLevel, data.PlayerLevel) }
		end
		local cost = Formulas.RebirthCost(data.Rebirths)
		if data.Wins < cost then
			return { ok = false, msg = ("Нужно %s побед"):format(Format.Short(cost)) }
		end
		data.Wins -= cost
		data.Rebirths += 1
		data.PlayerLevel = 1
		data.Xp = 0
		data.Stats.Rebirths += 1
		data.Strength = 0
		data.OwnedPickaxes = { [Settings.StartPickaxe] = true }
		data.EquippedPickaxe = Settings.StartPickaxe
		data.LevelProgress = {}
		WallService.ResetPlayer(player)
		DataService.MarkDirty(player)
		PickaxeService.GiveTool(player)
		RequestService.Notify(player, ("Перерождение %d! Сила навсегда ×%s"):format(data.Rebirths, tostring(Formulas.RebirthMultiplier(data))), "success")
		return { ok = true }
	end)

	DataService.AddStateHook(function(_, state, data)
		state.RebirthCost = Formulas.RebirthCost(data.Rebirths)
		state.RebirthLevel = Formulas.RebirthLevel(data.Rebirths)
	end)
end

return RebirthService
