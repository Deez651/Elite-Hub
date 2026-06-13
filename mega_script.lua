--[[
    ╔══════════════════════════════════════╗
    ║         MEGA SCRIPT — MOBILE         ║
    ║  Auto Fling + Fling List + Tools     ║
    ║  Tabs: [FLING] [LIST] [TOOLS]        ║
    ╚══════════════════════════════════════╝
]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")

local player  = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ══════════════════════════════════════
--  STATE
-- ══════════════════════════════════════
local autoFlingActive = false
local invisible       = false
local speedValue      = 16
local oldPos          = nil
local oldFPDH         = workspace.FallenPartsDestroyHeight
local selectedTargets = {}   -- { [name] = Player }
local listFlinging    = false

player.CharacterAdded:Connect(function(char)
    character = char
    autoFlingActive = false
    -- Восстанавливаем невидимость при респауне
    task.wait(0.15)
    if invisible then applyInvis(char, true) end
    -- Восстанавливаем скорость
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = speedValue end
end)

-- ══════════════════════════════════════
--  НЕВИДИМОСТЬ
-- ══════════════════════════════════════
function applyInvis(char, state)
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") or d:IsA("Decal") then
            d.Transparency = state and 1 or 0
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = state
            and Enum.HumanoidDisplayDistanceType.None
            or  Enum.HumanoidDisplayDistanceType.Viewer
        hum.HealthDisplayDistanceType = state
            and Enum.HumanoidHealthDisplayDistanceType.None
            or  Enum.HumanoidHealthDisplayDistanceType.DisplayWhenDamaged
    end
    -- Скрываем новые аксессуары которые подгружаются позже
    if state then
        char.DescendantAdded:Connect(function(desc)
            if invisible and (desc:IsA("BasePart") or desc:IsA("Decal")) then
                task.wait(0.05)
                desc.Transparency = 1
            end
        end)
    end
end

-- ══════════════════════════════════════
--  ЯДРО ФЛИНГА (механика KILASIK)
-- ══════════════════════════════════════
local function flingTarget(target, stillActive)
    local char = player.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    local tChar = target and target.Character
    if not char or not hum or not root or not tChar then return end

    local tHum  = tChar:FindFirstChildOfClass("Humanoid")
    local tRoot = tHum and tHum.RootPart
    if not tRoot then return end

    -- Запоминаем позицию для возврата
    if root.Velocity.Magnitude < 50 then
        oldPos = root.CFrame
    end

    workspace.FallenPartsDestroyHeight = 0/0

    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.new(0, 0, 0)
    bv.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent    = root

    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    local angle   = 0
    local timeEnd = tick() + 2

    local function snap(pos, ang)
        if not tRoot or not tRoot.Parent then return end
        root.CFrame = CFrame.new(tRoot.Position) * pos * ang
        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * pos * ang)
        root.Velocity    = Vector3.new(9e7, 9e7 * 10, 9e7)
        root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    repeat
        angle = angle + 100
        -- Крутимся вокруг Y (спин, не кувырок)
        if tRoot and tRoot.Velocity.Magnitude < 50 then
            snap(CFrame.new(0,  1.5, 0), CFrame.Angles(0, math.rad(angle), 0)) task.wait()
            snap(CFrame.new(0, -1.5, 0), CFrame.Angles(0, math.rad(angle), 0)) task.wait()
            snap(CFrame.new(0,  1.5, 0), CFrame.Angles(0, math.rad(angle), 0)) task.wait()
            snap(CFrame.new(0, -1.5, 0), CFrame.Angles(0, math.rad(angle), 0)) task.wait()
        elseif tRoot then
            snap(CFrame.new(0,  1.5,  tHum.WalkSpeed), CFrame.Angles(0, math.rad(angle), 0)) task.wait()
            snap(CFrame.new(0, -1.5, -tHum.WalkSpeed), CFrame.Angles(0, math.rad(angle), 0)) task.wait()
            snap(CFrame.new(0,  1.5,  tHum.WalkSpeed), CFrame.Angles(0, math.rad(angle), 0)) task.wait()
            snap(CFrame.new(0, -1.5, 0),                CFrame.Angles(0, math.rad(angle), 0)) task.wait()
            snap(CFrame.new(0, -1.5, 0),                CFrame.Angles(0, math.rad(angle), 0)) task.wait()
        end
    until tick() > timeEnd or not stillActive()

    -- Чистка
    if bv and bv.Parent then bv:Destroy() end
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = hum

    -- Возврат на старую позицию
    if oldPos then
        local attempts = 0
        repeat
            attempts = attempts + 1
            root.CFrame = oldPos * CFrame.new(0, 0.5, 0)
            char:SetPrimaryPartCFrame(oldPos * CFrame.new(0, 0.5, 0))
            hum:ChangeState("GettingUp")
            for _, p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then
                    p.Velocity    = Vector3.new()
                    p.RotVelocity = Vector3.new()
                end
            end
            task.wait()
        until (root.Position - oldPos.p).Magnitude < 25 or attempts > 60
        workspace.FallenPartsDestroyHeight = oldFPDH
    end

    -- Восстанавливаем невидимость если была включена
    if invisible then applyInvis(player.Character, true) end
