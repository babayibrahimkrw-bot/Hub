-- LILA HUB | GALAXY EDITION | V.2 FIXED (PART 1)
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera

local function notify(t,x)
	pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=t,Text=tostring(x):sub(1,190),Duration=6}) end)
end
local function C(r,g,b) return Color3.fromRGB(r,g,b) end

local ITEMS={
	{"Red Gold","red gold",150,C(255,40,70)}, {"Ruby","ruby",35,C(255,40,70)},
	{"Crystal Bars","crystal bar",24,C(190,120,255)}, {"Emerald","emerald",10,C(60,255,120)},
	{"Amethyst","amethyst",10,C(190,120,255)}, {"Diamond","diamond",7,C(120,230,255)},
	{"Crystal","crystal",4,C(190,120,255)}, {"Meat","meat",3,C(255,130,110)},
	{"Gold Ingot","gold",2,C(255,210,40)}, {"Iron","iron",2,C(200,205,215)},
	{"Copper","copper",1,C(230,130,60)},
}
local IGNORE={"shop","merchant","dummy"}
local SELLKEYS={"scrapper","scrap","sell","recycl","trade"}
local MON_LIST={"mon","???","Acidman","Ashes","Big Guy","Bill","Bloodman","Blud","Bob","Clyde","Devil","Ghost","Gus","Lurker","Meatman","Primate","Sandman","Scar","Taller"}
local MON={}
for _,n in ipairs(MON_LIST) do MON[n:lower()]=true end
local MONCOL=C(255,50,50)

local S={mon=false,alert=false,tp=false,farm=false,farmAll=false,sell=false,fb=false,afk=false,noclip=false,autoheal=false,fly=false,infjump=false}
local I={}
for _,it in ipairs(ITEMS) do I[it[1]]=false end
local cfg={target=2,tp=30,dist=500,alertD=60,sellIdx=3,flySpeed=50,fov=120}
local SELLN={1,3,5,10,20}

local conns,alive={},true
local function bind(sg,fn) local c=sg:Connect(fn) conns[#conns+1]=c return c end

local gui=Instance.new("ScreenGui") gui.Name="LILA_HUB" gui.ResetOnSpawn=false gui.DisplayOrder=999
local done=false
for _,g in ipairs({function() return lp:WaitForChild("PlayerGui",5) end, function() return gethui() end, function() return game:GetService("CoreGui") end}) do
	local ok,p=pcall(g)
	if ok and p and not done then
		pcall(function() local o=p:FindFirstChild("LILA_HUB") if o then o:Destroy() end end)
		if pcall(function() gui.Parent=p end) and gui.Parent==p then done=true end
	end
end
if not done then error("GUI failed") end

local BG=C(20,15,30) local ACCENT=C(180,50,255) local GREEN=C(0,255,100) local WHITE=C(255,255,255) local GREY=C(150,150,150)
local function corner(o,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=o end
local function mk(class,props,parent) local o=Instance.new(class) for k,v in pairs(props) do o[k]=v end if parent then o.Parent=parent end return o end

local main=mk("Frame",{Size=UDim2.fromOffset(500,300),Position=UDim2.new(0.5,-250,0.5,-150),BackgroundColor3=BG,BorderSizePixel=0},gui)
corner(main,10)
local bgGrad = mk("UIGradient",{Color=ColorSequence.new(C(60,20,80),C(10,5,15)),Rotation=45},main)

local topBar=mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=C(30,20,45),BackgroundTransparency=0.5},main) corner(topBar,10)
mk("TextLabel",{Size=UDim2.new(1,-100,1,0),Position=UDim2.fromOffset(10,0),BackgroundTransparency=1,Text="✖  Lila Hub V.2",TextColor3=WHITE,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},topBar)
local closeBtn=mk("TextButton",{Size=UDim2.fromOffset(25,25),Position=UDim2.new(1,-30,0,2),BackgroundTransparency=1,Text="X",TextColor3=WHITE,Font=Enum.Font.GothamBold},topBar)
bind(closeBtn.MouseButton1Click,function() gui.Enabled=false end)

