--[[
	RewardsConfig — ежедневные награды, ежедневные задания и достижения.

	Stat — какая статистика считается:
	  "Swings" удары в ямах, "LayersBroken" разрушенные слои, "LevelsCleared" пройденные уровни,
	  "EggsOpened" открытые яйца, "OresSold" проданные руды, "Rebirths" перерождения.
	Goal   — сколько нужно.
	Reward — сколько побед дать.
]]

return {
	-- Награда за вход: день 1, день 2 … (после 7-го дня цикл повторяется)
	DailyRewards = { 2, 3, 5, 8, 10, 15, 30 },

	-- Задания обновляются каждый день (по UTC)
	DailyQuests = {
		{ Id = "q_swings", Text = "Сделай 300 ударов в яме", Stat = "Swings", Goal = 300, Reward = 3 },
		{ Id = "q_layers", Text = "Разрушь 30 слоёв стены", Stat = "LayersBroken", Goal = 30, Reward = 5 },
		{ Id = "q_eggs", Text = "Открой 2 яйца", Stat = "EggsOpened", Goal = 2, Reward = 4 },
	},

	Achievements = {
		{ Id = "a_swing1", Text = "1 000 ударов в яме", Stat = "Swings", Goal = 1000, Reward = 5 },
		{ Id = "a_swing2", Text = "10 000 ударов в яме", Stat = "Swings", Goal = 10000, Reward = 30 },
		{ Id = "a_layers1", Text = "Разрушь 100 слоёв", Stat = "LayersBroken", Goal = 100, Reward = 10 },
		{ Id = "a_levels1", Text = "Пройди 10 уровней", Stat = "LevelsCleared", Goal = 10, Reward = 10 },
		{ Id = "a_levels2", Text = "Пройди 100 уровней", Stat = "LevelsCleared", Goal = 100, Reward = 60 },
		{ Id = "a_eggs1", Text = "Открой 10 яиц", Stat = "EggsOpened", Goal = 10, Reward = 15 },
		{ Id = "a_rebirth1", Text = "Первое перерождение", Stat = "Rebirths", Goal = 1, Reward = 10 },
		{ Id = "a_rebirth2", Text = "10 перерождений", Stat = "Rebirths", Goal = 10, Reward = 100 },
	},
}
