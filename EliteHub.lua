-- [[ ELITE HUB ULTIMATE EDITION — ROBLOX DELTA EXECUTOR ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- СОСТОЯНИЕ ХАБА (ГЛОБАЛЬНЫЕ НАСТРОЙКИ)
local currentSpeed = 16
local currentJump = 50
local noclipActive = false
local scriptRunning = true

local flyActive = false
local flySpeed = 50

local chamsActive = false
local chamsColor = Color3.fromRGB(0, 180, 255)

local aimbotActive = false
local aimbotFov = 120
local aimbotSmoothness = 0.15
local aimbotTargetPart = "Head"

-- РИСОВАНИЕ ПРИЦЕЛА (FOV)
local FovCircle = Drawing.new("Circle")
FovCircle.Color = Color3.fromRGB(0, 255, 150)
FovCircle.Thickness = 1.5
FovCircle.NumSides = 64
FovCircle.Radius = aimbotFov
FovCircle.Filled = false
FovCircle.Visible = false

-- ИНИЦИАЛИЗАЦИЯ ИНТЕРФЕЙСА
local parentUI
pcall(function() parentUI = game:GetService("CoreGui") end)
if not parentUI then parentUI = LocalPlayer:WaitForChild("PlayerGui") end

if parentUI:FindFirstChild("EliteHubUltimate") then parentUI.EliteHubUltimate:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EliteHubUltimate"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = parentUI

-- НЕОНОВАЯ ПАЛИТРА ЦВЕТОВ
local Theme = {
    Background = Color3.fromRGB(14, 15, 19),
    Sidebar = Color3.fromRGB(20, 21, 27),
    Main = Color3.fromRGB(26, 28, 36),
    Accent = Color3.fromRGB(0, 180, 255),
    Text = Color3.fromRGB(245, 245, 250),
    TextDim = Color3.fromRGB(130, 135, 145),
    Green = Color3.fromRGB(46, 204, 113),
    Red = Color3.fromRGB(231, 76, 60)
}

local function addCorner(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = obj
end

-- ГЛАВНЫЙ ФРЕЙМ (Большой и просторный)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 340)
MainFrame.Position = UDim2.new(0.5, -240, 0.4, -170)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 16)

-- Градиентная обводка контура окна
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 48, 62)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- БОКОВОЕ МЕНЮ (САЙДБАР)
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
addCorner(Sidebar, 16)

-- Фиксатор, чтобы скругление было только слева
local SidebarFix = Instance.new("Frame")
SidebarFix.Size = UDim2.new(0, 20, 1, 0)
SidebarFix.Position = UDim2.new(1, -20, 0, 0)
SidebarFix.BackgroundColor3 = Theme.Sidebar
SidebarFix.BorderSizePixel = 0
SidebarFix.Parent = Sidebar

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(1, 0, 0, 55)
Logo.BackgroundTransparency = 1
Logo.Text = "Δ ULTIMATE HUB"
Logo.TextColor3 = Theme.Accent
Logo.TextSize = 15
Logo.Font = Enum.Font.GothamBold
Logo.Parent = Sidebar

-- ОБЛАСТЬ ДЛЯ СТРАНИЦ КОНТЕНТА
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -165, 1, -20)
ContentFrame.Position = UDim2.new(0, 155, 0, 10)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- ИКОНКА ДЛЯ СВЕРНУТОГО РЕЖИМА (Кнопка Delta)
local MiniIcon = Instance.new("TextButton")
MiniIcon.Name = "DeltaMiniIcon"
MiniIcon.Size = UDim2.new(0, 52, 0, 52)
MiniIcon.BackgroundColor3 = Theme.Sidebar
MiniIcon.Text = "Δ"
MiniIcon.TextColor3 = Theme.Accent
MiniIcon.TextSize = 26
MiniIcon.Font = Enum.Font.GothamBold
MiniIcon.Visible = false
MiniIcon.Active = true
MiniIcon.Draggable = true
MiniIcon.Parent = ScreenGui
addCorner(MiniIcon, 26)
local IconStroke = Instance.new("UIStroke", MiniIcon)
IconStroke.Color = Theme.Accent
IconStroke.Thickness = 1.5

