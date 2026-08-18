-- ViolenceDistrict.lua - ГЛАВНЫЙ ФАЙЛ
print("[SOEKKI] Loading Violence District...")

local function loadModule(url)
    print("[SOEKKI] Loading: " .. url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if not success then
        error("Failed to load: " .. url .. "\nError: " .. tostring(result))
    end
    return result
end

-- ТВОЯ ССЫЛКА (репозиторий должен быть ПУБЛИЧНЫМ!)
local BASE_URL = "https://raw.githubusercontent.com/Soekki/SOEKKI/refs/heads/main/"

-- 1. Загружаем конфиг
local configCode = loadModule(BASE_URL .. "config.lua")
local config, configErr = loadstring(configCode)
if not config then
    error("Compile error in config: " .. tostring(configErr))
end
config()
print("[SOEKKI] ✅ config loaded!")

-- 2. Загружаем Generator Boost
local boostCode = loadModule(BASE_URL .. "generator_boost.lua")
local boost, boostErr = loadstring(boostCode)
if not boost then
    error("Compile error in generator_boost: " .. tostring(boostErr))
end
boost()
print("[SOEKKI] ✅ generator_boost loaded!")

-- 3. Загружаем функции
local functionsCode = loadModule(BASE_URL .. "main_functions.lua")
local func, funcErr = loadstring(functionsCode)
if not func then
    error("Compile error in main_functions: " .. tostring(funcErr))
end
func()
print("[SOEKKI] ✅ main_functions loaded!")

-- 4. Загружаем UI
local uiCode = loadModule(BASE_URL .. "main_ui.lua")
local ui, uiErr = loadstring(uiCode)
if not ui then
    error("Compile error in main_ui: " .. tostring(uiErr))
end
ui()
print("[SOEKKI] ✅ main_ui loaded!")

-- 5. Активируем Generator Boost по умолчанию (опционально)
task.wait(1)
if _G.GeneratorBoost then
    _G.GeneratorBoost:Toggle()
    print("[SOEKKI] 🟢 Generator Boost auto-enabled!")
end

print("[SOEKKI] 🚀 ALL LOADED!")
print("[SOEKKI] 💡 Press RightShift to toggle menu (works everywhere!)")
print("[SOEKKI] 💡 Use _G.GeneratorBoost:Toggle() to toggle repair boost")
print("[SOEKKI] 💡 Use _G.GeneratorBoost:StopRepair() to stop repair")