-- ═══════════════════════════════════════════════
--       INDONESIA HUB | Universal Script
--       Version: 3.0 | By: Indonesia Hub
--       Sambung 5 bagian lalu execute!
-- ═══════════════════════════════════════════════

-- BAGIAN 1/5: Core + Data

local ok1, err1 = pcall(function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local Camera = workspace.CurrentCamera

-- Bersihkan session lama
if _G.IH then
    pcall(function()
        if _G.IH.Connections then
            for _, c in pairs(_G.IH.Connections) do
                pcall(function() c:Disconnect() end)
            end
        end
        if _G.IH.GUI then _G.IH.GUI:Destroy() end
    end)
end

_G.IH = {
    Connections = {},
    GUI = nil,
    Config = {
        Lang = "EN",
        Colors = {
            Accent  = Color3.fromRGB(139, 92, 246),
            Monster = Color3.fromRGB(255, 60, 60),
            Player  = Color3.fromRGB(60, 150, 255),
            Item    = Color3.fromRGB(60, 255, 120),
            Text    = Color3.fromRGB(240, 240, 240),
            BG      = Color3.fromRGB(15, 15, 20),
            Sidebar = Color3.fromRGB(10, 10, 15),
            Surface = Color3.fromRGB(25, 25, 32),
        },
        ESP = {
            Monster = true,
            Player  = true,
            Item    = true,
            MaxDist = 500,
        },
        Player = {
            Fly         = false,
            FlySpeed    = 50,
            InfJump     = false,
            Noclip      = false,
            TpWalk      = false,
            TpWalkSpeed = 43,
            FOV         = 70,
            Speed       = false,
            SpeedVal    = 16,
        },
        Farm = {
            Active       = false,
            SelectedItem = "All",
            AutoSell     = true,
        },
    },
}

-- LANGUAGE
_G.IH.L = {
    EN = {
        player="Player", visuals="Visuals", farm="Farm",
        settings="Settings", about="About",
        fly="Fly", flyspeed="Fly Speed", fov="FOV",
        noclip="Noclip", infjump="Inf Jump",
        tpwalk="TP Walk", tpspeed="TP Speed",
        speed="Speed Hack", speedval="Speed Value",
        monster_esp="Monster ESP", player_esp="Player ESP",
        item_esp="Item ESP", maxdist="Max Distance",
        farm_all="Farm All", farm_select="Select Item",
        autosell="Auto Sell", language="Language",
        toggle_key="Toggle: RShift",
    },
    ID = {
        player="Pemain", visuals="Visual", farm="Farm",
        settings="Pengaturan", about="Tentang",
        fly="Terbang", flyspeed="Kecepatan Terbang", fov="FOV",
        noclip="Noclip", infjump="Lompat Inf",
        tpwalk="TP Jalan", tpspeed="Kecepatan TP",
        speed="Speed Hack", speedval="Nilai Speed",
        monster_esp="ESP Monster", player_esp="ESP Pemain",
        item_esp="ESP Item", maxdist="Jarak Max",
        farm_all="Farm Semua", farm_select="Pilih Item",
        autosell="Jual Otomatis", language="Bahasa",
        toggle_key="Toggle: RShift",
    },
}

function _G.IH.T(k)
    local lang = _G.IH.Config.Lang
    return (_G.IH.L[lang] or _G.IH.L.EN)[k] or k
end

function _G.IH.AddConn(c)
    table.insert(_G.IH.Connections, c)
end

-- MONSTERS (Universal + Lethal Ape)
_G.IH.Monsters = {
    -- Lethal Ape
    "Renry","Lana","Rin","Billy","Noxar","Sandguy",
    "Fearful","Gooba","Lost","Lurker","Dus","Kus",
    "Bloodman","Gus","Scar","Ashy","Sandman","John",
    "Stalker","Meat",
    -- Universal
    "Zombie","Monster","Enemy","Boss","NPC",
    "Alien","Ghost","Creature","Mob","Dummy",
}

-- ITEMS (Universal + Lethal Ape)
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
    {name="Coin",             price=1},
    {name="Gem",              price=5},
    {name="Ore",              price=3},
    {name="Wood",             price=1},
    {name="Stone",            price=1},
    {name="Silver",           price=4},
}

end) -- end pcall 1

if not ok1 then
    warn("[IH] Bagian 1 Error: "..tostring(err1))
else
    print("[IH] Bagian 1/5 OK ✓")
end
-- BAGIAN 2/5: ESP System

