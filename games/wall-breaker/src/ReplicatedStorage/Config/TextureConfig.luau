--[[
	TextureConfig — пиксельные текстуры карты (файлы в папке art/textures).

	Как включить:
	1) Studio › View › Asset Manager › Bulk Import → выберите PNG из art/textures.
	2) Правый клик по картинке → Copy Asset ID → вставьте сюда вместо 0.
	3) Нажмите Play — текстуры появятся на стенах, полу, ямах и слоях стен.

	Чтобы текстуры были видны и в Studio без запуска игры (и их можно было двигать/удалять):
	View › Command Bar → вставьте строку и нажмите Enter:
	  require(game.ReplicatedStorage.Shared.TextureApplier).Apply()

	StudsPerTile — размер одной плитки текстуры в стадах (больше = крупнее рисунок).
]]

return {
	StudsPerTile = 6,
	Textures = {
		brick = "rbxassetid://0", -- brick.png (стены — рыжие блоки с пупырышками)
		grass_top = "rbxassetid://0", -- grass_top.png
		grass_side = "rbxassetid://0", -- grass_side.png
		floor_tiles = "rbxassetid://0", -- floor_tiles.png (пол лобби — трава с пупырышками)
		floor_dark = "rbxassetid://0", -- floor_dark.png (пол уровней)
		stone_brick = "rbxassetid://0", -- stone_brick.png (арка, ступени магазина)
		dirt = "rbxassetid://0", -- dirt.png (Землянка)
		sand = "rbxassetid://0", -- sand.png (дорожки)
	},
	-- Текстуры слоёв стен по номеру уровня
	Levels = {
		"rbxassetid://0", -- 1 level_hay.png
		"rbxassetid://0", -- 2 level_wood.png
		"rbxassetid://0", -- 3 level_coal.png
		"rbxassetid://0", -- 4 level_stone.png
		"rbxassetid://0", -- 5 level_copper.png
		"rbxassetid://0", -- 6 level_iron.png
		"rbxassetid://0", -- 7 level_gold.png
		"rbxassetid://0", -- 8 level_obsidian.png
		"rbxassetid://0", -- 9 level_diamond.png
		"rbxassetid://0", -- 10 level_netherite.png
	},
	-- Текстуры ям по номеру (Pit_01 …): ключ из Textures или номер уровня из Levels
	Pits = { "dirt", 3, 4, 6, 7, 9, 8 },
}
