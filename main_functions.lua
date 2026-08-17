-- main_functions.lua - ИСПОЛЬЗУЕМ ОРИГИНАЛЬНЫЙ ОБРАБОТЧИК
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("[SOEKKI] ========================================")
print("[SOEKKI] ЗАГРУЗКА main_functions.lua (v2)")
print("[SOEKKI] ========================================")

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
--   НАСТРОЙКИ БАФФА ГЕНЕРАТОРОВ
-- ============================================
local GeneratorBoostConfig = {
    Enabled = false,
    BoostPercent = 50,
}

-- ============================================
--   КОНФИГУРАЦИЯ
-- ============================================
local Config = {
    Players = {
        Killer = {Color = Color3.fromRGB(255, 93, 108)}, 
        Survivor = {Color = Color3.fromRGB(64, 224, 255)}
    },
    Objects = {
        Generator = {Color = Color3.fromRGB(150, 0, 200)}, 
        Gate = {Color = Color3.fromRGB(255, 255, 255)},
        Pallet = {Color = Color3.fromRGB(74, 255, 181)}, 
        Window = {Color = Color3.fromRGB(74, 255, 181)},
        Hook = {Color = Color3.fromRGB(132, 255, 169)}
    }
}

local MaskNames = {
    ["Richard"] = "Rooster",
    ["Tony"] = "Tiger",
    ["Brandon"] = "Panther",
    ["Cobra"] = "Cobra",
    ["Richter"] = "Rat",
    ["Rabbit"] = "Rabbit",
    ["Alex"] = "Chainsaw"
}

local MaskColors = {
    ["Richard"] = Color3.fromRGB(255, 0, 0),
    ["Tony"] = Color3.fromRGB(255, 255, 0),
    ["Brandon"] = Color3.fromRGB(160, 32, 240),
    ["Cobra"] = Color3.fromRGB(0, 255, 0),
    ["Richter"] = Color3.fromRGB(0, 0, 0),
    ["Rabbit"] = Color3.fromRGB(255, 105, 180),
    ["Alex"] = Color3.fromRGB(255, 255, 255)
}

local ActiveGenerators = {}
local LastUpdateTick = 0
local LastFullESPRefresh = 0
local IndicatorGui = nil

-- ============================================
--   СИСТЕМА БАФФА - НОВЫЙ ПОДХОД
-- ============================================
local activeBoosts = {}
local originalRepairAnimHandler = nil
local repairAnimConnection = nil
local currentGenerator = nil
local isRepairing = false

-- Получаем ремоуты
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local Generator = Remotes and Remotes:FindFirstChild("Generator")
local RepairAnim = Generator and Generator:FindFirstChild("RepairAnim")
local RepairEvent = Generator and Generator:FindFirstChild("RepairEvent")

print("[SOEKKI] RepairAnim найден:", RepairAnim ~= nil)
print("[SOEKKI] RepairAnim uniqueid:", RepairAnim and RepairAnim:GetAttribute("uniqueid") or "none")
print("[SOEKKI] RepairEvent найден:", RepairEvent ~= nil)

