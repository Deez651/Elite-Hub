-- Jeez Hub v3.1 | Compact UI + Scrollable + All Features
-- Для Delta Executor (Mobile)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer
local mouse = lp:GetMouse()
local camera = workspace.CurrentCamera

-- States
local flingEnabled = false
local flingConn = nil
local noclipEnabled = false
local noclipConn = nil
local espEnabled = false
local flyEnabled = false
local flyConn = nil
local flyBody = nil
local flyGyro = nil
local flySpeed = 80
local minimize = false

-- === GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Name = "JeezHub"
ScreenGui.Parent = game.CoreGui

-- Main Frame (компактный)
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 280, 0, 350)
Frame.Position = UDim2.new(0.5, -140, 0.5, -175)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.ClipsDescendants = true
Frame.Parent = ScreenGui

local UICornerFrame = Instance.new("UICorner")
UICornerFrame.CornerRadius = UDim.new(0, 16)
UICornerFrame.Parent = Frame

local UIGradientFrame = Instance.new("UIGradient")
UIGradientFrame.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
}
UIGradientFrame.Rotation = 45
UIGradientFrame.Parent = Frame

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
Title.Text = "🔥 JEEZ HUB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local UICornerTitle = Instance.new("UICorner")
UICornerTitle.CornerRadius = UDim.new(0, 16)
UICornerTitle.Parent = Title

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 60, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 255))
}
TitleGradient.Rotation = 90
TitleGradient.Parent = Title

-- Версия
local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(0, 40, 0, 15)
Version.Position = UDim2.new(0, 10, 0, 5)
Version.BackgroundTransparency = 1
Version.Text = "v3.1"
Version.TextColor3 = Color3.fromRGB(200, 200, 200)
Version.TextSize = 10
Version.Font = Enum.Font.GothamBold
Version.TextXAlignment = Enum.TextXAlignment.Left
Version.Parent = Title

-- Кнопка сворачивания
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -35, 0, 7.5)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
MinimizeButton.BackgroundTransparency = 0.2
MinimizeButton.Text = "−"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 24
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Parent = Frame

local UICornerMin = Instance.new("UICorner")
UICornerMin.CornerRadius = UDim.new(0, 8)
UICornerMin.Parent = MinimizeButton

-- === SCROLLING FRAME ===
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, 0, 1, -50)
ScrollFrame.Position = UDim2.new(0, 0, 0, 50)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(140, 60, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 620)
ScrollFrame.Parent = Frame

-- === HELPER: Создание кнопки ===
local function createButton(parent, text, posY, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 250, 0, 48)
    btn.Position = UDim2.new(0, 15, 0, posY)
    btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 70)
    btn.BackgroundTransparency = 0.15
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(120, 40, 200)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.6
    stroke.Parent = btn

    return btn, stroke
end

-- === SEPARATOR ===
local function createSeparator(parent, posY, text)
    local sep = Instance.new("TextLabel")
    sep.Size = UDim2.new(0, 250, 0, 22)
    sep.Position = UDim2.new(0, 15, 0, posY)
    sep.BackgroundTransparency = 1
    sep.Text = "— " .. text .. " —"
    sep.TextColor3 = Color3.fromRGB(140, 80, 255)
    sep.TextSize = 12
    sep.Font = Enum.Font.GothamBold
    sep.Parent = parent
    return sep
end

-- === КНОПКИ (компактные) ===

-- COMBAT
createSeparator(ScrollFrame, 5, "COMBAT")
local FlingButton, FlingStroke = createButton(ScrollFrame, "🚫 Touch Fling: OFF", 32)

-- MOVEMENT
createSeparator(ScrollFrame, 90, "MOVEMENT")
local NoclipButton, NoclipStroke = createButton(ScrollFrame, "🚫 Noclip: OFF", 117)
local FlyButton, FlyStroke = createButton(ScrollFrame, "🚫 Fly: OFF", 175)

-- Fly Speed Slider (компактный)
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 250, 0, 20)
SpeedLabel.Position = UDim2.new(0, 15, 0, 233)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "✈️ Speed: 80"
SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedLabel.TextSize = 12
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = ScrollFrame

