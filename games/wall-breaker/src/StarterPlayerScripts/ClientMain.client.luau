--[[
	ClientMain — запуск клиентских систем (интерфейс, удары, эффекты, питомцы).
	Каждая система — отдельный модуль в папке Controllers.
]]
local Controllers = script:WaitForChild("Controllers")

local ORDER = { "State", "Toasts", "Panels", "Hud", "World", "Swing", "Pets" }
for _, name in ipairs(ORDER) do
	local module = require(Controllers:WaitForChild(name))
	if module.Init then
		local ok, err = pcall(module.Init)
		if not ok then
			warn("[Client] " .. name .. ": " .. tostring(err))
		end
	end
end
