--[[
	TrainingService — ямы прокачки силы и удары по воздуху.
	• Игрок спрыгивает в яму (внутрь детали TrainZone): кирка бьёт сама (GameSettings.PitAutoInterval),
	  а каждый клик добавляет ещё удар. В яме сила за удар минимум в 2 раза больше, чем по воздуху.
	• Удар по воздуху (не в яме и не по стене) даёт GameSettings.AirSwingPower силы (минимум 1).
	• Закрытые ямы накрыты барьером LockBarrier (клиент убирает его, когда яма открыта).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local PitConfig = require(Config:WaitForChild("PitConfig"))
local Settings = require(Config:WaitForChild("GameSettings"))
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

local function pitAt(pos: Vector3)
	for _, pit in ipairs(pits) do
		if pit.Zone and MapService.PointInPart(pit.Zone, pos) then
			return pit
		end
	end
	return nil
end

local function gainStrength(player: Player, data, power: number)
	local gain = Formulas.StrengthPerSwing(data, power, MonetizationService.HasPass(player, "StrengthX2"))
	data.Strength += gain
	DataService.MarkDirty(player)
	Remotes.Event("Effect"):FireClient(player, "Strength", gain)
end

local function playSlash(player: Player)
	local character = player.Character
	local tool = character and character:FindFirstChild("Pickaxe")
	if tool and tool:IsA("Tool") then
		local anim = Instance.new("StringValue")
		anim.Name = "toolanim"
		anim.Value = "Slash"
		anim.Parent = tool
		game:GetService("Debris"):AddItem(anim, 1)
	end
end

-- Опыт за удар в яме → уровень игрока
local function gainXp(player: Player, data, pitPower: number)
	data.Xp += math.max(1, math.floor(pitPower * Settings.Xp.PerPitPower))
	local leveled = false
	while data.Xp >= Formulas.XpForLevel(data.PlayerLevel) do
		data.Xp -= Formulas.XpForLevel(data.PlayerLevel)
		data.PlayerLevel += 1
		leveled = true
	end
	if leveled then
		Remotes.Event("Effect"):FireClient(player, "LevelUp", data.PlayerLevel)
	end
end

-- Удар в яме. true — игрок стоит в яме (даже если она закрыта)
function TrainingService.TrySwing(player: Player, data, pos: Vector3): boolean
	local pit = pitAt(pos)
	if not pit then
		return false
	end
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
	gainStrength(player, data, cfg.Power)
	gainXp(player, data, cfg.Power)
	data.Stats.Swings += 1
	return true
end

-- Удар по воздуху (не в яме и не по стене)
function TrainingService.AirSwing(player: Player, data)
	gainStrength(player, data, Settings.AirSwingPower)
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

	-- Автоудары в открытой яме
	task.spawn(function()
		while true do
			task.wait(Settings.PitAutoInterval)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataService.Get(player)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local pit = root and pitAt(root.Position)
				local cfg = pit and PitConfig.Pits[pit.Index]
				if data and cfg and data.Rebirths >= cfg.RequiredRebirths then
					playSlash(player)
					gainStrength(player, data, cfg.Power)
					gainXp(player, data, cfg.Power)
					data.Stats.Swings += 1
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		lastLockNotice[p] = nil
	end)
end

return TrainingService
