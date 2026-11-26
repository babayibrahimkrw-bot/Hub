-- ═══════════════════════════════════════════════
--       INDONESIA HUB | Lethal Ape v4.1
--       Full Script — Execute Langsung!
-- ═══════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Cleanup
if _G.IH then
    pcall(function()
        for _, c in pairs(_G.IH.Conn or {}) do pcall(function() c:Disconnect() end) end
        if _G.IH.GUI then _G.IH.GUI:Destroy() end
        if _G.IH.BtnGUI then _G.IH.BtnGUI:Destroy() end
    end)
end

_G.IH = {
    Conn = {},
    GUI = nil,
    BtnGUI = nil,
    ESPCache = {},
    Config = {
        Lang = "EN",
        Colors = {
            Accent  = Color3.fromRGB(139,92,246),
            Monster = Color3.fromRGB(255,60,60),
            Player  = Color3.fromRGB(60,150,255),
            Item    = Color3.fromRGB(60,220,100),
            BG      = Color3.fromRGB(13,13,18),
            Sidebar = Color3.fromRGB(9,9,13),
        },
        ESP = {
            Monster  = true,
            Player   = true,
            Item     = true,
            MaxDist  = 300,
            TextSize = 11,
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
            SpeedVal    = 25,
        },
        Farm = {
            Active       = false,
            SelectedItem = "All",
            AutoSell     = true,
            Delay        = 0.1,
        },
    },
}

function _G.IH.AddConn(c)
    table.insert(_G.IH.Conn, c)
    return c
end

_G.IH.Monsters = {
    "Renry","Lana","Rin","Billy","Noxar","Sandguy",
    "Fearful","Gooba","Lost","Lurker","Dus","Kus",
    "Bloodman","Gus","Scar","Ashy","Sandman","John",
    "Stalker","Meat","Zombie","Enemy","Boss","Monster",
}

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

function _G.IH.IsPlayerPart(obj)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and obj:IsDescendantOf(plr.Character) then
            return true
        end
    end
    return false
end

-- ═══════════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════════
local function getDist(pos)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return 9999 end
    return math.floor((pos - root.Position).Magnitude)
end

local function makeESP(part, title, color, sub)
    if not part or not part.Parent then return end
    local old = _G.IH.ESPCache[part]
    if old then pcall(function() old:Destroy() end) end

    local bb = Instance.new("BillboardGui")
    bb.Name = "IH_ESP"
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 120, 0, 40)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.MaxDistance = _G.IH.Config.ESP.MaxDist
    bb.Parent = part

    local bg = Instance.new("Frame", bb)
    bg.BackgroundColor3 = Color3.fromRGB(5,5,8)
    bg.BackgroundTransparency = 0.15
    bg.Size = UDim2.new(1,0,1,0)
    bg.BorderSizePixel = 0
    local bgC = Instance.new("UICorner", bg)
    bgC.CornerRadius = UDim.new(0,5)
    local bgS = Instance.new("UIStroke", bg)
    bgS.Color = color
    bgS.Thickness = 1.2
    bgS.Transparency = 0.1

    local topL = Instance.new("TextLabel", bg)
    topL.BackgroundTransparency = 1
    topL.Size = UDim2.new(1,-4,0.55,0)
    topL.Position = UDim2.new(0,2,0,0)
    topL.Text = title
    topL.TextColor3 = color
    topL.TextStrokeTransparency = 0.3
    topL.TextStrokeColor3 = Color3.new(0,0,0)
    topL.TextSize = _G.IH.Config.ESP.TextSize
    topL.Font = Enum.Font.GothamBold
    topL.TextXAlignment = Enum.TextXAlignment.Center
    topL.TextTruncate = Enum.TextTruncate.AtEnd

    local botL = Instance.new("TextLabel", bg)
    botL.BackgroundTransparency = 1
    botL.Size = UDim2.new(1,-4,0.45,0)
    botL.Position = UDim2.new(0,2,0.55,0)
    botL.Text = sub or ""
    botL.TextColor3 = Color3.fromRGB(200,200,200)
    botL.TextStrokeTransparency = 0.4
    botL.TextStrokeColor3 = Color3.new(0,0,0)
    botL.TextSize = _G.IH.Config.ESP.TextSize - 1
    botL.Font = Enum.Font.Gotham
    botL.TextXAlignment = Enum.TextXAlignment.Center
    botL.TextTruncate = Enum.TextTruncate.AtEnd

    _G.IH.ESPCache[part] = bb
    local conn
    conn = part.AncestryChanged:Connect(function()
        if not part.Parent then
            pcall(function() bb:Destroy() end)
            _G.IH.ESPCache[part] = nil
            conn:Disconnect()
        end
    end)
end

local function updateESP()
    local cfg = _G.IH.Config.ESP
    local cols = _G.IH.Config.Colors

    for part, bb in pairs(_G.IH.ESPCache) do
        if not part or not part.Parent then
            pcall(function() bb:Destroy() end)
            _G.IH.ESPCache[part] = nil
        end
    end

    if cfg.Monster then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LP.Character then
                local hum  = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    for _, mn in ipairs(_G.IH.Monsters) do
                        if obj.Name:lower():find(mn:lower()) then
                            local d = getDist(root.Position)
                            if d <= cfg.MaxDist and not _G.IH.ESPCache[root] then
                                local hp = math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)
                                makeESP(root, obj.Name, cols.Monster, "HP:"..hp.." "..d.."m")
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    if cfg.Player then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local d = getDist(root.Position)
                    if d <= cfg.MaxDist and not _G.IH.ESPCache[root] then
                        makeESP(root, plr.Name, cols.Player,
                            "HP:"..math.floor(hum.Health).." "..d.."m")
                    end
                end
            end
        end
    end

    if cfg.Item then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if not _G.IH.IsPlayerPart(obj) then
                for _, item in ipairs(_G.IH.Items) do
                    if obj.Name:lower():find(item.name:lower()) then
                        local part = obj:IsA("BasePart") and obj
                            or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
                        if part and not _G.IH.ESPCache[part] then
                            local d = getDist(part.Position)
                            if d <= cfg.MaxDist then
                                makeESP(part, item.name, cols.Item,
                                    item.price.."G | "..d.."m")
                            end
                        end
                        break
                    end
                end
            end
        end
    end