----------------------------------------------------------------
-- АРХИТЕКТУРА ИЗОЛИРОВАННЫХ СТРАНИЦ
----------------------------------------------------------------
local Pages = {}
local TabButtons = {}
local categoryNames = {"Игрок", "Визуалы", "Аимбот", "Настройки"}

for index, catName in ipairs(categoryNames) do
    -- Жесткий изолированный контейнер для каждой страницы
    local Page = Instance.new("Frame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = (index == 1)
    Page.Parent = ContentFrame
    Pages[catName] = Page
    
    -- Кнопка вкладки в левой панели
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0.9, 0, 0, 36)
    TabBtn.Position = UDim2.new(0.05, 0, 0, 60 + ((index - 1) * 42))
    TabBtn.BackgroundColor3 = (index == 1) and Theme.Main or Color3.fromRGB(0,0,0)
    TabBtn.BackgroundTransparency = (index == 1) and 0 or 1
    TabBtn.Text = catName
    TabBtn.TextColor3 = (index == 1) and Theme.Text or Theme.TextDim
    TabBtn.TextSize = 12
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.Parent = Sidebar
    addCorner(TabBtn, 8)
    
    TabButtons[catName] = TabBtn
    
    -- Переключение страниц без багов размеров
    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        for _, b in pairs(TabButtons) do 
            b.TextColor3 = Theme.TextDim 
            b.BackgroundTransparency = 1
        end
        Page.Visible = true
        TabBtn.TextColor3 = Theme.Text
        TabBtn.BackgroundColor3 = Theme.Main
        TabBtn.BackgroundTransparency = 0
    end)
end

----------------------------------------------------------------
-- ПРОДВИНУТЫЕ КОНСТРУКТОРЫ ЭЛЕМЕНТОВ ИНТЕРФЕЙСА
----------------------------------------------------------------
local function addToggle(pageTarget, text, posY, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 42)
    Frame.Position = UDim2.new(0, 0, 0, posY)
    Frame.BackgroundColor3 = Theme.Main
    Frame.Parent = pageTarget
    addCorner(Frame, 8)
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 14, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 60, 0, 26)
    Btn.Position = UDim2.new(1, -74, 0.5, -13)
    Btn.BackgroundColor3 = default and Theme.Green or Theme.Red
    Btn.Text = default and "ВКЛ" or "ВЫКЛ"
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.TextSize = 10
    Btn.Font = Enum.Font.GothamBold
    Btn.Parent = Frame
    addCorner(Btn, 6)
    
    local state = default
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Btn.Text = state and "ВКЛ" or "ВЫКЛ"
        TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = state and Theme.Green or Theme.Red}):Play()
        callback(state)
    end)
    return Btn
end

local function addSlider(pageTarget, name, posY, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 58)
    Frame.Position = UDim2.new(0, 0, 0, posY)
    Frame.BackgroundColor3 = Theme.Main
    Frame.Parent = pageTarget
    addCorner(Frame, 8)
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 22)
    Label.Position = UDim2.new(0, 14, 0, 6)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. default
    Label.TextColor3 = Theme.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -28, 0, 6)
    Track.Position = UDim2.new(0, 14, 0, 38)
    Track.BackgroundColor3 = Color3.fromRGB(48, 50, 64)
    Track.BorderSizePixel = 0
    Track.Parent = Frame
    addCorner(Track, 3)
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    addCorner(Fill, 3)
    
    local SliderBtn = Instance.new("TextButton")
    SliderBtn.Size = UDim2.new(0, 16, 0, 16)
    SliderBtn.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    SliderBtn.BackgroundColor3 = Theme.Text
    SliderBtn.Text = ""
    SliderBtn.Parent = Track
    addCorner(SliderBtn, 8)
    
    local isDragging = false
    local function updateValue(input)
        local length = Track.AbsoluteSize.X
        local deltaX = input.Position.X - Track.AbsolutePosition.X
        local percentage = math.clamp(deltaX / length, 0, 1)
        
        SliderBtn.Position = UDim2.new(percentage, -8, 0.5, -8)
        Fill.Size = UDim2.new(percentage, 0, 1, 0)
        
        local calculatedValue = min + (percentage * (max - min))
        Label.Text = name .. ": " .. math.floor(calculatedValue)
        callback(calculatedValue)
    end
    
    SliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = true end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateValue(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = false end
    end)
end

