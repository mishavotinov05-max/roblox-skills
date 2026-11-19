--[[
	Popups — анимация открытия яйца и окно выбора награды после стены.
	Внешний вид: StarterGui › MainHud › EggOpen и LevelChoice (можно перекрашивать).
]]
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Controllers = script.Parent
local State = require(Controllers:WaitForChild("State"))
local Toasts = require(Controllers:WaitForChild("Toasts"))

local Popups = {}
local gui: ScreenGui
local eggQueue = {}
local eggPlaying = false

local RARITY_COLORS = {
	["Обычный"] = Color3.fromRGB(200, 205, 220),
	["Необычный"] = Color3.fromRGB(110, 230, 120),
	["Редкий"] = Color3.fromRGB(80, 170, 255),
	["Эпический"] = Color3.fromRGB(190, 110, 255),
	["Легендарный"] = Color3.fromRGB(255, 200, 40),
}

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

local function eggColor(eggId: string): Color3
	local map = Workspace:FindFirstChild("Map")
	local model = map and map:FindFirstChild("Hub") and map.Hub:FindFirstChild("Eggs") and map.Hub.Eggs:FindFirstChild("Egg_" .. eggId)
	local part = model and model:FindFirstChild("Egg")
	if part and part:IsA("BasePart") then
		return part.Color
	end
	return Color3.fromRGB(240, 240, 255)
end

