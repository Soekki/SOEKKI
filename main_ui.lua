-- main_ui.lua - ВСЕ ВКЛАДКИ + ВСЕ КНОПКИ ESP
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- ============================================
--   ЦВЕТА
-- ============================================
local COLORS = {
	Background = Color3.fromRGB(20, 20, 25),
	Darker = Color3.fromRGB(28, 28, 35),
	Accent = Color3.fromRGB(120, 80, 200),
	Text = Color3.fromRGB(235, 235, 245),
	TextDim = Color3.fromRGB(140, 140, 155),
	ToggleOff = Color3.fromRGB(45, 45, 55),
	ToggleOn = Color3.fromRGB(120, 80, 200),
	TabActive = Color3.fromRGB(40, 40, 50),
	TabInactive = Color3.fromRGB(25, 25, 32),
}

-- ============================================
--   SCREEN GUI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ViolenceMenu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- ============================================
--   ГЛАВНЫЙ ФРЕЙМ
-- ============================================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 600, 0, 450)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
mainFrame.BackgroundColor3 = COLORS.Background
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.ZIndex = 1000
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local accentBorder = Instance.new("Frame")
accentBorder.Size = UDim2.new(1, 0, 1, 0)
accentBorder.BackgroundColor3 = COLORS.Accent
accentBorder.BackgroundTransparency = 0.85
accentBorder.BorderSizePixel = 2
accentBorder.BorderColor3 = COLORS.Accent
accentBorder.ZIndex = 1002
accentBorder.Parent = mainFrame

local accentCorner = Instance.new("UICorner")
accentCorner.CornerRadius = UDim.new(0, 12)
accentCorner.Parent = accentBorder

-- ============================================
--   ЗАГОЛОВОК
-- ============================================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = COLORS.Darker
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 1003
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLine = Instance.new("Frame")
titleLine.Size = UDim2.new(1, 0, 0, 1.5)
titleLine.Position = UDim2.new(0, 0, 1, 0)
titleLine.BackgroundColor3 = COLORS.Accent
titleLine.BackgroundTransparency = 0.3
titleLine.BorderSizePixel = 0
titleLine.ZIndex = 1004
titleLine.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "◆ VIOLENCE DISTRICT v1.0.0"
titleLabel.TextColor3 = COLORS.Text
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 1005
titleLabel.Parent = titleBar

local soekkiLabel = Instance.new("TextLabel")
soekkiLabel.Size = UDim2.new(1, -50, 1, 0)
soekkiLabel.Position = UDim2.new(0, 15, 0, 0)
soekkiLabel.BackgroundTransparency = 1
soekkiLabel.Text = "SOEKKI"
soekkiLabel.TextColor3 = COLORS.Accent
soekkiLabel.TextSize = 14
soekkiLabel.Font = Enum.Font.GothamBold
soekkiLabel.TextXAlignment = Enum.TextXAlignment.Right
soekkiLabel.ZIndex = 1006
soekkiLabel.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -32, 0, 5)
closeButton.BackgroundColor3 = COLORS.Darker
closeButton.BackgroundTransparency = 0.5
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.TextDim
closeButton.TextSize = 12
closeButton.Font = Enum.Font.GothamBold
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 1006
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

closeButton.MouseEnter:Connect(function()
	closeButton.BackgroundColor3 = COLORS.Accent
	closeButton.BackgroundTransparency = 0.3
	closeButton.TextColor3 = COLORS.Text
end)

closeButton.MouseLeave:Connect(function()
	closeButton.BackgroundColor3 = COLORS.Darker
	closeButton.BackgroundTransparency = 0.5
	closeButton.TextColor3 = COLORS.TextDim
end)

-- ============================================
--   ПЕРЕТАСКИВАНИЕ
-- ============================================
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)

titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- ============================================
--   ОБЛАСТЬ КОНТЕНТА
-- ============================================
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -140, 1, -35)
contentArea.Position = UDim2.new(0, 0, 0, 35)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.ZIndex = 1003
contentArea.Parent = mainFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 15)
contentPadding.PaddingLeft = UDim.new(0, 15)
contentPadding.PaddingRight = UDim.new(0, 15)
contentPadding.PaddingBottom = UDim.new(0, 15)
contentPadding.Parent = contentArea

