--[[
	DataService — загрузка, хранение и сохранение данных игроков (DataStoreService).

	Чтобы сохранение работало в Studio: Home › Game Settings › Security ›
	включите «Enable Studio Access to API Services» (игра должна быть опубликована).
]]
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("GameSettings"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Format = require(Shared:WaitForChild("Format"))

local DataService = {}

local profiles: { [Player]: any } = {}
local dirty: { [Player]: boolean } = {}
local loadedCallbacks = {}
local stateHooks = {}

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Settings.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore недоступен, прогресс не будет сохраняться:", result)
	end
end

-- Шаблон данных нового игрока. Новые поля можно добавлять — у старых игроков они появятся сами.
local function makeTemplate()
	return {
		Version = 1,
		Wins = Settings.StartWins,
		Strength = Settings.StartStrength,
		Rebirths = 0,
		PlayerLevel = 1, -- уровень игрока (качается в ямах)
		Xp = 0,
		LuckPercent = 0, -- купленная удача в процентах
		LuckBought = {}, -- { [offerId] = сколько раз куплено }
		PendingX3Level = 0,
		OwnedPickaxes = { [Settings.StartPickaxe] = true },
		EquippedPickaxe = Settings.StartPickaxe,
		Pets = {}, -- { {Uid = 1, Id = "dog"}, ... }
		EquippedPets = {}, -- { Uid, Uid, ... }
		NextPetUid = 1,
		Auras = {}, -- { [auraId] = true }
		EquippedAura = "",
		Ores = {}, -- { [oreId] = количество }
		LevelProgress = {}, -- { ["1"] = сломано слоёв }
		BestLevel = 0,
		Stats = { Swings = 0, LayersBroken = 0, LevelsCleared = 0, EggsOpened = 0, OresSold = 0, Rebirths = 0 },
		Daily = { LastClaim = 0, Streak = 0 },
		Quests = { Day = -1, Base = {}, Claimed = {} },
		Achievements = {}, -- { [id] = true }
		Wheel = { LastFree = 0, ExtraSpins = 0 },
		Purchases = {}, -- { [PurchaseId] = время }
		Settings = { AutoClick = true, ShowPets = true, Graphics = "High" },
	}
end

local function deepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in pairs(t) do
		c[k] = deepCopy(v)
	end
	return c
end

local function isArray(t)
	return type(t) == "table" and #t > 0
end

local function reconcile(target, template)
	for k, v in pairs(template) do
		if target[k] == nil then
			target[k] = deepCopy(v)
		elseif type(v) == "table" and type(target[k]) == "table" and not isArray(v) and next(v) ~= nil then
			reconcile(target[k], v)
		end
	end
end

local function makeLeaderstats(player: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local wins = Instance.new("IntValue")
	wins.Name = "Победы"
	wins.Parent = ls
	local strength = Instance.new("StringValue")
	strength.Name = "Сила"
	strength.Parent = ls
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Перерождения"
	rebirths.Parent = ls
	ls.Parent = player
end

local function updateLeaderstats(player: Player, data)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		return
	end
	local wins = ls:FindFirstChild("Победы") :: IntValue?
	local strength = ls:FindFirstChild("Сила") :: StringValue?
	local rebirths = ls:FindFirstChild("Перерождения") :: IntValue?
	if wins then
		wins.Value = math.min(data.Wins, 2 ^ 53)
	end
	if strength then
		strength.Value = Format.Short(data.Strength)
	end
	if rebirths then
		rebirths.Value = data.Rebirths
	end
end

-- Тестовый режим: бесконечные победы и сила (см. GameSettings.Infinite)
function DataService.IsInfinite(player: Player): boolean
	local inf = Settings.Infinite
	if not inf then
		return false
	end
	if inf.InStudio and RunService:IsStudio() then
		return true
	end
	if inf.ForOwner and game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return table.find(inf.UserIds or {}, player.UserId) ~= nil
end

function DataService.Get(player: Player)
	return profiles[player]
end

function DataService.MarkDirty(player: Player)
	if profiles[player] then
		dirty[player] = true
	end
end

-- Сервисы добавляют в отправляемое клиенту состояние свои поля
function DataService.AddStateHook(fn)
	table.insert(stateHooks, fn)
end

-- Вызвать fn(player, data), когда данные игрока загружены
function DataService.OnLoaded(fn)
	table.insert(loadedCallbacks, fn)
	for player, data in pairs(profiles) do
		task.spawn(fn, player, data)
	end
end

function DataService.AddWins(player: Player, amount: number)
	local data = profiles[player]
	if data then
		data.Wins += amount
		DataService.MarkDirty(player)
	end
end

function DataService.AddStat(player: Player, stat: string, amount: number)
	local data = profiles[player]
	if data then
		data.Stats[stat] = (data.Stats[stat] or 0) + amount
	end
end

local function push(player: Player)
	local data = profiles[player]
	if not data then
		return
	end
	local state = { Data = data, ServerTime = os.time() }
	for _, hook in ipairs(stateHooks) do
		local ok, err = pcall(hook, player, state, data)
		if not ok then
			warn("[DataService] state hook:", err)
		end
	end
	Remotes.Event("DataUpdate"):FireClient(player, state)
	updateLeaderstats(player, data)
end

function DataService.Load(player: Player)
	local key = "u_" .. player.UserId
	local data = nil
	local loadedOk = store == nil -- без DataStore работаем с пустыми данными
	if store then
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return (store :: DataStore):GetAsync(key)
			end)
			if ok then
				data = result
				loadedOk = true
				break
			end
			warn(("[DataService] Загрузка %s, попытка %d: %s"):format(player.Name, attempt, tostring(result)))
			task.wait(2)
		end
	end
	if not loadedOk then
		-- Не перезаписываем сохранение пустыми данными
		player:Kick("Не удалось загрузить прогресс. Пожалуйста, перезайдите.")
		return
	end
	if not player.Parent then
		return
	end
	if type(data) ~= "table" then
		data = makeTemplate()
		if RunService:IsStudio() and Settings.StudioTestWins > 0 then
			data.Wins = Settings.StudioTestWins
		end
	end
	reconcile(data, makeTemplate())
	-- перенос старой удачи (уровни → проценты)
	if type(data.LuckLevel) == "number" and data.LuckLevel > 0 then
		data.LuckPercent += data.LuckLevel * 4
		data.LuckLevel = nil
	end
	profiles[player] = data
	if DataService.IsInfinite(player) then
		player:SetAttribute("Infinite", true)
		data.Wins = math.max(data.Wins, Settings.Infinite.Amount)
		data.Strength = math.max(data.Strength, Settings.Infinite.Amount)
	end
	makeLeaderstats(player)
	for _, cb in ipairs(loadedCallbacks) do
		task.spawn(cb, player, data)
	end
	DataService.MarkDirty(player)
end

function DataService.Save(player: Player): boolean
	local data = profiles[player]
	if not data or not store or player:GetAttribute("Infinite") then
		return false -- тестовые игроки с бесконечными ресурсами не сохраняются
	end
	local key = "u_" .. player.UserId
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(key, function()
				return data
			end)
		end)
		if ok then
			return true
		end
		warn(("[DataService] Сохранение %s, попытка %d: %s"):format(player.Name, attempt, tostring(err)))
		task.wait(1)
	end
	return false
