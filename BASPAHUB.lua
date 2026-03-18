-- =============================================
--           BASPA HUB - Semi Tp Script
-- =============================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CoreGui           = game:GetService("CoreGui")
local StarterGui        = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- =============================================
--              PLOT DETECTION
-- =============================================

local function getMyBaseSide()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local yourBase = sign:FindFirstChild("YourBase")
            if yourBase and yourBase.Enabled then
                return plot:GetPivot().Position.Z > 60 and "left" or "right"
            end
        end
    end
    return nil
end

-- =============================================
--              POSITIONS & CFRAMES
-- =============================================

local pos1 = Vector3.new(-352.98, -7, 74.30)
local pos2 = Vector3.new(-352.98, -6.49, 45.76)
local standing1 = Vector3.new(-336.36, -4.59, 99.51)
local standing2 = Vector3.new(-334.81, -4.59, 18.90)

local spot1_sequence = {
    CFrame.new(-416.66, -6.34, -2.05)   * CFrame.Angles(0, math.rad(-62.89), 0),
    CFrame.new(-329.37, -4.68, 18.12)   * CFrame.Angles(0, math.rad(-30.53), 0)
}
local spot2_sequence = {
    CFrame.new(-402.18, -6.34, 131.83)  * CFrame.Angles(0, math.rad(-20.08), 0),
    CFrame.new(-336.36, -4.59, 99.51)   * CFrame.Angles(0, math.rad(0),      0)
}

local autoTpLeftCF  = CFrame.new(-402.18, -6.34, 131.83) * CFrame.Angles(0, math.rad(-20.08), 0)
local autoTpRightCF = CFrame.new(-329.37, -4.68,  18.12) * CFrame.Angles(0, math.rad(-30.53), 0)

-- =============================================
--              ESP SYSTEM
-- =============================================

local function createESPBox(position, labelText)
    local folder = Instance.new("Folder")
    folder.Name = "ESP_" .. labelText
    folder.Parent = workspace

    local box = Instance.new("Part")
    box.Size = Vector3.new(5, 0.5, 5)
    box.Position = position
    box.Anchored = true
    box.CanCollide = false
    box.Transparency = 0.5
    box.Material = Enum.Material.Neon
    box.Color = Color3.fromRGB(200, 0, 0)
    box.Parent = folder

    local sel = Instance.new("SelectionBox")
    sel.Adornee = box
    sel.LineThickness = 0.05
    sel.Color3 = Color3.fromRGB(255, 50, 50)
    sel.Parent = box

    local bb = Instance.new("BillboardGui")
    bb.Adornee = box
    bb.Size = UDim2.new(0, 160, 0, 40)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = box

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
    lbl.TextSize = 16
    lbl.Font = Enum.Font.GothamBold
    lbl.TextStrokeTransparency = 0.3
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.Parent = bb

    return folder
end

local espFolders = {}

local function clearESP()
    for _, f in pairs(espFolders) do
        if f and f.Parent then f:Destroy() end
    end
    espFolders = {}
end

local function refreshESP()
    clearESP()
    local side = getMyBaseSide()
    if side == "left" then
        -- base kiri → ESP di sisi kanan (lawan)
        table.insert(espFolders, createESPBox(pos2,                   "Teleport Here"))
        table.insert(espFolders, createESPBox(standing2,              "Standing 2"))
        table.insert(espFolders, createESPBox(autoTpRightCF.Position, "Auto tp Right"))
    elseif side == "right" then
        -- base kanan → ESP di sisi kiri (lawan)
        table.insert(espFolders, createESPBox(pos1,                   "Teleport Here"))
        table.insert(espFolders, createESPBox(standing1,              "Standing 1"))
        table.insert(espFolders, createESPBox(autoTpLeftCF.Position,  "Auto tp Left"))
    else
        table.insert(espFolders, createESPBox(pos1,                  "Teleport Here"))
        table.insert(espFolders, createESPBox(pos2,                  "Teleport Here"))
        table.insert(espFolders, createESPBox(standing1,             "Standing 1"))
        table.insert(espFolders, createESPBox(standing2,             "Standing 2"))
        table.insert(espFolders, createESPBox(autoTpLeftCF.Position, "Auto tp Left"))
        table.insert(espFolders, createESPBox(autoTpRightCF.Position,"Auto tp Right"))
    end
