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
local shown: { [Player]: { key: string, models: { Model }, lift: { [Model]: number } } } = {}

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
	local lift = {}
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for id in tostring(key):gmatch("[^,]+") do
		local m = makePet(id)
		-- насколько точка опоры модели выше её низа (чтобы ставить ровно на землю)
		local box, size = m:GetBoundingBox()
		lift[m] = m:GetPivot().Position.Y - (box.Position.Y - size.Y / 2)
		if root then
			m:PivotTo(root.CFrame * CFrame.new(0, 0, 5))
		end
		m.Parent = folder
		table.insert(models, m)
	end
	shown[player] = { key = key, models = models, lift = lift }
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

	-- Питомцы стоят на земле: луч вниз находит пол, поэтому они не проваливаются
	-- в холмы и ступени и не прыгают вместе с игроком.
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	RunService.RenderStepped:Connect(function(dt)
		local ignore: { Instance } = { folder }
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				table.insert(ignore, p.Character)
			end
		end
		rayParams.FilterDescendantsInstances = ignore
		local alpha = math.clamp(dt * 10, 0, 1)

		for player, entry in pairs(shown) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root then
				-- Поворот только вокруг вертикали (без наклонов)
				local look = root.CFrame.LookVector
				local flat = Vector3.new(look.X, 0, look.Z)
				if flat.Magnitude < 0.01 then
					flat = Vector3.new(0, 0, -1)
				end
				local facing = CFrame.lookAt(Vector3.zero, flat.Unit)
				-- Уровень ног игрока (запасной вариант, если под питомцем нет пола)
				local hip = humanoid and humanoid.HipHeight or 2
				local feetY = root.Position.Y - root.Size.Y / 2 - hip
				local n = #entry.models
				for i, model in ipairs(entry.models) do
					local spread = (i - (n + 1) / 2) * 3.2
					local spot = root.Position + facing:VectorToWorldSpace(Vector3.new(spread, 0, 5.5))
					local groundY = feetY
					local hit = Workspace:Raycast(Vector3.new(spot.X, root.Position.Y + 4, spot.Z), Vector3.new(0, -60, 0), rayParams)
					if hit then
						groundY = hit.Position.Y
					end
					local lift = entry.lift[model] or 1
					local target = CFrame.new(spot.X, groundY + lift, spot.Z) * facing.Rotation
					local current = model:GetPivot()
					-- По высоте двигаемся плавно, но не уходим под землю
					local nextCf = current:Lerp(target, alpha)
					if nextCf.Position.Y < groundY + lift - 0.05 then
						nextCf = CFrame.new(nextCf.Position.X, groundY + lift, nextCf.Position.Z) * nextCf.Rotation
					end
					model:PivotTo(nextCf)
				end
			end
		end
	end)
end

return Pets
