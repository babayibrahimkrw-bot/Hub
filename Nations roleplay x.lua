--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk.
]]
-- Nations Roleplay X | Auto-Painter — real remote finder + painter
-- Runtime: Xeno
-- PART 1/3: Core logic
]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")
local Workspace  = game:GetService("Workspace")
local lp         = Players.LocalPlayer
local mouse      = lp:GetMouse()

-- ─── XOR decrypt ─────────────────────────────────────────────────────────────
local char, byte, sub = string.char, string.byte, string.sub
local bxor = (bit32 or bit).bxor
local concat, insert = table.concat, table.insert

local function xorDecrypt(p1, p2)
    local t1 = {}
    for i = 1, #p1 do
        insert(t1, char(bxor(byte(sub(p1,i,i+1)), byte(sub(p2, i % #p2 + 1, i % #p2 + 1 + 1))) % 256))
    end
    return concat(t1)
end

-- ─── Find real remote ─────────────────────────────────────────────────────────
local function getRealRemote(bucket)
    local remotes = bucket:WaitForChild("Remotes", 10)
    if not remotes then return nil end

    local n = 0
    repeat task.wait(0.1) ; n += 1
    until remotes:GetAttribute("RemotesReady") or n >= 100

    local attrName = xorDecrypt("\226\218\213&Ͽ", "~\177\163\187E\134ۧ")
    local remoteName = bucket:GetAttribute(attrName)

    if remoteName then
        local remote = remotes:FindFirstChild(remoteName)
        if remote then
            print("[olliE] real remote found:", remoteName)
            return remote
        end
    end

    print("[olliE] attribute decrypt failed, dumping all attributes:")
    for k, v in pairs(bucket:GetAttributes()) do
        print(" ", k, "=", tostring(v))
    end
    return nil
end

-- ─── State ────────────────────────────────────────────────────────────────────
local paintColor        = Color3.fromRGB(255, 255, 255)
local painting          = true
local safeMode          = false
local keepTerColor      = false
local selectingProvince = false
local removingProvince  = false
local selectingColor    = false
local provinces         = {}
local paintsThisSec     = 0
local realRemote        = nil
local autoRadius        = 5
local autoSelectEnabled = false

-- ─── Wait for bucket + find remote ───────────────────────────────────────────
task.spawn(function()
    local char = lp.Character or lp.CharacterAdded:Wait()
    local bucket = char:WaitForChild("PaintBucket", 15)
    if not bucket then
        print("[olliE] no PaintBucket found — equip it first")
        return
    end
    realRemote = getRealRemote(bucket)
    if realRemote then
        print("[olliE] ready to paint")
    else
        print("[olliE] could not find real remote — paste attribute dump above")
    end
end)

lp.CharacterAdded:Connect(function(newChar)
    realRemote = nil
    local bucket = newChar:WaitForChild("PaintBucket", 15)
    if bucket then
        realRemote = getRealRemote(bucket)
    end
end)

-- ─── Paint loop ───────────────────────────────────────────────────────────────
local function startPainting(province)
    for _, info in pairs(provinces) do
        if info.Province == province then return end
    end
    local savedColor = province.Color
    local active = true
    local event

    event = RunService.Stepped:Connect(function()
        if not active then return end
        if not painting then return end
        if not realRemote then return end
        local targetColor = keepTerColor and savedColor or paintColor
        if province.Color == targetColor then return end
        paintsThisSec += 1
        pcall(function()
            realRemote:InvokeServer(
                "PaintPart",
                {["Part"] = province, ["Color"] = targetColor},
                "Peace"
            )
        end)
        if safeMode then task.wait(1) end
    end)

    local sel = Instance.new("SelectionBox")
    sel.Adornee       = province
    sel.Color3        = paintColor
    sel.LineThickness = 0.05
    sel.Parent        = workspace

    table.insert(provinces, {
        Province  = province,
        Event     = event,
        Highlight = sel,
        Saved     = savedColor,
        Stop      = function() active = false end,
    })
end

local function removeProvince(province)
    for i, info in pairs(provinces) do
        if info.Province == province then
            info.Stop()
            info.Event:Disconnect()
            info.Highlight:Destroy()
            table.remove(provinces, i)
            return
        end
    end
end

local function clearAll()
    for _, info in pairs(provinces) do
        info.Stop()
        info.Event:Disconnect()
        info.Highlight:Destroy()
    end
    provinces = {}
end

local function setColor(c)
    paintColor = c
    for _, info in pairs(provinces) do
        info.Highlight.Color3 = c
    end
end
--[[
	PART 2/3: Auto-select radius + GUI shell
	(Paste LANGSUNG setelah Bagian 1, jangan ada kode lain di antaranya)
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- ─── AUTO SELECT RADIUS ────────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════════════════
local autoSelectThread = nil

local function getProvincesInRadius()
    local char = lp.Character
    if not char then return {} end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return {} end

    local found = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Province" then
            local dist = (obj.Position - root.Position).Magnitude
            if dist <= autoRadius then
                found[#found + 1] = { part = obj, dist = dist }
            end
        end
    end
    table.sort(found, function(a, b) return a.dist < b.dist end)
    return found
end

local function autoSelectOnce()
    local found = getProvincesInRadius()
    if #found == 0 then return 0 end
    local count = 0
    for _, data in ipairs(found) do
        local already = false
        for _, info in pairs(provinces) do
            if info.Province == data.part then already = true break end
        end
        if not already then
            startPainting(data.part)
            count = count + 1
        end
    end
    return count
end

local function startAutoSelectLoop()
    if autoSelectThread then return end
    autoSelectThread = task.spawn(function()
        while autoSelectEnabled do
            if realRemote and painting then
                autoSelectOnce()
            end
            task.wait(0.5)
        end
        autoSelectThread = nil
    end)
end

local function stopAutoSelectLoop()
    autoSelectEnabled = false
    if autoSelectThread then
        pcall(task.cancel, autoSelectThread)
        autoSelectThread = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ─── UI SHELL ──────────────────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name         = "NRXPainter"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent       = lp.PlayerGui

local THEME = {
    bg         = Color3.fromRGB(18, 18, 26),
    surface    = Color3.fromRGB(28, 28, 40),
    surfaceAlt = Color3.fromRGB(35, 35, 50),
    accent     = Color3.fromRGB(120, 100, 255),
    green      = Color3.fromRGB(53, 227, 153),
    red        = Color3.fromRGB(241, 33, 103),
    orange     = Color3.fromRGB(247, 168, 72),
    blue       = Color3.fromRGB(100, 160, 255),
    text       = Color3.fromRGB(240, 240, 250),
    textDim    = Color3.fromRGB(150, 150, 170),
    border     = Color3.fromRGB(50, 50, 70),
}

local main = Instance.new("Frame")
main.Size             = UDim2.new(0, 260, 0, 580)
main.Position         = UDim2.new(0, 20, 0.5, -290)
main.BackgroundColor3 = THEME.bg
main.BorderSizePixel  = 0
main.Parent           = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = THEME.border; mainStroke.Thickness = 1; mainStroke.Parent = main

local topbar = Instance.new("Frame")
topbar.Size             = UDim2.new(1, 0, 0, 42)
topbar.BackgroundColor3 = THEME.surface
topbar.BorderSizePixel  = 0
topbar.Parent           = main
Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 14)
local topbarMask = Instance.new("Frame")
topbarMask.Size = UDim2.new(1, 0, 0, 14)
topbarMask.Position = UDim2.new(0, 0, 1, -14)
topbarMask.BackgroundColor3 = THEME.surface
topbarMask.BorderSizePixel = 0
topbarMask.Parent = topbar

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 4, 0, 20)
accentBar.Position = UDim2.new(0, 14, 0.5, -10)
accentBar.BackgroundColor3 = THEME.accent
accentBar.BorderSizePixel = 0
accentBar.Parent = topbar
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

local title = Instance.new("TextLabel")
title.Size               = UDim2.new(1, -60, 1, 0)
title.Position           = UDim2.new(0, 24, 0, 0)
title.BackgroundTransparency = 1
title.Text               = "NRX Auto-Painter"
title.TextColor3         = THEME.text
title.TextSize           = 16
title.Font               = Enum.Font.GothamBold
title.TextXAlignment     = Enum.TextXAlignment.Left
title.Parent             = topbar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 22, 0, 22)
minimizeBtn.Position = UDim2.new(1, -30, 0.5, -11)
minimizeBtn.BackgroundColor3 = THEME.surfaceAlt
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = THEME.textDim
minimizeBtn.TextSize = 18
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.AutoButtonColor = false
minimizeBtn.Parent = topbar
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, 0, 1, -42)
content.Position = UDim2.new(0, 0, 0, 42)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = THEME.accent
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = main

local contentPad = Instance.new("UIPadding")
contentPad.PaddingTop = UDim.new(0, 12)
contentPad.PaddingBottom = UDim.new(0, 12)
contentPad.PaddingLeft = UDim.new(0, 14)
contentPad.PaddingRight = UDim.new(0, 14)
contentPad.Parent = content

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

-- Status card
local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, 0, 0, 64)
statusCard.BackgroundColor3 = THEME.surface
statusCard.BorderSizePixel = 0
statusCard.LayoutOrder = 1
statusCard.Parent = content
Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0, 10)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(0, 14, 0, 14)
statusDot.BackgroundColor3 = THEME.orange
statusDot.BorderSizePixel = 0
statusDot.Parent = statusCard
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -40, 0, 16)
statusLabel.Position = UDim2.new(0, 28, 0, 10)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "waiting for bucket..."
statusLabel.TextColor3 = THEME.text
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusCard

local ppsLabel = Instance.new("TextLabel")
ppsLabel.Size = UDim2.new(1, -40, 0, 14)
ppsLabel.Position = UDim2.new(0, 14, 0, 30)
ppsLabel.BackgroundTransparency = 1
ppsLabel.Text = "0 paint/sec | 0 provinces"
ppsLabel.TextColor3 = THEME.textDim
ppsLabel.TextSize = 11
ppsLabel.Font = Enum.Font.Gotham
ppsLabel.TextXAlignment = Enum.TextXAlignment.Left
ppsLabel.Parent = statusCard

local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(1, -40, 0, 14)
modeLabel.Position = UDim2.new(0, 14, 0, 44)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "mode: idle"
modeLabel.TextColor3 = THEME.textDim
modeLabel.TextSize = 11
modeLabel.Font = Enum.Font.Gotham
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Parent = statusCard
--[[
	PART 3/3: UI components + event handlers
	(Paste LANGSUNG setelah Bagian 2)
]]

-- Helpers
local function makeSectionHeader(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  " .. text
    lbl.TextColor3 = THEME.textDim
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = content
    return lbl
end

local function makeButton(label, color, callback, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.LayoutOrder = order or 0
    btn.Parent = content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.85
    stroke.Thickness = 1
    stroke.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenSvc:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = color:Lerp(Color3.fromRGB(255,255,255), 0.1)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenSvc:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = color }):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenSvc:Create(btn, TweenInfo.new(0.08), { Size = UDim2.new(1, 0, 0, 33) }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenSvc:Create(btn, TweenInfo.new(0.12), { Size = UDim2.new(1, 0, 0, 36) }):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function makeToggle(label, default, callback, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = THEME.surface
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 0
    row.Parent = content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = THEME.text
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 46, 0, 22)
    pill.Position = UDim2.new(1, -58, 0.5, -11)
    pill.BackgroundColor3 = default and THEME.green or THEME.red
    pill.BorderSizePixel = 0
    pill.Parent = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = default and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default
    row.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            TweenSvc:Create(pill, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                BackgroundColor3 = state and THEME.green or THEME.red
            }):Play()
            TweenSvc:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Position = state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
            }):Play()
            callback(state)
        end
    end)
    return row