end

-- ══════════════════════════════════════
--  AUTO FLING — ближайший игрок
-- ══════════════════════════════════════
local function getNearestPlayer()
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil, math.huge end
    local nearest, minDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (r.Position - root.Position).Magnitude
                if d < minDist then minDist = d nearest = p end
            end
        end
    end
    return nearest, minDist
end

local function autoFlingLoop()
    task.spawn(function()
        while autoFlingActive do
            local char = player.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local root = hum and hum.RootPart
            if not hum or not root then task.wait(0.5) continue end

            local target, dist = getNearestPlayer()
            if not target then
                autoStatusLabel.Text = "👀 Нет игроков..."
                task.wait(0.5)
                continue
            end

            local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if not tRoot then task.wait(0.3) continue end

            -- Идём к цели если далеко
            if dist > 6 then
                autoStatusLabel.Text = "🚶 К " .. target.Name .. " (" .. math.floor(dist) .. " ст.)"
                hum:MoveTo(tRoot.Position)
                local timeout = tick() + 8
                repeat
                    task.wait(0.1)
                    local r2 = character and character:FindFirstChild("HumanoidRootPart")
                    tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                    if not r2 or not tRoot then break end
                    dist = (r2.Position - tRoot.Position).Magnitude
                    hum:MoveTo(tRoot.Position)
                until dist <= 6 or tick() > timeout or not autoFlingActive
            end

            if not autoFlingActive then break end

            autoStatusLabel.Text = "💥 Флингаю " .. target.Name .. "!"
            flingTarget(target, function() return autoFlingActive end)
            task.wait(0.4)
        end
        autoStatusLabel.Text = "Выключено"
    end)
end

-- ══════════════════════════════════════
--  LIST FLING — по выбранным игрокам
-- ══════════════════════════════════════
local function listFlingLoop()
    task.spawn(function()
        while listFlinging do
            local any = false
            for name, p in pairs(selectedTargets) do
                if not p or not p.Parent then
                    selectedTargets[name] = nil
                else
                    any = true
                    if listFlinging then
                        listStatusLabel.Text = "💥 " .. name
                        flingTarget(p, function() return listFlinging end)
                        task.wait(0.3)
                    end
                end
            end
            if not any then
                listStatusLabel.Text = "Выбери цели ↑"
                task.wait(0.4)
            end
        end
        listStatusLabel.Text = "Остановлено"
    end)
end

-- ══════════════════════════════════════
--  GUI — ПОСТРОЕНИЕ
-- ══════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name         = "MegaScript"
gui.ResetOnSpawn = false
gui.Parent       = player.PlayerGui