local SpeedSliderBG = Instance.new("Frame")
SpeedSliderBG.Size = UDim2.new(0, 250, 0, 6)
SpeedSliderBG.Position = UDim2.new(0, 15, 0, 258)
SpeedSliderBG.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
SpeedSliderBG.BorderSizePixel = 0
SpeedSliderBG.Parent = ScrollFrame

local SpeedSliderBGCorner = Instance.new("UICorner")
SpeedSliderBGCorner.CornerRadius = UDim.new(1, 0)
SpeedSliderBGCorner.Parent = SpeedSliderBG

local SpeedSliderFill = Instance.new("Frame")
SpeedSliderFill.Size = UDim2.new(0.4, 0, 1, 0)
SpeedSliderFill.BackgroundColor3 = Color3.fromRGB(140, 60, 255)
SpeedSliderFill.BorderSizePixel = 0
SpeedSliderFill.Parent = SpeedSliderBG

local SpeedFillCorner = Instance.new("UICorner")
SpeedFillCorner.CornerRadius = UDim.new(1, 0)
SpeedFillCorner.Parent = SpeedSliderFill

local SpeedKnob = Instance.new("TextButton")
SpeedKnob.Size = UDim2.new(0, 18, 0, 18)
SpeedKnob.Position = UDim2.new(0.4, -9, 0.5, -9)
SpeedKnob.BackgroundColor3 = Color3.fromRGB(200, 120, 255)
SpeedKnob.BorderSizePixel = 0
SpeedKnob.Text = ""
SpeedKnob.Parent = SpeedSliderBG

local SpeedKnobCorner = Instance.new("UICorner")
SpeedKnobCorner.CornerRadius = UDim.new(1, 0)
SpeedKnobCorner.Parent = SpeedKnob

-- VISUALS
createSeparator(ScrollFrame, 280, "VISUALS")
local ESPButton, ESPStroke = createButton(ScrollFrame, "🚫 ESP / Chams: OFF", 307)

-- MISC
createSeparator(ScrollFrame, 365, "MISC")
local WaveButton, WaveStroke = createButton(ScrollFrame, "👋 Wave", 392)

-- Credits (в конце scroll frame)
local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(0, 250, 0, 60)
Credits.Position = UDim2.new(0, 15, 0, 450)
Credits.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Credits.BackgroundTransparency = 0.5
Credits.Text = "💎 JEEZ HUB\nv3.1 Compact Edition\n\nMade by Jeez"
Credits.TextColor3 = Color3.fromRGB(140, 60, 255)
Credits.TextSize = 11
Credits.Font = Enum.Font.GothamBold
Credits.Parent = ScrollFrame

local CreditsCorner = Instance.new("UICorner")
CreditsCorner.CornerRadius = UDim.new(0, 10)
CreditsCorner.Parent = Credits

-- Обновляем размер Canvas после всех элементов
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 530)

-- ========================================
-- ============= FUNCTIONS ================
-- ========================================

-- === STABLE FLING ===
local function startFling()
    if flingConn then flingConn:Disconnect() end
    flingConn = RunService.Heartbeat:Connect(function()
        if not flingEnabled then return end
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local originalVel = hrp.Velocity
        hrp.Velocity = originalVel * 6500 + Vector3.new(0, 3500, 0)
        RunService.RenderStepped:Wait()
        hrp.Velocity = originalVel
    end)
end

-- === NOCLIP ===
local function startNoclip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        if not noclipEnabled then return end
        local char = lp.Character
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function stopNoclip()
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    local char = lp.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

-- === FLY ===
local function startFly()
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return end

    flyBody = Instance.new("BodyVelocity")
    flyBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBody.Velocity = Vector3.new(0, 0, 0)
    flyBody.Parent = hrp

    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyGyro.P = 9e4
    flyGyro.Parent = hrp

    humanoid.PlatformStand = true

    if flyConn then flyConn:Disconnect() end
    flyConn = RunService.Heartbeat:Connect(function()
        if not flyEnabled then return end
        if not hrp or not hrp.Parent then
            flyEnabled = false
            return
        end

        local camCF = camera.CFrame
        local moveDir = Vector3.new(0, 0, 0)
        local moveVector = humanoid.MoveDirection

        if moveVector.Magnitude > 0 then
            local look = camCF.LookVector
            local right = camCF.RightVector
            moveDir = (look * moveVector.Z * -1) + (right * moveVector.X)
        end

        -- Вверх/вниз (ПК)
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        flyBody.Velocity = moveDir * flySpeed
        flyGyro.CFrame = camCF
    end)
