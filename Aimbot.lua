--[[
╔═══════════════════════════════════════════════════╗
║   INDONESIA TEST HUB v4.5 — ARSENAL TEAM-AWARE    ║
║   Dev: LIKA (DeepSeek) ♀                          ║
║   Fitur: Team Check (2-4 tim) + Prediction + ESP  ║
║   Support: R15 & R6 | Red/Blue/Green/Yellow       ║
║   UI Toggle: [RightShift]                         ║
╚═══════════════════════════════════════════════════╝
--]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ============================================================
-- CONFIG
-- ============================================================
local CFG = {
    aimEnabled       = false,
    espEnabled       = false,
    showFOV          = true,
    debugMode        = false,

    maxDistance      = 300,
    maxAngleDeg      = 60,
    aimSpeed         = 0.35,
    headOnly         = true,
    requireWallCheck = true,

    -- TEAM
    ignoreTeammates  = true,
    showTeammatesESP = true,

    fillColor        = Color3.fromRGB(0, 255, 100),
    healthBasedColor = true,
    espThroughWalls  = true,

    uiKey            = Enum.KeyCode.RightShift,
}

-- ============================================================
-- AIM TUNING
-- ============================================================
local AIM_TUNE = {
    prediction   = 0.15,
    snapAngleDeg = 3,
    snapDistance = 50,
    headOffset   = Vector3.new(0, 0, 0),
    rotateBody   = true,
    minLerp      = 0.5,
}

-- ============================================================
-- TEAM UTIL (ARSENAL-AWARE)
-- ============================================================
local TEAM_COLORS = {
    ReallyRed    = Color3.fromRGB(255, 60, 60),
    ReallyBlue   = Color3.fromRGB(60, 120, 255),
    LimeGreen    = Color3.fromRGB(60, 220, 60),
    NewYeller    = Color3.fromRGB(255, 220, 60),
    -- fallback nama lain
    Red          = Color3.fromRGB(255, 60, 60),
    Blue         = Color3.fromRGB(60, 120, 255),
    Green        = Color3.fromRGB(60, 220, 60),
    Yellow       = Color3.fromRGB(255, 220, 60),
}

-- Ambil warna team dari TeamColor atau nama
local function getTeamColor(team)
    if not team then return Color3.fromRGB(180, 180, 180) end
    -- Coba dari TeamColor dulu
    local c = team.TeamColor and team.TeamColor.Color
    if c and (c.R + c.G + c.B) > 0.05 then
        return c
    end
    -- Fallback: nama team
    return TEAM_COLORS[team.Name] or Color3.fromRGB(180, 180, 180)
end

-- Cek teammate
local function isTeammate(p)
    if not p or p == LocalPlayer then return false end
    if not LocalPlayer.Team then return false end  -- FFA
    if not p.Team then return false end
    return p.Team == LocalPlayer.Team
end

-- Cek mode tim saat ini
local function getTeamMode()
    if not LocalPlayer.Team then return "FFA" end
    local teams = {}
    local seen = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Team and not seen[p.Team] then
            seen[p.Team] = true
            table.insert(teams, p.Team.Name)
        end
    end
    return string.format("%d tim (%s)", #teams, table.concat(teams, "/"))
end

-- ============================================================
-- UTIL
-- ============================================================
local function isAlive(p)
    if not p or not p.Character then return false end
    local h = p.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0 or false
end

local function getHead(c)
    if not c then return nil end
    local h = c:FindFirstChild("Head")
    if h and h:IsA("BasePart") then return h end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") and d.Name == "Head" then return d end
    end
    return nil
end

local function getTorso(c)
    if not c then return nil end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum and hum.RigType == Enum.HumanoidRigType.R15 then
        return c:FindFirstChild("UpperTorso")
            or c:FindFirstChild("LowerTorso")
            or c:FindFirstChild("Torso")
    end
    return c:FindFirstChild("Torso")
end

local function hasLOS(fromPos, toPart, ignore)
    if not toPart then return false end
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = ignore or {}
    p.IgnoreWater = true
    local r = workspace:Raycast(fromPos, toPart.Position - fromPos, p)
    if not r then return true end
    if r.Instance == toPart then return true end
    local tChar = toPart.Parent
    if tChar and r.Instance:IsDescendantOf(tChar) then return true end
    if (r.Position - toPart.Position).Magnitude <= 0.8 then return true end
    return false
end

local function getIgnoreList()
    local l = { Camera }
    if LocalPlayer.Character then table.insert(l, LocalPlayer.Character) end
    return l
end

local function findTarget(camPos, lookVec, ignore)
    local closest, cDist = nil, CFG.maxDistance
    local cosMax = math.cos(math.rad(CFG.maxAngleDeg))

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if CFG.ignoreTeammates and isTeammate(p) then
                if CFG.debugMode then print("[AIM] SKIP", p.Name, "→ teammate") end
                continue
            end
            if not isAlive(p) then
                if CFG.debugMode then print("[AIM] SKIP", p.Name, "→ dead") end
                continue
            end
            local part = CFG.headOnly and getHead(p.Character) or getTorso(p.Character)
            if not part then
                if CFG.debugMode then print("[AIM] SKIP", p.Name, "→ no part") end
                continue
            end
            local off = part.Position - camPos
            local d = off.Magnitude
            if d >= cDist then
                if CFG.debugMode then print(string.format("[AIM] SKIP %s → far (%.0f)", p.Name, d)) end
                continue
            end
            local dot = off.Unit:Dot(lookVec)
            if dot < cosMax then
                if CFG.debugMode then
                    print(string.format("[AIM] SKIP %s → FOV (%.1f°)", p.Name,
                        math.deg(math.acos(math.clamp(dot, -1, 1)))))
                end
                continue
            end
            if CFG.requireWallCheck and not hasLOS(camPos, part, ignore) then
                if CFG.debugMode then print("[AIM] SKIP", p.Name, "→ wall") end
                continue
            end
            closest = { player = p, part = part }
            cDist = d
        end
    end
    return closest
end
-- ============================================================
-- ESP (TEAM-COLORED)
-- ============================================================
local highlights = {}

local function removeESP(p)
    if highlights[p] then
        pcall(function() highlights[p]:Destroy() end)
        highlights[p] = nil
    end
end

local function applyESP(p)
    if not p or p == LocalPlayer or not p.Character then return end
    if highlights[p] and highlights[p].Parent then return end

    local teammate = isTeammate(p)
    if teammate and not CFG.showTeammatesESP then return end

    -- Warna: teammate = warna tim, enemy = hijau default
    local baseColor = teammate and getTeamColor(p.Team) or CFG.fillColor

    local hl = Instance.new("Highlight")
    hl.Name = "TestESP"
    hl.Adornee = p.Character
    hl.FillColor = baseColor
    hl.FillTransparency = 0.65
    hl.OutlineColor = baseColor
    hl.OutlineTransparency = 0
    hl.DepthMode = CFG.espThroughWalls
        and Enum.HighlightDepthMode.AlwaysOnTop
        or  Enum.HighlightDepthMode.Occluded
    hl.Parent = p.Character
    hl:SetAttribute("IsTeammate", teammate)
    hl:SetAttribute("BaseColor", baseColor)
    highlights[p] = hl
end

local function clearESP()
    for p in pairs(highlights) do removeESP(p) end
end

local function refreshESP()
    if CFG.espEnabled then
        for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
    else
        clearESP()
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.8)
        if CFG.espEnabled then applyESP(p) end
    end)
    -- Deteksi kalau team berubah
    p:GetPropertyChangedSignal("Team"):Connect(function()
        if CFG.espEnabled then removeESP(p); applyESP(p) end
    end)