-- ============================================
--   БОКОВАЯ ПАНЕЛЬ
-- ============================================
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 140, 0, 280)
sidebar.Position = UDim2.new(1, -150, 0.5, -140)
sidebar.BackgroundColor3 = COLORS.Darker
sidebar.BackgroundTransparency = 0.2
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 1003
sidebar.Parent = mainFrame

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 12)
sidebarCorner.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 4)
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebar

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0, 12)
sidebarPadding.PaddingLeft = UDim.new(0, 8)
sidebarPadding.PaddingRight = UDim.new(0, 8)
sidebarPadding.PaddingBottom = UDim.new(0, 12)
sidebarPadding.Parent = sidebar

-- ============================================
--   СИСТЕМА ВКЛАДОК
-- ============================================
local tabs = {}
local tabButtons = {}
local activeTab = nil

local function createTab(name, icon)
	local tabBtn = Instance.new("TextButton")
	tabBtn.Size = UDim2.new(1, 0, 0, 32)
	tabBtn.BackgroundColor3 = COLORS.TabInactive
	tabBtn.BackgroundTransparency = 0
	tabBtn.Text = icon .. "  " .. name
	tabBtn.TextColor3 = COLORS.TextDim
	tabBtn.TextSize = 12
	tabBtn.Font = Enum.Font.Gotham
	tabBtn.TextXAlignment = Enum.TextXAlignment.Left
	tabBtn.BorderSizePixel = 0
	tabBtn.ZIndex = 1004
	tabBtn.Parent = sidebar

	local tabBtnCorner = Instance.new("UICorner")
	tabBtnCorner.CornerRadius = UDim.new(0, 6)
	tabBtnCorner.Parent = tabBtn

	local tabBtnPadding = Instance.new("UIPadding")
	tabBtnPadding.PaddingLeft = UDim.new(0, 10)
	tabBtnPadding.Parent = tabBtn

	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Size = UDim2.new(1, 0, 1, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 3
	contentFrame.ScrollBarImageColor3 = COLORS.Accent
	contentFrame.Visible = false
	contentFrame.ZIndex = 1004
	contentFrame.Parent = contentArea

	local function selectTab()
		for _, btn in pairs(tabButtons) do
			btn.BackgroundColor3 = COLORS.TabInactive
			btn.TextColor3 = COLORS.TextDim
		end
		for _, frame in pairs(tabs) do
			frame.Visible = false
		end
		tabBtn.BackgroundColor3 = COLORS.TabActive
		tabBtn.TextColor3 = COLORS.Text
		contentFrame.Visible = true
		activeTab = name
	end

	tabBtn.MouseButton1Click:Connect(selectTab)
	tabBtn.MouseEnter:Connect(function()
		if activeTab ~= name then
			tabBtn.BackgroundColor3 = COLORS.TabInactive
			tabBtn.BackgroundTransparency = 0.3
		end
	end)
	tabBtn.MouseLeave:Connect(function()
		if activeTab ~= name then
			tabBtn.BackgroundColor3 = COLORS.TabInactive
			tabBtn.BackgroundTransparency = 0
		end
	end)

	table.insert(tabButtons, tabBtn)
	tabs[name] = contentFrame

	return contentFrame
end

-- ============================================
--   СОЗДАНИЕ TOGGLE
-- ============================================
local function createToggle(parent, labelText, optionName)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 30)
	container.BackgroundTransparency = 1
	container.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = COLORS.Text
	label.TextSize = 13
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 40, 0, 22)
	toggleBtn.Position = UDim2.new(1, -45, 0.5, -11)
	toggleBtn.BackgroundColor3 = COLORS.ToggleOff
	toggleBtn.Text = ""
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Parent = container
	
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 11)
	toggleCorner.Parent = toggleBtn
	
	local toggleDot = Instance.new("Frame")
	toggleDot.Size = UDim2.new(0, 16, 0, 16)
	toggleDot.Position = UDim2.new(0, 3, 0.5, -8)
	toggleDot.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	toggleDot.BorderSizePixel = 0
	toggleDot.Parent = toggleBtn
	
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(0, 8)
	dotCorner.Parent = toggleDot
	
	local isOn = false
	
	local function updateToggle(state)
		isOn = state
		if isOn then
			toggleBtn.BackgroundColor3 = COLORS.ToggleOn
			toggleDot.Position = UDim2.new(0, 21, 0.5, -8)
			toggleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		else
			toggleBtn.BackgroundColor3 = COLORS.ToggleOff
			toggleDot.Position = UDim2.new(0, 3, 0.5, -8)
			toggleDot.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		end
	end
	
	toggleBtn.MouseButton1Click:Connect(function()
		local newState = not isOn
		updateToggle(newState)
		
		if _G.ToggleESP then
			_G.ToggleESP(optionName)
		end
	end)
	
	-- Загружаем состояние
	task.wait(0.1)
	if _G.GetESPState then
		local state = _G.GetESPState(optionName)
		if state ~= nil then
			updateToggle(state)
		end
	end
	
	return updateToggle
