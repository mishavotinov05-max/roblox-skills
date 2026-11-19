--[[
	PickaxeService — магазин кирок, удача, выдача кирки в руки.

	Своя 3D-модель кирки: положите Tool в ServerStorage › PickaxeModels
	и назовите его как Id кирки (например "gold"). Внутри должна быть деталь "Handle".
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local PickaxeConfig = require(Config:WaitForChild("PickaxeConfig"))
local ShopConfig = require(Config:WaitForChild("ShopConfig"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Format = require(Shared:WaitForChild("Format"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RequestService = require(Services:WaitForChild("RequestService"))
local MapService = require(Services:WaitForChild("MapService"))

local PickaxeService = {}
local TOOL_NAME = "Pickaxe"

local function buildTool(cfg): Tool
	local custom = ServerStorage:FindFirstChild("PickaxeModels")
	local model = custom and custom:FindFirstChild(cfg.Id)
	if model and model:IsA("Tool") then
		local tool = model:Clone()
		tool.Name = TOOL_NAME
		return tool
	end

	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.ToolTip = cfg.Name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	-- Хват как у классического меча: рукоять вдоль Z, держим за нижний конец
	tool.GripPos = Vector3.new(0, 0, -1.6)
	tool.GripForward = Vector3.new(-1, 0, 0)
	tool.GripRight = Vector3.new(0, 1, 0)
	tool.GripUp = Vector3.new(0, 0, 1)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.45, 0.45, 4.4)
	handle.Color = cfg.HandleColor
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = CFrame.new()
	handle.Parent = tool

	local function addPart(name: string, size: Vector3, offset: CFrame, material: Enum.Material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = cfg.Color
		p.Material = material
		p.CanCollide = false
		p.Massless = true
		p.CFrame = handle.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = p
		weld.Parent = p
		p.Parent = tool
	end
	-- Головка кирки: перекладина и два острых конца
	addPart("Head", Vector3.new(3.4, 0.55, 0.6), CFrame.new(0, 0, 2.1), Enum.Material.Metal)
	addPart("TipA", Vector3.new(0.9, 0.4, 0.45), CFrame.new(-1.9, -0.2, 2.1) * CFrame.Angles(0, 0, math.rad(-25)), Enum.Material.Metal)
	addPart("TipB", Vector3.new(0.9, 0.4, 0.45), CFrame.new(1.9, -0.2, 2.1) * CFrame.Angles(0, 0, math.rad(25)), Enum.Material.Metal)
	addPart("Cap", Vector3.new(0.8, 0.8, 0.8), CFrame.new(0, 0, 2.1), Enum.Material.Neon)
	return tool
end

-- Выдать (или заменить) кирку и сразу взять её в руки
function PickaxeService.GiveTool(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local cfg = Catalog.Pickaxe(data.EquippedPickaxe)
	for _, container in ipairs({ player:FindFirstChild("Backpack"), player.Character }) do
		if container then
			for _, item in ipairs(container:GetChildren()) do
				if item:IsA("Tool") and item.Name == TOOL_NAME then
					item:Destroy()
				end
			end
		end
	end
	local tool = buildTool(cfg)
	local backpack = player:WaitForChild("Backpack", 5)
	if not backpack then
		return
	end
	tool.Parent = backpack
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:EquipTool(tool)
	end
end

function PickaxeService.Buy(player: Player, id: string)
	local data = DataService.Get(player)
	local cfg = type(id) == "string" and Catalog.Pickaxes[id]
	if not cfg then
		return { ok = false }
	end
	if data.OwnedPickaxes[id] then
		return PickaxeService.Equip(player, id)
	end
	if data.Wins < cfg.Price then
		return { ok = false, msg = ("Нужно %s побед"):format(Format.Short(cfg.Price)) }
	end
	data.Wins -= cfg.Price
	data.OwnedPickaxes[id] = true
	data.EquippedPickaxe = id
	DataService.MarkDirty(player)
	PickaxeService.GiveTool(player)
	RequestService.Notify(player, "Куплена кирка: " .. cfg.Name, "success")
	return { ok = true }
end

function PickaxeService.Equip(player: Player, id: string)
	local data = DataService.Get(player)
	if type(id) ~= "string" or not data.OwnedPickaxes[id] or not Catalog.Pickaxes[id] then
		return { ok = false, msg = "Сначала купите эту кирку" }
	end
	data.EquippedPickaxe = id
	DataService.MarkDirty(player)
	PickaxeService.GiveTool(player)
	return { ok = true }
end

function PickaxeService.BuyLuck(player: Player, offerId: string)
	local data = DataService.Get(player)
	local offer = nil
	for _, o in ipairs(ShopConfig.Luck.Offers) do
		if o.Id == offerId then
			offer = o
		end
	end
	if not offer then
		return { ok = false }
	end
	if data.LuckPercent >= ShopConfig.Luck.MaxPercent then
		return { ok = false, msg = "Удача уже максимальная" }
	end
	local bought = data.LuckBought[offer.Id] or 0
	local cost = Formulas.LuckOfferCost(offer, bought)
	if data.Wins < cost then
		return { ok = false, msg = ("Нужно %s побед"):format(Format.Short(cost)) }
	end
	data.Wins -= cost
	data.LuckBought[offer.Id] = bought + 1
	data.LuckPercent = math.min(ShopConfig.Luck.MaxPercent, data.LuckPercent + offer.Percent)
	DataService.MarkDirty(player)
	RequestService.Notify(player, ("%s: +%d%% удачи!"):format(offer.Name, offer.Percent), "success")
	return { ok = true }
end

local function setupSlots()
	for _, slot in ipairs(MapService.PickaxeSlots()) do
		local cfg = PickaxeConfig.Pickaxes[slot.Index]
		local prompt = MapService.FindPrompt(slot.BuyPad)
		if cfg then
			local priceText = cfg.Price == 0 and "Бесплатно" or Format.Short(cfg.Price)
			MapService.SetText(slot.BuyPad, "Price", priceText)
			MapService.SetText(slot.Model, "PickName", cfg.Name)
			if prompt then
				prompt.ObjectText = ("%s · сила ×%s"):format(cfg.Name, Format.Short(cfg.Power))
				prompt.ActionText = cfg.Price == 0 and "Взять" or ("Купить за " .. priceText)
				prompt.Triggered:Connect(function(player)
					local res = PickaxeService.Buy(player, cfg.Id)
					if res and res.msg then
						RequestService.Notify(player, res.msg, "error")
					end
				end)
			end
		else
			-- Место без кирки в конфиге
			MapService.SetText(slot.BuyPad, "Price", "—")
			if prompt then
				prompt.Enabled = false
			end
		end
	end
end

function PickaxeService.Init()
	RequestService.Register("BuyPickaxe", PickaxeService.Buy)
	RequestService.Register("EquipPickaxe", PickaxeService.Equip)
	RequestService.Register("BuyLuck", PickaxeService.BuyLuck)

	local function onCharacter(player: Player)
		task.wait(0.3)
		if DataService.Get(player) then
			PickaxeService.GiveTool(player)
		end
	end
	DataService.OnLoaded(function(player)
		player.CharacterAdded:Connect(function()
			onCharacter(player)
		end)
		if player.Character then
			onCharacter(player)
		end
	end)

	task.spawn(setupSlots)
end

return PickaxeService
