--[[
	LevelConfig — уровни (стены).

	Как устроено:
	• В каждом уровне LayersPerLevel слоёв. Слои ломаются по очереди.
	• Прочность слоя = BaseHP уровня × (1 + (номер слоя − 1) × LayerHPStep).
	• Урон за удар = Сила игрока.
	• «Рекомендуемая сила» = BaseHP / TargetHitsPerLayer (столько ударов уйдёт на слой).
	• Когда стена уровня сломана, игрок выбирает:
	    «+награда и в лобби» (бесплатно) или «×3 награды и в лобби» (за Robux),
	  либо идёт дальше — на следующем уровне награда больше.
	  Награда = WinsReward самого дальнего пройденного уровня.
	  С геймпассом «×3 Победы» бесплатная кнопка сразу даёт ×3.

	Чтобы добавить уровень 11:
	1) добавьте строку в Levels ниже (Id = 11);
	2) в Workspace › Levels скопируйте папку Level_10, назовите Level_11
	   и передвиньте её дальше по прямой (инструмент Move).
]]

return {
	LayersPerLevel = 10,
	LayerHPStep = 0.12, -- каждый следующий слой на 12% прочнее предыдущего
	TargetHitsPerLayer = 4,

	Levels = {
		{ Id = 1, Name = "Сено", BaseHP = 20, WinsReward = 1 },
		{ Id = 2, Name = "Дерево", BaseHP = 120, WinsReward = 3 },
		{ Id = 3, Name = "Уголь", BaseHP = 600, WinsReward = 6 },
		{ Id = 4, Name = "Камень", BaseHP = 3000, WinsReward = 15 },
		{ Id = 5, Name = "Медь", BaseHP = 14000, WinsReward = 25 },
		{ Id = 6, Name = "Железо", BaseHP = 60000, WinsReward = 40 },
		{ Id = 7, Name = "Золото", BaseHP = 250000, WinsReward = 67 },
		{ Id = 8, Name = "Обсидиан", BaseHP = 1000000, WinsReward = 75 },
		{ Id = 9, Name = "Алмаз", BaseHP = 4000000, WinsReward = 100 },
		{ Id = 10, Name = "Незерит", BaseHP = 16000000, WinsReward = 130 },
	},
}
