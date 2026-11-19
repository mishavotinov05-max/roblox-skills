--[[
	MapService — находит объекты карты по именам в Workspace › Map.
	Объекты можно свободно двигать, масштабировать и перекрашивать в Studio —
	скрипты ищут их по имени, а не по координатам.
]]
local Workspace = game:GetService("Workspace")

local MapService = {}

local function numberFromName(name: string): number?
	return tonumber(name:match("(%d+)$"))
end

local function sortedChildren(folder: Instance?, prefix: string)
	local list = {}
	if not folder then
		return list
	end
	for _, child in ipairs(folder:GetChildren()) do
		if child.Name:sub(1, #prefix) == prefix then
			local n = numberFromName(child.Name)
			if n then
				table.insert(list, { Index = n, Instance = child })
			end
		end
	end
	table.sort(list, function(a, b)
		return a.Index < b.Index
	end)
	return list
end

function MapService.Root(): Instance
	return Workspace:WaitForChild("Map")
end

function MapService.Hub(): Instance
	return MapService.Root():WaitForChild("Hub")
end

-- Точка внутри (повёрнутого) блока?
function MapService.PointInPart(part: BasePart, pos: Vector3, padding: number?): boolean
	local p = padding or 0
	local rel = part.CFrame:PointToObjectSpace(pos)
	local half = part.Size / 2
	return math.abs(rel.X) <= half.X + p and math.abs(rel.Y) <= half.Y + p and math.abs(rel.Z) <= half.Z + p
end

local levelsCache = nil
function MapService.Levels()
	if levelsCache then
		return levelsCache
	end
	local result = {}
	for _, entry in ipairs(sortedChildren(MapService.Root():WaitForChild("Levels"), "Level_")) do
		local folder = entry.Instance
		local wallFolder = folder:FindFirstChild("Wall")
		local layers = {}
		for _, l in ipairs(sortedChildren(wallFolder, "Layer_")) do
			layers[l.Index] = l.Instance
		end
		table.insert(result, {
			Id = entry.Index,
			Folder = folder,
			Zone = folder:FindFirstChild("Zone"),
			Layers = layers,
			Sign = folder:FindFirstChild("Sign"),
			RewardPad = folder:FindFirstChild("RewardPad"),
			LobbyPad = folder:FindFirstChild("LobbyPad"),
			MerchantSpot = folder:FindFirstChild("MerchantSpot"),
		})
	end
	levelsCache = result
	return result
end

function MapService.LevelAt(pos: Vector3)
	for _, level in ipairs(MapService.Levels()) do
		if level.Zone and MapService.PointInPart(level.Zone, pos) then
			return level
		end
	end
	return nil
end

function MapService.Pits()
	local result = {}
	for _, entry in ipairs(sortedChildren(MapService.Hub():FindFirstChild("Pits"), "Pit_")) do
		local model = entry.Instance
		table.insert(result, {
			Index = entry.Index,
			Model = model,
			Zone = model:FindFirstChild("TrainZone"),
			Barrier = model:FindFirstChild("LockBarrier"),
			Sign = model:FindFirstChild("Sign"),
		})
	end
	return result
end

function MapService.PickaxeSlots()
	local shop = MapService.Hub():FindFirstChild("PickaxeShop")
	local result = {}
	for _, entry in ipairs(sortedChildren(shop and shop:FindFirstChild("Slots"), "Slot_")) do
		table.insert(result, { Index = entry.Index, Model = entry.Instance, BuyPad = entry.Instance:FindFirstChild("BuyPad") })
	end
	return result
end

function MapService.Eggs()
	local folder = MapService.Hub():FindFirstChild("Eggs")
	local result = {}
	if folder then
		for _, model in ipairs(folder:GetChildren()) do
			local id = model.Name:match("^Egg_(.+)$")
			if id then
				table.insert(result, { Id = id, Model = model })
			end
		end
	end
	return result
end

function MapService.SpawnCFrame(): CFrame
	local spawn = MapService.Hub():FindFirstChild("SpawnLocation") :: BasePart?
	if spawn then
		return spawn.CFrame + Vector3.new(0, 4, 0)
	end
	return CFrame.new(0, 10, 0)
end

-- Ищет ProximityPrompt внутри объекта
function MapService.FindPrompt(inst: Instance?): ProximityPrompt?
	if not inst then
		return nil
	end
	return inst:FindFirstChildWhichIsA("ProximityPrompt", true)
end

-- Текст в SurfaceGui/BillboardGui по имени TextLabel
function MapService.SetText(inst: Instance?, labelName: string, text: string)
	if not inst then
		return
	end
	local label = inst:FindFirstChild(labelName, true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

return MapService
