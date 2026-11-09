-- LINA v7.4 FIX | Lethal Ape
local function notify0(t,x)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification",{Title=t,Text=tostring(x):sub(1,190),Duration=8})
	end)
end
notify0("LINA","Loading LINA v7.4...")

local okRun,errRun=pcall(function()
local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local lp=Players.LocalPlayer
local cam=workspace.CurrentCamera
local env=(getgenv and getgenv()) or _G
if env.LINA_UNLOAD then pcall(env.LINA_UNLOAD) end
local function notify(t,x)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification",{Title=t,Text=tostring(x):sub(1,190),Duration=6})
	end)
end
local function C(r,g,b) return Color3.fromRGB(r,g,b) end

-- DAFTAR ITEM & HARGA
local ITEMS={
	{"Red Gold","red gold",150,C(255,40,70)},
	{"Ruby","ruby",35,C(255,40,70)},
	{"Crystal Bars","crystal bar",24,C(190,120,255)},
	{"Emerald","emerald",10,C(60,255,120)},
	{"Amethyst","amethyst",10,C(190,120,255)},
	{"Diamond","diamond",7,C(120,230,255)},
	{"Crystal","crystal",4,C(190,120,255)},
	{"Meat","meat",3,C(255,130,110)},
	{"Gold Ingot","gold",2,C(255,210,40)},
	{"Iron","iron",2,C(200,205,215)},
	{"Copper","copper",1,C(230,130,60)},
}
local IGNORE={"shop","merchant","dummy"}
local SELLKEYS={"scrapper","scrap","sell","recycl","trade"}
local SELL_ALL_TOOLS=false
local MON_LIST={
	"mon","???","Acidman","Ashes","Ashy","Big Guy","Big Larry","Bill","Billy",
	"Bloodman","Bloody Ashy","Blud","Bob","Clyde","Color Lurker","Crud",
	"Devil","Dlud","Dus","Fluddy","Fred","Ghost","Giant Guy","GLI.TCH.",
	"Glowy-Blinky","Goo","Gooba","GorillaScar","Gus","Hazardman","Henry",
	"Horror Gus","Horror Sandman","Ingus","Jake","Jimmy","John","John (Lab)",
	"Kaz","Kus","Kus Clone","Lengthy","Lester","Lost","Lurker","Meatman",
	"Mini Lost (Lost Clone)","Mus","Finerooms Anomaly","Mysterious Gus",
	"Orange Blud","Orangeman","Pee-Wee","Plud","Primate","Rock Ape",
	"Sandguy","Sandman","Saw","Scar","Scary Monkeys","Timmy","Unknown",
	"VR Blud","Taller",
}
local MON={}
for _,n in ipairs(MON_LIST) do MON[n:lower()]=true end
local MONCOL=C(255,50,50)
local ALERTCOL=C(255,120,0)

local S={mon=false,alert=false,tp=false,farm=false,farmAll=false,sell=false,fb=false,afk=false,noclip=false,autoheal=false}
local I={}
for _,it in ipairs(ITEMS) do I[it[1]]=false end
local cfg={target=2,tp=30,dist=500,alertD=60,sellIdx=3}
local SELLN={1,3,5,10,20}