end

-- ============================================
--   СОЗДАНИЕ ВСЕХ ВКЛАДОК
-- ============================================
createTab("Visual", "👁️")
createTab("Movement", "🚀")
createTab("Modification", "🛠️")
createTab("Combat", "🔪")
createTab("Player", "👤")
createTab("Misc", "⚙")
createTab("Settings", "🔧")

-- ============================================
--   НАПОЛНЕНИЕ ВКЛАДКИ VISUAL (ВСЕ КНОПКИ ESP)
-- ============================================
local visualTab = tabs["Visual"]
visualTab.Visible = true

-- Заголовок ESP
local sectionLabel = Instance.new("TextLabel")
sectionLabel.Size = UDim2.new(1, 0, 0, 25)
sectionLabel.BackgroundTransparency = 1
sectionLabel.Text = "▶ ESP Settings"
sectionLabel.TextColor3 = COLORS.Accent
sectionLabel.TextSize = 14
sectionLabel.Font = Enum.Font.GothamBold
sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
sectionLabel.Parent = visualTab

local espSpacing = Instance.new("Frame")
espSpacing.Size = UDim2.new(1, 0, 0, 5)
espSpacing.BackgroundTransparency = 1
espSpacing.Parent = visualTab

-- ВСЕ КНОПКИ ESP
createToggle(visualTab, "Generators", "ShowGenerators")
createToggle(visualTab, "Gates", "ShowGates")
createToggle(visualTab, "Pallets", "ShowPallets")
createToggle(visualTab, "Windows", "ShowWindows")
createToggle(visualTab, "Hooks", "ShowHooks")
createToggle(visualTab, "Players", "ShowPlayers")
createToggle(visualTab, "Killer Warning", "ShowKillerWarning")

-- Разделитель
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, 0, 0, 1)
divider.BackgroundColor3 = COLORS.Darker
divider.BackgroundTransparency = 0.5
divider.Parent = visualTab

local miscSpacing = Instance.new("Frame")
miscSpacing.Size = UDim2.new(1, 0, 0, 10)
miscSpacing.BackgroundTransparency = 1
miscSpacing.Parent = visualTab

-- Заголовок Misc
local sectionLabel2 = Instance.new("TextLabel")
sectionLabel2.Size = UDim2.new(1, 0, 0, 25)
sectionLabel2.BackgroundTransparency = 1
sectionLabel2.Text = "▶ Misc Settings"
sectionLabel2.TextColor3 = COLORS.Accent
sectionLabel2.TextSize = 14
sectionLabel2.Font = Enum.Font.GothamBold
sectionLabel2.TextXAlignment = Enum.TextXAlignment.Left
sectionLabel2.Parent = visualTab

local miscSpacing2 = Instance.new("Frame")
miscSpacing2.Size = UDim2.new(1, 0, 0, 5)
miscSpacing2.BackgroundTransparency = 1
miscSpacing2.Parent = visualTab

