--[[
    ╔═══════════════════════════════════════════════╗
    ║                  JeezHub v2.0                 ║
    ║   Auto Fling · List Fling · ESP · Tools       ║
    ║   Invisibility · Speed · Noclip · Fly · Troll ║
    ╚═══════════════════════════════════════════════╝
    loadstring(game:HttpGet("YOUR_RAW_URL"))()
]]

-- ════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UIS           = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local Lighting      = game:GetService("Lighting")
local SG            = game:GetService("StarterGui")

local player   = Players.LocalPlayer
local camera   = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()

-- ════════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════════
local autoFlingActive = false
local listFlinging    = false
local invisible       = false
local noclipActive    = false
local flyActive       = false
local espActive       = false
local discoActive     = false
local knockActive     = false
local giantActive     = false
local speedValue      = 16
local selectedTargets = {}
local espObjects      = {}
local oldPos          = nil
local oldFPDH         = workspace.FallenPartsDestroyHeight
local minimized       = false

-- ════════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════════
local function notify(text)
    pcall(function()
        SG:SetCore("SendNotification", {
            Title    = "JeezHub",
            Text     = text,
            Duration = 3
        })
    end)
end

local function getChar()
    return player.Character
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local h = getHum()
    return h and h.RootPart
end

-- Безопасная очистка — удаляет любой instance
local function safeDestroy(inst)
    if inst and inst.Parent then
        pcall(function() inst:Destroy() end)
    end
end

-- ════════════════════════════════════════════
--  INVISIBLE
-- ════════════════════════════════════════════
local function applyInvis(char, state)
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") or d:IsA("Decal") then
            d.Transparency = state and 1 or 0
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType =
            state and Enum.HumanoidDisplayDistanceType.None
                  or  Enum.HumanoidDisplayDistanceType.Viewer
        hum.HealthDisplayDistanceType =
            state and Enum.HumanoidHealthDisplayDistanceType.None
                  or  Enum.HumanoidHealthDisplayDistanceType.DisplayWhenDamaged
    end
    if state then
        char.DescendantAdded:Connect(function(desc)
            if invisible and (desc:IsA("BasePart") or desc:IsA("Decal")) then
                task.wait(0.05)
                desc.Transparency = 1
            end
        end)
    end
end

-- ════════════════════════════════════════════
--  NOCLIP
-- ════════════════════════════════════════════
local noclipConn = nil

local function startNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        local c = getChar()
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end)
end

local function stopNoclip()
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    local c = getChar()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
            end
        end
    end
end

-- ════════════════════════════════════════════
--  FLY
-- ════════════════════════════════════════════
local flyConn    = nil
local flyBV      = nil
local flyBAV     = nil
local FLY_SPEED  = 60

local function startFly()
    local c    = getChar()
    local hum  = getHum()
    local root = getRoot()
    if not c or not hum or not root then return end

    flyActive = true
    hum.PlatformStand = true

    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity  = Vector3.new(0, 0, 0)
    flyBV.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Parent    = root

    flyBAV = Instance.new("BodyAngularVelocity")
    flyBAV.AngularVelocity = Vector3.new(0, 0, 0)
    flyBAV.MaxTorque       = Vector3.new(1e9, 1e9, 1e9)
    flyBAV.Parent          = root

    flyConn = RunService.RenderStepped:Connect(function()
        local r = getRoot()
        if not r or not flyActive then return end

        local cf  = camera.CFrame
        local vel = Vector3.new(0, 0, 0)

        if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up) then
            vel = vel + cf.LookVector * FLY_SPEED
        end
        if UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.Down) then
            vel = vel - cf.LookVector * FLY_SPEED
        end
        if UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left) then
            vel = vel - cf.RightVector * FLY_SPEED
        end
        if UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right) then
            vel = vel + cf.RightVector * FLY_SPEED
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.ButtonA) then
            vel = vel + Vector3.new(0, FLY_SPEED, 0)
        end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
            vel = vel - Vector3.new(0, FLY_SPEED, 0)
        end

        -- Mobile: кнопки на экране управляют через Humanoid.MoveDirection
        local h = getHum()
        if h and h.MoveDirection.Magnitude > 0 then
            vel = vel + Vector3.new(
                h.MoveDirection.X * FLY_SPEED,
                0,
                h.MoveDirection.Z * FLY_SPEED
            )
        end

        if flyBV then flyBV.Velocity = vel end
    end)
end

local function stopFly()
    flyActive = false
    if flyConn  then flyConn:Disconnect()  flyConn  = nil end
    safeDestroy(flyBV)  flyBV  = nil
    safeDestroy(flyBAV) flyBAV = nil
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

