--[[
	TextureApplier — накладывает пиксельные текстуры (TextureConfig) на детали карты.
	Запускается автоматически у каждого игрока. Можно запустить и в Studio из Command Bar:
	  require(game.ReplicatedStorage.Shared.TextureApplier).Apply()
	тогда текстуры станут обычными объектами Texture внутри деталей.
]]
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TextureConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("TextureConfig"))

local TextureApplier = {}
local ALL = { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top, Enum.NormalId.Bottom }
local SIDES = { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
local TOP = { Enum.NormalId.Top }

local function valid(id: string?): boolean
	return type(id) == "string" and id ~= "" and id ~= "rbxassetid://0"
end

local function add(part: Instance?, id: string?, faces, tileU: number?, tileV: number?)
	if not part or not part:IsA("BasePart") or not valid(id) then
		return
	end
	for _, face in ipairs(faces) do
		local name = "AutoTexture_" .. face.Name
		if not part:FindFirstChild(name) then
			local t = Instance.new("Texture")
			t.Name = name
			t.Texture = id :: string
			t.Face = face
			t.StudsPerTileU = tileU or TextureConfig.StudsPerTile
			t.StudsPerTileV = tileV or TextureConfig.StudsPerTile
			t.Parent = part
		end
	end
end

local function tex(key: string): string?
	return TextureConfig.Textures[key]
end

local function grassCap(part: Instance)
	add(part, tex("grass_top"), TOP, 4, 4)
	if part:IsA("BasePart") then
		add(part, tex("grass_side"), SIDES, 4, part.Size.Y)
	end
end

local function each(folder: Instance?, fn)
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			fn(child)
		end
	end
end

function TextureApplier.Apply()
	local map = Workspace:FindFirstChild("Map")
	if not map then
		return
	end
	local hub = map:FindFirstChild("Hub")
	if hub then
		each(hub:FindFirstChild("Floor"), function(p)
			add(p, tex("floor_tiles"), TOP, 8, 8)
		end)
		each(hub:FindFirstChild("Walls"), function(p)
			if p.Name:sub(1, 5) == "Grass" then
				grassCap(p)
			else
				add(p, tex("brick"), ALL)
			end
		end)
		local entrance = hub:FindFirstChild("LevelEntrance")
		each(entrance, function(p)
			if p.Name:match("^Pillar") or p.Name == "Lintel" then
				add(p, tex("stone_brick"), ALL, 4, 4)
			end
		end)
		local shop = hub:FindFirstChild("PickaxeShop")
		each(shop and shop:FindFirstChild("Steps"), function(p)
			if p.Name:match("^Row") or p.Name:match("^Stair") then
				add(p, tex("stone_brick"), SIDES, 4, 4)
				add(p, tex("floor_tiles"), TOP, 8, 8)
			end
		end)
		each(hub:FindFirstChild("Pits"), function(pit)
			local n = tonumber(pit.Name:match("(%d+)$"))
			local key = n and TextureConfig.Pits[n]
			local id = type(key) == "number" and TextureConfig.Levels[key] or (type(key) == "string" and tex(key) or nil)
			if id then
				add(pit:FindFirstChild("PitFloor"), id, TOP, 4, 4)
				for _, side in ipairs({ "WallN", "WallS", "WallW", "WallE" }) do
					add(pit:FindFirstChild(side), id, ALL, 4, 4)
				end
			end
		end)
	end

	each(map:FindFirstChild("Levels"), function(level)
		local n = tonumber(level.Name:match("(%d+)$"))
		each(level:FindFirstChild("Structure"), function(p)
			if p.Name:match("^Grass") then
				grassCap(p)
			elseif p.Name == "Floor" or p.Name == "NicheFloor" then
				add(p, tex("floor_dark"), TOP, 8, 8)
			elseif p.Name:match("^Wall") or p.Name:match("^Niche") or p.Name == "EndWall" then
				add(p, tex("brick"), ALL)
			end
		end)
		local id = n and TextureConfig.Levels[n]
		each(level:FindFirstChild("Wall"), function(layer)
			add(layer, id, ALL, 6, 6)
		end)
	end)

	local ground = map:FindFirstChild("Ground")
	each(ground, function(p)
		if p:IsA("BasePart") then
			add(p, tex("grass_top"), TOP, 8, 8)
		end
	end)
	each(ground and ground:FindFirstChild("Terraces"), function(block)
		add(block:FindFirstChild("Brick"), tex("brick"), ALL)
		local g = block:FindFirstChild("Grass")
		if g then
			grassCap(g)
		end
	end)
end

return TextureApplier