-- ============================================
--   МЕТОД 1: ПЕРЕХВАТ ОРИГИНАЛЬНОГО ОБРАБОТЧИКА
-- ============================================
local function hookOriginalHandler()
    print("[SOEKKI] [hookOriginalHandler] Пытаемся перехватить оригинальный обработчик...")
    
    -- Ищем скрипты, которые подписываются на RepairAnim
    local scripts = {}
    
    -- Проверяем все скрипты в ReplicatedStorage
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            table.insert(scripts, obj)
        end
    end
    
    -- Проверяем все скрипты в Workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            table.insert(scripts, obj)
        end
    end
    
    print("[SOEKKI] Найдено скриптов:", #scripts)
    
    -- Ищем скрипт, который содержит "RepairAnim"
    for _, script in ipairs(scripts) do
        local source = script:FindFirstChild("Source") or script:FindFirstChild("Value")
        if source then
            local text = source.Value or ""
            if string.find(text, "RepairAnim") then
                print("[SOEKKI] Найден скрипт с RepairAnim:", script:GetFullName())
            end
        end
    end
end

-- ============================================
--   МЕТОД 2: ИСПОЛЬЗУЕМ МОНИТОРИНГ АТРИБУТОВ
-- ============================================
local function monitorGenerators()
    print("[SOEKKI] [monitorGenerators] Запуск...")
    
    while true do
        if GeneratorBoostConfig.Enabled then
            local allGenerators = CollectionService:GetTagged("Generator")
            
            for _, generator in ipairs(allGenerators) do
                if generator:IsDescendantOf(workspace) then
                    -- Получаем атрибуты
                    local playersRepairing = 0
                    local repairProgress = 0
                    
                    pcall(function()
                        local count = generator:GetAttribute("PlayersRepairingCount")
                        if count ~= nil and type(count) == "number" then
                            playersRepairing = count
                        end
                        
                        local progress = generator:GetAttribute("RepairProgress")
                        if progress ~= nil and type(progress) == "number" then
                            repairProgress = progress
                        end
                    end)
                    
                    -- Если генератор чинится
                    if playersRepairing > 0 and repairProgress < 100 then
                        if not activeBoosts[generator] then
                            print("[SOEKKI] 🟢 Генератор чинится:", generator.Name)
                            print("[SOEKKI]    PlayersRepairingCount:", playersRepairing)
                            print("[SOEKKI]    RepairProgress:", string.format("%.1f%%", repairProgress))
                            
                            -- Применяем бафф через атрибуты
                            local boostMultiplier = 1 + (GeneratorBoostConfig.BoostPercent / 100)
                            
                            pcall(function()
                                generator:SetAttribute("repairboost", boostMultiplier)
                                generator:SetAttribute("BoostMultiplier", boostMultiplier)
                                generator:SetAttribute("RepairBoost", boostMultiplier)
                                generator:SetAttribute("GeneratorBoost", boostMultiplier)
                                
                                -- Также на все части
                                for _, part in ipairs(generator:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        part:SetAttribute("repairboost", boostMultiplier)
                                    end
                                end
                            end)
                            
                            activeBoosts[generator] = boostMultiplier
                            print("[SOEKKI] ✅ Бафф применен: x" .. string.format("%.2f", boostMultiplier))
                        end
                    elseif activeBoosts[generator] then
                        -- Если перестали чинить
                        print("[SOEKKI] 🔴 Генератор больше не чинится:", generator.Name)
                        
                        pcall(function()
                            generator:SetAttribute("repairboost", nil)
                            generator:SetAttribute("BoostMultiplier", nil)
                            generator:SetAttribute("RepairBoost", nil)
                            generator:SetAttribute("GeneratorBoost", nil)
                            
                            for _, part in ipairs(generator:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part:SetAttribute("repairboost", nil)
                                end
                            end
                        end)
                        
                        activeBoosts[generator] = nil
                        print("[SOEKKI] ❌ Бафф снят")
                    end
                end
            end
        else
            -- Если бафф выключен - чистим всё
            for generator, _ in pairs(activeBoosts) do
                pcall(function()
                    generator:SetAttribute("repairboost", nil)
                    generator:SetAttribute("BoostMultiplier", nil)
                    generator:SetAttribute("RepairBoost", nil)
                    generator:SetAttribute("GeneratorBoost", nil)
                end)
            end
            table.clear(activeBoosts)
        end
        
        task.wait(0.3)
    end
end

-- ============================================
--   МЕТОД 3: ПЕРЕХВАТ RepairedEvent
-- ============================================
local function setupRepairEvent()
    if RepairEvent then
        print("[SOEKKI] [setupRepairEvent] Подключаем RepairEvent...")
        
        -- Сохраняем оригинальные обработчики
        local connections = {}
        
        -- Создаем новый обработчик
        RepairEvent.OnClientEvent:Connect(function(repairPoint, isRepairing, ...)
            print("[SOEKKI] [RepairEvent] Вызван!")
            print("[SOEKKI]    repairPoint:", repairPoint)
            print("[SOEKKI]    isRepairing:", isRepairing)
            
            if repairPoint and repairPoint.Parent then
                local generator = repairPoint.Parent
                print("[SOEKKI]    generator:", generator and generator.Name or "nil")
                
                if generator and CollectionService:HasTag(generator, "Generator") then
                    currentGenerator = generator
                    
                    if isRepairing and GeneratorBoostConfig.Enabled then
                        local boostMultiplier = 1 + (GeneratorBoostConfig.BoostPercent / 100)
                        pcall(function()
                            generator:SetAttribute("repairboost", boostMultiplier)
                            generator:SetAttribute("BoostMultiplier", boostMultiplier)
                        end)
                        activeBoosts[generator] = boostMultiplier
                        print("[SOEKKI] ✅ Бафф применен через RepairEvent")
                    elseif not isRepairing then
                        pcall(function()
                            generator:SetAttribute("repairboost", nil)
                            generator:SetAttribute("BoostMultiplier", nil)
                        end)
                        activeBoosts[generator] = nil
                        print("[SOEKKI] ❌ Бафф снят через RepairEvent")
                    end
                end
            end
        end)
    end
end

-- ============================================
--   МЕТОД 4: ПРЯМОЙ ДОСТУП К ИГРЕ (для отладки)
-- ============================================
local function debugGeneratorState()
    print("[SOEKKI] ========================================")
    print("[SOEKKI] [debugGeneratorState] ТЕКУЩЕЕ СОСТОЯНИЕ:")
    
    local allGenerators = CollectionService:GetTagged("Generator")
    print("[SOEKKI] Всего генераторов:", #allGenerators)
    
    for _, gen in ipairs(allGenerators) do
        if gen:IsDescendantOf(workspace) then
            local progress = gen:GetAttribute("RepairProgress") or 0
            local count = gen:GetAttribute("PlayersRepairingCount") or 0
            local boost = gen:GetAttribute("repairboost") or "none"
            
            print("[SOEKKI]   -", gen.Name)
            print("[SOEKKI]       Progress:", string.format("%.1f%%", progress))
            print("[SOEKKI]       PlayersRepairingCount:", count)
            print("[SOEKKI]       repairboost:", boost)
            print("[SOEKKI]       В activeBoosts:", activeBoosts[gen] ~= nil)
        end
    end
    
    print("[SOEKKI] ========================================")
end

-- ============================================
--   ЗАПУСК ВСЕХ СИСТЕМ
-- ============================================
-- Запускаем мониторинг
task.spawn(monitorGenerators)

-- Подключаем RepairEvent
task.spawn(setupRepairEvent)

-- Перехват оригинального обработчика
task.spawn(hookOriginalHandler)

-- Дебаг команды в консоли
-- Можно вызвать через _G.debugGenerators()
_G.debugGenerators = debugGeneratorState

-- Выводим справку
print("[SOEKKI] ========================================")
print("[SOEKKI] СИСТЕМА ЗАГРУЖЕНА!")
print("[SOEKKI] ========================================")
print("[SOEKKI] Для отладки используйте:")
print("[SOEKKI]   _G.debugGenerators() - показать состояние всех генераторов")
print("[SOEKKI] ========================================")

-- ============================================
--   GUI ДЛЯ ESP
-- ============================================
local function SetupGui()
    if PlayerGui:FindFirstChild("ChasedInds") then 
        PlayerGui:FindFirstChild("ChasedInds"):Destroy() 
    end
    IndicatorGui = Instance.new("ScreenGui")
    IndicatorGui.Name = "ChasedInds"
    IndicatorGui.IgnoreGuiInset = true
    IndicatorGui.DisplayOrder = 999
    IndicatorGui.Parent = PlayerGui
end

-- ============================================
--   ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================
local function GetGameValue(obj, name)
    if not obj then return nil end
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    
    local child = obj:FindFirstChild(name)
    if child then
        local success, val = pcall(function() return child.Value end)
        if success then return val end
    end
    return nil
end

-- ============================================
--   ФУНКЦИЯ ПОДСВЕТКИ
-- ============================================
local function ApplyHighlight(object, color)
    if not object then return end
    local h = object:FindFirstChild("H") or Instance.new("Highlight")
    h.Name = "H"
    h.Adornee = object
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.8
    h.OutlineTransparency = 0.3
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = object
end

local function RemoveHighlight(object)
    if not object then return end
    local h = object:FindFirstChild("H")
    if h then h:Destroy() end
end

local function CreateBillboardTag(text, color, size, textSize)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BitchHook"
    billboard.AlwaysOnTop = true
    billboard.Size = size or UDim2.new(0, 120, 0, 30)
    
    local label = Instance.new("TextLabel")
    label.Name = "BitchHook"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize or 10
    label.TextWrapped = true
    label.RichText = true 
    label.Parent = billboard
    
    return billboard
end

-- ============================================
--   ОБНОВЛЕНИЕ ИГРОКОВ (СОКРАЩЕНО)
-- ============================================
local function updatePlayerNametag(player)
    if not IndicatorGui or not IndicatorGui.Parent then return end
    if not ESPConfig.ShowPlayers then
        local toRemove = {}
        for _, child in ipairs(IndicatorGui:GetChildren()) do
            if child.Name == player.Name or child.Name == player.Name .. "_Chased" or child.Name == player.Name .. "_Killer" then
                table.insert(toRemove, child)
            end
        end
        for _, child in ipairs(toRemove) do child:Destroy() end
        if player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local billboard = rootPart:FindFirstChild("BitchHook")
                if billboard then billboard:Destroy() end
                local maskBillboard = rootPart:FindFirstChild("MaskHook")
                if maskBillboard then maskBillboard:Destroy() end
                local h = player.Character:FindFirstChild("H")
                if h then h:Destroy() end
            end
        end
        return 
    end
    if not player.Character then return end
    
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not rootPart then return end
    
    local teamName = (player.Team and player.Team.Name:lower()) or ""
    local selectedKillerAttr = GetGameValue(player, "SelectedKiller")
    local rawMask = GetGameValue(player, "Mask") or GetGameValue(player.Character, "Mask")
    local isKnocked = GetGameValue(player.Character, "Knocked")
    local isHooked = GetGameValue(player.Character, "IsHooked")
    
    local isKiller = teamName:find("killer") ~= nil
    local color = isKiller and Config.Players.Killer.Color or Config.Players.Survivor.Color
    
    if isHooked then 
        color = Color3.fromRGB(255, 182, 193) 
    elseif humanoid and humanoid.Health < humanoid.MaxHealth then
        color = isKnocked and Color3.fromRGB(200, 100, 0) or Color3.fromRGB(200, 200, 0)
    end
    
    local distance = 0
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        distance = math.floor((rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
    end
    
    local baseName = (isKiller and selectedKillerAttr and tostring(selectedKillerAttr) ~= "") and tostring(selectedKillerAttr) or player.Name
    local billboard = rootPart:FindFirstChild("BitchHook")
    local nameText = baseName .. "\n[" .. distance .. " studs]"
    if not billboard then
        billboard = CreateBillboardTag(nameText, color)
        billboard.Adornee = rootPart
        billboard.Parent = rootPart
    else
        local lbl = billboard:FindFirstChild("BitchHook") or billboard:FindFirstChildOfClass("TextLabel")
        if lbl then
            lbl.Text = nameText
            lbl.TextColor3 = color
        end
    end
    ApplyHighlight(player.Character, color)
end

-- ============================================
--   ГЕНЕРАТОРЫ
-- ============================================
local function updateGeneratorProgress(generator)
    if not ESPConfig.ShowGenerators then
        local billboard = generator:FindFirstChild("GenBitchHook")
        if billboard then billboard:Destroy() end
        RemoveHighlight(generator)
        return true
    end
    
    if not generator or not generator.Parent then return true end
    local percent = GetGameValue(generator, "RepairProgress") or GetGameValue(generator, "Progress") or 0
    
    local billboard = generator:FindFirstChild("GenBitchHook")
    if percent >= 100 then
        if billboard then billboard:Destroy() end
        RemoveHighlight(generator)
        return true
    end
    
    local cp = math.clamp(percent, 0, 100)
    local finalColor = cp < 50 and Config.Objects.Generator.Color:Lerp(Color3.fromRGB(180, 180, 0), cp / 50) or Color3.fromRGB(180, 180, 0):Lerp(Color3.fromRGB(0, 150, 0), (cp - 50) / 50)
    
    local percentStr = string.format("[%.2f%%]", percent)
    if not billboard then
        billboard = CreateBillboardTag(percentStr, finalColor)
        billboard.Name, billboard.StudsOffset = "GenBitchHook", Vector3.new(0, 2, 0)
        billboard.Adornee = generator:FindFirstChild("defaultMaterial", true) or generator
        billboard.Parent = generator
    else
        local lbl = billboard:FindFirstChild("BitchHook") or billboard:FindFirstChildOfClass("TextLabel")
        if lbl then
            lbl.Text = percentStr
            lbl.TextColor3 = finalColor
        end
    end
    ApplyHighlight(generator, Config.Objects.Generator.Color)
    return false
end

-- ============================================
--   ОБНОВЛЕНИЕ ESP
-- ============================================
local function RefreshESP()
    ActiveGenerators = {}
    
    local Map = workspace:FindFirstChild("Map")
    if not Map then return end
    
    for _, obj in ipairs(Map:GetDescendants()) do
        if obj.Name == "Generator" then
            if ESPConfig.ShowGenerators then
                ApplyHighlight(obj, Config.Objects.Generator.Color)
                table.insert(ActiveGenerators, obj)
            else
                RemoveHighlight(obj)
            end
        elseif obj.Name == "Hook" then
            if ESPConfig.ShowHooks then
                local m = obj:FindFirstChild("Model")
                if m then
                    for _, p in ipairs(m:GetDescendants()) do
                        if p:IsA("MeshPart") then
                            ApplyHighlight(p, Config.Objects.Hook.Color)
                        end
                    end
                end
            else
                local m = obj:FindFirstChild("Model")
                if m then
                    for _, p in ipairs(m:GetDescendants()) do
                        if p:IsA("MeshPart") then
                            RemoveHighlight(p)
                        end
                    end
                end
            end
        elseif (obj.Name == "Palletwrong" or obj.Name == "Pallet") then
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
        end
    end
end

-- ============================================
--   ЭКСПОРТ
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
    if not enabled then
        for generator, _ in pairs(activeBoosts) do
            pcall(function()
                generator:SetAttribute("repairboost", nil)
                generator:SetAttribute("BoostMultiplier", nil)
                generator:SetAttribute("RepairBoost", nil)
                generator:SetAttribute("GeneratorBoost", nil)
            end)
        end
        table.clear(activeBoosts)
    end
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
--   ЗАПУСК
-- ============================================
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
    
    if now - LastFullESPRefresh > 5 then
        LastFullESPRefresh = now
        RefreshESP()
    end
    
    for _, p in ipairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer then 
            updatePlayerNametag(p) 
        end 
    end
    
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
    if not IndicatorGui then return end
    local l = {p.Name .. "_Chased", p.Name .. "_Killer", p.Name}
    for _, n in ipairs(l) do
        local obj = IndicatorGui:FindFirstChild(n)
        if obj then obj:Destroy() end
    end
end)

SetupGui()
RefreshESP()

-- Регистрируем
_G.ESPModule = module
_G.ToggleESP = module.ToggleESP
_G.GetESPState = module.GetESPState
_G.SetGeneratorBoostEnabled = module.SetGeneratorBoostEnabled
_G.GetGeneratorBoostEnabled = module.GetGeneratorBoostEnabled
_G.SetGeneratorBoostPercent = module.SetGeneratorBoostPercent
_G.GetGeneratorBoostPercent = module.GetGeneratorBoostPercent
_G.debugGenerators = debugGeneratorState

print("[SOEKKI] ========================================")
print("[SOEKKI] ✅ main_functions.lua ЗАГРУЖЕНА!")
print("[SOEKKI] ========================================")
print("[SOEKKI] ДЛЯ ОТЛАДКИ:")
print("[SOEKKI]   _G.debugGenerators() - показать состояние генераторов")
print("[SOEKKI] ========================================")

return module