-- ════════════════════════════════════════════
--  ESP
-- ════════════════════════════════════════════
local function createESPFor(p)
    if p == player then return end
    if espObjects[p.Name] then return end

    local function buildESP(char)
        if not char then return end
        local head = char:WaitForChild("Head", 5)
        if not head then return end

        -- Удаляем старый если есть
        local oldBill = head:FindFirstChild("JeezESP")
        if oldBill then oldBill:Destroy() end

        local bill = Instance.new("BillboardGui")
        bill.Name            = "JeezESP"
        bill.Size            = UDim2.new(0, 120, 0, 40)
        bill.StudsOffset     = Vector3.new(0, 3.2, 0)
        bill.AlwaysOnTop     = true
        bill.MaxDistance     = 500
        bill.Parent          = head

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size               = UDim2.new(1, 0, 0.6, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text               = p.Name
        nameLbl.TextColor3         = Color3.fromRGB(255, 80, 80)
        nameLbl.TextSize           = 14
        nameLbl.Font               = Enum.Font.GothamBold
        nameLbl.TextStrokeTransparency = 0
        nameLbl.TextStrokeColor3   = Color3.fromRGB(0, 0, 0)
        nameLbl.Parent             = bill

        local distLbl = Instance.new("TextLabel")
        distLbl.Size               = UDim2.new(1, 0, 0.4, 0)
        distLbl.Position           = UDim2.new(0, 0, 0.6, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Text               = "0 ст."
        distLbl.TextColor3         = Color3.fromRGB(255, 255, 100)
        distLbl.TextSize           = 11
        distLbl.Font               = Enum.Font.Gotham
        distLbl.TextStrokeTransparency = 0
        distLbl.TextStrokeColor3   = Color3.fromRGB(0, 0, 0)
        distLbl.Parent             = bill

        -- Обновление расстояния каждый кадр
        local espConn
        espConn = RunService.Heartbeat:Connect(function()
            if not espActive then
                bill.Enabled = false
                return
            end
            bill.Enabled = true
            local myRoot = getRoot()
            local tRoot  = char:FindFirstChild("HumanoidRootPart")
            if myRoot and tRoot then
                local dist = math.floor((tRoot.Position - myRoot.Position).Magnitude)
                distLbl.Text = dist .. " ст."
                -- Цвет по расстоянию
                if dist < 20 then
                    nameLbl.TextColor3 = Color3.fromRGB(255, 60, 60)
                elseif dist < 60 then
                    nameLbl.TextColor3 = Color3.fromRGB(255, 180, 50)
                else
                    nameLbl.TextColor3 = Color3.fromRGB(100, 220, 255)
                end
            end
        end)

        espObjects[p.Name] = {bill = bill, conn = espConn}
    end

    buildESP(p.Character)
    p.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if espActive then buildESP(char) end
    end)
end

local function enableESP()
    for _, p in ipairs(Players:GetPlayers()) do
        createESPFor(p)
    end
    -- Показываем все
    for _, data in pairs(espObjects) do
        if data.bill then data.bill.Enabled = true end
    end
end

local function disableESP()
    for _, data in pairs(espObjects) do
        if data.bill then data.bill.Enabled = false end
        if data.conn then data.conn:Disconnect() end
    end
    espObjects = {}
end

Players.PlayerAdded:Connect(function(p)
    if espActive then createESPFor(p) end
end)

Players.PlayerRemoving:Connect(function(p)
    local data = espObjects[p.Name]
    if data then
        if data.conn then data.conn:Disconnect() end
        if data.bill then safeDestroy(data.bill) end
        espObjects[p.Name] = nil
    end
end)

-- ════════════════════════════════════════════
--  DISCO
-- ════════════════════════════════════════════
local discoConn = nil
local origAmbient = Lighting.Ambient
local origFog     = Lighting.FogColor

local function startDisco()
    discoConn = RunService.Heartbeat:Connect(function()
        Lighting.Ambient  = Color3.fromHSV(math.random(), 1, 1)
        Lighting.FogColor = Color3.fromHSV(math.random(), 1, 1)
        Lighting.Brightness = math.random(1, 3)
    end)
end

local function stopDisco()
    if discoConn then discoConn:Disconnect() discoConn = nil end
    Lighting.Ambient    = origAmbient
    Lighting.FogColor   = origFog
    Lighting.Brightness = 2
end

-- ════════════════════════════════════════════
--  GIANT / TINY
-- ════════════════════════════════════════════
local originalScales = {}

local function setSize(scale)
    local c = getChar()
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local desc = hum:GetAppliedDescription()
    if not desc then return end
    if scale == 0 then
        -- Восстановить
        desc.HeadScale   = originalScales.HeadScale   or 1
        desc.BodyHeightScale = originalScales.BodyHeightScale or 1
        desc.BodyWidthScale  = originalScales.BodyWidthScale  or 1
        desc.BodyDepthScale  = originalScales.BodyDepthScale  or 1
    else
        if not originalScales.HeadScale then
            originalScales.HeadScale       = desc.HeadScale
            originalScales.BodyHeightScale = desc.BodyHeightScale
            originalScales.BodyWidthScale  = desc.BodyWidthScale
            originalScales.BodyDepthScale  = desc.BodyDepthScale
        end
        desc.HeadScale       = scale
        desc.BodyHeightScale = scale
        desc.BodyWidthScale  = scale
        desc.BodyDepthScale  = scale
    end
    hum:ApplyDescription(desc)
end

-- ════════════════════════════════════════════
--  KNOCKBACK
-- ════════════════════════════════════════════
local function setupKnockback(char)
    if not char then return end
    local function doKnock(hitChar)
        if not knockActive then return end
        if hitChar == char then return end
        local hitRoot = hitChar:FindFirstChild("HumanoidRootPart")
        local hitHum  = hitChar:FindFirstChildOfClass("Humanoid")
        local myRoot  = char:FindFirstChild("HumanoidRootPart")
        if not hitRoot or not hitHum or not myRoot then return end
        if hitHum.Health <= 0 then return end
        local flat = (hitRoot.Position - myRoot.Position)
        flat = Vector3.new(flat.X, 0, flat.Z).Unit
        if hitRoot:FindFirstChild("KnockBV") then
            hitRoot:FindFirstChild("KnockBV"):Destroy()
        end
        local bv = Instance.new("BodyVelocity")
        bv.Name      = "KnockBV"
        bv.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity  = Vector3.new(flat.X * 200, 100, flat.Z * 200)
        bv.Parent    = hitRoot
        task.delay(0.18, function() safeDestroy(bv) end)
    end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Touched:Connect(function(hit)
                local hc = hit:FindFirstAncestorOfClass("Model")
                if hc and hc:FindFirstChildOfClass("Humanoid") then
                    doKnock(hc)
                end
            end)
        end
    end
end

-- ════════════════════════════════════════════
--  FLING CORE (KILASIK — ИСПРАВЛЕННЫЙ)
-- ════════════════════════════════════════════
--  Исправление: BodyVelocity теперь удаляется
--  гарантированно через pcall + defer
-- ════════════════════════════════════════════
local function flingTarget(target, stillActiveFn)
    local c    = getChar()
    local hum  = c and c:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    local tChar = target and target.Character

    if not c or not hum or not root or not tChar then return end

    local tHum  = tChar:FindFirstChildOfClass("Humanoid")
    local tRoot = tHum and tHum.RootPart
    if not tRoot then return end

    -- Сохраняем позицию для возврата
    if root.Velocity.Magnitude < 50 then
        oldPos = root.CFrame
    end

    workspace.FallenPartsDestroyHeight = 0/0

    -- *** ИСПРАВЛЕНИЕ: создаём BV и гарантируем его удаление ***
    local bv = Instance.new("BodyVelocity")
    bv.Name     = "JeezFlingBV"
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent   = root

    -- Подстраховка: если что-то пойдёт не так — BV всё равно удалится через 5 сек
    task.delay(5, function() safeDestroy(bv) end)

    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    local angle   = 0
    local timeEnd = tick() + 2

    local function snap(pos, ang)
        if not tRoot or not tRoot.Parent then return end
        if not root or not root.Parent then return end
        pcall(function()
            root.CFrame = CFrame.new(tRoot.Position) * pos * ang
            c:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * pos * ang)
            root.Velocity    = Vector3.new(9e7, 9e7 * 10, 9e7)
            root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end)
    end

    -- Флинг цикл (спин по Y)
    local ok, err = pcall(function()
        repeat
            angle = angle + 100
            local ang = CFrame.Angles(0, math.rad(angle), 0)

            if tRoot and tRoot.Velocity.Magnitude < 50 then
                snap(CFrame.new(0,  1.5, 0), ang) task.wait()
                snap(CFrame.new(0, -1.5, 0), ang) task.wait()
                snap(CFrame.new(0,  1.5, 0), ang) task.wait()
                snap(CFrame.new(0, -1.5, 0), ang) task.wait()
            elseif tRoot then
                local ws = tHum and tHum.WalkSpeed or 16
                snap(CFrame.new(0,  1.5,  ws), ang) task.wait()
                snap(CFrame.new(0, -1.5, -ws), ang) task.wait()
                snap(CFrame.new(0,  1.5,  ws), ang) task.wait()
                snap(CFrame.new(0, -1.5,  0),  ang) task.wait()
                snap(CFrame.new(0, -1.5,  0),  ang) task.wait()
            end
        until tick() > timeEnd or not stillActiveFn()
    end)

    -- *** ГАРАНТИРОВАННАЯ ОЧИСТКА ***
    safeDestroy(bv)

    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = hum
    end)

    -- Возврат на старую позицию
    if oldPos and root and root.Parent then
        local attempts = 0
        repeat
            attempts = attempts + 1
            pcall(function()
                root.CFrame = oldPos * CFrame.new(0, 0.5, 0)
                c:SetPrimaryPartCFrame(oldPos * CFrame.new(0, 0.5, 0))
                hum:ChangeState("GettingUp")
                for _, p in ipairs(c:GetChildren()) do
                    if p:IsA("BasePart") then
                        p.Velocity    = Vector3.new()
                        p.RotVelocity = Vector3.new()
                    end
                end
            end)
            task.wait()
        until (root.Position - oldPos.p).Magnitude < 25 or attempts > 60
    end

    pcall(function()
        workspace.FallenPartsDestroyHeight = oldFPDH
    end)

    -- Восстановить невидимость если была
    if invisible then
        task.wait(0.1)
        applyInvis(getChar(), true)
    end
