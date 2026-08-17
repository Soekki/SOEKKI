-- main_functions.lua - ПОЛНАЯ РАБОЧАЯ ВЕРСИЯ
-- ESP + НАМЕТАГИ + FULLBRIGHT + БАФФ СКОРОСТИ ПОЧИНКИ
-- Бафф работает через ремоуты RepairEvent / SkillCheckResultEvent
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================
--   НАСТРОЙКИ ESP
-- ============================================
local ESPConfig = {
    ShowGenerators = true,
    ShowGates = true,
    ShowPallets = true,
    ShowWindows = true,
    ShowHooks = true,
    ShowPlayers = true,
    ShowKillerWarning = true,
    FullBright = true,
}

-- ============================================
--   НАСТРОЙКИ БАФФА СКОРОСТИ ПОЧИНКИ
-- ============================================
local GeneratorBoostConfig = {
    Enabled = false,
    BoostPercent = 50, -- % скорости починки (0-100)
}

-- ============================================
--   КОНФИГУРАЦИЯ ЦВЕТОВ
-- ============================================
local Config = {
    Players = {
        Killer = { Color = Color3.fromRGB(255, 93, 108) },
        Survivor = { Color = Color3.fromRGB(64, 224, 255) },
    },
    Objects = {
        Generator = { Color = Color3.fromRGB(150, 0, 200) },
        Gate = { Color = Color3.fromRGB(255, 255, 255) },
        Pallet = { Color = Color3.fromRGB(74, 255, 181) },
        Window = { Color = Color3.fromRGB(74, 255, 181) },
        Hook = { Color = Color3.fromRGB(132, 255, 169) },
    },
}

-- ============================================
--   ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================

-- Табличка (BillboardGui) с текстом
local function CreateBillboardTag(text, color, size, fontSize)
    local gui = Instance.new("BillboardGui")
    gui.Size = size or UDim2.new(0, 60, 0, 20)
    gui.AlwaysOnTop = true
    gui.LightInfluence = 1

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.3
    label.TextSize = fontSize or 14
    label.Font = Enum.Font.GothamBold
    label.Parent = gui

    return gui
end

-- Подсветка объекта
local function ApplyHighlight(obj, color)
    if not obj:FindFirstChildOfClass("Highlight") then
        local h = Instance.new("Highlight")
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.7
        h.OutlineTransparency = 0.5
        h.Parent = obj
    end
end

local function RemoveHighlight(obj)
    local h = obj:FindFirstChildOfClass("Highlight")
    if h then h:Destroy() end
end

-- ============================================
--   НАМЕТАГИ ИГРОКОВ
-- ============================================
local Nametags = {}

local function updatePlayerNametag(p)
    local char = p.Character
    if not char then return end
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local tag = Nametags[p]
    if not tag or not tag.Parent then
        tag = CreateBillboardTag(p.Name, Config.Players.Survivor.Color, UDim2.new(0, 80, 0, 22), 14)
        tag.Name = "Nametag_" .. p.Name
        tag.Adornee = head
        tag.StudsOffset = Vector3.new(0, 3, 0)
        tag.Parent = head
        Nametags[p] = tag
    end

    local teamName = p.Team and p.Team.Name:lower() or ""
    local color = teamName:find("killer") and Config.Players.Killer.Color or Config.Players.Survivor.Color
    local label = tag:FindFirstChildOfClass("TextLabel")
    if label then
        label.Text = p.Name
        label.TextColor3 = color
    end
end

-- ============================================
--   ИНДИКАТОР УБИЙЦЫ (СВЕРХУ ЭКРАНА)
-- ============================================
local IndicatorGui = nil

local function SetupGui()
    if IndicatorGui then
        IndicatorGui:Destroy()
    end
    IndicatorGui = Instance.new("ScreenGui")
    IndicatorGui.Name = "SOEKKIIndicators"
    IndicatorGui.ResetOnSpawn = false
    IndicatorGui.IgnoreGuiInset = true
    IndicatorGui.Parent = PlayerGui
end

local function updateNextKillerDisplay()
    if not IndicatorGui then return end

    local killerName = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local teamName = p.Team and p.Team.Name:lower() or ""
            if teamName:find("killer") then
                killerName = p.Name
                break
            end
        end
    end

    local label = IndicatorGui:FindFirstChild("KillerLabel")
    if killerName then
        if not label then
            label = Instance.new("TextLabel")
            label.Name = "KillerLabel"
            label.Size = UDim2.new(0, 200, 0, 30)
            label.Position = UDim2.new(0.5, -100, 0, 10)
            label.BackgroundTransparency = 1
            label.TextStrokeTransparency = 0
            label.TextSize = 16
            label.Font = Enum.Font.GothamBold
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.Parent = IndicatorGui
        end
        label.Text = "Killer: " .. killerName
        label.TextColor3 = Config.Players.Killer.Color
    elseif label then
        label:Destroy()
    end
