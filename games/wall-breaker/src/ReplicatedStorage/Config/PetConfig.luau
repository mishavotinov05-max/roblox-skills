--[[
	PetConfig — питомцы и яйца (как на картинках-референсах).

	Multiplier питомца — «x1.2 Силы». Надетые питомцы складываются:
	  два питомца x1.2 и x1.5 → множитель силы x2.7 (без питомцев — x1).

	Яйца:
	  Price       — цена в победах;
	  RobuxProduct — если яйцо за Robux: ключ товара из ShopConfig.Products (Price тогда не нужен);
	  Pets        — { Id питомца, шанс в процентах }.
	Модель яйца на карте: Workspace › Map › Hub › Eggs › Egg_<Id> (например Egg_chicken).

	Своя 3D-модель питомца: ReplicatedStorage › PetModels › модель с именем = Id питомца.
]]

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

return {
	Rarities = {
		["Обычный"] = rgb(170, 175, 190),
		["Редкий"] = rgb(60, 150, 255),
		["Эпический"] = rgb(170, 80, 255),
		["Легендарный"] = rgb(255, 185, 30),
		["Божественный"] = rgb(255, 60, 90),
	},

	Pets = {
		-- Куриное яйцо
		chicken = { Name = "Курица", Rarity = "Обычный", Multiplier = 1.2, Emoji = "🐔", Color = rgb(245, 245, 245) },
		chick = { Name = "Цыплёнок", Rarity = "Обычный", Multiplier = 1.5, Emoji = "🐥", Color = rgb(255, 220, 60) },
		bunny = { Name = "Кролик", Rarity = "Редкий", Multiplier = 2, Emoji = "🐰", Color = rgb(250, 240, 245) },
		fox_cub = { Name = "Лисёнок", Rarity = "Эпический", Multiplier = 3, Emoji = "🦊", Color = rgb(255, 120, 40) },
		-- Стальное яйцо
		ostrich = { Name = "Страус", Rarity = "Обычный", Multiplier = 4, Emoji = "🐦", Color = rgb(60, 50, 50) },
		boar = { Name = "Кабан", Rarity = "Редкий", Multiplier = 5.5, Emoji = "🐗", Color = rgb(140, 80, 50) },
		wolf = { Name = "Волк", Rarity = "Эпический", Multiplier = 7.5, Emoji = "🐺", Color = rgb(150, 155, 170) },
		bear = { Name = "Медведь", Rarity = "Легендарный", Multiplier = 16, Emoji = "🐻", Color = rgb(170, 100, 50) },
		-- Магическое яйцо
		magic_cat = { Name = "Маг. Кот", Rarity = "Обычный", Multiplier = 12, Emoji = "🐱", Color = rgb(170, 80, 255) },
		bat = { Name = "Летучая мышь", Rarity = "Редкий", Multiplier = 18, Emoji = "🦇", Color = rgb(90, 50, 110) },
		deer = { Name = "Олень", Rarity = "Эпический", Multiplier = 25, Emoji = "🦌", Color = rgb(240, 235, 250) },
		unicorn = { Name = "Единорог", Rarity = "Легендарный", Multiplier = 40, Emoji = "🦄", Color = rgb(255, 200, 240) },
		-- Админское яйцо
		robot = { Name = "Робот", Rarity = "Обычный", Multiplier = 50, Emoji = "🤖", Color = rgb(220, 225, 235) },
		cyber_wolf = { Name = "Кибер-Волк", Rarity = "Редкий", Multiplier = 75, Emoji = "🐺", Color = rgb(40, 200, 230) },
		mecha_dragon = { Name = "Меха-Дракон", Rarity = "Эпический", Multiplier = 100, Emoji = "🐉", Color = rgb(150, 150, 170) },
		admin_lion = { Name = "Админ-Лев", Rarity = "Легендарный", Multiplier = 150, Emoji = "🦁", Color = rgb(255, 200, 60) },
		-- Божественное яйцо (Robux)
		angel_fox = { Name = "Ангел-Лис", Rarity = "Обычный", Multiplier = 200, Emoji = "🦊", Color = rgb(255, 220, 170) },
		light_deer = { Name = "Свет. Олень", Rarity = "Редкий", Multiplier = 300, Emoji = "🦌", Color = rgb(255, 250, 230) },
		winged_wolf = { Name = "Крыл. Волк", Rarity = "Эпический", Multiplier = 500, Emoji = "🐺", Color = rgb(220, 225, 255) },
		archangel = { Name = "Архангел", Rarity = "Легендарный", Multiplier = 750, Emoji = "🦅", Color = rgb(255, 215, 90) },
		-- Дьявольское яйцо (Robux)
		hell_dog = { Name = "Адский Пёс", Rarity = "Обычный", Multiplier = 250, Emoji = "🐕", Color = rgb(70, 30, 30) },
		fire_bull = { Name = "Огн. Бык", Rarity = "Редкий", Multiplier = 400, Emoji = "🐂", Color = rgb(200, 50, 30) },
		demon_wolf = { Name = "Демон-Волк", Rarity = "Эпический", Multiplier = 600, Emoji = "🐺", Color = rgb(90, 20, 30) },
		devil_dragon = { Name = "Дьявол-Дракон", Rarity = "Божественный", Multiplier = 1000, Emoji = "🐲", Color = rgb(220, 30, 40) },
	},

	Eggs = {
		{ Id = "chicken", Name = "Куриное яйцо", Tag = "Обычное", Price = 20, Color = rgb(255, 140, 40),
			Pets = { { "chicken", 50 }, { "chick", 30 }, { "bunny", 15 }, { "fox_cub", 5 } } },
		{ Id = "steel", Name = "Стальное яйцо", Tag = "Редкое", Price = 250, Color = rgb(40, 120, 255),
			Pets = { { "ostrich", 50 }, { "boar", 30 }, { "wolf", 15 }, { "bear", 5 } } },
		{ Id = "magic", Name = "Магическое яйцо", Tag = "Эпическое", Price = 1000, Color = rgb(170, 60, 255),
			Pets = { { "magic_cat", 50 }, { "bat", 30 }, { "deer", 15 }, { "unicorn", 5 } } },
		{ Id = "admin", Name = "Админское яйцо", Tag = "Легендарное", Price = 2000, Color = rgb(255, 170, 20),
			Pets = { { "robot", 50 }, { "cyber_wolf", 30 }, { "mecha_dragon", 15 }, { "admin_lion", 5 } } },
		{ Id = "divine", Name = "Божественное яйцо", Tag = "Божественное", RobuxProduct = "egg_divine", RobuxPrice = 199, Color = rgb(150, 120, 255),
			Pets = { { "angel_fox", 50 }, { "light_deer", 30 }, { "winged_wolf", 15 }, { "archangel", 5 } } },
		{ Id = "devil", Name = "Дьявольское яйцо", Tag = "Божественное", RobuxProduct = "egg_devil", RobuxPrice = 250, Color = rgb(230, 30, 50),
			Pets = { { "hell_dog", 50 }, { "fire_bull", 30 }, { "demon_wolf", 15 }, { "devil_dragon", 5 } } },
	},
}