end

local espTimer = 0
_G.IH.AddConn(RunService.Heartbeat:Connect(function(dt)
    espTimer += dt
    if espTimer >= 0.5 then espTimer = 0; pcall(updateESP) end
end))

_G.IH.AddConn(workspace.DescendantAdded:Connect(function(obj)
    if not _G.IH.Config.ESP.Item then return end
    task.wait(0.1)
    if not obj.Parent or _G.IH.IsPlayerPart(obj) then return end
    for _, item in ipairs(_G.IH.Items) do
        if obj.Name:lower():find(item.name:lower()) then
            local part = obj:IsA("BasePart") and obj
                or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
            if part then
                local d = getDist(part.Position)
                if d <= _G.IH.Config.ESP.MaxDist then
                    makeESP(part, item.name, _G.IH.Config.Colors.Item,
                        item.price.."G | "..d.."m")
                end
            end
            break
        end
    end
end))

_G.IH.AddConn(workspace.DescendantRemoving:Connect(function(obj)
    local bb = _G.IH.ESPCache[obj]
    if bb then
        pcall(function() bb:Destroy() end)
        _G.IH.ESPCache[obj] = nil
    end
end))

-- ═══════════════════════════════════════════════
-- PLAYER MODS
-- ═══════════════════════════════════════════════
local flyBV, flyBG, flyConn

function _G.IH.StartFly()
    _G.IH.StopFly()
    local char = LP.Character or LP.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    hum.PlatformStand = true

    flyBV = Instance.new("BodyVelocity", root)
    flyBV.Name = "IH_FlyBV"
    flyBV.Velocity = Vector3.zero
    flyBV.MaxForce = Vector3.new(1e4,1e4,1e4)

    flyBG = Instance.new("BodyGyro", root)
    flyBG.Name = "IH_FlyBG"
    flyBG.MaxTorque = Vector3.new(1e4,1e4,1e4)
    flyBG.P = 1e4
    flyBG.CFrame = root.CFrame

    flyConn = RunService.Heartbeat:Connect(function()
        if not _G.IH.Config.Player.Fly then _G.IH.StopFly(); return end
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
        if mv.Magnitude > 0 then
            flyBV.Velocity = mv.Unit * spd
            flyBG.CFrame = CFrame.new(Vector3.zero, mv)
        else
            flyBV.Velocity = Vector3.zero
        end
    end)
    _G.IH.AddConn(flyConn)
end

function _G.IH.StopFly()
    if flyConn then pcall(function() flyConn:Disconnect() end); flyConn = nil end
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            for _, v in ipairs(root:GetChildren()) do
                if v.Name:find("IH_Fly") then v:Destroy() end
            end
        end
    end
end

_G.IH.AddConn(RunService.Stepped:Connect(function()
    if not _G.IH.Config.Player.Noclip then return end
    local char = LP.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end))

_G.IH.AddConn(RunService.Heartbeat:Connect(function()
    if _G.IH.Config.Player.Noclip then return end
    local char = LP.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and not p.CanCollide then p.CanCollide = true end
    end
end))

