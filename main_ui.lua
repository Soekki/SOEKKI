-- main_ui.lua - ПОЛНАЯ ВЕРСИЯ UI ПОВЕРХ ВСЕГО
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
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
	Success = Color3.fromRGB(0, 200, 100),
	Danger = Color3.fromRGB(255, 70, 70),
}

-- ============================================
--   SCREEN GUI (ПОВЕРХ ВСЕГО, НЕ УДАЛЯЕТСЯ)
-- ============================================
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

-- ============================================
--   ГЛАВНЫЙ ФРЕЙМ
-- ============================================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 650, 0, 500)
mainFrame.Position = UDim2.new(0.5, -325, 0.5, -250)
mainFrame.BackgroundColor3 = COLORS.Background
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.ZIndex = 9999
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame



-- ============================================
--   ЗАГОЛОВОК
-- ============================================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = COLORS.Darker
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 10003
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
titleLine.ZIndex = 10004
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
titleLabel.ZIndex = 10005
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
soekkiLabel.ZIndex = 10006
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
closeButton.ZIndex = 10006
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
sidebar.Size = UDim2.new(0, 140, 0, 330)
sidebar.Position = UDim2.new(1, -150, 0.5, -165)
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
local function createToggle(parent, labelText, optionName, customCallback)
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
		
		if customCallback then
			customCallback(newState)
		elseif _G.ToggleESP then
			_G.ToggleESP(optionName)
		end
	end)
	
	-- Загружаем состояние
	task.wait(0.1)
	if not customCallback and _G.GetESPState then
		local state = _G.GetESPState(optionName)
		if state ~= nil then
			updateToggle(state)
		end
	end
	
	return updateToggle, toggleBtn
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
--   ВКЛАДКА VISUAL (ESP)
-- ============================================
local visualTab = tabs["Visual"]
visualTab.Visible = true

local visualLayout = Instance.new("UIListLayout")
visualLayout.Padding = UDim.new(0, 4)
visualLayout.SortOrder = Enum.SortOrder.LayoutOrder
visualLayout.Parent = visualTab

local visualPadding = Instance.new("UIPadding")
visualPadding.PaddingTop = UDim.new(0, 5)
visualPadding.PaddingLeft = UDim.new(0, 5)
visualPadding.PaddingRight = UDim.new(0, 5)
visualPadding.PaddingBottom = UDim.new(0, 10)
visualPadding.Parent = visualTab

visualTab.AutomaticCanvasSize = Enum.AutomaticSize.Y
visualTab.CanvasSize = UDim2.new(0, 0, 0, 0)

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

createToggle(visualTab, "Generators", "ShowGenerators")
createToggle(visualTab, "Gates", "ShowGates")
createToggle(visualTab, "Pallets", "ShowPallets")
createToggle(visualTab, "Windows", "ShowWindows")
createToggle(visualTab, "Hooks", "ShowHooks")
createToggle(visualTab, "Players", "ShowPlayers")
createToggle(visualTab, "Killer Warning", "ShowKillerWarning")

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, 0, 0, 1)
divider.BackgroundColor3 = COLORS.Darker
divider.BackgroundTransparency = 0.5
divider.Parent = visualTab

local miscSpacing = Instance.new("Frame")
miscSpacing.Size = UDim2.new(1, 0, 0, 10)
miscSpacing.BackgroundTransparency = 1
miscSpacing.Parent = visualTab

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
--   ВКЛАДКА MOVEMENT
-- ============================================
local movementTab = tabs["Movement"]

local movLayout = Instance.new("UIListLayout")
movLayout.Padding = UDim.new(0, 4)
movLayout.SortOrder = Enum.SortOrder.LayoutOrder
movLayout.Parent = movementTab

local movPadding = Instance.new("UIPadding")
movPadding.PaddingTop = UDim.new(0, 5)
movPadding.PaddingLeft = UDim.new(0, 5)
movPadding.PaddingRight = UDim.new(0, 5)
movPadding.PaddingBottom = UDim.new(0, 10)
movPadding.Parent = movementTab

movementTab.AutomaticCanvasSize = Enum.AutomaticSize.Y
movementTab.CanvasSize = UDim2.new(0, 0, 0, 0)

