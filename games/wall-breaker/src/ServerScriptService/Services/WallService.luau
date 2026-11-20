--[[
	WallService — уровни: 10 слоёв стены, автоудары, выбор награды.

	• Стены у каждого игрока свои: сервер хранит прогресс (сколько слоёв сломано),
	  клиент скрывает сломанные слои только у себя.
	• Пока игрок стоит в уровне перед стеной, стена бьётся сама (GameSettings.AutoBreakInterval).
	  Если тапать — быстрее. Если силы хватает, слой ломается с одного удара.
	• После стены — промежуток с нишей справа. В нише 2 площадки:
	    RewardPad — «+N побед и в лобби» (бесплатно),
	    X3Pad     — «×3 и в лобби» (Robux, товар level_x3 в ShopConfig).
	  Или иди дальше — на следующем уровне награда больше.
	  N = награда самого дальнего пройденного уровня (LevelConfig.WinsReward).
	  После получения награды все стены снова целые — награда выдаётся один раз за забег.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = ReplicatedStorage:WaitForChild("Config")
local LevelConfig = require(Config:WaitForChild("LevelConfig"))
local Settings = require(Config:WaitForChild("GameSettings"))
local ShopConfig = require(Config:WaitForChild("ShopConfig"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Formulas = require(Shared:WaitForChild("Formulas"))
local Format = require(Shared:WaitForChild("Format"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RequestService = require(Services:WaitForChild("RequestService"))
local MapService = require(Services:WaitForChild("MapService"))
local MonetizationService = require(Services:WaitForChild("MonetizationService"))
local OreService = require(Services:WaitForChild("OreService"))
local BoostService = require(Services:WaitForChild("BoostService"))

local WallService = {}
local LAYERS = LevelConfig.LayersPerLevel

local hp: { [Player]: { [number]: number } } = {} -- оставшаяся прочность текущего слоя
local currentLevel: { [Player]: number? } = {}

local function progressOf(data, levelId: number): number
	return data.LevelProgress[tostring(levelId)] or 0
end

-- Самый дальний уровень, стена которого сломана в этом забеге
function WallService.RunBest(data): number
	local best = 0
	for key, prog in pairs(data.LevelProgress) do
		local id = tonumber(key)
		if id and prog >= LAYERS and id > best then
			best = id
		end
	end
	return best
end

function WallService.RewardFor(levelId: number): number
	local cfg = Catalog.Level(levelId)
	return cfg and cfg.WinsReward or 0
end

local function layerHP(player: Player, data, levelId: number): number
	hp[player] = hp[player] or {}
	local prog = progressOf(data, levelId)
	if hp[player][levelId] == nil then
		hp[player][levelId] = Formulas.LayerHP(levelId, math.min(prog + 1, LAYERS))
	end
	return hp[player][levelId]
end

function WallService.ResetPlayer(player: Player)
	hp[player] = {}
end

local function sendLevelState(player: Player, levelId: number?)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local cfg = levelId and Catalog.Level(levelId)
	if not levelId or not cfg then
		Remotes.Event("LevelState"):FireClient(player, nil)
		return
	end
	local prog = progressOf(data, levelId)
	local best = WallService.RunBest(data)
	Remotes.Event("LevelState"):FireClient(player, {
		Level = levelId,
		Name = cfg.Name,
		Layer = prog,
		Layers = LAYERS,
		HP = prog >= LAYERS and 0 or layerHP(player, data, levelId),
		MaxHP = Formulas.LayerHP(levelId, math.min(prog + 1, LAYERS)),
		Recommended = Formulas.RecommendedStrength(levelId),
		RunBest = best,
		RunReward = WallService.RewardFor(best),
	})
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

-- Текущий слой, если игрок стоит перед ним
local function targetLayer(data, pos: Vector3)
	local level = MapService.LevelAt(pos)
	if not level or not Catalog.Level(level.Id) then
		return nil, nil
	end
	local prog = progressOf(data, level.Id)
	if prog >= LAYERS then
		return level, nil
	end
	local layer = level.Layers[prog + 1] :: BasePart?
	if not layer then
		return level, nil
	end
	local rel = layer.CFrame:PointToObjectSpace(pos)
	if math.abs(rel.Z) > layer.Size.Z / 2 + Settings.WallReach or math.abs(rel.X) > layer.Size.X / 2 + 4 then
		return level, nil
	end
	return level, layer
end

local function hit(player: Player, data, level)
	local remaining = layerHP(player, data, level.Id) - Formulas.Damage(data) * BoostService.Multiplier(player)
	if remaining > 0 then
		hp[player][level.Id] = remaining
		sendLevelState(player, level.Id)
		return
	end
	-- Слой сломан
	local prog = progressOf(data, level.Id) + 1
	data.LevelProgress[tostring(level.Id)] = prog
	data.Stats.LayersBroken += 1
	hp[player][level.Id] = nil
	Remotes.Event("Effect"):FireClient(player, "Break", level.Id, prog)
	OreService.Roll(player, data)
	if prog >= LAYERS then
		data.BestLevel = math.max(data.BestLevel, level.Id)
	end
	DataService.MarkDirty(player)
	sendLevelState(player, level.Id)
end

-- Удар из SwingService. true — удар пришёлся по стене.
function WallService.TrySwing(player: Player, data, pos: Vector3): boolean
	local level, layer = targetLayer(data, pos)
	if not level or not layer then
		return false
	end
	hit(player, data, level)
	return true
end

local function teleportToLobby(player: Player)
	local character = player.Character
	if character then
		character:PivotTo(MapService.SpawnCFrame())
	end
end

-- Забрать награду за забег и вернуться в лобби
function WallService.CashOut(player: Player, multiplier: number, levelOverride: number?): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	local best = levelOverride or WallService.RunBest(data)
	if best <= 0 then
		return 0
	end
	local wins = WallService.RewardFor(best) * multiplier
	data.Wins += wins
	data.Stats.LevelsCleared += best
	data.LevelProgress = {}
	data.PendingX3Level = 0
	hp[player] = {}
	DataService.MarkDirty(player)
	teleportToLobby(player)
	Remotes.Event("Effect"):FireClient(player, "Reward", best, wins)
	RequestService.Notify(player, ("+%s побед!"):format(Format.Short(wins)), "wins")
	task.delay(0.5, sendLevelState, player, nil)
	return wins
end

local function productId(key: string): number
	for _, p in ipairs(ShopConfig.Products) do
		if p.Key == key then
			return p.Id
		end
	end
	return 0
end

function WallService.Init()
	for _, level in ipairs(MapService.Levels()) do
		local cfg = Catalog.Level(level.Id)
		if cfg then
			MapService.SetText(level.Sign, "Title", ("Уровень %d · %s"):format(level.Id, cfg.Name))
			MapService.SetText(level.Sign, "Sub", ("Сила: %s · награда %s побед"):format(Format.Short(Formulas.RecommendedStrength(level.Id)), Format.Short(cfg.WinsReward)))
		end
	end

	-- Площадки в нише
	local padDebounce: { [Player]: number } = {}
	local function playerFromHit(hit: BasePart): Player?
		local model = hit:FindFirstAncestorOfClass("Model")
		return model and Players:GetPlayerFromCharacter(model)
	end
	local function canUse(player: Player, cooldown: number): boolean
		local now = os.clock()
		if padDebounce[player] and now - padDebounce[player] < cooldown then
			return false
		end
		padDebounce[player] = now
		return true
	end
	Players.PlayerRemoving:Connect(function(p)
		padDebounce[p] = nil
	end)
	for _, level in ipairs(MapService.Levels()) do
		local cfg = Catalog.Level(level.Id)
		local reward = cfg and cfg.WinsReward or 0
		if level.RewardPad then
			MapService.SetText(level.RewardPad, "Reward", ("+%s %s"):format(Format.Short(reward), reward == 1 and "победа" or "побед"))
			level.RewardPad.Touched:Connect(function(hit)
				local player = playerFromHit(hit)
				local data = player and DataService.Get(player)
				if not player or not data or not canUse(player, 1.5) then
					return
				end
				if WallService.RunBest(data) <= 0 then
					RequestService.Notify(player, "Сначала сломай стену уровня", "error")
					return
				end
				WallService.CashOut(player, MonetizationService.HasPass(player, "WinsX3") and 3 or 1)
			end)
		end
		if level.X3Pad then
			MapService.SetText(level.X3Pad, "Reward", ("x3 = %s побед"):format(Format.Short(reward * 3)))
			level.X3Pad.Touched:Connect(function(hit)
				local player = playerFromHit(hit)
				local data = player and DataService.Get(player)
				if not player or not data or not canUse(player, 4) then
					return
				end
				local best = WallService.RunBest(data)
				if best <= 0 then
					RequestService.Notify(player, "Сначала сломай стену уровня", "error")
					return
				end
				if MonetizationService.HasPass(player, "WinsX3") then
					WallService.CashOut(player, 3)
					return
				end
				local id = productId("level_x3")
				if id == 0 then
					RequestService.Notify(player, "Покупка ещё не настроена (товар level_x3 в ShopConfig)", "error")
					return
				end
				data.PendingX3Level = best
				MarketplaceService:PromptProductPurchase(player, id)
			end)
		end
	end

	RequestService.Register("CashOutLevel", function(player)
		local data = DataService.Get(player)
		if WallService.RunBest(data) <= 0 then
			return { ok = false, msg = "Сначала сломай стену уровня" }
		end
		WallService.CashOut(player, MonetizationService.HasPass(player, "WinsX3") and 3 or 1)
		return { ok = true }
	end)

	RequestService.Register("LevelRewardX3", function(player)
		local data = DataService.Get(player)
		local best = WallService.RunBest(data)
		if best <= 0 then
			return { ok = false, msg = "Сначала сломай стену уровня" }
		end
		local id = productId("level_x3")
		if id == 0 then
			return { ok = false, msg = "Покупка ещё не настроена (товар level_x3 в ShopConfig)" }
		end
		data.PendingX3Level = best
		MarketplaceService:PromptProductPurchase(player, id)
		return { ok = true }
	end)

	-- Оплата ×3: выдаём тройную награду за уровень, запомненный при нажатии кнопки
	MonetizationService.RegisterProductHandler("level_x3", function(player, data)
		local level = data.PendingX3Level
		if not level or level <= 0 then
			level = math.max(1, WallService.RunBest(data))
		end
		WallService.CashOut(player, 3, level)
		return true
	end)

	RequestService.Register("GoToLobby", function(player)
		teleportToLobby(player)
		return { ok = true }
	end)

	-- Следим, где стоит игрок: панель уровня + автоудары по стене
	task.spawn(function()
		local acc = 0
		while true do
			task.wait(0.2)
			acc += 0.2
			local autoHit = acc >= Settings.AutoBreakInterval
			if autoHit then
				acc = 0
			end
			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataService.Get(player)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if data and root then
					local level, layer = targetLayer(data, root.Position)
					local id = level and level.Id or nil
					if id ~= currentLevel[player] then
						currentLevel[player] = id
						sendLevelState(player, id)
					end
					if autoHit and level and layer then
						playSlash(player)
						hit(player, data, level)
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		hp[player] = nil
		currentLevel[player] = nil
	end)
end

return WallService
