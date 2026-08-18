-- ViolenceDistrict.lua - SOEKKI persistent UI loader
print("[SOEKKI] Loading Violence District...")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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

local BASE_URL = "https://raw.githubusercontent.com/Soekki/SOEKKI/refs/heads/main/"

-- 1. Config
local configCode = loadModule(BASE_URL .. "config.lua")
local config, configErr = loadstring(configCode)
if not config then
    error("Compile error in config: " .. tostring(configErr))
end

local ok, err = pcall(config)
if not ok then
    error("Runtime error in config: " .. tostring(err))
end
print("[SOEKKI] config loaded!")

-- 2. Generator boost
local boostCode = loadModule(BASE_URL .. "generator_boost.lua")
local boost, boostErr = loadstring(boostCode)
if not boost then
    error("Compile error in generator_boost: " .. tostring(boostErr))
end

ok, err = pcall(boost)
if not ok then
    warn("[SOEKKI] generator_boost runtime error: " .. tostring(err))
else
    print("[SOEKKI] generator_boost loaded!")
end

-- 3. Main functions
local functionsCode = loadModule(BASE_URL .. "main_functions.lua")
local func, funcErr = loadstring(functionsCode)
if not func then
    error("Compile error in main_functions: " .. tostring(funcErr))
end

ok, err = pcall(func)
if not ok then
    error("Runtime error in main_functions: " .. tostring(err))
end
print("[SOEKKI] main_functions loaded!")

-- 4. UI
local uiCode = loadModule(BASE_URL .. "main_ui.lua")

-- The repository's current UI is patched in-memory so you only need to
-- replace this loader while testing the persistent-menu changes.
local function patchUI(source)
    local original = source

    -- Avoid duplicate menus on re-execution.
    local oldGuiBlock = [[
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ViolenceMenu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Защита от удаления
local function ReattachGui()
    if not screenGui.Parent then
        screenGui.Parent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
    end
end

player.CharacterAdded:Connect(function()
    task.wait(0.1)
    ReattachGui()
end)
]]

    local newGuiBlock = [[
-- ============================================
--   PERSISTENT SCREEN GUI
-- ============================================

local existingGui = nil

local function findExistingGui()
    local found = nil

    pcall(function()
        if typeof(gethui) == "function" then
            local hui = gethui()
            if hui then
                found = hui:FindFirstChild("ViolenceMenu")
            end
        end
    end)

    if not found then
        local playerGui = player:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            found = playerGui:FindFirstChild("ViolenceMenu")
        end
    end

    return found
end

existingGui = findExistingGui()

if existingGui then
    existingGui.Enabled = true
    existingGui.DisplayOrder = 2147483647
    existingGui.IgnoreGuiInset = true
    existingGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    local oldMain = existingGui:FindFirstChild("MainFrame", true)
    if oldMain then
        oldMain.Visible = true
    end

    print("[SOEKKI] Existing ViolenceMenu restored.")
    return
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ViolenceMenu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.DisplayOrder = 2147483647
screenGui.IgnoreGuiInset = true
screenGui.Enabled = true
screenGui.Archivable = true

local guiParent

pcall(function()
    if typeof(gethui) == "function" then
        local hui = gethui()
        if hui then
            guiParent = hui
        end
    end
end)

if not guiParent then
    guiParent = player:WaitForChild("PlayerGui")
end

screenGui.Parent = guiParent

local function ReattachGui()
    if not screenGui or not screenGui.Parent then
        local parent = guiParent

        if not parent or not parent.Parent then
            parent = player:FindFirstChildOfClass("PlayerGui")
        end

        if parent then
            pcall(function()
                screenGui.Parent = parent
            end)
        end
    end

    pcall(function()
        screenGui.Enabled = true
        screenGui.DisplayOrder = 2147483647
        screenGui.IgnoreGuiInset = true
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    end)
end

player.CharacterAdded:Connect(function()
    task.wait(0.15)
    ReattachGui()
end)

task.spawn(function()
    while task.wait(0.75) do
        if not screenGui then
            break
        end
        pcall(ReattachGui)
    end
end)
]]

    if source:find(oldGuiBlock, 1, true) then
        source = source:gsub(oldGuiBlock, newGuiBlock, 1)
    else
        warn("[SOEKKI] UI patch: ScreenGui block not found; source may have changed.")
    end

    -- Name MainFrame so watchdogs can find it.
    source = source:gsub(
        'local mainFrame = Instance%.new%("Frame"%)\n',
        'local mainFrame = Instance.new("Frame")\nmainFrame.Name = "MainFrame"\n',
        1
    )

    -- Never destroy the GUI. Hide it instead.
    local oldUnload = [[
unloadBtn.MouseButton1Click:Connect(function()
    print("[UI] ⚠ Unloading...")
    if _G.GeneratorBoost then
        _G.GeneratorBoost:StopRepair()
    end
    screenGui:Destroy()
    print("[UI] ✅ Unloaded!")
end)
]]

    local newUnload = [[
unloadBtn.Text = "◀ HIDE MENU"

unloadBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    print("[UI] Menu hidden. Press RightShift to show it again.")
end)
]]

    if source:find(oldUnload, 1, true) then
        source = source:gsub(oldUnload, newUnload, 1)
    else
        warn("[SOEKKI] UI patch: unload block not found; source may have changed.")
    end

    -- Remove the second RightShift listener and keep one CAS binding.
    local oldHotkeyTail = [[
ContextActionService:BindActionAtPriority(
	"ToggleMenu",
	function(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.Begin then
			mainFrame.Visible = not mainFrame.Visible
		end
	end,
	false,
	Enum.ContextActionPriority.High.Value,
	Enum.KeyCode.RightShift
)

-- Дополнительный биндинг через UserInputService
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.RightShift then
		mainFrame.Visible = not mainFrame.Visible
	end
end)

print("[SOEKKI] UI loaded! Press RightShift to toggle (works everywhere).")
]]

    local newHotkeyTail = [[
ContextActionService:UnbindAction("ToggleMenu")

ContextActionService:BindActionAtPriority(
    "ToggleMenu",
    function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            mainFrame.Visible = not mainFrame.Visible

            print(
                "[SOEKKI] Menu:",
                mainFrame.Visible and "VISIBLE" or "HIDDEN"
            )
        end

        return Enum.ContextActionResult.Sink
    end,
    false,
    Enum.ContextActionPriority.High.Value,
    Enum.KeyCode.RightShift
)

print("[SOEKKI] UI loaded! Press RightShift to toggle.")
]]

    if source:find(oldHotkeyTail, 1, true) then
        source = source:gsub(oldHotkeyTail, newHotkeyTail, 1)
    else
        warn("[SOEKKI] UI patch: hotkey block not found; source may have changed.")
    end

    if source == original then
        warn("[SOEKKI] UI patch made no changes.")
    end

    return source
