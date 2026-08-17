-- main_functions.lua - С МАКСИМАЛЬНЫМ ЛОГИРОВАНИЕМ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("[SOEKKI] ========================================")
print("[SOEKKI] ЗАГРУЗКА main_functions.lua")
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
print("[SOEKKI] ESP настройки загружены")

-- ============================================
--   НАСТРОЙКИ БАФФА ГЕНЕРАТОРОВ
-- ============================================
local GeneratorBoostConfig = {
    Enabled = false,
    BoostPercent = 50,
}
print("[SOEKKI] Настройки баффа: Enabled=false, Boost=50%")

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
--   СИСТЕМА БАФФА ГЕНЕРАТОРОВ
-- ============================================
local activeGeneratorBoosts = {}

print("[SOEKKI] Инициализация системы баффа...")

-- Функция для применения баффа
local function applyGeneratorBoost(generator)
    print("[SOEKKI] [applyGeneratorBoost] ВЫЗВАНА для:", generator and generator.Name or "nil")
    
    if not generator then
        print("[SOEKKI] [applyGeneratorBoost] ❌ ОШИБКА: generator = nil")
        return
    end
    
    if not GeneratorBoostConfig.Enabled then
        print("[SOEKKI] [applyGeneratorBoost] ⚠️ БАФФ ВЫКЛЮЧЕН, пропускаем")
        return
    end
    
    local boostPercent = GeneratorBoostConfig.BoostPercent / 100
    local boostMultiplier = 1 + boostPercent
    
    print("[SOEKKI] [applyGeneratorBoost] Процент баффа:", GeneratorBoostConfig.BoostPercent .. "%")
    print("[SOEKKI] [applyGeneratorBoost] Множитель:", string.format("%.2f", boostMultiplier))
    
    if activeGeneratorBoosts[generator] then
        if math.abs(activeGeneratorBoosts[generator] - boostMultiplier) < 0.01 then
            print("[SOEKKI] [applyGeneratorBoost] Бафф уже применен с таким же значением")
            return
        end
        print("[SOEKKI] [applyGeneratorBoost] Обновляем существующий бафф")
    end
    
    activeGeneratorBoosts[generator] = boostMultiplier
    print("[SOEKKI] [applyGeneratorBoost] Добавлен в activeGeneratorBoosts")
    
    -- Устанавливаем атрибуты
    print("[SOEKKI] [applyGeneratorBoost] Устанавливаем атрибуты...")
    
    local success, err = pcall(function()
        generator:SetAttribute("repairboost", boostMultiplier)
        print("[SOEKKI] [applyGeneratorBoost] ✅ repairboost =", boostMultiplier)
        generator:SetAttribute("BoostMultiplier", boostMultiplier)
        print("[SOEKKI] [applyGeneratorBoost] ✅ BoostMultiplier =", boostMultiplier)
        generator:SetAttribute("GeneratorBoost", boostMultiplier)
        print("[SOEKKI] [applyGeneratorBoost] ✅ GeneratorBoost =", boostMultiplier)
    end)
    
    if not success then
        print("[SOEKKI] [applyGeneratorBoost] ❌ Ошибка установки атрибутов:", err)
    end
    
    -- На все части
    local partsCount = 0
    for _, part in ipairs(generator:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part:SetAttribute("repairboost", boostMultiplier)
                partsCount = partsCount + 1
            end)
        end
    end
    print("[SOEKKI] [applyGeneratorBoost] Установлено на", partsCount, "частей")
    
    -- Ищем RepairPoint
    local repairPoint = generator:FindFirstChild("RepairPoint")
    if repairPoint then
        pcall(function()
            repairPoint:SetAttribute("repairboost", boostMultiplier)
            print("[SOEKKI] [applyGeneratorBoost] ✅ RepairPoint обновлен")
        end)
    else
        print("[SOEKKI] [applyGeneratorBoost] RepairPoint не найден")
    end
    
    print("[SOEKKI] ✅✅✅ БАФФ ПРИМЕНЕН к:", generator.Name, "x" .. string.format("%.2f", boostMultiplier))
    print("[SOEKKI] ========================================")
