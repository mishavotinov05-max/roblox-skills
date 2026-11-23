-- Toasts — всплывающие сообщения и цифры «+сила»
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local Toasts = {}
local container: Frame
local active = {}

local COLORS = {
	info = Color3.fromRGB(255, 255, 255),
	success = Color3.fromRGB(120, 255, 160),
	error = Color3.fromRGB(255, 120, 120),
	wins = Color3.fromRGB(255, 225, 77),
	pet = Color3.fromRGB(255, 160, 240),
	event = Color3.fromRGB(120, 220, 255),
}

local function makeLabel(text: string, color: Color3, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0, 700, 0, size)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(26, 16, 51)
	stroke.Parent = label
	return label
end

function Toasts.Show(text: string, kind: string?)
	kind = kind or "info"
	local color = COLORS[kind] or COLORS.info
	if kind and kind:sub(1, 4) == "ore:" then
		color = Color3.fromRGB(255, 200, 120)
	end
	local label = makeLabel(text, color, 40)
	label.Position = UDim2.new(0.5, 0, 0.3, 0)
	label.Parent = container
	table.insert(active, 1, label)
	for i, l in ipairs(active) do
		if l.Parent then
			TweenService:Create(l, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 0.3, (i - 1) * 46) }):Play()
		end
	end
	label.Size = UDim2.new(0, 500, 0, 30)
	TweenService:Create(label, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.new(0, 700, 0, 40) }):Play()
	task.delay(2.6, function()
		local t = TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 })
		t:Play()
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		end
		t.Completed:Wait()
		local i = table.find(active, label)
		if i then
			table.remove(active, i)
		end
		label:Destroy()
	end)
end

-- Летящая вверх цифра (например «+12 силы»)
function Toasts.Popup(text: string, color: Color3?)
	local label = makeLabel(text, color or Color3.fromRGB(255, 225, 77), 30)
	label.Size = UDim2.new(0, 260, 0, 30)
	local x = 0.5 + (math.random() - 0.5) * 0.12
	label.Position = UDim2.new(x, 0, 0.62, 0)
	label.Parent = container
	TweenService:Create(label, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { Position = UDim2.new(x, 0, 0.5, 0), TextTransparency = 1 }):Play()
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		TweenService:Create(stroke, TweenInfo.new(0.9), { Transparency = 1 }):Play()
	end
	game:GetService("Debris"):AddItem(label, 1)
end

-- Летящее число с иконкой (например, бицепс у «+сила»)
function Toasts.IconPopup(text: string, icon: string, color: Color3?)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Size = UDim2.new(0, 220, 0, 44)
	local x = 0.5 + (math.random() - 0.5) * 0.16
	holder.Position = UDim2.new(x, 0, 0.62, 0)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.Parent = holder
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.new(0, 40, 0, 40)
	img.Image = icon
	img.LayoutOrder = 1
	img.Parent = holder
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.new(0, 0, 0, 36)
	label.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)
	label.TextSize = 34
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 225, 77)
	label.LayoutOrder = 2
	label.Parent = holder
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	holder.Parent = container
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad)
	TweenService:Create(holder, info, { Position = UDim2.new(x, 0, 0.48, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	TweenService:Create(img, info, { ImageTransparency = 1 }):Play()
	game:GetService("Debris"):AddItem(holder, 1)
end

-- Если части старого интерфейса удалены — не ждём их вечно, а создаём пустой слой
local function hudLayer(name: string): Frame
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = pg:WaitForChild("MainHud", 5)
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "MainHud"
		gui.ResetOnSpawn = false
		gui.Parent = pg
	end
	local layer = gui:FindFirstChild(name)
	if not layer then
		local f = Instance.new("Frame")
		f.Name = name
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundTransparency = 1
		f.ZIndex = 20
		f.Parent = gui
		layer = f
	end
	return layer :: Frame
end

function Toasts.Init()
	container = hudLayer("Toasts")
	container.Visible = true -- в редакторе слой выключен, чтобы не мешал кликам
	Remotes.Event("Notify").OnClientEvent:Connect(Toasts.Show)
end

return Toasts
