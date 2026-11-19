-- Formulas — все игровые формулы в одном месте (используются и сервером, и интерфейсом)
local Config = script.Parent.Parent:WaitForChild("Config")
local LevelConfig = require(Config:WaitForChild("LevelConfig"))
local RebirthConfig = require(Config:WaitForChild("RebirthConfig"))
local ShopConfig = require(Config:WaitForChild("ShopConfig"))
local Catalog = require(script.Parent:WaitForChild("Catalog"))

local Formulas = {}

function Formulas.PetMultiplier(data): number
	local m = 1
	local byUid = {}
	for _, pet in ipairs(data.Pets or {}) do
		byUid[pet.Uid] = pet
	end
	for _, uid in ipairs(data.EquippedPets or {}) do
		local pet = byUid[uid]
		local def = pet and Catalog.Pets[pet.Id]
		if def then
			m += def.Bonus
		end
	end
	return m
end

function Formulas.AuraMultiplier(data): number
	local aura = data.EquippedAura and Catalog.Auras[data.EquippedAura]
	return aura and aura.Multiplier or 1
end

function Formulas.RebirthMultiplier(data): number
	return 1 + (data.Rebirths or 0) * RebirthConfig.StrengthBonusPerRebirth
end

function Formulas.PickaxePower(data): number
	return Catalog.Pickaxe(data.EquippedPickaxe).Power
end

-- Общий множитель силы (без ямы)
function Formulas.TotalMultiplier(data, hasStrengthPass: boolean?): number
	return Formulas.PickaxePower(data)
		* Formulas.PetMultiplier(data)
		* Formulas.AuraMultiplier(data)
		* Formulas.RebirthMultiplier(data)
		* (hasStrengthPass and 2 or 1)
end

-- Сила за один удар в яме
function Formulas.StrengthPerSwing(data, pitPower: number, hasStrengthPass: boolean?): number
	return pitPower * Formulas.TotalMultiplier(data, hasStrengthPass)
end

-- Урон по стене за удар = текущая сила (минимум 1)
function Formulas.Damage(data): number
	return math.max(1, data.Strength or 0)
end

function Formulas.LayerHP(levelId: number, layer: number): number
	local level = Catalog.Level(levelId)
	if not level then
		return math.huge
	end
	return math.floor(level.BaseHP * (1 + (layer - 1) * LevelConfig.LayerHPStep))
end

function Formulas.RecommendedStrength(levelId: number): number
	local level = Catalog.Level(levelId)
	return level and math.ceil(level.BaseHP / LevelConfig.TargetHitsPerLayer) or 0
end

function Formulas.RebirthCost(rebirths: number): number
	return math.floor(RebirthConfig.BaseCost * RebirthConfig.CostGrowth ^ rebirths)
end

function Formulas.LuckCost(level: number): number
	return math.floor(ShopConfig.Luck.BaseCost * ShopConfig.Luck.CostGrowth ^ level)
end

function Formulas.LuckPercent(data, hasLuckPass: boolean?): number
	local p = (data.LuckLevel or 0) * ShopConfig.Luck.PercentPerLevel
	if hasLuckPass then
		p = (p + 100) * 2 - 100 -- удача ×2: множитель шанса удваивается
	end
	return p
end

return Formulas