-- ===== Открытие яйца =====
local function playEgg(eggId: string, petId: string)
	local frame = gui:FindFirstChild("EggOpen") :: Frame?
	if not frame then
		return
	end
	local egg = frame:FindFirstChild("Egg") :: Frame
	local flash = frame:FindFirstChild("Flash") :: Frame
	local rays = frame:FindFirstChild("Rays") :: Frame
	local card = frame:FindFirstChild("PetCard") :: Frame
	local def = Catalog.Pets[petId]
	local rarityColor = def and RARITY_COLORS[def.Rarity] or Color3.new(1, 1, 1)

	frame.Visible = true
	frame.BackgroundTransparency = 1
	tween(frame, 0.25, { BackgroundTransparency = 0.35 })
	egg.Visible = true
	egg.BackgroundColor3 = eggColor(eggId)
	egg.Rotation = 0
	local eggScale = egg:FindFirstChildOfClass("UIScale") :: UIScale
	eggScale.Scale = 0
	tween(eggScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back).Completed:Wait()

	-- тряска, всё сильнее
	for i = 1, 8 do
		local angle = (i % 2 == 0 and 1 or -1) * (6 + i * 2)
		tween(egg, 0.09, { Rotation = angle }).Completed:Wait()
	end
	tween(egg, 0.08, { Rotation = 0 }).Completed:Wait()
	tween(eggScale, 0.15, { Scale = 1.25 }).Completed:Wait()

	-- вспышка
	flash.Visible = true
	flash.BackgroundTransparency = 0
	egg.Visible = false
	tween(flash, 0.5, { BackgroundTransparency = 1 })

	-- питомец
	rays.Visible = true
	rays.Rotation = 0
	for _, r in ipairs(rays:GetChildren()) do
		if r:IsA("Frame") then
			r.BackgroundColor3 = rarityColor
		end
	end
	tween(rays, 3, { Rotation = 120 }, Enum.EasingStyle.Linear)
	card.Visible = true
	local cardScale = card:FindFirstChildOfClass("UIScale") :: UIScale
	cardScale.Scale = 0
	setText(card, "PetIcon", "🐾")
	local icon = card:FindFirstChild("PetIcon")
	if icon and icon:IsA("TextLabel") and def then
		icon.TextColor3 = def.Color
	end
	setText(card, "PetName", def and def.Name or petId)
	setText(card, "PetRarity", def and def.Rarity or "")
	local rarity = card:FindFirstChild("PetRarity")
	if rarity and rarity:IsA("TextLabel") then
		rarity.TextColor3 = rarityColor
	end
	setText(card, "PetBonus", def and ("+" .. tostring(def.Bonus) .. " к силе") or "")
	tween(cardScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	task.wait(1.8)

	tween(frame, 0.3, { BackgroundTransparency = 1 })
	tween(cardScale, 0.25, { Scale = 0 }).Completed:Wait()
	frame.Visible = false
	rays.Visible = false
	card.Visible = false
	flash.Visible = false
	if def then
		Toasts.Show(("Выпал питомец: %s (%s)"):format(def.Name, def.Rarity), "pet")
	end
end

local function runEggQueue()
	if eggPlaying then
		return
	end
	eggPlaying = true
	while #eggQueue > 0 do
		local item = table.remove(eggQueue, 1)
		local ok, err = pcall(playEgg, item[1], item[2])
		if not ok then
			warn("[EggOpen]", err)
		end
	end
	eggPlaying = false
end

-- ===== Выбор награды после стены =====
local function showLevelChoice(info)
	local frame = gui:FindFirstChild("LevelChoice") :: Frame?
	if not frame then
		return
	end
	local reward = info.Reward
	setText(frame, "Title", ("Уровень %d · %s пройден!"):format(info.Level, info.Name))
	if info.HasNext then
		setText(frame, "Info", ("Награда сейчас: %s побед.\nИди дальше — за уровень %d дадут %s!"):format(
			Format.Short(reward),
			info.Level + 1,
			Format.Short(info.NextReward)
		))
	else
		setText(frame, "Info", ("Это последний уровень! Награда: %s побед."):format(Format.Short(reward)))
	end
	local free = frame:FindFirstChild("FreeButton", true)
	local x3 = frame:FindFirstChild("X3Button", true)
	local cont = frame:FindFirstChild("ContinueButton", true)
	if free and free:IsA("TextButton") then
		free.Text = info.HasPass and ("+%s 🏆 (×3) и в лобби"):format(Format.Short(reward * 3)) or ("+%s 🏆 и в лобби"):format(Format.Short(reward))
	end
	if x3 and x3:IsA("TextButton") then
		x3.Visible = not info.HasPass
		x3.Text = ("×3 = %s 🏆 и в лобби  (Robux)"):format(Format.Short(reward * 3))
	end
	if cont and cont:IsA("TextButton") then
		cont.Text = info.HasNext and "Идти дальше →" or "Закрыть"
	end
	frame.Visible = true
	local scale = frame:FindFirstChildOfClass("UIScale")
	if scale then
		scale.Scale = 0.6
		tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	end
end

local function hideLevelChoice()
	local frame = gui:FindFirstChild("LevelChoice")
	if frame and frame:IsA("GuiObject") then
		frame.Visible = false
	end
end

local function request(action: string)
	local res = State.Request(action)
	if res and res.msg then
		Toasts.Show(res.msg, res.ok and "info" or "error")
	end
	return res
end

function Popups.Init()
	gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainHud") :: ScreenGui

	local choice = gui:WaitForChild("LevelChoice")
	local function bind(name: string, fn)
		local b = choice:FindFirstChild(name, true)
		if b and b:IsA("GuiButton") then
			b.Activated:Connect(fn)
		end
	end
	bind("FreeButton", function()
		local res = request("CashOutLevel")
		if res and res.ok then
			hideLevelChoice()
		end
	end)
	bind("X3Button", function()
		local res = request("LevelRewardX3")
		if res and res.ok then
			hideLevelChoice()
		end
	end)
	bind("ContinueButton", hideLevelChoice)

	-- Кнопка «Забрать награду» на панели уровня (если пошли дальше, а потом передумали)
	local cashOut = gui:FindFirstChild("LevelPanel") and gui.LevelPanel:FindFirstChild("CashOutButton")
	if cashOut and cashOut:IsA("TextButton") then
		cashOut.Activated:Connect(function()
			request("CashOutLevel")
		end)
		Remotes.Event("LevelState").OnClientEvent:Connect(function(info)
			local best = info and info.RunBest or 0
			cashOut.Visible = best > 0
			if best > 0 then
				local mult = State.HasPass("WinsX3") and 3 or 1
				cashOut.Text = ("Забрать +%s 🏆 и в лобби"):format(Format.Short(info.RunReward * mult))
			end
		end)
	end

	local egg = gui:FindFirstChild("EggOpen")
	if egg and egg:IsA("GuiObject") then
		egg.Visible = false
	end

	Remotes.Event("Effect").OnClientEvent:Connect(function(kind, a, b)
		if kind == "Egg" then
			table.insert(eggQueue, { a, b })
			task.spawn(runEggQueue)
		elseif kind == "LevelComplete" then
			showLevelChoice(a)
		elseif kind == "Reward" then
			hideLevelChoice()
		end
	end)
end

return Popups