local movTitle = Instance.new("TextLabel")
movTitle.Size = UDim2.new(1, 0, 0, 25)
movTitle.BackgroundTransparency = 1
movTitle.Text = "▶ Movement Settings"
movTitle.TextColor3 = COLORS.Accent
movTitle.TextSize = 14
movTitle.Font = Enum.Font.GothamBold
movTitle.TextXAlignment = Enum.TextXAlignment.Left
movTitle.Parent = movementTab

createToggle(movementTab, "Speed Boost", "SpeedBoost")
createToggle(movementTab, "Infinite Lunge", "InfiniteLunge")
createToggle(movementTab, "Noclip (Vaults/Pallets)", "NoclipVaultsPallets")
createToggle(movementTab, "No Stun", "NoStun")
createToggle(movementTab, "Auto Moonwalk", "AutoMoonwalk")

-- ============================================
--   ВКЛАДКА MODIFICATION (АНИМАЦИИ + GENERATOR BOOST)
-- ============================================
local modTab = tabs["Modification"]

local modLayout = Instance.new("UIListLayout")
modLayout.Padding = UDim.new(0, 4)
modLayout.SortOrder = Enum.SortOrder.LayoutOrder
modLayout.Parent = modTab

local modPadding = Instance.new("UIPadding")
modPadding.PaddingTop = UDim.new(0, 5)
modPadding.PaddingLeft = UDim.new(0, 5)
modPadding.PaddingRight = UDim.new(0, 5)
modPadding.PaddingBottom = UDim.new(0, 10)
modPadding.Parent = modTab

modTab.AutomaticCanvasSize = Enum.AutomaticSize.Y
modTab.CanvasSize = UDim2.new(0, 0, 0, 0)

-- Animations
local animTitle = Instance.new("TextLabel")
animTitle.Size = UDim2.new(1, 0, 0, 25)
animTitle.BackgroundTransparency = 1
animTitle.Text = "▶ Animations"
animTitle.TextColor3 = COLORS.Accent
animTitle.TextSize = 14
animTitle.Font = Enum.Font.GothamBold
animTitle.TextXAlignment = Enum.TextXAlignment.Left
animTitle.Parent = modTab

local animationIds = {
    walk = "rbxassetid://121364777933025",
    run = "rbxassetid://88089545021831",
    crouchIdle = "rbxassetid://73650663675588",
    crouchWalk = "rbxassetid://137834747905828",
    injuredIdle = "rbxassetid://137828867671413",
    injuredWalk = "rbxassetid://136695692860739",
    injuredSprint = "rbxassetid://79999409695920",
    injuredCrouchIdle = "rbxassetid://84095653804164",
    injuredCrouchWalk = "rbxassetid://102450923773041",
    hit1 = "rbxassetid://104682704142865",
    hit2 = "rbxassetid://139830743437188",
    knockedIdle = "rbxassetid://74118390445259",
    knockedWalk = "rbxassetid://106618106536124",
    hitFront = "rbxassetid://139830743437188",
    hitBack = "rbxassetid://121845674088602",
    heal = "rbxassetid://110392490296814",
    failheal = "rbxassetid://87055506624885",
    getheal = "rbxassetid://95836365038528",
    leveropen = "rbxassetid://123959675151191",
    leveropeninjured = "rbxassetid://134838390519433",
    GeneratorPoint1 = "rbxassetid://83160743983246",
    GeneratorPoint2 = "rbxassetid://92960319113695",
    GeneratorPoint3 = "rbxassetid://136553272065734",
    GeneratorPoint4 = "rbxassetid://101968088258360",
}

local activeAnimationTrack = nil
local activeAnimationObject = nil

local function stopMenuAnimation()
    if activeAnimationTrack then
        pcall(function() activeAnimationTrack:Stop(0.05) end)
        activeAnimationTrack = nil
    end
    if activeAnimationObject then
        activeAnimationObject:Destroy()
        activeAnimationObject = nil
    end
end

local function playMenuAnimation(animationName)
    local animationId = animationIds[animationName]
    if not animationId then return end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    stopMenuAnimation()

    local animation = Instance.new("Animation")
    animation.Name = "ViolenceMenu_" .. animationName
    animation.AnimationId = animationId

    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)

    if not ok or not track then
        animation:Destroy()
        return
    end

    activeAnimationObject = animation
    activeAnimationTrack = track
    track.Priority = Enum.AnimationPriority.Action
    track.Looped = true
    track:Play(0.1, 1, 1)