end

-- ─── AUTO PAINT SECTION ────────────────────────────────────────────────────
makeSectionHeader("AUTO PAINT", 2)

local radiusRow = Instance.new("Frame")
radiusRow.Size = UDim2.new(1, 0, 0, 40)
radiusRow.BackgroundColor3 = THEME.surface
radiusRow.BorderSizePixel = 0
radiusRow.LayoutOrder = 3
radiusRow.Parent = content
Instance.new("UICorner", radiusRow).CornerRadius = UDim.new(0, 8)

local radiusLbl = Instance.new("TextLabel")
radiusLbl.Size = UDim2.new(0.5, -12, 1, 0)
radiusLbl.Position = UDim2.new(0, 12, 0, 0)
radiusLbl.BackgroundTransparency = 1
radiusLbl.Text = "Radius (stud)"
radiusLbl.TextColor3 = THEME.text
radiusLbl.TextSize = 12
radiusLbl.Font = Enum.Font.Gotham
radiusLbl.TextXAlignment = Enum.TextXAlignment.Left
radiusLbl.Parent = radiusRow

local radiusValue = Instance.new("TextLabel")
radiusValue.Size = UDim2.new(0, 40, 0, 26)
radiusValue.Position = UDim2.new(0.5, -60, 0.5, -13)
radiusValue.BackgroundColor3 = THEME.bg
radiusValue.Text = tostring(autoRadius)
radiusValue.TextColor3 = THEME.accent
radiusValue.TextSize = 13
radiusValue.Font = Enum.Font.GothamBold
radiusValue.Parent = radiusRow
Instance.new("UICorner", radiusValue).CornerRadius = UDim.new(0, 6)

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0, 26, 0, 26)
minusBtn.Position = UDim2.new(0.5, -14, 0.5, -13)
minusBtn.BackgroundColor3 = THEME.surfaceAlt
minusBtn.Text = "−"
minusBtn.TextColor3 = THEME.text
minusBtn.TextSize = 18
minusBtn.Font = Enum.Font.GothamBold
minusBtn.AutoButtonColor = false
minusBtn.Parent = radiusRow
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 6)

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0, 26, 0, 26)
plusBtn.Position = UDim2.new(0.5, 20, 0.5, -13)
plusBtn.BackgroundColor3 = THEME.surfaceAlt
plusBtn.Text = "+"
plusBtn.TextColor3 = THEME.text
plusBtn.TextSize = 18
plusBtn.Font = Enum.Font.GothamBold
plusBtn.AutoButtonColor = false
plusBtn.Parent = radiusRow
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 6)