end

task.spawn(function() task.wait(3) refreshESP() end)
player.CharacterAdded:Connect(function() task.wait(1) refreshESP() end)

-- =============================================
--              BLOCK SYSTEM (dari tp_fixed)
-- =============================================

local blockDelay   = 1.2
local minDelay     = 0.5
local maxDelay     = 8.0
local autoBlockEnabled = false

-- Click "Blokir" pada dialog block - Y lebih bawah dari center untuk HP
local function FastClick()
    task.wait(blockDelay)
    local cam = workspace.CurrentCamera.ViewportSize
    local x = cam.X / 2
    -- Dialog "Blokir" button ada di bawah center, ~58% dari tinggi layar
    local y = cam.Y * 0.58
    for _ = 1, 12 do
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true,  game, 1)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        task.wait(0.008)
    end
end

local function blockPlayer(plr)
    if not plr or plr == player then return end
    pcall(function() StarterGui:SetCore("PromptBlockPlayer", plr) end)
end

local backpackRef = player:WaitForChild("Backpack")
local charRef = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(c) charRef = c end)

local function checkForBrainrot()
    if not autoBlockEnabled then return false end
    for _, list in ipairs({backpackRef:GetChildren(), charRef:GetChildren()}) do
        for _, tool in ipairs(list) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("brainrot") or n:find("animal") or n:find("monkey")
                or n:find("dog") or n:find("cat") or n:find("bird") then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= player and plr.Character then
                            local bp = plr:FindFirstChild("Backpack")
                            if bp and not bp:FindFirstChild(tool.Name) then
                                blockPlayer(plr) FastClick() task.wait(0.25)
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

local function setupBrainrotDetection()
    checkForBrainrot()
    backpackRef.ChildAdded:Connect(function(c)
        if c:IsA("Tool") then task.wait(0.5) checkForBrainrot() end
    end)
    charRef.ChildAdded:Connect(function(c)
        if c:IsA("Tool") then task.wait(0.5) checkForBrainrot() end
    end)
    player.CharacterAdded:Connect(function(nc)
        charRef = nc
        nc.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then task.wait(0.5) checkForBrainrot() end
        end)
        task.wait(1) checkForBrainrot()
    end)
end

local function blockAllPlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            blockPlayer(plr) FastClick() task.wait(0.25)
        end
    end
end

-- blockPlayerEnabled = kalau true, setelah steal langsung block semua player
local blockPlayerEnabled = false

-- =============================================
--              STEAL SYSTEM
-- =============================================

local CONFIG = { ANTI_STEAL_ACTIVE = false }
local AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))

local allAnimalsCache   = {}
local PromptMemoryCache = {}
local InternalStealCache = {}
local IsStealing        = false
local StealProgress     = 0
local CurrentStealTarget = nil
local AUTO_STEAL_PROX_RADIUS = 200

local function getHRP()
    local c = player.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")
end

local function isMyBase(plotName)
    local plot = workspace.Plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    return sign and sign:FindFirstChild("YourBase") and sign.YourBase.Enabled
end

local function scanSinglePlot(plot)
    if not plot or not plot:IsA("Model") or isMyBase(plot.Name) then return end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return end
    for _, podium in ipairs(podiums:GetChildren()) do
        if podium:IsA("Model") and podium:FindFirstChild("Base") then
            table.insert(allAnimalsCache, {
                plot = plot.Name, slot = podium.Name,
                worldPosition = podium:GetPivot().Position,
                uid = plot.Name .. "_" .. podium.Name,
            })
        end
    end
end

local function initializeScanner()
    task.wait(2)
    local plots = workspace:WaitForChild("Plots", 10)
    for _, plot in ipairs(plots:GetChildren()) do scanSinglePlot(plot) end
    plots.ChildAdded:Connect(scanSinglePlot)
    task.spawn(function()
        while task.wait(5) do
            table.clear(allAnimalsCache)
            for _, plot in ipairs(plots:GetChildren()) do scanSinglePlot(plot) end
        end
    end)
end