end

-- ════════════════════════════════════════════
--  AUTO FLING LOOP
-- ════════════════════════════════════════════
local function getNearestPlayer()
    local root = getRoot()
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
            local hum  = getHum()
            local root = getRoot()
            if not hum or not root then task.wait(0.5) continue end

            local target, dist = getNearestPlayer()
            if not target then
                autoStatusLbl.Text = "👀 Нет игроков..."
                task.wait(0.5)
                continue
            end

            local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if not tRoot then task.wait(0.3) continue end

            if dist > 6 then
                autoStatusLbl.Text = "🚶 К " .. target.Name .. " (" .. math.floor(dist) .. " ст.)"
                hum:MoveTo(tRoot.Position)
                local timeout = tick() + 8
                repeat
                    task.wait(0.1)
                    local r2 = getRoot()
                    tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                    if not r2 or not tRoot then break end
                    dist = (r2.Position - tRoot.Position).Magnitude
                    hum:MoveTo(tRoot.Position)
                until dist <= 6 or tick() > timeout or not autoFlingActive
            end

            if not autoFlingActive then break end

            autoStatusLbl.Text = "💥 Флингаю " .. target.Name .. "!"
            flingTarget(target, function() return autoFlingActive end)
            task.wait(0.4)
        end
        autoStatusLbl.Text = "Выключено"
    end)
end

-- ════════════════════════════════════════════
--  LIST FLING LOOP
-- ════════════════════════════════════════════
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
                        listStatusLbl.Text = "💥 " .. name
                        flingTarget(p, function() return listFlinging end)
                        task.wait(0.3)
                    end
                end
            end
            if not any then
                listStatusLbl.Text = "Выбери цели ↑"
                task.wait(0.4)
            end
        end
        listStatusLbl.Text = "Остановлено"
    end)
end

-- ════════════════════════════════════════════
--  RESPAWN HANDLER
-- ════════════════════════════════════════════
player.CharacterAdded:Connect(function(char)
    character = char
    autoFlingActive = false
    listFlinging    = false
    if flyActive  then stopFly()   end
    if noclipActive then
        task.wait(0.3)
        startNoclip()
    end
    task.wait(0.2)
    if invisible  then applyInvis(char, true) end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = speedValue end
    setupKnockback(char)
    if espActive then
        task.wait(0.5)
        enableESP()
    end
end)

setupKnockback(character)

-- ════════════════════════════════════════════
--  GUI BUILDER
-- ════════════════════════════════════════════
-- Удаляем старый GUI если есть
if player.PlayerGui:FindFirstChild("JeezHub") then
    player.PlayerGui:FindFirstChild("JeezHub"):Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name             = "JeezHub"
gui.ResetOnSpawn     = false
gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
gui.Parent           = player.PlayerGui

-- ────────────── ГЛАВНЫЙ ФРЕЙМ ──────────────
local FULL_H  = 430
local MINI_H  = 38
local W       = 270

local frame = Instance.new("Frame")
frame.Name                  = "MainFrame"
frame.Size                  = UDim2.new(0, W, 0, FULL_H)
frame.Position              = UDim2.new(0.5, -W/2, 0.12, 0)
frame.BackgroundColor3      = Color3.fromRGB(9, 9, 16)
frame.BackgroundTransparency = 0.04
frame.Active                = true
frame.Draggable             = true
frame.BorderSizePixel       = 0
frame.ClipsDescendants      = true
frame.Parent                = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke", frame)
mainStroke.Color     = Color3.fromRGB(255, 50, 50)
mainStroke.Thickness = 2

-- ────────────── TITLE BAR ──────────────
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, MINI_H)
titleBar.BackgroundColor3 = Color3.fromRGB(18, 6, 6)
titleBar.BorderSizePixel  = 0
titleBar.ZIndex           = 10
titleBar.Parent           = frame

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)

-- Заглушка нижних углов заголовка
local titleFix = Instance.new("Frame")
titleFix.Size             = UDim2.new(1, 0, 0.5, 0)
titleFix.Position         = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = Color3.fromRGB(18, 6, 6)
titleFix.BorderSizePixel  = 0
titleFix.ZIndex           = 10
titleFix.Parent           = titleBar