local sidebar=mk("Frame",{Size=UDim2.new(0,130,1,-30),Position=UDim2.new(0,0,0,30),BackgroundColor3=C(25,20,40),BackgroundTransparency=0.2},main)
local contentArea=mk("Frame",{Size=UDim2.new(1,-140,1,-40),Position=UDim2.new(0,135,0,35),BackgroundTransparency=1},main)

local pages={}
local function createPage(name)
	local p=mk("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,Visible=false,CanvasSize=UDim2.new()},contentArea)
	mk("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},p)
	pages[name]=p
	return p
end

local pPlayer = createPage("Player")
local pVisual = createPage("Visuals")
local pFarm = createPage("Farm")
local pSet = createPage("Settings")

local function switchTab(pageName) for name, page in pairs(pages) do page.Visible = (name == pageName) end end
local function makeSideBtn(text, icon, posY, tabName)
	local btn = mk("TextButton",{Size=UDim2.new(1,-10,0,35),Position=UDim2.fromOffset(5,posY),BackgroundColor3=C(45,30,60),BackgroundTransparency=0.3,Text="  "..icon.."  "..text,TextColor3=WHITE,Font=Enum.Font.GothamMedium,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},sidebar)
	corner(btn,6) bind(btn.MouseButton1Click,function() switchTab(tabName) end)
end
makeSideBtn("Player", "👤", 10, "Player")
makeSideBtn("Visuals", "👁️", 50, "Visuals")
makeSideBtn("Farm", "🌾", 90, "Farm")
makeSideBtn("Settings", "⚙️", 130, "Settings")
-- LILA HUB | GALAXY EDITION | V.2 FIXED (PART 2)

local function makeToggle(parent, text, tbl, key, fn)
	local row = mk("Frame",{Size=UDim2.new(1,-10,0,40),BackgroundColor3=C(35,25,45),BackgroundTransparency=0.2},parent) corner(row,8)
	mk("TextLabel",{Size=UDim2.new(1,-80,1,0),Position=UDim2.fromOffset(15,0),BackgroundTransparency=1,Text=text,TextColor3=WHITE,Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left},row)
	local sw = mk("Frame",{Size=UDim2.fromOffset(50,24),Position=UDim2.new(1,-65,0.5,-12),BackgroundColor3=C(60,60,60)},row) corner(sw,12)
	local knob = mk("Frame",{Size=UDim2.fromOffset(18,18),Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=WHITE},sw) corner(knob,10)
	local hit = mk("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=""},sw)
	bind(hit.MouseButton1Click,function()
		tbl[key]=not tbl[key]
		if tbl[key] then TS:Create(sw,TweenInfo.new(0.2),{BackgroundColor3=GREEN}):Play() TS:Create(knob,TweenInfo.new(0.2),{Position=UDim2.new(1,-21,0.5,-9)}):Play()
		else TS:Create(sw,TweenInfo.new(0.2),{BackgroundColor3=C(60,60,60)}):Play() TS:Create(knob,TweenInfo.new(0.2),{Position=UDim2.new(0,3,0.5,-9)}):Play() end
		if fn then fn(tbl[key]) end
	end)
end

local function makeInput(parent, text, tbl, key)
	local row = mk("Frame",{Size=UDim2.new(1,-10,0,40),BackgroundColor3=C(35,25,45),BackgroundTransparency=0.2},parent) corner(row,8)
	mk("TextLabel",{Size=UDim2.new(1,-100,1,0),Position=UDim2.fromOffset(15,0),BackgroundTransparency=1,Text=text,TextColor3=WHITE,Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left},row)
	local box = mk("TextBox",{Size=UDim2.fromOffset(70,24),Position=UDim2.new(1,-85,0.5,-12),BackgroundColor3=C(50,40,60),Text=tostring(tbl[key]),TextColor3=WHITE,Font=Enum.Font.GothamBold,TextSize=12},row) corner(box,4)
	bind(box.FocusLost,function() local v=tonumber(box.Text) if v then tbl[key]=v else box.Text=tostring(tbl[key]) end end)
end

local function makeButton(parent, text, fn, color)
	local btn = mk("TextButton",{Size=UDim2.new(1,-10,0,40),BackgroundColor3=color or ACCENT,Text=text,TextColor3=WHITE,Font=Enum.Font.GothamBold,TextSize=14},parent) corner(btn,8)
	bind(btn.MouseButton1Click,function() fn() end)
end
-- LILA HUB | GALAXY EDITION | V.2 FIXED (PART 3)

local objs={} local danger=1e9
local function getPart(o) if o:IsA("BasePart") then return o end if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChild("HumanoidRootPart") or o:FindFirstChildWhichIsA("BasePart",true) end end
local function inPlayer(o) local m=o while m and m~=workspace do if Players:GetPlayerFromCharacter(m) then return true end m=m.Parent end return false end
local function hasTracked(o) local p=o.Parent while p and p~=workspace do if objs[p] then return true end p=p.Parent end return false end
local function destroyVis(t) if t.vis then pcall(function() t.vis.hl:Destroy() t.vis.bb:Destroy() end) t.vis=nil end end
local function removeObj(o) local t=objs[o] if t then destroyVis(t) if t.conn then pcall(function() t.conn:Disconnect() end) end objs[o]=nil end end
local function allHidden(o) if o:IsA("BasePart") then return o.Transparency>=0.95 end local any=false for _,d in ipairs(o:GetDescendants()) do if d:IsA("BasePart") then if d.Transparency<0.95 then return false end any=true end end return any end
local function taken(o,t) if not o.Parent then return true end if o:FindFirstAncestorOfClass("Tool") then return true end if inPlayer(o) then return true end local p=t.part if not p or not p.Parent then return true end if p.Position.Y<-400 then return true end if t.origin and (p.Position-t.origin).Magnitude>80 then return true end if allHidden(o) then return true end return false end

local function addObj(o,kind,col,name,price,part)
	if objs[o] then return end part=part or getPart(o) if not part then return end
	local dead={} for k in pairs(objs) do if k~=o and k:IsDescendantOf(o) then dead[#dead+1]=k end end for _,k in ipairs(dead) do removeObj(k) end
	local t={inst=o,kind=kind,col=col or MONCOL,name=name or o.Name,price=price,part=part,origin=part.Position,hum=o:IsA("Model") and o:FindFirstChildOfClass("Humanoid") or nil}
	t.conn=o.AncestryChanged:Connect(function() if not o:IsDescendantOf(workspace) or o:FindFirstAncestorOfClass("Tool") then removeObj(o) end end)
	objs[o]=t
end
local function has(l,keys) for _,k in ipairs(keys) do if l:find(k,1,true) then return true end end return false end
local function consider(o)
	if not alive then return end if o:IsA("Humanoid") then o=o.Parent end if not o or objs[o] then return end if not (o:IsA("Model") or o:IsA("BasePart")) then return end if o:FindFirstAncestorOfClass("Tool") then return end
	local l=o.Name:lower() if has(l,IGNORE) then return end
	local kind,col,price
	local isCrystalType = l:find("crystal") or l:find("amethyst") or l:find("gem") or l:find("ore")
	if MON[l] then kind="mon" col=MONCOL
	elseif o:IsA("Model") and o:FindFirstChildOfClass("Humanoid") then kind="mon" col=MONCOL
	else for _,it in ipairs(ITEMS) do if l:find(it[2],1,true) or l:sub(1,string.len(it[2]))==it[2] then kind=it[1] col=it[4] price=it[3] break end end 
		if not kind and isCrystalType then kind="Crystal" col=C(190,120,255) price=4 end end
	if not kind then return end if inPlayer(o) or hasTracked(o) then return end
	if kind~="mon" then local p=getPart(o) if not p then return end local s=p.Size if not isCrystalType and math.max(s.X,s.Y,s.Z)>80 then return end if p.Transparency>=0.95 and allHidden(o) then return end end
	addObj(o,kind,col,o.Name,price)
end
task.spawn(function() local n=0 for _,o in ipairs(workspace:GetDescendants()) do if not alive then return end pcall(consider,o) n=n+1 if n%300==0 then task.wait() end end end)
bind(workspace.DescendantAdded,function(o) task.defer(pcall,consider,o) end)

local function makeVis(t)
	local hl=Instance.new("Highlight") hl.Adornee=t.inst hl.FillColor=t.col hl.OutlineColor=t.col hl.FillTransparency=0.55 hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.Parent=gui
	local bb=Instance.new("BillboardGui") bb.Adornee=t.part bb.AlwaysOnTop=true bb.Size=UDim2.fromOffset(150,35) bb.StudsOffset=Vector3.new(0,3,0) bb.Parent=gui
	local l=Instance.new("TextLabel") l.Size=UDim2.fromScale(1,1) l.BackgroundTransparency=1 l.TextColor3=t.col l.TextStrokeTransparency=0.3 l.Font=Enum.Font.GothamBold l.TextSize=12 l.Parent=bb
	t.vis={hl=hl,bb=bb,label=l}
end
local function updateESP()
	local now=os.clock() local ch=lp.Character local hrp=ch and ch:FindFirstChild("HumanoidRootPart") local origin=hrp and hrp.Position or cam.CFrame.Position
	local show,gone={},{} danger=1e9
	for o,t in pairs(objs) do
		local kill=false
		if (not o:IsDescendantOf(workspace)) or (ch and o:IsDescendantOf(ch)) then kill=true
		elseif t.kind~="mon" and now>(t.nc or 0) then t.nc=now+0.4 if taken(o,t) then kill=true end end
		if kill then gone[#gone+1]=o
		else local p=t.part if not p or not p.Parent then p=getPart(o) t.part=p end
			if p then local d=(p.Position-origin).Magnitude t.d=d local on = (t.kind=="mon") and S.mon or I[t.kind]
				if on and d<=cfg.dist then show[#show+1]=t end
				if t.kind=="mon" and d<danger then danger=d end end end
	end
	for _,o in ipairs(gone) do removeObj(o) end table.sort(show,function(a,b) return a.d<b.d end)
	for i,t in ipairs(show) do
		if i>45 then break end t.stamp=now if not t.vis then makeVis(t) end
		t.vis.hl.Enabled=i<=28 t.vis.bb.Adornee=t.part
		local txt = t.kind
		if t.kind == "mon" then
			local realName = nil
			if t.hum and t.hum.DisplayName ~= "" and t.hum.DisplayName ~= "Mon" then realName = t.hum.DisplayName end
			if not realName then
				for _, obj in ipairs(t.inst:GetDescendants()) do
					if obj:IsA("TextLabel") and obj.Text ~= "" and #obj.Text < 30 then
						local txtCheck = obj.Text:lower()
						if MON[txtCheck] or txtCheck:find("gus") or txtCheck:find("man") then realName = obj.Text break end
					end
				end
			end
			if not realName and t.inst.Name ~= "Mon" and t.inst.Name ~= "mon" then realName = t.inst.Name end
			txt = realName or "Unknown Monster"
		end
		if t.price then txt = txt.." ("..t.price.."G)" end
		txt = txt.."\n"..math.floor(t.d).."m"
		t.vis.label.Text=txt
	end
	for _,t in pairs(objs) do if t.vis and t.stamp~=now then destroyVis(t) end end
end
-- LILA HUB | GALAXY EDITION | V.2 FIXED (PART 4)

local bad={} local lastMsg=0
local function getHrp() local c=lp.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function tpTo(pos) local hrp=getHrp() if not hrp then return end hrp.CFrame=CFrame.new(pos+Vector3.new(0,3,0)) hrp.AssemblyLinearVelocity=Vector3.new() end
local function fireOne(d) local ok=false if d:IsA("ProximityPrompt") and fireproximityprompt then pcall(function() d.HoldDuration=0 d.RequiresLineOfSight=false d.MaxActivationDistance=60 end) pcall(fireproximityprompt,d) ok=true elseif d:IsA("ClickDetector") and fireclickdetector then pcall(fireclickdetector,d) ok=true end return ok end

local function collect(o,part)
	local fired=false
	local list = {o}
	local p1 = o.Parent
	if p1 and p1 ~= workspace then
		table.insert(list, p1)
		for _, c in ipairs(p1:GetDescendants()) do table.insert(list, c) end
		local p2 = p1.Parent
		if p2 and p2 ~= workspace then for _, c in ipairs(p2:GetDescendants()) do table.insert(list, c) end end
	end
	for _, d in ipairs(o:GetDescendants()) do table.insert(list, d) end
	for _,d in ipairs(list) do if fireOne(d) then fired=true end end
	if not fired and firetouchinterest then local hrp=getHrp() if hrp and part then pcall(function() firetouchinterest(hrp,part,0) task.wait(0.05) firetouchinterest(hrp,part,1) end) end end
end

local function farmStep()
	if danger<40 then return end local hrp=getHrp() if not hrp then return end
	local target=ITEMS[cfg.target][1] local best,bd=nil,1e9 local now=os.clock()
	for o,t in pairs(objs) do
		local isT = S.farmAll and t.kind~="mon" or (not S.farmAll and t.kind==target)
		if isT and t.part and t.part.Parent and (bad[o] or 0)<now then
			local d=(t.part.Position-hrp.Position).Magnitude if d<bd then best,bd=t,d end
		end
	end
	if not best then if now-lastMsg>10 then lastMsg=now notify("LILA","No items found") end return end
	tpTo(best.part.Position) task.wait(0.15)
	collect(best.inst,best.part) task.wait(0.15)
	if taken(best.inst,best) then removeObj(best.inst) else bad[best.inst]=os.clock()+10 end
end

local function doSellAll()
	local pr=nil local n=0
	for _,o in ipairs(workspace:GetDescendants()) do
		if o:IsA("ProximityPrompt") or o:IsA("ClickDetector") then
			local chain=o.Name:lower().." "
			if o:IsA("ProximityPrompt") then chain=chain..o.ActionText:lower().." "..o.ObjectText:lower().." " end
			local p=o.Parent for _=1,4 do if p and p~=workspace then chain=chain..p.Name:lower().." " p=p.Parent end end
			if has(chain,SELLKEYS) then pr=o break end
		end
		n=n+1 if n%500==0 then task.wait() end
	end
	if not pr then notify("LILA","Scrapper not found") return end
	local holder=pr.Parent local part=holder and getPart(holder)
	if holder and not part then part=getPart(holder:FindFirstAncestorOfClass("Model")) end
	local hrp=getHrp() if not part or not hrp then return end
	local back=hrp.CFrame tpTo(part.Position+Vector3.new(0,0,3)) task.wait(0.5)
	local ch=lp.Character local bp=lp:FindFirstChildOfClass("Backpack") local tools={}
	if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and has(t.Name:lower(),{"ruby","gold","meat","crystal"}) then tools[#tools+1]=t end end end
	if ch then for _,t in ipairs(ch:GetChildren()) do if t:IsA("Tool") and has(t.Name:lower(),{"ruby","gold","meat","crystal"}) then tools[#tools+1]=t end end end
	for _,t in ipairs(tools) do pcall(function() t.Parent=ch end) end task.wait(0.4)
	for i=1,math.min(#tools+3,30) do fireOne(pr) task.wait(0.35) end
	if hrp.Parent then hrp.CFrame=back end
	notify("LILA","Sell done!")
end

local noclipParts={}
local flyBV=Instance.new("BodyVelocity") flyBV.MaxForce=Vector3.new(1e9,1e9,1e9) flyBV.Parent=nil
local flyBG=Instance.new("BodyGyro") flyBG.MaxTorque=Vector3.new(1e9,1e9,1e9) flyBG.P=1000 flyBG.D=50 flyBG.Parent=nil

bind(RS.RenderStepped,function()
    if S.fly and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local hrp=lp.Character.HumanoidRootPart flyBV.Parent=hrp flyBG.Parent=hrp flyBG.CFrame=cam.CFrame
        local moveDir=Vector3.new() local camCF=cam.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir=moveDir+camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir=moveDir-camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir=moveDir-camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir=moveDir+camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir=moveDir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir=moveDir-Vector3.new(0,1,0) end
        flyBV.Velocity=moveDir*cfg.flySpeed
    else flyBV.Parent=nil flyBG.Parent=nil end
end)

local acc=0
bind(RS.Heartbeat,function(dt)
    if cam.FieldOfView ~= cfg.fov then cam.FieldOfView = cfg.fov end
	if S.noclip and lp.Character then for _,v in pairs(lp.Character:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide=false table.insert(noclipParts,v) end end end
    if S.tp then local ch=lp.Character local h=ch and ch:FindFirstChildOfClass("Humanoid") local hrp=ch and ch:FindFirstChild("HumanoidRootPart") if h and hrp and h.MoveDirection.Magnitude>0 then hrp.CFrame=hrp.CFrame+h.MoveDirection*(cfg.tp*dt) end end
	acc=acc+dt if acc>=0.15 then acc=0 pcall(updateESP) end
end)

task.spawn(function() while alive do task.wait(0.1) if S.farm or S.farmAll then pcall(farmStep) end end end)

UIS.JumpRequest:Connect(function() if S.infjump and lp.Character then local hum=lp.Character:FindFirstChildOfClass("Humanoid") if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end end)

makeToggle(pPlayer, "Fly", S, "fly")
makeInput(pPlayer, "Fly Speed", cfg, "flySpeed")
makeToggle(pPlayer, "Noclip", S, "noclip")
makeToggle(pPlayer, "Infinite Jump", S, "infjump")
makeToggle(pPlayer, "TP Walk", S, "tp")
makeInput(pPlayer, "TP Speed", cfg, "tp")

makeInput(pVisual, "FOV Changer", cfg, "fov")
makeToggle(pVisual, "Monster ESP", S, "mon")
makeToggle(pVisual, "Monster Alert", S, "alert")
makeButton(pVisual, "Semua Item ON/OFF", function()
    local allOn = false for k,v in pairs(I) do if not v then allOn = true break end end
    for k,_ in pairs(I) do I[k] = allOn end
    notify("LILA", "Semua Item ESP: "..tostring(allOn))
end, C(235,70,50))

makeButton(pFarm, "Target: "..ITEMS[cfg.target][1], function(b)
	cfg.target = cfg.target % #ITEMS + 1
	b.Text = "Target: "..ITEMS[cfg.target][1]
end, C(50,120,235))
makeToggle(pFarm, "Auto Farm Target", S, "farm")
makeToggle(pFarm, "Auto Farm ALL", S, "farmAll")
makeToggle(pFarm, "Auto Sell", S, "sell")
makeButton(pFarm, "Jual Semua Item", function() task.spawn(doSellAll) end, C(235,70,50))

makeToggle(pSet, "Fullbright (Terang)", S, "fb", function(on) if on then game:GetService("Lighting").Ambient = C(255,255,255) else game:GetService("Lighting").Ambient = C(0,0,0) end end)
makeToggle(pSet, "Anti-AFK", S, "afk", function(on) if on then lp.Idled:Connect(function() game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0),cam.CFrame) task.wait(1) game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0),cam.CFrame) end) end end)

local function unload() alive=false for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end pcall(function() gui:Destroy() end) end
_G.LINA_UNLOAD = unload
makeButton(pSet, "Unload Script", unload, C(130,35,35))

switchTab("Player")
notify("LILA", "Galaxy UI V.2 Loaded!")