----------------------------------------------------------------
-- ГЕОМЕТРИЧЕСКАЯ СБОРКА ИНТЕРФЕЙСА ПО КООРДИНАТАМ
----------------------------------------------------------------

-- СТРАНИЦА: ИГРОК
addSlider(Pages["Игрок"], "Скорость бега", 0, MIN_SPEED, MAX_SPEED, currentSpeed, function(v) currentSpeed = v end)
addSlider(Pages["Игрок"], "Высота прыжка", 65, MIN_JUMP, MAX_JUMP, currentJump, function(v) currentJump = v end)
addToggle(Pages["Игрок"], "Режим Ноклип (Сквозь стены)", 130, noclipActive, function(v) noclipActive = v end)

local FlyToggle = addToggle(Pages["Игрок"], "Режим Полета (Fly)", 180, flyActive, function(v) flyActive = v end)
addSlider(Pages["Игрок"], "Скорость Полета", 230, 20, 250, flySpeed, function(v) flySpeed = v end)

-- СТРАНИЦА: ВИЗУАЛЫ
addToggle(Pages["Визуалы"], "Подсветка сквозь стены (Chams)", 0, chamsActive, function(v) chamsActive = v end)

-- СТРАНИЦА: АИМБОТ
addToggle(Pages["Аимбот"], "Автонаведение (Aimbot)", 0, aimbotActive, function(v) aimbotActive = v end)
addToggle(Pages["Аимбот"], "Отображать круг FOV прицела", 50, FovCircle.Visible, function(v) FovCircle.Visible = v end)
addSlider(Pages["Аимбот"], "Радиус захвата Аима (FOV)", 100, 40, 500, aimbotFov, function(v) 
    aimbotFov = v 
    FovCircle.Radius = v
end)
addSlider(Pages["Аимбот"], "Плавность наводки (%)", 165, 5, 60, 15, function(v)
    aimbotSmoothness = (v / 100)
end)

-- СТРАНИЦА: НАСТРОЙКИ
addToggle(Pages["Настройки"], "Свернуть хаб в иконку Delta", 0, false, function(v)
    if v then
        MainFrame.Visible = false
        MiniIcon.Visible = true
        MiniIcon.Position = UDim2.new(0, MainFrame.AbsolutePosition.X + 210, 0, MainFrame.AbsolutePosition.Y + 140)
    else
        MainFrame.Visible = true
        MiniIcon.Visible = false
    end
end)

local TotalExitBtn = Instance.new("TextButton")
TotalExitBtn.Size = UDim2.new(1, 0, 0, 46)
TotalExitBtn.Position = UDim2.new(0, 0, 0, 65)
TotalExitBtn.BackgroundColor3 = Theme.Red
TotalExitBtn.Text = "ПОЛНОСТЬЮ УДАЛИТЬ ЧИТ ИЗ ИГРЫ"
TotalExitBtn.TextColor3 = Theme.Text
TotalExitBtn.Font = Enum.Font.GothamBold
TotalExitBtn.TextSize = 12
TotalExitBtn.Parent = Pages["Настройки"]
addCorner(TotalExitBtn, 8)

----------------------------------------------------------------
-- ЯДРО АЛГОРИТМОВ И КЛИЕНТСКОЙ ФИЗИКИ
----------------------------------------------------------------

-- 1. ДВИЖОК ПОЛЕТА (FLY ENGINE)
local function handleFlyLogic()
    local BV = Instance.new("BodyVelocity")
    local BG = Instance.new("BodyGyro")
    
    RunService.RenderStepped:Connect(function()
        if not flyActive or not scriptRunning then 
            BV:Destroy()
            BG:Destroy()
            return 
        end
        
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        if root and humanoid then
            BG.Parent = root
            BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
            BG.cframe = Camera.CFrame
            
            BV.Parent = root
            BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
            
            local direction = humanoid.MoveDirection
            if direction.Magnitude > 0 then
                BV.velocity = Camera.CFrame.LookVector * (direction.Magnitude * flySpeed)
            else
                BV.velocity = Vector3.new(0, 0.1, 0)
            end
        end
    end)
end

FlyToggle.MouseButton1Click:Connect(function()
    task.wait(0.05)
    if flyActive then handleFlyLogic() end
end)