minusBtn.MouseButton1Click:Connect(function()
    autoRadius = math.max(1, autoRadius - 1)
    radiusValue.Text = tostring(autoRadius)
end)
plusBtn.MouseButton1Click:Connect(function()
    autoRadius = math.min(50, autoRadius + 1)
    radiusValue.Text = tostring(autoRadius)
end)

makeButton("🎯  Auto Select Now", Color3.fromRGB(90, 70, 200), function()
    local count = autoSelectOnce()
    modeLabel.Text = string.format("auto-selected %d provinsi", count)
    modeLabel.TextColor3 = THEME.accent
end, 4)

makeToggle("Auto Select (Loop)", false, function(v)
    autoSelectEnabled = v
    if v then
        startAutoSelectLoop()
        modeLabel.Text = "auto-select loop ON"
        modeLabel.TextColor3 = THEME.green
    else
        stopAutoSelectLoop()
        modeLabel.Text = "auto-select loop OFF"
        modeLabel.TextColor3 = THEME.textDim
    end
end, 5)

-- ─── MANUAL ACTIONS ────────────────────────────────────────────────────────
makeSectionHeader("MANUAL ACTIONS", 6)

makeButton("＋  Select Provinces", Color3.fromRGB(35, 130, 80), function()
    selectingProvince=true; removingProvince=false; selectingColor=false
    modeLabel.Text="selecting — click provinces"
    modeLabel.TextColor3=THEME.green
end, 7)