end

-- Функция для снятия баффа
local function removeGeneratorBoost(generator)
    print("[SOEKKI] [removeGeneratorBoost] ВЫЗВАНА для:", generator and generator.Name or "nil")
    
    if not generator then
        print("[SOEKKI] [removeGeneratorBoost] ❌ ОШИБКА: generator = nil")
        return
    end
    
    if not activeGeneratorBoosts[generator] then
        print("[SOEKKI] [removeGeneratorBoost] ⚠️ Бафф не найден в activeGeneratorBoosts")
        return
    end
    
    activeGeneratorBoosts[generator] = nil
    print("[SOEKKI] [removeGeneratorBoost] Удален из activeGeneratorBoosts")
    
    print("[SOEKKI] [removeGeneratorBoost] Снимаем атрибуты...")
    
    pcall(function()
        generator:SetAttribute("repairboost", nil)
        generator:SetAttribute("BoostMultiplier", nil)
        generator:SetAttribute("GeneratorBoost", nil)
        print("[SOEKKI] [removeGeneratorBoost] ✅ Атрибуты сняты с генератора")
    end)
    
    for _, part in ipairs(generator:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part:SetAttribute("repairboost", nil)
            end)
        end
    end
    
    local repairPoint = generator:FindFirstChild("RepairPoint")
    if repairPoint then
        pcall(function()
            repairPoint:SetAttribute("repairboost", nil)
            print("[SOEKKI] [removeGeneratorBoost] ✅ RepairPoint очищен")
        end)
    end
    
    print("[SOEKKI] ❌❌❌ БАФФ СНЯТ с:", generator.Name)
    print("[SOEKKI] ========================================")
end

-- ============================================
--   ОСНОВНАЯ ФУНКЦИЯ - КАК В PERFECTIONIST
-- ============================================
local function onRepairAnim(p1, p2, p3, p4, p5, p6)
    print("[SOEKKI] [onRepairAnim] ========================================")
    print("[SOEKKI] [onRepairAnim] ВЫЗВАНА!")
    print("[SOEKKI] [onRepairAnim] Аргументы:")
    print("[SOEKKI]   p1 =", p1, "тип:", type(p1))
    print("[SOEKKI]   p2 =", p2, "тип:", type(p2))
    print("[SOEKKI]   p3 =", p3, "тип:", type(p3))
    print("[SOEKKI]   p4 =", p4, "тип:", type(p4))
    print("[SOEKKI]   p5 =", p5, "тип:", type(p5))
    print("[SOEKKI]   p6 =", p6, "тип:", type(p6))
    
    if p2 == true then
        print("[SOEKKI] [onRepairAnim] 🔧 НАЧАЛО РЕМОНТА (p2 = true)")
    elseif p2 == false then
        print("[SOEKKI] [onRepairAnim] 🛑 КОНЕЦ РЕМОНТА (p2 = false)")
    else
        print("[SOEKKI] [onRepairAnim] ⚠️ НЕИЗВЕСТНОЕ ЗНАЧЕНИЕ p2 =", p2)
    end
    
    if p2 == true then
        -- Начало ремонта
        if not (p3 and p3.Parent) then
            print("[SOEKKI] [onRepairAnim] ❌ ОШИБКА: p3 или p3.Parent = nil")
            print("[SOEKKI] [onRepairAnim] p3 =", p3)
            return
        end
        
        local generator = p3.Parent
        print("[SOEKKI] [onRepairAnim] Генератор из p3.Parent:", generator and generator.Name or "nil")
        
        -- Проверяем теги
        local hasTag = CollectionService:HasTag(generator, "Generator")
        print("[SOEKKI] [onRepairAnim] CollectionService:HasTag(generator, 'Generator') =", hasTag)
        
        -- Проверяем имя
        print("[SOEKKI] [onRepairAnim] generator.Name =", generator and generator.Name or "nil")
        
        if CollectionService:HasTag(generator, "Generator") then
            print("[SOEKKI] [onRepairAnim] ✅ Это генератор!")
            
            if GeneratorBoostConfig.Enabled then
                print("[SOEKKI] [onRepairAnim] ✅ Бафф включен, применяем...")
                applyGeneratorBoost(generator)
            else
                print("[SOEKKI] [onRepairAnim] ⚠️ Бафф выключен, пропускаем")
                print("[SOEKKI] [onRepairAnim] Включите бафф в меню (Modification -> Enable Generator Boost)")
            end
        else
            print("[SOEKKI] [onRepairAnim] ⚠️ Это НЕ генератор (нет тега Generator)")
        end
    else
        -- Конец ремонта
        if p3 and p3.Parent then
            local generator = p3.Parent
            print("[SOEKKI] [onRepairAnim] Генератор из p3.Parent:", generator and generator.Name or "nil")
            
            if CollectionService:HasTag(generator, "Generator") then
                print("[SOEKKI] [onRepairAnim] ✅ Это генератор, снимаем бафф")
                removeGeneratorBoost(generator)
            else
                print("[SOEKKI] [onRepairAnim] ⚠️ Это НЕ генератор (нет тега Generator)")
            end
        else
            print("[SOEKKI] [onRepairAnim] ⚠️ p3 или p3.Parent = nil, не можем определить генератор")
        end
    end
    
    print("[SOEKKI] [onRepairAnim] ========================================")