-- Иконка + название
local titleIcon = Instance.new("TextLabel")
titleIcon.Size               = UDim2.new(0, 30, 1, 0)
titleIcon.Position           = UDim2.new(0, 8, 0, 0)
titleIcon.BackgroundTransparency = 1
titleIcon.Text               = "☠️"
titleIcon.TextSize           = 18
titleIcon.Font               = Enum.Font.GothamBold
titleIcon.ZIndex             = 11
titleIcon.Parent             = titleBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size               = UDim2.new(1, -90, 1, 0)
titleLbl.Position           = UDim2.new(0, 40, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text               = "JeezHub  v2.0"
titleLbl.TextColor3         = Color3.fromRGB(255, 80, 80)
titleLbl.TextSize           = 15
titleLbl.Font               = Enum.Font.GothamBold
titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
titleLbl.ZIndex             = 11
titleLbl.Parent             = titleBar

-- Кнопка свернуть
local minBtn = Instance.new("TextButton")
minBtn.Size             = UDim2.new(0, 28, 0, 22)
minBtn.Position         = UDim2.new(1, -62, 0.5, -11)
minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
minBtn.Text             = "─"
minBtn.TextColor3       = Color3.fromRGB(200, 200, 255)
minBtn.TextSize         = 14
minBtn.Font             = Enum.Font.GothamBold
minBtn.BorderSizePixel  = 0
minBtn.ZIndex           = 12
minBtn.Parent           = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- Кнопка закрыть
local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 28, 0, 22)
closeBtn.Position         = UDim2.new(1, -30, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
closeBtn.Text             = "✕"
closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize         = 13
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.BorderSizePixel  = 0
closeBtn.ZIndex           = 12
closeBtn.Parent           = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- ────────────── TABS ──────────────
local TAB_NAMES = {"🎯", "📋", "👁️", "🔧", "😈"}
local TAB_HINTS = {"Auto Fling", "Fling List", "ESP", "Tools", "Troll"}
local tabBtns   = {}
local tabPages  = {}

local tabBar = Instance.new("Frame")
tabBar.Size             = UDim2.new(1, -12, 0, 34)
tabBar.Position         = UDim2.new(0, 6, 0, MINI_H + 2)
tabBar.BackgroundColor3 = Color3.fromRGB(16, 16, 28)
tabBar.BorderSizePixel  = 0
tabBar.Parent           = frame
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)

local tabLL = Instance.new("UIListLayout")
tabLL.FillDirection = Enum.FillDirection.Horizontal
tabLL.SortOrder     = Enum.SortOrder.LayoutOrder
tabLL.Padding       = UDim.new(0, 3)
tabLL.Parent        = tabBar
Instance.new("UIPadding", tabBar).PaddingLeft = UDim.new(0, 3)

local PAGE_Y  = MINI_H + 38 + 4
local PAGE_H  = FULL_H - PAGE_Y - 6

for i, name in ipairs(TAB_NAMES) do
    local tb = Instance.new("TextButton")
    tb.Name             = "Tab" .. i
    tb.Size             = UDim2.new(0.195, -3, 1, -6)
    tb.BackgroundColor3 = Color3.fromRGB(26, 26, 42)
    tb.Text             = name
    tb.TextColor3       = Color3.fromRGB(140, 140, 180)
    tb.TextSize         = 16
    tb.Font             = Enum.Font.GothamBold
    tb.BorderSizePixel  = 0
    tb.LayoutOrder      = i
    tb.Parent           = tabBar
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 8)
    tabBtns[i] = tb

    local hint = Instance.new("TextLabel")
    hint.Size               = UDim2.new(0, 70, 0, 14)
    hint.Position           = UDim2.new(0.5, -35, 1, 2)
    hint.BackgroundTransparency = 1
    hint.Text               = TAB_HINTS[i]
    hint.TextColor3         = Color3.fromRGB(100, 100, 140)
    hint.TextSize           = 8
    hint.Font               = Enum.Font.Gotham
    hint.TextXAlignment     = Enum.TextXAlignment.Center
    hint.ZIndex             = 2
    hint.Parent             = tb

    local page = Instance.new("Frame")
    page.Name               = "Page" .. i
    page.Size               = UDim2.new(1, -12, 0, PAGE_H)
    page.Position           = UDim2.new(0, 6, 0, PAGE_Y)
    page.BackgroundTransparency = 1
    page.Visible            = (i == 1)
    page.BorderSizePixel    = 0
    page.Parent             = frame
    tabPages[i] = page
end

local currentTab = 1

local function switchTab(idx)
    currentTab = idx
    for i, tb in ipairs(tabBtns) do
        if i == idx then
            tb.BackgroundColor3 = Color3.fromRGB(150, 18, 18)
            tb.TextColor3       = Color3.fromRGB(255, 255, 255)
        else
            tb.BackgroundColor3 = Color3.fromRGB(26, 26, 42)
            tb.TextColor3       = Color3.fromRGB(140, 140, 180)
        end
        tabPages[i].Visible = (i == idx)
    end
end

-- ────────────── DRAG FIX HELPER ──────────────
local function safeBind(btn, cb)
    local ds, wd = nil, false
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then
            ds = i.Position wd = false
        end
    end)
    frame.InputChanged:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.Touch
        or  i.UserInputType == Enum.UserInputType.MouseMovement) and ds then
            if (Vector2.new(i.Position.X, i.Position.Y) - Vector2.new(ds.X, ds.Y)).Magnitude > 10 then
                wd = true
            end
        end
    end)
    btn.InputEnded:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.Touch
        and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if wd then return end
        cb()
    end)
end

-- Свернуть / развернуть
safeBind(minBtn, function()
    minimized = not minimized
    local targetH = minimized and MINI_H or FULL_H
    TweenService:Create(frame,
        TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, W, 0, targetH)}
    ):Play()
    minBtn.Text = minimized and "▲" or "─"
end)

-- Закрыть
safeBind(closeBtn, function()
    -- Выключаем всё
    autoFlingActive = false
    listFlinging    = false
    if flyActive    then stopFly()   end
    if noclipActive then stopNoclip() end
    if discoActive  then stopDisco() end
    if espActive    then disableESP() end
    if invisible    then applyInvis(getChar(), false) end
    local hum = getHum()
    if hum then hum.WalkSpeed = 16 end
    -- Анимация закрытия
    TweenService:Create(frame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quart),
        {BackgroundTransparency = 1, Size = UDim2.new(0, W, 0, 0)}
    ):Play()
    task.delay(0.25, function() safeDestroy(gui) end)
