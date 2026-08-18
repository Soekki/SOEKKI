-- generator_boost.lua - БАФФ СКОРОСТИ ПОЧИНКИ ГЕНЕРАТОРОВ
-- ============================================
--   УСКОРЕНИЕ РЕМОНТА ЧЕРЕЗ REPAIREVENT
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Config = _G.Config or {}

-- ============================================
--   ПОИСК REMOTE EVENTS
-- ============================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local GeneratorRemotes = Remotes and Remotes:FindFirstChild("Generator")

local RepairEvent = GeneratorRemotes and GeneratorRemotes:FindFirstChild("RepairEvent")
local RepairAnim = GeneratorRemotes and GeneratorRemotes:FindFirstChild("RepairAnim")
local RepairCommit = GeneratorRemotes and GeneratorRemotes:FindFirstChild("RepairCommit")
local RepairReject = GeneratorRemotes and GeneratorRemotes:FindFirstChild("RepairReject")

-- ============================================
--   ПРОВЕРКА НАЛИЧИЯ СОБЫТИЙ
-- ============================================
if not RepairEvent then
    warn("[GeneratorBoost] ❌ RepairEvent not found! Trying to find...")
    -- Поиск в других местах
    RepairEvent = ReplicatedStorage:FindFirstChild("RepairEvent", true)
    if not RepairEvent then
        warn("[GeneratorBoost] ❌ Still not found! Repair boost disabled.")
    end
end

print("[GeneratorBoost] 🔧 Found RepairEvent:", RepairEvent and "✅" or "❌")
print("[GeneratorBoost] 🔧 Found RepairAnim:", RepairAnim and "✅" or "❌")

-- ============================================
--   ОСНОВНАЯ ЛОГИКА БАФФА
-- ============================================

local GeneratorBoost = {
    Enabled = false,
    ActiveGenerators = {},  -- {generator, character, connection}
    RepairLoopConnections = {},
    CurrentTarget = nil,
    IsRepairing = false,
}

-- ============================================
--   ОТПРАВКА REPAIR EVENT
-- ============================================
local function SendRepairEvent(generator, character)
    if not RepairEvent then return false end
    if not generator or not generator.Parent then return false end
    
    -- Подготовка данных (как в оригинальной игре)
    local data = {
        generator = generator,
        character = character or LocalPlayer.Character,
    }
    
    -- Отправка события
    local success, err = pcall(function()
        RepairEvent:FireServer(data)
    end)
    
    if not success then
        warn("[GeneratorBoost] ❌ Failed to send RepairEvent:", err)
        return false
    end
    
    -- Отправка анимации (если включено)
    if Config.Generators.SendRepairAnim and RepairAnim then
        pcall(function()
            RepairAnim:FireServer(data)
        end)
    end
    
    return true
end

-- ============================================
--   ОТПРАВКА REPAIR COMMIT (фиксация ремонта)
-- ============================================
local function SendRepairCommit(generator, character)
    if not RepairCommit then return end
    
    local data = {
        generator = generator,
        character = character or LocalPlayer.Character,
    }
    
    pcall(function()
        RepairCommit:FireServer(data)
    end)
end

-- ============================================
--   ЦИКЛ РЕМОНТА (СПАМ СОБЫТИЯМИ)
-- ============================================
local function StartRepairLoop(generator)
    if not generator or not generator.Parent then return end
    if GeneratorBoost.IsRepairing then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    GeneratorBoost.IsRepairing = true
    GeneratorBoost.CurrentTarget = generator
    
    print("[GeneratorBoost] ⚡ Starting repair loop on generator:", generator.Name)
    
    local eventsPerCycle = Config.Generators.EventsPerCycle or 3
    local interval = Config.Generators.RepairMultiplier or 3.0
    local boostMultiplier = Config.Generators.RepairMultiplier or 3.0
    
    -- Отправляем несколько событий сразу для ускорения
    local function SendRepairBatch()
        if not GeneratorBoost.IsRepairing then return end
        if not generator or not generator.Parent then
            GeneratorBoost.IsRepairing = false
            return
        end
        
        -- Проверяем, не завершен ли генератор
        local progress = generator:GetAttribute("RepairProgress") or generator:GetAttribute("Progress") or 0
        if progress >= 100 then
            print("[GeneratorBoost] ✅ Generator completed!")
            GeneratorBoost.IsRepairing = false
            GeneratorBoost.CurrentTarget = nil
            return
        end
        
        -- Отправляем несколько событий за раз (спам)
        for i = 1, eventsPerCycle do
            SendRepairEvent(generator, character)
        end
        
        -- Отправляем коммит для фиксации прогресса
        SendRepairCommit(generator, character)
    end
    
    -- Создаем цикл с интервалом
    local connection = RunService.Heartbeat:Connect(function(delta)
        if not GeneratorBoost.IsRepairing then
            connection:Disconnect()
            return
        end
        
        -- Спам событиями каждые interval секунд
        if not GeneratorBoost._lastSend or tick() - GeneratorBoost._lastSend >= (Config.Generators.EventInterval or 0.05) then
            GeneratorBoost._lastSend = tick()
            SendRepairBatch()
        end
    end)
    
    table.insert(GeneratorBoost.RepairLoopConnections, connection)
end

