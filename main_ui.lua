-- main_ui.lua - ВСЕ ВКЛАДКИ + ESP + БАФФ ГЕНЕРАТОРОВ + АНИМАЦИИ
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
	InputBg = Color3.fromRGB(35, 35, 45),
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

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = COLORS.Darker
header.Text = "SOEKKI - Violence District"
header.TextColor3 = COLORS.Text
header.TextSize = 18
header.Font = Enum.Font.GothamBold
header.Parent = mainFrame

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 36)
tabBar.Position = UDim2.new(0, 0, 0, 40)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local pageContainer = Instance.new("Frame")
pageContainer.Size = UDim2.new(1, 0, 1, -76)
pageContainer.Position = UDim2.new(0, 0, 0, 76)
pageContainer.BackgroundTransparency = 1
pageContainer.Parent = mainFrame

-- ============================================
--   СОЗДАНИЕ ВКЛАДОК
-- ============================================
local tabNames = { "Visual", "Modification", "Movement", "Combat", "Player", "Misc", "Settings" }
local tabButtons = {}
local tabs = {}

for i, name in ipairs(tabNames) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1 / #tabNames, 0, 1, 0)
	btn.Position = UDim2.new((i - 1) / #tabNames, 0, 0, 0)
	btn.BackgroundColor3 = COLORS.TabInactive
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.TextColor3 = COLORS.TextDim
	btn.TextSize = 12
	btn.Font = Enum.Font.Gotham
	btn.Parent = tabBar
	tabButtons[i] = btn

	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundColor3 = COLORS.Background
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 6
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.Visible = false
	page.Parent = pageContainer

	tabs[name] = page
end

local activeTab = "Visual"
local function selectTab(name)
	activeTab = name
	for i, btn in ipairs(tabButtons) do
		local isActive = (tabNames[i] == name)
		btn.BackgroundColor3 = isActive and COLORS.TabActive or COLORS.TabInactive
		btn.TextColor3 = isActive and COLORS.Text or COLORS.TextDim
		tabs[tabNames[i]].Visible = isActive
	end
end

for i, btn in ipairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		selectTab(tabNames[i])
	end)
end

-- ============================================
--   СОЗДАНИЕ ТУМБЛЕРА (с кружком)
-- ============================================
local function createToggle(parent, labelText, optionName)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -60, 1, 0)
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
		updateToggle(not isOn)
		if _G.SetESPState then
			_G.SetESPState(optionName, isOn)
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
--   ТУМБЛЕР БАФФА ГЕНЕРАТОРОВ
-- ============================================
local function createBoostToggle(parent, labelText)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -60, 1, 0)
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
		updateToggle(not isOn)
		if _G.SetGeneratorBoostEnabled then
			_G.SetGeneratorBoostEnabled(isOn)
		end
	end)

	task.wait(0.1)
	if _G.GetGeneratorBoostEnabled then
		local state = _G.GetGeneratorBoostEnabled()
		if state ~= nil then
			updateToggle(state)
		end
	end

	return updateToggle
end

-- ============================================
--   ПОЛЕ ВВОДА (ПРОЦЕНТ БАФФА)
-- ============================================
local function createInput(parent, labelText, getter, setter)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -100, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = COLORS.Text
	label.TextSize = 13
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local inputBox = Instance.new("TextBox")
	inputBox.Size = UDim2.new(0, 80, 0, 28)
	inputBox.Position = UDim2.new(1, -80, 0, 0)
	inputBox.BackgroundColor3 = COLORS.InputBg
	inputBox.BorderSizePixel = 0
	inputBox.Text = "50"
	inputBox.TextColor3 = COLORS.Text
	inputBox.TextSize = 13
	inputBox.Font = Enum.Font.GothamBold
	inputBox.TextXAlignment = Enum.TextXAlignment.Center
	inputBox.PlaceholderText = "0-100"
	inputBox.Parent = container

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 6)
	inputCorner.Parent = inputBox

	local suffixLabel = Instance.new("TextLabel")
	suffixLabel.Size = UDim2.new(0, 15, 0, 20)
	suffixLabel.Position = UDim2.new(1, 0, 0, 0)
	suffixLabel.BackgroundTransparency = 1
	suffixLabel.Text = "%"
	suffixLabel.TextColor3 = COLORS.Accent
	suffixLabel.TextSize = 13
	suffixLabel.Font = Enum.Font.GothamBold
	suffixLabel.TextXAlignment = Enum.TextXAlignment.Left
	suffixLabel.Parent = container

	-- Загружаем начальное значение
	task.wait(0.1)
	if getter then
		local initialValue = getter()
		if initialValue ~= nil then
			inputBox.Text = tostring(math.floor(initialValue))
		end
	end

	inputBox.FocusLost:Connect(function(enterPressed)
		local num = tonumber(inputBox.Text)
		if num then
			num = math.clamp(math.floor(num), 0, 100)
			inputBox.Text = tostring(num)
			if setter then
				setter(num)
			end
		else
			if getter then
				local currentValue = getter()
				if currentValue ~= nil then
					inputBox.Text = tostring(math.floor(currentValue))
				else
					inputBox.Text = "50"
				end
			end
		end
	end)

	-- Обновляем значение при изменении через другие методы
	local updateConnection
	updateConnection = game:GetService("RunService").Heartbeat:Connect(function()
		if not container.Parent then
			if updateConnection then updateConnection:Disconnect() end
			return
		end
		if getter then
			local currentValue = getter()
			if currentValue ~= nil then
				local currentText = tonumber(inputBox.Text)
				if currentText ~= currentValue then
					inputBox.Text = tostring(math.floor(currentValue))
				end
			end
		end
	end)

	return inputBox