local ok2, err2 = pcall(function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

_G.IH.ESPList = {}

local function clearESP()
    for _, v in pairs(_G.IH.ESPList) do
        pcall(function() v:Destroy() end)
    end
    table.clear(_G.IH.ESPList)
end

local function getDist(pos)
    local char = LP.Character
    if not char then return 9999 end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return 9999 end
    return math.floor((pos - root.Position).Magnitude)
end

local function makeESP(parent, title, color, sub)
    -- Cek apakah parent valid
    if not parent or not parent.Parent then return end
    -- Hapus ESP lama kalau ada
    local old = parent:FindFirstChild("IH_ESP")
    if old then old:Destroy() end

    local bb = Instance.new("BillboardGui")
    bb.Name = "IH_ESP"
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 160, 0, 52)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.MaxDistance = _G.IH.Config.ESP.MaxDist
    bb.Parent = parent

    local bg = Instance.new("Frame", bb)
    bg.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    bg.BackgroundTransparency = 0.25
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BorderSizePixel = 0

    local corner = Instance.new("UICorner", bg)
    corner.CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2

    local topL = Instance.new("TextLabel", bg)
    topL.BackgroundTransparency = 1
    topL.Size = UDim2.new(1, -6, 0.55, 0)
    topL.Position = UDim2.new(0, 3, 0, 0)
    topL.Text = title
    topL.TextColor3 = color
    topL.TextStrokeTransparency = 0.4
    topL.TextStrokeColor3 = Color3.new(0, 0, 0)
    topL.TextScaled = true
    topL.Font = Enum.Font.GothamBold
    topL.TextXAlignment = Enum.TextXAlignment.Center

    local botL = Instance.new("TextLabel", bg)
    botL.BackgroundTransparency = 1
    botL.Size = UDim2.new(1, -6, 0.45, 0)
    botL.Position = UDim2.new(0, 3, 0.55, 0)
    botL.Text = sub or ""
    botL.TextColor3 = Color3.fromRGB(210, 210, 210)
    botL.TextStrokeTransparency = 0.4
    botL.TextStrokeColor3 = Color3.new(0, 0, 0)
    botL.TextScaled = true
    botL.Font = Enum.Font.Gotham
    botL.TextXAlignment = Enum.TextXAlignment.Center

    table.insert(_G.IH.ESPList, bb)
    return bb
end

local function runESP()
    clearESP()
    local cfg  = _G.IH.Config.ESP
    local cols = _G.IH.Config.Colors

    -- MONSTER ESP
    if cfg.Monster then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local hum  = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart")
                if hum and root and obj ~= LP.Character then
                    local isMonster = false
                    for _, mn in ipairs(_G.IH.Monsters) do
                        if obj.Name:lower():find(mn:lower()) then
                            isMonster = true; break
                        end
                    end
                    if isMonster then
                        local d  = getDist(root.Position)
                        if d <= cfg.MaxDist then
                            local hp = math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)
                            makeESP(root,
                                "👾 "..obj.Name,
                                cols.Monster,
                                "HP:"..hp.." | "..d.."m"
                            )
                        end
                    end
                end
            end
        end
    end

    -- PLAYER ESP
    if cfg.Player then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
                if root and hum then
                    local d = getDist(root.Position)
                    if d <= cfg.MaxDist then
                        local hp = math.floor(hum.Health)
                        makeESP(root,
                            "👤 "..plr.Name,
                            cols.Player,
                            "HP:"..hp.." | "..d.."m"
                        )
                    end
                end
            end
        end
    end

    -- ITEM ESP
    if cfg.Item then
        for _, obj in ipairs(workspace:GetDescendants()) do
            -- Skip karakter player
            local isChar = false
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character and obj:IsDescendantOf(plr.Character) then
                    isChar = true; break
                end
            end
            if not isChar then
                for _, item in ipairs(_G.IH.Items) do
                    if obj.Name:lower():find(item.name:lower()) then
                        local part = obj:IsA("BasePart") and obj
                            or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
                        if part then
                            local d = getDist(part.Position)
                            if d <= cfg.MaxDist then
                                makeESP(part,
                                    "💎 "..item.name,
                                    cols.Item,
                                    item.price.."G | "..d.."m"
                                )
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end

-- ESP loop setiap 1.5 detik
local espTimer = 0
_G.IH.AddConn(RunService.Heartbeat:Connect(function(dt)
    espTimer = espTimer + dt
    if espTimer >= 1.5 then
        espTimer = 0
        pcall(runESP)
    end
end))

end) -- end pcall 2

if not ok2 then
    warn("[IH] Bagian 2 Error: "..tostring(err2))
else
    print("[IH] Bagian 2/5 OK ✓")
end
-- BAGIAN 3/5: Player Mods + Farm

