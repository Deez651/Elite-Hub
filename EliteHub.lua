-- [[ ELITE MOBILE HUB — ОПТИМИЗАЦИЯ ПОД СМАРТФОНЫ ]] --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
local scriptRunning = true
local currentSpeed = 16
local currentJump = 50
local noclipActive = false
local flyActive = false
local flySpeed = 50
local chamsActive = false
local aimbotActive = false
local aimbotFov = 120
local aimbotSmoothness = 0.2

-- ИНИЦИАЛИЗАЦИЯ ИНТЕРФЕЙСА
local parentUI
pcall(function() parentUI = CoreGui end)
if not parentUI then parentUI = LocalPlayer:WaitForChild("PlayerGui") end

if parentUI:FindFirstChild("EliteMobile") then 
    parentUI.EliteMobile:Destroy() 
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EliteMobile"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = parentUI

-- ЦВЕТОВАЯ ТЕМА (Темная + Голубой Неон)
local Theme = {
    BG = Color3.fromRGB(20, 20, 25),
    TopBar = Color3.fromRGB(30, 30, 38),
    Sidebar = Color3.fromRGB(25, 25, 32),
    ElementBG = Color3.fromRGB(35, 35, 45),
    Accent = Color3.fromRGB(0, 200, 255),
    Text = Color3.fromRGB(255, 255, 255),
    Off = Color3.fromRGB(200, 50, 50),
    On = Color3.fromRGB(50, 200, 100)
}

local function addCorner(obj, rad)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, rad or 8)
    corner.Parent = obj
end

-- КАСТОМНЫЙ МОБИЛЬНЫЙ DRAG (ПЕРЕМЕЩЕНИЕ ПАЛЬЦЕМ)
local function MakeMobileDraggable(dragArea, moveObject)
    local dragging = false
    local dragInput, dragStart, startPos

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = moveObject.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            moveObject.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ГЛАВНОЕ ОКНО
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 260) -- Широкое окно под горизонтальный хват телефона
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -130)
MainFrame.BackgroundColor3 = Theme.BG
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 12)

-- ВЕРХНЯЯ ПАНЕЛЬ (ДЛЯ ПЕРЕМЕЩЕНИЯ И КНОПОК ОКОН)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Theme.TopBar
TopBar.Parent = MainFrame
addCorner(TopBar, 12)
MakeMobileDraggable(TopBar, MainFrame)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 150, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ELITE MOBILE"
Title.TextColor3 = Theme.Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- КНОПКА СВОРАЧИВАНИЯ (-)
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 40, 0, 40)
MinBtn.Position = UDim2.new(1, -85, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.Text
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TopBar

-- КНОПКА ЗАКРЫТИЯ (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.Off
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TopBar

-- ПЛАВАЮЩАЯ ИКОНКА ДЛЯ РАЗВОРАЧИВАНИЯ (ПОЯВЛЯЕТСЯ ПРИ СВОРАЧИВАНИИ)
local FloatIcon = Instance.new("TextButton")
FloatIcon.Size = UDim2.new(0, 50, 0, 50)
FloatIcon.Position = UDim2.new(0.05, 0, 0.1, 0)
FloatIcon.BackgroundColor3 = Theme.TopBar
FloatIcon.Text = "E"
FloatIcon.TextColor3 = Theme.Accent
FloatIcon.TextSize = 24
FloatIcon.Font = Enum.Font.GothamBold
FloatIcon.Visible = false
FloatIcon.Parent = ScreenGui
addCorner(FloatIcon, 25) -- Круглая кнопка
local FloatStroke = Instance.new("UIStroke", FloatIcon)
FloatStroke.Color = Theme.Accent
FloatStroke.Thickness = 2
MakeMobileDraggable(FloatIcon, FloatIcon)

-- ЛОГИКА ОКОН
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatIcon.Visible = true
end)

FloatIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatIcon.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    scriptRunning = false
    ScreenGui:Destroy()
end)

-- БОКОВАЯ ПАНЕЛЬ ВКЛАДОК
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 110, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.Parent = MainFrame

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -110, 1, -40)
Content.Position = UDim2.new(0, 110, 0, 40)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

----------------------------------------------------------------
-- ГЕНЕРАТОР МОБИЛЬНЫХ ЭЛЕМЕНТОВ (КРУПНЫЕ, УДОБНЫЕ)
----------------------------------------------------------------
local Pages = {}
local Tabs = {}

