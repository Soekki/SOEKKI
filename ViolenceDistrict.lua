-- ViolenceDistrict.lua - Главный файл загрузки
print("[SOEKKI] Loading Violence District...")

local success, result = pcall(function()
    -- Загружаем функции ESP
    local functions = loadstring(game:HttpGet("https://raw.githubusercontent.com/Soekki/ViolenceDistrict/refs/heads/main/main_functions.lua"))()
    if not functions then
        error("Failed to load main_functions.lua")
    end
    
    -- Загружаем UI
    local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Soekki/ViolenceDistrict/refs/heads/main/main_ui.lua"))()
    if not ui then
        error("Failed to load main_ui.lua")
    end
    
    print("[SOEKKI] All modules loaded successfully!")
end)

if not success then
    warn("[SOEKKI] Error loading: " .. tostring(result))
end

return {
    Loaded = success,
    Error = result
}