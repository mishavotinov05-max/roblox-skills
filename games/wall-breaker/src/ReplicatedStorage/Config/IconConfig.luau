--[[
	IconConfig — картинки для кнопок интерфейса.

	Пока здесь "rbxassetid://0", кнопки показывают эмодзи-заглушку.

	ИКОНКИ «КАК НА РЕФЕРЕНСЕ» лежат в папке art/icons_ref (вырезаны из вашей картинки):
	  ref_shop/pets/auras/rebirth — целые плитки (с подписью) → вставьте их ID в *Tile, а *Symbol оставьте 0;
	  ref_settings, ref_quests, ref_wheel, ref_rewards → Settings, Quests, WheelDisc (Base/Top оставьте 0), Rewards
	    (на этих значках уже есть подпись — своя подпись кнопки скрывается автоматически);
	  ref_wins, ref_strength, ref_luck → Wins, Strength, Luck;
	  ref_level_sword, ref_power_sword → LevelSword, PowerSword.
	Как поставить настоящие иконки (из папки art/icons):
	1) Studio › View › Asset Manager › Bulk Import → выберите PNG-файлы.
	2) Правый клик по картинке в Asset Manager › Copy Asset ID.
	3) Вставьте сюда вместо 0, например "rbxassetid://1234567890".
]]

return {
	-- Слева 2×2 (фон-плитка и символ отдельно — символ анимируется)
	ShopTile = "rbxassetid://140134205287427", -- layer_tile_shop.png
	ShopSymbol = "rbxassetid://0", -- layer_sym_shop.png
	PetsTile = "rbxassetid://132751927335269", -- layer_tile_pets.png
	PetsSymbol = "rbxassetid://0", -- layer_sym_pets.png
	AurasTile = "rbxassetid://85302115462208", -- layer_tile_auras.png
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

	-- Карточки слева внизу и полоса уровня — целые картинки (папка art/ui_ref).
	-- Число игра пишет сама поверх картинки.
	WinsCard = "rbxassetid://0", -- card_wins.png
	StrengthCard = "rbxassetid://0", -- card_strength.png
	LuckCard = "rbxassetid://0", -- card_luck.png
	RebirthCard = "rbxassetid://0", -- card_rebirth.png
	LevelBarEmpty = "rbxassetid://0", -- levelbar_empty.png
	LevelBarFull = "rbxassetid://0", -- levelbar_full.png
	PowerButton = "rbxassetid://0", -- power_button.png

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
