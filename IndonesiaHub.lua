-- ═══════════════════════════════════════════════
--      INDONESIA HUB | Lethal Ape
--      Version: 2.0 | indonesiahub.dev
--      Sambung semua 5 bagian lalu execute!
-- ═══════════════════════════════════════════════

-- [PART 1/5] Core + Data System

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

_G.IH = {}

-- CONFIG
_G.IH.Config = {
    Lang = "EN",
    Colors = {
        Accent    = Color3.fromRGB(139, 92, 246),
        Accent2   = Color3.fromRGB(168, 139, 250),
        BG        = Color3.fromRGB(18, 18, 24),
        Sidebar   = Color3.fromRGB(13, 13, 18),
        Surface   = Color3.fromRGB(28, 28, 36),
        Text      = Color3.fromRGB(240, 240, 240),
        Monster   = Color3.fromRGB(255, 60, 60),
        Player    = Color3.fromRGB(60, 150, 255),
        Item      = Color3.fromRGB(60, 255, 120),
    },
    ESP = {
        Monster = true,
        Player  = true,
        Item    = true,
        MaxDist = 500,
    },
    Player = {
        Fly        = false,
        FlySpeed   = 50,
        InfJump    = false,
        Noclip     = false,
        TpWalk     = false,
        TpWalkSpeed= 43,
        FOV        = 70,
    },
    Farm = {
        Active      = false,
        SelectedItem= "All",
        AutoSell    = true,
    },
}

-- LANGUAGE
_G.IH.L = {
    EN = {
        player="Player", visuals="Visuals", farm="Farm",
        settings="Settings", about="About",
        fly="Fly", flyspeed="Fly Speed", fov="FOV Changer",
        noclip="Noclip", infjump="Infinite Jump",
        tpwalk="TP Walk", tpspeed="TP Speed",
        esp_monster="Monster ESP", esp_player="Player ESP", esp_item="Item ESP",
        maxdist="Max Distance", farm_all="Farm All", farm_select="Farm Item",
        autosell="Auto Sell to Scrapper", color1="Accent Color",
        color2="Monster Color", color3="Player Color",
        color4="Item Color", color5="Text Color",
        language="Language", on="ON", off="OFF",
        about_text="Indonesia Hub v2.0\nLethal Ape Script\nBy: Indonesia Hub",
    },
    ID = {
        player="Pemain", visuals="Visual", farm="Farm",
        settings="Pengaturan", about="Tentang",
        fly="Terbang", flyspeed="Kecepatan Terbang", fov="Ubah FOV",
        noclip="Noclip", infjump="Lompat Tak Terbatas",
        tpwalk="TP Jalan", tpspeed="Kecepatan TP",
        esp_monster="ESP Monster", esp_player="ESP Pemain", esp_item="ESP Item",
        maxdist="Jarak Maksimal", farm_all="Farm Semua", farm_select="Pilih Item",
        autosell="Jual Otomatis ke Scrapper", color1="Warna Aksen",
        color2="Warna Monster", color3="Warna Pemain",
        color4="Warna Item", color5="Warna Teks",
        language="Bahasa", on="ON", off="OFF",
        about_text="Indonesia Hub v2.0\nScript Lethal Ape\nBy: Indonesia Hub",
    },
}

function _G.IH.T(k)
    return (_G.IH.L[_G.IH.Config.Lang] or _G.IH.L.EN)[k] or k
end

-- MONSTERS
_G.IH.Monsters = {
    "Renry","Lana","Rin","Billy","Noxar","Sandguy",
    "Fearful","Meat","Gooba","Lost","Lurker","Dus",
    "Kus","Bloodman","Gus","Scar","Ashy","Sandman",
    "John","Stalker"
}

-- ITEMS
_G.IH.Items = {
    {name="Gold",             price=2},
    {name="Meat",             price=3},
    {name="Iron",             price=2},
    {name="Crystal",          price=4},
    {name="Emerald",          price=10},
    {name="Ruby",             price=12},
    {name="Diamond",          price=7},
    {name="Red Gold",         price=150},
    {name="Copper",           price=1},
    {name="Irons",            price=6},
    {name="Crystalized Slime",price=3},
    {name="Amethyst Crystal", price=10},
    {name="Bone",             price=2},
    {name="Slime",            price=1},
    {name="Ancient Coin",     price=20},
    {name="Mystic Ore",       price=15},
    {name="Dark Crystal",     price=8},
    {name="Shadow Stone",     price=5},
}

print("[Indonesia Hub] Part 1/5 OK")
-- [PART 2/5] ESP System

_G.IH.ESPList = {}

