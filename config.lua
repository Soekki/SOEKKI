-- config.lua - ФАЙЛ КОНФИГУРАЦИИ
-- ============================================
--   НАСТРОЙКИ ЧИТА
-- ============================================

local Config = {
    -- ==========================================
    --   НАСТРОЙКИ ГЕНЕРАТОРОВ
    -- ==========================================
    Generators = {
        -- ВКЛЮЧИТЬ/ВЫКЛЮЧИТЬ УСКОРЕНИЕ РЕМОНТА
        RepairBoostEnabled = false,
        
        -- МНОЖИТЕЛЬ СКОРОСТИ РЕМОНТА (1.0 = норма, 2.0 = в 2 раза быстрее, 5.0 = супер-быстро)
        RepairMultiplier = 3.0,
        
        -- ИНТЕРВАЛ ОТПРАВКИ СОБЫТИЙ (в секундах)
        -- Меньше = быстрее, но рискованнее (0.01 = очень быстро)
        EventInterval = 0.05,
        
        -- ОТПРАВЛЯТЬ ЛИ REPAIRANIM (если true - чинка с анимацией, если false - без анимации)
        SendRepairAnim = true,
        
        -- КОЛИЧЕСТВО РЕМОНТОВ ЗА ОДИН ЦИКЛ (спам событиями)
        EventsPerCycle = 3,
        
        -- АВТОМАТИЧЕСКИ НАЧИНАТЬ РЕМОНТ ПРИ ПОДХОДЕ К ГЕНЕРАТОРУ
        AutoStartRepair = true,
        
        -- РАДИУС АВТО-СТАРТА РЕМОНТА
        AutoStartRadius = 15,
    },
    
    -- ==========================================
    --   НАСТРОЙКИ SKILL CHECK (уже есть)
    -- ==========================================
    SkillCheck = {
        AutoSkillCheck = true,
        InstantSkillCheck = false,
        SkillCheckMode = "Perfect",  -- "Perfect", "Normal", "Off"
        NoSkillChecks = false,
        SkillCheckSpeedVal = 1,
    },
    
    -- ==========================================
    --   ДРУГИЕ НАСТРОЙКИ
    -- ==========================================
    ESP = {
        ShowGenerators = true,
        ShowGates = true,
        ShowPallets = true,
        ShowWindows = true,
        ShowHooks = true,
        ShowPlayers = true,
        ShowKillerWarning = true,
        FullBright = true,
    },
    
    SpeedBoost = 1.1,
}

-- Глобальный доступ
_G.Config = Config

print("[CONFIG] Loaded!")
return Config