_G.IH.AddConn(UserInputService.JumpRequest:Connect(function()
    if not _G.IH.Config.Player.InfJump then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

_G.IH.AddConn(RunService.Heartbeat:Connect(function()
    if not _G.IH.Config.Player.TpWalk then return end
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if hum.MoveDirection.Magnitude > 0 then
        root.CFrame = root.CFrame + hum.MoveDirection * _G.IH.Config.Player.TpWalkSpeed * 0.016
    end
end))

_G.IH.AddConn(RunService.Heartbeat:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = _G.IH.Config.Player.Speed and _G.IH.Config.Player.SpeedVal or 16
end))

function _G.IH.SetFOV(v)
    Camera.FieldOfView = v
    _G.IH.Config.Player.FOV = v
end

LP.CharacterAdded:Connect(function()
    task.wait(1.5)
    if _G.IH.Config.Player.Fly then _G.IH.StartFly() end
end)

-- ═══════════════════════════════════════════════
-- FARM SYSTEM
-- ═══════════════════════════════════════════════
local farmThread = nil

local function tpTo(pos)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(pos + Vector3.new(0,3.5,0)) end
end

local function findScrapper()
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("scrapper") or n:find("scrap") or n:find("sell") then
            local part = obj:IsA("BasePart") and obj
                or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
            if part then return part end
        end
    end
    for _, pp in ipairs(workspace:GetDescendants()) do
        if pp:IsA("ProximityPrompt") then
            local t = (pp.ActionText or ""):lower()
            if t:find("sell") or t:find("scrap") then
                local part = pp.Parent:IsA("BasePart") and pp.Parent
                    or pp.Parent:FindFirstChildOfClass("BasePart")
                if part then return part end
            end
        end
    end
    return nil
end

local function collectItem(part)
    if not part or not part.Parent then return end
    tpTo(part.Position)
    task.wait(0.08)
    local pp = part:FindFirstChildOfClass("ProximityPrompt")
        or (part.Parent and part.Parent:FindFirstChildOfClass("ProximityPrompt"))
    if pp then pcall(function() fireproximityprompt(pp) end); return end
    pcall(function()
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if root then
            firetouchinterest(root, part, 0)
            task.wait(0.05)
            firetouchinterest(root, part, 1)
        end
    end)
end

function _G.IH.StartFarm()
    if farmThread then return end
    _G.IH.Config.Farm.Active = true
    farmThread = task.spawn(function()
        while _G.IH.Config.Farm.Active do
            local found = {}
            for _, obj in ipairs(workspace:GetDescendants()) do
                if not _G.IH.IsPlayerPart(obj) then
                    for _, item in ipairs(_G.IH.Items) do
                        local match = _G.IH.Config.Farm.SelectedItem == "All"
                            or _G.IH.Config.Farm.SelectedItem == item.name
                        if match and obj.Name:lower():find(item.name:lower()) then
                            local part = obj:IsA("BasePart") and obj
                                or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
                            if part and part.Parent then
                                table.insert(found, part)
                            end
                            break
                        end
                    end
                end
            end
            for _, part in ipairs(found) do
                if not _G.IH.Config.Farm.Active then break end
                pcall(collectItem, part)
                task.wait(_G.IH.Config.Farm.Delay)
            end
            if _G.IH.Config.Farm.AutoSell and #found > 0 then
                local scrap = findScrapper()
                if scrap then
                    tpTo(scrap.Position)
                    task.wait(0.8)
                    local pp = scrap:FindFirstChildOfClass("ProximityPrompt")
                        or scrap.Parent:FindFirstChildOfClass("ProximityPrompt")
                    if pp then pcall(function() fireproximityprompt(pp) end) end
                    task.wait(0.3)
                end
            end
            task.wait(0.3)
        end
        farmThread = nil
    end)
end

function _G.IH.StopFarm()
    _G.IH.Config.Farm.Active = false
    farmThread = nil
end

-- ═══════════════════════════════════════════════
-- GUI SYSTEM
-- ═══════════════════════════════════════════════
local ok, err = pcall(function()

local H = gethui()
pcall(function()
    for _, v in ipairs(H:GetChildren()) do
        if v.Name == "IH_GUI" or v.Name == "IH_Btn" then v:Destroy() end
    end
end)

local SG = Instance.new("ScreenGui")
SG.Name = "IH_GUI"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder = 999
SG.Parent = H
_G.IH.GUI = SG

-- Helpers
local function mkC(p,r)
    local c=Instance.new("UICorner",p);c.CornerRadius=UDim.new(0,r or 8);return c
end
local function mkS(p,col,th,tr)
    local s=Instance.new("UIStroke",p)
    s.Color=col or Color3.fromRGB(60,60,80)
    s.Thickness=th or 1;s.Transparency=tr or 0.5;return s
end
local function mkL(p,txt,sz,col,fnt,pos,size,xa)
    local l=Instance.new("TextLabel",p)
    l.BackgroundTransparency=1;l.Text=txt;l.TextSize=sz or 13
    l.TextColor3=col or Color3.fromRGB(225,225,225)
    l.Font=fnt or Enum.Font.Gotham
    l.Position=pos or UDim2.new(0,0,0,0)
    l.Size=size or UDim2.new(1,0,1,0)
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextTruncate=Enum.TextTruncate.AtEnd;return l
end

-- Toggle
local function mkToggle(parent,yPos,txt,init,cb)
    local row=Instance.new("Frame",parent)
    row.BackgroundTransparency=1
    row.Position=UDim2.new(0,0,0,yPos)
    row.Size=UDim2.new(1,0,0,36)
    mkC(row,6)

    mkL(row,txt,13,Color3.fromRGB(210,210,215),Enum.Font.Gotham,
        UDim2.new(0,12,0,0),UDim2.new(1,-68,1,0))

    local bg=Instance.new("Frame",row)
    bg.Size=UDim2.new(0,44,0,22)
    bg.Position=UDim2.new(1,-54,0.5,-11)
    bg.BackgroundColor3=init and Color3.fromRGB(139,92,246) or Color3.fromRGB(40,40,52)
    bg.BorderSizePixel=0;mkC(bg,11)

    local dot=Instance.new("Frame",bg)
    dot.Size=UDim2.new(0,16,0,16)
    dot.Position=init and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8)
    dot.BackgroundColor3=Color3.fromRGB(255,255,255)
    dot.BorderSizePixel=0;mkC(dot,8)

    local state=init
    local function upd(s)
        state=s
        TweenService:Create(bg,TweenInfo.new(0.15),{
            BackgroundColor3=s and Color3.fromRGB(139,92,246) or Color3.fromRGB(40,40,52)
        }):Play()
        TweenService:Create(dot,TweenInfo.new(0.15),{
            Position=s and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8)
        }):Play()
    end

    local btn=Instance.new("TextButton",row)
    btn.BackgroundTransparency=1;btn.Size=UDim2.new(1,0,1,0)
    btn.Text="";btn.ZIndex=2
    btn.MouseButton1Click:Connect(function() upd(not state);pcall(cb,state) end)
    btn.MouseEnter:Connect(function()
        row.BackgroundTransparency=0.85
        row.BackgroundColor3=Color3.fromRGB(20,20,30)
    end)
    btn.MouseLeave:Connect(function() row.BackgroundTransparency=1 end)

    return row,upd
end