local function clearESP()
    for _, v in pairs(_G.IH.ESPList) do
        pcall(function() v:Destroy() end)
    end
    _G.IH.ESPList = {}
end

local function getDist(part)
    local char = LP.Character
    if not char then return 9999 end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return 9999 end
    return math.floor((part.Position - root.Position).Magnitude)
end

local function makeESP(parent, name, color, sub)
    local bb = Instance.new("BillboardGui")
    bb.Name = "IH_ESP"
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 150, 0, 55)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.Parent = parent

    local bg = Instance.new("Frame")
    bg.BackgroundColor3 = Color3.fromRGB(10,10,15)
    bg.BackgroundTransparency = 0.3
    bg.Size = UDim2.new(1,0,1,0)
    bg.Parent = bb
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,6)

    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3

    local top = Instance.new("TextLabel", bg)
    top.BackgroundTransparency = 1
    top.Size = UDim2.new(1,0,0.55,0)
    top.Text = name
    top.TextColor3 = color
    top.TextStrokeTransparency = 0.5
    top.TextStrokeColor3 = Color3.new(0,0,0)
    top.TextScaled = true
    top.Font = Enum.Font.GothamBold

    local bot = Instance.new("TextLabel", bg)
    bot.Name = "Sub"
    bot.BackgroundTransparency = 1
    bot.Size = UDim2.new(1,0,0.45,0)
    bot.Position = UDim2.new(0,0,0.55,0)
    bot.Text = sub or ""
    bot.TextColor3 = Color3.fromRGB(200,200,200)
    bot.TextStrokeTransparency = 0.5
    bot.TextStrokeColor3 = Color3.new(0,0,0)
    bot.TextScaled = true
    bot.Font = Enum.Font.Gotham

    table.insert(_G.IH.ESPList, bb)
    return bb
end

local function runESP()
    clearESP()
    local cfg = _G.IH.Config.ESP
    local cols = _G.IH.Config.Colors

    -- Monster ESP
    if cfg.Monster then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                for _, mn in ipairs(_G.IH.Monsters) do
                    if obj.Name:lower():find(mn:lower()) then
                        local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildOfClass("Part")
                        local hum  = obj:FindFirstChildOfClass("Humanoid")
                        if root and not root:FindFirstChild("IH_ESP") then
                            local d  = getDist(root)
                            if d <= cfg.MaxDist then
                                local hp = hum and math.floor(hum.Health).."/"..math.floor(hum.MaxHealth) or "?"
                                makeESP(root,
                                    "👾 "..obj.Name,
                                    cols.Monster,
                                    string.format("HP:%s | %dm", hp, d)
                                )
                            end
                        end
                    end
                end
            end
        end
    end

    -- Player ESP
    if cfg.Player then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
                if root and not root:FindFirstChild("IH_ESP") then
                    local d  = getDist(root)
                    if d <= cfg.MaxDist then
                        local hp = hum and math.floor(hum.Health) or "?"
                        makeESP(root,
                            "👤 "..plr.Name,
                            cols.Player,
                            string.format("HP:%s | %dm", hp, d)
                        )
                    end
                end
            end
        end
    end

    -- Item ESP
    if cfg.Item then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                for _, item in ipairs(_G.IH.Items) do
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                    if part and obj.Name:lower():find(item.name:lower()) and not part:FindFirstChild("IH_ESP") then
                        local d = getDist(part)
                        if d <= cfg.MaxDist then
                            makeESP(part,
                                "💎 "..item.name,
                                cols.Item,
                                string.format("%dG | %dm", item.price, d)
                            )
                        end
                    end
                end
            end
        end
    end
end

-- ESP Loop tiap 1 detik biar ga lag
_G.IH.ESPConn = RunService.Heartbeat:Connect(function()
    if tick() % 1 < 0.016 then
        pcall(runESP)
    end
end)

print("[Indonesia Hub] Part 2/5 OK")
-- [PART 3/5] Player Mods + Farm System

-- ═══ FLY ═══
local flyConn, bv
local function startFly()
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    hum.PlatformStand = true
    bv = Instance.new("BodyVelocity", root)
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)

    flyConn = RunService.Heartbeat:Connect(function()
        if not _G.IH.Config.Player.Fly then
            startFly_stop(); return
        end
        local spd = _G.IH.Config.Player.FlySpeed
        local mv  = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then mv = mv - Vector3.new(0,1,0) end
        bv.Velocity = mv.Magnitude > 0 and mv.Unit * spd or Vector3.zero
    end)
end

function startFly_stop()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if bv then bv:Destroy(); bv = nil end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

