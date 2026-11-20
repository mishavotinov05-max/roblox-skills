--[[
	ShopConfig — удача и платные покупки (Robux).

	УДАЧА увеличивает шанс выпадения руд: шанс × (1 + удача% / 100).
	В магазине несколько вариантов удачи. Каждый можно покупать много раз,
	после каждой покупки он дорожает в CostGrowth раз.

	ВАЖНО про Robux-покупки:
	Id = 0 означает «ещё не создан». Создайте геймпасс / товар в Creator Dashboard
	(create.roblox.com › ваша игра › Monetization), скопируйте его номер и вставьте вместо 0.
	Пока Id = 0, кнопка покажет сообщение «Покупка ещё не настроена».
]]

return {
	Luck = {
		MaxPercent = 500, -- максимум удачи в процентах
		CostGrowth = 1.3,
		Offers = {
			{ Id = "small", Name = "Малая удача", Percent = 5, Price = 10, Emoji = "🍀" },
			{ Id = "medium", Name = "Средняя удача", Percent = 15, Price = 25, Emoji = "🍀" },
			{ Id = "big", Name = "Большая удача", Percent = 40, Price = 60, Emoji = "🌟" },
			{ Id = "mega", Name = "Мега удача", Percent = 100, Price = 140, Emoji = "💎" },
		},
	},

	-- Геймпассы (покупаются один раз навсегда)
	GamePasses = {
		WinsX3 = { Id = 0, Name = "×3 Победы", Description = "Награда за уровни всегда ×3", Icon = "PassWinsX3" },
		StrengthX2 = { Id = 0, Name = "×2 Сила", Description = "Вся сила за удар ×2", Icon = "PassStrengthX2" },
		LuckX2 = { Id = 0, Name = "×2 Удача", Description = "Удача ×2", Icon = "PassLuckX2" },
		AutoClick = { Id = 0, Name = "Автоклик", Description = "Кирка бьёт сама", Icon = "PassAutoClick" },
	},
	GamePassOrder = { "WinsX3", "StrengthX2", "LuckX2", "AutoClick" },

	-- Товары разработчика (можно покупать много раз)
	-- Hidden = true — не показывается в магазине (покупается через отдельную кнопку в игре)
	Products = {
		{ Key = "wins_small", Id = 0, Name = "+50 побед", Wins = 50 },
		{ Key = "wins_big", Id = 0, Name = "+500 побед", Wins = 500 },
		{ Key = "luck_robux", Id = 0, Name = "+50% удачи", LuckPercent = 50 },
		{ Key = "spin", Id = 0, Name = "Вращение колеса", Spins = 1 },
		{ Key = "level_x3", Id = 0, Name = "×3 награда за уровень", Hidden = true },
		-- Пакеты опыта (кнопки под полосой уровня). XpFactor — сколько «уровней» опыта:
		-- опыт = опыт, нужный для текущего уровня × XpFactor
		{ Key = "xp_small", Id = 0, Name = "Опыт: малый", XpFactor = 0.5, Hidden = true },
		{ Key = "xp_medium", Id = 0, Name = "Опыт: средний", XpFactor = 3, Hidden = true },
		{ Key = "xp_big", Id = 0, Name = "Опыт: большой", XpFactor = 15, Hidden = true },
		-- Яйца за Robux (PetConfig → RobuxProduct)
		{ Key = "egg_divine", Id = 0, Name = "Божественное яйцо", Hidden = true },
		{ Key = "egg_devil", Id = 0, Name = "Дьявольское яйцо", Hidden = true },
	},
}