-- Главный фрейм
local frame = Instance.new("Frame")
frame.Size                = UDim2.new(0, 260, 0, 400)
frame.Position            = UDim2.new(0.5, -130, 0.18, 0)
frame.BackgroundColor3    = Color3.fromRGB(10, 10, 18)
frame.BackgroundTransparency = 0.05
frame.Active              = true
frame.Draggable           = true
frame.BorderSizePixel     = 0
frame.Parent              = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
local mainStroke = Instance.new("UIStroke", frame)
mainStroke.Color     = Color3.fromRGB(255, 60, 60)
mainStroke.Thickness = 2

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 8, 8)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)
-- Заполняем нижние углы заголовка
local titleFix = Instance.new("Frame")
titleFix.Size             = UDim2.new(1, 0, 0.5, 0)
titleFix.Position         = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = Color3.fromRGB(22, 8, 8)
titleFix.BorderSizePixel  = 0
titleFix.Parent           = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text               = "☠️  MEGA SCRIPT"
titleLabel.TextColor3         = Color3.fromRGB(255, 100, 100)
titleLabel.TextSize           = 15
titleLabel.Font               = Enum.Font.GothamBold
titleLabel.Parent             = titleBar

-- ──────────────────────────────────────
--  ТАБЫ
-- ──────────────────────────────────────
local TAB_Y = 38
local tabNames = {"🎯 FLING", "📋 LIST", "🔧 TOOLS"}
local tabBtns  = {}
local tabPages = {}

local tabBar = Instance.new("Frame")
tabBar.Size             = UDim2.new(1, -12, 0, 32)
tabBar.Position         = UDim2.new(0, 6, 0, TAB_Y)
tabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
tabBar.BorderSizePixel  = 0
tabBar.Parent           = frame
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder     = Enum.SortOrder.LayoutOrder
tabLayout.Padding       = UDim.new(0, 4)
tabLayout.Parent        = tabBar
Instance.new("UIPadding", tabBar).PaddingLeft  = UDim.new(0, 4)

for i, name in ipairs(tabNames) do
    local tb = Instance.new("TextButton")
    tb.Size             = UDim2.new(0.32, -4, 1, -6)
    tb.Position         = UDim2.new(0, 0, 0, 3)
    tb.BackgroundColor3 = Color3.fromRGB(28, 28, 45)
    tb.Text             = name
    tb.TextColor3       = Color3.fromRGB(160, 160, 200)
    tb.TextSize         = 11
    tb.Font             = Enum.Font.GothamBold
    tb.BorderSizePixel  = 0
    tb.LayoutOrder      = i
    tb.Parent           = tabBar
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 8)
    tabBtns[i] = tb

    -- Страница таба
    local page = Instance.new("Frame")
    page.Size             = UDim2.new(1, -12, 1, -(TAB_Y + 38))
    page.Position         = UDim2.new(0, 6, 0, TAB_Y + 38)
    page.BackgroundTransparency = 1
    page.Visible          = (i == 1)
    page.BorderSizePixel  = 0
    page.Parent           = frame
    tabPages[i] = page
end

local currentTab = 1

local function switchTab(idx)
    currentTab = idx
    for i, tb in ipairs(tabBtns) do
        if i == idx then
            tb.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
            tb.TextColor3       = Color3.fromRGB(255, 255, 255)
        else
            tb.BackgroundColor3 = Color3.fromRGB(28, 28, 45)
            tb.TextColor3       = Color3.fromRGB(160, 160, 200)
        end
        tabPages[i].Visible = (i == idx)
    end
end
switchTab(1)

-- Фикс drag для всех кнопок
local dragStart, wasDragged = nil, false
frame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStart = i.Position wasDragged = false
    end
end)
frame.InputChanged:Connect(function(i)
    if (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) and dragStart then
        if (Vector2.new(i.Position.X, i.Position.Y) - Vector2.new(dragStart.X, dragStart.Y)).Magnitude > 10 then
            wasDragged = true
        end
    end
end)

local function safeBind(btn, cb)
    local ds2, wd2 = nil, false
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            ds2 = i.Position wd2 = false
        end
    end)
    frame.InputChanged:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) and ds2 then
            if (Vector2.new(i.Position.X, i.Position.Y) - Vector2.new(ds2.X, ds2.Y)).Magnitude > 10 then wd2 = true end
        end
    end)
    btn.InputEnded:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.Touch and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if wd2 then return end
        cb()
    end)
end

for i, tb in ipairs(tabBtns) do
    safeBind(tb, function() switchTab(i) end)