-- ═══ INF JUMP ═══
local ijConn
local function startInfJump()
    ijConn = UserInputService.JumpRequest:Connect(function()
        if not _G.IH.Config.Player.InfJump then return end
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end
startInfJump()

-- ═══ NOCLIP ═══
local ncConn
local function startNoclip()
    ncConn = RunService.Stepped:Connect(function()
        if not _G.IH.Config.Player.Noclip then return end
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end
    end)
end
startNoclip()

-- ═══ TPWALK ═══
local tpConn
local function startTpWalk()
    local prevPos
    tpConn = RunService.Heartbeat:Connect(function()
        if not _G.IH.Config.Player.TpWalk then prevPos = nil; return end
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        if hum.MoveDirection.Magnitude > 0 then
            local spd = _G.IH.Config.Player.TpWalkSpeed
            root.CFrame = root.CFrame + hum.MoveDirection * spd * 0.016
        end
    end)
end
startTpWalk()

-- ═══ FOV ═══
function _G.IH.SetFOV(val)
    Camera.FieldOfView = val
    _G.IH.Config.Player.FOV = val
end

-- ═══ FARM SYSTEM ═══
_G.IH.FarmConn = nil

local function findScrapper()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("scrapper") or obj.Name:lower():find("sell") then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part then return part end
        end
    end
    return nil
end

local function tpTo(part)
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(part.Position + Vector3.new(0,3,0))
    end
end

local function collectItem(part)
    tpTo(part)
    task.wait(0.3)
    -- Touch trigger
    local char = LP.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            local touching = root:GetTouchingParts()
            for _, tp in ipairs(touching) do
                if tp == part then break end
            end
        end
    end
end

function _G.IH.StartFarm()
    if _G.IH.FarmConn then return end
    _G.IH.Config.Farm.Active = true
    _G.IH.FarmConn = task.spawn(function()
        while _G.IH.Config.Farm.Active do
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if not _G.IH.Config.Farm.Active then break end
                local isAll = _G.IH.Config.Farm.SelectedItem == "All"
                for _, item in ipairs(_G.IH.Items) do
                    if (isAll or _G.IH.Config.Farm.SelectedItem == item.name) then
                        local part = obj:IsA("BasePart") and obj or
                            (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
                        if part and obj.Name:lower():find(item.name:lower()) then
                            pcall(collectItem, part)
                            task.wait(0.2)
                        end
                    end
                end
            end
            -- Auto Sell
            if _G.IH.Config.Farm.AutoSell then
                local scrapper = findScrapper()
                if scrapper then
                    tpTo(scrapper)
                    task.wait(1)
                end
            end
            task.wait(0.5)
        end
    end)
end

function _G.IH.StopFarm()
    _G.IH.Config.Farm.Active = false
    _G.IH.FarmConn = nil
end

print("[Indonesia Hub] Part 3/5 OK")
-- [PART 4/5] GUI System

-- Destroy old GUI
pcall(function()
    if CoreGui:FindFirstChild("IndonesiaHub") then
        CoreGui.IndonesiaHub:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "IndonesiaHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ═══ HELPERS ═══
local function corner(parent, rad)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, rad or 8)
    return c
end

local function stroke(parent, color, thick, trans)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or Color3.fromRGB(60,60,70)
    s.Thickness = thick or 1
    s.Transparency = trans or 0.5
    return s
end

local function label(parent, text, size, color, font, pos, sz)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size or 14
    l.TextColor3 = color or Color3.fromRGB(240,240,240)
    l.Font = font or Enum.Font.GothamBold
    l.Position = pos or UDim2.new(0,0,0,0)
    l.Size = sz or UDim2.new(1,0,1,0)
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local function makeToggle(parent, yPos, labelText, state, callback)
    local row = Instance.new("Frame", parent)
    row.BackgroundTransparency = 1
    row.Position = UDim2.new(0,0,0,yPos)
    row.Size = UDim2.new(1,0,0,36)

    local lbl = label(row, labelText, 14, Color3.fromRGB(220,220,220), Enum.Font.Gotham,
        UDim2.new(0,12,0,0), UDim2.new(0.7,0,1,0))
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBG = Instance.new("Frame", row)
    toggleBG.Size = UDim2.new(0,46,0,24)
    toggleBG.Position = UDim2.new(1,-58,0.5,-12)
    toggleBG.BackgroundColor3 = state and Color3.fromRGB(139,92,246) or Color3.fromRGB(50,50,60)
    corner(toggleBG, 12)

    local toggleDot = Instance.new("Frame", toggleBG)
    toggleDot.Size = UDim2.new(0,18,0,18)
    toggleDot.Position = state and UDim2.new(0,25,0.5,-9) or UDim2.new(0,3,0.5,-9)
    toggleDot.BackgroundColor3 = Color3.fromRGB(255,255,255)
    corner(toggleDot, 9)

    local function updateVisual(s)
        TweenService:Create(toggleBG, TweenInfo.new(0.2), {
            BackgroundColor3 = s and Color3.fromRGB(139,92,246) or Color3.fromRGB(50,50,60)
        }):Play()
        TweenService:Create(toggleDot, TweenInfo.new(0.2), {
            Position = s and UDim2.new(0,25,0.5,-9) or UDim2.new(0,3,0.5,-9)
        }):Play()
    end

    local btn = Instance.new("TextButton", row)
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1,0,1,0)
    btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        state = not state
        updateVisual(state)
        callback(state)
    end)

    return row, function(s) state=s; updateVisual(s) end