-- Slider
local function mkSlider(parent,yPos,txt,mn,mx,val,cb)
    local row=Instance.new("Frame",parent)
    row.BackgroundTransparency=1
    row.Position=UDim2.new(0,0,0,yPos)
    row.Size=UDim2.new(1,0,0,50)

    mkL(row,txt,12,Color3.fromRGB(185,185,195),Enum.Font.Gotham,
        UDim2.new(0,12,0,2),UDim2.new(0.65,0,0,18))

    local vBox=Instance.new("TextBox",row)
    vBox.Size=UDim2.new(0,60,0,24);vBox.Position=UDim2.new(1,-72,0,12)
    vBox.BackgroundColor3=Color3.fromRGB(18,18,26)
    vBox.TextColor3=Color3.fromRGB(225,225,225)
    vBox.Text=tostring(val);vBox.TextSize=12
    vBox.Font=Enum.Font.GothamBold;vBox.ClearTextOnFocus=false
    vBox.BorderSizePixel=0;mkC(vBox,5)
    mkS(vBox,Color3.fromRGB(70,50,110),1,0.3)

    local track=Instance.new("Frame",row)
    track.Position=UDim2.new(0,12,0,36)
    track.Size=UDim2.new(1,-90,0,4)
    track.BackgroundColor3=Color3.fromRGB(35,35,46)
    track.BorderSizePixel=0;mkC(track,2)

    local fill=Instance.new("Frame",track)
    fill.BackgroundColor3=Color3.fromRGB(139,92,246)
    fill.Size=UDim2.new((val-mn)/(mx-mn),0,1,0)
    fill.BorderSizePixel=0;mkC(fill,2)

    local thumb=Instance.new("Frame",track)
    thumb.Size=UDim2.new(0,12,0,12)
    thumb.Position=UDim2.new((val-mn)/(mx-mn),-6,0.5,-6)
    thumb.BackgroundColor3=Color3.fromRGB(255,255,255)
    thumb.BorderSizePixel=0;mkC(thumb,6)
    mkS(thumb,Color3.fromRGB(139,92,246),1.2,0)

    local function setVal(v)
        v=math.clamp(math.floor(v+0.5),mn,mx)
        local pct=(v-mn)/(mx-mn)
        vBox.Text=tostring(v)
        TweenService:Create(fill,TweenInfo.new(0.08),{Size=UDim2.new(pct,0,1,0)}):Play()
        TweenService:Create(thumb,TweenInfo.new(0.08),{Position=UDim2.new(pct,-6,0.5,-6)}):Play()
        pcall(cb,v)
    end

    vBox.FocusLost:Connect(function()
        local n=tonumber(vBox.Text);if n then setVal(n) end
    end)

    local dragging=false
    local dbtn=Instance.new("TextButton",track)
    dbtn.BackgroundTransparency=1;dbtn.Size=UDim2.new(1,0,1,16)
    dbtn.Position=UDim2.new(0,0,0,-8);dbtn.Text="";dbtn.ZIndex=3
    dbtn.MouseButton1Down:Connect(function() dragging=true end)
    _G.IH.AddConn(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or
           i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end))
    _G.IH.AddConn(UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or
           i.UserInputType==Enum.UserInputType.Touch then
            local abs=track.AbsolutePosition;local sz=track.AbsoluteSize
            local px=UserInputService:GetMouseLocation().X
            setVal(mn+math.clamp((px-abs.X)/sz.X,0,1)*(mx-mn))
        end
    end))
    return row,setVal
end

-- ═══ MAIN WINDOW ═══
local cols=_G.IH.Config.Colors

local Main=Instance.new("Frame",SG)
Main.Name="Main"
Main.Size=UDim2.new(0,520,0,390)
Main.Position=UDim2.new(0.5,-260,0.5,-195)
Main.BackgroundColor3=cols.BG
Main.BorderSizePixel=0
Main.ClipsDescendants=true
mkC(Main,12)
mkS(Main,Color3.fromRGB(80,45,130),1.5,0.1)

-- Gradient BG
local grad=Instance.new("UIGradient",Main)
grad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(18,13,28)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(13,13,18)),
}
grad.Rotation=135

-- Titlebar
local TB=Instance.new("Frame",Main)
TB.Size=UDim2.new(1,0,0,36)
TB.BackgroundColor3=Color3.fromRGB(10,8,16)
TB.BorderSizePixel=0
mkS(TB,Color3.fromRGB(60,35,100),1,0.3)

-- Logo glow
local logoWrap=Instance.new("Frame",TB)
logoWrap.Size=UDim2.new(0,26,0,26)
logoWrap.Position=UDim2.new(0,8,0.5,-13)
logoWrap.BackgroundColor3=Color3.fromRGB(139,92,246)
logoWrap.BorderSizePixel=0
mkC(logoWrap,7)
mkS(logoWrap,Color3.fromRGB(180,150,255),1.5,0.1)
local lt=Instance.new("TextLabel",logoWrap)
lt.Size=UDim2.new(1,0,1,0);lt.BackgroundTransparency=1
lt.Text="IH";lt.TextColor3=Color3.fromRGB(255,255,255)
lt.TextSize=10;lt.Font=Enum.Font.GothamBold
lt.TextXAlignment=Enum.TextXAlignment.Center

mkL(TB,"Indonesia Hub",13,Color3.fromRGB(200,180,255),Enum.Font.GothamBold,
    UDim2.new(0,42,0,0),UDim2.new(0.55,0,1,0))

-- Version badge
local vbadge=Instance.new("TextLabel",TB)
vbadge.Size=UDim2.new(0,36,0,16)
vbadge.Position=UDim2.new(0,145,0.5,-8)
vbadge.BackgroundColor3=Color3.fromRGB(80,45,130)
vbadge.Text="v4.1"
vbadge.TextColor3=Color3.fromRGB(200,180,255)
vbadge.TextSize=9;vbadge.Font=Enum.Font.GothamBold
vbadge.BorderSizePixel=0
mkC(vbadge,4)

-- Title buttons
local function mkTBtn(xOff,col,txt,cb)
    local b=Instance.new("TextButton",TB)
    b.Size=UDim2.new(0,20,0,20)
    b.Position=UDim2.new(1,xOff,0.5,-10)
    b.BackgroundColor3=col;b.Text=txt
    b.TextColor3=Color3.fromRGB(255,255,255)
    b.TextSize=10;b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0;mkC(b,5)
    b.MouseButton1Click:Connect(cb)
    return b