end

function DataService.Init()
	Players.PlayerAdded:Connect(DataService.Load)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(DataService.Load, p)
	end

	Players.PlayerRemoving:Connect(function(player)
		DataService.Save(player)
		profiles[player] = nil
		dirty[player] = nil
	end)

	game:BindToClose(function()
		local pending = 0
		for player in pairs(profiles) do
			pending += 1
			task.spawn(function()
				DataService.Save(player)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.2)
		end
	end)

	-- Отправка изменений клиенту не чаще 5 раз в секунду
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.2 then
			return
		end
		acc = 0
		for player in pairs(dirty) do
			dirty[player] = nil
			push(player)
		end
	end)

	-- Бесконечные ресурсы: пополняем
	task.spawn(function()
		while true do
			task.wait(1)
			for player, data in pairs(profiles) do
				if player:GetAttribute("Infinite") then
					if data.Wins < Settings.Infinite.Amount or data.Strength < Settings.Infinite.Amount then
						data.Wins = math.max(data.Wins, Settings.Infinite.Amount)
						data.Strength = math.max(data.Strength, Settings.Infinite.Amount)
						DataService.MarkDirty(player)
					end
				end
			end
		end
	end)

	-- Автосохранение
	task.spawn(function()
		while true do
			task.wait(Settings.AutoSaveInterval)
			for player in pairs(profiles) do
				task.spawn(DataService.Save, player)
			end
		end
	end)
end

return DataService