end

local function makeSlider(parent, yPos, labelText, min, max, val, callback)
    local row = Instance.new("Frame", parent)
    row.BackgroundTransparency = 1
    row.Position = UDim2.new(0,0,0,yPos)
    row.Size = UDim2.new(1,0,0,46)

    label(row, labelText, 13, Color3.fromRGB(200,200,200), Enum.Font.Gotham,
        UDim2.new(0,12,0,0), UDim2.new(0.6,0,0,20))

    local valBox = Instance.new("TextBox", row)
    valBox.Size = UDim2.new(0,70,0,28)
    valBox.Position = UDim2.new(1,-82,0,9)
    valBox.BackgroundColor3 = Color3.fromRGB(28,28,36)
    valBox.TextColor3 = Color3.fromRGB(240,240,240)
    valBox.Text = tostring(val)
    valBox.TextSize = 14
    valBox.Font = Enum.Font.GothamBold
    valBox.ClearTextOnFocus = false
    corner(valBox, 6)
    stroke(valBox, Color3.fromRGB(80,60,120), 1, 0.3)

    local track = Instance.new("Frame", row)
    track.Position = UDim2.new(0,12,0,34)
    track.Size = UDim2.new(1,-94,0,4)
    track.BackgroundColor3 = Color3.fromRGB(40,40,50)
    corner(track, 2)

    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = Color3.fromRGB(139,92,246)
    fill.Size = UDim2.new((val-min)/(max-min),0,1,0)
    fill.BorderSizePixel = 0
    corner(fill, 2)

    local function setVal(v)
        v = math.clamp(math.floor(v), min, max)
        valBox.Text = tostring(v)
        fill.Size = UDim2.new((v-min)/(max-min),0,1,0)
        callback(v)
    end

    valBox.FocusLost:Connect(function()
        local n = tonumber(valBox.Text)
        if n then setVal(n) end
    end)

    local dragging = false
    local thumb = Instance.new("TextButton", track)
    thumb.Size = UDim2.new(0,14,0,14)
    thumb.Position = UDim2.new((val-min)/(max-min),- 7,0.5,-7)
    thumb.BackgroundColor3 = Color3.fromRGB(255,255,255)
    thumb.Text = ""
    corner(thumb, 7)

    thumb.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    RunService.Heartbeat:Connect(function()
        if dragging then
            local mp = UserInputService:GetMouseLocation()
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local pct = math.clamp((mp.X - abs.X)/sz.X, 0, 1)
            local v   = math.floor(min + pct*(max-min))
            thumb.Position = UDim2.new(pct,-7,0.5,-7)
            setVal(v)
        end
    end)

    return row
end

-- ═══ MAIN WINDOW ═══
local cfg = _G.IH.Config.Colors

local Main = Instance.new("Frame", ScreenGui)
Main.Name = "Main"
Main.Size = UDim2.new(0,560,0,420)
Main.Position = UDim2.new(0.5,-280,0.5,-210)
Main.BackgroundColor3 = cfg.BG
Main.BorderSizePixel = 0
corner(Main, 10)
stroke(Main, Color3.fromRGB(80,50,130), 1.5, 0.3)

-- Shadow
local shadow = Instance.new("Frame", Main)
shadow.Size = UDim2.new(1,20,1,20)
shadow.Position = UDim2.new(0,-10,0,-10)
shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
shadow.BackgroundTransparency = 0.5
shadow.ZIndex = -1
corner(shadow, 14)

-- Titlebar
local titleBar = Instance.new("Frame", Main)
titleBar.Size = UDim2.new(1,0,0,38)
titleBar.BackgroundColor3 = Color3.fromRGB(13,13,20)
titleBar.BorderSizePixel = 0
corner(titleBar, 10)

