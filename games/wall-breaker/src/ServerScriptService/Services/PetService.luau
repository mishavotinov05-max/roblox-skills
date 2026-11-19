--[[
	PetService — яйца и питомцы.
	Яйцо открывается кнопкой у яйца в лобби (ProximityPrompt).
	Надетые питомцы записываются в атрибут игрока "EquippedPets" — клиент рисует их рядом с игроком.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("GameSettings"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RequestService = require(Services:WaitForChild("RequestService"))
local MapService = require(Services:WaitForChild("MapService"))

local PetService = {}
local rng = Random.new()

local function findPet(data, uid: number)
	for i, pet in ipairs(data.Pets) do
		if pet.Uid == uid then
			return pet, i
		end
	end
	return nil, nil
end

local function isEquipped(data, uid: number): boolean
	return table.find(data.EquippedPets, uid) ~= nil
end

function PetService.UpdateAttribute(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local ids = {}
	for _, uid in ipairs(data.EquippedPets) do
		local pet = findPet(data, uid)
		if pet then
			table.insert(ids, pet.Id)
		end
	end
	player:SetAttribute("EquippedPets", table.concat(ids, ","))
end

local function rollPet(egg): string
	local total = 0
	for _, entry in ipairs(egg.Pets) do
		total += entry[2]
	end
	local r = rng:NextNumber() * total
	for _, entry in ipairs(egg.Pets) do
		r -= entry[2]
		if r <= 0 then
			return entry[1]
		end
	end
	return egg.Pets[#egg.Pets][1]
end

function PetService.OpenEgg(player: Player, eggId: string)
	local data = DataService.Get(player)
	local egg = type(eggId) == "string" and Catalog.Eggs[eggId]
	if not data or not egg then
		return { ok = false }
	end
	if #data.Pets >= Settings.MaxPetsInInventory then
		return { ok = false, msg = "Инвентарь питомцев полон — удалите лишних" }
	end
	if data.Wins < egg.Price then
		return { ok = false, msg = ("Нужно %s побед"):format(Format.Short(egg.Price)) }
	end
	data.Wins -= egg.Price
	local petId = rollPet(egg)
	local uid = data.NextPetUid
	data.NextPetUid += 1
	table.insert(data.Pets, { Uid = uid, Id = petId })
	data.Stats.EggsOpened += 1
	if #data.EquippedPets < Settings.MaxEquippedPets then
		table.insert(data.EquippedPets, uid)
	end
	PetService.UpdateAttribute(player)
	DataService.MarkDirty(player)
	local def = Catalog.Pets[petId]
	RequestService.Notify(player, ("Выпал питомец: %s (%s, +%s)"):format(def.Name, def.Rarity, tostring(def.Bonus)), "pet")
	return { ok = true, pet = petId }
end

function PetService.Equip(player: Player, uid: number)
	local data = DataService.Get(player)
	if type(uid) ~= "number" or not findPet(data, uid) or isEquipped(data, uid) then
		return { ok = false }
	end
	if #data.EquippedPets >= Settings.MaxEquippedPets then
		return { ok = false, msg = ("Можно надеть не больше %d питомцев"):format(Settings.MaxEquippedPets) }
	end
	table.insert(data.EquippedPets, uid)
	PetService.UpdateAttribute(player)
	DataService.MarkDirty(player)
	return { ok = true }
end

function PetService.Unequip(player: Player, uid: number)
	local data = DataService.Get(player)
	local i = table.find(data.EquippedPets, uid)
	if i then
		table.remove(data.EquippedPets, i)
		PetService.UpdateAttribute(player)
		DataService.MarkDirty(player)
	end
	return { ok = true }
end

function PetService.EquipBest(player: Player)
	local data = DataService.Get(player)
	local sorted = table.clone(data.Pets)
	table.sort(sorted, function(a, b)
		local da, db = Catalog.Pets[a.Id], Catalog.Pets[b.Id]
		return (da and da.Bonus or 0) > (db and db.Bonus or 0)
	end)
	data.EquippedPets = {}
	for i = 1, math.min(Settings.MaxEquippedPets, #sorted) do
		table.insert(data.EquippedPets, sorted[i].Uid)
	end
	PetService.UpdateAttribute(player)
	DataService.MarkDirty(player)
	return { ok = true }
end

function PetService.Delete(player: Player, uid: number)
	local data = DataService.Get(player)
	local _, index = findPet(data, uid)
	if not index then
		return { ok = false }
	end
	PetService.Unequip(player, uid)
	table.remove(data.Pets, index)
	DataService.MarkDirty(player)
	return { ok = true }
end

function PetService.Init()
	RequestService.Register("OpenEgg", PetService.OpenEgg)
	RequestService.Register("EquipPet", PetService.Equip)
	RequestService.Register("UnequipPet", PetService.Unequip)
	RequestService.Register("EquipBestPets", PetService.EquipBest)
	RequestService.Register("DeletePet", PetService.Delete)

	DataService.OnLoaded(function(player)
		PetService.UpdateAttribute(player)
	end)

	task.spawn(function()
		for _, egg in ipairs(MapService.Eggs()) do
			local cfg = Catalog.Eggs[egg.Id]
			local prompt = MapService.FindPrompt(egg.Model)
			if cfg then
				MapService.SetText(egg.Model, "Title", cfg.Name)
				MapService.SetText(egg.Model, "Price", Format.Short(cfg.Price))
				if prompt then
					prompt.ObjectText = cfg.Name
					prompt.ActionText = "Открыть за " .. Format.Short(cfg.Price)
					prompt.Triggered:Connect(function(player)
						local res = PetService.OpenEgg(player, cfg.Id)
						if res and res.msg then
							RequestService.Notify(player, res.msg, "error")
						end
					end)
				end
			elseif prompt then
				prompt.Enabled = false
			end
		end
	end)
end

return PetService
