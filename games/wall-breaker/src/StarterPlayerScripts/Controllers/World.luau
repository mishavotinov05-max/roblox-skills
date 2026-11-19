--[[
	World — то, что каждый игрок видит по-своему:
	• сломанные им слои стен исчезают только у него;
	• открытые им ямы теряют барьер;
	• прогресс на табличках уровней;
	• эффекты: обломки стены, «+сила».
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Config = ReplicatedStorage:WaitForChild("Config")
local PitConfig = require(Config:WaitForChild("PitConfig"))
local LevelConfig = require(Config:WaitForChild("LevelConfig"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Controllers = script.Parent
local State = require(Controllers:WaitForChild("State"))
local Toasts = require(Controllers:WaitForChild("Toasts"))

local World = {}
local levels = {} -- [id] = { Layers = {part}, Sign = part }
local pits = {} -- [index] = { Barrier = part }
local original: { [BasePart]: number } = {}

local function numberFromName(name: string): number?
	return tonumber(name:match("(%d+)$"))
end

local function scan()
	local map = Workspace:WaitForChild("Map")
	local levelFolder = map:WaitForChild("Levels")
	for _, folder in ipairs(levelFolder:GetChildren()) do
		local id = numberFromName(folder.Name)
		local wall = folder:FindFirstChild("Wall")
		if id and wall then
			local layers = {}
			for _, layer in ipairs(wall:GetChildren()) do
				local n = numberFromName(layer.Name)
				if n and layer:IsA("BasePart") then
					layers[n] = layer
					original[layer] = layer.Transparency
				end
			end
			levels[id] = { Layers = layers, Sign = folder:FindFirstChild("Sign") }
		end
	end
	local pitFolder = map:WaitForChild("Hub"):FindFirstChild("Pits")
	if pitFolder then
		for _, model in ipairs(pitFolder:GetChildren()) do
			local n = numberFromName(model.Name)
			local barrier = model:FindFirstChild("LockBarrier")
			if n and barrier and barrier:IsA("BasePart") then
				pits[n] = { Barrier = barrier }
				original[barrier] = barrier.Transparency
			end
		end
	end
end

local function setVisible(part: BasePart, visible: boolean)
	part.Transparency = visible and (original[part] or 0) or 1
	part.CanCollide = visible
	part.CanQuery = visible
	for _, d in ipairs(part:GetDescendants()) do
		if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			d.Enabled = visible
		elseif d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = visible and 0 or 1
		end
	end
end

local function refresh()
	local data = State.Data
	if not data then
		return
	end
	for id, level in pairs(levels) do
		local prog = data.LevelProgress[tostring(id)] or 0
		for n, layer in pairs(level.Layers) do
			setVisible(layer, n > prog)
		end
		if level.Sign then
			local label = level.Sign:FindFirstChild("Progress", true)
			if label and label:IsA("TextLabel") then
				label.Text = ("Прогресс: %d / %d"):format(prog, LevelConfig.LayersPerLevel)
			end
		end
	end
	for index, pit in pairs(pits) do
		local cfg = PitConfig.Pits[index]
		local open = cfg ~= nil and data.Rebirths >= cfg.RequiredRebirths
		setVisible(pit.Barrier, not open)
	end
end

local function breakEffect(levelId: number, layerIndex: number)
	local level = levels[levelId]
	local layer = level and level.Layers[layerIndex]
	if not layer then
		return
	end
	for _ = 1, 14 do
		local chunk = Instance.new("Part")
		local s = 0.6 + math.random() * 1.2
		chunk.Size = Vector3.new(s, s, s)
		chunk.Color = layer.Color
		chunk.Material = layer.Material
		chunk.CanCollide = false
		chunk.CanQuery = false
		chunk.CanTouch = false
		local offset = Vector3.new((math.random() - 0.5) * layer.Size.X * 0.8, (math.random() - 0.3) * layer.Size.Y * 0.6, 0)
		chunk.CFrame = layer.CFrame * CFrame.new(offset)
		chunk.AssemblyLinearVelocity = layer.CFrame.LookVector * -(8 + math.random() * 12) + Vector3.new((math.random() - 0.5) * 16, 10 + math.random() * 12, 0)
		chunk.AssemblyAngularVelocity = Vector3.new(math.random() * 8, math.random() * 8, math.random() * 8)
		chunk.Parent = Workspace
		Debris:AddItem(chunk, 1.6)
	end
end

function World.Init()
	-- пиксельные текстуры карты (если ID указаны в TextureConfig)
	local ok, err = pcall(function()
		require(Shared:WaitForChild("TextureApplier")).Apply()
	end)
	if not ok then
		warn("[Textures]", err)
	end
	scan()
	State.Changed:Connect(refresh)
	Remotes.Event("Effect").OnClientEvent:Connect(function(kind, a, b)
		if kind == "Strength" then
			Toasts.Popup("+" .. Format.Short(a) .. " силы")
		elseif kind == "Break" then
			breakEffect(a, b)
		elseif kind == "Reward" then
			Toasts.Popup("+" .. Format.Short(b) .. " 🏆", Color3.fromRGB(255, 225, 77))
		end
	end)
end

return World
