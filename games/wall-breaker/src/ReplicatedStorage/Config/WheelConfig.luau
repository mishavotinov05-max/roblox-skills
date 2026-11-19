--[[
	WheelConfig — колесо фортуны.

	Cooldown — через сколько секунд даётся бесплатное вращение.
	Prizes   — сектора колеса по кругу (по часовой стрелке, начиная сверху).
	  Type: "Wins" (победы), "StrengthPercent" (+% к текущей силе), "Luck" (уровни удачи),
	        "Aura" (аура по Id из AuraConfig).
	  Weight — вес шанса (больше = чаще).
]]

return {
	Cooldown = 15 * 60,
	Prizes = {
		{ Text = "+5 побед", Type = "Wins", Amount = 5, Weight = 30, Color = Color3.fromRGB(255, 77, 109) },
		{ Text = "+25% силы", Type = "StrengthPercent", Amount = 25, Weight = 22, Color = Color3.fromRGB(255, 210, 63) },
		{ Text = "+15 побед", Type = "Wins", Amount = 15, Weight = 15, Color = Color3.fromRGB(61, 220, 132) },
		{ Text = "+1 удача", Type = "Luck", Amount = 1, Weight = 12, Color = Color3.fromRGB(63, 169, 255) },
		{ Text = "+50 побед", Type = "Wins", Amount = 50, Weight = 6, Color = Color3.fromRGB(166, 91, 255) },
		{ Text = "+100% силы", Type = "StrengthPercent", Amount = 100, Weight = 8, Color = Color3.fromRGB(255, 138, 61) },
		{ Text = "Аура Радуга", Type = "Aura", AuraId = "rainbow", Weight = 2, Color = Color3.fromRGB(255, 95, 210) },
		{ Text = "+3 удачи", Type = "Luck", Amount = 3, Weight = 5, Color = Color3.fromRGB(51, 224, 208) },
	},
}