local function findPrompt(animal)
    local cached = PromptMemoryCache[animal.uid]
    if cached and cached.Parent then return cached end
    local plot   = workspace.Plots:FindFirstChild(animal.plot)
    local podium = plot and plot.AnimalPodiums:FindFirstChild(animal.slot)
    local prompt = podium and podium.Base.Spawn.PromptAttachment:FindFirstChildOfClass("ProximityPrompt")
    if prompt then PromptMemoryCache[animal.uid] = prompt end
    return prompt
end

local function buildStealCallbacks(prompt)
    if InternalStealCache[prompt] then return end
    local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
    local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 then for _, c in ipairs(c1) do table.insert(data.holdCallbacks, c.Function) end end
    local ok2, c2 = pcall(getconnections, prompt.Triggered)
    if ok2 then for _, c in ipairs(c2) do table.insert(data.triggerCallbacks, c.Function) end end
    InternalStealCache[prompt] = data
end

local function autoEquipCarpet()
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local b = player:FindFirstChild("Backpack")
    if h and b then
        local carpet = b:FindFirstChild("Flying Carpet")
        if carpet then h:EquipTool(carpet) end
        task.wait(0.05)
    end
end

local function executeInternalStealAsync(prompt, animalData, useSpot2)
    local data = InternalStealCache[prompt]
    if not data or not data.ready or IsStealing then return end
    data.ready = false
    IsStealing = true
    StealProgress = 0
    CurrentStealTarget = animalData
    local tpDone = false
    task.spawn(function()
        for _, fn in ipairs(data.holdCallbacks) do task.spawn(fn) end
        local startTime = tick()
        while tick() - startTime < 1.3 do
            StealProgress = (tick() - startTime) / 1.3
            if StealProgress >= 0.73 and not tpDone then
                tpDone = true
                local hrp = getHRP()
                if hrp then
                    local seq = useSpot2 and spot2_sequence or spot1_sequence
                    hrp.CFrame = seq[1] task.wait(0.1)
                    hrp.CFrame = seq[2] task.wait(0.2)
                    local d1 = (hrp.Position - pos1).Magnitude
                    local d2 = (hrp.Position - pos2).Magnitude
                    hrp.CFrame = CFrame.new(d1 < d2 and pos1 or pos2)
                end
            end
            task.wait()
        end
        StealProgress = 1
        for _, fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end
        task.wait(0.2)
        data.ready = true
        IsStealing = false StealProgress = 0
        CurrentStealTarget = nil CONFIG.ANTI_STEAL_ACTIVE = false
    end)
end

local function getNearestAnimal()
    local hrp = getHRP()
    if not hrp then return nil end
    local nearest, dist = nil, math.huge
    for _, animal in ipairs(allAnimalsCache) do
        local d = (hrp.Position - animal.worldPosition).Magnitude
        if d < dist and d <= AUTO_STEAL_PROX_RADIUS then dist = d nearest = animal end
    end
    return nearest
end

-- =============================================
-- FULL FLOW: equip → TP ke lawan → steal → TP ke sini → block
-- =============================================

local function getTeleportHerePos()
    local side = getMyBaseSide()
    if side == "left" then return pos2 end  -- base kiri → kembali ke kanan
    return pos1                              -- base kanan → kembali ke kiri
end

local function doBlockAfterSteal()
    if not blockPlayerEnabled then return end
    task.spawn(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                blockPlayer(plr)
                task.wait(0.3)
                FastClick()
                task.wait(0.4)
            end
        end
    end)
end

