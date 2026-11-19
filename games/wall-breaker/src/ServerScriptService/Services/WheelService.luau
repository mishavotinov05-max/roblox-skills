--[[
	WheelService — колесо фортуны (настройки в WheelConfig).
	Бесплатное вращение раз в Cooldown секунд + купленные вращения (ShopConfig.Products).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local WheelConfig = require(Config:WaitForChild("WheelConfig"))
local ShopConfig = require(Config:WaitForChild("ShopConfig"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RequestService = require(Services:WaitForChild("RequestService"))
local AuraService = require(Services:WaitForChild("AuraService"))

local WheelService = {}
local rng = Random.new()

local function pickIndex(): number
	local total = 0
	for _, prize in ipairs(WheelConfig.Prizes) do
		total += prize.Weight
	end
	local r = rng:NextNumber() * total
	for i, prize in ipairs(WheelConfig.Prizes) do
		r -= prize.Weight
		if r <= 0 then
			return i
		end
	end
	return #WheelConfig.Prizes
end

local function applyPrize(player: Player, data, prize): string
	if prize.Type == "Wins" then
		data.Wins += prize.Amount
		return prize.Text
	elseif prize.Type == "StrengthPercent" then
		local gain = math.max(math.floor(data.Strength * prize.Amount / 100), prize.Amount)
		data.Strength += gain
		return "+" .. Format.Short(gain) .. " силы"
	elseif prize.Type == "Luck" then
		data.LuckLevel = math.min(ShopConfig.Luck.MaxLevel, data.LuckLevel + prize.Amount)
		return prize.Text
	elseif prize.Type == "Aura" then
		if AuraService.Grant(player, prize.AuraId) then
			return prize.Text
		end
		data.Wins += 25
		return "Аура уже есть → +25 побед"
	end
	return prize.Text
end

function WheelService.Init()
	RequestService.Register("SpinWheel", function(player)
		local data = DataService.Get(player)
		local now = os.time()
		local remaining = WheelConfig.Cooldown - (now - data.Wheel.LastFree)
		if remaining > 0 then
			if data.Wheel.ExtraSpins > 0 then
				data.Wheel.ExtraSpins -= 1
			else
				return { ok = false, msg = "Бесплатное вращение через " .. Format.Time(remaining) }
			end
		else
			data.Wheel.LastFree = now
		end
		local index = pickIndex()
		local text = applyPrize(player, data, WheelConfig.Prizes[index])
		DataService.MarkDirty(player)
		return { ok = true, index = index, text = text }
	end)

	DataService.AddStateHook(function(_, state, data)
		state.WheelReadyIn = math.max(0, WheelConfig.Cooldown - (os.time() - data.Wheel.LastFree))
	end)
end

return WheelService
