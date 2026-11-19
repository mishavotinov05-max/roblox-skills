--[[
	PickaxeConfig — кирки.

	Price  — цена в победах (0 = выдаётся бесплатно).
	Power  — множитель силы за удар в яме (чем больше, тем быстрее качаешься).
	Color / HandleColor — цвет кирки в руках игрока.

	Порядок в списке = порядок мест в магазине:
	1-я кирка стоит на месте Slot_01, 2-я — на Slot_02 и т.д.
	(Workspace › Hub › PickaxeShop › Slots).
	Чтобы добавить кирку: допишите строку и скопируйте модель Slot_12 → Slot_13.
]]

return {
	Pickaxes = {
		{ Id = "wood", Name = "Деревянная", Price = 0, Power = 1, Color = Color3.fromRGB(217, 160, 102), HandleColor = Color3.fromRGB(107, 63, 29) },
		{ Id = "stone", Name = "Каменная", Price = 5, Power = 2, Color = Color3.fromRGB(195, 200, 210), HandleColor = Color3.fromRGB(168, 106, 60) },
		{ Id = "copper", Name = "Медная", Price = 15, Power = 3, Color = Color3.fromRGB(255, 178, 122), HandleColor = Color3.fromRGB(168, 106, 60) },
		{ Id = "iron", Name = "Железная", Price = 40, Power = 5, Color = Color3.fromRGB(241, 244, 250), HandleColor = Color3.fromRGB(168, 106, 60) },
		{ Id = "gold", Name = "Золотая", Price = 100, Power = 8, Color = Color3.fromRGB(255, 216, 77), HandleColor = Color3.fromRGB(168, 106, 60) },
		{ Id = "emerald", Name = "Изумрудная", Price = 250, Power = 12, Color = Color3.fromRGB(109, 255, 168), HandleColor = Color3.fromRGB(168, 106, 60) },
		{ Id = "ruby", Name = "Рубиновая", Price = 600, Power = 18, Color = Color3.fromRGB(255, 122, 140), HandleColor = Color3.fromRGB(168, 106, 60) },
		{ Id = "diamond", Name = "Алмазная", Price = 1500, Power = 27, Color = Color3.fromRGB(159, 248, 255), HandleColor = Color3.fromRGB(168, 106, 60) },
		{ Id = "obsidian", Name = "Обсидиановая", Price = 4000, Power = 40, Color = Color3.fromRGB(138, 92, 255), HandleColor = Color3.fromRGB(59, 42, 85) },
		{ Id = "netherite", Name = "Незеритовая", Price = 10000, Power = 60, Color = Color3.fromRGB(106, 80, 84), HandleColor = Color3.fromRGB(59, 42, 46) },
		{ Id = "crystal", Name = "Кристальная", Price = 25000, Power = 90, Color = Color3.fromRGB(255, 176, 240), HandleColor = Color3.fromRGB(138, 92, 255) },
		{ Id = "rainbow", Name = "Радужная", Price = 60000, Power = 135, Color = Color3.fromRGB(255, 225, 77), HandleColor = Color3.fromRGB(94, 231, 255) },
	},
}
