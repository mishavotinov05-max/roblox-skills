--[[
	AuraConfig — ауры (свечение вокруг игрока).
	Price      — цена в победах (0 = купить нельзя, только из колеса фортуны).
	Multiplier — множитель силы, пока аура надета (надета может быть одна).
]]

return {
	Auras = {
		{ Id = "spark", Name = "Искра", Price = 30, Multiplier = 1.2, Color = Color3.fromRGB(255, 225, 77) },
		{ Id = "frost", Name = "Иней", Price = 150, Multiplier = 1.5, Color = Color3.fromRGB(94, 231, 255) },
		{ Id = "flame", Name = "Пламя", Price = 600, Multiplier = 2, Color = Color3.fromRGB(255, 106, 42) },
		{ Id = "void", Name = "Бездна", Price = 2500, Multiplier = 3, Color = Color3.fromRGB(166, 91, 255) },
		{ Id = "rainbow", Name = "Радуга", Price = 0, Multiplier = 4, Color = Color3.fromRGB(255, 95, 210) }, -- только из колеса
	},
}