end
mkTBtn(-6, Color3.fromRGB(200,50,50),"✕",function() Main.Visible=false end)
mkTBtn(-30,Color3.fromRGB(40,40,55),"—",function()
    Main.Size=Main.Size.Y.Offset>40
        and UDim2.new(0,520,0,36) or UDim2.new(0,520,0,390)
end)

-- Drag
local drag,dSt,dPos=false,nil,nil
TB.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or
       i.UserInputType==Enum.UserInputType.Touch then
        drag=true;dSt=i.Position;dPos=Main.Position
    end
end)
_G.IH.AddConn(UserInputService.InputChanged:Connect(function(i)
    if not drag then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement or
       i.UserInputType==Enum.UserInputType.Touch then
        local d=i.Position-dSt
        Main.Position=UDim2.new(dPos.X.Scale,dPos.X.Offset+d.X,
            dPos.Y.Scale,dPos.Y.Offset+d.Y)
    end
end))
_G.IH.AddConn(UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or
       i.UserInputType==Enum.UserInputType.Touch then drag=false end
end))

-- Sidebar
local SB=Instance.new("Frame",Main)
SB.Size=UDim2.new(0,145,1,-36)
SB.Position=UDim2.new(0,0,0,36)
SB.BackgroundColor3=Color3.fromRGB(8,6,14)
SB.BorderSizePixel=0
mkS(SB,Color3.fromRGB(50,30,80),1,0.3)

-- Sidebar gradient
local sbgrad=Instance.new("UIGradient",SB)
sbgrad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(12,8,20)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(8,6,14)),
}
sbgrad.Rotation=180

-- Content
local CT=Instance.new("Frame",Main)
CT.Size=UDim2.new(1,-149,1,-40)
CT.Position=UDim2.new(0,147,0,38)
CT.BackgroundTransparency=1
CT.ClipsDescendants=true

-- Divider
local div=Instance.new("Frame",Main)
div.Size=UDim2.new(0,1,1,-36)
div.Position=UDim2.new(0,145,0,36)
div.BackgroundColor3=Color3.fromRGB(80,45,130)
div.BackgroundTransparency=0.5
div.BorderSizePixel=0

-- Tabs
local tabBtns={}
local tabFrames={}
local tabList={
    {id="player", ico="👤",lbl="Player"},
    {id="visuals",ico="👁", lbl="Visuals"},
    {id="farm",   ico="🌾",lbl="Farm"},
    {id="settings",ico="⚙",lbl="Settings"},
    {id="about",  ico="ℹ", lbl="About"},
}

local function switchTab(id)
    for tid,fr in pairs(tabFrames) do fr.Visible=tid==id end
    for tid,bt in pairs(tabBtns) do
        local a=tid==id
        local activeCol=Color3.fromRGB(22,16,38)
        TweenService:Create(bt,TweenInfo.new(0.12),{
            BackgroundColor3=a and activeCol or Color3.fromRGB(8,6,14),
            BackgroundTransparency=a and 0 or 1,
        }):Play()
        -- Active indicator
        local ind=bt:FindFirstChild("Indicator")
        if ind then
            TweenService:Create(ind,TweenInfo.new(0.12),{
                BackgroundTransparency=a and 0 or 1
            }):Play()
        end
        local lbl=bt:FindFirstChild("TabLabel")
        if lbl then
            lbl.TextColor3=a and Color3.fromRGB(175,145,255) or Color3.fromRGB(100,100,120)
        end
        local ico=bt:FindFirstChild("TabIcon")
        if ico then
            ico.TextColor3=a and Color3.fromRGB(175,145,255) or Color3.fromRGB(100,100,120)
        end
    end
end

