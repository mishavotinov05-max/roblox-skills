--[[
	PickaxeLook — внешний вид кирки (одинаковый в руке, на спине и на витрине).

	Кирка собирается из обычных деталей в «своей» системе координат:
	  рукоять вдоль оси Y (низ в 0, верх в HANDLE_LENGTH), головка-полумесяц поперёк, вдоль оси Z.
	Цвета и эффект берутся из PickaxeConfig (Color, HandleColor, Accent, Effect).
	Хотите свою 3D-модель — положите Tool в ServerStorage › PickaxeModels с именем = Id кирки.
]]
local PickaxeLook = {}

PickaxeLook.HANDLE_LENGTH = 4.6
local L = PickaxeLook.HANDLE_LENGTH
local R = 3.2 -- радиус изгиба головки
local SEGMENTS = 11
local SPAN = 50 -- градусов в каждую сторону

local function darker(c: Color3, k: number): Color3
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

local function emitter(parent: Instance, color: Color3, rate: number, texture: string?, speed: number?, size: number?)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.LightEmission = 0.8
	e.Rate = rate
	e.Lifetime = NumberRange.new(0.5, 1)
	e.Speed = NumberRange.new(speed or 1, (speed or 1) * 2)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size or 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	if texture then
		e.Texture = texture
	end
	e.Parent = parent
	return e
end