end

-- ══════════════════════════════════════
--  ТАБ 1 — AUTO FLING
-- ══════════════════════════════════════
local p1 = tabPages[1]

autoStatusLabel = Instance.new("TextLabel")
autoStatusLabel.Size               = UDim2.new(1, 0, 0, 26)
autoStatusLabel.Position           = UDim2.new(0, 0, 0, 4)
autoStatusLabel.BackgroundTransparency = 1
autoStatusLabel.Text               = "Выключено"
autoStatusLabel.TextColor3         = Color3.fromRGB(150, 150, 200)
autoStatusLabel.TextSize           = 12
autoStatusLabel.Font               = Enum.Font.Gotham
autoStatusLabel.TextXAlignment     = Enum.TextXAlignment.Center
autoStatusLabel.Parent             = p1

local autoBtn = Instance.new("TextButton")
autoBtn.Size             = UDim2.new(1, 0, 0, 52)
autoBtn.Position         = UDim2.new(0, 0, 0, 34)
autoBtn.BackgroundColor3 = Color3.fromRGB(130, 18, 18)
autoBtn.Text             = "🎯  AUTO FLING"
autoBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
autoBtn.TextSize         = 18
autoBtn.Font             = Enum.Font.GothamBold
autoBtn.BorderSizePixel  = 0
autoBtn.Parent           = p1
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 12)
local abStroke = Instance.new("UIStroke", autoBtn)
abStroke.Color     = Color3.fromRGB(255, 80, 80)
abStroke.Thickness = 1.5

-- Описание
local autoDesc = Instance.new("TextLabel")
autoDesc.Size               = UDim2.new(1, 0, 0, 60)
autoDesc.Position           = UDim2.new(0, 0, 0, 96)
autoDesc.BackgroundTransparency = 1
autoDesc.Text               = "Автоматически идёт к\nближайшему игроку и\nфлингает его. Повторяет."
autoDesc.TextColor3         = Color3.fromRGB(120, 120, 170)
autoDesc.TextSize           = 12
autoDesc.Font               = Enum.Font.Gotham
autoDesc.TextXAlignment     = Enum.TextXAlignment.Center
autoDesc.TextWrapped        = true
autoDesc.Parent             = p1

safeBind(autoBtn, function()
    if autoFlingActive then
        autoFlingActive = false
        autoBtn.Text             = "🎯  AUTO FLING"
        autoBtn.BackgroundColor3 = Color3.fromRGB(130, 18, 18)
        abStroke.Color           = Color3.fromRGB(255, 80, 80)
        mainStroke.Color         = Color3.fromRGB(255, 60, 60)
    else
        autoFlingActive = true
        autoBtn.Text             = "🛑  СТОП"
        autoBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        abStroke.Color           = Color3.fromRGB(255, 220, 50)
        mainStroke.Color         = Color3.fromRGB(255, 220, 50)
        autoFlingLoop()
    end
end)

-- ══════════════════════════════════════
--  ТАБ 2 — LIST FLING
-- ══════════════════════════════════════
local p2 = tabPages[2]

listStatusLabel = Instance.new("TextLabel")
listStatusLabel.Size               = UDim2.new(1, 0, 0, 22)
listStatusLabel.Position           = UDim2.new(0, 0, 0, 2)
listStatusLabel.BackgroundTransparency = 1
listStatusLabel.Text               = "Выбери цели ↑"
listStatusLabel.TextColor3         = Color3.fromRGB(150, 150, 200)
listStatusLabel.TextSize           = 11
listStatusLabel.Font               = Enum.Font.Gotham
listStatusLabel.TextXAlignment     = Enum.TextXAlignment.Center
listStatusLabel.Parent             = p2

-- Скролл список игроков
local scroll = Instance.new("ScrollingFrame")
scroll.Size                = UDim2.new(1, 0, 0, 170)
scroll.Position            = UDim2.new(0, 0, 0, 26)
scroll.BackgroundColor3    = Color3.fromRGB(16, 16, 26)
scroll.BorderSizePixel     = 0
scroll.ScrollBarThickness  = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 80, 80)
scroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent              = p2
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 10)