local function createPage(name, index)
    local Tab = Instance.new("TextButton")
    Tab.Size = UDim2.new(1, -10, 0, 40)
    Tab.Position = UDim2.new(0, 5, 0, 10 + (index - 1) * 45)
    Tab.BackgroundColor3 = (index == 1) and Theme.ElementBG or Theme.Sidebar
    Tab.Text = name
    Tab.TextColor3 = Theme.Text
    Tab.Font = Enum.Font.GothamMedium
    Tab.TextSize = 14
    Tab.Parent = Sidebar
    addCorner(Tab, 8)
    
    local Page = Instance.new("Frame")
    Page.Size = UDim2.new(1, -10, 1, -10)
    Page.Position = UDim2.new(0, 5, 0, 5)
    Page.BackgroundTransparency = 1
    Page.Visible = (index == 1)
    Page.Parent = Content
    
    Tabs[name] = Tab
    Pages[name] = Page
    
    Tab.MouseButton1Click:Connect(function()
        for pName, p in pairs(Pages) do
            p.Visible = (pName == name)
            Tabs[pName].BackgroundColor3 = (pName == name) and Theme.ElementBG or Theme.Sidebar
            Tabs[pName].TextColor3 = (pName == name) and Theme.Accent or Theme.Text
        end
    end)
    return Page
end

local function addMobileToggle(page, text, posY, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 45) -- Высота 45 для жирного пальца
    Frame.Position = UDim2.new(0, 0, 0, posY)
    Frame.BackgroundColor3 = Theme.ElementBG
    Frame.Parent = page
    addCorner(Frame, 8)
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.Parent = Frame
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 70, 0, 30)
    Btn.Position = UDim2.new(1, -80, 0.5, -15)
    Btn.BackgroundColor3 = default and Theme.On or Theme.Off
    Btn.Text = default and "ВКЛ" or "ВЫКЛ"
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.Parent = Frame
    addCorner(Btn, 8)
    
    local state = default
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Btn.Text = state and "ВКЛ" or "ВЫКЛ"
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.On or Theme.Off}):Play()
        callback(state)
    end)
    return Btn
end

local function addMobileSlider(page, text, posY, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 60) -- Высота 60 для слайдера
    Frame.Position = UDim2.new(0, 0, 0, posY)
    Frame.BackgroundColor3 = Theme.ElementBG
    Frame.Parent = page
    addCorner(Frame, 8)
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -30, 0, 25)
    Label.Position = UDim2.new(0, 15, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. default
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.Parent = Frame
    
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -30, 0, 8) -- Толстая полоска
    Track.Position = UDim2.new(0, 15, 0, 40)
    Track.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    Track.Parent = Frame
    addCorner(Track, 4)
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Accent
    Fill.Parent = Track
    addCorner(Fill, 4)
    
    local Knob = Instance.new("TextButton")
    Knob.Size = UDim2.new(0, 24, 0, 24) -- Огромный ползунок для пальца
    Knob.Position = UDim2.new((default - min) / (max - min), -12, 0.5, -12)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.Text = ""
    Knob.Parent = Track
    addCorner(Knob, 12)
    
    local dragging = false
    local function update(input)
        local deltaX = input.Position.X - Track.AbsolutePosition.X
        local percent = math.clamp(deltaX / Track.AbsoluteSize.X, 0, 1)
        
        Knob.Position = UDim2.new(percent, -12, 0.5, -12)
        Fill.Size = UDim2.new(percent, 0, 1, 0)
        
        local val = math.floor(min + (percent * (max - min)))
        Label.Text = text .. ": " .. val
        callback(val)
    end
    
    Knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

----------------------------------------------------------------
-- СОЗДАНИЕ ВКЛАДОК И НАПОЛНЕНИЕ
----------------------------------------------------------------
local P_Player = createPage("Игрок", 1)
local P_Combat = createPage("Аимбот", 2)
local P_Visual = createPage("Визуалы", 3)

-- === ВКЛАДКА ИГРОКА ===
addMobileSlider(P_Player, "Скорость", 0, 16, 100, 16, function(v) currentSpeed = v end)
addMobileSlider(P_Player, "Прыжок", 65, 50, 150, 50, function(v) currentJump = v end)
addMobileToggle(P_Player, "Сквозь стены (Noclip)", 130, false, function(v) noclipActive = v end)
addMobileToggle(P_Player, "Полет (Fly)", 180, false, function(v) flyActive = v end)

-- === ВКЛАДКА АИМБОТ ===
addMobileToggle(P_Combat, "Включить Аимбот", 0, false, function(v) aimbotActive = v end)
addMobileSlider(P_Combat, "Размер захвата (FOV)", 50, 50, 400, 120, function(v) aimbotFov = v end)
addMobileSlider(P_Combat, "Сила наводки", 115, 1, 50, 15, function(v) aimbotSmoothness = v / 100 end)

-- === ВКЛАДКА ВИЗУАЛОВ ===
addMobileToggle(P_Visual, "Обводка сквозь стены", 0, false, function(v) chamsActive = v end)

----------------------------------------------------------------
-- СИСТЕМНЫЕ ФУНКЦИИ (ФИЗИКА, АИМ, ПОДСВЕТКА)
----------------------------------------------------------------