end

local function createAnimationButton(parent, name)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 30)
    button.BackgroundColor3 = COLORS.Darker
    button.BackgroundTransparency = 0.15
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = COLORS.Text
    button.TextSize = 13
    button.Font = Enum.Font.Gotham
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = parent

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.Parent = button

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    button.MouseButton1Click:Connect(function()
        playMenuAnimation(name)
    end)
end

local animationOrder = {
    "walk", "run", "crouchIdle", "crouchWalk",
    "injuredIdle", "injuredWalk", "injuredSprint",
    "injuredCrouchIdle", "injuredCrouchWalk",
    "hit1", "hit2", "knockedIdle", "knockedWalk",
    "hitFront", "hitBack", "heal", "failheal", "getheal",
    "leveropen", "leveropeninjured",
    "GeneratorPoint1", "GeneratorPoint2", "GeneratorPoint3", "GeneratorPoint4"
}

for _, animationName in ipairs(animationOrder) do
    createAnimationButton(modTab, animationName)
end

local stopAnimationButton = Instance.new("TextButton")
stopAnimationButton.Size = UDim2.new(1, 0, 0, 30)
stopAnimationButton.BackgroundColor3 = COLORS.ToggleOff
stopAnimationButton.BorderSizePixel = 0
stopAnimationButton.Text = "■  Stop Animation"
stopAnimationButton.TextColor3 = COLORS.Text
stopAnimationButton.TextSize = 13
stopAnimationButton.Font = Enum.Font.GothamBold
stopAnimationButton.Parent = modTab

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 6)
stopCorner.Parent = stopAnimationButton

stopAnimationButton.MouseButton1Click:Connect(stopMenuAnimation)

player.CharacterAdded:Connect(function()
    stopMenuAnimation()
end)

-- Разделитель перед Generator Boost
local genDivider = Instance.new("Frame")
genDivider.Size = UDim2.new(1, 0, 0, 1)
genDivider.BackgroundColor3 = COLORS.Darker
genDivider.BackgroundTransparency = 0.5
genDivider.Parent = modTab

local genSpacing = Instance.new("Frame")
genSpacing.Size = UDim2.new(1, 0, 0, 10)
genSpacing.BackgroundTransparency = 1
genSpacing.Parent = modTab

-- Заголовок Generator Boost
local genBoostTitle = Instance.new("TextLabel")
genBoostTitle.Size = UDim2.new(1, 0, 0, 25)
genBoostTitle.BackgroundTransparency = 1
genBoostTitle.Text = "▶ Generator Boost"
genBoostTitle.TextColor3 = COLORS.Accent
genBoostTitle.TextSize = 14
genBoostTitle.Font = Enum.Font.GothamBold
genBoostTitle.TextXAlignment = Enum.TextXAlignment.Left
genBoostTitle.Parent = modTab

local genBoostDesc = Instance.new("TextLabel")
genBoostDesc.Size = UDim2.new(1, 0, 0, 20)
genBoostDesc.BackgroundTransparency = 1
genBoostDesc.Text = "Ускоряет ремонт генераторов через RepairEvent"
genBoostDesc.TextColor3 = COLORS.TextDim
genBoostDesc.TextSize = 11
genBoostDesc.Font = Enum.Font.Gotham
genBoostDesc.TextXAlignment = Enum.TextXAlignment.Left
genBoostDesc.Parent = modTab

local genBoostSpacing = Instance.new("Frame")
genBoostSpacing.Size = UDim2.new(1, 0, 0, 5)
genBoostSpacing.BackgroundTransparency = 1
genBoostSpacing.Parent = modTab

-- Toggle для Generator Boost
local genToggleContainer = Instance.new("Frame")
genToggleContainer.Size = UDim2.new(1, 0, 0, 30)
genToggleContainer.BackgroundTransparency = 1
genToggleContainer.Parent = modTab

local genToggleLabel = Instance.new("TextLabel")
genToggleLabel.Size = UDim2.new(1, -50, 1, 0)
genToggleLabel.BackgroundTransparency = 1
genToggleLabel.Text = "Enable Repair Boost"
genToggleLabel.TextColor3 = COLORS.Text
genToggleLabel.TextSize = 13
genToggleLabel.Font = Enum.Font.Gotham
genToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
genToggleLabel.Parent = genToggleContainer