end)

for i in ipairs(TAB_NAMES) do
    safeBind(tabBtns[i], function() switchTab(i) end)
end

switchTab(1)

-- ════════════════════════════════════════════
--  TAB 1 — AUTO FLING
-- ════════════════════════════════════════════
local p1 = tabPages[1]

autoStatusLbl = Instance.new("TextLabel")
autoStatusLbl.Size               = UDim2.new(1, 0, 0, 24)
autoStatusLbl.Position           = UDim2.new(0, 0, 0, 2)
autoStatusLbl.BackgroundTransparency = 1
autoStatusLbl.Text               = "Выключено"
autoStatusLbl.TextColor3         = Color3.fromRGB(130, 130, 180)
autoStatusLbl.TextSize           = 12
autoStatusLbl.Font               = Enum.Font.Gotham
autoStatusLbl.TextXAlignment     = Enum.TextXAlignment.Center
autoStatusLbl.Parent             = p1

local autoBtn = Instance.new("TextButton")
autoBtn.Size             = UDim2.new(1, 0, 0, 56)
autoBtn.Position         = UDim2.new(0, 0, 0, 28)
autoBtn.BackgroundColor3 = Color3.fromRGB(120, 16, 16)
autoBtn.Text             = "🎯  AUTO FLING"
autoBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
autoBtn.TextSize         = 19
autoBtn.Font             = Enum.Font.GothamBold
autoBtn.BorderSizePixel  = 0
autoBtn.Parent           = p1
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 12)
local abStroke = Instance.new("UIStroke", autoBtn)
abStroke.Color = Color3.fromRGB(255, 70, 70) abStroke.Thickness = 1.5

local autoDesc = Instance.new("TextLabel")
autoDesc.Size               = UDim2.new(1, 0, 0, 55)
autoDesc.Position           = UDim2.new(0, 0, 0, 92)
autoDesc.BackgroundTransparency = 1
autoDesc.Text               = "Автоматически ходит к\nближайшему игроку и флингает.\nПовторяется до остановки."
autoDesc.TextColor3         = Color3.fromRGB(100, 100, 150)
autoDesc.TextSize           = 12
autoDesc.Font               = Enum.Font.Gotham
autoDesc.TextXAlignment     = Enum.TextXAlignment.Center
autoDesc.TextWrapped        = true
autoDesc.Parent             = p1

safeBind(autoBtn, function()
    if autoFlingActive then
        autoFlingActive = false
        autoBtn.Text             = "🎯  AUTO FLING"
        autoBtn.BackgroundColor3 = Color3.fromRGB(120, 16, 16)
        abStroke.Color           = Color3.fromRGB(255, 70, 70)
        mainStroke.Color         = Color3.fromRGB(255, 50, 50)
    else
        autoFlingActive = true
        autoBtn.Text             = "🛑  СТОП"
        autoBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        abStroke.Color           = Color3.fromRGB(255, 210, 40)
        mainStroke.Color         = Color3.fromRGB(255, 210, 40)
        autoFlingLoop()
    end
end)

-- ════════════════════════════════════════════
--  TAB 2 — LIST FLING
-- ════════════════════════════════════════════
local p2 = tabPages[2]

listStatusLbl = Instance.new("TextLabel")
listStatusLbl.Size               = UDim2.new(1, 0, 0, 20)
listStatusLbl.Position           = UDim2.new(0, 0, 0, 0)
listStatusLbl.BackgroundTransparency = 1
listStatusLbl.Text               = "Выбери цели"
listStatusLbl.TextColor3         = Color3.fromRGB(130, 130, 180)
listStatusLbl.TextSize           = 11
listStatusLbl.Font               = Enum.Font.Gotham
listStatusLbl.TextXAlignment     = Enum.TextXAlignment.Center
listStatusLbl.Parent             = p2

local scroll = Instance.new("ScrollingFrame")
scroll.Size                = UDim2.new(1, 0, 0, 185)
scroll.Position            = UDim2.new(0, 0, 0, 22)
scroll.BackgroundColor3    = Color3.fromRGB(14, 14, 24)
scroll.BorderSizePixel     = 0
scroll.ScrollBarThickness  = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 70, 70)
scroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent              = p2
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 10)
local lL = Instance.new("UIListLayout", scroll)
lL.Padding = UDim.new(0, 3) lL.SortOrder = Enum.SortOrder.Name
local lPad = Instance.new("UIPadding", scroll)
lPad.PaddingTop = UDim.new(0, 4) lPad.PaddingLeft = UDim.new(0, 4) lPad.PaddingRight = UDim.new(0, 4)

local playerBtns = {}

local function updateListStatus()
    local n = 0
    for _ in pairs(selectedTargets) do n = n + 1 end
    listStatusLbl.Text = listFlinging
        and ("☠️ Флингает " .. n .. " цел.")
        or  ("Выбрано: " .. n)
    listStatusLbl.TextColor3 = listFlinging
        and Color3.fromRGB(255, 70, 70)
        or  Color3.fromRGB(130, 130, 180)
end