end

uiCode = patchUI(uiCode)

local ui, uiErr = loadstring(uiCode)
if not ui then
    error("Compile error in patched main_ui: " .. tostring(uiErr))
end

ok, err = pcall(ui)
if not ok then
    error("Runtime error in patched main_ui: " .. tostring(err))
end
print("[SOEKKI] main_ui loaded with persistent-menu patch!")

-- Do NOT auto-toggle GeneratorBoost here.
-- We will fix its actual repair protocol after the requested logs are available.

-- 5. Watchdog
local function findSOEKKIGui()
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

local function restoreMenu()
    local gui = findSOEKKIGui()

    if gui then
        pcall(function()
            gui.Enabled = true
            gui.DisplayOrder = 2147483647
            gui.IgnoreGuiInset = true
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        end)
        return
    end

    warn("[SOEKKI] ViolenceMenu missing; rebuilding UI...")

    local freshCode = loadModule(BASE_URL .. "main_ui.lua")
    freshCode = patchUI(freshCode)

    local freshUI, freshErr = loadstring(freshCode)
    if not freshUI then
        warn("[SOEKKI] Failed to compile rebuilt UI: " .. tostring(freshErr))
        return
    end

    local rebuildOK, rebuildErr = pcall(freshUI)
    if rebuildOK then
        print("[SOEKKI] ViolenceMenu rebuilt.")
    else
        warn("[SOEKKI] Failed to rebuild menu: " .. tostring(rebuildErr))
    end
end

task.spawn(function()
    while task.wait(0.75) do
        pcall(restoreMenu)
    end
end)

print("[SOEKKI] Persistent menu watchdog enabled!")
print("[SOEKKI] ALL LOADED!")
print("[SOEKKI] Press RightShift to show/hide the menu.")