-- ============================================
--   ОСТАНОВКА РЕМОНТА
-- ============================================
function GeneratorBoost.StopRepair()
    if GeneratorBoost.IsRepairing then
        print("[GeneratorBoost] ⏹ Stopping repair loop...")
        GeneratorBoost.IsRepairing = false
        GeneratorBoost.CurrentTarget = nil
        
        -- Отключаем все соединения
        for _, conn in ipairs(GeneratorBoost.RepairLoopConnections) do
            pcall(function() conn:Disconnect() end)
        end
        GeneratorBoost.RepairLoopConnections = {}
        
        -- Отправляем RepairReject для остановки
        if RepairReject then
            pcall(function()
                RepairReject:FireServer({})
            end)
        end
    end
end

-- ============================================
--   ВКЛЮЧЕНИЕ/ВЫКЛЮЧЕНИЕ БАФФА
-- ============================================
function GeneratorBoost.Toggle()
    GeneratorBoost.Enabled = not GeneratorBoost.Enabled
    
    if GeneratorBoost.Enabled then
        print("[GeneratorBoost] 🟢 Boost ENABLED!")
        
        -- Если есть текущая цель - начинаем ремонт
        if GeneratorBoost.CurrentTarget then
            StartRepairLoop(GeneratorBoost.CurrentTarget)
        end
        
        -- Автоматический старт ремонта при подходе
        if Config.Generators.AutoStartRepair then
            GeneratorBoost.AutoStartScan()
        end
    else
        print("[GeneratorBoost] 🔴 Boost DISABLED!")
        GeneratorBoost.StopRepair()
        
        -- Останавливаем авто-скан
        if GeneratorBoost._scanConnection then
            GeneratorBoost._scanConnection:Disconnect()
            GeneratorBoost._scanConnection = nil
        end
    end
    
    return GeneratorBoost.Enabled
end

-- ============================================
--   АВТОМАТИЧЕСКОЕ ОБНАРУЖЕНИЕ ГЕНЕРАТОРОВ
-- ============================================
function GeneratorBoost:AutoStartScan()
    if GeneratorBoost._scanConnection then
        GeneratorBoost._scanConnection:Disconnect()
        GeneratorBoost._scanConnection = nil
    end
    
    if not GeneratorBoost.Enabled then return end
    
    -- Запускаем сканирование на каждом Heartbeat
    GeneratorBoost._scanConnection = RunService.Heartbeat:Connect(function()
        if not GeneratorBoost.Enabled then
            GeneratorBoost._scanConnection:Disconnect()
            GeneratorBoost._scanConnection = nil
            return
        end
        
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local radius = Config.Generators.AutoStartRadius or 15
        
        -- Ищем генераторы в радиусе
        local Map = workspace:FindFirstChild("Map")
        if not Map then return end
        
        for _, obj in ipairs(Map:GetDescendants()) do
            if obj.Name == "Generator" and obj:IsA("Model") then
                -- Проверяем, не завершен ли генератор
                local progress = obj:GetAttribute("RepairProgress") or obj:GetAttribute("Progress") or 0
                if progress >= 100 then
                    continue
                end
                
                -- Находим центр генератора
                local centerPart = obj:FindFirstChild("defaultMaterial", true) or obj:FindFirstChildWhichIsA("Part")
                if not centerPart then continue end
                
                -- Проверяем расстояние
                local distance = (centerPart.Position - rootPart.Position).Magnitude
                if distance <= radius then
                    -- Автоматически начинаем ремонт
                    if GeneratorBoost.CurrentTarget ~= obj then
                        GeneratorBoost.StopRepair()
                        GeneratorBoost.CurrentTarget = obj
                        StartRepairLoop(obj)
                    end
                    break
                end
            end
        end
    end)
end

-- ============================================
--   РУЧНОЙ СТАРТ РЕМОНТА (ИЗ UI)
-- ============================================
function GeneratorBoost:StartRepairOnTarget(generator)
    if not generator or not generator.Parent then return end
    
    -- Проверяем, не завершен ли
    local progress = generator:GetAttribute("RepairProgress") or generator:GetAttribute("Progress") or 0
    if progress >= 100 then
        print("[GeneratorBoost] ⚠️ Generator already completed!")
        return
    end
    
    if GeneratorBoost.CurrentTarget == generator and GeneratorBoost.IsRepairing then
        print("[GeneratorBoost] ⚠️ Already repairing this generator!")
        return
    end
    
    GeneratorBoost.StopRepair()
    GeneratorBoost.CurrentTarget = generator
    StartRepairLoop(generator)
end

-- ============================================
--   ПОИСК БЛИЖАЙШЕГО ГЕНЕРАТОРА
-- ============================================
function GeneratorBoost:GetNearestGenerator()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local Map = workspace:FindFirstChild("Map")
    if not Map then return nil end
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, obj in ipairs(Map:GetDescendants()) do
        if obj.Name == "Generator" and obj:IsA("Model") then
            local progress = obj:GetAttribute("RepairProgress") or obj:GetAttribute("Progress") or 0
            if progress >= 100 then continue end
            
            local centerPart = obj:FindFirstChild("defaultMaterial", true) or obj:FindFirstChildWhichIsA("Part")
            if not centerPart then continue end
            
            local dist = (centerPart.Position - rootPart.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = obj
            end
        end
    end
    
    return nearest, nearestDist
end

-- ============================================
--   ЭКСПОРТ
-- ============================================
_G.GeneratorBoost = GeneratorBoost

print("[GeneratorBoost] ✅ Loaded!")
print("[GeneratorBoost] 💡 Use _G.GeneratorBoost:Toggle() to enable/disable")
print("[GeneratorBoost] 💡 Use _G.GeneratorBoost:StartRepairOnTarget(generator) to start repair")

return GeneratorBoost