-- Fix bottom corner of titlebar
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1,0,0.5,0)
titleFix.Position = UDim2.new(0,0,0.5,0)
titleFix.BackgroundColor3 = Color3.fromRGB(13,13,20)
titleFix.BorderSizePixel = 0

-- Icon
local icon = Instance.new("Frame", titleBar)
icon.Size = UDim2.new(0,22,0,22)
icon.Position = UDim2.new(0,10,0.5,-11)
icon.BackgroundColor3 = Color3.fromRGB(139,92,246)
corner(icon, 6)
local iconL = Instance.new("TextLabel", icon)
iconL.Size = UDim2.new(1,0,1,0)
iconL.BackgroundTransparency = 1
iconL.Text = "IH"
iconL.TextColor3 = Color3.fromRGB(255,255,255)
iconL.TextSize = 10
iconL.Font = Enum.Font.GothamBold

-- Title
local titleL = label(titleBar, "Indonesia Hub", 14,
    Color3.fromRGB(220,210,255), Enum.Font.GothamBold,
    UDim2.new(0,40,0,0), UDim2.new(0.6,0,1,0))

-- Close btn
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0,24,0,24)
closeBtn.Position = UDim2.new(1,-30,0.5,-12)
closeBtn.BackgroundColor3 = Color3.fromRGB(220,60,60)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
corner(closeBtn, 6)
closeBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- Min btn
local minBtn = Instance.new("TextButton", titleBar)
minBtn.Size = UDim2.new(0,24,0,24)
minBtn.Position = UDim2.new(1,-58,0.5,-12)
minBtn.BackgroundColor3 = Color3.fromRGB(50,50,65)
minBtn.Text = "—"
minBtn.TextColor3 = Color3.fromRGB(200,200,200)
minBtn.TextSize = 12
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
corner(minBtn, 6)

-- Draggable
local dragging2, dragStart, startPos
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging2 = true
        dragStart = i.Position
        startPos  = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging2 and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging2 = false end
end)

-- ═══ SIDEBAR ═══
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0,160,1,-38)
Sidebar.Position = UDim2.new(0,0,0,38)
Sidebar.BackgroundColor3 = cfg.Sidebar
Sidebar.BorderSizePixel = 0

local SidebarFix = Instance.new("Frame", Sidebar)
SidebarFix.Size = UDim2.new(1,0,0,10)
SidebarFix.BackgroundColor3 = cfg.Sidebar
SidebarFix.BorderSizePixel = 0

local sideStroke = Instance.new("UIStroke", Sidebar)
sideStroke.Color = Color3.fromRGB(50,40,80)
sideStroke.Thickness = 1
sideStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- ═══ CONTENT AREA ═══
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1,-164,1,-42)
Content.Position = UDim2.new(0,162,0,40)
Content.BackgroundTransparency = 1

-- ═══ TABS ═══
local tabs = {}
local tabFrames = {}
local activeTab = nil

local tabDefs = {
    {id="player",  icon="👤", label=_G.IH.T("player")},
    {id="visuals", icon="👁️",  label=_G.IH.T("visuals")},
    {id="farm",    icon="🌾", label=_G.IH.T("farm")},
    {id="settings",icon="⚙️", label=_G.IH.T("settings")},
    {id="about",   icon="ℹ️",  label=_G.IH.T("about")},
}

local function switchTab(id)
    activeTab = id
    for tid, frame in pairs(tabFrames) do
        frame.Visible = tid == id
    end
    for tid, btn in pairs(tabs) do
        btn.BackgroundColor3 = tid == id
            and Color3.fromRGB(30,25,50)
            or Color3.fromRGB(0,0,0)
        btn.BackgroundTransparency = tid == id and 0 or 1
        local lbl = btn:FindFirstChildOfClass("TextLabel")
        if lbl then
            lbl.TextColor3 = tid == id
                and Color3.fromRGB(180,150,255)
                or Color3.fromRGB(130,130,145)
        end
    end
end

