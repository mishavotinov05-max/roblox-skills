--[[
	DailyService — ежедневные награды, ежедневные задания и достижения (RewardsConfig).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local RewardsConfig = require(Config:WaitForChild("RewardsConfig"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RequestService = require(Services:WaitForChild("RequestService"))

local DailyService = {}
local DAY = 86400

local function today(): number
	return math.floor(os.time() / DAY)
end

-- Каждый новый день задания начинаются с нуля (запоминаем статистику на начало дня)
local function ensureQuestDay(data)
	if data.Quests.Day ~= today() then
		data.Quests.Day = today()
		data.Quests.Base = table.clone(data.Stats)
		data.Quests.Claimed = {}
	end
end

local function questProgress(data, quest): number
	return (data.Stats[quest.Stat] or 0) - (data.Quests.Base[quest.Stat] or 0)
end

function DailyService.Init()
	RequestService.Register("ClaimDaily", function(player)
		local data = DataService.Get(player)
		local now = os.time()
		local since = now - data.Daily.LastClaim
		if since < DAY then
			return { ok = false, msg = "Следующая награда через " .. Format.Time(DAY - since) }
		end
		local streak = (since < DAY * 2) and data.Daily.Streak + 1 or 1
		local list = RewardsConfig.DailyRewards
		local reward = list[((streak - 1) % #list) + 1]
		data.Daily.LastClaim = now
		data.Daily.Streak = streak
		data.Wins += reward
		DataService.MarkDirty(player)
		RequestService.Notify(player, ("День %d: +%s побед"):format(streak, Format.Short(reward)), "wins")
		return { ok = true }
	end)

	RequestService.Register("ClaimQuest", function(player, id)
		local data = DataService.Get(player)
		ensureQuestDay(data)
		for _, quest in ipairs(RewardsConfig.DailyQuests) do
			if quest.Id == id then
				if data.Quests.Claimed[id] then
					return { ok = false, msg = "Уже получено" }
				end
				if questProgress(data, quest) < quest.Goal then
					return { ok = false, msg = "Задание ещё не выполнено" }
				end
				data.Quests.Claimed[id] = true
				data.Wins += quest.Reward
				DataService.MarkDirty(player)
				RequestService.Notify(player, ("Задание выполнено: +%s побед"):format(Format.Short(quest.Reward)), "wins")
				return { ok = true }
			end
		end
		return { ok = false }
	end)

	RequestService.Register("ClaimAchievement", function(player, id)
		local data = DataService.Get(player)
		for _, ach in ipairs(RewardsConfig.Achievements) do
			if ach.Id == id then
				if data.Achievements[id] then
					return { ok = false, msg = "Уже получено" }
				end
				if (data.Stats[ach.Stat] or 0) < ach.Goal then
					return { ok = false, msg = "Ещё не выполнено" }
				end
				data.Achievements[id] = true
				data.Wins += ach.Reward
				DataService.MarkDirty(player)
				RequestService.Notify(player, ("Достижение: +%s побед"):format(Format.Short(ach.Reward)), "wins")
				return { ok = true }
			end
		end
		return { ok = false }
	end)

	DataService.OnLoaded(function(player, data)
		ensureQuestDay(data)
		DataService.MarkDirty(player)
	end)

	DataService.AddStateHook(function(_, state, data)
		ensureQuestDay(data)
		local quests = {}
		for _, quest in ipairs(RewardsConfig.DailyQuests) do
			quests[quest.Id] = math.max(0, questProgress(data, quest))
		end
		state.QuestProgress = quests
		state.QuestResetIn = (today() + 1) * DAY - os.time()
		state.DailyReadyIn = math.max(0, DAY - (os.time() - data.Daily.LastClaim))
	end)
end

return DailyService
