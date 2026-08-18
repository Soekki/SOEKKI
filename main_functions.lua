-- main_functions.lua - ПОЛНАЯ ВЕРСИЯ С РАЗДЕЛЬНЫМИ НАСТРОЙКАМИ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================
--   НАСТРОЙКИ ESP (КАЖДАЯ ОТДЕЛЬНО)
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
--   ФУНКЦИЯ ПОДСВЕТКИ (РАБОТАЕТ ОТДЕЛЬНО ОТ PLAYERS)
-- ============================================
local function ApplyHighlight(object, color)
    -- НЕ проверяем ShowPlayers здесь!
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

-- Удаляем старый ApplyHighlight для объектов (если есть)
local function RemoveHighlight(object)
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
    
    -- Если ShowPlayers выключен - удаляем всё
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
    
    -- Подсветка игрока (используем ApplyHighlight, но НЕ проверяем ShowPlayers)
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
    -- Подсветка генератора
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
--   ОБНОВЛЕНИЕ ESP (КАЖДАЯ ФУНКЦИЯ ОТДЕЛЬНО)
-- ============================================
local function RefreshESP()
    ActiveGenerators = {}
    
    -- Windows
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
        -- Generators
        if obj.Name == "Generator" then
            if ESPConfig.ShowGenerators then
                ApplyHighlight(obj, Config.Objects.Generator.Color)
                table.insert(ActiveGenerators, obj)
            else
                RemoveHighlight(obj)
            end
        -- Hooks
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
        -- Pallets
        elseif (obj.Name == "Palletwrong" or obj.Name == "Pallet") then
            if ESPConfig.ShowPallets then
                ApplyHighlight(obj, Config.Objects.Pallet.Color)
            else
                RemoveHighlight(obj)
            end
        -- Gates
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

print("[SOEKKI] Functions loaded!")


-- ============================================
--   ЗАГРУЗКА GENERATOR BOOST
-- ============================================
local function LoadGeneratorBoost()
    print("[SOEKKI] Loading GeneratorBoost...")
    
    -- Проверяем наличие модуля
    local boostModule = script.Parent:FindFirstChild("generator_boost")
    if not boostModule then
        warn("[SOEKKI] ❌ generator_boost.lua not found!")
        return
    end
    
    local boostFunc, err = loadstring(boostModule:GetFullName())
    if not boostFunc then
        warn("[SOEKKI] ❌ Failed to load generator_boost:", err)
        return
    end
    
    pcall(boostFunc)
    print("[SOEKKI] ✅ GeneratorBoost loaded!")
    
    -- Добавляем функцию в глобальный доступ
    _G.ToggleGeneratorBoost = function()
        if _G.GeneratorBoost then
            return _G.GeneratorBoost:Toggle()
        end
        warn("[SOEKKI] ❌ GeneratorBoost not available!")
        return false
    end
end

-- Загружаем
LoadGeneratorBoost()

return module