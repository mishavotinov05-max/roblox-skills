--[[
	Graphics — режимы графики (Настройки › Графика): Low / Medium / High.
	Меняет только то, что видит этот игрок. Значения режимов — в таблице MODES ниже.
	Сами эффекты лежат в Explorer › Lighting (Bloom, SunRays, Atmosphere, ColorCorrection).
]]
local Lighting = game:GetService("Lighting")
local Controllers = script.Parent
local State = require(Controllers:WaitForChild("State"))

local Graphics = {}

local MODES = {
	Low = { Shadows = false, Bloom = false, SunRays = false, Atmosphere = false, Particles = 0.3 },
	Medium = { Shadows = true, Bloom = true, SunRays = false, Atmosphere = true, Particles = 0.6 },
	High = { Shadows = true, Bloom = true, SunRays = true, Atmosphere = true, Particles = 1 },
}
Graphics.ParticleScale = 1
local current = nil

local function apply(mode: string)
	local m = MODES[mode] or MODES.High
	Lighting.GlobalShadows = m.Shadows
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		bloom.Enabled = m.Bloom
	end
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if rays then
		rays.Enabled = m.SunRays
	end
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then
		atm.Density = m.Atmosphere and 0.22 or 0
	end
	Graphics.ParticleScale = m.Particles
end

function Graphics.Init()
	State.Changed:Connect(function()
		local mode = State.Data and State.Data.Settings.Graphics or "High"
		if mode ~= current then
			current = mode
			apply(mode)
		end
	end)
end

return Graphics