for i, t in ipairs(tabDefs) do
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1,-12,0,36)
    btn.Position = UDim2.new(0,6,0, 10 + (i-1)*40)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.BorderSizePixel = 0
    corner(btn, 7)

    local row = Instance.new("Frame", btn)
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1,0,1,0)

    local ico = Instance.new("TextLabel", row)
    ico.Size = UDim2.new(0,30,1,0)
    ico.Position = UDim2.new(0,8,0,0)
    ico.BackgroundTransparency = 1
    ico.Text = t.icon
    ico.TextSize = 16
    ico.Font = Enum.Font.GothamBold
    ico.TextColor3 = Color3.fromRGB(130,130,145)

    local lbl2 = Instance.new("TextLabel", row)
    lbl2.Size = UDim2.new(1,-42,1,0)
    lbl2.Position = UDim2.new(0,38,0,0)
    lbl2.BackgroundTransparency = 1
    lbl2.Text = t.label
    lbl2.TextSize = 13
    lbl2.Font = Enum.Font.GothamBold
    lbl2.TextColor3 = Color3.fromRGB(130,130,145)
    lbl2.TextXAlignment = Enum.TextXAlignment.Left

    local frame = Instance.new("ScrollingFrame", Content)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 3
    frame.ScrollBarImageColor3 = Color3.fromRGB(100,80,160)
    frame.CanvasSize = UDim2.new(0,0,0,400)
    frame.Visible = false

    tabs[t.id] = btn
    tabFrames[t.id] = frame

    btn.MouseButton1Click:Connect(function() switchTab(t.id) end)
end

_G.IH.TabFrames = tabFrames
_G.IH.SwitchTab = switchTab
switchTab("player")

print("[Indonesia Hub] Part 4/5 OK")
-- [PART 5/5] Tab Content + Finalize

local TF = _G.IH.TabFrames
local cfg = _G.IH.Config

-- ═══ PLAYER TAB ═══
local pf = TF.player
local py = 8

makeToggle(pf, py, "Fly", cfg.Player.Fly, function(s)
    cfg.Player.Fly = s
    if s then _G.IH.startFly and _G.IH.startFly() or startFly()
    else startFly_stop() end
end); py = py + 42

makeSlider(pf, py, "Fly Speed", 10, 200, cfg.Player.FlySpeed, function(v)
    cfg.Player.FlySpeed = v
end); py = py + 52

makeSlider(pf, py, "FOV Changer", 50, 120, cfg.Player.FOV, function(v)
    _G.IH.SetFOV(v)
end); py = py + 52

makeToggle(pf, py, "Noclip", cfg.Player.Noclip, function(s)
    cfg.Player.Noclip = s
end); py = py + 42

makeToggle(pf, py, "Infinite Jump", cfg.Player.InfJump, function(s)
    cfg.Player.InfJump = s
end); py = py + 42

makeToggle(pf, py, "TP Walk", cfg.Player.TpWalk, function(s)
    cfg.Player.TpWalk = s
end); py = py + 42

makeSlider(pf, py, "TP Speed", 10, 200, cfg.Player.TpWalkSpeed, function(v)
    cfg.Player.TpWalkSpeed = v
end); py = py + 52
pf.CanvasSize = UDim2.new(0,0,0,py+10)

-- ═══ VISUALS TAB (ESP) ═══
local vf = TF.visuals
local vy = 8

makeToggle(vf, vy, "Monster ESP", cfg.ESP.Monster, function(s)
    cfg.ESP.Monster = s
end); vy = vy + 42

makeToggle(vf, vy, "Player ESP", cfg.ESP.Player, function(s)
    cfg.ESP.Player = s
end); vy = vy + 42

makeToggle(vf, vy, "Item ESP", cfg.ESP.Item, function(s)
    cfg.ESP.Item = s
end); vy = vy + 42

makeSlider(vf, vy, "Max Distance", 50, 1000, cfg.ESP.MaxDist, function(v)
    cfg.ESP.MaxDist = v
end); vy = vy + 52
vf.CanvasSize = UDim2.new(0,0,0,vy+10)

-- ═══ FARM TAB ═══
local ff = TF.farm
local fy = 8

-- Farm All toggle
makeToggle(ff, fy, "Farm All Items", cfg.Farm.SelectedItem == "All", function(s)
    cfg.Farm.SelectedItem = s and "All" or _G.IH.Items[1].name
end); fy = fy + 42

-- Farm toggle
makeToggle(ff, fy, "Start Farm", cfg.Farm.Active, function(s)
    if s then _G.IH.StartFarm() else _G.IH.StopFarm() end
end); fy = fy + 42

-- Auto sell
makeToggle(ff, fy, "Auto Sell (Scrapper)", cfg.Farm.AutoSell, function(s)
    cfg.Farm.AutoSell = s
end); fy = fy + 42

