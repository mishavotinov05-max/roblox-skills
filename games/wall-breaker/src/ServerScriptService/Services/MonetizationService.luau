--[[
	MonetizationService — геймпассы и товары за Robux (MarketplaceService).
	Номера (Id) задаются в ReplicatedStorage › Config › ShopConfig.
]]
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ShopConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local RequestService = require(script.Parent:WaitForChild("RequestService"))

local MonetizationService = {}
local owned: { [Player]: { [string]: boolean } } = {}
local productHandlers = {}

-- Другие сервисы могут обработать свой товар: fn(player, data, product) → true, если выдано
function MonetizationService.RegisterProductHandler(key: string, fn)
	productHandlers[key] = fn
end

function MonetizationService.HasPass(player: Player, key: string): boolean
	return owned[player] ~= nil and owned[player][key] == true
end

local function passKeyById(id: number): string?
	for key, pass in pairs(ShopConfig.GamePasses) do
		if pass.Id ~= 0 and pass.Id == id then
			return key
		end
	end
	return nil
end

local function productById(id: number)
	for _, product in ipairs(ShopConfig.Products) do
		if product.Id ~= 0 and product.Id == id then
			return product
		end
	end
	return nil
end

local function trimPurchases(purchases)
	local count = 0
	local oldestKey, oldestTime = nil, math.huge
	for k, t in pairs(purchases) do
		count += 1
		if t < oldestTime then
			oldestKey, oldestTime = k, t
		end
	end
	if count > 100 and oldestKey then
		purchases[oldestKey] = nil
	end
end

function MonetizationService.Init()
	DataService.OnLoaded(function(player)
		owned[player] = {}
		for key, pass in pairs(ShopConfig.GamePasses) do
			if pass.Id ~= 0 then
				local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
				if ok and has then
					owned[player][key] = true
				end
			end
		end
		DataService.MarkDirty(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)

	DataService.AddStateHook(function(player, state)
		state.Passes = owned[player] or {}
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local key = passKeyById(passId)
		if key and owned[player] then
			owned[player][key] = true
			DataService.MarkDirty(player)
			RequestService.Notify(player, "Спасибо! Геймпасс «" .. ShopConfig.GamePasses[key].Name .. "» активирован", "success")
		end
	end)

	MarketplaceService.ProcessReceipt = function(info)
		local player = Players:GetPlayerByUserId(info.PlayerId)
		local data = player and DataService.Get(player)
		if not player or not data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local purchaseId = tostring(info.PurchaseId)
		if data.Purchases[purchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted -- уже выдано (защита от повтора)
		end
		local product = productById(info.ProductId)
		if not product then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local handler = productHandlers[product.Key]
		if handler then
			local ok, granted = pcall(handler, player, data, product)
			if not ok or not granted then
				warn("[Monetization] товар не выдан:", product.Key, granted)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end
		if product.Wins then
			data.Wins += product.Wins
		end
		if product.Spins then
			data.Wheel.ExtraSpins += product.Spins
		end
		if product.LuckPercent then
			data.LuckPercent = math.min(ShopConfig.Luck.MaxPercent, data.LuckPercent + product.LuckPercent)
		end
		data.Purchases[purchaseId] = os.time()
		trimPurchases(data.Purchases)
		DataService.MarkDirty(player)
		if not DataService.Save(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		RequestService.Notify(player, "Покупка получена: " .. product.Name, "success")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	RequestService.Register("BuyPass", function(player, key)
		local pass = type(key) == "string" and ShopConfig.GamePasses[key]
		if not pass then
			return { ok = false }
		end
		if pass.Id == 0 then
			return { ok = false, msg = "Покупка ещё не настроена (Id = 0 в ShopConfig)" }
		end
		if MonetizationService.HasPass(player, key) then
			return { ok = false, msg = "Уже куплено" }
		end
		MarketplaceService:PromptGamePassPurchase(player, pass.Id)
		return { ok = true }
	end)

	RequestService.Register("BuyProduct", function(player, key)
		for _, product in ipairs(ShopConfig.Products) do
			if product.Key == key then
				if product.Id == 0 then
					return { ok = false, msg = "Покупка ещё не настроена (Id = 0 в ShopConfig)" }
				end
				MarketplaceService:PromptProductPurchase(player, product.Id)
				return { ok = true }
			end
		end
		return { ok = false }
	end)
end

return MonetizationService