for i,t in ipairs(tabList) do
    local btn=Instance.new("TextButton",SB)
    btn.Size=UDim2.new(1,-10,0,34)
    btn.Position=UDim2.new(0,5,0,8+(i-1)*38)
    btn.BackgroundTransparency=1
    btn.Text="";btn.BorderSizePixel=0
    mkC(btn,7)

    -- Active indicator bar
    local ind=Instance.new("Frame",btn)
    ind.Name="Indicator"
    ind.Size=UDim2.new(0,3,0.6,0)
    ind.Position=UDim2.new(0,0,0.2,0)
    ind.BackgroundColor3=Color3.fromRGB(139,92,246)
    ind.BackgroundTransparency=1
    ind.BorderSizePixel=0
    mkC(ind,2)

    local ico=Instance.new("TextLabel",btn)
    ico.Name="TabIcon"
    ico.Size=UDim2.new(0,24,1,0)
    ico.Position=UDim2.new(0,10,0,0)
    ico.BackgroundTransparency=1
    ico.Text=t.ico;ico.TextSize=14
    ico.Font=Enum.Font.GothamBold
    ico.TextColor3=Color3.fromRGB(100,100,120)
    ico.TextXAlignment=Enum.TextXAlignment.Center

    local lbl=Instance.new("TextLabel",btn)
    lbl.Name="TabLabel"
    lbl.Size=UDim2.new(1,-38,1,0)
    lbl.Position=UDim2.new(0,36,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=t.lbl;lbl.TextSize=12
    lbl.Font=Enum.Font.GothamBold
    lbl.TextColor3=Color3.fromRGB(100,100,120)
    lbl.TextXAlignment=Enum.TextXAlignment.Left

    local sf=Instance.new("ScrollingFrame",CT)
    sf.Size=UDim2.new(1,0,1,0)
    sf.BackgroundTransparency=1
    sf.BorderSizePixel=0
    sf.ScrollBarThickness=2
    sf.ScrollBarImageColor3=Color3.fromRGB(90,65,150)
    sf.CanvasSize=UDim2.new(0,0,0,600)
    sf.Visible=false

    tabBtns[t.id]=btn
    tabFrames[t.id]=sf
    btn.MouseButton1Click:Connect(function() switchTab(t.id) end)
end

-- ═══ PLAYER TAB ═══
local pf=tabFrames.player;local py=6
mkToggle(pf,py,"Fly",_G.IH.Config.Player.Fly,function(s)
    _G.IH.Config.Player.Fly=s
    if s then _G.IH.StartFly() else _G.IH.StopFly() end
end);py+=40
mkSlider(pf,py,"Fly Speed",10,300,_G.IH.Config.Player.FlySpeed,function(v)
    _G.IH.Config.Player.FlySpeed=v
end);py+=54
mkSlider(pf,py,"FOV",50,120,_G.IH.Config.Player.FOV,function(v)
    _G.IH.SetFOV(v)
end);py+=54
mkToggle(pf,py,"Noclip",_G.IH.Config.Player.Noclip,function(s)
    _G.IH.Config.Player.Noclip=s
end);py+=40
mkToggle(pf,py,"Infinite Jump",_G.IH.Config.Player.InfJump,function(s)
    _G.IH.Config.Player.InfJump=s
end);py+=40
mkToggle(pf,py,"TP Walk",_G.IH.Config.Player.TpWalk,function(s)
    _G.IH.Config.Player.TpWalk=s
end);py+=40
mkSlider(pf,py,"TP Speed",10,200,_G.IH.Config.Player.TpWalkSpeed,function(v)
    _G.IH.Config.Player.TpWalkSpeed=v
end);py+=54
mkToggle(pf,py,"Speed Hack",_G.IH.Config.Player.Speed,function(s)
    _G.IH.Config.Player.Speed=s
end);py+=40
mkSlider(pf,py,"Speed Value",16,500,_G.IH.Config.Player.SpeedVal,function(v)
    _G.IH.Config.Player.SpeedVal=v
end);py+=54
pf.CanvasSize=UDim2.new(0,0,0,py+10)

-- ═══ VISUALS TAB ═══
local vf=tabFrames.visuals;local vy=6
mkToggle(vf,vy,"Monster ESP",_G.IH.Config.ESP.Monster,function(s)
    _G.IH.Config.ESP.Monster=s
end);vy+=40
mkToggle(vf,vy,"Player ESP",_G.IH.Config.ESP.Player,function(s)
    _G.IH.Config.ESP.Player=s
end);vy+=40
mkToggle(vf,vy,"Item ESP",_G.IH.Config.ESP.Item,function(s)
    _G.IH.Config.ESP.Item=s
end);vy+=40
mkSlider(vf,vy,"Max Distance",50,1000,_G.IH.Config.ESP.MaxDist,function(v)
    _G.IH.Config.ESP.MaxDist=v
end);vy+=54
mkSlider(vf,vy,"ESP Text Size",8,16,_G.IH.Config.ESP.TextSize,function(v)
    _G.IH.Config.ESP.TextSize=v
end);vy+=54
vf.CanvasSize=UDim2.new(0,0,0,vy+10)

-- ═══ FARM TAB ═══
local ff=tabFrames.farm;local fy=6
mkToggle(ff,fy,"Farm All Items",_G.IH.Config.Farm.SelectedItem=="All",function(s)
    _G.IH.Config.Farm.SelectedItem=s and "All" or _G.IH.Items[1].name
end);fy+=40
mkToggle(ff,fy,"Auto Sell (Scrapper)",_G.IH.Config.Farm.AutoSell,function(s)
    _G.IH.Config.Farm.AutoSell=s
end);fy+=40
mkSlider(ff,fy,"Farm Delay (ms)",50,500,_G.IH.Config.Farm.Delay*1000,function(v)
    _G.IH.Config.Farm.Delay=v/1000
end);fy+=54

local frow=Instance.new("Frame",ff)
frow.BackgroundTransparency=1
frow.Position=UDim2.new(0,0,0,fy)
frow.Size=UDim2.new(1,0,0,36)
local fbtn=Instance.new("TextButton",frow)
fbtn.Size=UDim2.new(1,-24,0,30)
fbtn.Position=UDim2.new(0,12,0,3)
fbtn.BackgroundColor3=Color3.fromRGB(45,170,90)
fbtn.Text="▶  Start Farm"
fbtn.TextColor3=Color3.fromRGB(255,255,255)
fbtn.TextSize=13;fbtn.Font=Enum.Font.GothamBold
fbtn.BorderSizePixel=0;mkC(fbtn,7)
mkS(fbtn,Color3.fromRGB(80,220,130),1,0.5)
local farmOn=false
fbtn.MouseButton1Click:Connect(function()
    farmOn=not farmOn
    if farmOn then
        fbtn.Text="⏹  Stop Farm"
        fbtn.BackgroundColor3=Color3.fromRGB(190,55,55)
        mkS(fbtn,Color3.fromRGB(255,100,100),1,0.5)
        _G.IH.StartFarm()
    else
        fbtn.Text="▶  Start Farm"
        fbtn.BackgroundColor3=Color3.fromRGB(45,170,90)
        mkS(fbtn,Color3.fromRGB(80,220,130),1,0.5)
        _G.IH.StopFarm()
    end
end)
fy+=44

local selL=Instance.new("TextLabel",ff)
selL.Position=UDim2.new(0,12,0,fy)
selL.Size=UDim2.new(1,-24,0,16)
selL.BackgroundTransparency=1
selL.Text="Select Item:"
selL.TextColor3=Color3.fromRGB(150,150,170)
selL.TextSize=11;selL.Font=Enum.Font.GothamBold
selL.TextXAlignment=Enum.TextXAlignment.Left
fy+=20

local grid=Instance.new("Frame",ff)
grid.Position=UDim2.new(0,8,0,fy)
grid.Size=UDim2.new(1,-16,0,10)
grid.BackgroundTransparency=1
local uigl=Instance.new("UIGridLayout",grid)
uigl.CellSize=UDim2.new(0,100,0,24)
uigl.CellPadding=UDim2.new(0,4,0,4)
uigl.SortOrder=Enum.SortOrder.LayoutOrder

local function refreshGrid(sel)
    for _,b in ipairs(grid:GetChildren()) do
        if b:IsA("TextButton") then
            b.BackgroundColor3=b.Text==sel
                and Color3.fromRGB(85,50,140) or Color3.fromRGB(18,18,28)
        end
    end
end
for _,item in ipairs(_G.IH.Items) do
    local ib=Instance.new("TextButton",grid)
    ib.Size=UDim2.new(0,100,0,24)
    ib.BackgroundColor3=_G.IH.Config.Farm.SelectedItem==item.name
        and Color3.fromRGB(85,50,140) or Color3.fromRGB(18,18,28)
    ib.Text=item.name;ib.TextColor3=Color3.fromRGB(205,205,215)
    ib.TextSize=10;ib.Font=Enum.Font.Gotham
    ib.BorderSizePixel=0;mkC(ib,5)
    mkS(ib,Color3.fromRGB(50,38,80),1,0.4)
    ib.MouseButton1Click:Connect(function()
        _G.IH.Config.Farm.SelectedItem=item.name
        refreshGrid(item.name)
    end)
end
local gridH=math.ceil(#_G.IH.Items/4)*28+4
grid.Size=UDim2.new(1,-16,0,gridH)
fy=fy+gridH+10
ff.CanvasSize=UDim2.new(0,0,0,fy)

-- ═══ SETTINGS TAB ═══
local sf=tabFrames.settings;local sy=6
local lrow=Instance.new("Frame",sf)
lrow.BackgroundTransparency=1
lrow.Position=UDim2.new(0,0,0,sy)
lrow.Size=UDim2.new(1,0,0,34)
local ll=Instance.new("TextLabel",lrow)
ll.BackgroundTransparency=1;ll.Position=UDim2.new(0,12,0,0)
ll.Size=UDim2.new(0.5,0,1,0);ll.Text="Language / Bahasa"
ll.TextColor3=Color3.fromRGB(185,185,200);ll.TextSize=12
ll.Font=Enum.Font.Gotham;ll.TextXAlignment=Enum.TextXAlignment.Left
local function mkLB(p,xOff,txt,act)
    local b=Instance.new("TextButton",p)
    b.Size=UDim2.new(0,44,0,22);b.Position=UDim2.new(1,xOff,0.5,-11)
    b.BackgroundColor3=act and Color3.fromRGB(95,50,170) or Color3.fromRGB(22,22,32)
    b.Text=txt;b.TextColor3=Color3.fromRGB(235,235,235)
    b.TextSize=11;b.Font=Enum.Font.GothamBold;b.BorderSizePixel=0;mkC(b,5)
    return b
end
local enB=mkLB(lrow,-96,"EN",_G.IH.Config.Lang=="EN")
local idB=mkLB(lrow,-48,"ID",_G.IH.Config.Lang=="ID")
local function setLang(l)
    _G.IH.Config.Lang=l
    enB.BackgroundColor3=l=="EN" and Color3.fromRGB(95,50,170) or Color3.fromRGB(22,22,32)
    idB.BackgroundColor3=l=="ID" and Color3.fromRGB(95,50,170) or Color3.fromRGB(22,22,32)
end
enB.MouseButton1Click:Connect(function() setLang("EN") end)
idB.MouseButton1Click:Connect(function() setLang("ID") end)
sy+=42

local colorDefs={
    {key="Accent", lbl="Accent"},
    {key="Monster",lbl="Monster ESP"},
    {key="Player", lbl="Player ESP"},
    {key="Item",   lbl="Item ESP"},
}
local presets={
    Color3.fromRGB(139,92,246),Color3.fromRGB(255,60,60),
    Color3.fromRGB(60,150,255),Color3.fromRGB(60,215,110),
    Color3.fromRGB(255,175,45),Color3.fromRGB(255,95,175),
    Color3.fromRGB(255,255,255),
}
for _,cd in ipairs(colorDefs) do
    local crow=Instance.new("Frame",sf)
    crow.BackgroundTransparency=1;crow.Position=UDim2.new(0,0,0,sy)
    crow.Size=UDim2.new(1,0,0,34)
    local cl=Instance.new("TextLabel",crow)
    cl.BackgroundTransparency=1;cl.Position=UDim2.new(0,12,0,0)
    cl.Size=UDim2.new(0.4,0,1,0);cl.Text=cd.lbl
    cl.TextColor3=Color3.fromRGB(180,180,200);cl.TextSize=11
    cl.Font=Enum.Font.Gotham;cl.TextXAlignment=Enum.TextXAlignment.Left
    for i,col in ipairs(presets) do
        local db=Instance.new("TextButton",crow)
        db.Size=UDim2.new(0,18,0,18);db.Position=UDim2.new(0,118+(i-1)*24,0.5,-9)
        db.BackgroundColor3=col;db.Text="";db.BorderSizePixel=0;mkC(db,9)
        db.MouseButton1Click:Connect(function() _G.IH.Config.Colors[cd.key]=col end)
    end
    sy+=38
end
sf.CanvasSize=UDim2.new(0,0,0,sy+10)

-- ═══ ABOUT TAB ═══
local af=tabFrames.about
local abox=Instance.new("Frame",af)
abox.Position=UDim2.new(0,10,0,10)
abox.Size=UDim2.new(1,-20,0,210)
abox.BackgroundColor3=Color3.fromRGB(10,8,16)
abox.BorderSizePixel=0;mkC(abox,12)
mkS(abox,Color3.fromRGB(80,45,130),1.5,0.1)
local agrad=Instance.new("UIGradient",abox)
agrad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(18,12,30)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(10,8,16)),
}
agrad.Rotation=135
local al=Instance.new("TextLabel",abox)
al.Size=UDim2.new(1,0,0,50);al.Position=UDim2.new(0,0,0,8)
al.BackgroundTransparency=1;al.Text="🇮🇩 Indonesia Hub"
al.TextColor3=Color3.fromRGB(175,145,255);al.TextSize=20
al.Font=Enum.Font.GothamBold;al.TextXAlignment=Enum.TextXAlignment.Center
local ad=Instance.new("TextLabel",abox)
ad.Size=UDim2.new(1,-16,0,145);ad.Position=UDim2.new(0,8,0,56)
ad.BackgroundTransparency=1
ad.Text="Lethal Ape Script v4.1\n\n✅ ESP: Monster, Player, Item\n✅ Player: Fly, Noclip, TpWalk\n✅ Speed Hack & FOV Changer\n✅ Farm: Auto Collect & Sell\n✅ Settings: Color & Language\n\nRShift = Toggle GUI\nBy: Indonesia Hub Community"
ad.TextColor3=Color3.fromRGB(140,140,160);ad.TextSize=11
ad.Font=Enum.Font.Gotham;ad.TextWrapped=true
ad.TextXAlignment=Enum.TextXAlignment.Center
af.CanvasSize=UDim2.new(0,0,0,230)

