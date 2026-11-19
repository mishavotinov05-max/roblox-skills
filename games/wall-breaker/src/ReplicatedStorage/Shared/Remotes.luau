-- Remotes — сетевые события между сервером и клиентом.
-- Сервер создаёт их при старте, клиент ждёт.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	"Swing", -- клиент → сервер: удар киркой
	"DataUpdate", -- сервер → клиент: данные игрока
	"LevelState", -- сервер → клиент: уровень/слой/прочность
	"Notify", -- сервер → клиент: всплывающее сообщение
	"Effect", -- сервер → клиент: эффекты (сила, обломки)
}
local FUNCTIONS = {
	"Request", -- клиент → сервер: покупки и действия (с ответом)
}

local Remotes = {}
local folder: Folder? = nil

local function getFolder(): Folder
	if folder then
		return folder
	end
	if RunService:IsServer() then
		local f = ReplicatedStorage:FindFirstChild("Remotes")
		if not f then
			f = Instance.new("Folder")
			f.Name = "Remotes"
			f.Parent = ReplicatedStorage
		end
		for _, name in ipairs(EVENTS) do
			if not f:FindFirstChild(name) then
				local e = Instance.new("RemoteEvent")
				e.Name = name
				e.Parent = f
			end
		end
		for _, name in ipairs(FUNCTIONS) do
			if not f:FindFirstChild(name) then
				local e = Instance.new("RemoteFunction")
				e.Name = name
				e.Parent = f
			end
		end
		folder = f
	else
		folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	end
	return folder :: Folder
end

function Remotes.Event(name: string): RemoteEvent
	return getFolder():WaitForChild(name) :: RemoteEvent
end

function Remotes.Function(name: string): RemoteFunction
	return getFolder():WaitForChild(name) :: RemoteFunction
end

return Remotes