local function makePlayerBtn(p)
    if p == player then return end
    if playerBtns[p.Name] then return end

    local row = Instance.new("TextButton")
    row.Name             = p.Name
    row.Size             = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
    row.Text             = "  👤  " .. p.Name
    row.TextColor3       = Color3.fromRGB(190, 200, 255)
    row.TextSize         = 12
    row.Font             = Enum.Font.GothamBold
    row.TextXAlignment   = Enum.TextXAlignment.Left
    row.BorderSizePixel  = 0
    row.Parent           = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local chk = Instance.new("TextLabel")
    chk.Size             = UDim2.new(0, 22, 0, 22)
    chk.Position         = UDim2.new(1, -26, 0.5, -11)
    chk.BackgroundColor3 = Color3.fromRGB(32, 32, 52)
    chk.Text             = ""
    chk.TextColor3       = Color3.fromRGB(80, 255, 100)
    chk.TextSize         = 13
    chk.Font             = Enum.Font.GothamBold
    chk.BorderSizePixel  = 0
    chk.Parent           = row
    Instance.new("UICorner", chk).CornerRadius = UDim.new(0, 6)

    playerBtns[p.Name] = {row = row, chk = chk}

    safeBind(row, function()
        if selectedTargets[p.Name] then
            selectedTargets[p.Name] = nil
            chk.Text             = ""
            chk.BackgroundColor3 = Color3.fromRGB(32, 32, 52)
            row.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
        else
            selectedTargets[p.Name] = p
            chk.Text             = "✓"
            chk.BackgroundColor3 = Color3.fromRGB(20, 65, 30)
            row.BackgroundColor3 = Color3.fromRGB(42, 16, 16)
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

-- Кнопки START/STOP и SELECT/DESELECT
local row1 = Instance.new("Frame")
row1.Size = UDim2.new(1,0,0,34) row1.Position = UDim2.new(0,0,0,212)
row1.BackgroundTransparency = 1 row1.BorderSizePixel = 0 row1.Parent = p2

local startLBtn = Instance.new("TextButton")
startLBtn.Size = UDim2.new(0.5,-3,1,0) startLBtn.BackgroundColor3 = Color3.fromRGB(18,85,25)
startLBtn.Text = "▶ START" startLBtn.TextColor3 = Color3.fromRGB(255,255,255)
startLBtn.TextSize = 13 startLBtn.Font = Enum.Font.GothamBold
startLBtn.BorderSizePixel = 0 startLBtn.Parent = row1
Instance.new("UICorner",startLBtn).CornerRadius = UDim.new(0,9)

local stopLBtn = Instance.new("TextButton")
stopLBtn.Size = UDim2.new(0.5,-3,1,0) stopLBtn.Position = UDim2.new(0.5,3,0,0)
stopLBtn.BackgroundColor3 = Color3.fromRGB(95,16,16)
stopLBtn.Text = "■ STOP" stopLBtn.TextColor3 = Color3.fromRGB(255,255,255)
stopLBtn.TextSize = 13 stopLBtn.Font = Enum.Font.GothamBold
stopLBtn.BorderSizePixel = 0 stopLBtn.Parent = row1
Instance.new("UICorner",stopLBtn).CornerRadius = UDim.new(0,9)

local row2 = Instance.new("Frame")
row2.Size = UDim2.new(1,0,0,28) row2.Position = UDim2.new(0,0,0,250)
row2.BackgroundTransparency = 1 row2.BorderSizePixel = 0 row2.Parent = p2

local selAllBtn = Instance.new("TextButton")
selAllBtn.Size = UDim2.new(0.5,-3,1,0) selAllBtn.BackgroundColor3 = Color3.fromRGB(25,25,46)
selAllBtn.Text = "✓ Все" selAllBtn.TextColor3 = Color3.fromRGB(170,170,255)
selAllBtn.TextSize = 12 selAllBtn.Font = Enum.Font.GothamBold
selAllBtn.BorderSizePixel = 0 selAllBtn.Parent = row2
Instance.new("UICorner",selAllBtn).CornerRadius = UDim.new(0,8)

local deselBtn = Instance.new("TextButton")
deselBtn.Size = UDim2.new(0.5,-3,1,0) deselBtn.Position = UDim2.new(0.5,3,0,0)
deselBtn.BackgroundColor3 = Color3.fromRGB(25,25,46)
deselBtn.Text = "✗ Сброс" deselBtn.TextColor3 = Color3.fromRGB(170,170,255)
deselBtn.TextSize = 12 deselBtn.Font = Enum.Font.GothamBold
deselBtn.BorderSizePixel = 0 deselBtn.Parent = row2
Instance.new("UICorner",deselBtn).CornerRadius = UDim.new(0,8)

safeBind(startLBtn, function()
    if listFlinging then return end
    local n = 0; for _ in pairs(selectedTargets) do n = n+1 end
    if n == 0 then listStatusLbl.Text = "⚠️ Выбери цели!" return end
    listFlinging = true; updateListStatus(); listFlingLoop()
end)
safeBind(stopLBtn, function() listFlinging = false; updateListStatus() end)
safeBind(selAllBtn, function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            selectedTargets[p.Name] = p
            local d = playerBtns[p.Name]
            if d then d.chk.Text="✓" d.chk.BackgroundColor3=Color3.fromRGB(20,65,30) d.row.BackgroundColor3=Color3.fromRGB(42,16,16) end
        end
    end; updateListStatus()
end)
safeBind(deselBtn, function()
    selectedTargets = {}
    for _, d in pairs(playerBtns) do
        d.chk.Text="" d.chk.BackgroundColor3=Color3.fromRGB(32,32,52) d.row.BackgroundColor3=Color3.fromRGB(22,22,36)
    end; updateListStatus()
end)

Players.PlayerAdded:Connect(function(p) makePlayerBtn(p) end)
Players.PlayerRemoving:Connect(function(p)
    selectedTargets[p.Name] = nil
    local d = playerBtns[p.Name]
    if d then safeDestroy(d.row) playerBtns[p.Name] = nil end
    updateListStatus()
end)

refreshList(); updateListStatus()

-- ════════════════════════════════════════════
--  TAB 3 — ESP
-- ════════════════════════════════════════════
local p3 = tabPages[3]

local espDesc = Instance.new("TextLabel")
espDesc.Size = UDim2.new(1,0,0,44) espDesc.Position = UDim2.new(0,0,0,4)
espDesc.BackgroundTransparency = 1
espDesc.Text = "Подсветка игроков сквозь стены.\nИмя меняет цвет по расстоянию:\n🔴 Близко  🟡 Средне  🔵 Далеко"
espDesc.TextColor3 = Color3.fromRGB(110,110,160) espDesc.TextSize = 11
espDesc.Font = Enum.Font.Gotham espDesc.TextXAlignment = Enum.TextXAlignment.Center
espDesc.TextWrapped = true espDesc.Parent = p3

local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(1,0,0,48) espBtn.Position = UDim2.new(0,0,0,52)
espBtn.BackgroundColor3 = Color3.fromRGB(20,20,55)
espBtn.Text = "👁️  ESP: OFF" espBtn.TextColor3 = Color3.fromRGB(180,180,255)
espBtn.TextSize = 16 espBtn.Font = Enum.Font.GothamBold
espBtn.BorderSizePixel = 0 espBtn.Parent = p3
Instance.new("UICorner",espBtn).CornerRadius = UDim.new(0,12)
local eStroke = Instance.new("UIStroke",espBtn)
eStroke.Color = Color3.fromRGB(80,80,200) eStroke.Thickness = 1.5

safeBind(espBtn, function()
    espActive = not espActive
    if espActive then
        enableESP()
        espBtn.Text = "👁️  ESP: ON"
        espBtn.BackgroundColor3 = Color3.fromRGB(18,18,100)
        eStroke.Color = Color3.fromRGB(120,120,255)
    else
        disableESP()
        espBtn.Text = "👁️  ESP: OFF"
        espBtn.BackgroundColor3 = Color3.fromRGB(20,20,55)
        eStroke.Color = Color3.fromRGB(80,80,200)
    end
end)

local espNote = Instance.new("TextLabel")
espNote.Size = UDim2.new(1,0,0,30) espNote.Position = UDim2.new(0,0,0,108)
espNote.BackgroundTransparency = 1
espNote.Text = "Виден только тебе (клиент)"
espNote.TextColor3 = Color3.fromRGB(80,80,110) espNote.TextSize = 11
espNote.Font = Enum.Font.Gotham espNote.TextXAlignment = Enum.TextXAlignment.Center
espNote.Parent = p3

-- ════════════════════════════════════════════
--  TAB 4 — TOOLS
-- ════════════════════════════════════════════
local p4 = tabPages[4]

-- Скорость
local spdLbl = Instance.new("TextLabel")
spdLbl.Size=UDim2.new(1,0,0,18) spdLbl.Position=UDim2.new(0,0,0,2)
spdLbl.BackgroundTransparency=1 spdLbl.Text="🏃 Скорость: "..speedValue
spdLbl.TextColor3=Color3.fromRGB(140,190,255) spdLbl.TextSize=12
spdLbl.Font=Enum.Font.GothamBold spdLbl.TextXAlignment=Enum.TextXAlignment.Left spdLbl.Parent=p4

local spdTrack = Instance.new("Frame")
spdTrack.Size=UDim2.new(1,0,0,11) spdTrack.Position=UDim2.new(0,0,0,22)
spdTrack.BackgroundColor3=Color3.fromRGB(22,22,38) spdTrack.BorderSizePixel=0 spdTrack.Parent=p4
Instance.new("UICorner",spdTrack).CornerRadius=UDim.new(1,0)

local SPD_MIN,SPD_MAX=0,250
local spdFill=Instance.new("Frame")
spdFill.Size=UDim2.new(speedValue/SPD_MAX,0,1,0) spdFill.BackgroundColor3=Color3.fromRGB(70,150,255)
spdFill.BorderSizePixel=0 spdFill.Parent=spdTrack
Instance.new("UICorner",spdFill).CornerRadius=UDim.new(1,0)

local spdKnob=Instance.new("TextButton")
spdKnob.Size=UDim2.new(0,22,0,22) spdKnob.Position=UDim2.new(speedValue/SPD_MAX,-11,0.5,-11)
spdKnob.BackgroundColor3=Color3.fromRGB(255,255,255) spdKnob.Text=""
spdKnob.BorderSizePixel=0 spdKnob.ZIndex=5 spdKnob.Parent=spdTrack
Instance.new("UICorner",spdKnob).CornerRadius=UDim.new(1,0)

local spdBtnRow=Instance.new("Frame")
spdBtnRow.Size=UDim2.new(1,0,0,26) spdBtnRow.Position=UDim2.new(0,0,0,37)
spdBtnRow.BackgroundTransparency=1 spdBtnRow.BorderSizePixel=0 spdBtnRow.Parent=p4
for i,pre in ipairs({{"🐢 16",16},{"⚡ 60",60},{"🚀 200",200}}) do
    local pb=Instance.new("TextButton")
    pb.Size=UDim2.new(0.33,-2,1,0) pb.Position=UDim2.new((i-1)*0.333,i>1 and 2 or 0,0,0)
    pb.BackgroundColor3=Color3.fromRGB(24,34,65) pb.Text=pre[1]
    pb.TextColor3=Color3.fromRGB(160,190,255) pb.TextSize=10 pb.Font=Enum.Font.GothamBold
    pb.BorderSizePixel=0 pb.Parent=spdBtnRow
    Instance.new("UICorner",pb).CornerRadius=UDim.new(0,7)
    local spd=pre[2]
    safeBind(pb,function()
        speedValue=spd
        local r=speedValue/SPD_MAX
        spdFill.Size=UDim2.new(r,0,1,0) spdKnob.Position=UDim2.new(r,-11,0.5,-11)
        spdLbl.Text="🏃 Скорость: "..speedValue
        local h=getHum(); if h then h.WalkSpeed=speedValue end
    end)
end

local spdDrag=false
spdKnob.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then spdDrag=true end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then spdDrag=false end
end)
UIS.InputChanged:Connect(function(i)
    if not spdDrag then return end
    if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseMovement then return end
    local r=math.clamp((i.Position.X-spdTrack.AbsolutePosition.X)/spdTrack.AbsoluteSize.X,0,1)
    speedValue=math.floor(SPD_MIN+r*(SPD_MAX-SPD_MIN))
    spdFill.Size=UDim2.new(r,0,1,0) spdKnob.Position=UDim2.new(r,-11,0.5,-11)
    spdLbl.Text="🏃 Скорость: "..speedValue
    local h=getHum(); if h then h.WalkSpeed=speedValue end
end)