switchTab("player")

-- ═══ OPEN BUTTON (Floating) ═══
local BG=Instance.new("ScreenGui")
BG.Name="IH_Btn";BG.ResetOnSpawn=false
BG.DisplayOrder=998;BG.Parent=H
_G.IH.BtnGUI=BG

-- Background button
local btnFrame=Instance.new("Frame",BG)
btnFrame.Size=UDim2.new(0,52,0,52)
btnFrame.Position=UDim2.new(0,8,0.5,-26)
btnFrame.BackgroundColor3=Color3.fromRGB(10,8,18)
btnFrame.BorderSizePixel=0;mkC(btnFrame,14)
mkS(btnFrame,Color3.fromRGB(100,60,180),2,0.1)

-- Glow effect
local glow=Instance.new("Frame",btnFrame)
glow.Size=UDim2.new(1,10,1,10)
glow.Position=UDim2.new(0,-5,0,-5)
glow.BackgroundColor3=Color3.fromRGB(100,60,180)
glow.BackgroundTransparency=0.85
glow.BorderSizePixel=0;mkC(glow,18)
glow.ZIndex=0

-- Gradient on button
local btnGrad=Instance.new("UIGradient",btnFrame)
btnGrad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(100,60,200)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(60,30,120)),
}
btnGrad.Rotation=135

