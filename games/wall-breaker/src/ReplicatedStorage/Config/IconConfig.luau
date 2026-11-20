--[[
	IconConfig — картинки для кнопок интерфейса.

	Пока здесь "rbxassetid://0", кнопки показывают эмодзи-заглушку.
	Как поставить настоящие иконки (из папки art/icons):
	1) Studio › View › Asset Manager › Bulk Import → выберите PNG-файлы.
	2) Правый клик по картинке в Asset Manager › Copy Asset ID.
	3) Вставьте сюда вместо 0, например "rbxassetid://1234567890".
]]

return {
	-- Слева 2×2 (фон-плитка и символ отдельно — символ анимируется)
	ShopTile = "rbxassetid://0", -- layer_tile_shop.png
	ShopSymbol = "rbxassetid://0", -- layer_sym_shop.png
	PetsTile = "rbxassetid://0", -- layer_tile_pets.png
	PetsSymbol = "rbxassetid://0", -- layer_sym_pets.png
	AurasTile = "rbxassetid://0", -- layer_tile_auras.png
	AurasSymbol = "rbxassetid://0", -- layer_sym_auras.png
	RebirthTile = "rbxassetid://0", -- layer_tile_rebirth.png
	RebirthSymbol = "rbxassetid://0", -- layer_sym_rebirth.png

	-- Колесо фортуны
	WheelBase = "rbxassetid://0", -- layer_wheel_base.png
	WheelDisc = "rbxassetid://0", -- layer_wheel_disc.png
	WheelTop = "rbxassetid://0", -- layer_wheel_top.png

	-- Правый верхний угол
	Achievements = "rbxassetid://0", -- bar_achievements.png
	Rewards = "rbxassetid://0", -- bar_rewards.png
	Quests = "rbxassetid://0", -- bar_daily.png (свиток)
	Settings = "rbxassetid://0", -- bar_settings.png

	-- Меч на полосе уровня и на кнопке «Мощный удар»
	LevelSword = "rbxassetid://0", -- icon_sword.png
	PowerSword = "rbxassetid://0", -- icon_sword_dark.png

	-- Показатели
	Strength = "rbxassetid://0", -- stat_strength.png (рука)
	Luck = "rbxassetid://0", -- stat_luck.png
	Wins = "rbxassetid://0", -- stat_wins.png

	-- Геймпассы
	PassWinsX3 = "rbxassetid://0", -- pass_wins_x3.png
	PassStrengthX2 = "rbxassetid://0", -- pass_strength_x2.png
	PassLuckX2 = "rbxassetid://0", -- pass_luck_x2.png
	PassAutoClick = "rbxassetid://0", -- pass_auto_click.png
}
