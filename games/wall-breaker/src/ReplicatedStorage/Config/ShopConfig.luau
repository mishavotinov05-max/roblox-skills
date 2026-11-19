--[[
	ShopConfig — улучшение удачи и платные покупки (Robux).

	ВАЖНО про Robux-покупки:
	Id = 0 означает «ещё не создан». Создайте геймпасс / товар в Creator Dashboard
	(create.roblox.com › ваша игра › Monetization), скопируйте его номер и вставьте вместо 0.
	Пока Id = 0, кнопка покажет сообщение «Покупка ещё не настроена».
]]

return {
	-- Улучшение удачи за победы (влияет на шанс выпадения руд)
	Luck = {
		MaxLevel = 50,
		PercentPerLevel = 4, -- +4% удачи за уровень
		BaseCost = 10, -- цена 1-го уровня в победах
		CostGrowth = 1.35, -- каждый следующий уровень дороже в 1.35 раза
	},

	-- Геймпассы (покупаются один раз навсегда)
	GamePasses = {
		WinsX3 = { Id = 0, Name = "×3 Победы", Description = "Награда за уровень ×3", Icon = "PassWinsX3" },
		StrengthX2 = { Id = 0, Name = "×2 Сила", Description = "Вся сила за удар ×2", Icon = "PassStrengthX2" },
		LuckX2 = { Id = 0, Name = "×2 Удача", Description = "Удача ×2", Icon = "PassLuckX2" },
		AutoClick = { Id = 0, Name = "Автоклик", Description = "Кирка бьёт сама", Icon = "PassAutoClick" },
	},
	GamePassOrder = { "WinsX3", "StrengthX2", "LuckX2", "AutoClick" },

	-- Товары разработчика (можно покупать много раз)
	Products = {
		{ Key = "wins_small", Id = 0, Name = "+50 побед", Wins = 50 },
		{ Key = "wins_big", Id = 0, Name = "+500 побед", Wins = 500 },
		{ Key = "spin", Id = 0, Name = "Вращение колеса", Spins = 1 },
	},
}
