-- config.lua - ФАЙЛ КОНФИГУРАЦИИ
-- ============================================
--   НАСТРОЙКИ ЧИТА
-- ============================================

local Config = {
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
    
    -- Speed Boost: 0% = x1.00, 100% = x2.00
    SpeedBoostPercent = 0,
}

-- Глобальный доступ
_G.Config = Config

print("[CONFIG] Loaded!")
return Config