local genToggleBtn = Instance.new("TextButton")
genToggleBtn.Size = UDim2.new(0, 40, 0, 22)
genToggleBtn.Position = UDim2.new(1, -45, 0.5, -11)
genToggleBtn.BackgroundColor3 = COLORS.ToggleOff
genToggleBtn.Text = ""
genToggleBtn.BorderSizePixel = 0
genToggleBtn.Parent = genToggleContainer

local genToggleCorner = Instance.new("UICorner")
genToggleCorner.CornerRadius = UDim.new(0, 11)
genToggleCorner.Parent = genToggleBtn

local genToggleDot = Instance.new("Frame")
genToggleDot.Size = UDim2.new(0, 16, 0, 16)
genToggleDot.Position = UDim2.new(0, 3, 0.5, -8)
genToggleDot.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
genToggleDot.BorderSizePixel = 0
genToggleDot.Parent = genToggleBtn

local genDotCorner = Instance.new("UICorner")
genDotCorner.CornerRadius = UDim.new(0, 8)
genDotCorner.Parent = genToggleDot

local genBoostEnabled = false

local function updateGenToggle(state)
    genBoostEnabled = state
    if state then
        genToggleBtn.BackgroundColor3 = COLORS.ToggleOn
        genToggleDot.Position = UDim2.new(0, 21, 0.5, -8)
        genToggleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        genToggleLabel.Text = "Enable Repair Boost ✅"
        genToggleLabel.TextColor3 = COLORS.Success
    else
        genToggleBtn.BackgroundColor3 = COLORS.ToggleOff
        genToggleDot.Position = UDim2.new(0, 3, 0.5, -8)
        genToggleDot.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        genToggleLabel.Text = "Enable Repair Boost"
        genToggleLabel.TextColor3 = COLORS.Text
    end
end

genToggleBtn.MouseButton1Click:Connect(function()
    local newState = not genBoostEnabled
    updateGenToggle(newState)
    
    if _G.GeneratorBoost then
        if newState then
            _G.GeneratorBoost.Enabled = true
            _G.GeneratorBoost:Toggle()
            print("[UI] 🟢 Generator Boost ENABLED!")
        else
            _G.GeneratorBoost.Enabled = false
            _G.GeneratorBoost:Toggle()
            print("[UI] 🔴 Generator Boost DISABLED!")
        end
    else
        warn("[UI] ❌ GeneratorBoost not loaded!")
    end
end)

-- Кнопка "Repair Nearest Generator"
local repairNearestBtn = Instance.new("TextButton")
repairNearestBtn.Size = UDim2.new(1, 0, 0, 30)
repairNearestBtn.BackgroundColor3 = COLORS.Darker
repairNearestBtn.BackgroundTransparency = 0.15
repairNearestBtn.BorderSizePixel = 0
repairNearestBtn.Text = "⚡ Repair Nearest Generator"
repairNearestBtn.TextColor3 = COLORS.Text
repairNearestBtn.TextSize = 13
repairNearestBtn.Font = Enum.Font.GothamBold
repairNearestBtn.TextXAlignment = Enum.TextXAlignment.Center
repairNearestBtn.Parent = modTab

local repairNearestCorner = Instance.new("UICorner")
repairNearestCorner.CornerRadius = UDim.new(0, 6)
repairNearestCorner.Parent = repairNearestBtn

repairNearestBtn.MouseButton1Click:Connect(function()
    if _G.GeneratorBoost then
        local nearest, dist = _G.GeneratorBoost:GetNearestGenerator()
        if nearest then
            print("[UI] 🔧 Starting repair on nearest generator (distance: " .. tostring(dist) .. ")")
            _G.GeneratorBoost:StartRepairOnTarget(nearest)
        else
            print("[UI] ⚠️ No generators found nearby!")
        end
    else
        print("[UI] ❌ GeneratorBoost not loaded!")
    end
end)

-- Кнопка "Stop Repair"
local stopRepairBtn = Instance.new("TextButton")
stopRepairBtn.Size = UDim2.new(1, 0, 0, 30)
stopRepairBtn.BackgroundColor3 = COLORS.ToggleOff
stopRepairBtn.BackgroundTransparency = 0.2
stopRepairBtn.BorderSizePixel = 0
stopRepairBtn.Text = "⏹ Stop Repair"
stopRepairBtn.TextColor3 = COLORS.Text
stopRepairBtn.TextSize = 13
stopRepairBtn.Font = Enum.Font.GothamBold
stopRepairBtn.TextXAlignment = Enum.TextXAlignment.Center
stopRepairBtn.Parent = modTab