-- Кнопки тулов
local function makeToggleBtn(parent, yPos, icon, label, onColor, offColor, strokeOn, strokeOff, onFn, offFn)
    local btn = Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,0,38) btn.Position=UDim2.new(0,0,0,yPos)
    btn.BackgroundColor3=offColor btn.Text=icon.."  "..label..": OFF"
    btn.TextColor3=Color3.fromRGB(210,210,255) btn.TextSize=13 btn.Font=Enum.Font.GothamBold
    btn.BorderSizePixel=0 btn.Parent=parent
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)
    local st=Instance.new("UIStroke",btn); st.Color=strokeOff; st.Thickness=1.5
    local state=false
    safeBind(btn,function()
        state=not state
        if state then
            btn.Text=icon.."  "..label..": ON"
            btn.BackgroundColor3=onColor; st.Color=strokeOn
            onFn()
        else
            btn.Text=icon.."  "..label..": OFF"
            btn.BackgroundColor3=offColor; st.Color=strokeOff
            offFn()
        end
    end)
    return btn, function() return state end
end

-- Невидимость
makeToggleBtn(p4, 68, "👁️", "НЕВИДИМОСТЬ",
    Color3.fromRGB(16,16,85), Color3.fromRGB(20,20,50),
    Color3.fromRGB(130,130,255), Color3.fromRGB(80,80,180),
    function() invisible=true;  applyInvis(getChar(),true)  end,
    function() invisible=false; applyInvis(getChar(),false) end
)