local listLayout2 = Instance.new("UIListLayout")
listLayout2.Padding   = UDim.new(0, 3)
listLayout2.SortOrder = Enum.SortOrder.Name
listLayout2.Parent    = scroll
local lPad = Instance.new("UIPadding", scroll)
lPad.PaddingTop   = UDim.new(0, 4)
lPad.PaddingLeft  = UDim.new(0, 4)
lPad.PaddingRight = UDim.new(0, 4)

local playerBtns = {}

local function updateListStatus()
    local count = 0
    for _ in pairs(selectedTargets) do count = count + 1 end
    if listFlinging then
        listStatusLabel.Text      = "☠️ Флингает " .. count .. " цел."
        listStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    else
        listStatusLabel.Text      = "Выбрано: " .. count
        listStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    end
end

local function makePlayerBtn(p)
    if p == player then return end
    if playerBtns[p.Name] then return end

    local row = Instance.new("TextButton")
    row.Name             = p.Name
    row.Size             = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Color3.fromRGB(24, 24, 38)
    row.Text             = "  👤  " .. p.Name
    row.TextColor3       = Color3.fromRGB(200, 210, 255)
    row.TextSize         = 12
    row.Font             = Enum.Font.GothamBold
    row.TextXAlignment   = Enum.TextXAlignment.Left
    row.BorderSizePixel  = 0
    row.Parent           = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local check = Instance.new("TextLabel")
    check.Size             = UDim2.new(0, 24, 0, 24)
    check.Position         = UDim2.new(1, -28, 0.5, -12)
    check.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    check.Text             = ""
    check.TextColor3       = Color3.fromRGB(100, 255, 120)
    check.TextSize         = 14
    check.Font             = Enum.Font.GothamBold
    check.BorderSizePixel  = 0
    check.Parent           = row
    Instance.new("UICorner", check).CornerRadius = UDim.new(0, 6)

    playerBtns[p.Name] = {row = row, check = check}

    safeBind(row, function()
        if selectedTargets[p.Name] then
            selectedTargets[p.Name] = nil
            check.Text             = ""
            check.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
            row.BackgroundColor3   = Color3.fromRGB(24, 24, 38)
        else
            selectedTargets[p.Name] = p
            check.Text             = "✓"
            check.BackgroundColor3 = Color3.fromRGB(25, 70, 35)
            row.BackgroundColor3   = Color3.fromRGB(45, 18, 18)
        end
        updateListStatus()
    end)
end

local function refreshList()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    playerBtns = {}
    local list = Players:GetPlayers()
    table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
    for _, p in ipairs(list) do makePlayerBtn(p) end
end

-- START / STOP / SELECT ALL / DESELECT
local listBtnRow = Instance.new("Frame")
listBtnRow.Size             = UDim2.new(1, 0, 0, 36)
listBtnRow.Position         = UDim2.new(0, 0, 0, 202)
listBtnRow.BackgroundTransparency = 1
listBtnRow.BorderSizePixel  = 0
listBtnRow.Parent           = p2

local startListBtn = Instance.new("TextButton")
startListBtn.Size             = UDim2.new(0.5, -3, 1, 0)
startListBtn.BackgroundColor3 = Color3.fromRGB(20, 90, 28)
startListBtn.Text             = "▶ START"
startListBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
startListBtn.TextSize         = 13
startListBtn.Font             = Enum.Font.GothamBold
startListBtn.BorderSizePixel  = 0
startListBtn.Parent           = listBtnRow
Instance.new("UICorner", startListBtn).CornerRadius = UDim.new(0, 9)

local stopListBtn = Instance.new("TextButton")
stopListBtn.Size             = UDim2.new(0.5, -3, 1, 0)
stopListBtn.Position         = UDim2.new(0.5, 3, 0, 0)
stopListBtn.BackgroundColor3 = Color3.fromRGB(100, 18, 18)
stopListBtn.Text             = "■ STOP"
stopListBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
stopListBtn.TextSize         = 13
stopListBtn.Font             = Enum.Font.GothamBold
stopListBtn.BorderSizePixel  = 0
stopListBtn.Parent           = listBtnRow
Instance.new("UICorner", stopListBtn).CornerRadius = UDim.new(0, 9)

