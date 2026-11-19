--[[
	OreConfig — руды, которые выпадают при разрушении слоя стены.

	Chance — шанс выпадения за один разрушенный слой (0.15 = 15%), до бонуса удачи.
	Удача увеличивает все шансы: шанс × (1 + удача% / 100).
	Price  — сколько побед даёт торговец за 1 штуку.

	Проверка идёт от самой редкой руды к самой частой, выпадает максимум одна руда за слой.
]]

return {
	Ores = {
		{ Id = "ruby", Name = "Рубин", Chance = 0.0025, Price = 40, Color = Color3.fromRGB(239, 43, 74) },
		{ Id = "emerald", Name = "Изумруд", Chance = 0.008, Price = 15, Color = Color3.fromRGB(34, 199, 106) },
		{ Id = "gold", Name = "Золото", Chance = 0.025, Price = 5, Color = Color3.fromRGB(255, 200, 40) },
		{ Id = "iron", Name = "Железо", Chance = 0.06, Price = 2, Color = Color3.fromRGB(230, 200, 180) },
		{ Id = "coal", Name = "Уголь", Chance = 0.15, Price = 1, Color = Color3.fromRGB(50, 52, 60) },
	},
}