end

-- ============================================
--   НАПОЛНЕНИЕ ВКЛАДКИ VISUAL
-- ============================================
local visualTab = tabs["Visual"]
visualTab.Visible = true

local sectionLabel = Instance.new("TextLabel")
sectionLabel.Size = UDim2.new(1, 0, 0, 25)
sectionLabel.BackgroundTransparency = 1
sectionLabel.Text = "▶ ESP Settings"
sectionLabel.TextColor3 = COLORS.Accent
sectionLabel.TextSize = 14
sectionLabel.Font = Enum.Font.GothamBold
sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
sectionLabel.Parent = visualTab

createToggle(visualTab, "Show Generators", "ShowGenerators")
createToggle(visualTab, "Show Gates", "ShowGates")
createToggle(visualTab, "Show Pallets", "ShowPallets")
createToggle(visualTab, "Show Windows", "ShowWindows")
createToggle(visualTab, "Show Hooks", "ShowHooks")
createToggle(visualTab, "Show Players", "ShowPlayers")
createToggle(visualTab, "Killer Warning", "ShowKillerWarning")

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, 0, 0, 1)
divider.BackgroundColor3 = COLORS.Darker
divider.BackgroundTransparency = 0.5
divider.Parent = visualTab

local sectionLabel2 = Instance.new("TextLabel")
sectionLabel2.Size = UDim2.new(1, 0, 0, 25)
sectionLabel2.BackgroundTransparency = 1
sectionLabel2.Text = "▶ Misc Settings"
sectionLabel2.TextColor3 = COLORS.Accent
sectionLabel2.TextSize = 14
sectionLabel2.Font = Enum.Font.GothamBold
sectionLabel2.TextXAlignment = Enum.TextXAlignment.Left
sectionLabel2.Parent = visualTab

createToggle(visualTab, "Full Bright", "FullBright")

-- ============================================
--   НАПОЛНЕНИЕ ВКЛАДКИ MODIFICATION
-- ============================================
local modTab = tabs["Modification"]

local boostSection = Instance.new("TextLabel")
boostSection.Size = UDim2.new(1, 0, 0, 25)
boostSection.BackgroundTransparency = 1
boostSection.Text = "▶ Repair Boost"
boostSection.TextColor3 = COLORS.Accent
boostSection.TextSize = 14
boostSection.Font = Enum.Font.GothamBold
boostSection.TextXAlignment = Enum.TextXAlignment.Left
boostSection.Parent = modTab

createBoostToggle(modTab, "Boost Enabled")

local boostInput = createInput(
	modTab,
	"Boost Speed",
	_G.GetGeneratorBoostPercent,
	_G.SetGeneratorBoostPercent
)

-- ============================================
--   АНИМАЦИИ
-- ============================================
local animationIds = {
	["walk"] = "rbxassetid://121364777933025",
	["run"] = "rbxassetid://88089545021831",
	["crouchIdle"] = "rbxassetid://73650663675588",
	["crouchWalk"] = "rbxassetid://137834747905828",
	["injuredIdle"] = "rbxassetid://137828867671413",
	["injuredWalk"] = "rbxassetid://136695692860739",
	["injuredSprint"] = "rbxassetid://79999409695920",
	["injuredCrouchIdle"] = "rbxassetid://84095653804164",
	["injuredCrouchWalk"] = "rbxassetid://102450923773041",
	["hit1"] = "rbxassetid://104682704142865",
	["hit2"] = "rbxassetid://139830743437188",
	["knockedIdle"] = "rbxassetid://74118390445259",
	["knockedWalk"] = "rbxassetid://106618106536124",
	["hitFront"] = "rbxassetid://139830743437188",
	["hitBack"] = "rbxassetid://121845674088602",
	["heal"] = "rbxassetid://110392490296814",
	["failheal"] = "rbxassetid://87055506624885",
	["getheal"] = "rbxassetid://95836365038528",
	["leveropen"] = "rbxassetid://123959675151191",
	["leveropeninjured"] = "rbxassetid://134838390519433",
	["GeneratorPoint1"] = "rbxassetid://83160743983246",
	["GeneratorPoint2"] = "rbxassetid://92960319113695",
	["GeneratorPoint3"] = "rbxassetid://136553272065734",
	["GeneratorPoint4"] = "rbxassetid://101968088258360",
}

local activeAnimationTrack = nil
local activeAnimationObject = nil

local function stopMenuAnimation()
	if activeAnimationTrack then
		activeAnimationTrack:Stop()
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

local animSection = Instance.new("TextLabel")
animSection.Size = UDim2.new(1, 0, 0, 25)
animSection.BackgroundTransparency = 1
animSection.Text = "▶ Animations"
animSection.TextColor3 = COLORS.Accent
animSection.TextSize = 14
animSection.Font = Enum.Font.GothamBold
animSection.TextXAlignment = Enum.TextXAlignment.Left
animSection.Parent = modTab

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

-- ============================================
--   ДРУГИЕ ВКЛАДКИ (ЗАГЛУШКИ)
-- ============================================
local function createPlaceholder(tabName, text)
	local page = tabs[tabName]
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 30)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = COLORS.TextDim
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = page
end

createPlaceholder("Movement", "🚀 Movement options coming soon...")
createPlaceholder("Combat", "🔪 Combat options coming soon...")
createPlaceholder("Player", "👤 Player options coming soon...")
createPlaceholder("Misc", "⚙ Misc options coming soon...")
createPlaceholder("Settings", "🔧 Settings options coming soon...")

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
print("[SOEKKI] Generator boost controls added to Modification tab!")