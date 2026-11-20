--[[
	Popups — яйца:
	• EggPreview — когда подходишь к яйцу, появляется окно: какие питомцы могут выпасть,
	  их множители и шансы, и зелёная кнопка «Открыть».
	• EggOpen — анимация открытия как у кейсов: лента с питомцами быстро прокручивается,
	  замедляется и останавливается на выпавшем питомце, карточка увеличивается.
	Внешний вид: StarterGui › MainHud › EggPreview и EggOpen (можно перекрашивать в Studio).
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Config")
local PetConfig = require(Config:WaitForChild("PetConfig"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Controllers = script.Parent
local State = require(Controllers:WaitForChild("State"))
local Toasts = require(Controllers:WaitForChild("Toasts"))

local Popups = {}
local gui: ScreenGui
local player = Players.LocalPlayer
local currentEgg = nil -- конфиг яйца, у которого стоит игрок
local opening = false
local queue = {}

local PREVIEW_DISTANCE = 13

local function tween(obj: Instance, time: number, props, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function setText(root: Instance, name: string, text: string)
	local l = root:FindFirstChild(name, true)
	if l and (l:IsA("TextLabel") or l:IsA("TextButton")) then
		l.Text = text
	end
end

local function rarityColor(rarity: string?): Color3
	return (rarity and PetConfig.Rarities[rarity]) or Color3.fromRGB(170, 175, 190)
end

local function priceText(egg): string
	if egg.RobuxProduct then
		return ("💎 %d Robux"):format(egg.RobuxPrice or 0)
	end
	return ("🏆 %s Побед"):format(Format.Comma(egg.Price))
end

-- ===== Окно у яйца =====
local function fillPreview(egg)
	local frame = gui:FindFirstChild("EggPreview") :: Frame
	local box = frame:FindFirstChild("EggBox") :: Frame
	box.BackgroundColor3 = egg.Color
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = egg.Color
	end
	setText(box, "Title", (egg.Name:gsub(" ", "\n", 1)))
	setText(box, "Price", priceText(egg))
	local list = frame:FindFirstChild("Pets") :: Frame
	local template = list:FindFirstChild("PetTemplate") :: Frame
	for _, child in ipairs(list:GetChildren()) do
		if child.Name == "Pet" then
			child:Destroy()
		end
	end
	for i, entry in ipairs(egg.Pets) do
		local def = Catalog.Pets[entry[1]]
		if def then
			local card = template:Clone()
			card.Name = "Pet"
			card.Visible = true
			card.LayoutOrder = i
			setText(card, "Emoji", def.Emoji or "🐾")
			setText(card, "PetName", def.Name)
			setText(card, "Mult", ("x%s Силы"):format(Format.Short(def.Multiplier)))
			setText(card, "Chance", tostring(entry[2]) .. "%")
			local s = card:FindFirstChildOfClass("UIStroke")
			if s then
				s.Color = rarityColor(def.Rarity)
			end
			card.Parent = list
		end
	end
	setText(frame, "OpenButton", egg.RobuxProduct and ("Открыть за " .. tostring(egg.RobuxPrice) .. " R$") or "Открыть")
end

local function nearestEgg()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local map = Workspace:FindFirstChild("Map")
	local hub = map and map:FindFirstChild("Hub")
	local folder = hub and hub:FindFirstChild("Eggs")
	if not root or not folder then
		return nil
	end
	local best, bestDist = nil, PREVIEW_DISTANCE
	for _, model in ipairs(folder:GetChildren()) do
		local id = model.Name:match("^Egg_(.+)$")
		local egg = id and Catalog.Eggs[id]
		if egg and model:IsA("Model") then
			local p = model:GetPivot().Position
			local d = (Vector3.new(p.X, root.Position.Y, p.Z) - root.Position).Magnitude
			if d < bestDist then
				best, bestDist = egg, d
			end
		end
	end
	return best
end

-- ===== Анимация открытия (лента как у кейсов) =====
local CARD_W, CARD_GAP = 150, 10
local WIN_INDEX = 34

local function weightedPick(egg)
	local total = 0
	for _, e in ipairs(egg.Pets) do
		total += e[2]
	end
	local r = math.random() * total
	for _, e in ipairs(egg.Pets) do
		r -= e[2]
		if r <= 0 then
			return e[1]
		end
	end
	return egg.Pets[1][1]
end

local function makeCard(template: Frame, petId: string, index: number): Frame
	local def = Catalog.Pets[petId]
	local card = template:Clone()
	card.Name = "Card"
	card.Visible = true
	card.Position = UDim2.new(0, (index - 1) * (CARD_W + CARD_GAP), 0.5, 0)
	local col = rarityColor(def and def.Rarity)
	card.BackgroundColor3 = col:Lerp(Color3.fromRGB(25, 15, 45), 0.55)
	local spot = card:FindFirstChild("Spot")
	if spot and spot:IsA("Frame") then
		spot.BackgroundColor3 = col
	end
	local s = card:FindFirstChildOfClass("UIStroke")
	if s then
		s.Color = col
	end
	setText(card, "Emoji", def and def.Emoji or "🐾")
	setText(card, "PetName", def and def.Name or petId)
	setText(card, "Mult", def and ("x" .. Format.Short(def.Multiplier)) or "")
	return card
end

local function playOpen(eggId: string, petId: string)
	local egg = Catalog.Eggs[eggId]
	local def = Catalog.Pets[petId]
	local frame = gui:FindFirstChild("EggOpen") :: Frame
	local reel = frame:FindFirstChild("Reel") :: Frame
	local strip = reel:FindFirstChild("Strip") :: Frame
	local template = reel:FindFirstChild("CardTemplate") :: Frame
	local win = frame:FindFirstChild("WinCard") :: Frame
	if not egg or not frame then
		return
	end

	for _, c in ipairs(strip:GetChildren()) do
		c:Destroy()
	end
	for i = 1, WIN_INDEX + 5 do
		local id = i == WIN_INDEX and petId or weightedPick(egg)
		makeCard(template, id, i).Parent = strip
	end
	setText(frame, "Title", "Открываем: " .. egg.Name)
	frame.Visible = true
	reel.Visible = true
	win.Visible = false
	frame.BackgroundTransparency = 1
	tween(frame, 0.25, { BackgroundTransparency = 0.25 })

	-- карточка WIN_INDEX должна оказаться точно под маркером в центре
	local reelWidth = reel.AbsoluteSize.X > 0 and reel.AbsoluteSize.X or 760
	local jitter = (math.random() - 0.5) * (CARD_W * 0.6)
	local target = -((WIN_INDEX - 1) * (CARD_W + CARD_GAP) + CARD_W / 2 - reelWidth / 2 + jitter)
	strip.Position = UDim2.new(0, 0, 0, 0)
	local spin = tween(strip, 4.6, { Position = UDim2.new(0, target, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	spin.Completed:Wait()
	task.wait(0.25)

	-- выигрыш: карточка выезжает и увеличивается
	local col = rarityColor(def and def.Rarity)
	win.BackgroundColor3 = col
	setText(win, "Emoji", def and def.Emoji or "🐾")
	setText(win, "PetName", def and def.Name or petId)
	setText(win, "Rarity", def and def.Rarity or "")
	setText(win, "Mult", def and ("x%s Силы"):format(Format.Short(def.Multiplier)) or "")
	local scale = win:FindFirstChildOfClass("UIScale") :: UIScale
	scale.Scale = 0.4
	win.Visible = true
	tween(reel, 0.25, { BackgroundTransparency = 1 })
	reel.Visible = false
	tween(scale, 0.45, { Scale = 1.1 }, Enum.EasingStyle.Back).Completed:Wait()
	tween(scale, 0.2, { Scale = 1 })
	task.wait(1.6)
	tween(scale, 0.25, { Scale = 0 }).Completed:Wait()
	tween(frame, 0.2, { BackgroundTransparency = 1 }).Completed:Wait()
	frame.Visible = false
	reel.BackgroundTransparency = 0
	if def then
		Toasts.Show(("Выпал питомец: %s (x%s Силы)"):format(def.Name, Format.Short(def.Multiplier)), "pet")
	end
end

local function runQueue()
	if opening then
		return
	end
	opening = true
	while #queue > 0 do
		local item = table.remove(queue, 1)
		local ok, err = pcall(playOpen, item[1], item[2])
		if not ok then
			warn("[EggOpen]", err)
			local frame = gui:FindFirstChild("EggOpen")
			if frame and frame:IsA("GuiObject") then
				frame.Visible = false
			end
		end
	end
	opening = false
end

function Popups.Init()
	gui = player:WaitForChild("PlayerGui"):WaitForChild("MainHud") :: ScreenGui
	local preview = gui:WaitForChild("EggPreview") :: Frame
	local eggOpen = gui:WaitForChild("EggOpen") :: Frame
	preview.Visible = false
	eggOpen.Visible = false

	local openButton = preview:FindFirstChild("OpenButton", true)
	if openButton and openButton:IsA("GuiButton") then
		openButton.Activated:Connect(function()
			if not currentEgg or opening then
				return
			end
			local res = State.Request("OpenEgg", currentEgg.Id)
			if res and res.msg then
				Toasts.Show(res.msg, res.ok and "info" or "error")
			end
		end)
	end

	-- Показываем окно, когда игрок рядом с яйцом
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.2 then
			return
		end
		acc = 0
		local egg = nearestEgg()
		if egg ~= currentEgg then
			currentEgg = egg
			if egg then
				fillPreview(egg)
				preview.Visible = true
				local scale = preview:FindFirstChildOfClass("UIScale")
				if scale then
					scale.Scale = 0.8
					tween(scale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
				end
			else
				preview.Visible = false
			end
		end
		preview.Visible = currentEgg ~= nil and not opening
	end)

	Remotes.Event("Effect").OnClientEvent:Connect(function(kind, a, b)
		if kind == "Egg" then
			table.insert(queue, { a, b })
			task.spawn(runQueue)
		end
	end)
end

return Popups
