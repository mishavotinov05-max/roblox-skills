--[[
	Pets — рисует питомцев рядом с игроками (только на экране, сервер не нагружается).
	Своя модель: ReplicatedStorage › PetModels › <Id питомца> (Model). Иначе — круглый питомец.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Catalog"))
local Controllers = script.Parent
local State = require(Controllers:WaitForChild("State"))

local Pets = {}
local folder: Folder
local shown: { [Player]: { key: string, models: { Model } } } = {}

local function makePet(id: string): Model
	local custom = ReplicatedStorage:FindFirstChild("PetModels")
	local template = custom and custom:FindFirstChild(id)
	if template and template:IsA("Model") then
		local m = template:Clone()
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
			end
		end
		return m
	end
	local def = Catalog.Pets[id]
	local model = Instance.new("Model")
	model.Name = id
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2, 2, 2)
	body.Color = def and def.Color or Color3.new(1, 1, 1)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.Parent = model
	model.PrimaryPart = body
	for _, x in ipairs({ -0.4, 0.4 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.4, 0.4, 0.4)
		eye.Color = Color3.fromRGB(26, 16, 51)
		eye.Anchored = true
		eye.CanCollide = false
		eye.CanQuery = false
		eye.CFrame = body.CFrame * CFrame.new(x, 0.25, -0.85)
		eye.Parent = model
	end
	for _, x in ipairs({ -0.55, 0.55 }) do
		local ear = Instance.new("Part")
		ear.Name = "Ear"
		ear.Size = Vector3.new(0.4, 0.7, 0.3)
		ear.Color = body.Color
		ear.Anchored = true
		ear.CanCollide = false
		ear.CanQuery = false
		ear.CFrame = body.CFrame * CFrame.new(x, 1, 0)
		ear.Parent = model
	end
	return model
end

local function sync(player: Player)
	local key = player:GetAttribute("EquippedPets") or ""
	local data = State.Data
	if player ~= Players.LocalPlayer and data and data.Settings.ShowPets == false then
		key = ""
	end
	local entry = shown[player]
	if entry and entry.key == key then
		return
	end
	if entry then
		for _, m in ipairs(entry.models) do
			m:Destroy()
		end
	end
	local models = {}
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for id in tostring(key):gmatch("[^,]+") do
		local m = makePet(id)
		if root then
			m:PivotTo(root.CFrame * CFrame.new(0, 0, 5))
		end
		m.Parent = folder
		table.insert(models, m)
	end
	shown[player] = { key = key, models = models }
end

function Pets.Init()
	folder = Instance.new("Folder")
	folder.Name = "ClientPets"
	folder.Parent = Workspace

	local function watch(player: Player)
		player:GetAttributeChangedSignal("EquippedPets"):Connect(function()
			sync(player)
		end)
		sync(player)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in ipairs(Players:GetPlayers()) do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		local entry = shown[player]
		if entry then
			for _, m in ipairs(entry.models) do
				m:Destroy()
			end
		end
		shown[player] = nil
	end)
	State.Changed:Connect(function()
		for _, p in ipairs(Players:GetPlayers()) do
			sync(p)
		end
	end)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for player, entry in pairs(shown) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local n = #entry.models
				for i, model in ipairs(entry.models) do
					local spread = (i - (n + 1) / 2) * 3.2
					local bob = math.sin(t * 4 + i) * 0.35
					local target = root.CFrame * CFrame.new(spread, -1 + bob, 5.5)
					local current = model:GetPivot()
					model:PivotTo(current:Lerp(target, 0.15))
				end
			end
		end
	end)
end

return Pets