local btnTxt=Instance.new("TextLabel",btnFrame)
btnTxt.Size=UDim2.new(1,0,0.55,0)
btnTxt.Position=UDim2.new(0,0,0,4)
btnTxt.BackgroundTransparency=1
btnTxt.Text="IH"
btnTxt.TextColor3=Color3.fromRGB(255,255,255)
btnTxt.TextSize=14;btnTxt.Font=Enum.Font.GothamBold
btnTxt.TextXAlignment=Enum.TextXAlignment.Center

local btnSub=Instance.new("TextLabel",btnFrame)
btnSub.Size=UDim2.new(1,0,0.35,0)
btnSub.Position=UDim2.new(0,0,0.62,0)
btnSub.BackgroundTransparency=1
btnSub.Text="v4.1"
btnSub.TextColor3=Color3.fromRGB(180,150,255)
btnSub.TextSize=8;btnSub.Font=Enum.Font.Gotham
btnSub.TextXAlignment=Enum.TextXAlignment.Center

-- Pulse animation
local pulsing=true
task.spawn(function()
    while pulsing do
        TweenService:Create(glow,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
            BackgroundTransparency=0.7
        }):Play()
        task.wait(1)
        TweenService:Create(glow,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
            BackgroundTransparency=0.92
        }):Play()
        task.wait(1)
    end
end)

local ob=Instance.new("TextButton",btnFrame)
ob.Size=UDim2.new(1,0,1,0);ob.BackgroundTransparency=1
ob.Text="";ob.ZIndex=2
ob.MouseButton1Click:Connect(function()
    Main.Visible=not Main.Visible
    if Main.Visible then Main.Size=UDim2.new(0,520,0,390) end
    -- Animasi button klik
    TweenService:Create(btnFrame,TweenInfo.new(0.1),{
        Size=UDim2.new(0,46,0,46),Position=UDim2.new(0,11,0.5,-23)
    }):Play()
    task.wait(0.1)
    TweenService:Create(btnFrame,TweenInfo.new(0.1),{
        Size=UDim2.new(0,52,0,52),Position=UDim2.new(0,8,0.5,-26)
    }):Play()
end)

-- Toggle RShift
_G.IH.AddConn(UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.RightShift then
        Main.Visible=not Main.Visible
        if Main.Visible then Main.Size=UDim2.new(0,520,0,390) end
    end
end))

end)

if not ok then
    warn("[IH] GUI Error: "..tostring(err))
else
    print("╔══════════════════════════════╗")
    print("║   INDONESIA HUB v4.1 ✓      ║")
    print("║   Tombol IH = Buka/Tutup UI ║")
    print("║   RShift   = Toggle GUI     ║")
    print("╚══════════════════════════════╝")
end
