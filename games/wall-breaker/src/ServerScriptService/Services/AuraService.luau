--[[
	AuraService — покупка и надевание аур, светящийся эффект вокруг игрока.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RequestService = require(Services:WaitForChild("RequestService"))

local AuraService = {}

function AuraService.ApplyVisual(player: Player)
	local data = DataService.Get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end
	local old = root:FindFirstChild("AuraFx")
	if old then
		old:Destroy()
	end
	local aura = Catalog.Auras[data.EquippedAura]
	if not aura then
		return
	end
	local att = Instance.new("Attachment")
	att.Name = "AuraFx"
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(aura.Color)
	emitter.LightEmission = 1
	emitter.Rate = 30
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Parent = att
	local light = Instance.new("PointLight")
	light.Color = aura.Color
	light.Range = 10
	light.Brightness = 1.5
	light.Parent = att
	att.Parent = root
end

function AuraService.Grant(player: Player, id: string): boolean
	local data = DataService.Get(player)
	if not data or not Catalog.Auras[id] then
		return false
	end
	if data.Auras[id] then
		return false
	end
	data.Auras[id] = true
	DataService.MarkDirty(player)
	return true
end

function AuraService.Init()
	RequestService.Register("BuyAura", function(player, id)
		local data = DataService.Get(player)
		local aura = type(id) == "string" and Catalog.Auras[id]
		if not aura then
			return { ok = false }
		end
		if data.Auras[id] then
			return { ok = false, msg = "Уже куплено" }
		end
		if aura.Price <= 0 then
			return { ok = false, msg = "Эту ауру можно выиграть только в колесе фортуны" }
		end
		if data.Wins < aura.Price then
			return { ok = false, msg = ("Нужно %s побед"):format(Format.Short(aura.Price)) }
		end
		data.Wins -= aura.Price
		data.Auras[id] = true
		data.EquippedAura = id
		DataService.MarkDirty(player)
		AuraService.ApplyVisual(player)
		RequestService.Notify(player, "Аура «" .. aura.Name .. "» надета", "success")
		return { ok = true }
	end)

	RequestService.Register("EquipAura", function(player, id)
		local data = DataService.Get(player)
		if id == "" then
			data.EquippedAura = ""
		elseif type(id) == "string" and data.Auras[id] then
			data.EquippedAura = id
		else
			return { ok = false }
		end
		DataService.MarkDirty(player)
		AuraService.ApplyVisual(player)
		return { ok = true }
	end)

	DataService.OnLoaded(function(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 5)
			AuraService.ApplyVisual(player)
		end)
		AuraService.ApplyVisual(player)
	end)
end

return AuraService