end

-- ============================================
--   ESP (ПОДСВЕТКА ОБЪЕКТОВ)
-- ============================================
local ActiveGenerators = {}

-- Возвращает true, если генератор больше не актуален
local function updateGeneratorProgress(g)
    local progress = g:GetAttribute("RepairProgress")
    if progress ~= nil and progress >= 100 then
        RemoveHighlight(g)
        return true
    end
    return false
end

local function RefreshESP()
    local Map = workspace:FindFirstChild("Map")
    if not Map then return end

    table.clear(ActiveGenerators)

    for _, obj in ipairs(Map:GetDescendants()) do
        if obj.Name == "Generator" then
            if ESPConfig.ShowGenerators then
                ApplyHighlight(obj, Config.Objects.Generator.Color)
                table.insert(ActiveGenerators, obj)
            else
                RemoveHighlight(obj)
            end
        elseif obj.Name == "Hook" then
            local m = obj:FindFirstChild("Model")
            if ESPConfig.ShowHooks and m then
                for _, p in ipairs(m:GetDescendants()) do
                    if p:IsA("MeshPart") then
                        ApplyHighlight(p, Config.Objects.Hook.Color)
                    end
                end
            elseif m then
                for _, p in ipairs(m:GetDescendants()) do
                    if p:IsA("MeshPart") then
                        RemoveHighlight(p)
                    end
                end
            end
        elseif obj.Name == "Palletwrong" or obj.Name == "Pallet" then
            if ESPConfig.ShowPallets then
                ApplyHighlight(obj, Config.Objects.Pallet.Color)
            else
                RemoveHighlight(obj)
            end
        elseif obj.Name == "Gate" then
            if ESPConfig.ShowGates then
                ApplyHighlight(obj, Config.Objects.Gate.Color)
            else
                RemoveHighlight(obj)
            end
        elseif obj.Name == "Window" then
            if ESPConfig.ShowWindows then
                ApplyHighlight(obj, Config.Objects.Window.Color)
            else
                RemoveHighlight(obj)
            end
        end
    end
end

-- ============================================
--   БАФФ СКОРОСТИ ПОЧИНКИ (ЧЕРЕЗ РЕМОУТЫ)
-- ============================================
local VD_RepairEvent = nil
local VD_SkillCheckEvent = nil

-- Ждём появления ремоутов (игра может ещё грузиться)
task.spawn(function()
    local tries = 0
    while tries < 60 do
        local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local Gen = Remotes and Remotes:FindFirstChild("Generator")
        if Gen then
            VD_RepairEvent = Gen:FindFirstChild("RepairEvent")
            VD_SkillCheckEvent = Gen:FindFirstChild("SkillCheckResultEvent")
            if VD_RepairEvent and VD_SkillCheckEvent then
                print("[SOEKKI] ✅ Ремоуты баффа найдены (RepairEvent + SkillCheckResultEvent)")
                return
            end
        end
        task.wait(0.2)
        tries = tries + 1
    end
    warn("[SOEKKI] ⚠️ Ремоуты баффа не найдены за 12 сек. Проверь ReplicatedStorage.Remotes.Generator")
end)

-- Поиск ближайшей точки ремонта (GeneratorPoint) у генератора рядом с игроком
local function findNearestRepairPoint(maxDist)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local Map = workspace:FindFirstChild("Map")
    if not Map then return nil end

    local best, bestDist = nil, maxDist
    for _, gen in ipairs(Map:GetDescendants()) do
        if gen.Name == "Generator" then
            for _, point in ipairs(gen:GetChildren()) do
                if point.Name:find("GeneratorPoint") then
                    local ok, d = pcall(function()
                        return (point.Position - root.Position).Magnitude
                    end)
                    if ok and d < bestDist then
                        best, bestDist = { gen = gen, point = point }, d
                    end
                end
            end
        end
    end
    return best
end

-- Цикл баффа: стартуем починку и сдаём успешные скилл-чеки
task.spawn(function()
    while true do
        if GeneratorBoostConfig.Enabled and VD_RepairEvent and VD_SkillCheckEvent then
            local target = findNearestRepairPoint(12)
            if target then
                pcall(function()
                    VD_RepairEvent:FireServer(target.point, true)
                    VD_SkillCheckEvent:FireServer("success", 1, target.gen, target.point)
                end)
            end
        end
        -- Скорость зависит от процента в меню:
        -- 0% -> 0.2s (как обычные автогены), 100% -> 0.05s
        local interval = 0.2 - (GeneratorBoostConfig.BoostPercent / 100) * 0.15
        task.wait(math.max(interval, 0.05))
    end
end)