end)
Players.PlayerRemoving:Connect(removeESP)

for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then applyESP(p) end
    p.CharacterAdded:Connect(function()
        task.wait(0.8)
        if CFG.espEnabled then applyESP(p) end
    end)
    p:GetPropertyChangedSignal("Team"):Connect(function()
        if CFG.espEnabled then removeESP(p); applyESP(p) end
    end)
end

-- Update warna: teammate = warna tim fixed, enemy = health-based
RunService.Heartbeat:Connect(function()
    if not CFG.espEnabled or not CFG.healthBasedColor then return end
    for p, hl in pairs(highlights) do
        if not p.Parent or not hl or not hl.Parent then
            highlights[p] = nil
            continue
        end
        if hl:GetAttribute("IsTeammate") then
            local c = hl:GetAttribute("BaseColor") or getTeamColor(p.Team)
            hl.FillColor = c
            hl.OutlineColor = c
            continue
        end
        local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            local c = Color3.fromRGB(
                math.floor(255 * (1 - pct)),
                math.floor(255 * pct),
                50
            )
            hl.FillColor = c
            hl.OutlineColor = c
        end
    end
end)

-- ============================================================
-- FOV CIRCLE GUI
-- ============================================================
local parentGui = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

local oldFOV = parentGui:FindFirstChild("FOVGui")
if oldFOV then oldFOV:Destroy() end

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "FOVGui"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.DisplayOrder = 9999
FOVGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FOVGui.Parent = parentGui

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.Size = UDim2.new(0, 100, 0, 100)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.ZIndex = 2
FOVCircle.Visible = true
FOVCircle.Parent = FOVGui
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)

