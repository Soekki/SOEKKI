-- generator_boost.lua - БАФФ СКОРОСТИ ПОЧИНКИ ГЕНЕРАТОРОВ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ============================================
--   ПОИСК REMOTE EVENTS (ВСЕ ВОЗМОЖНЫЕ ВАРИАНТЫ)
-- ============================================
local function FindRemote(path)
    local parts = {}
    for part in string.gmatch(path, "[^.]+") do
        table.insert(parts, part)
    end
    
    local current = ReplicatedStorage
    for _, part in ipairs(parts) do
        if not current then return nil end
        current = current:FindFirstChild(part)
    end
    return current
end

-- Ищем RepairEvent во всех возможных местах
local RepairEvent = FindRemote("Remotes.Generator.RepairEvent")
    or FindRemote("Remotes.RepairEvent")
    or FindRemote("RepairEvent")
    or ReplicatedStorage:FindFirstChild("RepairEvent", true)

local RepairAnim = FindRemote("Remotes.Generator.RepairAnim")
    or FindRemote("Remotes.RepairAnim")
    or FindRemote("RepairAnim")
    or ReplicatedStorage:FindFirstChild("RepairAnim", true)

local RepairCommit = FindRemote("Remotes.Generator.RepairCommit")
    or FindRemote("Remotes.RepairCommit")
    or FindRemote("RepairCommit")
    or ReplicatedStorage:FindFirstChild("RepairCommit", true)

print("[GeneratorBoost] 🔧 Found RepairEvent:", RepairEvent and "✅" or "❌")
print("[GeneratorBoost] 🔧 Found RepairAnim:", RepairAnim and "✅" or "❌")
print("[GeneratorBoost] 🔧 Found RepairCommit:", RepairCommit and "✅" or "❌")

-- ============================================
--   ОСНОВНАЯ ЛОГИКА
-- ============================================

local GeneratorBoost = {
    Enabled = false,
    IsRepairing = false,
    CurrentTarget = nil,
    Connections = {},
    RepairLoopConnection = nil,
    ScanConnection = nil,
}

-- ============================================
--   ОТПРАВКА REPAIR EVENT
-- ============================================
local function SendRepairEvent(generator, character)
    if not RepairEvent then 
        warn("[GeneratorBoost] ❌ RepairEvent not found!")
        return false 
    end
    if not generator or not generator.Parent then return false end
    
    -- Пробуем разные форматы данных
    local dataFormats = {
        {generator = generator, character = character},
        {Generator = generator, Character = character},
        {gen = generator, char = character},
        {generator},
        {generator, character},
    }
    
    for _, data in ipairs(dataFormats) do
        local success, err = pcall(function()
            RepairEvent:FireServer(unpack(data))
        end)
        if success then 
            return true 
        end
    end
    
    -- Если ничего не сработало, пробуем просто FireServer без параметров
    local success, err = pcall(function()
        RepairEvent:FireServer()
    end)
    
    if not success then
        warn("[GeneratorBoost] ❌ Failed to send RepairEvent:", err)
        return false
    end
    
    return true
end

-- ============================================
--   ОТПРАВКА REPAIR ANIM
-- ============================================
local function SendRepairAnim(generator, character)
    if not RepairAnim then return false end
    
    local dataFormats = {
        {generator = generator, character = character},
        {Generator = generator, Character = character},
        {gen = generator, char = character},
        {generator},
        {generator, character},
    }
    
    for _, data in ipairs(dataFormats) do
        local success, err = pcall(function()
            RepairAnim:FireServer(unpack(data))
        end)
        if success then return true end
    end
    
    return false
end

-- ============================================
--   ОТПРАВКА REPAIR COMMIT
-- ============================================
local function SendRepairCommit(generator, character)
    if not RepairCommit then return false end
    
    local dataFormats = {
        {generator = generator, character = character},
        {Generator = generator, Character = character},
        {gen = generator, char = character},
        {generator},
        {generator, character},
    }
    
    for _, data in ipairs(dataFormats) do
        local success, err = pcall(function()
            RepairCommit:FireServer(unpack(data))
        end)
        if success then return true end
    end
    
    return false
end

