--[[
	WallService — уровни: 10 слоёв стены, награда за прохождение, возврат в лобби.

	Стены у каждого игрока свои: сервер хранит прогресс (сколько слоёв сломано),
	а клиент скрывает сломанные слои только у себя.
	Награда в нише выдаётся один раз за прохождение: после получения стены уровня
	снова появляются, и чтобы получить награду ещё раз, их нужно сломать заново.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local LevelConfig = require(Config:WaitForChild("LevelConfig"))
local Settings = require(Config:WaitForChild("GameSettings"))
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

local WallService = {}
local LAYERS = LevelConfig.LayersPerLevel

local hp: { [Player]: { [number]: number } } = {} -- оставшаяся прочность текущего слоя
local currentLevel: { [Player]: number? } = {}
local padDebounce: { [Player]: number } = {}

local function progressOf(data, levelId: number): number
	return data.LevelProgress[tostring(levelId)] or 0
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
	if not levelId then
		Remotes.Event("LevelState"):FireClient(player, nil)
		return
	end
	local cfg = Catalog.Level(levelId)
	if not cfg then
		Remotes.Event("LevelState"):FireClient(player, nil)
		return
	end
	local prog = progressOf(data, levelId)
	local maxHP = Formulas.LayerHP(levelId, math.min(prog + 1, LAYERS))
	Remotes.Event("LevelState"):FireClient(player, {
		Level = levelId,
		Name = cfg.Name,
		Layer = prog,
		Layers = LAYERS,
		HP = prog >= LAYERS and 0 or layerHP(player, data, levelId),
		MaxHP = maxHP,
		Recommended = Formulas.RecommendedStrength(levelId),
	})
end

function WallService.TrySwing(player: Player, data, pos: Vector3): boolean
	local level = MapService.LevelAt(pos)
	if not level then
		return false
	end
	local prog = progressOf(data, level.Id)
	if prog >= LAYERS or not Catalog.Level(level.Id) then
		return true
	end
	local layer = level.Layers[prog + 1] :: BasePart?
	if not layer then
		return true
	end
	-- Игрок должен стоять перед текущим слоем
	local rel = layer.CFrame:PointToObjectSpace(pos)
	if math.abs(rel.Z) > layer.Size.Z / 2 + Settings.WallReach or math.abs(rel.X) > layer.Size.X / 2 + 4 then
		return true
	end

	local remaining = layerHP(player, data, level.Id) - Formulas.Damage(data)
	if remaining > 0 then
		hp[player][level.Id] = remaining
		sendLevelState(player, level.Id)
		return true
	end

	-- Слой сломан
	prog += 1
	data.LevelProgress[tostring(level.Id)] = prog
	data.Stats.LayersBroken += 1
	hp[player][level.Id] = nil
	Remotes.Event("Effect"):FireClient(player, "Break", level.Id, prog)
	OreService.Roll(player, data)
	if prog >= LAYERS then
		data.BestLevel = math.max(data.BestLevel, level.Id)
		RequestService.Notify(player, "Стена пройдена! Забери награду в нише справа →", "success")
	end
	DataService.MarkDirty(player)
	sendLevelState(player, level.Id)
	return true
end

local function claimReward(player: Player, levelId: number)
	local data = DataService.Get(player)
	local cfg = Catalog.Level(levelId)
	if not data or not cfg then
		return
	end
	if progressOf(data, levelId) < LAYERS then
		return -- стена ещё не сломана — награды нет
	end
	local mult = MonetizationService.HasPass(player, "WinsX3") and 3 or 1
	local wins = cfg.WinsReward * mult
	data.Wins += wins
	data.Stats.LevelsCleared += 1
	data.LevelProgress[tostring(levelId)] = 0 -- награда за это прохождение получена
	if hp[player] then
		hp[player][levelId] = nil
	end
	DataService.MarkDirty(player)
	Remotes.Event("Effect"):FireClient(player, "Reward", levelId, wins)
	RequestService.Notify(player, ("+%s %s!"):format(Format.Short(wins), wins == 1 and "победа" or "победы"), "wins")
	sendLevelState(player, levelId)
end

local function teleportToLobby(player: Player)
	local character = player.Character
	if character then
		character:PivotTo(MapService.SpawnCFrame())
	end
end

local function playerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model)
end

local function debounce(player: Player): boolean
	local now = os.clock()
	if padDebounce[player] and now - padDebounce[player] < 1 then
		return false
	end
	padDebounce[player] = now
	return true
end

function WallService.Init()
	for _, level in ipairs(MapService.Levels()) do
		local cfg = Catalog.Level(level.Id)
		if cfg then
			MapService.SetText(level.Sign, "Title", ("Уровень %d · %s"):format(level.Id, cfg.Name))
			MapService.SetText(level.Sign, "Sub", "Рекомендуемая сила: " .. Format.Short(Formulas.RecommendedStrength(level.Id)))
		end
		if level.RewardPad then
			local mult = "×3 с геймпассом"
			MapService.SetText(level.RewardPad, "Reward", ("+%d %s"):format(cfg and cfg.WinsReward or 1, "победа"))
			MapService.SetText(level.RewardPad, "Hint", mult)
			level.RewardPad.Touched:Connect(function(hit)
				local player = playerFromHit(hit)
				if player and debounce(player) then
					claimReward(player, level.Id)
				end
			end)
		end
		if level.LobbyPad then
			level.LobbyPad.Touched:Connect(function(hit)
				local player = playerFromHit(hit)
				if player and debounce(player) then
					teleportToLobby(player)
				end
			end)
		end
	end

	-- Следим, на каком уровне стоит игрок, и обновляем панель уровня
	task.spawn(function()
		while true do
			task.wait(0.4)
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local level = root and MapService.LevelAt(root.Position)
				local id = level and level.Id or nil
				if id ~= currentLevel[player] then
					currentLevel[player] = id
					sendLevelState(player, id)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		hp[player] = nil
		currentLevel[player] = nil
		padDebounce[player] = nil
	end)

	RequestService.Register("GoToLobby", function(player)
		teleportToLobby(player)
		return { ok = true }
	end)
end

return WallService