local ok3, err3 = pcall(function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ═══ FLY ═══
local flyBV, flyConn
function _G.IH.StartFly()
    _G.IH.StopFly()
    local char = LP.Character or LP.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    hum.PlatformStand = true

    flyBV = Instance.new("BodyVelocity", root)
    flyBV.Velocity   = Vector3.zero
    flyBV.MaxForce   = Vector3.new(1e6, 1e6, 1e6)
    flyBV.Name       = "IH_FlyBV"

    flyConn = RunService.Heartbeat:Connect(function()
        if not _G.IH.Config.Player.Fly then
            _G.IH.StopFly(); return
        end
        if not flyBV or not flyBV.Parent then return end
        local spd = _G.IH.Config.Player.FlySpeed
        local mv  = Vector3.zero
        local cf  = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then mv -= Vector3.new(0,1,0) end
        flyBV.Velocity = mv.Magnitude > 0 and mv.Unit * spd or Vector3.zero
    end)
    _G.IH.AddConn(flyConn)
end

function _G.IH.StopFly()
    if flyConn then pcall(function() flyConn:Disconnect() end); flyConn = nil end
    if flyBV   then pcall(function() flyBV:Destroy() end); flyBV = nil end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

-- ═══ INF JUMP ═══
_G.IH.AddConn(UserInputService.JumpRequest:Connect(function()
    if not _G.IH.Config.Player.InfJump then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

-- ═══ NOCLIP ═══
_G.IH.AddConn(RunService.Stepped:Connect(function()
    if not _G.IH.Config.Player.Noclip then
        -- Restore collision
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
        return
    end
    local char = LP.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end))

-- ═══ TPWALK ═══
_G.IH.AddConn(RunService.Heartbeat:Connect(function()
    if not _G.IH.Config.Player.TpWalk then return end
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if hum.MoveDirection.Magnitude > 0 then
        local spd = _G.IH.Config.Player.TpWalkSpeed
        root.CFrame = root.CFrame + hum.MoveDirection * spd * 0.016
    end
end))

-- ═══ SPEED HACK ═══
_G.IH.AddConn(RunService.Heartbeat:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if _G.IH.Config.Player.Speed then
        hum.WalkSpeed = _G.IH.Config.Player.SpeedVal
    else
        if hum.WalkSpeed == _G.IH.Config.Player.SpeedVal then
            hum.WalkSpeed = 16
        end
    end
end))

-- ═══ FOV ═══
function _G.IH.SetFOV(v)
    workspace.CurrentCamera.FieldOfView = v
    _G.IH.Config.Player.FOV = v
end

-- ═══ FARM ═══
local farmThread = nil

local function tpTo(pos)
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
    end
end

local function findScrapper()
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("scrapper") or n:find("sell") or n:find("shop") or n:find("vendor") then
            local part = obj:IsA("BasePart") and obj
                or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
            if part then return part end
        end
    end
    return nil
end

function _G.IH.StartFarm()
    if farmThread then return end
    _G.IH.Config.Farm.Active = true
    farmThread = task.spawn(function()
        while _G.IH.Config.Farm.Active do
            local collected = 0
            for _, obj in ipairs(workspace:GetDescendants()) do
                if not _G.IH.Config.Farm.Active then break end
                local isAll = _G.IH.Config.Farm.SelectedItem == "All"
                for _, item in ipairs(_G.IH.Items) do
                    local match = isAll or _G.IH.Config.Farm.SelectedItem == item.name
                    if match and obj.Name:lower():find(item.name:lower()) then
                        local part = obj:IsA("BasePart") and obj
                            or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
                        if part and part.Parent then
                            pcall(tpTo, part.Position)
                            task.wait(0.25)
                            collected = collected + 1
                        end
                        break
                    end
                end
            end
            if _G.IH.Config.Farm.AutoSell and collected > 0 then
                local scrap = findScrapper()
                if scrap then
                    pcall(tpTo, scrap.Position)
                    task.wait(1.5)
                end
            end
            task.wait(0.5)
        end
        farmThread = nil
    end)
end

function _G.IH.StopFarm()
    _G.IH.Config.Farm.Active = false
    farmThread = nil
end

-- Character respawn handler
LP.CharacterAdded:Connect(function()
    task.wait(1)
    if _G.IH.Config.Player.Fly then _G.IH.StartFly() end
end)

end) -- end pcall 3

if not ok3 then
    warn("[IH] Bagian 3 Error: "..tostring(err3))
else
    print("[IH] Bagian 3/5 OK ✓")
end
-- BAGIAN 4/5: GUI Core

local ok4, err4 = pcall(function()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- Hapus GUI lama
pcall(function()
    CoreGui:FindFirstChild("IH_GUI") and CoreGui.IH_GUI:Destroy()
    CoreGui:FindFirstChild("IH_Btn") and CoreGui.IH_Btn:Destroy()
end)

local SG = Instance.new("ScreenGui", CoreGui)
SG.Name = "IH_GUI"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder = 999
_G.IH.GUI = SG

-- ═══ HELPER FUNCTIONS ═══
local function mkCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

local function mkStroke(p, col, th, tr)
    local s = Instance.new("UIStroke", p)
    s.Color = col or Color3.fromRGB(60,60,80)
    s.Thickness = th or 1
    s.Transparency = tr or 0.5
    return s
end

local function mkLabel(p, txt, sz, col, fnt, pos, size, xa)
    local l = Instance.new("TextLabel", p)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextSize = sz or 14
    l.TextColor3 = col or Color3.fromRGB(230,230,230)
    l.Font = fnt or Enum.Font.Gotham
    l.Position = pos or UDim2.new(0,0,0,0)
    l.Size = size or UDim2.new(1,0,1,0)
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    return l
end

-- ═══ TOGGLE ═══
function _G.IH.MkToggle(parent, yPos, txt, initState, cb)
    local row = Instance.new("Frame", parent)
    row.BackgroundTransparency = 1
    row.Position = UDim2.new(0, 0, 0, yPos)
    row.Size = UDim2.new(1, 0, 0, 38)

    mkLabel(row, txt, 13, Color3.fromRGB(215,215,215), Enum.Font.Gotham,
        UDim2.new(0,14,0,0), UDim2.new(1,-70,1,0))

    local bg = Instance.new("Frame", row)
    bg.Size = UDim2.new(0,46,0,24)
    bg.Position = UDim2.new(1,-58,0.5,-12)
    bg.BackgroundColor3 = initState
        and Color3.fromRGB(139,92,246) or Color3.fromRGB(45,45,58)
    bg.BorderSizePixel = 0
    mkCorner(bg, 12)

    local dot = Instance.new("Frame", bg)
    dot.Size = UDim2.new(0,18,0,18)
    dot.Position = initState
        and UDim2.new(0,25,0.5,-9) or UDim2.new(0,3,0.5,-9)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255)
    dot.BorderSizePixel = 0
    mkCorner(dot, 9)

    local state = initState
    local function upd(s)
        state = s
        TweenService:Create(bg, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            BackgroundColor3 = s and Color3.fromRGB(139,92,246) or Color3.fromRGB(45,45,58)
        }):Play()
        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            Position = s and UDim2.new(0,25,0.5,-9) or UDim2.new(0,3,0.5,-9)
        }):Play()
    end

    local btn = Instance.new("TextButton", row)
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1,0,1,0)
    btn.Text = ""
    btn.ZIndex = 2
    btn.MouseButton1Click:Connect(function()
        upd(not state)
        pcall(cb, state)
    end)

    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(25,25,35)
        }):Play()
        row.BackgroundTransparency = 0.7
    end)
    btn.MouseLeave:Connect(function()
        row.BackgroundTransparency = 1
    end)
    mkCorner(row, 6)

    return row, upd