-- ============================================
--   ЭКСПОРТ ФУНКЦИЙ
-- ============================================
local module = {}

function module.ToggleESP(option)
    ESPConfig[option] = not ESPConfig[option]
    RefreshESP()
    return ESPConfig[option]
end

function module.GetESPState(option)
    return ESPConfig[option]
end

function module.SetESPState(option, state)
    ESPConfig[option] = state
    RefreshESP()
    return ESPConfig[option]
end

function module.SetGeneratorBoostEnabled(enabled)
    GeneratorBoostConfig.Enabled = enabled
    print("[SOEKKI] Generator boost enabled:", enabled)
end

function module.GetGeneratorBoostEnabled()
    return GeneratorBoostConfig.Enabled
end

function module.SetGeneratorBoostPercent(percent)
    GeneratorBoostConfig.BoostPercent = math.clamp(percent, 0, 100)
    print("[SOEKKI] Generator boost percent:", GeneratorBoostConfig.BoostPercent .. "%")
end

function module.GetGeneratorBoostPercent()
    return GeneratorBoostConfig.BoostPercent
end

-- ============================================
--   FULLBRIGHT
-- ============================================
local OriginalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
}
local LastFullBrightState = nil

-- ============================================
--   ЗАПУСК / ОБНОВЛЕНИЯ
-- ============================================
local LastUpdateTick = 0
local LastFullESPRefresh = 0

SetupGui()
RefreshESP()

workspace.ChildAdded:Connect(function(c)
    if c.Name == "Map" then
        task.wait(1)
        RefreshESP()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    SetupGui()
    task.wait(1)
end)

RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - LastUpdateTick < 0.05 then return end
    LastUpdateTick = now

    -- Fullbright
    if ESPConfig.FullBright then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        LastFullBrightState = true
    elseif LastFullBrightState == true then
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.FogEnd = OriginalLighting.FogEnd
        LastFullBrightState = false
    end

    -- Периодический рефреш ESP (раз в 5 сек)
    if now - LastFullESPRefresh > 5 then
        LastFullESPRefresh = now
        RefreshESP()
    end

    updateNextKillerDisplay()

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local killerNearby = false

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if ESPConfig.ShowPlayers then
                updatePlayerNametag(p)
            end
            local pTeam = p.Team and p.Team.Name:lower() or ""
            if pTeam:find("killer") and myRoot and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude < 99 then
                    killerNearby = true
                end
            end
        end
    end

    -- Предупреждение об убийце рядом
    if myRoot and ESPConfig.ShowKillerWarning then
        local warn = myRoot:FindFirstChild("KillerWarn")
        if killerNearby then
            if not warn then
                warn = CreateBillboardTag("!", Color3.fromRGB(255, 0, 0), UDim2.new(0, 50, 0, 50), 40)
                warn.Name = "KillerWarn"
                warn.StudsOffset = Vector3.new(0, 4, 0)
                warn.Adornee = myRoot
                warn.Parent = myRoot
            end
        elseif warn then
            warn:Destroy()
        end
    end

    -- Обновление списка генераторов
    for i = #ActiveGenerators, 1, -1 do
        local g = ActiveGenerators[i]
        if g and g.Parent then
            if updateGeneratorProgress(g) then
                table.remove(ActiveGenerators, i)
            end
        else
            table.remove(ActiveGenerators, i)
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    local tag = Nametags[p]
    if tag then
        tag:Destroy()
        Nametags[p] = nil
    end
    if not IndicatorGui then return end
    local l = { p.Name .. "_Chased", p.Name .. "_Killer", p.Name }
    for _, n in ipairs(l) do
        local obj = IndicatorGui:FindFirstChild(n)
        if obj then obj:Destroy() end
    end
end)

-- Регистрируем в глобальном пространстве
_G.ESPModule = module
_G.ToggleESP = module.ToggleESP
_G.GetESPState = module.GetESPState
_G.SetESPState = module.SetESPState
_G.SetGeneratorBoostEnabled = module.SetGeneratorBoostEnabled
_G.GetGeneratorBoostEnabled = module.GetGeneratorBoostEnabled
_G.SetGeneratorBoostPercent = module.SetGeneratorBoostPercent
_G.GetGeneratorBoostPercent = module.GetGeneratorBoostPercent

print("[SOEKKI] Functions loaded!")
print("[SOEKKI] Generator boost system loaded!")

return module