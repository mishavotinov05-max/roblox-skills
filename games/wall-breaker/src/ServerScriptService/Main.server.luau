--[[
	Main — запуск серверных систем.
	Каждая система — отдельный модуль в папке Services.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
Remotes.Event("Swing") -- создаём папку Remotes до запуска остального

local Services = script.Parent:WaitForChild("Services")
local ORDER = {
	"DataService",
	"RequestService",
	"MonetizationService",
	"MapService",
	"BoostService",
	"PickaxeService",
	"TrainingService",
	"OreService",
	"WallService",
	"PetService",
	"AuraService",
	"RebirthService",
	"WheelService",
	"DailyService",
	"SwingService",
}

local modules = {}
for _, name in ipairs(ORDER) do
	modules[name] = require(Services:WaitForChild(name))
end
-- Сначала подключаем обработчики, потом DataService начинает загружать игроков
for _, name in ipairs(ORDER) do
	if name ~= "DataService" and modules[name].Init then
		modules[name].Init()
	end
end
modules.DataService.Init()
print("[WallBreaker] Сервер запущен")