local function executeFullFlow(useSpot2)
    task.spawn(function()
        -- 1. Equip carpet
        autoEquipCarpet()

        -- 2. TP ke sisi lawan via spot sequence
        local hrp = getHRP()
        if not hrp then return end
        local seq = useSpot2 and spot2_sequence or spot1_sequence
        hrp.CFrame = seq[1]
        task.wait(0.12)
        hrp.CFrame = seq[2]
        task.wait(0.2)

        -- 3. Cari brainrot pakai findNearestPrompt dari upang
        -- Naikin STEAL_RADIUS sementara biar detect dari jauh
        local oldRadius = STEAL_RADIUS
        STEAL_RADIUS = 200
        local prompt, _, name = findNearestPrompt()
        STEAL_RADIUS = oldRadius

        if prompt then
            -- TP ke posisi brainrotnya
            local plots = workspace:FindFirstChild("Plots")
            local spawnPos = nil
            pcall(function()
                for _, plot in ipairs(plots:GetChildren()) do
                    local pods = plot:FindFirstChild("AnimalPodiums")
                    if pods then
                        for _, pod in ipairs(pods:GetChildren()) do
                            local base = pod:FindFirstChild("Base")
                            local sp = base and base:FindFirstChild("Spawn")
                            if sp then
                                local att = sp:FindFirstChild("PromptAttachment")
                                if att then
                                    for _, ch in ipairs(att:GetChildren()) do
                                        if ch == prompt then spawnPos = sp.Position end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            if spawnPos then
                hrp = getHRP()
                if hrp then
                    hrp.CFrame = CFrame.new(spawnPos + Vector3.new(0, 3, 0))
                    task.wait(0.1)
                end
            end

            executeSteal(prompt, name)
            task.wait(STEAL_DURATION + 0.3)
        end

        -- 4. TP balik ke "Teleport Here"
        local hrp2 = getHRP()
        if hrp2 then
            hrp2.CFrame = CFrame.new(getTeleportHerePos())
        end

        -- 5. Block kalau auto block ON
        doBlockAfterSteal()
    end)
end

-- =============================================
--   AUTO STEAL (dari upang_script)
-- =============================================

local isStealing      = false
local autoStealEnabled = false
local autoStealConn   = nil
local StealData       = {}
local STEAL_RADIUS    = 9
local STEAL_DURATION  = 0.2

-- Circle indicator
local stealCirclePart = nil
local circleConn      = nil

local function buildCirclePart()
    if stealCirclePart then stealCirclePart:Destroy() stealCirclePart = nil end
    local p = Instance.new("Part")
    p.Name        = "BASPA_Circle"
    p.Anchored    = false
    p.CanCollide  = false
    p.CastShadow  = false
    p.CanQuery    = false
    p.CanTouch    = false
    p.Material    = Enum.Material.Neon
    p.Color       = Color3.fromRGB(255, 195, 0)
    p.Transparency = 0.4
    p.Shape       = Enum.PartType.Cylinder
    local d = STEAL_RADIUS * 2
    p.Size   = Vector3.new(0.12, d, d)
    p.Parent = workspace
    stealCirclePart = p
end

local function showStealCircle()
    buildCirclePart()
    if circleConn then circleConn:Disconnect() end
    circleConn = RunService.Heartbeat:Connect(function()
        if not stealCirclePart or not stealCirclePart.Parent then buildCirclePart() end
        if not stealCirclePart then return end
        local c = player.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        stealCirclePart.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 2.9, hrp.Position.Z)
                                * CFrame.Angles(0, 0, math.rad(90))
        stealCirclePart.Transparency = 0.3 + math.sin(tick() * 3) * 0.18
    end)
end

local function hideStealCircle()
    if circleConn then circleConn:Disconnect() circleConn = nil end
    if stealCirclePart then stealCirclePart:Destroy() stealCirclePart = nil end
end

-- Cari prompt dalam radius
local function findNearestPrompt()
    local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not h then return nil, nil, nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil, nil, nil end
    local np, nd, nn = nil, math.huge, nil
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyBase(plot.Name) then continue end
        local pods = plot:FindFirstChild("AnimalPodiums")
        if not pods then continue end
        for _, pod in ipairs(pods:GetChildren()) do
            pcall(function()
                local base  = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - h.Position).Magnitude
                    if dist < nd and dist <= STEAL_RADIUS then
                        local att = spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _, ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") then
                                    np, nd, nn = ch, dist, pod.Name break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    return np, nd, nn
end

-- Execute steal pakai getconnections (persis dari upang)
local function executeSteal(prompt, name)
    if isStealing then return end
    if not StealData[prompt] then
        StealData[prompt] = { hold = {}, trigger = {}, ready = true }
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(StealData[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(StealData[prompt].trigger, c.Function) end
                end
            end
        end)
    end
    local data = StealData[prompt]
    if not data.ready then return end
    data.ready = false
    isStealing = true

    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(f) end
        task.wait(STEAL_DURATION)
        for _, f in ipairs(data.trigger) do task.spawn(f) end
        data.ready = true
        isStealing = false
    end)