-- ОБРАБОТКА ИГРОКА (Бег, Прыжок, Ноклип, Флай)
RunService.Stepped:Connect(function()
    if not scriptRunning then return end
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if hum then
        if not flyActive then hum.WalkSpeed = currentSpeed end
        hum.UseJumpPower = true
        hum.JumpPower = currentJump
    end
    
    if noclipActive then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    
    -- Мобильный Флай
    if flyActive and root and hum then
        if not root:FindFirstChild("EliteMobileFlyBV") then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "EliteMobileFlyBV"
            bv.MaxForce = Vector3.new(100000, 100000, 100000)
            bv.Parent = root
            
            local bg = Instance.new("BodyGyro")
            bg.Name = "EliteMobileFlyBG"
            bg.MaxTorque = Vector3.new(100000, 100000, 100000)
            bg.Parent = root
        end
        
        local bv = root:FindFirstChild("EliteMobileFlyBV")
        local bg = root:FindFirstChild("EliteMobileFlyBG")
        
        if bv and bg then
            bg.CFrame = Camera.CFrame
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                bv.Velocity = Camera.CFrame.LookVector * (moveDir.Magnitude * flySpeed)
            else
                bv.Velocity = Vector3.new(0, 0.1, 0) -- зависание на месте
            end
        end
    else
        if root and root:FindFirstChild("EliteMobileFlyBV") then
            root.EliteMobileFlyBV:Destroy()
            root.EliteMobileFlyBG:Destroy()
        end
    end
end)

-- ОБРАБОТКА ESP (Подсветка)
task.spawn(function()
    while task.wait(1) do
        if not scriptRunning then break end
        
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character then
                local char = pl.Character
                if chamsActive then
                    if not char:FindFirstChild("EliteMobileESP") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "EliteMobileESP"
                        hl.FillColor = Theme.Accent
                        hl.FillTransparency = 0.5
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.Parent = char
                    end
                else
                    if char:FindFirstChild("EliteMobileESP") then
                        char.EliteMobileESP:Destroy()
                    end
                end
            end
        end
    end
end)

-    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        tapTime = tick()
    end
end)

MobileToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Если нажатие длилось меньше 0.2 секунд (это был быстрый тап, а не перенос)
        if tick() - tapTime < 0.2 then
            MainFrame.Visible = not MainFrame.Visible
        end
    end
end)

----------------------------------------------------------------
-- МОБИЛЬНЫЙ ПАТЧ (УПРАВЛЕНИЕ, DRAG И СВОРАЧИВАНИЕ)
----------------------------------------------------------------
local UIS = game:GetService("UserInputService")

-- 1. Мобильное перетаскивание главного окна (MainFrame)
local dragToggle = nil
local dragSpeed = 0.1
local dragStart = nil
local startPos = nil

local function updateInput(input)
    local delta = input.Position - dragStart
    local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    game:GetService("TweenService"):Create(MainFrame, TweenInfo.new(dragSpeed), {Position = position}):Play()
end

MainFrame.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then 
        dragToggle = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if dragToggle then
            updateInput(input)
        end
    end
end)

-- 2. Создание плавающей круглой кнопки сворачивания для мобилок
local MobileToggleBtn = Instance.new("TextButton")
MobileToggleBtn.Name = "MobileToggle"
MobileToggleBtn.Size = UDim2.new(0, 45, 0, 45)
MobileToggleBtn.Position = UDim2.new(0, 10, 0, 10)
MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
MobileToggleBtn.Text = "Δ"
MobileToggleBtn.TextColor3 = Color3.fromRGB(0, 180, 255)
MobileToggleBtn.TextSize = 22
MobileToggleBtn.Font = Enum.Font.GothamBold
MobileToggleBtn.Parent = ScreenGui -- Привязываем к твоему ScreenGui

-- Скругляем до круга
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = MobileToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 180, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = MobileToggleBtn

-- 3. Делаем кнопку тоже перетаскиваемой (чтобы не мешала на экране)
local btnDragToggle = false
local btnDragStart, btnStartPos

MobileToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        btnDragToggle = true
        btnDragStart = input.Position
        btnStartPos = MobileToggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then btnDragToggle = false end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) and btnDragToggle then
        local delta = input.Position - btnDragStart
        MobileToggleBtn.Position = UDim2.new(btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y)
    end
end)

-- 4. Сворачивание/Разворачивание по быстрому тапу (исключаем конфликт с перетаскиванием)
local tapTime = 0
MobileToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        tapTime = tick()
    end
end)

MobileToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Если нажатие длилось меньше 0.2 секунд (это был быстрый тап, а не перенос)
        if tick() - tapTime < 0.2 then
            MainFrame.Visible = not MainFrame.Visible
        end
    end
end)

