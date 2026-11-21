--[[
	SwingService — обработка ударов киркой.
	Клиент только сообщает «я ударил». Сервер сам проверяет паузу между ударами,
	что кирка в руках и где стоит игрок (в яме или перед стеной).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("GameSettings"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local TrainingService = require(Services:WaitForChild("TrainingService"))
local WallService = require(Services:WaitForChild("WallService"))

local SwingService = {}
local lastSwing: { [Player]: number } = {}

local function playSlash(tool: Tool)
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim" -- стандартный скрипт Animate проигрывает удар
	anim.Value = "Slash"
	anim.Parent = tool
	game:GetService("Debris"):AddItem(anim, 1)
end

function SwingService.Init()
	Remotes.Event("Swing").OnServerEvent:Connect(function(player: Player)
		local now = os.clock()
		if lastSwing[player] and now - lastSwing[player] < Settings.SwingCooldown * 0.8 then
			return
		end
		lastSwing[player] = now

		local data = DataService.Get(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local tool = character and character:FindFirstChild("Pickaxe")
		if not data or not root or not tool or not tool:IsA("Tool") then
			return
		end
		playSlash(tool)
		local pos = root.Position
		if TrainingService.TrySwing(player, data, pos) then
			return
		end
		-- опыт за каждый удар (по стене или по воздуху), чтобы шкала уровня заполнялась
		local perSwing = Settings.Xp.PerSwing or 0
		if WallService.TrySwing(player, data, pos) then
			if perSwing > 0 then
				TrainingService.AddXp(player, data, perSwing)
			end
			return
		end
		TrainingService.AirSwing(player, data)
		if perSwing > 0 then
			TrainingService.AddXp(player, data, perSwing)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
	end)
end

return SwingService
