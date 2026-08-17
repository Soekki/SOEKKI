-- main_functions.lua - ВЕРСИЯ С ОТПРАВКОЙ НА СЕРВЕР (как в perfectionist)
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
--   СИСТЕМА БАФФА ГЕНЕРАТОРОВ (КАК В PERFECTIONIST)
-- ============================================
local activeGeneratorBoosts = {}
local currentGenerator = nil  -- Текущий генератор, который мы чиним
local boostType = nil  -- "fast" или "slow"

-- Получаем ремоуты как в perfectionist.txt
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local Generator = Remotes and Remotes:FindFirstChild("Generator")
local RepairAnim = Generator and Generator:FindFirstChild("RepairAnim")
local perfectionistplanning = Remotes and Remotes:FindFirstChild("Perks") and Remotes.Perks:FindFirstChild("perfectionistplanning")

print("[SOEKKI] RepairAnim найден:", RepairAnim ~= nil)
print("[SOEKKI] perfectionistplanning найден:", perfectionistplanning ~= nil)

-- Функция для определения типа баффа (fast/slow) по проценту
local function getBoostType()
    if GeneratorBoostConfig.BoostPercent >= 75 then
        return "fast"
    elseif GeneratorBoostConfig.BoostPercent >= 25 then
        return "medium"
    else
        return "slow"
    end
end

-- Функция для применения баффа (отправка на сервер)
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
    
    local boostType = getBoostType()
    print("[SOEKKI] [applyGeneratorBoost] Тип баффа:", boostType)
    print("[SOEKKI] [applyGeneratorBoost] Процент:", GeneratorBoostConfig.BoostPercent .. "%")
    
    -- Сохраняем текущий генератор
    currentGenerator = generator
    
    -- ОТПРАВЛЯЕМ НА СЕРВЕР как в perfectionist.txt
    if perfectionistplanning then
        print("[SOEKKI] [applyGeneratorBoost] Отправляем на сервер: applyBoost", boostType)
        perfectionistplanning:FireServer("applyBoost", boostType)
        print("[SOEKKI] ✅✅✅ БАФФ ОТПРАВЛЕН НА СЕРВЕР! Тип:", boostType)
    else
        print("[SOEKKI] [applyGeneratorBoost] ❌ perfectionistplanning не найден!")
        print("[SOEKKI] [applyGeneratorBoost] Пытаемся найти альтернативный ремоут...")
        
        -- Ищем альтернативные ремоуты
        local Perks = Remotes and Remotes:FindFirstChild("Perks")
        if Perks then
            for _, child in ipairs(Perks:GetChildren()) do
                print("[SOEKKI]   Найден ремоут:", child.Name)
                if child.Name:lower():find("boost") or child.Name:lower():find("repair") then
                    print("[SOEKKI]   Пробуем отправить в:", child.Name)
                    pcall(function()
                        child:FireServer("applyBoost", boostType)
                    end)
                end
            end
        end
    end
    
    -- Также устанавливаем атрибуты для надежности
    pcall(function()
        generator:SetAttribute("repairboost", 1 + GeneratorBoostConfig.BoostPercent / 100)
        generator:SetAttribute("BoostMultiplier", 1 + GeneratorBoostConfig.BoostPercent / 100)
    end)
    
    activeGeneratorBoosts[generator] = boostType
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
        print("[SOEKKI] [removeGeneratorBoost] ⚠️ Бафф не найден")
        return
    end
    
    -- ОТПРАВЛЯЕМ НА СЕРВЕР снятие баффа
    if perfectionistplanning then
        print("[SOEKKI] [removeGeneratorBoost] Отправляем на сервер: clearBoost")
        perfectionistplanning:FireServer("clearBoost")
        print("[SOEKKI] ❌❌❌ БАФФ СНЯТ (отправлено на сервер)")
    end
    
    -- Снимаем атрибуты
    pcall(function()
        generator:SetAttribute("repairboost", nil)
        generator:SetAttribute("BoostMultiplier", nil)
    end)
    
    activeGeneratorBoosts[generator] = nil
    if currentGenerator == generator then
        currentGenerator = nil
    end
    
    print("[SOEKKI] ========================================")