local conns,alive={},true
local noclipParts={}
local function bind(sg,fn) local c=sg:Connect(fn) conns[#conns+1]=c return c end

-- GUI ROOT
local gui=Instance.new("ScreenGui")
gui.Name="LINA_V73" gui.ResetOnSpawn=false gui.DisplayOrder=999
local done=false
for _,g in ipairs({
	function() return lp:WaitForChild("PlayerGui",5) end,
	function() return gethui() end,
	function() return game:GetService("CoreGui") end}) do
	local ok,p=pcall(g)
	if ok and p and not done then
		pcall(function() local o=p:FindFirstChild("LINA_V73") if o then o:Destroy() end end)
		if pcall(function() gui.Parent=p end) and gui.Parent==p then done=true end
	end
end
if not done then error("GUI failed to load") end

-- THEME
local BG=C(14,14,20)
local ROW=C(34,34,48)
local OFFC=C(70,70,90)
local ACCENT=C(235,70,50)
local WHITE=Color3.new(1,1,1)
local GREY=C(160,165,180)
local function corner(o,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=o end
local function mk(class,props,parent) local o=Instance.new(class) for k,v in pairs(props) do o[k]=v end if parent then o.Parent=parent end return o end

local main=mk("Frame",{Size=UDim2.fromOffset(250,360),Position=UDim2.new(0,10,0.1,0),BackgroundColor3=BG,BorderSizePixel=0},gui)
corner(main,12)
local stroke = mk("UIStroke",{Color=ACCENT,Thickness=1.4,Transparency=0.35},main)
local bar=mk("Frame",{Size=UDim2.new(1,0,0,4),BackgroundColor3=ACCENT,BorderSizePixel=0},main)
corner(bar,4)

local header=mk("TextLabel",{Size=UDim2.new(1,-50,0,22),Position=UDim2.fromOffset(12,6),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,Text="LINA  v7.4",TextColor3=WHITE,Font=Enum.Font.GothamBold,TextSize=15},main)
local status=mk("TextLabel",{Size=UDim2.new(1,-20,0,14),Position=UDim2.fromOffset(12,26),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,Text="Status: idle",TextColor3=C(120,255,160),Font=Enum.Font.Code,TextSize=11},main)
local function stat(x) status.Text=tostring(x):sub(1,44) end

local minBtn=mk("TextButton",{Size=UDim2.fromOffset(28,24),Position=UDim2.new(1,-38,0,8),BackgroundColor3=ROW,Text="-",TextColor3=WHITE,Font=Enum.Font.GothamBold,TextSize=16},main)
corner(minBtn,7)
local tabBar=mk("Frame",{Size=UDim2.new(1,-16,0,28),Position=UDim2.fromOffset(8,46),BackgroundTransparency=1},main)
local body=mk("Frame",{Size=UDim2.new(1,-12,1,-84),Position=UDim2.fromOffset(6,78),BackgroundTransparency=1},main)

local minimized=false
bind(minBtn.MouseButton1Click,function() minimized=not minimized tabBar.Visible=not minimized body.Visible=not minimized main.Size=minimized and UDim2.fromOffset(250,44) or UDim2.fromOffset(250,360) minBtn.Text=minimized and "+" or "-" end)

local dragging,ds,sp0
bind(header.InputBegan,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true ds=i.Position sp0=main.Position i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
bind(UIS.InputChanged,function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-ds main.Position=UDim2.new(sp0.X.Scale,sp0.X.Offset+d.X,sp0.Y.Scale,sp0.Y.Offset+d.Y) end end)

-- TAB
local pages,tabBtns={},{}
local function showTab(n) for k,p in ipairs(pages) do p.Visible=(k==n) tabBtns[k].BackgroundColor3=(k==n) and ACCENT or ROW tabBtns[k].TextColor3=(k==n) and WHITE or GREY end end
for i,name in ipairs({"ESP","Farm","Move","Set"}) do
	local sf=mk("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=ACCENT,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Visible=false},body)
	mk("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center},sf)
	mk("UIPadding",{PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,8)},sf)
	pages[i]=sf
	local tb=mk("TextButton",{Size=UDim2.new(1/4,-4,1,0),Position=UDim2.new((i-1)/4,2,0,0),BackgroundColor3=ROW,Text=name,TextColor3=GREY,Font=Enum.Font.GothamBold,TextSize=12},tabBar)
	corner(tb,8)
	tabBtns[i]=tb
	bind(tb.MouseButton1Click,function() showTab(i) end)
		end
-- COMPONENTS
local order=0
local function row(page,h) order=order+1 local f=mk("Frame",{Size=UDim2.new(1,-8,0,h or 34),BackgroundColor3=ROW,BorderSizePixel=0,LayoutOrder=order},page) corner(f,9) return f end
local function lbl(parent,text,col) return mk("TextLabel",{Size=UDim2.new(1,-70,1,0),Position=UDim2.fromOffset(12,0),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,Text=text,TextColor3=col or WHITE,Font=Enum.Font.GothamMedium,TextSize=12},parent) end
local function tog(page,label,tbl,key,fn,col)
	local r=row(page) lbl(r,label,col)
	local sw=mk("TextButton",{Size=UDim2.fromOffset(42,20),Position=UDim2.new(1,-52,0.5,-10),BackgroundColor3=OFFC,Text="",AutoButtonColor=false},r) corner(sw,10)
	local knob=mk("Frame",{Size=UDim2.fromOffset(16,16),Position=UDim2.new(0,2,0.5,-8),BackgroundColor3=WHITE,BorderSizePixel=0},sw) corner(knob,8)
	local function refresh() local on=tbl[key] TS:Create(sw,TweenInfo.new(0.15),{BackgroundColor3=on and ACCENT or OFFC}):Play() TS:Create(knob,TweenInfo.new(0.15),{Position=on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}):Play() end
	bind(sw.MouseButton1Click,function() tbl[key]=not tbl[key] refresh() if fn then fn(tbl[key]) end end)
	refresh() return refresh
end
local function num(page,label,tbl,key,mn,mx,unit)
	local r=row(page) lbl(r,label..(unit and (" ("..unit..")") or ""))
	local box=mk("TextBox",{Size=UDim2.fromOffset(62,24),Position=UDim2.new(1,-72,0.5,-12),BackgroundColor3=BG,Text=tostring(tbl[key]),TextColor3=C(255,210,120),PlaceholderText="num",Font=Enum.Font.GothamBold,TextSize=13,ClearTextOnFocus=true},r) corner(box,7)
	bind(box.FocusLost,function() local v=tonumber(box.Text) if v then v=math.clamp(math.floor(v),mn,mx) tbl[key]=v end box.Text=tostring(tbl[key]) end)
end
local function btn(page,text,cb,col) order=order+1 local b=mk("TextButton",{Size=UDim2.new(1,-8,0,34),BackgroundColor3=col or ROW,Text=text,TextColor3=WHITE,Font=Enum.Font.GothamBold,TextSize=12,LayoutOrder=order},page) corner(b,9) bind(b.MouseButton1Click,function() cb(b) end) return b end
local function title(page,text) order=order+1 mk("TextLabel",{Size=UDim2.new(1,-8,0,18),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,Text="  "..text,TextColor3=GREY,Font=Enum.Font.GothamBold,TextSize=11,LayoutOrder=order},page) end

local banner=mk("TextLabel",{Size=UDim2.fromOffset(300,36),Position=UDim2.new(0.5,-150,0,60),TextColor3=WHITE,Font=Enum.Font.GothamBold,TextSize=15,Visible=false},gui) corner(banner,10)

-- REGISTRY & ESP
local objs={}
local danger=1e9
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
	if MON[l] then kind="mon" col=MONCOL
	elseif o:IsA("Model") and o:FindFirstChildOfClass("Humanoid") then kind="mon" col=MONCOL
	else 
		for _,it in ipairs(ITEMS) do 
			if l:find(it[2],1,true) or l:sub(1, string.len(it[2])) == it[2] then 
				kind=it[1] col=it[4] price=it[3] break 
			end 
		end 
	end
	if not kind then return end if inPlayer(o) or hasTracked(o) then return end
	
	if kind~="mon" then 
		local p=getPart(o) if not p then return end 
		local s=p.Size 
		if math.max(s.X,s.Y,s.Z)>40 then return end 
		if p.Transparency>=0.95 and allHidden(o) then return end 
	end
	addObj(o,kind,col,o.Name,price)
end
task.spawn(function() local n=0 for _,o in ipairs(workspace:GetDescendants()) do if not alive then return end pcall(consider,o) n=n+1 if n%300==0 then task.wait() end end end)
bind(workspace.DescendantAdded,function(o) task.defer(pcall,consider,o) end)

local function makeVis(t)
	local hl=Instance.new("Highlight") hl.Adornee=t.inst hl.FillColor=t.col hl.OutlineColor=t.col hl.FillTransparency=0.55 hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.Parent=gui
	local bb=Instance.new("BillboardGui") bb.Adornee=t.part bb.AlwaysOnTop=true bb.Size=UDim2.fromOffset(180,45) bb.StudsOffset=Vector3.new(0,3,0) bb.Parent=gui
	local l=Instance.new("TextLabel") l.Size=UDim2.fromScale(1,1) l.BackgroundTransparency=1 l.TextColor3=t.col l.TextStrokeTransparency=0.3 l.Font=Enum.Font.GothamBold l.TextSize=12 l.Parent=bb
	t.vis={hl=hl,bb=bb,label=l}
end

local function updateESP()
	local now=os.clock() local ch=lp.Character local hrp=ch and ch:FindFirstChild("HumanoidRootPart") local origin=hrp and hrp.Position or cam.CFrame.Position
	local show,gone,nearest,nd={},{},nil,nil danger=1e9
	for o,t in pairs(objs) do
		local kill=false
		if (not o:IsDescendantOf(workspace)) or (ch and o:IsDescendantOf(ch)) then kill=true
		elseif t.kind~="mon" and now>(t.nc or 0) then t.nc=now+0.4 if taken(o,t) then kill=true end end
		if kill then gone[#gone+1]=o
		else
			local p=t.part if not p or not p.Parent then p=getPart(o) t.part=p end
			if p then
				local d=(p.Position-origin).Magnitude local prev=t.d t.d=d local on
				if t.kind=="mon" then on=S.mon else on=I[t.kind] end
				if on and d<=cfg.dist then show[#show+1]=t end
				if t.kind=="mon" then
					if d<danger then danger=d end
					if S.alert and hrp then if prev and d<prev-0.3 then t.appr=now+1.2 end if d<=cfg.alertD and (t.appr or 0)>now and (not nd or d<nd) then nearest,nd=t,d end end
				end
			end
		end
	end
	for _,o in ipairs(gone) do removeObj(o) end table.sort(show,function(a,b) return a.d<b.d end)
	for i,t in ipairs(show) do
		if i>45 then break end t.stamp=now if not t.vis then makeVis(t) end
		t.vis.hl.Enabled=i<=28 t.vis.bb.Adornee=t.part
		
        -- TEXT ESP & FIX NAMA MONSTER
		local txt = t.kind
		if t.kind == "mon" and t.hum and t.hum.DisplayName ~= "" then
			txt = t.hum.DisplayName
		end
		if t.price then txt = txt.." ("..t.price.." Gold)" end
		txt = txt.."\n"..math.floor(t.d).."m"
		if t.hum and t.hum.Parent then txt=txt.." | HP "..math.floor(t.hum.Health) end
		t.vis.label.Text=txt
	end
	for _,t in pairs(objs) do if t.vis and t.stamp~=now then destroyVis(t) end end
	if nearest then banner.Text="! "..nearest.name.." approaching ["..math.floor(nd).."m]" banner.BackgroundColor3=ALERTCOL banner.Visible=true else banner.Visible=false end
		end
-- AUTO FARM & FITUR BARU
local bad={} local collected=0 local lastMsg=0
local function getHrp() local c=lp.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function tpTo(pos) local hrp=getHrp() if not hrp then return end hrp.CFrame=CFrame.new(pos+Vector3.new(0,3,0)) hrp.AssemblyLinearVelocity=Vector3.new() end
local function fireOne(d)
	local ok=false
	if d:IsA("ProximityPrompt") and fireproximityprompt then pcall(function() d.HoldDuration=0 d.RequiresLineOfSight=false d.MaxActivationDistance=40 end) pcall(fireproximityprompt,d) ok=true
	elseif d:IsA("ClickDetector") and fireclickdetector then pcall(fireclickdetector,d) ok=true end
	return ok
end
local function collect(o,part)
	local fired=false local list=o:GetDescendants() list[#list+1]=o
	if o.Parent then for _,c in ipairs(o.Parent:GetChildren()) do list[#list+1]=c end end
	for _,d in ipairs(list) do if fireOne(d) then fired=true end end
	if not fired and firetouchinterest then local hrp=getHrp() if hrp and part then pcall(function() firetouchinterest(hrp,part,0) task.wait(0.05) firetouchinterest(hrp,part,1) end) end end
end

local sellPrompt=nil
local function findSell()
	if sellPrompt and sellPrompt.Parent then return sellPrompt end local n=0
	for _,o in ipairs(workspace:GetDescendants()) do
		if o:IsA("ProximityPrompt") or o:IsA("ClickDetector") then
			local chain=o.Name:lower().." "
			if o:IsA("ProximityPrompt") then chain=chain..o.ActionText:lower().." "..o.ObjectText:lower().." " end
			local p=o.Parent for _=1,4 do if p and p~=workspace then chain=chain..p.Name:lower().." " p=p.Parent end end
			if has(chain,SELLKEYS) then sellPrompt=o return o end
		end
		n=n+1 if n%500==0 then task.wait() end
	end
	return nil
end

local selling=false
local function isSellTool(t) if SELL_ALL_TOOLS then return true end local l=t.Name:lower() for _,it in ipairs(ITEMS) do if l:find(it[2],1,true) then return true end end return false end
local function doSellAll(backCf)
	if selling then return end selling=true
	local ok,err=pcall(function()
		stat("Finding Scrapper...") local pr=findSell() if not pr then notify("LINA","Scrapper not found") stat("Scrapper not found") return end
		local holder=pr.Parent local part=holder and getPart(holder) if not part and holder then local m=holder:FindFirstAncestorOfClass("Model") part=m and getPart(m) end
		local hrp=getHrp() if not part or not hrp then stat("Scrapper pos not found") return end
		local back=backCf or hrp.CFrame tpTo(part.Position+Vector3.new(0,0,3)) task.wait(0.5)
		local ch=lp.Character local hum=ch and ch:FindFirstChildOfClass("Humanoid") local bp=lp:FindFirstChildOfClass("Backpack") local tools={}
		if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and isSellTool(t) then tools[#tools+1]=t end end end
		if ch then for _,t in ipairs(ch:GetChildren()) do if t:IsA("Tool") and isSellTool(t) then tools[#tools+1]=t end end end
		stat("Taking all: "..#tools.." items") for _,t in ipairs(tools) do pcall(function() t.Parent=ch end) end task.wait(0.4)
		local function left() local n=0 for _,t in ipairs(tools) do if t.Parent then n=n+1 end end return n end
		local tries=math.min(#tools+3,30) for i=1,tries do if left()==0 then break end stat("Selling "..i.."/"..tries.." left "..left()) fireOne(pr) task.wait(0.35) end
		pcall(function() if hum then hum:UnequipTools() end end) task.wait(0.3) if hrp.Parent then hrp.CFrame=back end
		collected=0 stat("Sell done, left "..left())
	end)
	selling=false if not ok then notify("LINA","Sell error: "..tostring(err)) end
end

-- LOGIKA FARM CEPAT & AMAN
local function farmStep()
	if selling then return end local hrp=getHrp() if not hrp then return end 
	if danger<40 then stat("Monster nearby! Paused") return end
	local best,bd=nil,1e9 local now=os.clock()
	for o,t in pairs(objs) do
		local isTarget = false
		if S.farmAll then if t.kind~="mon" then isTarget=true end 
		else if t.kind==ITEMS[cfg.target][1] then isTarget=true end end
		
		if isTarget and t.part and t.part.Parent and (bad[o] or 0)<now then
			local d=(t.part.Position-hrp.Position).Magnitude if d<bd then best,bd=t,d end
		end
	end
	if not best then
		stat("No items found") if now-lastMsg>10 then lastMsg=now notify("LINA","No items in map") end return
	end
	local back=hrp.CFrame stat((S.farmAll and "Getting ALL" or "Getting "..ITEMS[cfg.target][1]).." ("..math.floor(bd).."m)")
	tpTo(best.part.Position) task.wait(0.1) 
	collect(best.inst,best.part) task.wait(0.15) 
	
	if taken(best.inst,best) then collected=collected+1 removeObj(best.inst) stat("Collected: "..collected) else bad[best.inst]=os.clock()+20 end
	if S.sell and collected>=SELLN[cfg.sellIdx] then doSellAll(back) end
end

task.spawn(function() while alive do task.wait(0.1) if (S.farm or S.farmAll) then pcall(farmStep) end end end)

-- ISI TAB ESP
local pE,pF,pM,pSet=pages[1],pages[2],pages[3],pages[4]
title(pE,"MONSTER") tog(pE,"Monster ESP",S,"mon",nil,MONCOL) tog(pE,"Monster Alert",S,"alert",nil,ALERTCOL)
title(pE,"ITEM") local itemRefresh={}
for _,it in ipairs(ITEMS) do itemRefresh[#itemRefresh+1]=tog(pE,it[1],I,it[1],nil,it[4]) end
local allOn=false
btn(pE,"All Items ON / OFF",function() allOn=not allOn for _,it in ipairs(ITEMS) do I[it[1]]=allOn end for _,r in ipairs(itemRefresh) do r() end end)
title(pE,"SETTINGS") num(pE,"ESP Distance",cfg,"dist",10,5000,"studs") num(pE,"Alert Distance",cfg,"alertD",10,500,"studs")

-- ISI TAB FARM
title(pF,"AUTO FARM (TARGET)") btn(pF,"Target: "..ITEMS[cfg.target][1],function(b) cfg.target=cfg.target%#ITEMS+1 b.Text="Target: "..ITEMS[cfg.target][1] b.TextColor3=ITEMS[cfg.target][4] end).TextColor3=ITEMS[cfg.target][4]
tog(pF,"Farm Target",S,"farm")
title(pF,"AUTO FARM (SEMUA)") tog(pF,"Farm ALL Items (Fast)",S,"farmAll", function(on) if on then S.farm = false end end, ACCENT) 
title(pF,"SELL") tog(pF,"AUTO SELL",S,"sell")
btn(pF,"Sell every: "..SELLN[cfg.sellIdx].." items",function(b) cfg.sellIdx=cfg.sellIdx%#SELLN+1 b.Text="Sell every: "..SELLN[cfg.sellIdx].." items" end)
btn(pF,"SELL ALL ITEMS",function() task.spawn(doSellAll) end,ACCENT)

-- ISI TAB MOVE
title(pM,"MOVE") tog(pM,"TP Walk",S,"tp") num(pM,"TP Speed",cfg,"tp",1,300,"studs/s")
tog(pM, "Fullbright (Terang)", S, "fb", function(on) if on then game:GetService("Lighting").Ambient = Color3.fromRGB(255,255,255) game:GetService("Lighting").Brightness = 2 else game:GetService("Lighting").Ambient = Color3.fromRGB(0,0,0) game:GetService("Lighting").Brightness = 1 end end) 
tog(pM, "Anti-AFK", S, "afk", function(on) if on then lp.Idled:Connect(function() game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame) task.wait(1) game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame) end) end end) 

tog(pM, "Noclip (Tembus Tembok)", S, "noclip", function(on) 
	if on then 
		bind(RS.Stepped, function() 
			local ch=lp.Character 
			if ch then 
				for _,v in pairs(ch:GetDescendants()) do 
					if v:IsA("BasePart") and v.CanCollide then 
						v.CanCollide=false 
						table.insert(noclipParts, v) 
					end 
				end 
			end 
		end) 
	else 
		for _,v in pairs(noclipParts) do
			pcall(function() v.CanCollide = true end)
		end
		noclipParts = {} 
	end 
end)

btn(pM, "SERVER HOP (Pindah Server)", function() notify("LINA","Hopping server...") local TS=game:GetService("TeleportService") pcall(function() TS:Teleport(game.PlaceId, lp) end) end, C(235,120,0)) 
tog(pM, "Auto Heal (Makan Meat)", S, "autoheal", function(on) if on then task.spawn(function() while S.autoheal and alive do task.wait(1) local hum=lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") if hum and hum.Health<hum.MaxHealth then local bp=lp:FindFirstChildOfClass("Backpack") if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and (t.Name:lower():find("meat") or t.Name:lower():find("food")) then t.Parent=lp.Character task.wait(0.5) t.Parent=bp break end end end end end end) end end) 

local function unload() alive=false for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end for o in pairs(objs) do pcall(removeObj,o) end pcall(function() gui:Destroy() end) end
env.LINA_UNLOAD=unload
btn(pM,"Unload Script",unload,C(130,35,35))

-- TAB SET (WARNA & BAHASA)
local LANGUAGES = { ["EN"] = {"ESP","Farm","Move","Settings","LINA v7.4"}, ["ID"] = {"ESP","Kebun","Gerak","Pengaturan","LINA v7.4"} }
title(pSet, "UI THEME COLOR")
local colors = { {"Red", C(235,70,50)}, {"Blue", C(50,120,235)}, {"Green", C(50,235,120)}, {"Purple", C(180,50,235)} }
for _, cData in ipairs(colors) do btn(pSet, "Theme: "..cData[1], function(b) bar.BackgroundColor3 = cData[2] stroke.Color = cData[2] banner.BackgroundColor3 = cData[2] for k,p in ipairs(pages) do if p.Visible then tabBtns[k].BackgroundColor3 = cData[2] break end end end, cData[2]) end
title(pSet, "LANGUAGE")
for langCode, textData in pairs(LANGUAGES) do btn(pSet, "Language: "..langCode, function(b) tabBtns[1].Text = textData[1] tabBtns[2].Text = textData[2] tabBtns[3].Text = textData[3] tabBtns[4].Text = textData[4] header.Text = textData[5] end) end

showTab(1)

-- LOOP
local acc=0
bind(RS.Heartbeat,function(dt)
	if S.tp then local ch=lp.Character local h=ch and ch:FindFirstChildOfClass("Humanoid") local hrp=ch and ch:FindFirstChild("HumanoidRootPart") if h and hrp and h.MoveDirection.Magnitude>0 then hrp.CFrame=hrp.CFrame+h.MoveDirection*(cfg.tp*dt) end end
	acc=acc+dt if acc>=0.15 then acc=0 pcall(updateESP) end
end)
notify("LINA","READY v7.4! Bug Fixed & Monster Name Fixed.")
end)
if not okRun then notify0("LINA ERROR",errRun) end
