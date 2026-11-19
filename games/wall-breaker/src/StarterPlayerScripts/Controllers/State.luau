-- State — последние данные игрока с сервера + отправка запросов
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local State = {
	Snapshot = nil, -- { Data = ..., Passes = ..., RebirthCost = ..., ... }
	Data = nil,
	ReceivedAt = 0,
}
local changed = Instance.new("BindableEvent")
State.Changed = changed.Event

function State.Init()
	Remotes.Event("DataUpdate").OnClientEvent:Connect(function(snapshot)
		State.Snapshot = snapshot
		State.Data = snapshot.Data
		State.ReceivedAt = os.clock()
		changed:Fire(snapshot)
	end)
end

function State.HasPass(key: string): boolean
	return State.Snapshot ~= nil and State.Snapshot.Passes ~= nil and State.Snapshot.Passes[key] == true
end

-- Сколько секунд осталось до момента, который сервер прислал как "...ReadyIn"
function State.Countdown(field: string): number
	if not State.Snapshot or not State.Snapshot[field] then
		return 0
	end
	return math.max(0, State.Snapshot[field] - (os.clock() - State.ReceivedAt))
end

-- Отправить действие на сервер. Возвращает таблицу { ok = bool, msg = string? }
function State.Request(action: string, ...): any
	local args = table.pack(...)
	local ok, result = pcall(function()
		return Remotes.Function("Request"):InvokeServer(action, table.unpack(args, 1, args.n))
	end)
	if not ok then
		return { ok = false, msg = "Нет связи с сервером" }
	end
	return result or { ok = false }
end

return State
