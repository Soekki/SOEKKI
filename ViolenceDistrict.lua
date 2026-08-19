-- ViolenceDistrict.lua - SOEKKI persistent UI loader (robust patch)
-- This version does not depend on exact whitespace/text blocks in main_ui.lua.

print("[SOEKKI] Loading Violence District...")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local BASE_URL = "https://raw.githubusercontent.com/Soekki/SOEKKI/refs/heads/main/"

local function loadModule(url)
    print("[SOEKKI] Loading: " .. url)

    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        error("Failed to load: " .. tostring(url) .. "\nError: " .. tostring(result))
    end

    return result
end

local function runModule(name, code)
    local fn, compileErr = loadstring(code)
    if not fn then
        error("Compile error in " .. name .. ": " .. tostring(compileErr))
    end

    local ok, runtimeErr = pcall(fn)
    if not ok then
        error("Runtime error in " .. name .. ": " .. tostring(runtimeErr))
    end

    print("[SOEKKI] " .. name .. " loaded!")
end

-- Config
runModule("config", loadModule(BASE_URL .. "config.lua"))

-- Generator boost is loaded, but NOT auto-enabled.
do
    local boostCode = loadModule(BASE_URL .. "generator_boost.lua")
    local boostFn, boostErr = loadstring(boostCode)

    if not boostFn then
        warn("[SOEKKI] Compile error in generator_boost: " .. tostring(boostErr))
    else
        local ok, err = pcall(boostFn)
        if ok then
            print("[SOEKKI] generator_boost loaded!")
        else
            warn("[SOEKKI] generator_boost runtime error: " .. tostring(err))
        end
    end
end

-- Main functions
runModule("main_functions", loadModule(BASE_URL .. "main_functions.lua"))

-- ============================================================
-- Robust UI patch
-- ============================================================
local function patchUI(source)
    local original = source
    local changes = 0

    -- 1) Use Global ZIndexBehavior.
    local newSource, n = source:gsub(
        'screenGui%.ZIndexBehavior%s*=%s*Enum%.ZIndexBehavior%.Sibling',
        'screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global',
        1
    )
    if n > 0 then
        source = newSource
        changes += n
    end

    -- 2) Keep MainFrame as the lowest background layer.
    newSource, n = source:gsub(
        'mainFrame%.ZIndex%s*=%s*%d+',
        'mainFrame.ZIndex = 0',
        1
    )

    if n > 0 then
        source = newSource
        changes += n
    end

    -- 2) Max normal ScreenGui DisplayOrder.
    newSource, n = source:gsub(
        'screenGui%.DisplayOrder%s*=%s*%d+',
        'screenGui.DisplayOrder = 2147483647',
        1
    )
    if n > 0 then
        source = newSource
        changes += n
    else
        newSource, n = source:gsub(
            '(screenGui%.Name%s*=%s*"ViolenceMenu"%s*\n)',
            '%1screenGui.DisplayOrder = 2147483647\n',
            1
        )
        if n > 0 then
            source = newSource
            changes += n
        end
    end

    -- 3) Use gethui() when available, otherwise PlayerGui.
    local parentReplacement = [[
local __SOEKKI_GUI_PARENT

pcall(function()
    if typeof(gethui) == "function" then
        local __hui = gethui()
        if __hui then
            __SOEKKI_GUI_PARENT = __hui
        end
    end
end)

if not __SOEKKI_GUI_PARENT then
    __SOEKKI_GUI_PARENT = player:WaitForChild("PlayerGui")
end

screenGui.Parent = __SOEKKI_GUI_PARENT
]]

    newSource, n = source:gsub(
        'screenGui%.Parent%s*=%s*player:WaitForChild%("PlayerGui"%)',
        function()
            return parentReplacement
        end,
        1
    )
    if n > 0 then
        source = newSource
        changes += n
    end

    -- 4) Give MainFrame a stable name.
    if not source:find('mainFrame.Name%s*=%s*"MainFrame"', 1) then
        newSource, n = source:gsub(
            '(local%s+mainFrame%s*=%s*Instance%.new%("Frame"%)%s*\n)',
            '%1mainFrame.Name = "MainFrame"\n',
            1
        )
        if n > 0 then
            source = newSource
            changes += n
        end
    end

    -- 5) Never destroy the menu from the Settings button.
    newSource, n = source:gsub(
        'screenGui:Destroy%(%)[^\n]*',
        'mainFrame.Visible = false',
        1
    )
    if n > 0 then
        source = newSource
        changes += n
    end

    newSource, n = source:gsub(
        'unloadBtn%.Text%s*=%s*"[^"]*"',
        'unloadBtn.Text = "◀ HIDE MENU"',
        1
    )
    if n > 0 then
        source = newSource
        changes += n
    end

    -- 6) Remove the duplicate UserInputService RightShift handler.
    newSource, n = source:gsub(
        'UserInputService%.InputBegan:Connect%(%s*function%(input,%s*gameProcessed%)%s*.-%s*end%)',
        '',
        1
    )
    if n > 0 then
        source = newSource
        changes += n
    end

    -- 7) Ensure the CAS action is unbound before binding.
    newSource, n = source:gsub(
        'ContextActionService:BindActionAtPriority%(%s*',
        'ContextActionService:UnbindAction("ToggleMenu")\n\nContextActionService:BindActionAtPriority(\n',
        1
    )
    if n > 0 then
        source = newSource
        changes += n
    end

    if source ~= original then
        print("[SOEKKI] UI robust patch applied. Changes:", changes)
    else
        warn("[SOEKKI] UI robust patch made no source changes.")
    end

    return source