-- Нoclip
makeToggleBtn(p4, 110, "👻", "NOCLIP",
    Color3.fromRGB(14,65,65), Color3.fromRGB(16,45,45),
    Color3.fromRGB(60,220,220), Color3.fromRGB(40,140,140),
    function() noclipActive=true;  startNoclip() end,
    function() noclipActive=false; stopNoclip()  end
)

-- Полёт
makeToggleBtn(p4, 152, "🦅", "FLY",
    Color3.fromRGB(14,55,14), Color3.fromRGB(16,40,16),
    Color3.fromRGB(60,220,60), Color3.fromRGB(40,140,40),
    function() flyActive=true;  startFly() end,
    function() flyActive=false; stopFly()  end
)

-- Отбрасывание
makeToggleBtn(p4, 194, "💥", "KNOCKBACK",
    Color3.fromRGB(80,35,10), Color3.fromRGB(50,22,10),
    Color3.fromRGB(255,140,60), Color3.fromRGB(180,90,40),
    function() knockActive=true  end,
    function() knockActive=false end
)

-- ════════════════════════════════════════════
--  TAB 5 — TROLL
-- ════════════════════════════════════════════
local p5 = tabPages[5]

-- Дискотека
makeToggleBtn(p5, 4, "🪩", "DISCO",
    Color3.fromRGB(80,10,80), Color3.fromRGB(45,10,45),
    Color3.fromRGB(255,80,255), Color3.fromRGB(160,40,160),
    function() discoActive=true;  startDisco() end,
    function() discoActive=false; stopDisco()  end
)

-- Великан
local giantBtn = Instance.new("TextButton")
giantBtn.Size=UDim2.new(0.5,-3,0,38) giantBtn.Position=UDim2.new(0,0,0,46)
giantBtn.BackgroundColor3=Color3.fromRGB(50,20,70)
giantBtn.Text="🦕 ВЕЛИКАН" giantBtn.TextColor3=Color3.fromRGB(220,180,255)
giantBtn.TextSize=13 giantBtn.Font=Enum.Font.GothamBold
giantBtn.BorderSizePixel=0 giantBtn.Parent=p5
Instance.new("UICorner",giantBtn).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",giantBtn).Color=Color3.fromRGB(160,80,255)

local tinyBtn = Instance.new("TextButton")
tinyBtn.Size=UDim2.new(0.5,-3,0,38) tinyBtn.Position=UDim2.new(0.5,3,0,46)
tinyBtn.BackgroundColor3=Color3.fromRGB(40,40,15)
tinyBtn.Text="🐜 МАЛЫШ" tinyBtn.TextColor3=Color3.fromRGB(220,220,150)
tinyBtn.TextSize=13 tinyBtn.Font=Enum.Font.GothamBold
tinyBtn.BorderSizePixel=0 tinyBtn.Parent=p5
Instance.new("UICorner",tinyBtn).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",tinyBtn).Color=Color3.fromRGB(200,200,80)

local normBtn = Instance.new("TextButton")
normBtn.Size=UDim2.new(1,0,0,32) normBtn.Position=UDim2.new(0,0,0,88)
normBtn.BackgroundColor3=Color3.fromRGB(28,28,28)
normBtn.Text="↩  Нормальный размер" normBtn.TextColor3=Color3.fromRGB(180,180,180)
normBtn.TextSize=12 normBtn.Font=Enum.Font.GothamBold
normBtn.BorderSizePixel=0 normBtn.Parent=p5
Instance.new("UICorner",normBtn).CornerRadius=UDim.new(0,10)

safeBind(giantBtn, function() pcall(function() setSize(4)   end) end)
safeBind(tinyBtn,  function() pcall(function() setSize(0.3) end) end)
safeBind(normBtn,  function() pcall(function() setSize(0)   end) end)

-- Телепорт на спаун
local spawnBtn = Instance.new("TextButton")
spawnBtn.Size=UDim2.new(1,0,0,38) spawnBtn.Position=UDim2.new(0,0,0,126)
spawnBtn.BackgroundColor3=Color3.fromRGB(15,45,70)
spawnBtn.Text="🏠  ТЕЛЕПОРТ НА СПАУН" spawnBtn.TextColor3=Color3.fromRGB(120,200,255)
spawnBtn.TextSize=13 spawnBtn.Font=Enum.Font.GothamBold
spawnBtn.BorderSizePixel=0 spawnBtn.Parent=p5
Instance.new("UICorner",spawnBtn).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",spawnBtn).Color=Color3.fromRGB(60,160,255)

safeBind(spawnBtn, function()
    local root = getRoot()
    if not root then return end
    local spawn = workspace:FindFirstChild("SpawnLocation")
    if spawn then
        root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
    else
        root.CFrame = CFrame.new(0, 10, 0)
    end
    notify("Телепортирован на спаун!")
end)

-- Прыжок высоко
local jumpBtn = Instance.new("TextButton")
jumpBtn.Size=UDim2.new(1,0,0,38) jumpBtn.Position=UDim2.new(0,0,0,168)
jumpBtn.BackgroundColor3=Color3.fromRGB(15,60,30)
jumpBtn.Text="🚀  СУПЕРПРЫЖОК" jumpBtn.TextColor3=Color3.fromRGB(100,255,150)
jumpBtn.TextSize=13 jumpBtn.Font=Enum.Font.GothamBold
jumpBtn.BorderSizePixel=0 jumpBtn.Parent=p5
Instance.new("UICorner",jumpBtn).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",jumpBtn).Color=Color3.fromRGB(60,220,100)

safeBind(jumpBtn, function()
    local root = getRoot()
    local hum  = getHum()
    if not root or not hum then return end
    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.new(0, 250, 0)
    bv.MaxForce  = Vector3.new(0, 1e9, 0)
    bv.Parent    = root
    task.delay(0.15, function() safeDestroy(bv) end)
end)

-- ════════════════════════════════════════════
--  ФИНАЛ
-- ════════════════════════════════════════════
notify("JeezHub v2.0 загружен! ☠️")
print("╔══════════════════════════════╗")
print("║      JeezHub v2.0 Loaded     ║")
print("║  Auto Fling · ESP · Tools    ║")
print("╚══════════════════════════════╝")