local fovStroke = Instance.new("UIStroke", FOVCircle)
fovStroke.Color = Color3.fromRGB(0, 255, 100)
fovStroke.Thickness = 2
fovStroke.Transparency = 0.4
fovStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.Size = UDim2.new(0, 6, 0, 6)
crosshair.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
crosshair.BorderSizePixel = 0
crosshair.ZIndex = 3
crosshair.Visible = true
crosshair.Parent = FOVGui
Instance.new("UICorner", crosshair).CornerRadius = UDim.new(1, 0)

local targetLbl = Instance.new("TextLabel")
targetLbl.Name = "TargetLbl"
targetLbl.AnchorPoint = Vector2.new(0.5, 0)
targetLbl.Position = UDim2.new(0.5, 0, 0.5, 30)
targetLbl.Size = UDim2.new(0, 250, 0, 18)
targetLbl.BackgroundTransparency = 1
targetLbl.Text = ""
targetLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
targetLbl.Font = Enum.Font.GothamBold
targetLbl.TextSize = 12
targetLbl.ZIndex = 3
targetLbl.Visible = false
targetLbl.Parent = FOVGui
-- ============================================================
-- MAIN LOOP v4.5 — TEAM-AWARE
-- ============================================================
local cameraLocked = false
local lastTarget   = nil
local debugCounter = 0

local function getBodyAlign(hrp)
    local align = hrp:FindFirstChild("AimBodyAlign")
    if align then return align end

    local att = hrp:FindFirstChild("RootAttachment")
    if not att then
        att = Instance.new("Attachment")
        att.Name = "AimRootAtt"
        att.Parent = hrp
    end

    align = Instance.new("AlignOrientation")
    align.Name           = "AimBodyAlign"
    align.Mode           = Enum.OrientationAlignmentMode.OneAttachment
    align.Attachment0    = att
    align.MaxTorque      = 20000
    align.Responsiveness = 60
    align.RigidityEnabled = false
    align.Parent         = hrp
    return align
end

local function cleanupBodyAlign()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local align = hrp:FindFirstChild("AimBodyAlign")
        if align then align:Destroy() end
    end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = true end
end

