--[[
	PetConfig — питомцы и яйца.

	Bonus питомца — прибавка к множителю силы.
	Пример: надеты 2 питомца с Bonus 0.5 и 1 → множитель = 1 + 0.5 + 1 = 2.5.

	Яйца: Price — цена в победах, Pets — кто может выпасть и с каким весом.
	Шанс = вес / сумма весов в этом яйце.
	Модель яйца на карте: Workspace › Hub › Eggs › Egg_<Id> (например Egg_common).

	Своя 3D-модель питомца: положите модель в ReplicatedStorage › PetModels
	и назовите её так же, как Id питомца (например "dog"). Иначе будет простой шарик.
]]

return {
	Pets = {
		dog = { Name = "Пёсик", Rarity = "Обычный", Bonus = 0.2, Color = Color3.fromRGB(214, 160, 102) },
		cat = { Name = "Котик", Rarity = "Обычный", Bonus = 0.3, Color = Color3.fromRGB(255, 190, 120) },
		bunny = { Name = "Зайка", Rarity = "Необычный", Bonus = 0.5, Color = Color3.fromRGB(240, 240, 255) },
		fox = { Name = "Лис", Rarity = "Редкий", Bonus = 1, Color = Color3.fromRGB(255, 120, 40) },
		owl = { Name = "Сова", Rarity = "Редкий", Bonus = 1.5, Color = Color3.fromRGB(150, 110, 80) },
		dragon = { Name = "Дракончик", Rarity = "Эпический", Bonus = 3, Color = Color3.fromRGB(166, 91, 255) },
		unicorn = { Name = "Единорог", Rarity = "Эпический", Bonus = 4, Color = Color3.fromRGB(255, 160, 230) },
		phoenix = { Name = "Феникс", Rarity = "Легендарный", Bonus = 8, Color = Color3.fromRGB(255, 90, 31) },
	},

	Eggs = {
		{
			Id = "common",
			Name = "Обычное яйцо",
			Price = 10,
			Pets = { { "dog", 50 }, { "cat", 35 }, { "bunny", 15 } },
		},
		{
			Id = "rare",
			Name = "Редкое яйцо",
			Price = 75,
			Pets = { { "bunny", 45 }, { "fox", 35 }, { "owl", 20 } },
		},
		{
			Id = "epic",
			Name = "Эпическое яйцо",
			Price = 400,
			Pets = { { "owl", 50 }, { "dragon", 32 }, { "unicorn", 15 }, { "phoenix", 3 } },
		},
	},
}