end

-- ============================================
--   ОСНОВНАЯ ФУНКЦИЯ - КАК В PERFECTIONIST
-- ============================================
local function onRepairAnim(p1, p2, p3, p4, p5, p6)
    print("[SOEKKI] [onRepairAnim] ========================================")
    print("[SOEKKI] [onRepairAnim] ВЫЗВАНА!")
    
    -- Выводим все аргументы
    print("[SOEKKI]   p1 =", p1, "тип:", type(p1))
    print("[SOEKKI]   p2 =", p2, "тип:", type(p2))
    print("[SOEKKI]   p3 =", p3, "тип:", type(p3))
    print("[SOEKKI]   p4 =", p4, "тип:", type(p4))
    print("[SOEKKI]   p5 =", p5, "тип:", type(p5))
    print("[SOEKKI]   p6 =", p6, "тип:", type(p6))
    
    if p2 == true then
        print("[SOEKKI] 🔧 НАЧАЛО РЕМОНТА")
    elseif p2 == false then
        print("[SOEKKI] 🛑 КОНЕЦ РЕМОНТА")
    else
        print("[SOEKKI] ⚠️ НЕИЗВЕСТНОЕ ЗНАЧЕНИЕ p2 =", p2)
        return
    end
    
    -- Ищем генератор как в perfectionist.txt
    local generator = nil
    
    -- Способ 1: p3.Parent (как в perfectionist)
    if p3 and p3.Parent then
        generator = p3.Parent
        print("[SOEKKI] Способ 1 (p3.Parent):", generator and generator.Name or "nil")
    end
    
    -- Способ 2: если p3 это CFrame, то p4 может быть объектом
    if not generator and p4 and p4.Parent then
        generator = p4.Parent
        print("[SOEKKI] Способ 2 (p4.Parent):", generator and generator.Name or "nil")
    end
    
    -- Способ 3: ищем среди аргументов объект с Parent
    if not generator then
        local args = {p1, p2, p3, p4, p5, p6}
        for i, arg in ipairs(args) do
            if type(arg) == "table" and arg.Parent and type(arg.Parent) == "table" then
                generator = arg.Parent
                print("[SOEKKI] Способ 3 (аргумент #" .. i .. ".Parent):", generator and generator.Name or "nil")
                break
            end
        end
    end
    
    if not generator then
        print("[SOEKKI] ❌ Не удалось найти генератор!")
        return
    end
    
    -- Проверяем, что это генератор
    local isGenerator = CollectionService:HasTag(generator, "Generator")
    print("[SOEKKI] CollectionService:HasTag =", isGenerator)
    print("[SOEKKI] generator.Name =", generator.Name)
    
    if not isGenerator then
        -- Проверяем дочерние элементы
        for _, child in ipairs(generator:GetDescendants()) do
            if CollectionService:HasTag(child, "Generator") then
                isGenerator = true
                generator = child
                print("[SOEKKI] Найден генератор в дочерних элементах:", generator.Name)
                break
            end
        end
    end
    
    if not isGenerator then
        print("[SOEKKI] ⚠️ Это НЕ генератор, пропускаем")
        return
    end
    
    if p2 == true then
        -- Начало ремонта
        if GeneratorBoostConfig.Enabled then
            applyGeneratorBoost(generator)
        else
            print("[SOEKKI] ⚠️ Бафф выключен! Включите в меню (Modification -> Enable Generator Boost)")
        end
    else
        -- Конец ремонта
        removeGeneratorBoost(generator)
    end
    
    print("[SOEKKI] ========================================")
end