local stopRepairCorner = Instance.new("UICorner")
stopRepairCorner.CornerRadius = UDim.new(0, 6)
stopRepairCorner.Parent = stopRepairBtn

stopRepairBtn.MouseButton1Click:Connect(function()
    if _G.GeneratorBoost then
        _G.GeneratorBoost:StopRepair()
        print("[UI] ⏹ Repair stopped!")
    end
end)

-- Индикатор статуса
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = COLORS.TextDim
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = modTab

local function updateStatus()
    if _G.GeneratorBoost and _G.GeneratorBoost.IsRepairing then
        statusLabel.Text = "Status: ⚡ Repairing..."
        statusLabel.TextColor3 = COLORS.Success
    else
        statusLabel.Text = "Status: Idle"
        statusLabel.TextColor3 = COLORS.TextDim
    end
end

game:GetService("RunService").Heartbeat:Connect(function()
    if mainFrame.Visible then
        updateStatus()
    end
end)

-- ============================================
--   ВКЛАДКА COMBAT
-- ============================================
local combatTab = tabs["Combat"]

local combatLayout = Instance.new("UIListLayout")
combatLayout.Padding = UDim.new(0, 4)
combatLayout.SortOrder = Enum.SortOrder.LayoutOrder
combatLayout.Parent = combatTab

local combatPadding = Instance.new("UIPadding")
combatPadding.PaddingTop = UDim.new(0, 5)
combatPadding.PaddingLeft = UDim.new(0, 5)
combatPadding.PaddingRight = UDim.new(0, 5)
combatPadding.PaddingBottom = UDim.new(0, 10)
combatPadding.Parent = combatTab

combatTab.AutomaticCanvasSize = Enum.AutomaticSize.Y
combatTab.CanvasSize = UDim2.new(0, 0, 0, 0)

local combatTitle = Instance.new("TextLabel")
combatTitle.Size = UDim2.new(1, 0, 0, 25)
combatTitle.BackgroundTransparency = 1
combatTitle.Text = "▶ Combat Settings"
combatTitle.TextColor3 = COLORS.Accent
combatTitle.TextSize = 14
combatTitle.Font = Enum.Font.GothamBold
combatTitle.TextXAlignment = Enum.TextXAlignment.Left
combatTitle.Parent = combatTab

createToggle(combatTab, "Auto Parry", "AutoParry")
createToggle(combatTab, "Auto Skill Check", "AutoSkillCheck")
createToggle(combatTab, "Instant Skill Check", "InstantSkillCheck")
createToggle(combatTab, "No Skill Checks", "NoSkillChecks")
createToggle(combatTab, "Anti Wiggle", "AntiWiggle")
createToggle(combatTab, "Auto Self Unhook", "AutoSelfUnhook")

-- ============================================
--   ВКЛАДКА PLAYER
-- ============================================
local playerTab = tabs["Player"]

local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 4)
playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerLayout.Parent = playerTab

local playerPadding = Instance.new("UIPadding")
playerPadding.PaddingTop = UDim.new(0, 5)
playerPadding.PaddingLeft = UDim.new(0, 5)
playerPadding.PaddingRight = UDim.new(0, 5)
playerPadding.PaddingBottom = UDim.new(0, 10)
playerPadding.Parent = playerTab

playerTab.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerTab.CanvasSize = UDim2.new(0, 0, 0, 0)

local playerTitle = Instance.new("TextLabel")
playerTitle.Size = UDim2.new(1, 0, 0, 25)
playerTitle.BackgroundTransparency = 1
playerTitle.Text = "▶ Player Settings"
playerTitle.TextColor3 = COLORS.Accent
playerTitle.TextSize = 14
playerTitle.Font = Enum.Font.GothamBold
playerTitle.TextXAlignment = Enum.TextXAlignment.Left
playerTitle.Parent = playerTab

createToggle(playerTab, "Infinite Flashlight", "InfiniteFlashlight")
createToggle(playerTab, "Rainbow Character", "RainbowCharacter")
createToggle(playerTab, "Walk While Emoting", "WalkWhileEmoting")