local selRow = Instance.new("Frame")
selRow.Size             = UDim2.new(1, 0, 0, 28)
selRow.Position         = UDim2.new(0, 0, 0, 244)
selRow.BackgroundTransparency = 1
selRow.BorderSizePixel  = 0
selRow.Parent           = p2

local selAllBtn = Instance.new("TextButton")
selAllBtn.Size             = UDim2.new(0.5, -3, 1, 0)
selAllBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 50)
selAllBtn.Text             = "✓ Все"
selAllBtn.TextColor3       = Color3.fromRGB(180, 180, 255)
selAllBtn.TextSize         = 12
selAllBtn.Font             = Enum.Font.GothamBold
selAllBtn.BorderSizePixel  = 0
selAllBtn.Parent           = selRow
Instance.new("UICorner", selAllBtn).CornerRadius = UDim.new(0, 8)

local deselAllBtn = Instance.new("TextButton")
deselAllBtn.Size             = UDim2.new(0.5, -3, 1, 0)
deselAllBtn.Position         = UDim2.new(0.5, 3, 0, 0)
deselAllBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 50)
deselAllBtn.Text             = "✗ Сброс"
deselAllBtn.TextColor3       = Color3.fromRGB(180, 180, 255)
deselAllBtn.TextSize         = 12
deselAllBtn.Font             = Enum.Font.GothamBold
deselAllBtn.BorderSizePixel  = 0
deselAllBtn.Parent           = selRow
Instance.new("UICorner", deselAllBtn).CornerRadius = UDim.new(0, 8)

safeBind(startListBtn, function()
    if listFlinging then return end
    local count = 0
    for _ in pairs(selectedTargets) do count = count + 1 end
    if count == 0 then listStatusLabel.Text = "⚠️ Выбери цели!" return end
    listFlinging = true
    updateListStatus()
    listFlingLoop()
end)

safeBind(stopListBtn, function()
    listFlinging = false
    updateListStatus()
end)

safeBind(selAllBtn, function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            selectedTargets[p.Name] = p
            local d = playerBtns[p.Name]
            if d then
                d.check.Text             = "✓"
                d.check.BackgroundColor3 = Color3.fromRGB(25, 70, 35)
                d.row.BackgroundColor3   = Color3.fromRGB(45, 18, 18)
            end
        end
    end
    updateListStatus()
end)

safeBind(deselAllBtn, function()
    selectedTargets = {}
    for _, d in pairs(playerBtns) do
        d.check.Text             = ""
        d.check.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
        d.row.BackgroundColor3   = Color3.fromRGB(24, 24, 38)
    end
    updateListStatus()
end)

Players.PlayerAdded:Connect(function(p) makePlayerBtn(p) end)
Players.PlayerRemoving:Connect(function(p)
    selectedTargets[p.Name] = nil
    local d = playerBtns[p.Name]
    if d then d.row:Destroy() playerBtns[p.Name] = nil end
    updateListStatus()
end)

refreshList()
updateListStatus()

-- ══════════════════════════════════════
--  ТАБ 3 — TOOLS
-- ══════════════════════════════════════
local p3 = tabPages[3]

-- НЕВИДИМОСТЬ
local invBtn = Instance.new("TextButton")
invBtn.Size             = UDim2.new(1, 0, 0, 44)
invBtn.Position         = UDim2.new(0, 0, 0, 4)
invBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 50)
invBtn.Text             = "👁️  НЕВИДИМОСТЬ: OFF"
invBtn.TextColor3       = Color3.fromRGB(180, 180, 255)
invBtn.TextSize         = 14
invBtn.Font             = Enum.Font.GothamBold
invBtn.BorderSizePixel  = 0
invBtn.Parent           = p3
Instance.new("UICorner", invBtn).CornerRadius = UDim.new(0, 12)
local iStroke = Instance.new("UIStroke", invBtn)
iStroke.Color     = Color3.fromRGB(100, 100, 200)
iStroke.Thickness = 1.5