RunService.RenderStepped:Connect(function()
    if not CFG.aimEnabled then
        FOVCircle.Visible = true
        fovStroke.Transparency = 1.0
        crosshair.BackgroundTransparency = 1
        targetLbl.Visible = false
        cameraLocked = false
        lastTarget = nil
        cleanupBodyAlign()
        return
    end

    local viewport  = Camera.ViewportSize
    local camFovRad = math.rad(Camera.FieldOfView)
    local aimFovRad = math.rad(CFG.maxAngleDeg)
    local radius = (viewport.Y / 2) * math.tan(aimFovRad) / math.tan(camFovRad / 2)
    radius = math.clamp(radius, 20, viewport.Y * 1.5)

    FOVCircle.Visible = true
    FOVCircle.Size = UDim2.new(0, radius * 2, 0, radius * 2)
    crosshair.Visible = true
    crosshair.BackgroundTransparency = 0
    fovStroke.Transparency = CFG.showFOV and 0.4 or 1.0

    if not LocalPlayer.Character then return end

    local camPos  = Camera.CFrame.Position
    local lookVec = Camera.CFrame.LookVector
    local target  = findTarget(camPos, lookVec, getIgnoreList())

    if target and target.part then
        cameraLocked = true
        lastTarget   = target

        fovStroke.Color = Color3.fromRGB(255, 50, 50)
        if CFG.showFOV then fovStroke.Transparency = 0 end
        crosshair.BackgroundColor3 = Color3.fromRGB(255, 50, 50)

        -- Label: tandai kalau target teammate (harusnya nggak kejadian kalau ignoreTeammates ON)
        local tag = isTeammate(target.player) and " [TEAM]" or ""
        targetLbl.Text = "🎯 " .. target.player.Name .. tag
        targetLbl.Visible = true

        local targetPos = target.part.Position
        local targetVel = target.part.AssemblyLinearVelocity or Vector3.zero
        local horizontalVel = Vector3.new(targetVel.X, 0, targetVel.Z)
        local predictedPos = targetPos + horizontalVel * AIM_TUNE.prediction
        predictedPos = predictedPos + AIM_TUNE.headOffset

        local toTarget = predictedPos - camPos
        local distToTarget = toTarget.Magnitude
        local angleToTarget = math.deg(math.acos(
            math.clamp(Camera.CFrame.LookVector.Unit:Dot(toTarget.Unit), -1, 1)
        ))

        local isSnap = false
        if angleToTarget <= AIM_TUNE.snapAngleDeg then
            isSnap = true
        elseif distToTarget <= AIM_TUNE.snapDistance and angleToTarget <= 8 then
            isSnap = true
        end

        if isSnap then
            Camera.CFrame = CFrame.lookAt(camPos, predictedPos)
        else
            local baseLerp = math.max(CFG.aimSpeed, AIM_TUNE.minLerp)
            local distanceFactor = math.clamp(1 - (distToTarget / CFG.maxDistance), 0.3, 1)
            local lerpFactor = math.clamp(baseLerp * distanceFactor + 0.2, 0, 1)
            local lookCF = CFrame.lookAt(camPos, predictedPos)
            Camera.CFrame = Camera.CFrame:Lerp(lookCF, lerpFactor)
        end

        if AIM_TUNE.rotateBody then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                hum.AutoRotate = false
                local align = getBodyAlign(hrp)
                local myPos = hrp.Position
                local lookDir = Vector3.new(predictedPos.X - myPos.X, 0, predictedPos.Z - myPos.Z)
                if lookDir.Magnitude > 0.5 then
                    align.CFrame = CFrame.lookAt(Vector3.zero, lookDir.Unit)
                end
            end
        else
            cleanupBodyAlign()
        end
    else
        if cameraLocked then cameraLocked = false end
        fovStroke.Color = Color3.fromRGB(0, 255, 100)
        if CFG.showFOV then fovStroke.Transparency = 0.4 end
        crosshair.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        targetLbl.Visible = false
        cleanupBodyAlign()
    end

    debugCounter = debugCounter + 1
    if CFG.debugMode and debugCounter % 60 == 0 then
        print(string.format(
            "[FOV] radius=%.1f | FOV=%.0f° | visible=%s | trans=%.2f | mode=%s",
            radius, CFG.maxAngleDeg, tostring(FOVCircle.Visible),
            fovStroke.Transparency, getTeamMode()
        ))
    end
end)
-- ============================================================
-- UI PANEL
-- ============================================================
local SG = Instance.new("ScreenGui")
SG.Name = "TestHubUI"
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.DisplayOrder = 10000
SG.Parent = parentGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 760)
Main.Position = UDim2.new(0, 20, 0, 40)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Parent = SG
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(0, 200, 255)
stroke.Thickness = 2

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
Header.BorderSizePixel = 0
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔥 INDONESIA HUB v4.5"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 28, 0, 28)
HideBtn.Position = UDim2.new(1, -34, 0, 6)
HideBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 90)
HideBtn.Text = "—"
HideBtn.TextColor3 = Color3.new(1,1,1)
HideBtn.Font = Enum.Font.GothamBold
HideBtn.TextSize = 14
HideBtn.Parent = Header
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 6)

local Minimized = false
HideBtn.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    Main.Size = Minimized and UDim2.new(0, 320, 0, 40) or UDim2.new(0, 320, 0, 760)
    HideBtn.Text = Minimized and "＋" or "—"
end)

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -12, 1, -50)
Content.Position = UDim2.new(0, 6, 0, 46)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content
Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
end)

local function sectionLabel(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -4, 0, 22)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(120, 200, 255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = Content
end

local function toggleBtn(text, state, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 32)
    b.BackgroundColor3 = state and Color3.fromRGB(45, 100, 70) or Color3.fromRGB(35, 35, 48)
    b.Text = (state and "  🟢  " or "  ⚪  ") .. text
    b.TextColor3 = Color3.fromRGB(230, 230, 240)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.Parent = Content
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function()
        state = not state
        b.Text = (state and "  🟢  " or "  ⚪  ") .. text
        b.BackgroundColor3 = state and Color3.fromRGB(45, 100, 70) or Color3.fromRGB(35, 35, 48)
        callback(state)
    end)
    return b
end