-- ============================================
--   ПОДКЛЮЧЕНИЕ РЕМОУТОВ
-- ============================================
local function setupRemoteListeners()
    print("[SOEKKI] [setupRemoteListeners] Поиск ремоутов...")
    
    if RepairAnim then
        print("[SOEKKI] ✅ RepairAnim найден, подключаем...")
        RepairAnim.OnClientEvent:Connect(onRepairAnim)
        print("[SOEKKI] ✅ RepairAnim подключен!")
    else
        print("[SOEKKI] ❌ RepairAnim не найден!")
        
        -- Пробуем найти альтернативные пути
        local paths = {
            ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Generator"),
            ReplicatedStorage:FindFirstChild("Generator"),
            ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Repair")
        }
        
        for _, path in ipairs(paths) do
            if path then
                local anim = path:FindFirstChild("RepairAnim")
                if anim then
                    print("[SOEKKI] Найден RepairAnim по альтернативному пути!")
                    anim.OnClientEvent:Connect(onRepairAnim)
                end
            end
        end
    end
    
    -- Выводим все ремоуты в Perks
    local Perks = Remotes and Remotes:FindFirstChild("Perks")
    if Perks then
        print("[SOEKKI] Содержимое Perks:")
        for _, child in ipairs(Perks:GetChildren()) do
            print("[SOEKKI]   -", child.Name)
        end
    end
end

-- Запускаем
task.spawn(setupRemoteListeners)

-- ============================================
--   МОНИТОРИНГ (ДЛЯ ОТЛАДКИ)
-- ============================================
task.spawn(function()
    print("[SOEKKI] [Monitor] Запуск мониторинга...")
    
    while true do
        if GeneratorBoostConfig.Enabled and currentGenerator then
            print("[SOEKKI] [Monitor] Активный бафф на:", currentGenerator.Name)
            print("[SOEKKI] [Monitor]   Тип:", activeGeneratorBoosts[currentGenerator] or "none")
            print("[SOEKKI] [Monitor]   Процент:", GeneratorBoostConfig.BoostPercent .. "%")
        end
        
        task.wait(10)
    end
end)

-- ============================================
--   GUI ДЛЯ ESP
-- ============================================
local function SetupGui()
    print("[SOEKKI] [SetupGui] Создание GUI...")
    if PlayerGui:FindFirstChild("ChasedInds") then 
        PlayerGui:FindFirstChild("ChasedInds"):Destroy() 
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
    print("[SOEKKI] [SetGeneratorBoostEnabled] enabled =", enabled)
    GeneratorBoostConfig.Enabled = enabled
    
    if not enabled then
        if perfectionistplanning then
            print("[SOEKKI] Отправляем clearBoost на сервер")
            perfectionistplanning:FireServer("clearBoost")
        end
        for generator, _ in pairs(activeGeneratorBoosts) do
            activeGeneratorBoosts[generator] = nil
        end
        table.clear(activeGeneratorBoosts)
        currentGenerator = nil
    end
end

function module.GetGeneratorBoostEnabled()
    return GeneratorBoostConfig.Enabled
end

function module.SetGeneratorBoostPercent(percent)
    GeneratorBoostConfig.BoostPercent = math.clamp(percent, 0, 100)
    print("[SOEKKI] Boost percent:", GeneratorBoostConfig.BoostPercent .. "%")
    
    -- Если бафф включен и есть активный генератор, обновляем
    if GeneratorBoostConfig.Enabled and currentGenerator then
        local boostType = getBoostType()
        if perfectionistplanning then
            print("[SOEKKI] Обновляем бафф на сервере:", boostType)
            perfectionistplanning:FireServer("applyBoost", boostType)
        end
    end
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
print("[SOEKKI] ========================================")
print("[SOEKKI] ИНСТРУКЦИЯ ПО ТЕСТИРОВАНИЮ:")
print("[SOEKKI] 1. Откройте консоль (F9)")
print("[SOEKKI] 2. Включите бафф в меню")
print("[SOEKKI] 3. Начните чинить генератор")
print("[SOEKKI] 4. Смотрите логи")
print("[SOEKKI] ========================================")
print("[SOEKKI] perfectionistplanning найден:", perfectionistplanning ~= nil)

return module