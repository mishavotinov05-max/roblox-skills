--[[
	OreService — выпадение руд, торговец в лобби и редкий торговец на уровнях.
	Шаблон редкого торговца: ServerStorage › RareMerchantTemplate (можно перекрасить/заменить).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Config")
local OreConfig = require(Config:WaitForChild("OreConfig"))
local Settings = require(Config:WaitForChild("GameSettings"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Formulas = require(Shared:WaitForChild("Formulas"))
local Format = require(Shared:WaitForChild("Format"))
local Catalog = require(Shared:WaitForChild("Catalog"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RequestService = require(Services:WaitForChild("RequestService"))
local MapService = require(Services:WaitForChild("MapService"))
local MonetizationService = require(Services:WaitForChild("MonetizationService"))

local OreService = {}
local rng = Random.new()

-- Бросок на выпадение руды после разрушения слоя
function OreService.Roll(player: Player, data)
	local luck = Formulas.LuckPercent(data, MonetizationService.HasPass(player, "LuckX2"))
	local mult = 1 + luck / 100
	for _, ore in ipairs(OreConfig.Ores) do
		if rng:NextNumber() < ore.Chance * mult then
			data.Ores[ore.Id] = (data.Ores[ore.Id] or 0) + 1
			DataService.MarkDirty(player)
			RequestService.Notify(player, "Выпала руда: " .. ore.Name .. "!", "ore:" .. ore.Id)
			return ore
		end
	end
	return nil
end

function OreService.SellAll(player: Player, multiplier: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local total, count = 0, 0
	for id, n in pairs(data.Ores) do
		local ore = Catalog.Ores[id]
		if ore and n > 0 then
			total += ore.Price * n * multiplier
			count += n
		end
	end
	if count == 0 then
		RequestService.Notify(player, "У тебя нет руд. Ломай стены — руды выпадают из слоёв!", "error")
		return
	end
	total = math.floor(total)
	data.Ores = {}
	data.Wins += total
	data.Stats.OresSold += count
	DataService.MarkDirty(player)
	RequestService.Notify(player, ("Продано руд: %d → +%s побед"):format(count, Format.Short(total)), "success")
end

local function buildMerchantModel(): Model
	local template = ServerStorage:FindFirstChild("RareMerchantTemplate")
	if template and template:IsA("Model") then
		return template:Clone()
	end
	local model = Instance.new("Model")
	model.Name = "RareMerchant"
	local counter = Instance.new("Part")
	counter.Name = "Counter"
	counter.Anchored = true
	counter.Size = Vector3.new(6, 3, 3)
	counter.Color = Color3.fromRGB(122, 74, 36)
	counter.Material = Enum.Material.WoodPlanks
	counter.CFrame = CFrame.new(0, 1.5, 0)
	counter.Parent = model
	local prompt = Instance.new("ProximityPrompt")
	prompt.Parent = counter
	model.PrimaryPart = counter
	return model
end

local activeMerchant: Model? = nil

local function spawnMerchant()
	if activeMerchant then
		return
	end
	local spots = {}
	for _, level in ipairs(MapService.Levels()) do
		if level.MerchantSpot then
			table.insert(spots, level)
		end
	end
	if #spots == 0 then
		return
	end
	local level = spots[rng:NextInteger(1, #spots)]
	local model = buildMerchantModel()
	model.Name = "RareMerchant"
	model:PivotTo((level.MerchantSpot :: BasePart).CFrame)
	local prompt = MapService.FindPrompt(model)
	if prompt then
		prompt.ActionText = ("Продать руды ×%s"):format(tostring(Settings.RareMerchant.PriceMultiplier))
		prompt.ObjectText = "Редкий торговец"
		prompt.RequiresLineOfSight = false
		prompt.Triggered:Connect(function(player)
			OreService.SellAll(player, Settings.RareMerchant.PriceMultiplier)
		end)
	end
	model.Parent = Workspace
	activeMerchant = model
	RequestService.NotifyAll(("Редкий торговец появился на уровне %d! Покупает руды ×%s"):format(level.Id, tostring(Settings.RareMerchant.PriceMultiplier)), "event")
	task.delay(Settings.RareMerchant.Duration, function()
		if activeMerchant == model then
			activeMerchant = nil
		end
		model:Destroy()
	end)
end

function OreService.Init()
	-- Торговец в лобби
	task.spawn(function()
		local trader = MapService.Hub():WaitForChild("OreTrader", 10)
		local prompt = MapService.FindPrompt(trader)
		if prompt then
			prompt.Triggered:Connect(function(player)
				OreService.SellAll(player, 1)
			end)
		end
	end)

	-- Редкий торговец
	task.spawn(function()
		while true do
			task.wait(Settings.RareMerchant.CheckInterval)
			if rng:NextNumber() < Settings.RareMerchant.Chance then
				spawnMerchant()
			end
		end
	end)
end

return OreService