end

local function stopFly()
    local char = lp.Character
    local humanoid = char and char:FindFirstChild("Humanoid")

    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBody then flyBody:Destroy() flyBody = nil end
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
    if humanoid then humanoid.PlatformStand = false end
end

-- === ESP / CHAMS ===
local espFolder = Instance.new("Folder")
espFolder.Name = "JeezESP"
espFolder.Parent = game.CoreGui

local function createESP(player)
    if player == lp then return end

    local function apply(character)
        if not character then return end
        task.wait(0.5)

        local oldFolder = espFolder:FindFirstChild(player.Name)
        if oldFolder then oldFolder:Destroy() end

        local folder = Instance.new("Folder")
        folder.Name = player.Name
        folder.Parent = espFolder

        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return end

        -- Billboard GUI
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = hrp
        billboard.Parent = folder

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.Parent = billboard

        local healthLabel = Instance.new("TextLabel")
        healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
        healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
        healthLabel.BackgroundTransparency = 1
        healthLabel.Text = "❤️ " .. math.floor(humanoid.Health)
        healthLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        healthLabel.TextSize = 13
        healthLabel.Font = Enum.Font.Gotham
        healthLabel.TextStrokeTransparency = 0.3
        healthLabel.Parent = billboard

        -- Highlight (Chams)
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(140, 60, 255)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0.3
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = character
        highlight.Parent = folder

        -- Update loop
        local updateConn
        updateConn = RunService.Heartbeat:Connect(function()
            if not espEnabled or not character.Parent or not hrp.Parent then
                updateConn:Disconnect()
                return
            end

            if humanoid and humanoid.Parent then
                healthLabel.Text = "❤️ " .. math.floor(humanoid.Health)
                local ratio = humanoid.Health / humanoid.MaxHealth
                if ratio > 0.6 then
                    highlight.FillColor = Color3.fromRGB(60, 200, 60)
                elseif ratio > 0.3 then
                    highlight.FillColor = Color3.fromRGB(255, 200, 0)
                else
                    highlight.FillColor = Color3.fromRGB(255, 50, 50)
                end
            end
        end)
    end

    if player.Character then
        apply(player.Character)
    end
    player.CharacterAdded:Connect(function(char)
        if espEnabled then
            apply(char)
        end
    end)
end

local function enableESP()
    for _, player in pairs(Players:GetPlayers()) do
        createESP(player)
    end
    Players.PlayerAdded:Connect(function(player)
        if espEnabled then
            createESP(player)
        end
    end)
end

local function disableESP()
    for _, child in pairs(espFolder:GetChildren()) do
        child:Destroy()
    end
end

-- === WAVE ANIMATION ===
local function playWave()
    local char = lp.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    if not humanoid then return end

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://507770239"

    local track = humanoid:LoadAnimation(anim)
    track:Play()
    task.spawn(function()
        track.Stopped:Wait()
        track:Destroy()
    end)
end

-- === TOUCH DETECTION ===
local function onTouch()
    if not flingEnabled then return end
    local target = mouse.Target
    if not target then return end
    local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
    if targetPlayer and targetPlayer ~= lp then
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad)
        TweenService:Create(FlingStroke, tweenInfo, {Transparency = 0}):Play()
        task.wait(0.1)
        TweenService:Create(FlingStroke, tweenInfo, {Transparency = 0.6}):Play()
    end
end

UserInputService.TouchTap:Connect(function(_, gpe)
    if gpe then return end
    onTouch()
end)
mouse.Button1Down:Connect(onTouch)

-- ========================================
-- ============ BUTTON EVENTS =============
-- ========================================

local function animateButton(btn, stroke, on, onColor, offColor)
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local color = on and onColor or offColor
    TweenService:Create(btn, tweenInfo, {BackgroundColor3 = color}):Play()
    TweenService:Create(stroke, tweenInfo, {Color = color}):Play()
end