end

local function startAutoSteal()
    if autoStealConn then return end
    showStealCircle()
    autoStealConn = RunService.Heartbeat:Connect(function()
        if not autoStealEnabled or isStealing then return end
        local p, _, n = findNearestPrompt()
        if p then
            executeSteal(p, n)
            -- Block setelah steal kalau auto block ON
            task.spawn(function()
                task.wait(STEAL_DURATION + 0.3)
                doBlockAfterSteal()
            end)
        end
    end)
end

local function stopAutoSteal()
    if autoStealConn then autoStealConn:Disconnect() autoStealConn = nil end
    hideStealCircle()
    isStealing = false
end

local function executeTP(sequence)
    local c = player.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    local hum  = c and c:FindFirstChildOfClass("Humanoid")
    local bp   = player:FindFirstChild("Backpack")
    if root and hum and bp then
        local carpet = bp:FindFirstChild("Flying Carpet")
        if carpet then hum:EquipTool(carpet) end
        task.wait(0.05)
        root.CFrame = sequence[1] task.wait(0.1)
        root.CFrame = sequence[2]
    end
end

-- =============================================
--              RESET FLAGS
-- =============================================

-- =============================================
--              NEW GUI - BASPA HUB
-- =============================================

if CoreGui:FindFirstChild("BaspaHub") then CoreGui["BaspaHub"]:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BaspaHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = CoreGui

-- ── MAIN FRAME ────────────────────────────────
local W, H = 260, 620
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, W, 0, H)
mainFrame.Position = UDim2.new(1, -(W + 10), 0.5, -H/2)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Animated border
local borderStroke = Instance.new("UIStroke", mainFrame)
borderStroke.Thickness = 2
borderStroke.Color = Color3.fromRGB(200, 20, 20)

local borderGrad = Instance.new("UIGradient")
borderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 30, 30)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(80,  0,  0)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(255, 30, 30)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80,  0,  0)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 30, 30)),
})
borderGrad.Parent = borderStroke
task.spawn(function()
    while true do
        for i = 0, 360, 3 do
            borderGrad.Rotation = i
            task.wait(0.015)
        end
    end
end)

-- ── HEADER ────────────────────────────────────
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundColor3 = Color3.fromRGB(18, 5, 5)
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

-- fix bottom corners of header
local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 12)
headerFix.Position = UDim2.new(0, 0, 1, -12)
headerFix.BackgroundColor3 = Color3.fromRGB(18, 5, 5)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 32)
titleLabel.Position = UDim2.new(0, 0, 0, 6)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "BASPA HUB"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = header

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(1, 0, 0, 14)
subtitleLabel.Position = UDim2.new(0, 0, 0, 36)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Semi Tp • Duels"
subtitleLabel.TextColor3 = Color3.fromRGB(180, 50, 50)
subtitleLabel.TextSize = 10
subtitleLabel.Font = Enum.Font.GothamMedium
subtitleLabel.Parent = header

-- ── SCROLLABLE CONTENT ────────────────────────
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -52)
scrollFrame.Position = UDim2.new(0, 0, 0, 52)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 20, 20)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- auto sized
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainFrame

local contentPad = Instance.new("UIPadding")
contentPad.PaddingLeft = UDim.new(0, 10)
contentPad.PaddingRight = UDim.new(0, 10)
contentPad.PaddingTop = UDim.new(0, 8)
contentPad.PaddingBottom = UDim.new(0, 10)
contentPad.Parent = scrollFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 6)
contentLayout.Parent = scrollFrame

-- ── HELPERS ───────────────────────────────────

local function makeSection(labelText, order)
    local sect = Instance.new("TextLabel")
    sect.Size = UDim2.new(1, 0, 0, 18)
    sect.BackgroundTransparency = 1
    sect.Text = "  " .. labelText:upper()
    sect.TextColor3 = Color3.fromRGB(180, 30, 30)
    sect.TextSize = 10
    sect.Font = Enum.Font.GothamBold
    sect.TextXAlignment = Enum.TextXAlignment.Left
    sect.LayoutOrder = order
    sect.Parent = scrollFrame

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.BackgroundColor3 = Color3.fromRGB(60, 10, 10)
    line.BorderSizePixel = 0
    line.LayoutOrder = order + 1
    line.Parent = scrollFrame