-- Item picker label
local itemLbl = Instance.new("TextLabel", ff)
itemLbl.Position = UDim2.new(0,12,0,fy)
itemLbl.Size = UDim2.new(1,-24,0,20)
itemLbl.BackgroundTransparency = 1
itemLbl.Text = "Select Item:"
itemLbl.TextColor3 = Color3.fromRGB(180,180,200)
itemLbl.TextSize = 13
itemLbl.Font = Enum.Font.GothamBold
itemLbl.TextXAlignment = Enum.TextXAlignment.Left
fy = fy + 24

-- Item buttons
local itemGrid = Instance.new("Frame", ff)
itemGrid.Position = UDim2.new(0,10,0,fy)
itemGrid.Size = UDim2.new(1,-20,0,1)
itemGrid.BackgroundTransparency = 1

local uiGrid = Instance.new("UIGridLayout", itemGrid)
uiGrid.CellSize = UDim2.new(0,110,0,28)
uiGrid.CellPadding = UDim2.new(0,6,0,6)
uiGrid.SortOrder = Enum.SortOrder.LayoutOrder

for i, item in ipairs(_G.IH.Items) do
    local btn = Instance.new("TextButton", itemGrid)
    btn.Size = UDim2.new(0,110,0,28)
    btn.BackgroundColor3 = cfg.Farm.SelectedItem == item.name
        and Color3.fromRGB(80,50,130)
        or Color3.fromRGB(28,28,38)
    btn.Text = item.name
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    btn.TextSize = 11
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    corner(btn, 6)
    stroke(btn, Color3.fromRGB(60,50,90), 1, 0.5)
    btn.MouseButton1Click:Connect(function()
        cfg.Farm.SelectedItem = item.name
        for _, b in ipairs(itemGrid:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = b.Text == item.name
                    and Color3.fromRGB(80,50,130)
                    or Color3.fromRGB(28,28,38)
            end
        end
    end)
end

local gridH = math.ceil(#_G.IH.Items/3) * 34 + 10
itemGrid.Size = UDim2.new(1,-20,0,gridH)
fy = fy + gridH + 10
ff.CanvasSize = UDim2.new(0,0,0,fy)

-- ═══ SETTINGS TAB ═══
local sf = TF.settings
local sy = 8

-- Language
local langRow = Instance.new("Frame", sf)
langRow.Position = UDim2.new(0,0,0,sy)
langRow.Size = UDim2.new(1,0,0,36)
langRow.BackgroundTransparency = 1

local langLbl = label(langRow, "Language / Bahasa", 13,
    Color3.fromRGB(200,200,200), Enum.Font.Gotham,
    UDim2.new(0,12,0,0), UDim2.new(0.6,0,1,0))

local enBtn = Instance.new("TextButton", langRow)
enBtn.Size = UDim2.new(0,50,0,26)
enBtn.Position = UDim2.new(1,-112,0.5,-13)
enBtn.BackgroundColor3 = cfg.Lang == "EN"
    and Color3.fromRGB(100,60,180) or Color3.fromRGB(30,30,42)
enBtn.Text = "EN"
enBtn.TextColor3 = Color3.fromRGB(255,255,255)
enBtn.TextSize = 12
enBtn.Font = Enum.Font.GothamBold
enBtn.BorderSizePixel = 0
corner(enBtn, 6)

local idBtn = Instance.new("TextButton", langRow)
idBtn.Size = UDim2.new(0,50,0,26)
idBtn.Position = UDim2.new(1,-58,0.5,-13)
idBtn.BackgroundColor3 = cfg.Lang == "ID"
    and Color3.fromRGB(100,60,180) or Color3.fromRGB(30,30,42)
idBtn.Text = "ID"
idBtn.TextColor3 = Color3.fromRGB(255,255,255)
idBtn.TextSize = 12
idBtn.Font = Enum.Font.GothamBold
idBtn.BorderSizePixel = 0
corner(idBtn, 6)

enBtn.MouseButton1Click:Connect(function()
    _G.IH.Config.Lang = "EN"
    enBtn.BackgroundColor3 = Color3.fromRGB(100,60,180)
    idBtn.BackgroundColor3 = Color3.fromRGB(30,30,42)
end)
idBtn.MouseButton1Click:Connect(function()
    _G.IH.Config.Lang = "ID"
    idBtn.BackgroundColor3 = Color3.fromRGB(100,60,180)
    enBtn.BackgroundColor3 = Color3.fromRGB(30,30,42)
end)
sy = sy + 46

-- Colors
local colorDefs = {
    {key="Accent",  label="Accent Color",   default=Color3.fromRGB(139,92,246)},
    {key="Monster", label="Monster ESP",    default=Color3.fromRGB(255,60,60)},
    {key="Player",  label="Player ESP",     default=Color3.fromRGB(60,150,255)},
    {key="Item",    label="Item ESP",       default=Color3.fromRGB(60,255,120)},
    {key="Text",    label="Text Color",     default=Color3.fromRGB(240,240,240)},
}

local colorPresets = {
    Color3.fromRGB(139,92,246),
    Color3.fromRGB(255,60,60),
    Color3.fromRGB(60,150,255),
    Color3.fromRGB(60,220,120),
    Color3.fromRGB(255,180,50),
    Color3.fromRGB(255,100,180),
}

for _, cd in ipairs(colorDefs) do
    local crow = Instance.new("Frame", sf)
    crow.Position = UDim2.new(0,0,0,sy)
    crow.Size = UDim2.new(1,0,0,38)
    crow.BackgroundTransparency = 1

    label(crow, cd.label, 13, Color3.fromRGB(200,200,200), Enum.Font.Gotham,
        UDim2.new(0,12,0,0), UDim2.new(0.4,0,1,0))

    for i, col in ipairs(colorPresets) do
        local dot = Instance.new("TextButton", crow)
        dot.Size = UDim2.new(0,22,0,22)
        dot.Position = UDim2.new(0, 130 + (i-1)*28, 0.5, -11)
        dot.BackgroundColor3 = col
        dot.Text = ""
        dot.BorderSizePixel = 0
        corner(dot, 11)
        dot.MouseButton1Click:Connect(function()
            _G.IH.Config.Colors[cd.key] = col
        end)
    end
    sy = sy + 44
end
sf.CanvasSize = UDim2.new(0,0,0,sy+10)

-- ═══ ABOUT TAB ═══
local af = TF.about
local aboutBox = Instance.new("Frame", af)
aboutBox.Position = UDim2.new(0,12,0,12)
aboutBox.Size = UDim2.new(1,-24,0,180)
aboutBox.BackgroundColor3 = Color3.fromRGB(18,18,26)
aboutBox.BorderSizePixel = 0
corner(aboutBox, 10)
stroke(aboutBox, Color3.fromRGB(80,50,130), 1.5, 0.4)

local aLogo = Instance.new("TextLabel", aboutBox)
aLogo.Size = UDim2.new(1,0,0,50)
aLogo.Position = UDim2.new(0,0,0,10)
aLogo.BackgroundTransparency = 1
aLogo.Text = "🇮🇩 Indonesia Hub"
aLogo.TextColor3 = Color3.fromRGB(180,150,255)
aLogo.TextSize = 20
aLogo.Font = Enum.Font.GothamBold

local aDesc = Instance.new("TextLabel", aboutBox)
aDesc.Size = UDim2.new(1,-20,0,100)
aDesc.Position = UDim2.new(0,10,0,60)
aDesc.BackgroundTransparency = 1
aDesc.Text = "Lethal Ape Script v2.0\nESP · Farm · Player Mods\n\nBy: Indonesia Hub Community\nUse at your own risk!"
aDesc.TextColor3 = Color3.fromRGB(160,160,180)
aDesc.TextSize = 13
aDesc.Font = Enum.Font.Gotham
aDesc.TextWrapped = true
aDesc.TextXAlignment = Enum.TextXAlignment.Center

-- ═══ OPEN/CLOSE KEYBIND ═══
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        local Main2 = ScreenGui:FindFirstChild("Main")
        if Main2 then Main2.Visible = not Main2.Visible end
    end
end)

-- ═══ OPEN BUTTON (kalau di close) ═══
local openBtn = Instance.new("ScreenGui", CoreGui)
openBtn.Name = "IH_OpenBtn"
openBtn.ResetOnSpawn = false
local ob = Instance.new("TextButton", openBtn)
ob.Size = UDim2.new(0,36,0,36)
ob.Position = UDim2.new(0,10,0.5,-18)
ob.BackgroundColor3 = Color3.fromRGB(100,60,180)
ob.Text = "IH"
ob.TextColor3 = Color3.fromRGB(255,255,255)
ob.TextSize = 11
ob.Font = Enum.Font.GothamBold
ob.BorderSizePixel = 0
corner(ob, 8)
stroke(ob, Color3.fromRGB(160,120,255), 1.5, 0.3)
ob.MouseButton1Click:Connect(function()
    local Main2 = ScreenGui:FindFirstChild("Main")
    if Main2 then Main2.Visible = true end
end)

-- ═══ DONE ═══
print("╔══════════════════════════════╗")
print("║   INDONESIA HUB LOADED ✓    ║")
print("║   Lethal Ape Script v2.0    ║")
print("║   Press RShift to toggle    ║")
print("╚══════════════════════════════╝")
