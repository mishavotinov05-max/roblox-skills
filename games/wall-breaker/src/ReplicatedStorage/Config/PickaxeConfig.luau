--[[
	PickaxeConfig — кирки (коллекция из 16 кирок).

	Price  — цена в победах (0 = выдаётся бесплатно).
	Power  — множитель силы («x1 Силы», «x150 Силы»).
	Rarity — редкость (только для подписи и цвета).
	Color / HandleColor — цвет головки и рукояти.
	Effect — эффект редкости: shine, glow, ice, fire, electric, cosmic, angel, shadow, devil (или нет).
	Accent — цвет свечения/эффекта.
	Image  — картинка кирки (PNG без фона, art/pickaxes/<Id>.png → загрузить в Roblox → вставить ID).
	         Если Image задан, кирка в руке, на спине и на витрине показывается этой картинкой — точь-в-точь как нарисована.
	Внешний вид кирки собирается в ReplicatedStorage › Shared › PickaxeLook (размеры, изгиб, детали).

	Порядок в списке = порядок мест в магазине на карте:
	1-я кирка стоит на месте Slot_01, 2-я — на Slot_02 и т.д.
	(Workspace › Map › Hub › PickaxeShop › Slots).
	Чтобы добавить кирку: допишите строку и скопируйте модель Slot_16 → Slot_17.
]]

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

return {
	Rarities = {
		["Обычная"] = rgb(190, 195, 210),
		["Редкая"] = rgb(70, 160, 255),
		["Эпическая"] = rgb(170, 90, 255),
		["Легендарная"] = rgb(255, 190, 40),
		["Божественная"] = rgb(255, 60, 80),
	},
	Pickaxes = {
		{ Id = "wood", Image = "rbxassetid://0", Name = "Деревянная", Rarity = "Обычная", Price = 0, Power = 1, Color = rgb(205, 140, 80), HandleColor = rgb(107, 63, 29) },
		{ Id = "stone", Image = "rbxassetid://0", Name = "Каменная", Rarity = "Обычная", Price = 5, Power = 1.3, Color = rgb(190, 195, 205), HandleColor = rgb(140, 90, 50) },
		{ Id = "copper", Image = "rbxassetid://0", Name = "Медная", Rarity = "Обычная", Price = 15, Power = 1.7, Color = rgb(230, 130, 70), HandleColor = rgb(140, 90, 50) },
		{ Id = "iron", Image = "rbxassetid://0", Name = "Железная", Rarity = "Редкая", Price = 40, Power = 2.5, Color = rgb(235, 240, 250), HandleColor = rgb(140, 90, 50), Effect = "shine", Accent = rgb(150, 210, 255) },
		{ Id = "steel", Image = "rbxassetid://0", Name = "Стальная", Rarity = "Редкая", Price = 100, Power = 3.5, Color = rgb(150, 165, 185), HandleColor = rgb(90, 60, 40), Effect = "shine", Accent = rgb(120, 190, 255) },
		{ Id = "gold", Image = "rbxassetid://0", Name = "Золотая", Rarity = "Эпическая", Price = 250, Power = 5, Color = rgb(255, 210, 60), HandleColor = rgb(140, 90, 50), Effect = "glow", Accent = rgb(255, 240, 150) },
		{ Id = "diamond", Image = "rbxassetid://0", Name = "Алмазная", Rarity = "Эпическая", Price = 600, Power = 7.5, Color = rgb(110, 240, 255), HandleColor = rgb(140, 90, 50), Effect = "glow", Accent = rgb(200, 255, 255) },
		{ Id = "emerald", Image = "rbxassetid://0", Name = "Изумрудная", Rarity = "Эпическая", Price = 1500, Power = 10, Color = rgb(70, 230, 120), HandleColor = rgb(140, 90, 50), Effect = "glow", Accent = rgb(170, 255, 190) },
		{ Id = "obsidian", Image = "rbxassetid://0", Name = "Обсидиановая", Rarity = "Легендарная", Price = 4000, Power = 15, Color = rgb(130, 70, 220), HandleColor = rgb(60, 40, 80), Effect = "glow", Accent = rgb(200, 120, 255) },
		{ Id = "ice", Image = "rbxassetid://0", Name = "Ледяная", Rarity = "Легендарная", Price = 10000, Power = 20, Color = rgb(160, 230, 255), HandleColor = rgb(90, 130, 170), Effect = "ice", Accent = rgb(210, 245, 255) },
		{ Id = "fire", Image = "rbxassetid://0", Name = "Огненная", Rarity = "Легендарная", Price = 25000, Power = 30, Color = rgb(255, 110, 30), HandleColor = rgb(90, 40, 20), Effect = "fire", Accent = rgb(255, 220, 80) },
		{ Id = "electric", Image = "rbxassetid://0", Name = "Электрическая", Rarity = "Легендарная", Price = 60000, Power = 40, Color = rgb(80, 200, 255), HandleColor = rgb(40, 60, 110), Effect = "electric", Accent = rgb(160, 240, 255) },
		{ Id = "cosmic", Image = "rbxassetid://0", Name = "Космическая", Rarity = "Божественная", Price = 150000, Power = 60, Color = rgb(150, 110, 255), HandleColor = rgb(40, 30, 90), Effect = "cosmic", Accent = rgb(255, 140, 255) },
		{ Id = "angel", Image = "rbxassetid://0", Name = "Ангельская", Rarity = "Божественная", Price = 400000, Power = 80, Color = rgb(255, 240, 200), HandleColor = rgb(230, 190, 90), Effect = "angel", Accent = rgb(255, 215, 90) },
		{ Id = "shadow", Image = "rbxassetid://0", Name = "Теневая", Rarity = "Божественная", Price = 1000000, Power = 100, Color = rgb(90, 40, 140), HandleColor = rgb(30, 20, 40), Effect = "shadow", Accent = rgb(190, 90, 255) },
		{ Id = "devil", Image = "rbxassetid://0", Name = "Дьявольская", Rarity = "Божественная", Price = 2500000, Power = 150, Color = rgb(220, 30, 40), HandleColor = rgb(40, 15, 15), Effect = "devil", Accent = rgb(255, 80, 40) },
	},
}