end

local function makeToggle(labelText, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = scrollFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -54, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0, 40, 0, 22)
    track.Position = UDim2.new(1, -52, 0.5, -11)
    track.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    track.Text = ""
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(140, 140, 150)
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local active = false
    track.MouseButton1Click:Connect(function()
        active = not active
        local goal = active and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        local trackCol = active and Color3.fromRGB(160, 15, 15) or Color3.fromRGB(35, 35, 45)
        local knobCol  = active and Color3.fromRGB(255, 80, 80)  or Color3.fromRGB(140, 140, 150)
        TweenService:Create(knob,  TweenInfo.new(0.15), {Position = goal}):Play()
        TweenService:Create(track, TweenInfo.new(0.15), {BackgroundColor3 = trackCol}):Play()
        TweenService:Create(knob,  TweenInfo.new(0.15), {BackgroundColor3 = knobCol}):Play()
        callback(active)
    end)
end

local function makeButton(labelText, color, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = color
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = scrollFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    -- hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.new(
                math.min(color.R + 0.08, 1),
                math.min(color.G + 0.05, 1),
                math.min(color.B + 0.05, 1)
            )
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = color}):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ── PROGRESS BAR ──────────────────────────────
local function makeProgressBar(order)
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 0, 14)
    bg.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    bg.BorderSizePixel = 0
    bg.LayoutOrder = order
    bg.Parent = scrollFrame
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
    fill.BorderSizePixel = 0
    fill.Parent = bg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local pctLbl = Instance.new("TextLabel")
    pctLbl.Size = UDim2.new(1, 0, 1, 0)
    pctLbl.BackgroundTransparency = 1
    pctLbl.Text = "0%"
    pctLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    pctLbl.TextSize = 9
    pctLbl.Font = Enum.Font.GothamBold
    pctLbl.TextXAlignment = Enum.TextXAlignment.Right
    pctLbl.Parent = bg

    return fill, pctLbl
end

-- ── DROPDOWN ──────────────────────────────────
local function makeDropdown(order)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = true
    container.LayoutOrder = order
    container.Parent = scrollFrame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 34)
    btn.Text = "TP TO SPOT  ▼"
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, 76)
    list.Position = UDim2.new(0, 0, 0, 38)
    list.BackgroundTransparency = 1
    list.Parent = container

    local function makeItem(text, yPos, callback)
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, 0, 0, 32)
        item.Position = UDim2.new(0, 0, 0, yPos)
        item.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        item.Text = text
        item.TextColor3 = Color3.fromRGB(200, 200, 200)
        item.Font = Enum.Font.GothamMedium
        item.TextSize = 11
        item.BorderSizePixel = 0
        item.Parent = list
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 6)
        item.MouseButton1Click:Connect(callback)
    end

    makeItem("▸  TP TO SPOT 1",  0,  function() executeTP(spot1_sequence) end)
    makeItem("▸  TP TO SPOT 2", 36,  function() executeTP(spot2_sequence) end)

    local open = false
    btn.MouseButton1Click:Connect(function()
        open = not open
        btn.Text = open and "TP TO SPOT  ▲" or "TP TO SPOT  ▼"
        TweenService:Create(container, TweenInfo.new(0.2), {
            Size = open and UDim2.new(1, 0, 0, 114) or UDim2.new(1, 0, 0, 34)
        }):Play()
    end)

    return container
end