makeButton("－  Remove Province", Color3.fromRGB(130, 45, 45), function()
    removingProvince=true; selectingProvince=false; selectingColor=false
    modeLabel.Text="removing — click provinces"
    modeLabel.TextColor3=Color3.fromRGB(255,120,120)
end, 8)

makeButton("💉  Eyedrop Color", Color3.fromRGB(70, 70, 130), function()
    selectingColor=true; selectingProvince=false; removingProvince=false
    modeLabel.Text="eyedrop — click a province"
    modeLabel.TextColor3=THEME.blue
end, 9)

makeButton("✓  Done", THEME.surfaceAlt, function()
    selectingProvince=false; removingProvince=false; selectingColor=false
    modeLabel.Text="mode: idle"
    modeLabel.TextColor3=THEME.textDim
end, 10)

makeButton("🗑  Clear All", Color3.fromRGB(100, 35, 35), function()
    clearAll()
    modeLabel.Text="mode: idle"
    modeLabel.TextColor3=THEME.textDim
end, 11)

-- ─── COLOR ─────────────────────────────────────────────────────────────────
makeSectionHeader("COLOR", 12)

local swatchCard = Instance.new("Frame")
swatchCard.Size = UDim2.new(1, 0, 0, 60)
swatchCard.BackgroundColor3 = THEME.surface
swatchCard.BorderSizePixel = 0
swatchCard.LayoutOrder = 13
swatchCard.Parent = content
Instance.new("UICorner", swatchCard).CornerRadius = UDim.new(0, 10)

