--[[
	TrainingService — ямы прокачки силы.
	Игрок спрыгивает в яму (внутрь детали TrainZone) и бьёт киркой — получает силу.
	Закрытые ямы накрыты барьером LockBarrier (клиент убирает его, когда яма открыта).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local PitConfig = require(Config:WaitForChild("PitConfig"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Formulas = require(Shared:WaitForChild("Formulas"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RequestService = require(Services:WaitForChild("RequestService"))
local MapService = require(Services:WaitForChild("MapService"))
local MonetizationService = require(Services:WaitForChild("MonetizationService"))

local TrainingService = {}
local pits = {}
local lastLockNotice: { [Player]: number } = {}

-- Возвращает true, если удар был в яме (даже если она закрыта)
function TrainingService.TrySwing(player: Player, data, pos: Vector3): boolean
	for _, pit in ipairs(pits) do
		if pit.Zone and MapService.PointInPart(pit.Zone, pos) then
			local cfg = PitConfig.Pits[pit.Index]
			if not cfg then
				return true
			end
			if data.Rebirths < cfg.RequiredRebirths then
				local now = os.clock()
				if not lastLockNotice[player] or now - lastLockNotice[player] > 3 then
					lastLockNotice[player] = now
					RequestService.Notify(player, ("Яма «%s» откроется после %d перерождений"):format(cfg.Name, cfg.RequiredRebirths), "error")
				end
				return true
			end
			local gain = Formulas.StrengthPerSwing(data, cfg.Power, MonetizationService.HasPass(player, "StrengthX2"))
			data.Strength += gain
			data.Stats.Swings += 1
			DataService.MarkDirty(player)
			Remotes.Event("Effect"):FireClient(player, "Strength", gain)
			return true
		end
	end
	return false
end

function TrainingService.Init()
	pits = MapService.Pits()
	for _, pit in ipairs(pits) do
		local cfg = PitConfig.Pits[pit.Index]
		if cfg then
			MapService.SetText(pit.Sign, "Title", cfg.Name)
			MapService.SetText(
				pit.Sign,
				"Sub",
				cfg.RequiredRebirths > 0 and ("🔒 %d перерождений · +%s силы"):format(cfg.RequiredRebirths, tostring(cfg.Power))
					or ("открыта · +%s силы"):format(tostring(cfg.Power))
			)
		else
			MapService.SetText(pit.Sign, "Title", "Новая яма")
			MapService.SetText(pit.Sign, "Sub", "свободное место")
		end
	end
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		lastLockNotice[p] = nil
	end)
end

return TrainingService
