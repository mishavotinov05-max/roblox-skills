--[[
	RequestService — единая точка для действий игрока из интерфейса (покупки, надеть и т.д.).
	Каждый сервис регистрирует свои действия через RequestService.Register("Имя", функция).
	Здесь же — защита от спама и уведомления.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local RequestService = {}
local handlers = {}
local callLog: { [Player]: { number } } = {}

function RequestService.Register(name: string, fn)
	handlers[name] = fn
end

function RequestService.Notify(player: Player, text: string, kind: string?)
	Remotes.Event("Notify"):FireClient(player, text, kind or "info")
end

function RequestService.NotifyAll(text: string, kind: string?)
	Remotes.Event("Notify"):FireAllClients(text, kind or "info")
end

local function rateLimited(player: Player): boolean
	local now = os.clock()
	local log = callLog[player] or {}
	callLog[player] = log
	while #log > 0 and now - log[1] > 1 do
		table.remove(log, 1)
	end
	if #log >= 12 then
		return true
	end
	table.insert(log, now)
	return false
end

function RequestService.Init()
	Remotes.Function("Request").OnServerInvoke = function(player: Player, action: any, ...)
		if type(action) ~= "string" or not handlers[action] then
			return { ok = false }
		end
		if rateLimited(player) then
			return { ok = false, msg = "Слишком быстро!" }
		end
		if not DataService.Get(player) then
			return { ok = false, msg = "Данные ещё загружаются…" }
		end
		local ok, result = pcall(handlers[action], player, ...)
		if not ok then
			warn("[Request]", action, result)
			return { ok = false, msg = "Ошибка, попробуйте ещё раз" }
		end
		return result or { ok = true }
	end

	-- Настройки игрока (автоклик, показ питомцев)
	RequestService.Register("SetSetting", function(player, key, value)
		local data = DataService.Get(player)
		if key == "Graphics" and (value == "Low" or value == "Medium" or value == "High") then
			data.Settings.Graphics = value
			DataService.MarkDirty(player)
			return { ok = true }
		end
		if (key == "AutoClick" or key == "ShowPets") and type(value) == "boolean" then
			data.Settings[key] = value
			DataService.MarkDirty(player)
			return { ok = true }
		end
		return { ok = false }
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		callLog[player] = nil
	end)
end

return RequestService