-- 2. ВЫСОКОПРОИЗВОДИТЕЛЬНЫЕ ЧАМСЫ (CHAMS ENGINE)
task.spawn(function()
    while scriptRunning do
        if chamsActive then
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer and pl.Character then
                    local character = pl.Character
                    if not character:FindFirstChild("UltimateCham") then
                        local High = Instance.new("Highlight")
                        High.Name = "UltimateCham"
                        High.FillColor = chamsColor
                        High.FillTransparency = 0.4
                        High.OutlineColor = Color3.fromRGB(255, 255, 255)
                        High.OutlineTransparency = 0.2
                        High.Adornee = character
                        High.Parent = character
                    end
                end
            end
        else
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl.Character and pl.Character:FindFirstChild("UltimateCham") then
                    pl.Character.UltimateCham:Destroy()
                end
            end
        end
        task.wait(0.4)
    end
end)

-- 3. АИМБОТ С КОРРЕКЦИЕЙ НАВЕДЕНИЯ НА ТЕЛЕФОНАХ (AIMBOT ENGINE)
local function calculateClosestTarget()
    local targetUser = nil
    local maxDistance = math.huge

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild(aimbotTargetPart) then
            local part = pl.Character[aimbotTargetPart]
            local screenPosition, visibleOnScreen = Camera:WorldToViewportPoint(part.Position)
            
            if visibleOnScreen then
                local cursorPosition = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - cursorPosition).Magnitude
                
                if distance < maxDistance and distance <= aimbotFov then
                    targetUser = pl
                    maxDistance = distance
                end
            end
        end
    end
    return targetUser
end

RunService.RenderStepped:Connect(function()
    if not scriptRunning then return end
    
    if FovCircle.Visible then
        FovCircle.Position = UserInputService:GetMouseLocation()
    end
    
    if aimbotActive then
        local validTarget = calculateClosestTarget()
        if validTarget and validTarget.Character and validTarget.Character:FindFirstChild(aimbotTargetPart) then
            local positionOnScreen = Camera:WorldToViewportPoint(validTarget.Character[aimbotTargetPart].Position)
            local currentCursor = UserInputService:GetMouseLocation()
            
            local deltaX = (positionOnScreen.X - currentCursor.X) * aimbotSmoothness
            local deltaY = (positionOnScreen.Y - currentCursor.Y) * aimbotSmoothness
            
            -- Проверка доступных методов наведения в Delta Executor
            if mouse_moverel then
                mouse_moverel(deltaX, deltaY)
            else
                -- Универсальный мобильный доводчик камеры, если либы инжектора отключены
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, validTarget.Character[aimbotTargetPart].Position)
            end
        end
    end
end)

-- 4. ПОЛНАЯ ДЕИНСТАЛЛЯЦИЯ И ОЧИСТКА ПАМЯТИ
TotalExitBtn.MouseButton1Click:Connect(function()
    scriptRunning = false
    aimbotActive = false
    chamsActive = false
    flyActive = false
    noclipActive = false
    FovCircle.Visible = false
    FovCircle:Remove()
    
    pcall(function()
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then 
            humanoid.WalkSpeed = 16 
            humanoid.JumpPower = 50 
        end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl.Character and pl.Character:FindFirstChild("UltimateCham") then pl.Character.UltimateCham:Destroy() end
        end
    end)
    ScreenGui:Destroy()
end)

MiniIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniIcon.Visible = false
    MainFrame.Position = UDim2.new(0, MiniIcon.AbsolutePosition.X - 210, 0, MiniIcon.AbsolutePosition.Y - 140)
end)

----------------------------------------------------------------
-- ОВЕРЛЕЙ-ПЕРЕХВАТ ДЛЯ СТАБИЛИЗАЦИИ ФИЗИКИ ПЕРСОНАЖА
----------------------------------------------------------------
RunService.Stepped:Connect(function()
    if not scriptRunning then return end
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- Стабилизация бега (игнорируем сбросы игры при флай-моде)
            if humanoid.WalkSpeed ~= currentSpeed and not flyActive then humanoid.WalkSpeed = currentSpeed end
            humanoid.UseJumpPower = true
            if humanoid.JumpPower ~= currentJump then humanoid.JumpPower = currentJump end
        end
        -- Принудительное отключение коллизий во всех итерациях кадров
        if noclipActive then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end
    end
end)