safeBind(invBtn, function()
    invisible = not invisible
    applyInvis(player.Character, invisible)
    if invisible then
        invBtn.Text             = "👁️  НЕВИДИМОСТЬ: ON"
        invBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 90)
        iStroke.Color           = Color3.fromRGB(140, 140, 255)
    else
        invBtn.Text             = "👁️  НЕВИДИМОСТЬ: OFF"
        invBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 50)
        iStroke.Color           = Color3.fromRGB(100, 100, 200)
    end
end)

-- СКОРОСТЬ
local spdLabel = Instance.new("TextLabel")
spdLabel.Size               = UDim2.new(1, 0, 0, 20)
spdLabel.Position           = UDim2.new(0, 0, 0, 56)
spdLabel.BackgroundTransparency = 1
spdLabel.Text               = "🏃 Скорость: " .. speedValue
spdLabel.TextColor3         = Color3.fromRGB(160, 200, 255)
spdLabel.TextSize           = 13
spdLabel.Font               = Enum.Font.GothamBold
spdLabel.TextXAlignment     = Enum.TextXAlignment.Left
spdLabel.Parent             = p3

local spdTrack = Instance.new("Frame")
spdTrack.Size             = UDim2.new(1, 0, 0, 12)
spdTrack.Position         = UDim2.new(0, 0, 0, 80)
spdTrack.BackgroundColor3 = Color3.fromRGB(28, 28, 45)
spdTrack.BorderSizePixel  = 0
spdTrack.Parent           = p3
Instance.new("UICorner", spdTrack).CornerRadius = UDim.new(1, 0)

local SPD_MIN, SPD_MAX = 0, 200
local spdRatio = speedValue / SPD_MAX

local spdFill = Instance.new("Frame")
spdFill.Size             = UDim2.new(spdRatio, 0, 1, 0)
spdFill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
spdFill.BorderSizePixel  = 0
spdFill.Parent           = spdTrack
Instance.new("UICorner", spdFill).CornerRadius = UDim.new(1, 0)

local spdKnob = Instance.new("TextButton")
spdKnob.Size             = UDim2.new(0, 24, 0, 24)
spdKnob.Position         = UDim2.new(spdRatio, -12, 0.5, -12)
spdKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
spdKnob.Text             = ""
spdKnob.BorderSizePixel  = 0
spdKnob.ZIndex           = 5
spdKnob.Parent           = spdTrack
Instance.new("UICorner", spdKnob).CornerRadius = UDim.new(1, 0)

-- Быстрые кнопки скорости
local spdBtnRow = Instance.new("Frame")
spdBtnRow.Size             = UDim2.new(1, 0, 0, 28)
spdBtnRow.Position         = UDim2.new(0, 0, 0, 98)
spdBtnRow.BackgroundTransparency = 1
spdBtnRow.BorderSizePixel  = 0
spdBtnRow.Parent           = p3

local spdPresets = {{"🐢 Норм", 16}, {"🐇 Быстро", 50}, {"🚀 Макс", 200}}
for i, preset in ipairs(spdPresets) do
    local pb = Instance.new("TextButton")
    pb.Size             = UDim2.new(0.33, -3, 1, 0)
    pb.Position         = UDim2.new((i-1) * 0.33, (i == 1 and 0 or 3), 0, 0)
    pb.BackgroundColor3 = Color3.fromRGB(28, 38, 70)
    pb.Text             = preset[1]
    pb.TextColor3       = Color3.fromRGB(180, 200, 255)
    pb.TextSize         = 10
    pb.Font             = Enum.Font.GothamBold
    pb.BorderSizePixel  = 0
    pb.Parent           = spdBtnRow
    Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 7)
    local spd = preset[2]
    safeBind(pb, function()
        speedValue = spd
        local r = speedValue / SPD_MAX
        spdFill.Size     = UDim2.new(r, 0, 1, 0)
        spdKnob.Position = UDim2.new(r, -12, 0.5, -12)
        spdLabel.Text    = "🏃 Скорость: " .. speedValue
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = speedValue end
    end)
end

-- Ползунок скорости
local spdDragging = false
spdKnob.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        spdDragging = true
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        spdDragging = false
    end