end

-- ═══ SLIDER ═══
function _G.IH.MkSlider(parent, yPos, txt, mn, mx, val, cb)
    local row = Instance.new("Frame", parent)
    row.BackgroundTransparency = 1
    row.Position = UDim2.new(0, 0, 0, yPos)
    row.Size = UDim2.new(1, 0, 0, 52)

    mkLabel(row, txt, 12, Color3.fromRGB(190,190,200), Enum.Font.Gotham,
        UDim2.new(0,14,0,2), UDim2.new(0.6,0,0,20))

    local vBox = Instance.new("TextBox", row)
    vBox.Size = UDim2.new(0,66,0,26)
    vBox.Position = UDim2.new(1,-78,0,10)
    vBox.BackgroundColor3 = Color3.fromRGB(22,22,30)
    vBox.TextColor3 = Color3.fromRGB(230,230,230)
    vBox.Text = tostring(val)
    vBox.TextSize = 13
    vBox.Font = Enum.Font.GothamBold
    vBox.ClearTextOnFocus = false
    vBox.BorderSizePixel = 0
    mkCorner(vBox, 6)
    mkStroke(vBox, Color3.fromRGB(80,55,120), 1, 0.3)

    local track = Instance.new("Frame", row)
    track.Position = UDim2.new(0,14,0,36)
    track.Size = UDim2.new(1,-96,0,5)
    track.BackgroundColor3 = Color3.fromRGB(38,38,50)
    track.BorderSizePixel = 0
    mkCorner(track, 3)

    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = Color3.fromRGB(139,92,246)
    fill.Size = UDim2.new((val-mn)/(mx-mn),0,1,0)
    fill.BorderSizePixel = 0
    mkCorner(fill, 3)

    local thumb = Instance.new("Frame", track)
    thumb.Size = UDim2.new(0,13,0,13)
    thumb.Position = UDim2.new((val-mn)/(mx-mn),-6,0.5,-6)
    thumb.BackgroundColor3 = Color3.fromRGB(255,255,255)
    thumb.BorderSizePixel = 0
    mkCorner(thumb, 7)
    mkStroke(thumb, Color3.fromRGB(139,92,246), 1.5, 0)

    local function setVal(v)
        v = math.clamp(math.floor(v+0.5), mn, mx)
        local pct = (v-mn)/(mx-mn)
        vBox.Text = tostring(v)
        TweenService:Create(fill, TweenInfo.new(0.1), {Size=UDim2.new(pct,0,1,0)}):Play()
        TweenService:Create(thumb, TweenInfo.new(0.1), {Position=UDim2.new(pct,-6,0.5,-6)}):Play()
        pcall(cb, v)
    end

    vBox.FocusLost:Connect(function()
        local n = tonumber(vBox.Text)
        if n then setVal(n) end
    end)

    local dragging = false
    local dbtn = Instance.new("TextButton", track)
    dbtn.BackgroundTransparency = 1
    dbtn.Size = UDim2.new(1,0,1,20)
    dbtn.Position = UDim2.new(0,0,0,-10)
    dbtn.Text = ""
    dbtn.ZIndex = 3
    dbtn.MouseButton1Down:Connect(function() dragging = true end)

    _G.IH.AddConn(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    _G.IH.AddConn(UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local pos = i.UserInputType == Enum.UserInputType.Touch
                and i.Position or UserInputService:GetMouseLocation()
            local pct = math.clamp((pos.X - abs.X) / sz.X, 0, 1)
            setVal(mn + pct * (mx - mn))
        end
    end))

    return row, setVal