end

-- ============================================
--   ПОДКЛЮЧЕНИЕ РЕМОУТОВ
-- ============================================
local function setupRemoteListeners()
    print("[SOEKKI] [setupRemoteListeners] ========================================")
    print("[SOEKKI] [setupRemoteListeners] Поиск ремоутов...")
    
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not Remotes then 
        print("[SOEKKI] [setupRemoteListeners] ❌ Remotes не найдены!")
        return 
    end
    print("[SOEKKI] [setupRemoteListeners] ✅ Remotes найден")
    
    local Generator = Remotes:FindFirstChild("Generator")
    if not Generator then 
        print("[SOEKKI] [setupRemoteListeners] ❌ Generator ремоуты не найдены!")
        return 
    end
    print("[SOEKKI] [setupRemoteListeners] ✅ Generator найден")
    
    -- Список всех ремоутов в Generator
    print("[SOEKKI] [setupRemoteListeners] Содержимое Generator:")
    for _, child in ipairs(Generator:GetChildren()) do
        print("[SOEKKI]   -", child.Name, "(" .. child.ClassName .. ")")
    end
    
    local RepairAnim = Generator:FindFirstChild("RepairAnim")
    if RepairAnim then
        print("[SOEKKI] [setupRemoteListeners] ✅ RepairAnim найден, подключаем...")
        RepairAnim.OnClientEvent:Connect(onRepairAnim)
        print("[SOEKKI] [setupRemoteListeners] ✅ RepairAnim подключен!")
    else
        print("[SOEKKI] [setupRemoteListeners] ❌ RepairAnim не найден!")
    end
    
    -- Также пробуем RepairEvent
    local RepairEvent = Generator:FindFirstChild("RepairEvent")
    if RepairEvent then
        print("[SOEKKI] [setupRemoteListeners] ✅ RepairEvent найден, подключаем...")
        RepairEvent.OnClientEvent:Connect(function(repairPoint, isRepairing)
            print("[SOEKKI] [RepairEvent] ========================================")
            print("[SOEKKI] [RepairEvent] ВЫЗВАН!")
            print("[SOEKKI] [RepairEvent] repairPoint =", repairPoint)
            print("[SOEKKI] [RepairEvent] isRepairing =", isRepairing)
            
            if repairPoint and repairPoint.Parent then
                local generator = repairPoint.Parent
                print("[SOEKKI] [RepairEvent] generator =", generator and generator.Name or "nil")
                
                if CollectionService:HasTag(generator, "Generator") then
                    if isRepairing and GeneratorBoostConfig.Enabled then
                        applyGeneratorBoost(generator)
                    elseif not isRepairing then
                        removeGeneratorBoost(generator)
                    end
                end
            else
                print("[SOEKKI] [RepairEvent] ⚠️ repairPoint или repairPoint.Parent = nil")
            end
            print("[SOEKKI] [RepairEvent] ========================================")
        end)
        print("[SOEKKI] [setupRemoteListeners] ✅ RepairEvent подключен!")
    else
        print("[SOEKKI] [setupRemoteListeners] ⚠️ RepairEvent не найден")
    end
    
    print("[SOEKKI] [setupRemoteListeners] ========================================")