createToggle(visualTab, "Full Bright", "FullBright")

-- ============================================
--   ДРУГИЕ ВКЛАДКИ (ПУСТЫЕ, ДЛЯ БУДУЩИХ ФУНКЦИЙ)
-- ============================================
-- Movement
local movementTab = tabs["Movement"]
local movLabel = Instance.new("TextLabel")
movLabel.Size = UDim2.new(1, 0, 0, 30)
movLabel.BackgroundTransparency = 1
movLabel.Text = "🚀 Movement options coming soon..."
movLabel.TextColor3 = COLORS.TextDim
movLabel.TextSize = 14
movLabel.Font = Enum.Font.Gotham
movLabel.TextXAlignment = Enum.TextXAlignment.Center
movLabel.Parent = movementTab

-- Modification
local modTab = tabs["Modification"]
local modLabel = Instance.new("TextLabel")
modLabel.Size = UDim2.new(1, 0, 0, 30)
modLabel.BackgroundTransparency = 1
modLabel.Text = "🛠️ Modification options coming soon..."
modLabel.TextColor3 = COLORS.TextDim
modLabel.TextSize = 14
modLabel.Font = Enum.Font.Gotham
modLabel.TextXAlignment = Enum.TextXAlignment.Center
modLabel.Parent = modTab

-- Combat
local combatTab = tabs["Combat"]
local combatLabel = Instance.new("TextLabel")
combatLabel.Size = UDim2.new(1, 0, 0, 30)
combatLabel.BackgroundTransparency = 1
combatLabel.Text = "🔪 Combat options coming soon..."
combatLabel.TextColor3 = COLORS.TextDim
combatLabel.TextSize = 14
combatLabel.Font = Enum.Font.Gotham
combatLabel.TextXAlignment = Enum.TextXAlignment.Center
combatLabel.Parent = combatTab

-- Player
local playerTab = tabs["Player"]
local playerLabel = Instance.new("TextLabel")
playerLabel.Size = UDim2.new(1, 0, 0, 30)
playerLabel.BackgroundTransparency = 1
playerLabel.Text = "👤 Player options coming soon..."
playerLabel.TextColor3 = COLORS.TextDim
playerLabel.TextSize = 14
playerLabel.Font = Enum.Font.Gotham
playerLabel.TextXAlignment = Enum.TextXAlignment.Center
playerLabel.Parent = playerTab

-- Misc
local miscTab = tabs["Misc"]
local miscLabel = Instance.new("TextLabel")
miscLabel.Size = UDim2.new(1, 0, 0, 30)
miscLabel.BackgroundTransparency = 1
miscLabel.Text = "⚙ Misc options coming soon..."
miscLabel.TextColor3 = COLORS.TextDim
miscLabel.TextSize = 14
miscLabel.Font = Enum.Font.Gotham
miscLabel.TextXAlignment = Enum.TextXAlignment.Center
miscLabel.Parent = miscTab

-- Settings
local settingsTab = tabs["Settings"]
local settingsLabel = Instance.new("TextLabel")
settingsLabel.Size = UDim2.new(1, 0, 0, 30)
settingsLabel.BackgroundTransparency = 1
settingsLabel.Text = "🔧 Settings options coming soon..."
settingsLabel.TextColor3 = COLORS.TextDim
settingsLabel.TextSize = 14
settingsLabel.Font = Enum.Font.Gotham
settingsLabel.TextXAlignment = Enum.TextXAlignment.Center
settingsLabel.Parent = settingsTab

-- ============================================
--   АКТИВАЦИЯ ПЕРВОЙ ВКЛАДКИ
-- ============================================
if #tabButtons > 0 then
	tabButtons[1].BackgroundColor3 = COLORS.TabActive
	tabButtons[1].TextColor3 = COLORS.Text
	for name, frame in pairs(tabs) do
		frame.Visible = (name == "Visual")
	end
	activeTab = "Visual"
end

-- ============================================
--   ХОТКЕЙ
-- ============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
		mainFrame.Visible = not mainFrame.Visible
	end
end)

print("[SOEKKI] UI loaded! Press RightShift to toggle.")