end

-- ═══ MAIN WINDOW ═══
local cols = _G.IH.Config.Colors

local Main = Instance.new("Frame", SG)
Main.Name = "Main"
Main.Size = UDim2.new(0, 540, 0, 400)
Main.Position = UDim2.new(0.5, -270, 0.5, -200)
Main.BackgroundColor3 = cols.BG
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
mkCorner(Main, 10)
mkStroke(Main, Color3.fromRGB(70,45,120), 1.5, 0.2)

-- Titlebar
local TB = Instance.new("Frame", Main)
TB.Size = UDim2.new(1,0,0,36)
TB.BackgroundColor3 = cols.Sidebar
TB.BorderSizePixel = 0
mkStroke(TB, Color3.fromRGB(50,35,90), 1, 0.5)

-- Logo
local logo = Instance.new("Frame", TB)
logo.Size = UDim2.new(0,24,0,24)
logo.Position = UDim2.new(0,10,0.5,-12)
logo.BackgroundColor3 = Color3.fromRGB(139,92,246)
logo.BorderSizePixel = 0
mkCorner(logo, 7)
local logoTxt = Instance.new("TextLabel", logo)
logoTxt.Size = UDim2.new(1,0,1,0)
logoTxt.BackgroundTransparency = 1
logoTxt.Text = "IH"
logoTxt.TextColor3 = Color3.fromRGB(255,255,255)
logoTxt.TextSize = 10
logoTxt.Font = Enum.Font.GothamBold
logoTxt.TextXAlignment = Enum.TextXAlignment.Center

mkLabel(TB, "Indonesia Hub", 13,
    Color3.fromRGB(210,195,255), Enum.Font.GothamBold,
    UDim2.new(0,42,0,0), UDim2.new(0.5,0,1,0))

-- Close & Min buttons
local function mkTBBtn(xOff, col, txt, cb)
    local b = Instance.new("TextButton", TB)
    b.Size = UDim2.new(0,22,0,22)
    b.Position = UDim2.new(1,xOff,0.5,-11)
    b.BackgroundColor3 = col
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    mkCorner(b, 5)
    b.MouseButton1Click:Connect(cb)
    return b
end

mkTBBtn(-8,  Color3.fromRGB(210,55,55), "✕", function() Main.Visible = false end)
mkTBBtn(-34, Color3.fromRGB(45,45,60),  "—", function()
    Main.Size = Main.Size.Y.Offset > 40
        and UDim2.new(0,540,0,36) or UDim2.new(0,540,0,400)
end)

-- Draggable
local drag, dragSt, dragPos = false, nil, nil
TB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or
       i.UserInputType == Enum.UserInputType.Touch then
        drag = true; dragSt = i.Position; dragPos = Main.Position
    end
end)
_G.IH.AddConn(UserInputService.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragSt
        Main.Position = UDim2.new(
            dragPos.X.Scale, dragPos.X.Offset + d.X,
            dragPos.Y.Scale, dragPos.Y.Offset + d.Y)
    end
end))
_G.IH.AddConn(UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or
       i.UserInputType == Enum.UserInputType.Touch then drag = false end
end))

-- Sidebar
local SB = Instance.new("Frame", Main)
SB.Size = UDim2.new(0,150,1,-36)
SB.Position = UDim2.new(0,0,0,36)
SB.BackgroundColor3 = cols.Sidebar
SB.BorderSizePixel = 0
mkStroke(SB, Color3.fromRGB(45,35,75), 1, 0.5)

-- Content
local CT = Instance.new("Frame", Main)
CT.Size = UDim2.new(1,-154,1,-40)
CT.Position = UDim2.new(0,152,0,38)
CT.BackgroundTransparency = 1
CT.ClipsDescendants = true

-- Tabs
local tabBtns   = {}
local tabFrames = {}

local tabList = {
    {id="player",  ico="👤", lbl="Player"},
    {id="visuals", ico="👁",  lbl="Visuals"},
    {id="farm",    ico="🌾", lbl="Farm"},
    {id="settings",ico="⚙", lbl="Settings"},
    {id="about",   ico="ℹ",  lbl="About"},
}

local function switchTab(id)
    for tid, fr in pairs(tabFrames) do fr.Visible = tid == id end
    for tid, bt in pairs(tabBtns) do
        local active = tid == id
        TweenService:Create(bt, TweenInfo.new(0.15), {
            BackgroundColor3 = active
                and Color3.fromRGB(28,22,45) or cols.Sidebar,
            BackgroundTransparency = active and 0 or 1,
        }):Play()
        local lbl = bt:FindFirstChildOfClass("TextLabel")
        if lbl then
            lbl.TextColor3 = active
                and Color3.fromRGB(175,145,255)
                or Color3.fromRGB(120,120,140)
        end
    end
end