-- ============================================
--   ВКЛАДКА MISC
-- ============================================
local miscTab = tabs["Misc"]

local miscLayout = Instance.new("UIListLayout")
miscLayout.Padding = UDim.new(0, 4)
miscLayout.SortOrder = Enum.SortOrder.LayoutOrder
miscLayout.Parent = miscTab

local miscPadding = Instance.new("UIPadding")
miscPadding.PaddingTop = UDim.new(0, 5)
miscPadding.PaddingLeft = UDim.new(0, 5)
miscPadding.PaddingRight = UDim.new(0, 5)
miscPadding.PaddingBottom = UDim.new(0, 10)
miscPadding.Parent = miscTab

miscTab.AutomaticCanvasSize = Enum.AutomaticSize.Y
miscTab.CanvasSize = UDim2.new(0, 0, 0, 0)

local miscTitle = Instance.new("TextLabel")
miscTitle.Size = UDim2.new(1, 0, 0, 25)
miscTitle.BackgroundTransparency = 1
miscTitle.Text = "▶ Misc Settings"
miscTitle.TextColor3 = COLORS.Accent
miscTitle.TextSize = 14
miscTitle.Font = Enum.Font.GothamBold
miscTitle.TextXAlignment = Enum.TextXAlignment.Left
miscTitle.Parent = miscTab

createToggle(miscTab, "Show Info Banner", "ShowInfoBanner")
createToggle(miscTab, "Show Spectator List", "ShowSpectatorList")
createToggle(miscTab, "Show Hotkey Overlay", "ShowHotkeyOverlay")
createToggle(miscTab, "Hide Flowstate UI", "HideFlowstateUI")
createToggle(miscTab, "Hide Parry UI", "HideParryUI")

-- ============================================
--   ВКЛАДКА SETTINGS
-- ============================================
local settingsTab = tabs["Settings"]

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.Padding = UDim.new(0, 4)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Parent = settingsTab

local settingsPadding = Instance.new("UIPadding")
settingsPadding.PaddingTop = UDim.new(0, 5)
settingsPadding.PaddingLeft = UDim.new(0, 5)
settingsPadding.PaddingRight = UDim.new(0, 5)
settingsPadding.PaddingBottom = UDim.new(0, 10)
settingsPadding.Parent = settingsTab

settingsTab.AutomaticCanvasSize = Enum.AutomaticSize.Y
settingsTab.CanvasSize = UDim2.new(0, 0, 0, 0)

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Size = UDim2.new(1, 0, 0, 25)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "▶ Settings"
settingsTitle.TextColor3 = COLORS.Accent
settingsTitle.TextSize = 14
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.Parent = settingsTab

-- Кнопка Unload
local unloadBtn = Instance.new("TextButton")
unloadBtn.Size = UDim2.new(1, 0, 0, 35)
unloadBtn.BackgroundColor3 = COLORS.Danger
unloadBtn.BackgroundTransparency = 0.2
unloadBtn.BorderSizePixel = 0
unloadBtn.Text = "⚠ UNLOAD SCRIPT"
unloadBtn.TextColor3 = COLORS.Danger
unloadBtn.TextSize = 14
unloadBtn.Font = Enum.Font.GothamBold
unloadBtn.Parent = settingsTab

local unloadCorner = Instance.new("UICorner")
unloadCorner.CornerRadius = UDim.new(0, 6)
unloadCorner.Parent = unloadBtn

unloadBtn.MouseButton1Click:Connect(function()
    print("[UI] ⚠ Unloading...")
    if _G.GeneratorBoost then
        _G.GeneratorBoost:StopRepair()
    end
    screenGui:Destroy()
    print("[UI] ✅ Unloaded!")
end)

unloadBtn.MouseEnter:Connect(function()
    unloadBtn.BackgroundTransparency = 0.1
end)

unloadBtn.MouseLeave:Connect(function()
    unloadBtn.BackgroundTransparency = 0.2
end)

-- Информация
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 40)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "SOEKKI v1.0.0\nPress RightShift to toggle menu"
infoLabel.TextColor3 = COLORS.TextDim
infoLabel.TextSize = 11
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.TextYAlignment = Enum.TextYAlignment.Center
infoLabel.Parent = settingsTab

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
--   ХОТКЕЙ (РАБОТАЕТ ПОВЕРХ ВСЕГО)
-- ============================================
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