end)
UIS.InputChanged:Connect(function(i)
    if not spdDragging then return end
    if i.UserInputType ~= Enum.UserInputType.Touch and i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local r = math.clamp((i.Position.X - spdTrack.AbsolutePosition.X) / spdTrack.AbsoluteSize.X, 0, 1)
    speedValue = math.floor(SPD_MIN + r * (SPD_MAX - SPD_MIN))
    spdFill.Size     = UDim2.new(r, 0, 1, 0)
    spdKnob.Position = UDim2.new(r, -12, 0.5, -12)
    spdLabel.Text    = "🏃 Скорость: " .. speedValue
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = speedValue end
end)

-- РАЗДЕЛИТЕЛЬ
local sep = Instance.new("Frame")
sep.Size             = UDim2.new(1, 0, 0, 1)
sep.Position         = UDim2.new(0, 0, 0, 134)
sep.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
sep.BorderSizePixel  = 0
sep.Parent           = p3

-- ОТБРАСЫВАНИЕ при касании
local knockActive = false
local knockConn   = nil

local function setupKnockback(char)
    local function knockPlayer(hitChar)
        if hitChar == char then return end
        local hitRoot = hitChar:FindFirstChild("HumanoidRootPart")
        local hitHum  = hitChar:FindFirstChildOfClass("Humanoid")
        local myRoot  = char and char:FindFirstChild("HumanoidRootPart")
        if not hitRoot or not hitHum or not myRoot then return end
        if hitHum.Health <= 0 then return end
        local flat = (hitRoot.Position - myRoot.Position)
        flat = Vector3.new(flat.X, 0, flat.Z).Unit
        if hitRoot:FindFirstChild("KnockBV") then hitRoot:FindFirstChild("KnockBV"):Destroy() end
        local bv = Instance.new("BodyVelocity")
        bv.Name      = "KnockBV"
        bv.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity  = Vector3.new(flat.X * 200, 100, flat.Z * 200)
        bv.Parent    = hitRoot
        task.delay(0.18, function() if bv and bv.Parent then bv:Destroy() end end)
    end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Touched:Connect(function(hit)
                if not knockActive then return end
                local hitChar = hit:FindFirstAncestorOfClass("Model")
                if hitChar and hitChar ~= char and hitChar:FindFirstChildOfClass("Humanoid") then
                    knockPlayer(hitChar)
                end
            end)
        end
    end
end

setupKnockback(character)
player.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    setupKnockback(char)
end)

local knockBtn = Instance.new("TextButton")
knockBtn.Size             = UDim2.new(1, 0, 0, 44)
knockBtn.Position         = UDim2.new(0, 0, 0, 142)
knockBtn.BackgroundColor3 = Color3.fromRGB(50, 22, 10)
knockBtn.Text             = "💥  ОТБРАСЫВАНИЕ: OFF"
knockBtn.TextColor3       = Color3.fromRGB(255, 180, 120)
knockBtn.TextSize         = 13
knockBtn.Font             = Enum.Font.GothamBold
knockBtn.BorderSizePixel  = 0
knockBtn.Parent           = p3
Instance.new("UICorner", knockBtn).CornerRadius = UDim.new(0, 12)
local kStroke = Instance.new("UIStroke", knockBtn)
kStroke.Color     = Color3.fromRGB(200, 100, 50)
kStroke.Thickness = 1.5

safeBind(knockBtn, function()
    knockActive = not knockActive
    if knockActive then
        knockBtn.Text             = "💥  ОТБРАСЫВАНИЕ: ON"
        knockBtn.BackgroundColor3 = Color3.fromRGB(120, 55, 10)
        kStroke.Color             = Color3.fromRGB(255, 160, 80)
    else
        knockBtn.Text             = "💥  ОТБРАСЫВАНИЕ: OFF"
        knockBtn.BackgroundColor3 = Color3.fromRGB(50, 22, 10)
        kStroke.Color             = Color3.fromRGB(200, 100, 50)
    end
end)

-- ══════════════════════════════════════
print("[MegaScript] Загружен! Все функции готовы.")