for i, t in ipairs(tabList) do
    local btn = Instance.new("TextButton", SB)
    btn.Size = UDim2.new(1,-10,0,34)
    btn.Position = UDim2.new(0,5,0, 8+(i-1)*38)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.BorderSizePixel = 0
    mkCorner(btn, 7)

    local icoL = mkLabel(btn, t.ico, 15, Color3.fromRGB(120,120,140),
        Enum.Font.GothamBold, UDim2.new(0,8,0,0), UDim2.new(0,28,1,0),
        Enum.TextXAlignment.Center)

    local txtL = mkLabel(btn, t.lbl, 12, Color3.fromRGB(120,120,140),
        Enum.Font.GothamBold, UDim2.new(0,36,0,0), UDim2.new(1,-40,1,0))

    local sf = Instance.new("ScrollingFrame", CT)
    sf.Size = UDim2.new(1,0,1,0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Color3.fromRGB(100,75,160)
    sf.CanvasSize = UDim2.new(0,0,0,500)
    sf.Visible = false

    tabBtns[t.id]   = btn
    tabFrames[t.id] = sf

    btn.MouseButton1Click:Connect(function() switchTab(t.id) end)
end

_G.IH.TabFrames  = tabFrames
_G.IH.SwitchTab  = switchTab
_G.IH.MainWindow = Main
switchTab("player")

-- Open button (saat main di-close)
local BtnSG = Instance.new("ScreenGui", CoreGui)
BtnSG.Name = "IH_Btn"
BtnSG.ResetOnSpawn = false
BtnSG.DisplayOrder = 998
local openBtn = Instance.new("TextButton", BtnSG)
openBtn.Size = UDim2.new(0,38,0,38)
openBtn.Position = UDim2.new(0,8,0.5,-19)
openBtn.BackgroundColor3 = Color3.fromRGB(100,55,180)
openBtn.Text = "IH"
openBtn.TextColor3 = Color3.fromRGB(255,255,255)
openBtn.TextSize = 11
openBtn.Font = Enum.Font.GothamBold
openBtn.BorderSizePixel = 0
mkCorner(openBtn, 8)
mkStroke(openBtn, Color3.fromRGB(160,120,255), 1.5, 0.2)
openBtn.MouseButton1Click:Connect(function()
    Main.Visible = true
    Main.Size = UDim2.new(0,540,0,400)
end)

-- Toggle RShift
_G.IH.AddConn(UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
        if Main.Visible then Main.Size = UDim2.new(0,540,0,400) end
    end
end))

end) -- end pcall 4

if not ok4 then
    warn("[IH] Bagian 4 Error: "..tostring(err4))
else
    print("[IH] Bagian 4/5 OK ✓")
end
-- BAGIAN 5/5: Tab Content + Finish

