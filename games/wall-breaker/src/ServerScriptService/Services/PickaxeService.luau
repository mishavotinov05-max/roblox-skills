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
local Settings = require(Config:WaitForChild("GameSettings"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local PickaxeLook = require(Shared:WaitForChild("PickaxeLook"))
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
	-- Посадка: держим за низ рукояти, кирка наклонена назад (угол — GameSettings.PickaxeGripTilt)
	local L = PickaxeLook.HANDLE_LENGTH
	local tilt = math.rad(Settings.PickaxeGripTilt or 25)
	tool.GripPos = Vector3.new(0, 0, -(L / 2 - 0.7))
	tool.GripForward = Vector3.new(-1, 0, 0)
	tool.GripRight = Vector3.new(0, math.cos(tilt), math.sin(tilt))
	tool.GripUp = Vector3.new(0, -math.sin(tilt), math.cos(tilt))

	-- невидимый корень Handle; видимая кирка приварена к нему
	local root = Instance.new("Part")
	root.Name = "Handle"
	root.Size = Vector3.new(0.4, 0.4, 0.4)
	root.Transparency = 1
	root.CanCollide = false
	root.Massless = true
	root.CFrame = CFrame.new()
	root.Parent = tool
	-- модель строится с рукоятью по Y; в инструменте рукоять идёт по Z, головка — по X
	local origin = CFrame.fromMatrix(Vector3.new(0, 0, -L / 2), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1))
	local look = PickaxeLook.Build(cfg, origin)
	local shaft = look.PrimaryPart :: BasePart
	shaft.Name = "Shaft"
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = shaft
	w.Parent = shaft
	for _, p in ipairs(look:GetChildren()) do
		p.Parent = tool
	end
	look:Destroy()
	return tool
end

-- Кирка на спине, пока она не в руках
local function updateBack(player: Player, show: boolean)
	local character = player.Character
	if not character then
		return
	end
	local old = character:FindFirstChild("BackPickaxe")
	if old then
		old:Destroy()
	end
	local data = DataService.Get(player)
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not show or not data or not torso or not torso:IsA("BasePart") then
		return
	end
	local look = PickaxeLook.Build(Catalog.Pickaxe(data.EquippedPickaxe))
	look.Name = "BackPickaxe"
	local L = PickaxeLook.HANDLE_LENGTH
	look:PivotTo(torso.CFrame * CFrame.new(0, 0, 0.75) * CFrame.Angles(0, 0, math.rad(40)) * CFrame.new(0, -L / 2 - 0.4, 0)
		* CFrame.Angles(0, math.rad(90), 0))
	for _, p in ipairs(look:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Massless = true
		end
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = look.PrimaryPart
	weld.Parent = look.PrimaryPart
	look.Parent = character
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
	tool.Equipped:Connect(function()
		updateBack(player, false)
	end)
	tool.Unequipped:Connect(function()
		updateBack(player, true)
	end)
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
			MapService.SetText(slot.Model, "PickInfo", ("%s · x%s Силы"):format(cfg.Rarity or "", Format.Short(cfg.Power)))
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