-- ── DELAY ROW ─────────────────────────────────
local function makeDelayRow(order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = scrollFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 50, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Delay"
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 60, 0, 22)
    box.Position = UDim2.new(0, 60, 0.5, -11)
    box.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    box.Text = tostring(blockDelay)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 11
    box.PlaceholderText = "0.1–5.0"
    box.PlaceholderColor3 = Color3.fromRGB(90, 90, 100)
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    local bs = Instance.new("UIStroke", box)
    bs.Color = Color3.fromRGB(50, 10, 10)

    local setBtn = Instance.new("TextButton")
    setBtn.Size = UDim2.new(0, 38, 0, 22)
    setBtn.Position = UDim2.new(0, 126, 0.5, -11)
    setBtn.BackgroundColor3 = Color3.fromRGB(130, 15, 15)
    setBtn.Text = "Set"
    setBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    setBtn.Font = Enum.Font.GothamBold
    setBtn.TextSize = 11
    setBtn.BorderSizePixel = 0
    setBtn.Parent = row
    Instance.new("UICorner", setBtn).CornerRadius = UDim.new(0, 5)

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(0, 70, 1, 0)
    statusLbl.Position = UDim2.new(0, 170, 0, 0)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = blockDelay.."s"
    statusLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
    statusLbl.TextSize = 10
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.Parent = row

    setBtn.MouseButton1Click:Connect(function()
        local n = tonumber(box.Text)
        if n then
            blockDelay = math.clamp(math.floor(n*100+0.5)/100, minDelay, maxDelay)
            box.Text = tostring(blockDelay)
            statusLbl.Text = blockDelay.."s"
        else
            box.Text = tostring(blockDelay)
        end
    end)
end

-- =============================================
--           BUILD GUI LAYOUT
-- =============================================

-- SECTION: BLOCK (order 20–29)
makeSection("Block", 20)

-- Auto Block = kalau ON, setelah steal otomatis block semua player (sama kayak Auto Block All tapi otomatis)
makeToggle("Auto Block", 22, function(s)
    blockPlayerEnabled = s
end)

makeDelayRow(23)

makeButton("⬛  Auto Block All", Color3.fromRGB(120, 10, 10), 24, function()
    task.spawn(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                blockPlayer(plr)
                task.wait(0.3)
                FastClick()
                task.wait(0.4)
            end
        end
    end)
end)

-- SECTION: TELEPORT (order 30–39)
makeSection("Teleport", 30)

-- Auto detect plot → tp ke sisi lawan → steal → balik → block
makeButton("⚡  Teleport (Plot Auto)", Color3.fromRGB(140, 15, 15), 31, function()
    local side = getMyBaseSide()
    -- base kiri → lawan di kanan = spot1 (Z kecil)
    -- base kanan → lawan di kiri = spot2 (Z besar)
    local useSpot2 = (side == "right")
    executeFullFlow(useSpot2)
end)

-- Manual kiri = TP ke sisi kiri (Z besar = spot2)
makeButton("◀  TP Left", Color3.fromRGB(30, 30, 45), 32, function()
    executeFullFlow(true)
end)

-- Manual kanan = TP ke sisi kanan (Z kecil = spot1)
makeButton("▶  TP Right", Color3.fromRGB(30, 30, 45), 33, function()
    executeFullFlow(false)
end)

-- SECTION: AUTO STEAL (order 40–49)
makeSection("Auto Steal", 40)

-- Grab only loop, no TP
makeToggle("Auto Steal (Grab Only)", 41, function(s)
    autoStealEnabled = s
    if s then startAutoSteal() else stopAutoSteal() end
end)

-- Progress bar
local fillBar, pctLabel = makeProgressBar(42)
task.spawn(function()
    while true do
        fillBar.Size = UDim2.new(math.clamp(StealProgress, 0, 1), 0, 1, 0)
        pctLabel.Text = math.floor(StealProgress * 100 + 0.5) .. "%"
        task.wait(0.02)
    end
end)

-- ── FOOTER ────────────────────────────────────
local footerLbl = Instance.new("TextLabel")
footerLbl.Size = UDim2.new(1, 0, 0, 16)
footerLbl.BackgroundTransparency = 1
footerLbl.Text = "discord.gg/vainshub"
footerLbl.TextColor3 = Color3.fromRGB(60, 20, 20)
footerLbl.TextSize = 9
footerLbl.Font = Enum.Font.Gotham
footerLbl.LayoutOrder = 99
footerLbl.Parent = scrollFrame

-- ── DRAG ──────────────────────────────────────
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- =============================================
--              INIT
-- =============================================

task.spawn(function() task.wait(1) ResetToWork() end)
initializeScanner()
setupBrainrotDetection()