end

local uiCode = loadModule(BASE_URL .. "main_ui.lua")
uiCode = patchUI(uiCode)

local uiFn, uiErr = loadstring(uiCode)
if not uiFn then
    error("Compile error in patched main_ui: " .. tostring(uiErr))
end

local ok, err = pcall(uiFn)
if not ok then
    error("Runtime error in patched main_ui: " .. tostring(err))
end

print("[SOEKKI] main_ui loaded with robust persistent-menu patch!")

-- ============================================================
-- Persistent menu watchdog
-- ============================================================
local function findMenu()
    local gui

    pcall(function()
        if typeof(gethui) == "function" then
            local hui = gethui()
            if hui then
                gui = hui:FindFirstChild("ViolenceMenu")
            end
        end
    end)

    if not gui then
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            gui = playerGui:FindFirstChild("ViolenceMenu")
        end
    end

    return gui
end

local restoring = false

local function protectMenu()
    local gui = findMenu()

    if gui then
        pcall(function()
            gui.Enabled = true
            gui.DisplayOrder = 2147483647
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
            gui.IgnoreGuiInset = true
        end)
        return
    end

    if restoring then
        return
    end

    restoring = true

    task.spawn(function()
        warn("[SOEKKI] ViolenceMenu missing; rebuilding UI...")

        local okRestore, restoreErr = pcall(function()
            local fresh = patchUI(loadModule(BASE_URL .. "main_ui.lua"))
            local freshFn, freshCompileErr = loadstring(fresh)

            if not freshFn then
                error(freshCompileErr)
            end

            local okRun, runErr = pcall(freshFn)
            if not okRun then
                error(runErr)
            end
        end)

        if okRestore then
            print("[SOEKKI] ViolenceMenu rebuilt.")
        else
            warn("[SOEKKI] ViolenceMenu rebuild failed:", restoreErr)
        end

        restoring = false
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.15)
    pcall(protectMenu)
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(protectMenu)
    end
end)

print("[SOEKKI] Persistent menu watchdog enabled!")
print("[SOEKKI] ALL LOADED!")
print("[SOEKKI] Press RightShift to show/hide the menu.")
