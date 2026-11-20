--[[
	BoostService — «Мощный удар»: на время вся сила и урон умножаются.
	Настройки: GameSettings.PowerStrike (Multiplier, Duration, Cooldown).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameSettings"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RequestService = require(Services:WaitForChild("RequestService"))

local BoostService = {}
local activatedAt: { [Player]: number } = {}

function BoostService.Multiplier(player: Player): number
	local t = activatedAt[player]
	if t and os.clock() - t < Settings.PowerStrike.Duration then
		return Settings.PowerStrike.Multiplier
	end
	return 1
end

function BoostService.Init()
	RequestService.Register("PowerStrike", function(player)
		local t = activatedAt[player]
		local since = t and os.clock() - t or math.huge
		if since < Settings.PowerStrike.Cooldown then
			return { ok = false, msg = ("Мощный удар будет готов через %d сек."):format(math.ceil(Settings.PowerStrike.Cooldown - since)) }
		end
		activatedAt[player] = os.clock()
		DataService.MarkDirty(player)
		RequestService.Notify(player, ("Мощный удар! Сила ×%s на %d сек."):format(tostring(Settings.PowerStrike.Multiplier), Settings.PowerStrike.Duration), "success")
		return { ok = true }
	end)

	DataService.AddStateHook(function(player, state)
		local t = activatedAt[player]
		local since = t and os.clock() - t or math.huge
		state.PowerStrikeActiveFor = math.max(0, Settings.PowerStrike.Duration - since)
		state.PowerStrikeReadyIn = math.max(0, Settings.PowerStrike.Cooldown - since)
	end)

	Players.PlayerRemoving:Connect(function(p)
		activatedAt[p] = nil
	end)
end

return BoostService