-- ============================================
--   ЦИКЛ РЕМОНТА
-- ============================================
local function StartRepairLoop(generator)
    if not generator or not generator.Parent then 
        print("[GeneratorBoost] ⚠️ Generator no longer exists!")
        return 
    end
    
    if GeneratorBoost.IsRepairing and GeneratorBoost.CurrentTarget == generator then
        return
    end
    
    local character = LocalPlayer.Character
    if not character then 
        print("[GeneratorBoost] ⚠️ No character!")
        return 
    end
    
    -- Останавливаем предыдущий цикл
    GeneratorBoost:StopRepair()
    
    GeneratorBoost.IsRepairing = true
    GeneratorBoost.CurrentTarget = generator
    
    print("[GeneratorBoost] ⚡ Starting repair loop on generator:", generator.Name)
    
    local eventsPerCycle = 5  -- Количество событий за цикл
    local lastSend = 0
    local interval = 0.03  -- Интервал между отправками (очень быстро!)
    
    -- Основной цикл
    GeneratorBoost.RepairLoopConnection = RunService.Heartbeat:Connect(function()
        if not GeneratorBoost.IsRepairing or not GeneratorBoost.Enabled then
            GeneratorBoost:StopRepair()
            return
        end
        
        if not generator or not generator.Parent then
            print("[GeneratorBoost] ⚠️ Generator destroyed!")
            GeneratorBoost:StopRepair()
            return
        end
        
        -- Проверяем прогресс
        local progress = generator:GetAttribute("RepairProgress") or generator:GetAttribute("Progress") or 0
        if progress and progress >= 100 then
            print("[GeneratorBoost] ✅ Generator completed!")
            GeneratorBoost:StopRepair()
            return
        end
        
        -- Отправляем события с интервалом
        local now = tick()
        if now - lastSend >= interval then
            lastSend = now
            
            -- Отправляем несколько событий за раз
            for i = 1, eventsPerCycle do
                SendRepairEvent(generator, character)
                SendRepairAnim(generator, character)
            end
            
            -- Фиксируем прогресс
            SendRepairCommit(generator, character)
        end
    end)
end

-- ============================================
--   ОСТАНОВКА РЕМОНТА
-- ============================================
function GeneratorBoost:StopRepair()
    if GeneratorBoost.IsRepairing then
        print("[GeneratorBoost] ⏹ Stopping repair loop...")
    end
    
    GeneratorBoost.IsRepairing = false
    GeneratorBoost.CurrentTarget = nil
    
    if GeneratorBoost.RepairLoopConnection then
        GeneratorBoost.RepairLoopConnection:Disconnect()
        GeneratorBoost.RepairLoopConnection = nil
    end
    
    if GeneratorBoost.ScanConnection then
        GeneratorBoost.ScanConnection:Disconnect()
        GeneratorBoost.ScanConnection = nil
    end
end

-- ============================================
--   ВКЛЮЧЕНИЕ/ВЫКЛЮЧЕНИЕ БАФФА
-- ============================================
function GeneratorBoost:Toggle()
    self.Enabled = not self.Enabled
    
    if self.Enabled then
        print("[GeneratorBoost] 🟢 Boost ENABLED!")
        -- Автоматический поиск ближайшего генератора
        local nearest = self:GetNearestGenerator()
        if nearest then
            self:StartRepairOnTarget(nearest)
        else
            -- Запускаем сканирование
            self:StartAutoScan()
        end
    else
        print("[GeneratorBoost] 🔴 Boost DISABLED!")
        self:StopRepair()
    end
    
    return self.Enabled
end

-- ============================================
--   АВТОМАТИЧЕСКОЕ СКАНИРОВАНИЕ
-- ============================================
function GeneratorBoost:StartAutoScan()
    if self.ScanConnection then
        self.ScanConnection:Disconnect()
        self.ScanConnection = nil
    end
    
    if not self.Enabled then return end
    
    self.ScanConnection = RunService.Heartbeat:Connect(function()
        if not self.Enabled then
            self:StopRepair()
            return
        end
        
        if not self.IsRepairing then
            local nearest = self:GetNearestGenerator()
            if nearest then
                self:StartRepairOnTarget(nearest)
            end
        end
    end)
end

-- ============================================
--   РУЧНОЙ СТАРТ РЕМОНТА
-- ============================================
function GeneratorBoost:StartRepairOnTarget(generator)
    if not generator or not generator.Parent then 
        print("[GeneratorBoost] ⚠️ Invalid generator!")
        return 
    end
    
    local progress = generator:GetAttribute("RepairProgress") or generator:GetAttribute("Progress") or 0
    if progress and progress >= 100 then
        print("[GeneratorBoost] ⚠️ Generator already completed!")
        return
    end
    
    if self.IsRepairing and self.CurrentTarget == generator then
        print("[GeneratorBoost] ⚠️ Already repairing this generator!")
        return
    end
    
    self:StopRepair()
    StartRepairLoop(generator)
end

-- ============================================
--   ПОИСК БЛИЖАЙШЕГО ГЕНЕРАТОРА
-- ============================================
function GeneratorBoost:GetNearestGenerator()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local Map = Workspace:FindFirstChild("Map") or Workspace
    if not Map then return nil end
    
    local nearest = nil
    local nearestDist = math.huge
    
    -- Ищем во всем Workspace
    local allObjects = Workspace:GetDescendants()
    for _, obj in ipairs(allObjects) do
        if obj.Name == "Generator" and obj:IsA("Model") then
            local progress = obj:GetAttribute("RepairProgress") or obj:GetAttribute("Progress") or 0
            if progress >= 100 then 
                goto continue
            end
            
            -- Ищем центр генератора
            local centerPart = obj:FindFirstChild("defaultMaterial", true) 
                or obj:FindFirstChildWhichIsA("Part")
                or obj:FindFirstChildWhichIsA("MeshPart")
            
            if not centerPart then goto continue end
            
            local dist = (centerPart.Position - rootPart.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = obj
            end
        end
        ::continue::
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