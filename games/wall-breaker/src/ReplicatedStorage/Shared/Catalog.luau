-- Catalog — быстрый поиск записей в конфигах по Id (общий для сервера и клиента)
local Config = script.Parent.Parent:WaitForChild("Config")

local PickaxeConfig = require(Config:WaitForChild("PickaxeConfig"))
local PetConfig = require(Config:WaitForChild("PetConfig"))
local AuraConfig = require(Config:WaitForChild("AuraConfig"))
local LevelConfig = require(Config:WaitForChild("LevelConfig"))
local OreConfig = require(Config:WaitForChild("OreConfig"))

local Catalog = {}

local function index(list)
	local map = {}
	for i, item in ipairs(list) do
		map[item.Id] = item
		item._Index = i
	end
	return map
end

Catalog.Pickaxes = index(PickaxeConfig.Pickaxes)
Catalog.Auras = index(AuraConfig.Auras)
Catalog.Levels = index(LevelConfig.Levels)
Catalog.Ores = index(OreConfig.Ores)
Catalog.Eggs = index(PetConfig.Eggs)
Catalog.Pets = PetConfig.Pets

function Catalog.Pickaxe(id: string?)
	return (id and Catalog.Pickaxes[id]) or PickaxeConfig.Pickaxes[1]
end

function Catalog.Level(id: number)
	return Catalog.Levels[id]
end

return Catalog