end

-- Запускаем
task.spawn(setupRemoteListeners)

-- ============================================
--   МОНИТОРИНГ ГЕНЕРАТОРОВ (ДЛЯ ОТЛАДКИ)
-- ============================================
task.spawn(function()
    print("[SOEKKI] [Monitor] Запуск мониторинга генераторов...")
    local checkCount = 0
    
    while true do
        checkCount = checkCount + 1
        
        -- Каждые 10 проверок выводим статус
        if checkCount % 10 == 0 then
            local gens = CollectionService:GetTagged("Generator")
            print("[SOEKKI] [Monitor] Статус: найдено генераторов =", #gens)
            print("[SOEKKI] [Monitor] Активных баффов =", table.getn(activeGeneratorBoosts))
            
            for gen, boost in pairs(activeGeneratorBoosts) do
                if gen and gen.Parent then
                    local progress = pcall(function() return gen:GetAttribute("RepairProgress") or 0 end)
                    if type(progress) == "number" then
                        print("[SOEKKI] [Monitor]   -", gen.Name, "бафф x" .. string.format("%.2f", boost), "прогресс:", string.format("%.1f%%", progress))
                    end
                end
            end
        end
        
        task.wait(5)
    end
end)

-- ============================================
--   GUI ДЛЯ ESP
-- ============================================
local function SetupGui()
    print("[SOEKKI] [SetupGui] Создание GUI...")
    if PlayerGui:FindFirstChild("ChasedInds") then 
        PlayerGui:FindFirstChild("ChasedInds"):Destroy() 
        print("[SOEKKI] [SetupGui] Старый GUI удален")
    end
    IndicatorGui = Instance.new("ScreenGui")
    IndicatorGui.Name = "ChasedInds"
    IndicatorGui.IgnoreGuiInset = true
    IndicatorGui.DisplayOrder = 999
    IndicatorGui.Parent = PlayerGui
    print("[SOEKKI] [SetupGui] ✅ GUI создан")
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
--   ОБНОВЛЕНИЕ ИГРОКОВ
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
        for _, child in ipairs(toRemove) do
            child:Destroy()
        end
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
    
    if not player.Character then
        local m = IndicatorGui:FindFirstChild(player.Name) if m then m:Destroy() end
        local c = IndicatorGui:FindFirstChild(player.Name .. "_Chased") if c then c:Destroy() end
        local k = IndicatorGui:FindFirstChild(player.Name .. "_Killer") if k then k:Destroy() end
        return 
    end
    
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not rootPart then return end
    
    local teamName = (player.Team and player.Team.Name:lower()) or ""
    local selectedKillerAttr = GetGameValue(player, "SelectedKiller")
    local rawMask = GetGameValue(player, "Mask") or GetGameValue(player.Character, "Mask")
    local isKnocked = GetGameValue(player.Character, "Knocked")
    local isHooked = GetGameValue(player.Character, "IsHooked")
    local isChased = GetGameValue(player.Character, "IsChased")
    
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

    local hasMask = false
    if isKiller and string.match(tostring(selectedKillerAttr):lower(), "masked") and rawMask then
        local searchMask = tostring(rawMask):lower()
        for key, name in pairs(MaskNames) do
            if key:lower() == searchMask then
                hasMask = true
                local maskBillboard = rootPart:FindFirstChild("MaskHook")
                if not maskBillboard then
                    maskBillboard = CreateBillboardTag(name, MaskColors[key] or Color3.new(1,1,1), UDim2.new(0, 100, 0, 20), 12)
                    maskBillboard.Name = "MaskHook"
                    maskBillboard.StudsOffset = Vector3.new(0, 3, 0)
                    maskBillboard.Adornee = rootPart
                    maskBillboard.Parent = rootPart
                else
                    local lbl = maskBillboard:FindFirstChild("BitchHook") or maskBillboard:FindFirstChildOfClass("TextLabel")
                    if lbl then
                        lbl.Text = name
                        lbl.TextColor3 = MaskColors[key] or Color3.new(1,1,1)
                    end
                end
                break
            end
        end
    end
    if not hasMask then
        local maskBillboard = rootPart:FindFirstChild("MaskHook")
        if maskBillboard then maskBillboard:Destroy() end
    end

    local chasedLabel2D = IndicatorGui:FindFirstChild(player.Name .. "_Chased")
    if isChased then
        local ct3 = billboard:FindFirstChild("ChasedLabel")
        if not ct3 then
            ct3 = Instance.new("TextLabel", billboard)
            ct3.Name = "ChasedLabel"
            ct3.Size, ct3.Position, ct3.BackgroundTransparency = UDim2.new(1,0,1,0), UDim2.new(0,0,-1.2,0), 1
            ct3.Font, ct3.TextSize = Enum.Font.GothamBold, 24
        end
        ct3.Text, ct3.TextColor3, ct3.TextStrokeTransparency = "!!", color, 0
        
        if not chasedLabel2D then
            chasedLabel2D = Instance.new("TextLabel", IndicatorGui)
            chasedLabel2D.Name, chasedLabel2D.BackgroundTransparency = player.Name .. "_Chased", 1
            chasedLabel2D.Font, chasedLabel2D.TextSize, chasedLabel2D.TextStrokeTransparency = Enum.Font.GothamBold, 24, 0
            chasedLabel2D.AnchorPoint = Vector2.new(0.5, 0.5)
        end
        chasedLabel2D.Text, chasedLabel2D.TextColor3 = "!!", color
        
        local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(rootPart.Position)
        if onScreen then
            chasedLabel2D.Visible = false 
        else
            chasedLabel2D.Visible = true
            local viewportCenter = workspace.CurrentCamera.ViewportSize / 2
            local direction = Vector2.new(screenPos.X, screenPos.Y) - viewportCenter
            if screenPos.Z < 0 then direction = -direction end
            local maxScale = math.max(math.abs(direction.X) / (viewportCenter.X - 30), math.abs(direction.Y) / (viewportCenter.Y - 30))
            chasedLabel2D.Position = UDim2.new(0, viewportCenter.X + direction.X / (maxScale == 0 and 1 or maxScale), 0, viewportCenter.Y + direction.Y / (maxScale == 0 and 1 or maxScale))
        end
    else
        if chasedLabel2D then chasedLabel2D:Destroy() end
        local ct3 = billboard:FindFirstChild("ChasedLabel")
        if ct3 then ct3:Destroy() end
    end

    local killerLabel2D = IndicatorGui:FindFirstChild(player.Name .. "_Killer")
    if isKiller then
        if not killerLabel2D then
            killerLabel2D = Instance.new("TextLabel", IndicatorGui)
            killerLabel2D.Name, killerLabel2D.BackgroundTransparency = player.Name .. "_Killer", 1
            killerLabel2D.Font, killerLabel2D.TextSize, killerLabel2D.TextStrokeTransparency = Enum.Font.GothamBold, 10, 0
            killerLabel2D.Size, killerLabel2D.RichText, killerLabel2D.AnchorPoint = UDim2.new(0, 120, 0, 30), true, Vector2.new(0.5, 0.5)
        end
        killerLabel2D.Text, killerLabel2D.TextColor3 = baseName .. "\n[" .. distance .. " studs]", color
        
        local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(rootPart.Position)
        if not onScreen then
            killerLabel2D.Visible = true
            local viewportCenter = workspace.CurrentCamera.ViewportSize / 2
            local direction = Vector2.new(screenPos.X, screenPos.Y) - viewportCenter
            if screenPos.Z < 0 then direction = -direction end
            local maxScale = math.max(math.abs(direction.X) / (viewportCenter.X - 30), math.abs(direction.Y) / (viewportCenter.Y - 30))
            killerLabel2D.Position = UDim2.new(0, viewportCenter.X + direction.X / (maxScale == 0 and 1 or maxScale), 0, viewportCenter.Y + direction.Y / (maxScale == 0 and 1 or maxScale))
        else
            killerLabel2D.Visible = false
        end
    elseif killerLabel2D then killerLabel2D:Destroy() end
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
--   NEXT KILLER DISPLAY
-- ============================================
local function updateNextKillerDisplay()
    if not IndicatorGui or not IndicatorGui.Parent then return end
    local label = IndicatorGui:FindFirstChild("NextKillerDisplay")
    local teamName = (LocalPlayer.Team and LocalPlayer.Team.Name:lower()) or ""
    if teamName:find("spectator") or teamName:find("lobby") then
        if not label then
            label = Instance.new("TextLabel", IndicatorGui)
            label.Name, label.Size, label.Position = "NextKillerDisplay", UDim2.new(0, 220, 0, 30), UDim2.new(0.5, 0, 0, 45)
            label.AnchorPoint, label.BackgroundTransparency, label.BackgroundColor3 = Vector2.new(0.5, 0), 0.5, Color3.new(0, 0, 0)
            label.TextColor3, label.Font, label.TextSize, label.RichText = Color3.new(1, 1, 1), Enum.Font.GothamBold, 14, true
            label.Text = "Next Killer: Calculating..."
        end
        local players = Players:GetPlayers()
        
        table.sort(players, function(a, b)
            local aA = GetGameValue(a, "AllowKiller") or false
            local bA = GetGameValue(b, "AllowKiller") or false
            if aA ~= bA then
                return aA == true
            end
            return (GetGameValue(a, "KillerChance") or 0) > (GetGameValue(b, "KillerChance") or 0)
        end)
        
        local nk = players[1]
        if nk then
            label.Text = "Next Killer: <font color=\"rgb(255,0,0)\">" .. (nk == LocalPlayer and "YOU" or tostring(GetGameValue(nk, "SelectedKiller") or nk.Name)) .. "</font>"
        end
    elseif label then label:Destroy() end
end

-- ============================================
--   ОБНОВЛЕНИЕ ESP
-- ============================================
local function RefreshESP()
    ActiveGenerators = {}
    
    if ESPConfig.ShowWindows then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "Window" then
                ApplyHighlight(obj, Config.Objects.Window.Color)
            end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "Window" then
                RemoveHighlight(obj)
            end
        end
    end
    
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
--   ЭКСПОРТ ФУНКЦИЙ
-- ============================================
local module = {}

function module.ToggleESP(option)
    print("[SOEKKI] [ToggleESP] Переключение:", option)
    ESPConfig[option] = not ESPConfig[option]
    RefreshESP()
    print("[SOEKKI] [ToggleESP] Новое состояние:", ESPConfig[option])
    return ESPConfig[option]
end

function module.GetESPState(option)
    return ESPConfig[option]
end

function module.SetESPState(option, state)
    print("[SOEKKI] [SetESPState] Установка:", option, "=", state)
    ESPConfig[option] = state
    RefreshESP()
    return ESPConfig[option]
end

function module.SetGeneratorBoostEnabled(enabled)
    print("[SOEKKI] [SetGeneratorBoostEnabled] ========================================")
    print("[SOEKKI] [SetGeneratorBoostEnabled] ВЫЗВАНА! enabled =", enabled)
    
    GeneratorBoostConfig.Enabled = enabled
    print("[SOEKKI] [SetGeneratorBoostEnabled] Новое состояние:", GeneratorBoostConfig.Enabled)
    
    if not enabled then
        local count = 0
        for generator, _ in pairs(activeGeneratorBoosts) do
            removeGeneratorBoost(generator)
            count = count + 1
        end
        table.clear(activeGeneratorBoosts)
        print("[SOEKKI] [SetGeneratorBoostEnabled] Снято баффов:", count)
    else
        print("[SOEKKI] [SetGeneratorBoostEnabled] Бафф включен. Процент:", GeneratorBoostConfig.BoostPercent .. "%")
    end
    
    print("[SOEKKI] [SetGeneratorBoostEnabled] ========================================")
end

function module.GetGeneratorBoostEnabled()
    return GeneratorBoostConfig.Enabled
end

function module.SetGeneratorBoostPercent(percent)
    print("[SOEKKI] [SetGeneratorBoostPercent] ========================================")
    print("[SOEKKI] [SetGeneratorBoostPercent] ВЫЗВАНА! percent =", percent)
    
    local newPercent = math.clamp(percent, 0, 100)
    GeneratorBoostConfig.BoostPercent = newPercent
    print("[SOEKKI] [SetGeneratorBoostPercent] Новое значение:", GeneratorBoostConfig.BoostPercent .. "%")
    print("[SOEKKI] [SetGeneratorBoostPercent] Множитель:", string.format("%.2f", 1 + newPercent / 100))
    
    -- Обновляем активные баффы с новым значением
    if GeneratorBoostConfig.Enabled then
        print("[SOEKKI] [SetGeneratorBoostPercent] Обновляем активные баффы...")
        local count = 0
        for generator, _ in pairs(activeGeneratorBoosts) do
            applyGeneratorBoost(generator)
            count = count + 1
        end
        print("[SOEKKI] [SetGeneratorBoostPercent] Обновлено баффов:", count)
    end
    
    print("[SOEKKI] [SetGeneratorBoostPercent] ========================================")
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
        print("[SOEKKI] Обнаружена карта (Map), обновляем ESP...")
        task.wait(1)
        RefreshESP()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    print("[SOEKKI] Персонаж создан, пересоздаем GUI...")
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
    updateNextKillerDisplay()
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local killerNearby = false
    
    for _, p in ipairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer then 
            updatePlayerNametag(p) 
            local pTeam = p.Team and p.Team.Name:lower() or ""
            if pTeam:find("killer") and myRoot and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude < 99 then
                    killerNearby = true
                end
            end
        end 
    end
    
    if myRoot and ESPConfig.ShowKillerWarning then
        local warn = myRoot:FindFirstChild("KillerWarn")
        if killerNearby then
            if not warn then
                warn = CreateBillboardTag("!", Color3.fromRGB(255, 0, 0), UDim2.new(0, 50, 0, 50), 40)
                warn.Name, warn.StudsOffset, warn.Adornee, warn.Parent = "KillerWarn", Vector3.new(0, 4, 0), myRoot, myRoot
            end
        elseif warn then
            warn:Destroy()
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

-- Регистрируем в глобальном пространстве
_G.ESPModule = module
_G.ToggleESP = module.ToggleESP
_G.GetESPState = module.GetESPState
_G.SetGeneratorBoostEnabled = module.SetGeneratorBoostEnabled
_G.GetGeneratorBoostEnabled = module.GetGeneratorBoostEnabled
_G.SetGeneratorBoostPercent = module.SetGeneratorBoostPercent
_G.GetGeneratorBoostPercent = module.GetGeneratorBoostPercent

print("[SOEKKI] ========================================")
print("[SOEKKI] ✅ main_functions.lua ЗАГРУЖЕНА!")
print("[SOEKKI] ✅ ESP система готова")
print("[SOEKKI] ✅ Система баффа готова")
print("[SOEKKI] ========================================")
print("[SOEKKI] ИНСТРУКЦИЯ ПО ТЕСТИРОВАНИЮ:")
print("[SOEKKI] 1. Откройте консоль (F9)")
print("[SOEKKI] 2. Включите бафф в меню (Modification -> Enable Generator Boost)")
print("[SOEKKI] 3. Начните чинить генератор")
print("[SOEKKI] 4. Смотрите логи в консоли")
print("[SOEKKI] ========================================")

return module