local function slider(text, minVal, maxVal, curVal, step, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -4, 0, 46)
    holder.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    holder.BorderSizePixel = 0
    holder.Parent = Content
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.Position = UDim2.new(0, 8, 0, 3)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. tostring(curVal)
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    bar.BorderSizePixel = 0
    bar.Parent = holder
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((curVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = bar

    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = minVal + (maxVal - minVal) * rel
        val = math.floor(val / step + 0.5) * step
        val = math.clamp(val, minVal, maxVal)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text .. ": " .. tostring(val)
        callback(val)
    end

    btn.MouseButton1Down:Connect(function()
        dragging = true
        setFromX(UserInputService:GetMouseLocation().X)
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============ TEAM INDICATOR (live update) ============
sectionLabel("👥 TEAM STATUS")
local teamStatus = Instance.new("TextLabel")
teamStatus.Size = UDim2.new(1, -4, 0, 38)
teamStatus.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
teamStatus.BorderSizePixel = 0
teamStatus.Text = "Mode: ...\nTeam: ..."
teamStatus.TextColor3 = Color3.fromRGB(200, 220, 255)
teamStatus.Font = Enum.Font.GothamBold
teamStatus.TextSize = 11
teamStatus.TextXAlignment = Enum.TextXAlignment.Left
teamStatus.Parent = Content
Instance.new("UICorner", teamStatus).CornerRadius = UDim.new(0, 6)

task.spawn(function()
    while SG and SG.Parent do
        local mode = getTeamMode()
        local myTeamName = LocalPlayer.Team and LocalPlayer.Team.Name or "None (FFA)"
        local myColor = getTeamColor(LocalPlayer.Team)
        teamStatus.Text = string.format("  Mode: %s\n  Team: %s", mode, myTeamName)
        teamStatus.TextColor3 = myColor
        task.wait(2)
    end
end)

-- ============ SECTIONS ============
sectionLabel("⚔️ AIM ASSIST")
toggleBtn("Aimbot Enable", CFG.aimEnabled, function(on) CFG.aimEnabled = on end)
toggleBtn("Show FOV Circle", CFG.showFOV, function(on) CFG.showFOV = on end)
toggleBtn("Head Only", CFG.headOnly, function(on) CFG.headOnly = on end)
toggleBtn("Wall Check (LOS)", CFG.requireWallCheck, function(on) CFG.requireWallCheck = on end)
toggleBtn("Body Sync", AIM_TUNE.rotateBody, function(on) AIM_TUNE.rotateBody = on end)
toggleBtn("Debug Mode", CFG.debugMode, function(on) CFG.debugMode = on end)
slider("FOV Angle (°)", 5, 180, CFG.maxAngleDeg, 1, function(v) CFG.maxAngleDeg = v end)
slider("Max Distance", 50, 600, CFG.maxDistance, 10, function(v) CFG.maxDistance = v end)
slider("Smooth (0.01-1.0)", 1, 100, math.floor(CFG.aimSpeed * 100), 1, function(v)
    CFG.aimSpeed = v / 100
end)
slider("Prediction", 1, 40, math.floor(AIM_TUNE.prediction * 100), 1, function(v)
    AIM_TUNE.prediction = v / 100
end)

sectionLabel("👥 TEAM CHECK")
toggleBtn("Ignore Teammates (Aim)", CFG.ignoreTeammates, function(on)
    CFG.ignoreTeammates = on
end)
toggleBtn("Show Teammates ESP", CFG.showTeammatesESP, function(on)
    CFG.showTeammatesESP = on
    if CFG.espEnabled then clearESP(); refreshESP() end
end)

sectionLabel("👁️ ESP")
toggleBtn("ESP Enable", CFG.espEnabled, function(on)
    CFG.espEnabled = on
    refreshESP()
end)
toggleBtn("Through Walls", CFG.espThroughWalls, function(on)
    CFG.espThroughWalls = on
    if CFG.espEnabled then clearESP(); refreshESP() end
end)
toggleBtn("Health Color (Enemy)", CFG.healthBasedColor, function(on) CFG.healthBasedColor = on end)

sectionLabel("ℹ️ INFO")
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -4, 0, 70)
info.BackgroundTransparency = 1
info.Text = "Dev: LIKA ♀ | v4.5 TEAM\nESP teammate = warna tim\nESP enemy = health color\nUI toggle: RightShift"
info.TextColor3 = Color3.fromRGB(140, 140, 160)
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Parent = Content

-- ============ DRAG ============
local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ============ TOGGLE UI ============
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CFG.uiKey then
        Main.Visible = not Main.Visible
    end
end)

print("[INDONESIA HUB v4.5] Loaded ✅ | ARSENAL TEAM-AWARE | 4-part")
