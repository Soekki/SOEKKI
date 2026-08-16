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

-- ВАЖНО: ссылки на ТВОЙ репозиторий SOEKKI
local BASE_URL = "https://raw.githubusercontent.com/Soekki/SOEKKI/refs/heads/main/"

-- Загружаем функции
local functionsCode = loadModule(BASE_URL .. "main_functions.lua")
local func, funcErr = loadstring(functionsCode)
if not func then
    error("Compile error in main_functions: " .. tostring(funcErr))
end
func()
print("[SOEKKI] ✅ main_functions loaded!")

-- Загружаем UI
local uiCode = loadModule(BASE_URL .. "main_ui.lua")
local ui, uiErr = loadstring(uiCode)
if not ui then
    error("Compile error in main_ui: " .. tostring(uiErr))
end
ui()
print("[SOEKKI] ✅ main_ui loaded!")

print("[SOEKKI] 🚀 ALL LOADED! Press RightShift to toggle menu.")