local swatch = Instance.new("Frame")
swatch.Size = UDim2.new(1, -24, 0, 36)
swatch.Position = UDim2.new(0, 12, 0, 12)
swatch.BackgroundColor3 = paintColor
swatch.BorderSizePixel = 0
swatch.Parent = swatchCard
Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 8)
local swatchStroke = Instance.new("UIStroke")
swatchStroke.Color = Color3.fromRGB(255,255,255)
swatchStroke.Transparency = 0.7
swatchStroke.Thickness = 1
swatchStroke.Parent = swatch

local swatchLbl = Instance.new("TextLabel")
swatchLbl.Size = UDim2.new(1, 0, 1, 0)
swatchLbl.BackgroundTransparency = 1
swatchLbl.Text = "Color  ·  R random  ·  E eyedrop"
swatchLbl.TextColor3 = Color3.fromRGB(255,255,255)
swatchLbl.TextSize = 11
swatchLbl.Font = Enum.Font.GothamBold
swatchLbl.TextXAlignment = Enum.TextXAlignment.Center
swatchLbl.Parent = swatch

local rgbValues = {r=255, g=255, b=255}

local function updateFromRGB()
    local c = Color3.fromRGB(rgbValues.r, rgbValues.g, rgbValues.b)
    setColor(c)
    swatch.BackgroundColor3 = c
end

local sliderRefs = {}
local function makeSlider(labelText, key, colorTint, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundColor3 = THEME.surface
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    frame.Parent = content
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 16, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = colorTint
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -80, 0, 6)
    track.Position = UDim2.new(0, 30, 0.5, -3)
    track.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    track.BorderSizePixel = 0
    track.Parent = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(rgbValues[key]/255, 0, 1, 0)
    fill.BackgroundColor3 = colorTint
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 34, 1, 0)
    valLabel.Position = UDim2.new(1, -38, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(rgbValues[key])
    valLabel.TextColor3 = THEME.textDim
    valLabel.TextSize = 11
    valLabel.Font = Enum.Font.GothamBold
    valLabel.Parent = frame

    local sliding = false
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
    end)
    UserInput.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    UserInput.InputChanged:Connect(function(inp)
        if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            rgbValues[key] = math.floor(rel * 255)
            fill.Size     = UDim2.new(rel, 0, 1, 0)
            valLabel.Text = tostring(rgbValues[key])
            updateFromRGB()
        end
    end)

    sliderRefs[key] = { fill = fill, val = valLabel }
    return fill, valLabel
end