-- FLING
FlingButton.MouseButton1Click:Connect(function()
    flingEnabled = not flingEnabled
    if flingEnabled then
        FlingButton.Text = "✅ Touch Fling: ON"
        animateButton(FlingButton, FlingStroke, true, Color3.fromRGB(50, 200, 50), nil)
        startFling()
    else
        FlingButton.Text = "🚫 Touch Fling: OFF"
        animateButton(FlingButton, FlingStroke, false, nil, Color3.fromRGB(200, 50, 50))
        if flingConn then flingConn:Disconnect() flingConn = nil end
    end
end)

-- NOCLIP
NoclipButton.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        NoclipButton.Text = "✅ Noclip: ON"
        animateButton(NoclipButton, NoclipStroke, true, Color3.fromRGB(50, 200, 50), nil)
        startNoclip()
    else
        NoclipButton.Text = "🚫 Noclip: OFF"
        animateButton(NoclipButton, NoclipStroke, false, nil, Color3.fromRGB(200, 50, 50))
        stopNoclip()
    end
end)

-- FLY
FlyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    if flyEnabled then
        FlyButton.Text = "✅ Fly: ON"
        animateButton(FlyButton, FlyStroke, true, Color3.fromRGB(50, 200, 50), nil)
        startFly()
    else
        FlyButton.Text = "🚫 Fly: OFF"
        animateButton(FlyButton, FlyStroke, false, nil, Color3.fromRGB(200, 50, 50))
        stopFly()
    end
end)

-- FLY SPEED SLIDER
local sliderDragging = false

SpeedKnob.MouseButton1Down:Connect(function()
    sliderDragging = true
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

RunService.RenderStepped:Connect(function()
    if sliderDragging then
        local mousePos = UserInputService:GetMouseLocation()
        local sliderPos = SpeedSliderBG.AbsolutePosition
        local sliderSize = SpeedSliderBG.AbsoluteSize

        local rel = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
        SpeedKnob.Position = UDim2.new(rel, -9, 0.5, -9)
        SpeedSliderFill.Size = UDim2.new(rel, 0, 1, 0)
        flySpeed = math.floor(10 + rel * 290)
        SpeedLabel.Text = "✈️ Speed: " .. flySpeed
    end
end)

-- ESP
ESPButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        ESPButton.Text = "✅ ESP / Chams: ON"
        animateButton(ESPButton, ESPStroke, true, Color3.fromRGB(50, 200, 50), nil)
        enableESP()
    else
        ESPButton.Text = "🚫 ESP / Chams: OFF"
        animateButton(ESPButton, ESPStroke, false, nil, Color3.fromRGB(200, 50, 50))
        disableESP()
    end
end)

-- WAVE
WaveButton.MouseButton1Click:Connect(function()
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
    TweenService:Create(WaveButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(100, 150, 255)}):Play()
    playWave()
    task.wait(0.3)
    TweenService:Create(WaveButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
end)

-- === MINIMIZE ===
MinimizeButton.MouseButton1Click:Connect(function()
    minimize = not minimize
    local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    if minimize then
        TweenService:Create(Frame, tweenInfo, {Size = UDim2.new(0, 280, 0, 45)}):Play()
        TweenService:Create(Title, tweenInfo, {Size = UDim2.new(1, 0, 1, 0), TextSize = 18}):Play()
        MinimizeButton.Text = "+"
        ScrollFrame.Visible = false
    else
        TweenService:Create(Frame, tweenInfo, {Size = UDim2.new(0, 280, 0, 350)}):Play()
        TweenService:Create(Title, tweenInfo, {Size = UDim2.new(1, 0, 0, 45), TextSize = 20}):Play()
        MinimizeButton.Text = "−"
        task.wait(0.2)
        ScrollFrame.Visible = true
    end
end)

-- === RESPAWN FIX ===
lp.CharacterAdded:Connect(function()
    task.wait(1)
    if flingEnabled then startFling() end
    if noclipEnabled then startNoclip() end
    if flyEnabled then startFly() end
end)

-- === NOTIFICATION ===
pcall(function()
    game.StarterGui:SetCore("SendNotification", {
        Title = "🔥 Jeez Hub v3.1";
        Text = "Compact Edition!\nScroll to see all features";
        Duration = 4;
    })
end)

print("🔥 Jeez Hub v3.1 Compact загружен!")
print("📱 Компактное меню + прокрутка")