-- Собирает модель кирки. origin — где будет низ рукояти (CFrame модели).
function PickaxeLook.Build(cfg, origin: CFrame?): Model
	origin = origin or CFrame.new()
	local model = Instance.new("Model")
	model.Name = "PickaxeLook"
	local head, handleColor = cfg.Color, cfg.HandleColor
	local accent = cfg.Accent or head
	local effect = cfg.Effect or ""
	local rare = effect ~= "" and effect ~= "shine"
	local headMat = (effect == "ice" or effect == "glow") and Enum.Material.Glass or Enum.Material.Metal

	local function add(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = origin * cf
		p.Color = color
		p.Material = material
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.Anchored = false
		p.CastShadow = material ~= Enum.Material.Neon
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then
			p.Shape = shape
		end
		if material == Enum.Material.SmoothPlastic or material == Enum.Material.Metal then
			p.Reflectance = 0.08
		end
		p.Parent = model
		return p
	end

	-- рукоять, обмотка, навершие
	local handle = add("Handle", Vector3.new(0.42, L, 0.42), CFrame.new(0, L / 2, 0), handleColor, Enum.Material.Wood)
	for i, y in ipairs({ 0.55, 0.95, 1.35 }) do
		add("Wrap" .. i, Vector3.new(0.5, 0.16, 0.5), CFrame.new(0, y, 0), darker(handleColor, 0.6), Enum.Material.Fabric)
	end
	add("Pommel", Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, 0.05, 0), rare and accent or darker(handleColor, 0.8), Enum.Material.Metal, Enum.PartType.Ball)
	add("Collar", Vector3.new(0.72, 0.95, 0.95), CFrame.new(0, L - 0.25, 0), darker(head, 0.75), Enum.Material.Metal)

	-- головка-полумесяц: сегменты по дуге, к концам тоньше
	local top = L + 0.3
	local seg = R * math.rad(SPAN * 2 / (SEGMENTS - 1)) * 1.3
	for i = 0, SEGMENTS - 1 do
		local deg = -SPAN + i * (SPAN * 2 / (SEGMENTS - 1))
		local t = math.rad(deg)
		local k = math.abs(deg) / SPAN
		local h = 1.0 * (1 - 0.65 * k) + 0.2
		local cf = CFrame.new(0, top - R * (1 - math.cos(t)), R * math.sin(t)) * CFrame.Angles(t, 0, 0)
		add("Head" .. i, Vector3.new(0.5, h, seg), cf, head, headMat)
		if rare then -- светящаяся жилка по головке
			add("Vein" .. i, Vector3.new(0.54, math.max(0.08, h * 0.22), seg * 0.95), cf * CFrame.new(0, -h * 0.1, 0), accent, Enum.Material.Neon)
		elseif effect == "shine" then
			add("Shine" .. i, Vector3.new(0.52, 0.08, seg * 0.9), cf * CFrame.new(0, h / 2 - 0.05, 0), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		end
	end
	-- острые кончики
	for _, sgn in ipairs({ -1, 1 }) do
		local t = math.rad(SPAN * sgn)
		local cf = CFrame.new(0, top - R * (1 - math.cos(t)), R * math.sin(t)) * CFrame.Angles(t, 0, 0) * CFrame.new(0, -0.05, sgn * seg * 0.75)
		local w = Instance.new("WedgePart")
		w.Name = sgn < 0 and "TipA" or "TipB"
		w.Size = Vector3.new(0.46, 0.3, 0.75)
		w.CFrame = origin * cf * CFrame.Angles(0, sgn < 0 and math.pi or 0, 0)
		w.Color = head
		w.Material = headMat
		w.CanCollide, w.CanQuery, w.CanTouch, w.Massless = false, false, false, true
		w.Parent = model
	end

	-- особые детали
	local center = model:FindFirstChild("Head" .. math.floor(SEGMENTS / 2)) :: BasePart
	if effect == "angel" then
		for _, sgn in ipairs({ -1, 1 }) do
			for f = 1, 3 do
				add(
					"Feather" .. sgn .. f,
					Vector3.new(0.2, 0.45, 1.6 - f * 0.25),
					CFrame.new(0, L - 0.6 + f * 0.35, sgn * (0.9 + f * 0.25)) * CFrame.Angles(math.rad(sgn * (25 + f * 12)), 0, 0),
					Color3.new(1, 1, 1),
					Enum.Material.SmoothPlastic
				)
			end
		end
		add("Halo", Vector3.new(0.12, 1.3, 1.3), CFrame.new(0, top + 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)), accent, Enum.Material.Neon, Enum.PartType.Cylinder)
	elseif effect == "devil" then
		for _, sgn in ipairs({ -1, 1 }) do
			add("Horn" .. sgn, Vector3.new(0.3, 0.9, 0.3), CFrame.new(0, top + 0.5, sgn * 0.5) * CFrame.Angles(math.rad(sgn * 25), 0, 0), accent, Enum.Material.Neon)
		end
	end

	-- свет и частицы у редких кирок
	if rare and center then
		local light = Instance.new("PointLight")
		light.Color = accent
		light.Range = 8
		light.Brightness = 1.2
		light.Parent = center
		local fx = {
			fire = { Color3.fromRGB(255, 140, 30), 14, "rbxasset://textures/particles/fire_main.dds", 2, 0.6 },
			ice = { Color3.fromRGB(200, 240, 255), 6, "rbxasset://textures/particles/sparkles_main.dds", 0.6, 0.35 },
			electric = { Color3.fromRGB(120, 220, 255), 10, "rbxasset://textures/particles/sparkles_main.dds", 3, 0.3 },
			cosmic = { Color3.fromRGB(220, 140, 255), 8, "rbxasset://textures/particles/sparkles_main.dds", 0.8, 0.4 },
			angel = { Color3.fromRGB(255, 240, 180), 6, "rbxasset://textures/particles/sparkles_main.dds", 0.6, 0.4 },
			shadow = { Color3.fromRGB(120, 40, 180), 10, "rbxasset://textures/particles/smoke_main.dds", 0.8, 0.8 },
			devil = { Color3.fromRGB(255, 60, 20), 12, "rbxasset://textures/particles/fire_main.dds", 1.5, 0.5 },
		}
		local f = fx[effect]
		if f then
			emitter(center, f[1], f[2], f[3], f[4], f[5])
		end
	end

	model.PrimaryPart = handle
	-- всё сварено с рукоятью
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p ~= handle then
			local w = Instance.new("WeldConstraint")
			w.Part0 = handle
			w.Part1 = p
			w.Parent = p
		end
	end
	return model
end

return PickaxeLook