makeSlider("R", "r", Color3.fromRGB(255, 90, 90), 14)
makeSlider("G", "g", Color3.fromRGB(90, 255, 90), 15)
makeSlider("B", "b", Color3.fromRGB(90, 140, 255), 16)

-- ─── OPTIONS ───────────────────────────────────────────────────────────────
makeSectionHeader("OPTIONS", 17)

makeToggle("Toggle Paint",         true,  function(v) painting     = v end, 18)
makeToggle("Safe Mode (1s delay)", false, function(v) safeMode     = v end, 19)
makeToggle("Keep Territory Color", false, function(v) keepTerColor = v end, 20)

-- ─── Minimize ──────────────────────────────────────────────────────────────
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local targetSize = minimized and UDim2.new(0, 260, 0, 42) or UDim2.new(0, 260, 0, 580)
    TweenSvc:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
        Size = targetSize
    }):Play()
    minimizeBtn.Text = minimized and "+" or "−"
end)

-- ─── Dragging ──────────────────────────────────────────────────────────────
local dragging, dragStart, startPos
topbar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
       or inp.UserInputType == Enum.UserInputType.Touch then
        dragging=true; dragStart=inp.Position; startPos=main.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then dragging=false end
        end)
    end
end)
UserInput.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
                     or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)

-- ─── Status sync ──────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.5) do
        if realRemote then
            statusLabel.Text = "Remote locked ✓"
            statusLabel.TextColor3 = THEME.green
            statusDot.BackgroundColor3 = THEME.green
        else
            statusLabel.Text = "Waiting for bucket..."
            statusLabel.TextColor3 = THEME.orange
            statusDot.BackgroundColor3 = THEME.orange
        end
    end
end)

-- ─── Mouse click ──────────────────────────────────────────────────────────
local function syncSliders(c)
    local r,g,b = math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)
    rgbValues.r,rgbValues.g,rgbValues.b = r,g,b
    if sliderRefs.r then sliderRefs.r.fill.Size=UDim2.new(r/255,0,1,0); sliderRefs.r.val.Text=tostring(r) end
    if sliderRefs.g then sliderRefs.g.fill.Size=UDim2.new(g/255,0,1,0); sliderRefs.g.val.Text=tostring(g) end
    if sliderRefs.b then sliderRefs.b.fill.Size=UDim2.new(b/255,0,1,0); sliderRefs.b.val.Text=tostring(b) end
    swatch.BackgroundColor3=c
end

mouse.Button1Down:Connect(function()
    local t = mouse.Target
    if not t then return end
    if selectingColor and t.Name == "Province" then
        setColor(t.Color); syncSliders(t.Color)
        selectingColor=false
        modeLabel.Text="mode: idle"; modeLabel.TextColor3=THEME.textDim
        return
    end
    if t.Name ~= "Province" then return end
    if selectingProvince then startPainting(t) end
    if removingProvince  then removeProvince(t) end
end)

-- ─── Keybinds ─────────────────────────────────────────────────────────────
UserInput.InputBegan:Connect(function(inp, isTyping)
    if isTyping then return end
    if inp.KeyCode == Enum.KeyCode.R then
        local c = Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
        setColor(c); syncSliders(c)
    elseif inp.KeyCode == Enum.KeyCode.E then
        selectingColor=true; selectingProvince=false; removingProvince=false
        modeLabel.Text="eyedrop — click a province"
        modeLabel.TextColor3=THEME.blue
    elseif inp.KeyCode == Enum.KeyCode.Q then
        painting = not painting
    end
end)

-- ─── Stats loop ──────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(1) do
        ppsLabel.Text = paintsThisSec.." paint/sec  ·  "..#provinces.." provinces"
        ppsLabel.TextColor3 =
            paintsThisSec>=300 and Color3.fromRGB(235,8,10) or
            paintsThisSec>=100 and Color3.fromRGB(245,128,37) or
            paintsThisSec>=50  and Color3.fromRGB(247,226,112) or
            THEME.green
        paintsThisSec = 0
    end
end)

print("[NRX] Auto-Painter loaded — 3 parts OK")