local ok5, err5 = pcall(function()

local TweenService = game:GetService("TweenService")
local TF  = _G.IH.TabFrames
local cfg = _G.IH.Config
local MkT = _G.IH.MkToggle
local MkS = _G.IH.MkSlider

-- ═══ PLAYER TAB ═══
local pf = TF.player
local py = 6

MkT(pf, py, "Fly", cfg.Player.Fly, function(s)
    cfg.Player.Fly = s
    if s then _G.IH.StartFly() else _G.IH.StopFly() end
end); py += 42

MkS(pf, py, "Fly Speed", 10, 300, cfg.Player.FlySpeed, function(v)
    cfg.Player.FlySpeed = v
end); py += 56

MkS(pf, py, "FOV Changer", 50, 120, cfg.Player.FOV, function(v)
    _G.IH.SetFOV(v)
end); py += 56

MkT(pf, py, "Noclip", cfg.Player.Noclip, function(s)
    cfg.Player.Noclip = s
end); py += 42

MkT(pf, py, "Infinite Jump", cfg.Player.InfJump, function(s)
    cfg.Player.InfJump = s
end); py += 42

MkT(pf, py, "TP Walk", cfg.Player.TpWalk, function(s)
    cfg.Player.TpWalk = s
end); py += 42

MkS(pf, py, "TP Speed", 10, 200, cfg.Player.TpWalkSpeed, function(v)
    cfg.Player.TpWalkSpeed = v
end); py += 56

MkT(pf, py, "Speed Hack", cfg.Player.Speed, function(s)
    cfg.Player.Speed = s
end); py += 42

MkS(pf, py, "Speed Value", 16, 500, cfg.Player.SpeedVal, function(v)
    cfg.Player.SpeedVal = v
end); py += 56

pf.CanvasSize = UDim2.new(0,0,0,py+10)

-- ═══ VISUALS TAB ═══
local vf = TF.visuals
local vy = 6

MkT(vf, vy, "Monster ESP", cfg.ESP.Monster, function(s)
    cfg.ESP.Monster = s
end); vy += 42

MkT(vf, vy, "Player ESP", cfg.ESP.Player, function(s)
    cfg.ESP.Player = s
end); vy += 42

MkT(vf, vy, "Item ESP", cfg.ESP.Item, function(s)
    cfg.ESP.Item = s
end); vy += 42

MkS(vf, vy, "Max Distance", 50, 2000, cfg.ESP.MaxDist, function(v)
    cfg.ESP.MaxDist = v
end); vy += 56

vf.CanvasSize = UDim2.new(0,0,0,vy+10)

-- ═══ FARM TAB ═══
local ff = TF.farm
local fy = 6

MkT(ff, fy, "Farm All Items", cfg.Farm.SelectedItem=="All", function(s)
    cfg.Farm.SelectedItem = s and "All" or _G.IH.Items[1].name
end); fy += 42

MkT(ff, fy, "Auto Sell (Scrapper)", cfg.Farm.AutoSell, function(s)
    cfg.Farm.AutoSell = s
end); fy += 42

-- Start/Stop Farm button
local farmRow = Instance.new("Frame", ff)
farmRow.BackgroundTransparency = 1
farmRow.Position = UDim2.new(0,0,0,fy)
farmRow.Size = UDim2.new(1,0,0,36)

local farmBtn = Instance.new("TextButton", farmRow)
farmBtn.Size = UDim2.new(1,-28,0,30)
farmBtn.Position = UDim2.new(0,14,0,3)
farmBtn.BackgroundColor3 = Color3.fromRGB(50,180,100)
farmBtn.Text = "▶ Start Farm"
farmBtn.TextColor3 = Color3.fromRGB(255,255,255)
farmBtn.TextSize = 13
farmBtn.Font = Enum.Font.GothamBold
farmBtn.BorderSizePixel = 0

local function mkC(p,r)
    local c=Instance.new("UICorner",p);c.CornerRadius=UDim.new(0,r or 8);return c
end
mkC(farmBtn, 7)

local farmActive = false
farmBtn.MouseButton1Click:Connect(function()
    farmActive = not farmActive
    if farmActive then
        farmBtn.Text = "⏹ Stop Farm"
        farmBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
        _G.IH.StartFarm()
    else
        farmBtn.Text = "▶ Start Farm"
        farmBtn.BackgroundColor3 = Color3.fromRGB(50,180,100)
        _G.IH.StopFarm()
    end
end)
fy += 42

-- Item selector label
local selLbl = Instance.new("TextLabel", ff)
selLbl.Position = UDim2.new(0,14,0,fy)
selLbl.Size = UDim2.new(1,-28,0,18)
selLbl.BackgroundTransparency = 1
selLbl.Text = "Select Item:"
selLbl.TextColor3 = Color3.fromRGB(170,170,190)
selLbl.TextSize = 12
selLbl.Font = Enum.Font.GothamBold
selLbl.TextXAlignment = Enum.TextXAlignment.Left
fy += 22

-- Item grid
local grid = Instance.new("Frame", ff)
grid.Position = UDim2.new(0,10,0,fy)
grid.Size = UDim2.new(1,-20,0,10)
grid.BackgroundTransparency = 1

local uigl = Instance.new("UIGridLayout", grid)
uigl.CellSize = UDim2.new(0,105,0,26)
uigl.CellPadding = UDim2.new(0,5,0,5)
uigl.SortOrder = Enum.SortOrder.LayoutOrder

local function refreshItemBtns(selected)
    for _, b in ipairs(grid:GetChildren()) do
        if b:IsA("TextButton") then
            b.BackgroundColor3 = b.Text==selected
                and Color3.fromRGB(90,55,145)
                or Color3.fromRGB(25,25,35)
        end
    end
end

for _, item in ipairs(_G.IH.Items) do
    local ib = Instance.new("TextButton", grid)
    ib.Size = UDim2.new(0,105,0,26)
    ib.BackgroundColor3 = cfg.Farm.SelectedItem==item.name
        and Color3.fromRGB(90,55,145) or Color3.fromRGB(25,25,35)
    ib.Text = item.name
    ib.TextColor3 = Color3.fromRGB(215,215,215)
    ib.TextSize = 11
    ib.Font = Enum.Font.Gotham
    ib.BorderSizePixel = 0
    mkC(ib, 6)

    local s = Instance.new("UIStroke", ib)
    s.Color = Color3.fromRGB(55,45,85)
    s.Thickness = 1
    s.Transparency = 0.4

    ib.MouseButton1Click:Connect(function()
        cfg.Farm.SelectedItem = item.name
        refreshItemBtns(item.name)
    end)
end

local rows = math.ceil(#_G.IH.Items / 4)
local gridH = rows * 31 + 5
grid.Size = UDim2.new(1,-20,0,gridH)
fy += gridH + 10
ff.CanvasSize = UDim2.new(0,0,0,fy)

-- ═══ SETTINGS TAB ═══
local sf = TF.settings
local sy = 6

-- Language
local lrow = Instance.new("Frame", sf)
lrow.BackgroundTransparency = 1
lrow.Position = UDim2.new(0,0,0,sy)
lrow.Size = UDim2.new(1,0,0,36)

local function mkLbl2(p,txt)
    local l=Instance.new("TextLabel",p)
    l.BackgroundTransparency=1
    l.Position=UDim2.new(0,14,0,0)
    l.Size=UDim2.new(0.5,0,1,0)
    l.Text=txt
    l.TextColor3=Color3.fromRGB(195,195,210)
    l.TextSize=13
    l.Font=Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end
mkLbl2(lrow, "Language / Bahasa")

local function mkLangBtn(p, xOff, txt, isActive)
    local b = Instance.new("TextButton", p)
    b.Size = UDim2.new(0,48,0,25)
    b.Position = UDim2.new(1,xOff,0.5,-12)
    b.BackgroundColor3 = isActive
        and Color3.fromRGB(100,55,180) or Color3.fromRGB(28,28,40)
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(240,240,240)
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    mkC(b, 6)
    return b
end

local enB = mkLangBtn(lrow, -106, "EN", cfg.Lang=="EN")
local idB = mkLangBtn(lrow, -54,  "ID", cfg.Lang=="ID")

local function setLang(lang)
    cfg.Lang = lang
    enB.BackgroundColor3 = lang=="EN" and Color3.fromRGB(100,55,180) or Color3.fromRGB(28,28,40)
    idB.BackgroundColor3 = lang=="ID" and Color3.fromRGB(100,55,180) or Color3.fromRGB(28,28,40)
end
enB.MouseButton1Click:Connect(function() setLang("EN") end)
idB.MouseButton1Click:Connect(function() setLang("ID") end)
sy += 46

-- Color presets
local colorDefs = {
    {key="Accent",  lbl="Accent Color"},
    {key="Monster", lbl="Monster ESP Color"},
    {key="Player",  lbl="Player ESP Color"},
    {key="Item",    lbl="Item ESP Color"},
    {key="Text",    lbl="Text Color"},
}
local presets = {
    Color3.fromRGB(139,92,246),
    Color3.fromRGB(255,60,60),
    Color3.fromRGB(60,150,255),
    Color3.fromRGB(60,220,120),
    Color3.fromRGB(255,180,50),
    Color3.fromRGB(255,100,180),
    Color3.fromRGB(255,255,255),
}

for _, cd in ipairs(colorDefs) do
    local crow = Instance.new("Frame", sf)
    crow.BackgroundTransparency = 1
    crow.Position = UDim2.new(0,0,0,sy)
    crow.Size = UDim2.new(1,0,0,36)
    mkLbl2(crow, cd.lbl)

    for i, col in ipairs(presets) do
        local db = Instance.new("TextButton", crow)
        db.Size = UDim2.new(0,20,0,20)
        db.Position = UDim2.new(0, 130+(i-1)*26, 0.5,-10)
        db.BackgroundColor3 = col
        db.Text = ""
        db.BorderSizePixel = 0
        mkC(db, 10)
        db.MouseButton1Click:Connect(function()
            cfg.Colors[cd.key] = col
        end)
    end
    sy += 40
end

sf.CanvasSize = UDim2.new(0,0,0,sy+10)

-- ═══ ABOUT TAB ═══
local af = TF.about
local abox = Instance.new("Frame", af)
abox.Position = UDim2.new(0,12,0,12)
abox.Size = UDim2.new(1,-24,0,220)
abox.BackgroundColor3 = Color3.fromRGB(14,14,20)
abox.BorderSizePixel = 0
mkC(abox, 10)

local ast = Instance.new("UIStroke", abox)
ast.Color = Color3.fromRGB(80,50,130)
ast.Thickness = 1.5
ast.Transparency = 0.3

local aLogo = Instance.new("TextLabel", abox)
aLogo.Size = UDim2.new(1,0,0,55)
aLogo.Position = UDim2.new(0,0,0,8)
aLogo.BackgroundTransparency = 1
aLogo.Text = "🇮🇩 Indonesia Hub"
aLogo.TextColor3 = Color3.fromRGB(175,145,255)
aLogo.TextSize = 20
aLogo.Font = Enum.Font.GothamBold
aLogo.TextXAlignment = Enum.TextXAlignment.Center

local aDesc = Instance.new("TextLabel", abox)
aDesc.Size = UDim2.new(1,-20,0,140)
aDesc.Position = UDim2.new(0,10,0,62)
aDesc.BackgroundTransparency = 1
aDesc.Text = "Universal Script v3.0\nLethal Ape & More\n\n✅ ESP: Monster, Player, Item\n✅ Player: Fly, Noclip, TpWalk\n✅ Farm: Auto Collect & Sell\n✅ Settings: Color & Language\n\nPress RShift to toggle GUI\nBy: Indonesia Hub Community"
aDesc.TextColor3 = Color3.fromRGB(155,155,175)
aDesc.TextSize = 12
aDesc.Font = Enum.Font.Gotham
aDesc.TextWrapped = true
aDesc.TextXAlignment = Enum.TextXAlignment.Center

af.CanvasSize = UDim2.new(0,0,0,250)

-- ═══ DONE ═══
print("╔══════════════════════════╗")
print("║  INDONESIA HUB v3.0 ✓  ║")
print("║  Universal Script       ║")
print("║  RShift = Toggle GUI    ║")
print("╚══════════════════════════╝")

end) -- end pcall 5

if not ok5 then
    warn("[IH] Bagian 5 Error: "..tostring(err5))
else
    print("[IH] Bagian 5/5 OK ✓")
    print("[IH] Semua bagian loaded! GUI siap!")
end
