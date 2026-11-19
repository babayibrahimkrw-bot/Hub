-- POTONGAN 1/9  (tempel berurutan jadi SATU script; jangan ubah isinya)
--[[
	=====================================================================
	 CC201 AUTO BUILDER via F3X (Building Tools)  -  DELTA EXECUTOR
	 Tempel semua POTONGAN berurutan menjadi SATU script, lalu Execute.
	 Syarat: game menyediakan F3X / "Building Tools" dan kamu memegangnya.
	 Model dibuat lewat server endpoint F3X, jadi terlihat semua pemain
	 (bukan client-side). Tidak ada celah yang dipakai: script hanya
	 memanggil fungsi bawaan tool itu, sama seperti saat membangun manual.
	=====================================================================
]]

----------------------------------------------------------------------
-- KONFIGURASI
----------------------------------------------------------------------
local MODEL_NAME = "CC201_Locomotive"
local DISTANCE_AHEAD = 50        -- jarak model di depan karaktermu (studs)
local BATCH_SIZE = 120           -- jumlah part per panggilan sinkronisasi
local BATCH_DELAY = 0.05         -- jeda antar panggilan (naikkan jika kena throttle)
local CLONE_CHUNK = 400          -- maks part per panggilan Clone
local USE_CLONE = true           -- true: gandakan part (cepat); false: buat satu-satu
local NAME_PARTS = false         -- true: beri nama tiap part (lebih lambat)
local REVEAL_TRANSPARENCY = 0.6  -- dipakai jika "Tembus pandang" aktif

local Workspace = game:GetService("Workspace")
local LocalPlayer = game:GetService("Players").LocalPlayer

----------------------------------------------------------------------
-- ALIAS, MATERIAL, WARNA
----------------------------------------------------------------------
local PI = math.pi
local rad = math.rad
local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles

local SP = Enum.Material.SmoothPlastic
local MT = Enum.Material.Metal
local FAB = Enum.Material.Fabric
local GLS = Enum.Material.Glass
local NEON = Enum.Material.Neon

local SIDES = { 1, -1 }

local C = {
	-- livery & eksterior
	White = Color3.fromRGB(236, 239, 242),
	Cream = Color3.fromRGB(222, 226, 230),
	Red = Color3.fromRGB(196, 28, 36),
	DarkRed = Color3.fromRGB(150, 20, 28),
	Blue = Color3.fromRGB(28, 64, 150),
	Orange = Color3.fromRGB(240, 120, 30),
	Black = Color3.fromRGB(22, 22, 24),
	DarkGrey = Color3.fromRGB(52, 56, 62),
	Steel = Color3.fromRGB(150, 156, 164),
	Roof = Color3.fromRGB(104, 122, 140),
	RoofLight = Color3.fromRGB(128, 144, 160),
	Deck = Color3.fromRGB(92, 104, 116),
	Tank = Color3.fromRGB(66, 74, 84),
	Wheel = Color3.fromRGB(46, 48, 52),
	WheelPlate = Color3.fromRGB(92, 96, 104),
	Glass = Color3.fromRGB(26, 38, 50),
	Lamp = Color3.fromRGB(255, 243, 205),
	LampRed = Color3.fromRGB(220, 30, 30),
	Rubber = Color3.fromRGB(30, 30, 32),
	-- interior
	GlassIn = Color3.fromRGB(150, 190, 210),
	Wall = Color3.fromRGB(196, 202, 208),
	WallLower = Color3.fromRGB(88, 104, 122),
	Ceiling = Color3.fromRGB(228, 230, 232),
	Floor = Color3.fromRGB(58, 62, 68),
	Mat = Color3.fromRGB(30, 32, 36),
	Console = Color3.fromRGB(64, 74, 88),
	Panel = Color3.fromRGB(26, 28, 32),
	DarkSteel = Color3.fromRGB(70, 76, 84),
	Seat = Color3.fromRGB(44, 48, 58),
	SeatFrame = Color3.fromRGB(96, 100, 108),
	Green = Color3.fromRGB(50, 200, 90),
	Amber = Color3.fromRGB(245, 170, 40),
	Brass = Color3.fromRGB(184, 140, 60),
	Engine = Color3.fromRGB(74, 98, 110),
	EngineDark = Color3.fromRGB(44, 56, 64),
	Generator = Color3.fromRGB(150, 60, 50),
	Radiator = Color3.fromRGB(96, 104, 112),
	Pipe = Color3.fromRGB(176, 120, 60),
	PipeGrey = Color3.fromRGB(120, 126, 134),
	Cable = Color3.fromRGB(34, 34, 38),
}


----------------------------------------------------------------------
-- PEREKAM SPESIFIKASI PART
-- (tidak membuat Instance di sini; F3X yang membuatnya di server)
----------------------------------------------------------------------
local SPECS = {}
local model = { Name = MODEL_NAME }

local function group(parent, name)
	return { Name = name, Parent = parent }
end

local function topGroup(g)
	local t = g
	while t.Parent and t.Parent ~= model do
		t = t.Parent
	end
	return t
end

local function clampSize(v)
	return V3(math.max(v.X, 0.05), math.max(v.Y, 0.05), math.max(v.Z, 0.05))
end

local function record(kind, parent, name, size, cf, color, mat, collide)
	local s = {
		Kind = kind,
		Name = name,
		Size = clampSize(size),
		CF = cf,
		Color = color,
		Material = mat or SP,
		Collide = (collide == true),
		Transparency = 0,
		Reflectance = 0,
		Group = parent,
	}
	SPECS[#SPECS + 1] = s
	return s
end

local function boxCF(parent, name, size, cf, color, mat, collide)
	return record("Normal", parent, name, size, cf, color, mat, collide)
end

local function box(parent, name, size, pos, color, mat, collide)
	return boxCF(parent, name, size, CF(pos), color, mat, collide)
end

local AXIS_X = CFrame.identity
local AXIS_Y = ANG(0, 0, PI / 2)
local AXIS_Z = ANG(0, PI / 2, 0)

local function cylCF(parent, name, length, diameter, cf, color, mat, collide)
	return record("Cylinder", parent, name, V3(length, diameter, diameter), cf, color, mat, collide)
end

local function cyl(parent, name, length, diameter, pos, axis, color, mat, collide)
	return cylCF(parent, name, length, diameter, CF(pos) * axis, color, mat, collide)
end

local function ball(parent, name, diameter, pos, color, mat)
	return record("Ball", parent, name, V3(diameter, diameter, diameter), CF(pos), color, mat, false)
end


-- Papan miring pada bidang XY dari (x0,y0) ke (x1,y1); zWidth = lebar sepanjang Z
local function slabXY(parent, name, x0, y0, x1, y1, thick, zWidth, zc, color, mat)
	local dx, dy = x1 - x0, y1 - y0
	local len = math.sqrt(dx * dx + dy * dy)
	return boxCF(
		parent,
		name,
		V3(len, thick, zWidth),
		CF((x0 + x1) / 2, (y0 + y1) / 2, zc) * ANG(0, 0, math.atan2(dy, dx)),
		color,
		mat,
		false
	)
end

-- Pipa/kabel silinder dari titik p0 ke p1 (Vector3 lokal)
local function pipe(parent, name, p0, p1, dia, color, mat)
	local d = p1 - p0
	local len = d.Magnitude
	if len < 0.01 then
		return nil
	end
	local up = (math.abs(d.Unit.Y) > 0.99) and V3(1, 0, 0) or V3(0, 1, 0)
	local cf = CFrame.lookAt((p0 + p1) / 2, p1, up) * ANG(0, PI / 2, 0)
	return cylCF(parent, name, len, dia, cf, color, mat, false)
end

-- Panel datar dengan lubang persegi (dinding berjendela).
-- frame = CFrame pusat panel (X = lebar, Y = tinggi, Z = tebal)
-- holes = { {x=, y=, w=, h=}, ... } pusat lubang relatif ke pusat panel
local function panelWithHoles(parent, name, frame, w, h, th, holes, color, mat)
	local xs = { -w / 2, w / 2 }
	for _, o in ipairs(holes) do
		table.insert(xs, o.x - o.w / 2)
		table.insert(xs, o.x + o.w / 2)
	end
	table.sort(xs)

	local function rect(x0, x1, y0, y1)
		boxCF(parent, name, V3(x1 - x0, y1 - y0, th), frame * CF((x0 + x1) / 2, (y0 + y1) / 2, 0), color, mat, false)
	end

	for i = 1, #xs - 1 do
		local x0, x1 = xs[i], xs[i + 1]
		if x1 - x0 > 0.001 then
			local xm = (x0 + x1) / 2
			local gaps = {}
			for _, o in ipairs(holes) do
				if xm > o.x - o.w / 2 and xm < o.x + o.w / 2 then
					table.insert(gaps, { o.y - o.h / 2, o.y + o.h / 2 })
				end
			end
			table.sort(gaps, function(a, b)
				return a[1] < b[1]
			end)
			local cursor = -h / 2
			for _, gp in ipairs(gaps) do
				if gp[1] - cursor > 0.001 then
					rect(x0, x1, cursor, gp[1])
				end
				cursor = math.max(cursor, gp[2])
			end
			if h / 2 - cursor > 0.001 then
				rect(x0, x1, cursor, h / 2)
			end
		end
	end
end

-- Frame permukaan: X = kanan penonton, Y = atas, Z = keluar dari permukaan
local function faceCF(pos, face)
	if face == "front" then
		return CFrame.fromMatrix(pos, V3(0, 0, -1), V3(0, 1, 0))
	elseif face == "back" then
		return CFrame.fromMatrix(pos, V3(0, 0, 1), V3(0, 1, 0))
	elseif face == "right" then
		return CFrame.fromMatrix(pos, V3(1, 0, 0), V3(0, 1, 0))
	end
	return CFrame.fromMatrix(pos, V3(-1, 0, 0), V3(0, 1, 0)) -- "left"
end

----------------------------------------------------------------------
-- TEKS PIXEL (nomor lokomotif & huruf logo KAI), font 3x5
----------------------------------------------------------------------
local FONT = {
	["C"] = { "111", "100", "100", "100", "111" },
	["0"] = { "111", "101", "101", "101", "111" },
	["1"] = { "010", "110", "010", "010", "111" },
	["2"] = { "111", "001", "111", "100", "111" },
	["3"] = { "111", "001", "111", "001", "111" },
	["8"] = { "111", "101", "111", "101", "111" },
	["K"] = { "101", "101", "110", "101", "101" },
	["A"] = { "010", "101", "111", "101", "101" },
	["I"] = { "111", "010", "010", "010", "111" },
}

local function drawText(parent, text, frame, pixel, color, depth, slant, label)
	local n = #text
	local totalCols = n * 4 - 1
	local startX = -totalCols * pixel / 2
	for i = 1, n do
		local glyph = FONT[text:sub(i, i)]
		if glyph then
			for r = 1, 5 do
				local row = glyph[r]
				for c = 1, 3 do
					if row:sub(c, c) == "1" then
						local px = startX + ((i - 1) * 4 + (c - 1) + 0.5) * pixel + (3 - r) * slant
						local py = (3 - r) * pixel
						boxCF(parent, label, V3(pixel, pixel, depth), frame * CF(px, py, depth / 2), color, SP)
					end
				end
			end
		end
	end
end

-- Logo KAI: huruf biru miring + swoosh oranye
local function drawKAI(parent, frame, pixel, depth)
	drawText(parent, "KAI", frame * CF(0, pixel * 0.4, 0), pixel, C.Blue, depth, pixel * 0.25, "KAI_Letter")
	local segs = 9
	local span = pixel * 11
	for i = 0, segs - 1 do
		local t = (i + 0.5) / segs
		local x = -span * 0.5 + span * t
		local y = -pixel * 3.0 + pixel * 5.4 * (t ^ 1.6)
		local slope = (pixel * 5.4 * 1.6 * (t ^ 0.6)) / span
		boxCF(
			parent,
			"KAI_Swoosh",
			V3(span / segs * 1.3, pixel * 0.45, depth * 1.4),
			frame * CF(x, y, depth * 0.7) * ANG(0, 0, math.atan(slope)),
			C.Orange,
			SP
		)
	end
end

local function numberPlate(parent, face, pos, plateSize, textPixel)
	local f = faceCF(pos, face)
	boxCF(parent, "NumberPlate", V3(plateSize.X, plateSize.Y, 0.05), f * CF(0, 0, 0.025), C.Black, SP)
	drawText(parent, "CC 201 83 31", f * CF(0, 0, 0.05), textPixel, C.White, 0.03, 0, "NumberText")
end
-- POTONGAN 2/9  (tempel berurutan jadi SATU script; jangan ubah isinya)
----------------------------------------------------------------------
-- HELPER KOMPONEN UMUM
----------------------------------------------------------------------
-- Jendela eksterior: kaca gelap + bingkai hitam (frame = permukaan dinding)
local function windowOnFace(parent, name, frame, w, h)
	local glass = boxCF(parent, name .. "_Glass", V3(w, h, 0.08), frame * CF(0, 0, 0.04), C.Glass, SP)
	glass.Reflectance = 0.2
	local t = 0.12
	boxCF(parent, name .. "_FrameTop", V3(w + 2 * t, t, 0.14), frame * CF(0, h / 2 + t / 2, 0.07), C.Black, SP)
	boxCF(parent, name .. "_FrameBottom", V3(w + 2 * t, t, 0.14), frame * CF(0, -h / 2 - t / 2, 0.07), C.Black, SP)
	boxCF(parent, name .. "_FrameLeft", V3(t, h, 0.14), frame * CF(-w / 2 - t / 2, 0, 0.07), C.Black, SP)
	boxCF(parent, name .. "_FrameRight", V3(t, h, 0.14), frame * CF(w / 2 + t / 2, 0, 0.07), C.Black, SP)
end

-- Jendela interior: kaca transparan + bingkai + ambang.
-- frame = pusat lubang pada permukaan dalam dinding; inw = arah ke dalam kabin pada sumbu Z lokal
local function interiorWindow(parent, name, frame, w, h, inw)
	local t = 0.1
	local d = 0.12
	local pane = boxCF(parent, name .. "_Pane", V3(w, h, 0.04), frame * CF(0, 0, -inw * 0.06), C.GlassIn, GLS, false)
	pane.Transparency = 0.55
	pane.Reflectance = 0.1
	boxCF(parent, name .. "_TrimTop", V3(w + 2 * t, t, d), frame * CF(0, h / 2 + t / 2, inw * d / 2), C.DarkSteel, MT, false)
	boxCF(parent, name .. "_TrimBottom", V3(w + 2 * t, t, d), frame * CF(0, -h / 2 - t / 2, inw * d / 2), C.DarkSteel, MT, false)
	boxCF(parent, name .. "_TrimLeft", V3(t, h, d), frame * CF(-w / 2 - t / 2, 0, inw * d / 2), C.DarkSteel, MT, false)
	boxCF(parent, name .. "_TrimRight", V3(t, h, d), frame * CF(w / 2 + t / 2, 0, inw * d / 2), C.DarkSteel, MT, false)
	boxCF(
		parent,
		name .. "_Sill",
		V3(w + 2 * t + 0.1, 0.08, d + 0.25),
		frame * CF(0, -h / 2 - t - 0.04, inw * (d + 0.25) / 2),
		C.Steel,
		MT,
		false
	)
end

-- Pegangan tangan berbentuk kotak (2 tiang + 2 palang)
local function handrail(parent, xa, xb, z, y0, y1)
	local len = y1 - y0
	local ym = (y0 + y1) / 2
	local xm = (xa + xb) / 2
	local span = math.abs(xb - xa)
	cyl(parent, "Handrail_Post", len, 0.18, V3(xa, ym, z), AXIS_Y, C.Steel, MT)
	cyl(parent, "Handrail_Post", len, 0.18, V3(xb, ym, z), AXIS_Y, C.Steel, MT)
	cyl(parent, "Handrail_Top", span + 0.18, 0.18, V3(xm, y1, z), AXIS_X, C.Steel, MT)
	cyl(parent, "Handrail_Mid", span, 0.14, V3(xm, ym, z), AXIS_X, C.Steel, MT)
	box(parent, "Handrail_Base", V3(0.4, 0.06, 0.4), V3(xa, y0 + 0.03, z), C.Black, MT)
	box(parent, "Handrail_Base", V3(0.4, 0.06, 0.4), V3(xb, y0 + 0.03, z), C.Black, MT)
end

-- Tangga samping (3 pijakan + 2 pegangan vertikal)
local function buildLadder(parent, xc, s)
	local zr = s * 4.95
	for _, dx in ipairs({ -0.75, 0.75 }) do
		cyl(parent, "Ladder_Rail", 6.8, 0.16, V3(xc + dx, 4.3, zr), AXIS_Y, C.Steel, MT)
		box(parent, "Ladder_BracketTop", V3(0.15, 0.15, 0.95), V3(xc + dx, 7.4, s * 4.475), C.Black, MT)
		box(parent, "Ladder_BracketDeck", V3(0.15, 0.15, 0.3), V3(xc + dx, 4.5, s * 4.8), C.Black, MT)
	end
	for _, y in ipairs({ 1.3, 2.65, 4.0 }) do
		box(parent, "Ladder_Step", V3(1.5, 0.1, 0.8), V3(xc, y, s * 4.6), C.Deck, MT)
		box(parent, "Ladder_StepRidge", V3(1.4, 0.05, 0.08), V3(xc, y + 0.07, s * 4.45), C.Steel, MT)
		box(parent, "Ladder_StepRidge", V3(1.4, 0.05, 0.08), V3(xc, y + 0.07, s * 4.75), C.Steel, MT)
	end
end

-- Lampu bulat (rumah hitam + lensa neon)
local function lamp(parent, name, pos, dia, lensColor)
	cyl(parent, name .. "_Housing", 0.35, dia + 0.25, pos, AXIS_X, C.Black, MT)
	cyl(parent, name .. "_Lens", 0.2, dia, pos + V3(0.2, 0, 0), AXIS_X, lensColor, NEON)
end

----------------------------------------------------------------------
-- DIMENSI UTAMA EKSTERIOR
----------------------------------------------------------------------
local WR = 1.7                       -- jari-jari roda
local HOOD_X0, HOOD_X1 = -22.6, 14.0 -- ujung belakang kap, dinding belakang kabin
local CAB_X1 = 21.8                  -- dinding depan kabin
local XH = (HOOD_X0 + HOOD_X1) / 2
local LH = HOOD_X1 - HOOD_X0
local XC = (HOOD_X1 + CAB_X1) / 2
local LC = CAB_X1 - HOOD_X1

----------------------------------------------------------------------
-- 1. RANGKA & DEK
----------------------------------------------------------------------
local function buildFrameAndDeck()
	local g = group(model, "Frame_And_Deck")
	local frame = box(g, "MainFrame", V3(47.4, 0.7, 7.0), V3(0, 3.95, 0), C.Black, MT, true)
	box(g, "Deck", V3(47.4, 0.4, 9.4), V3(0, 4.5, 0), C.Deck, MT, true)

	for _, s in ipairs(SIDES) do
		box(g, "DeckEdgeLip", V3(47.4, 0.3, 0.15), V3(0, 4.85, s * 4.625), C.DarkGrey, MT)
		for i = 0, 55 do
			local x = -22.4 + i * 0.8
			box(g, "DeckTreadBar", V3(0.18, 0.08, 0.5), V3(x, 4.74, s * 4.4), C.Steel, MT)
		end
	end
	for _, x in ipairs({ 22.1, 22.5, 22.9, 23.3, -22.9, -23.3 }) do
		box(g, "DeckTreadBar_End", V3(0.18, 0.08, 8.4), V3(x, 4.74, 0), C.Steel, MT)
	end
end

----------------------------------------------------------------------
-- 2. TANGKI, TABUNG UDARA, PIPA (rangka bawah)
----------------------------------------------------------------------
local function buildUndercarriage()
	local g = group(model, "Undercarriage")
	box(g, "FuelTank", V3(12, 1.6, 5.0), V3(0, 2.8, 0), C.Tank, MT, true)
	for i = -2, 2 do
		box(g, "FuelTank_Strap", V3(0.25, 1.7, 5.1), V3(i * 2.4, 2.8, 0), C.Black, MT)
	end
	for _, s in ipairs(SIDES) do
		cyl(g, "FuelTank_FillerCap", 0.2, 0.8, V3(0, 2.9, s * 2.55), AXIS_Z, C.Steel, MT)
		box(g, "FuelTank_Gauge", V3(0.5, 0.5, 0.1), V3(3.0, 2.6, s * 2.52), C.Black, SP)
		cyl(g, "AirReservoir", 10, 0.9, V3(0, 3.0, s * 3.15), AXIS_X, C.DarkGrey, MT)
		for _, bx in ipairs({ -3.5, -1.2, 1.2, 3.5 }) do
			cyl(g, "AirReservoir_Band", 0.25, 1.0, V3(bx, 3.0, s * 3.15), AXIS_X, C.Black, MT)
		end
		cyl(g, "AirBrakePipe", 44, 0.12, V3(0, 3.52, s * 2.62), AXIS_X, C.Steel, MT)
	end
end

----------------------------------------------------------------------
-- 3. BOGIE (3 gandar x 2 roda per bogie)
----------------------------------------------------------------------
local function buildWheelset(parent, x)
	cyl(parent, "Axle", 6.6, 0.45, V3(x, WR, 0), AXIS_Z, C.DarkGrey, MT)
	cyl(parent, "Axle_Motor", 2.4, 1.9, V3(x + 1.4, 2.1, 0), AXIS_Z, C.DarkGrey, MT)
	cyl(parent, "Axle_MotorBand", 0.15, 2.0, V3(x + 1.4, 2.1, 0), AXIS_Z, C.Black, MT)

	for _, s in ipairs(SIDES) do
		-- roda
		cyl(parent, "Wheel_Tread", 0.45, 3.4, V3(x, WR, s * 2.0), AXIS_Z, C.Wheel, MT)
		cyl(parent, "Wheel_Flange", 0.12, 3.56, V3(x, WR, s * 1.715), AXIS_Z, C.Wheel, MT)
		cyl(parent, "Wheel_Plate", 0.06, 2.9, V3(x, WR, s * 2.255), AXIS_Z, C.WheelPlate, MT)
		cyl(parent, "Wheel_Hub", 0.14, 0.95, V3(x, WR, s * 2.32), AXIS_Z, C.DarkGrey, MT)
		cyl(parent, "Wheel_HubCap", 0.2, 0.5, V3(x, WR, s * 2.38), AXIS_Z, C.Steel, MT)
		for k = 0, 7 do
			local a = k / 8 * 2 * PI
			cyl(
				parent,
				"Wheel_Bolt",
				0.08,
				0.15,
				V3(x + 1.05 * math.cos(a), WR + 1.05 * math.sin(a), s * 2.32),
				AXIS_Z,
				C.Steel,
				MT
			)
		end
		-- sepatu rem
		for _, dx in ipairs({ -1.9, 1.9 }) do
			box(parent, "BrakeShoe", V3(0.35, 1.0, 0.5), V3(x + dx, WR, s * 2.0), C.Black, MT)
		end
		-- kotak gandar, pegas, dudukan
		local zb = s * 2.95
		box(parent, "AxleBox", V3(1.2, 1.1, 0.75), V3(x, WR, zb), C.DarkGrey, MT)
		cyl(parent, "AxleBox_Cap", 0.12, 0.6, V3(x, WR, s * 3.38), AXIS_Z, C.Steel, MT)
		for _, bx in ipairs({ -0.45, 0.45 }) do
			for _, by in ipairs({ -0.4, 0.4 }) do
				cyl(parent, "AxleBox_Bolt", 0.08, 0.12, V3(x + bx, WR + by, s * 3.35), AXIS_Z, C.Steel, MT)
			end
		end
		cyl(parent, "Spring_Core", 0.7, 0.4, V3(x, 2.65, zb), AXIS_Y, C.Steel, MT)
		for k = 0, 3 do
			cyl(parent, "Spring_Coil", 0.07, 0.65, V3(x, 2.4 + k * 0.18, zb), AXIS_Y, C.DarkGrey, MT)
		end
		for _, dx in ipairs({ -0.72, 0.72 }) do
			box(parent, "Pedestal", V3(0.2, 1.9, 0.3), V3(x + dx, 2.15, s * 3.0), C.Black, MT)
		end
	end
end

local function buildBogie(parent, xb, name)
	local g = group(parent, name)
	for _, dx in ipairs({ -5, 0, 5 }) do
		buildWheelset(g, xb + dx)
	end
	for _, s in ipairs(SIDES) do
		box(g, "Bogie_SideFrame", V3(11.6, 0.55, 0.45), V3(xb, 3.275, s * 3.3), C.Black, MT)
	end
	for _, dx in ipairs({ -2.5, 2.5 }) do
		box(g, "Bogie_Transom", V3(0.6, 0.5, 6.6), V3(xb + dx, 3.25, 0), C.Black, MT)
	end
	cyl(g, "Bogie_CenterPlate", 0.5, 2.0, V3(xb, 3.35, 0), AXIS_Y, C.Steel, MT)
end

----------------------------------------------------------------------
-- 4. PINTU & VENTILASI SAMPING KAP MESIN
----------------------------------------------------------------------
local function buildDoor(parent, cx, s)
	local y0, y1 = 7.5, 10.2
	local h = y1 - y0
	local yc = (y0 + y1) / 2
	box(parent, "Door_Panel", V3(3.2, h - 0.2, 0.04), V3(cx, yc, s * 4.02), C.Cream, SP)
	box(parent, "Door_FrameTop", V3(3.4, 0.1, 0.08), V3(cx, y1 - 0.05, s * 4.04), C.DarkGrey, SP)
	box(parent, "Door_FrameBottom", V3(3.4, 0.1, 0.08), V3(cx, y0 + 0.05, s * 4.04), C.DarkGrey, SP)
	box(parent, "Door_FrameLeft", V3(0.1, h, 0.08), V3(cx - 1.65, yc, s * 4.04), C.DarkGrey, SP)
	box(parent, "Door_FrameRight", V3(0.1, h, 0.08), V3(cx + 1.65, yc, s * 4.04), C.DarkGrey, SP)
	box(parent, "Door_Handle", V3(0.12, 0.5, 0.14), V3(cx + 1.2, yc, s * 4.15), C.Black, MT)
	cyl(parent, "Door_Hinge", 0.5, 0.12, V3(cx - 1.55, yc + 0.7, s * 4.11), AXIS_Y, C.Black, MT)
	cyl(parent, "Door_Hinge", 0.5, 0.12, V3(cx - 1.55, yc - 0.7, s * 4.11), AXIS_Y, C.Black, MT)
end

local function buildVent(parent, cx, s)
	local y0, y1 = 7.5, 10.2
	local h = y1 - y0
	local yc = (y0 + y1) / 2
	box(parent, "Vent_Backing", V3(3.2, h - 0.2, 0.04), V3(cx, yc, s * 4.02), C.Black, SP)
	box(parent, "Vent_FrameTop", V3(3.4, 0.1, 0.1), V3(cx, y1 - 0.05, s * 4.05), C.Steel, MT)
	box(parent, "Vent_FrameBottom", V3(3.4, 0.1, 0.1), V3(cx, y0 + 0.05, s * 4.05), C.Steel, MT)
	box(parent, "Vent_FrameLeft", V3(0.1, h, 0.1), V3(cx - 1.65, yc, s * 4.05), C.Steel, MT)
	box(parent, "Vent_FrameRight", V3(0.1, h, 0.1), V3(cx + 1.65, yc, s * 4.05), C.Steel, MT)
	for i = 0, 10 do
		local y = 7.75 + i * 0.22
		boxCF(parent, "Vent_Slat", V3(3.1, 0.07, 0.3), CF(cx, y, s * 4.1) * ANG(rad(30 * s), 0, 0), C.Steel, MT)
	end
end
-- POTONGAN 3/9  (tempel berurutan jadi SATU script; jangan ubah isinya)
----------------------------------------------------------------------
-- 5. KAP MESIN (HOOD)
----------------------------------------------------------------------
local function buildHood()
	local g = group(model, "Hood")
	box(g, "Hood_Lower_Red", V3(LH, 2.4, 8.2), V3(XH, 5.9, 0), C.Red, SP, true)
	box(g, "Hood_Upper_White", V3(LH, 3.4, 8.0), V3(XH, 8.8, 0), C.White, SP, true)
	box(g, "Hood_Roof_Plate", V3(LH, 0.4, 7.6), V3(XH, 10.7, 0), C.Roof, MT, true)

	local sg = group(g, "Hood_Side_Details")
	for _, s in ipairs(SIDES) do
		local face = (s == 1) and "right" or "left"

		-- garis biru & aksen livery
		box(sg, "Livery_BlueStripe", V3(LH, 0.28, 0.06), V3(XH, 7.45, s * 4.03), C.Blue, SP)
		boxCF(sg, "Livery_BlueWedge", V3(4.0, 0.5, 0.06), CF(-19.8, 6.0, s * 4.13) * ANG(0, 0, rad(20)), C.Blue, SP)
		boxCF(sg, "Livery_DarkWedge", V3(3.2, 0.35, 0.06), CF(-19.0, 5.3, s * 4.13) * ANG(0, 0, rad(20)), C.Black, SP)

		-- garis panel
		for k = 0, 9 do
			local x = -22.2 + 4.0 * k
			box(sg, "Seam_Red", V3(0.06, 2.4, 0.06), V3(x, 5.9, s * 4.13), C.DarkRed, SP)
			if math.abs(x + 4.2) > 2.5 then
				box(sg, "Seam_White", V3(0.06, 3.4, 0.06), V3(x, 8.8, s * 4.03), C.DarkGrey, SP)
			end
		end

		-- pintu & ventilasi
		for _, cx in ipairs({ -20.2, -12.2, 3.8 }) do
			buildDoor(sg, cx, s)
		end
		for _, cx in ipairs({ -16.2, -8.2, -0.2, 7.8 }) do
			buildVent(sg, cx, s)
		end

		-- panel akses bagian merah
		for i = 0, 8 do
			local hx = -20.2 + 4.0 * i
			box(sg, "Hatch_Panel", V3(2.4, 1.5, 0.05), V3(hx, 5.9, s * 4.125), C.DarkRed, SP)
			box(sg, "Hatch_Handle", V3(0.4, 0.1, 0.1), V3(hx + 0.8, 5.9, s * 4.18), C.Steel, MT)
		end

		-- paku keling
		for _, y in ipairs({ 5.1, 6.7 }) do
			for x = -22.0, 13.6, 1.2 do
				cyl(sg, "Rivet", 0.08, 0.12, V3(x, y, s * 4.14), AXIS_Z, C.DarkRed, MT)
			end
		end

		-- logo KAI + nomor lokomotif
		drawKAI(sg, faceCF(V3(-4.2, 9.1, s * 4.0), face), 0.42, 0.06)
		numberPlate(sg, face, V3(11.7, 8.6, s * 4.0), V3(4.2, 0.62, 0), 0.085)
	end

	-- ujung belakang kap: kisi-kisi udara, lampu, nomor
	local rg = group(g, "Hood_Rear_Face")
	local f = faceCF(V3(HOOD_X0, 8.85, 0), "back")
	boxCF(rg, "RearGrille_Backing", V3(5.6, 2.5, 0.05), f * CF(0, 0, 0.025), C.Black, SP)
	boxCF(rg, "RearGrille_FrameTop", V3(5.9, 0.14, 0.1), f * CF(0, 1.32, 0.05), C.Steel, MT)
	boxCF(rg, "RearGrille_FrameBottom", V3(5.9, 0.14, 0.1), f * CF(0, -1.32, 0.05), C.Steel, MT)
	boxCF(rg, "RearGrille_FrameLeft", V3(0.14, 2.5, 0.1), f * CF(-2.87, 0, 0.05), C.Steel, MT)
	boxCF(rg, "RearGrille_FrameRight", V3(0.14, 2.5, 0.1), f * CF(2.87, 0, 0.05), C.Steel, MT)
	for i = 0, 10 do
		local y = -1.1 + i * 0.22
		boxCF(rg, "RearGrille_Slat", V3(5.4, 0.07, 0.3), f * CF(0, y, 0.1) * ANG(rad(30), 0, 0), C.Steel, MT)
	end
	for _, s in ipairs(SIDES) do
		cyl(rg, "TailLamp_Housing", 0.2, 0.9, V3(HOOD_X0 - 0.1, 9.9, s * 3.3), AXIS_X, C.Black, MT)
		cyl(rg, "TailLamp_Lens", 0.12, 0.65, V3(HOOD_X0 - 0.22, 9.9, s * 3.3), AXIS_X, C.LampRed, NEON)
	end
	numberPlate(rg, "back", V3(HOOD_X0, 6.0, 0), V3(4.2, 0.62, 0), 0.085)
	for _, s in ipairs(SIDES) do
		buildLadder(g, -21.8, s)
	end

	-- kaca belakang kabin (menghadap kap mesin)
	local cg = group(g, "Cab_Rear_Glass")
	for _, s in ipairs(SIDES) do
		windowOnFace(cg, "Cab_RearGlass", faceCF(V3(HOOD_X1, 11.7, s * 2.0), "back"), 2.7, 1.1)
	end
end

----------------------------------------------------------------------
-- JALANKAN BAGIAN 1 (rangka, bogie, kap mesin)
----------------------------------------------------------------------




----------------------------------------------------------------------
-- 6. KABIN MASINIS (EKSTERIOR)
----------------------------------------------------------------------
local function buildCab()
	local g = group(model, "Cab")
	box(g, "Cab_Lower_Red", V3(LC, 2.4, 8.2), V3(XC, 5.9, 0), C.Red, SP, true)
	box(g, "Cab_Upper_White", V3(LC, 5.4, 8.0), V3(XC, 9.8, 0), C.White, SP, true)
	box(g, "Cab_Roof", V3(8.5, 0.5, 8.6), V3(18.15, 12.75, 0), C.Roof, MT, true)
	cyl(g, "Cab_Roof_RoundFront", 8.1, 0.5, V3(22.15, 12.75, 0), AXIS_Z, C.Roof, MT)
	cyl(g, "Cab_Roof_RoundRear", 8.1, 0.5, V3(14.15, 12.75, 0), AXIS_Z, C.Roof, MT)
	for k = 0, 6 do
		box(g, "Cab_Roof_Rib", V3(0.12, 0.06, 8.2), V3(14.7 + k * 1.1, 13.03, 0), C.DarkGrey, MT)
	end

	-- muka depan: kaca depan, logo, nomor, wiper
	for _, s in ipairs(SIDES) do
		windowOnFace(g, "Windshield", faceCF(V3(CAB_X1, 10.8, s * 2.05), "front"), 3.2, 2.4)
		boxCF(g, "Wiper_Arm", V3(0.05, 1.4, 0.06), CF(CAB_X1 + 0.12, 10.1, s * 1.9) * ANG(rad(60 * s), 0, 0), C.Black, SP)
		cyl(g, "Wiper_Pivot", 0.15, 0.14, V3(CAB_X1 + 0.1, 9.45, s * 1.4), AXIS_X, C.Black, MT)
	end
	drawKAI(g, faceCF(V3(CAB_X1, 8.55, 0), "front"), 0.28, 0.06)
	numberPlate(g, "front", V3(CAB_X1, 7.6, 0), V3(4.2, 0.62, 0), 0.085)

	-- lampu utama & lampu kecil di depan atap kabin
	for _, z in ipairs({ -3.7, 3.7 }) do
		lamp(g, "CornerLight", V3(22.575, 12.75, z), 0.6, C.Lamp)
	end
	for _, z in ipairs({ -1.1, 0, 1.1 }) do
		lamp(g, "HeadLight", V3(22.575, 12.75, z), 0.45, C.Lamp)
	end

	-- sisi kiri-kanan kabin
	for _, s in ipairs(SIDES) do
		local face = (s == 1) and "right" or "left"
		windowOnFace(g, "Cab_RearSideWindow", faceCF(V3(15.9, 10.7, s * 4.0), face), 1.9, 1.9)
		windowOnFace(g, "Cab_DoorWindow", faceCF(V3(18.6, 10.6, s * 4.0), face), 1.6, 2.0)
		windowOnFace(g, "Cab_FrontSideWindow", faceCF(V3(20.8, 10.7, s * 4.0), face), 1.1, 1.9)

		-- pintu kabin
		box(g, "CabDoor_FrameTop", V3(2.8, 0.1, 0.16), V3(18.6, 12.05, s * 4.08), C.DarkGrey, SP)
		box(g, "CabDoor_FrameBottom", V3(2.8, 0.1, 0.16), V3(18.6, 5.05, s * 4.08), C.DarkGrey, SP)
		box(g, "CabDoor_FrameLeft", V3(0.1, 7.1, 0.16), V3(17.25, 8.55, s * 4.08), C.DarkGrey, SP)
		box(g, "CabDoor_FrameRight", V3(0.1, 7.1, 0.16), V3(19.95, 8.55, s * 4.08), C.DarkGrey, SP)
		box(g, "CabDoor_Handle", V3(0.35, 0.12, 0.14), V3(19.5, 8.6, s * 4.1), C.Black, MT)
		box(g, "CabDoor_KickPlate", V3(2.6, 0.5, 0.06), V3(18.6, 5.4, s * 4.13), C.Steel, MT)

		-- spion
		box(g, "Mirror_Arm", V3(0.1, 0.1, 0.7), V3(21.4, 9.9, s * 4.35), C.Black, MT)
		box(g, "Mirror_Glass", V3(0.08, 0.7, 0.45), V3(21.4, 9.9, s * 4.75), C.Black, SP)

		-- talang atap
		box(g, "Cab_DripRail", V3(7.8, 0.1, 0.18), V3(XC, 12.4, s * 4.05), C.Steel, MT)

		-- tangga + pegangan
		buildLadder(g, 18.6, s)

		-- ventilasi atap kabin
		box(g, "Cab_RoofVent", V3(1.2, 0.3, 1.2), V3(16.5, 13.15, s * 1.8), C.RoofLight, MT)
		for k = -1, 1 do
			box(g, "Cab_RoofVent_Slat", V3(0.9, 0.05, 0.1), V3(16.5, 13.33, s * 1.8 + k * 0.3), C.Black, MT)
		end
	end

	-- klakson, antena
	for _, z in ipairs({ -0.7, 0.7 }) do
		cyl(g, "Horn_Tube", 0.9, 0.35, V3(20.5, 13.45, z), AXIS_Y, C.DarkGrey, MT)
		cyl(g, "Horn_Bell", 0.3, 0.65, V3(20.5, 13.95, z), AXIS_Y, C.Steel, MT)
	end
	cyl(g, "Antenna_Base", 0.2, 0.3, V3(15.2, 13.1, 3.0), AXIS_Y, C.Black, MT)
	cyl(g, "Antenna_Mast", 1.6, 0.08, V3(15.2, 13.9, 3.0), AXIS_Y, C.Black, MT)
end

----------------------------------------------------------------------
-- 7. ATAP RUANG MESIN: KIPAS, KISI-KISI, EXHAUST, PANEL
----------------------------------------------------------------------
local function buildFan(parent, cx, cz)
	local base = 10.9
	cyl(parent, "Fan_Well", 0.1, 5.2, V3(cx, base + 0.05, cz), AXIS_Y, C.Black, MT)
	local R = 2.75
	for i = 0, 19 do
		local a = i / 20 * 2 * PI
		boxCF(
			parent,
			"Fan_Rim",
			V3(0.9, 0.55, 0.3),
			CF(cx + R * math.cos(a), base + 0.275, cz + R * math.sin(a)) * ANG(0, -a - PI / 2, 0),
			C.Roof,
			MT
		)
	end
	cyl(parent, "Fan_Hub", 0.45, 0.9, V3(cx, base + 0.3, cz), AXIS_Y, C.Steel, MT)
	for i = 0, 7 do
		local a = i / 8 * 2 * PI
		boxCF(
			parent,
			"Fan_Blade",
			V3(2.0, 0.07, 0.75),
			CF(cx, base + 0.3, cz) * ANG(0, -a, 0) * CF(1.45, 0, 0) * ANG(rad(20), 0, 0),
			C.WheelPlate,
			MT
		)
	end
	for i = 0, 5 do
		boxCF(parent, "Fan_GuardBar", V3(5.2, 0.08, 0.1), CF(cx, base + 0.62, cz) * ANG(0, i / 6 * PI, 0), C.DarkGrey, MT)
	end
	for _, ring in ipairs({ { 1.3, 12, 0.7 }, { 2.2, 18, 0.8 } }) do
		local r, n, len = ring[1], ring[2], ring[3]
		for i = 0, n - 1 do
			local a = i / n * 2 * PI
			boxCF(
				parent,
				"Fan_GuardRing",
				V3(len, 0.08, 0.1),
				CF(cx + r * math.cos(a), base + 0.62, cz + r * math.sin(a)) * ANG(0, -a - PI / 2, 0),
				C.DarkGrey,
				MT
			)
		end
	end
end

local function roofGrille(parent, cx, lenX, widZ, nSlats)
	box(parent, "RoofGrille_Base", V3(lenX, 0.1, widZ), V3(cx, 10.95, 0), C.Black, MT)
	for _, s in ipairs(SIDES) do
		box(parent, "RoofGrille_FrameSide", V3(lenX + 0.2, 0.2, 0.15), V3(cx, 11.0, s * widZ / 2), C.DarkGrey, MT)
		box(parent, "RoofGrille_FrameEnd", V3(0.15, 0.2, widZ + 0.2), V3(cx + s * lenX / 2, 11.0, 0), C.DarkGrey, MT)
	end
	for i = 1, nSlats do
		local x = cx - lenX / 2 + (i - 0.5) * lenX / nSlats
		boxCF(parent, "RoofGrille_Slat", V3(0.4, 0.07, widZ - 0.1), CF(x, 11.02, 0) * ANG(0, 0, rad(28)), C.Steel, MT)
	end
end

local function buildRoofDetails()
	local g = group(model, "Roof_Details")
	local top = 10.9

	-- panel atap
	for x = -22.0, 13.5, 2.0 do
		box(g, "Roof_Seam", V3(0.06, 0.05, 7.4), V3(x, top + 0.025, 0), C.DarkGrey, MT)
	end
	for _, s in ipairs(SIDES) do
		box(g, "Roof_EdgeRail", V3(36.0, 0.12, 0.14), V3(XH, top + 0.06, s * 3.7), C.DarkGrey, MT)
	end

	-- kipas pendingin
	buildFan(g, -15.0, 0)

	-- kisi-kisi ventilasi atap
	roofGrille(g, -5.5, 3.2, 5.4, 10)
	roofGrille(g, 3.2, 3.6, 5.4, 12)
	roofGrille(g, 11.2, 3.0, 5.4, 10)

	-- penutup panel atap + baut
	for _, cx in ipairs({ -9.5, 8.0 }) do
		box(g, "Roof_Hatch", V3(2.2, 0.12, 5.2), V3(cx, top + 0.06, 0), C.RoofLight, MT)
		for _, ix in ipairs({ -0.9, 0.9 }) do
			for _, iz in ipairs({ -2.3, -1.15, 0, 1.15, 2.3 }) do
				cyl(g, "Roof_Bolt", 0.06, 0.16, V3(cx + ix, top + 0.15, iz), AXIS_Y, C.Steel, MT)
			end
		end
	end

	-- exhaust
	local ex = -1.2
	cyl(g, "Exhaust_Flange", 0.15, 1.9, V3(ex, top + 0.075, 0), AXIS_Y, C.DarkGrey, MT)
	cyl(g, "Exhaust_Stack", 1.4, 1.1, V3(ex, top + 0.85, 0), AXIS_Y, C.Black, MT)
	cyl(g, "Exhaust_Band", 0.12, 1.3, V3(ex, top + 0.4, 0), AXIS_Y, C.Steel, MT)
	cyl(g, "Exhaust_Band", 0.12, 1.3, V3(ex, top + 1.2, 0), AXIS_Y, C.Steel, MT)
	for k = 0, 2 do
		local a = k / 3 * 2 * PI
		cyl(g, "Exhaust_CapPost", 0.35, 0.1, V3(ex + 0.55 * math.cos(a), top + 1.725, 0.55 * math.sin(a)), AXIS_Y, C.DarkGrey, MT)
	end
	cyl(g, "Exhaust_Cap", 0.1, 1.6, V3(ex, top + 1.95, 0), AXIS_Y, C.DarkGrey, MT)
end
-- POTONGAN 4/9  (tempel berurutan jadi SATU script; jangan ubah isinya)
----------------------------------------------------------------------
-- 8. UJUNG DEPAN / BELAKANG: headstock, coupler, selang, lampu
----------------------------------------------------------------------
local function buildEnd(sx)
	local g = group(model, (sx == 1) and "Front_End" or "Rear_End")

	box(g, "Headstock", V3(0.6, 1.8, 8.6), V3(sx * 23.7, 3.8, 0), C.Red, SP, true)

	for _, s in ipairs(SIDES) do
		-- lampu kecil di headstock
		cyl(g, "Marker_Housing", 0.2, 0.7, V3(sx * 24.1, 4.0, s * 3.7), AXIS_X, C.Black, MT)
		cyl(g, "Marker_Lens", 0.12, 0.5, V3(sx * 24.22, 4.0, s * 3.7), AXIS_X, (sx == 1) and C.Lamp or C.LampRed, NEON)

		-- selang rem udara
		cyl(g, "AirPipe_Stub", 0.6, 0.18, V3(sx * 24.3, 3.0, s * 1.5), AXIS_X, C.Steel, MT)
		for i = 0, 6 do
			local t = i / 6 * PI * 0.5
			ball(g, "AirHose", 0.22, V3(sx * (24.6 + 0.45 * math.sin(t)), 3.0 - 1.3 * (1 - math.cos(t)), s * 1.5), C.Rubber)
		end
		box(g, "AirHose_Gladhand", V3(0.25, 0.3, 0.25), V3(sx * 25.05, 1.6, s * 1.5), C.Steel, MT)

		-- kabel sambungan
		box(g, "Cable_Receptacle", V3(0.5, 0.5, 0.5), V3(sx * 24.25, 3.2, s * 2.6), C.Black, MT)
		for i = 0, 6 do
			local t = i / 6 * PI * 0.5
			ball(g, "Cable", 0.3, V3(sx * (24.5 + 0.4 * math.sin(t)), 3.2 - 1.0 * (1 - math.cos(t)), s * 2.6), C.DarkGrey)
		end

		-- pegangan tangan di platform ujung
		if sx == 1 then
			handrail(g, 22.2, 23.2, s * 4.45, 4.7, 8.2)
		else
			handrail(g, -22.8, -23.5, s * 4.45, 4.7, 7.4)
		end
	end

	-- coupler (knuckle)
	box(g, "Coupler_Shank", V3(1.0, 0.55, 0.65), V3(sx * 24.5, 3.4, 0), C.DarkGrey, MT)
	box(g, "Coupler_Head", V3(0.75, 0.85, 1.4), V3(sx * 24.875, 3.4, 0), C.DarkGrey, MT)
	box(g, "Coupler_Knuckle", V3(0.45, 0.7, 0.4), V3(sx * 25.0, 3.4, 0.6), C.Black, MT)
	cyl(g, "Coupler_Pin", 1.1, 0.18, V3(sx * 24.85, 3.4, 0), AXIS_Y, C.Steel, MT)
	cyl(g, "Coupler_LiftLever", 1.0, 0.1, V3(sx * 25.15, 3.9, -0.6), AXIS_Y, C.Steel, MT)
end

----------------------------------------------------------------------
-- JALANKAN EKSTERIOR (sisa) & CATAT JUMLAH PART EKSTERIOR
----------------------------------------------------------------------


----------------------------------------------------------------------
-- INTERIOR: STRUKTUR FOLDER & BATAS RUANG DALAM
-- Kabin   : x 14.4 .. 21.6, z -3.85 .. 3.85, y 4.85 .. 12.3
-- R. mesin: x -22.4 .. 14.2, z -3.85 .. 3.85, y 4.85 .. 10.3
----------------------------------------------------------------------
local interior = group(model, "CC201_Interior")

local F = {
	Shell = group(interior, "Cab_Shell"),
	Windows = group(interior, "Cab_Windows"),
	Dashboard = group(interior, "Cab_Dashboard"),
	Seats = group(interior, "Cab_Seats"),
	Controls = group(interior, "Cab_Controls"),
	Details = group(interior, "Cab_Details"),
	Engine = group(interior, "EngineRoom"),
}

local K = {
	X0 = 14.4,
	X1 = 21.6,
	ZH = 3.85,
	Y0 = 4.85,
	Y1 = 12.3,
	ER_X0 = -22.4,
	ER_X1 = 14.2,
	ER_Y1 = 10.3,
}
local LCX, LCY = (K.X0 + K.X1) / 2, (K.Y0 + K.Y1) / 2 -- pusat dinding kabin (18.0, 8.575)

----------------------------------------------------------------------
-- LANTAI KABIN
----------------------------------------------------------------------
local function buildCabFloor()
	local g = F.Shell
	local w, d = K.X1 - K.X0, K.ZH * 2
	box(g, "Cab_FloorPlate", V3(w, 0.15, d), V3(LCX, 4.775, 0), C.Floor, MT, true)

	for x = K.X0 + 0.3, K.X1 - 0.2, 0.5 do
		box(g, "Cab_FloorTread", V3(0.08, 0.04, d - 0.3), V3(x, 4.87, 0), C.DarkSteel, MT)
	end

	for _, s in ipairs(SIDES) do
		box(g, "Cab_FloorMat", V3(2.6, 0.06, 2.4), V3(19.4, 4.88, s * 2.0), C.Mat, SP)
		for k = 0, 4 do
			box(g, "Cab_FloorMatRib", V3(0.07, 0.02, 2.2), V3(18.4 + k * 0.5, 4.92, s * 2.0), C.Rubber, SP)
		end
	end

	box(g, "Cab_FloorHatch", V3(1.6, 0.05, 1.2), V3(16.0, 4.9, -2.4), C.DarkSteel, MT)
	for _, bx in ipairs({ -0.65, 0.65 }) do
		for _, bz in ipairs({ -0.45, 0.45 }) do
			cyl(g, "Cab_FloorHatchBolt", 0.04, 0.12, V3(16.0 + bx, 4.94, -2.4 + bz), AXIS_Y, C.Steel, MT)
		end
	end
	box(g, "Cab_FloorHatchHandle", V3(0.5, 0.04, 0.1), V3(16.0, 4.94, -2.4), C.Steel, MT)
end

----------------------------------------------------------------------
-- LANGIT-LANGIT KABIN
----------------------------------------------------------------------
local function buildCabCeiling()
	local g = F.Shell
	local w, d = K.X1 - K.X0, K.ZH * 2
	box(g, "Cab_CeilingPanel", V3(w, 0.2, d), V3(LCX, 12.4, 0), C.Ceiling, SP)
	for _, x in ipairs({ 15.2, 16.8, 18.4, 20.0 }) do
		box(g, "Cab_CeilingRib", V3(0.16, 0.08, d - 0.2), V3(x, 12.26, 0), C.Steel, MT)
	end
	for _, s in ipairs(SIDES) do
		box(g, "Cab_CeilingCove", V3(w, 0.18, 0.18), V3(LCX, 12.21, s * 3.76), C.Wall, SP)
	end
	box(g, "Cab_CeilingCoveFront", V3(0.18, 0.18, d), V3(K.X1 - 0.09, 12.21, 0), C.Wall, SP)
	box(g, "Cab_CeilingCoveRear", V3(0.18, 0.18, d), V3(K.X0 + 0.09, 12.21, 0), C.Wall, SP)
end

----------------------------------------------------------------------
-- DINDING KABIN: sisi kiri-kanan (jendela + pintu masuk) & depan (kaca depan)
----------------------------------------------------------------------
local function buildCabWalls()
	local g = F.Shell
	local wg = F.Windows
	local W, H = K.X1 - K.X0, K.Y1 - K.Y0

	local sideWindows = {
		{ name = "RearSideWindow", x = 15.9, y = 10.7, w = 1.9, h = 1.9, pz = 3.85 },
		{ name = "DoorWindow", x = 18.6, y = 10.6, w = 1.6, h = 2.0, pz = 3.77 },
		{ name = "FrontSideWindow", x = 20.8, y = 10.7, w = 1.1, h = 1.9, pz = 3.85 },
	}

	for _, s in ipairs(SIDES) do
		local holes = {}
		for _, o in ipairs(sideWindows) do
			table.insert(holes, { x = o.x - LCX, y = o.y - LCY, w = o.w, h = o.h })
		end
		panelWithHoles(g, "Cab_SideLining", CF(LCX, LCY, s * 3.91), W, H, 0.12, holes, C.Wall, SP)
		box(g, "Cab_SideDado", V3(W, 1.35, 0.05), V3(LCX, 5.525, s * 3.825), C.WallLower, SP)

		for _, o in ipairs(sideWindows) do
			interiorWindow(wg, "Cab_" .. o.name, CF(o.x, o.y, s * o.pz), o.w, o.h, -s)
		end

		-- pintu masuk kabin (daun pintu sisi dalam)
		panelWithHoles(
			g,
			"CabDoor_Leaf",
			CF(18.6, 8.55, s * 3.81),
			2.7,
			6.9,
			0.08,
			{ { x = 0, y = 2.05, w = 1.6, h = 2.0 } },
			C.Cream,
			SP
		)
		box(g, "CabDoor_TrimTop", V3(2.9, 0.1, 0.14), V3(18.6, 12.05, s * 3.78), C.DarkSteel, MT)
		box(g, "CabDoor_TrimBottom", V3(2.9, 0.1, 0.14), V3(18.6, 5.1, s * 3.78), C.DarkSteel, MT)
		box(g, "CabDoor_TrimLeft", V3(0.1, 6.9, 0.14), V3(17.25, 8.55, s * 3.78), C.DarkSteel, MT)
		box(g, "CabDoor_TrimRight", V3(0.1, 6.9, 0.14), V3(19.95, 8.55, s * 3.78), C.DarkSteel, MT)
		cyl(g, "CabDoor_HandleBar", 0.9, 0.1, V3(19.3, 8.4, s * 3.55), AXIS_X, C.Steel, MT)
		for _, hx in ipairs({ 18.9, 19.7 }) do
			cyl(g, "CabDoor_HandlePost", 0.22, 0.08, V3(hx, 8.4, s * 3.66), AXIS_Z, C.Steel, MT)
		end
		box(g, "CabDoor_Lock", V3(0.35, 0.22, 0.08), V3(19.3, 7.7, s * 3.73), C.Black, MT)
		box(g, "CabDoor_KickPlate", V3(2.5, 0.4, 0.04), V3(18.6, 5.4, s * 3.75), C.Steel, MT)
	end

	-- lapisan dinding depan dengan dua lubang kaca depan
	local fholes = {}
	for _, z in ipairs({ -2.05, 2.05 }) do
		table.insert(fholes, { x = -z, y = 10.8 - LCY, w = 3.2, h = 2.4 })
		interiorWindow(wg, "Cab_Windshield", CF(K.X1, 10.8, z) * ANG(0, PI / 2, 0), 3.2, 2.4, -1)
	end
	panelWithHoles(g, "Cab_FrontLining", CF(K.X1 + 0.06, LCY, 0) * ANG(0, PI / 2, 0), K.ZH * 2, H, 0.12, fholes, C.Wall, SP)
end

----------------------------------------------------------------------
-- SEKAT BELAKANG KABIN (pintu ke ruang mesin + kaca belakang)
----------------------------------------------------------------------
local function buildBulkhead()
	local g = F.Shell
	local wg = F.Windows
	local frame = CF(14.3, LCY, 0) * ANG(0, PI / 2, 0)

	local holes = { { x = 0, y = 7.575 - LCY, w = 2.4, h = 5.45 } }
	for _, z in ipairs({ -2.0, 2.0 }) do
		table.insert(holes, { x = -z, y = 11.7 - LCY, w = 2.7, h = 1.1 })
		interiorWindow(wg, "Cab_RearGlass", CF(K.X0, 11.7, z) * ANG(0, PI / 2, 0), 2.7, 1.1, 1)
	end
	panelWithHoles(g, "Cab_Bulkhead", frame, K.ZH * 2, K.Y1 - K.Y0, 0.2, holes, C.Wall, SP)

	for _, s in ipairs(SIDES) do
		box(g, "Cab_BulkheadDado", V3(0.05, 1.35, 2.65), V3(K.X0 + 0.025, 5.525, s * 2.525), C.WallLower, SP)
	end

	for _, s in ipairs(SIDES) do
		box(g, "EngineDoor_Jamb", V3(0.25, 5.45, 0.12), V3(14.5, 7.575, s * 1.26), C.DarkSteel, MT)
	end
	box(g, "EngineDoor_Header", V3(0.25, 0.12, 2.64), V3(14.5, 10.36, 0), C.DarkSteel, MT)
	box(g, "EngineDoor_Threshold", V3(0.5, 0.06, 2.6), V3(14.4, 4.88, 0), C.Steel, MT)
end
-- POTONGAN 5/9  (tempel berurutan jadi SATU script; jangan ubah isinya)
----------------------------------------------------------------------
-- PEMETAAN PANEL DASHBOARD MIRING: dari (x 20.0, y 8.0) ke (x 21.4, y 8.9)
-- u = jarak sepanjang kemiringan, z = melintang, off = tegak lurus panel
----------------------------------------------------------------------
local DASH_X0, DASH_Y0, DASH_X1, DASH_Y1 = 20.0, 8.0, 21.4, 8.9
local DASH_ANGLE = math.atan2(DASH_Y1 - DASH_Y0, DASH_X1 - DASH_X0)
local DASH_SIN, DASH_COS = math.sin(DASH_ANGLE), math.cos(DASH_ANGLE)
local DASH_TILT = ANG(0, 0, DASH_ANGLE)
local DASH_NORMAL_AXIS = ANG(0, 0, DASH_ANGLE + PI / 2)
local DASH_TOP = 0.075

local function dashPos(u, z, off)
	return V3(DASH_X0 + u * DASH_COS - off * DASH_SIN, DASH_Y0 + u * DASH_SIN + off * DASH_COS, z)
end

local function dashBox(parent, name, u, z, su, sn, sz, color, mat, lift)
	local off = DASH_TOP + sn / 2 + (lift or 0)
	return boxCF(parent, name, V3(su, sn, sz), CF(dashPos(u, z, off)) * DASH_TILT, color, mat, false)
end

local function dashCyl(parent, name, u, z, len, dia, color, mat, lift)
	local off = DASH_TOP + len / 2 + (lift or 0)
	return cylCF(parent, name, len, dia, CF(dashPos(u, z, off)) * DASH_NORMAL_AXIS, color, mat, false)
end

local function gauge(parent, name, u, z, dia, frac)
	dashCyl(parent, name .. "_Bezel", u, z, 0.12, dia + 0.1, C.DarkSteel, MT)
	dashCyl(parent, name .. "_Face", u, z, 0.08, dia, C.White, SP)
	local r = dia * 0.42
	local topOff = DASH_TOP + 0.095
	for i = 0, 9 do
		local a = rad(225 + i * 30)
		boxCF(
			parent,
			name .. "_Tick",
			V3(0.07, 0.02, 0.025),
			CF(dashPos(u + r * math.cos(a), z + r * math.sin(a), topOff)) * DASH_TILT * ANG(0, -a, 0),
			C.Black,
			SP,
			false
		)
	end
	local an = rad(225 + 270 * frac)
	local len = dia * 0.4
	boxCF(
		parent,
		name .. "_Needle",
		V3(len, 0.02, 0.03),
		CF(dashPos(u + len / 2 * math.cos(an), z + len / 2 * math.sin(an), topOff + 0.015)) * DASH_TILT * ANG(0, -an, 0),
		C.Red,
		SP,
		false
	)
	dashCyl(parent, name .. "_Cap", u, z, 0.04, dia * 0.18, C.Black, SP, 0.09)
	local gl = dashCyl(parent, name .. "_Glass", u, z, 0.02, dia, C.GlassIn, GLS, 0.125)
	gl.Transparency = 0.75
end

local function toggle(parent, u, z, color)
	dashBox(parent, "Toggle_Base", u, z, 0.2, 0.06, 0.2, C.DarkSteel, MT)
	local base = dashPos(u, z, DASH_TOP + 0.06)
	local tip = dashPos(u + 0.08, z, DASH_TOP + 0.28)
	pipe(parent, "Toggle_Lever", base, tip, 0.05, C.Steel, MT)
	ball(parent, "Toggle_Tip", 0.1, tip, color, SP)
end

local function pushButton(parent, u, z, color)
	dashCyl(parent, "Button_Bezel", u, z, 0.06, 0.26, C.DarkSteel, MT)
	dashCyl(parent, "Button_Cap", u, z, 0.1, 0.18, color, SP, 0.06)
end

local function indicator(parent, u, z, color)
	dashCyl(parent, "Indicator_Housing", u, z, 0.06, 0.22, C.Black, MT)
	dashCyl(parent, "Indicator_Lens", u, z, 0.08, 0.14, color, NEON, 0.06)
end

local function knob(parent, name, u, z, dia, ang)
	dashCyl(parent, name .. "_Base", u, z, 0.05, dia + 0.1, C.DarkSteel, MT)
	dashCyl(parent, name .. "_Knob", u, z, 0.14, dia, C.Black, SP, 0.05)
	boxCF(
		parent,
		name .. "_Pointer",
		V3(dia * 0.5, 0.02, 0.03),
		CF(dashPos(u + dia * 0.25 * math.cos(ang), z + dia * 0.25 * math.sin(ang), DASH_TOP + 0.202)) * DASH_TILT * ANG(0, -ang, 0),
		C.White,
		SP,
		false
	)
end

local function monitor(parent, name, u, z, su, sz)
	dashBox(parent, name .. "_Bezel", u, z, su, 0.1, sz, C.Black, SP)
	dashBox(parent, name .. "_Screen", u, z, su - 0.1, 0.02, sz - 0.1, Color3.fromRGB(20, 70, 96), NEON, 0.1)
	for i = 0, 2 do
		dashBox(parent, name .. "_Line", u - 0.12 + i * 0.12, z, 0.04, 0.02, sz - 0.3, C.Green, NEON, 0.12)
	end
end

----------------------------------------------------------------------
-- DASHBOARD & MEJA KONTROL
----------------------------------------------------------------------
local function buildDashboard()
	local g = F.Dashboard

	box(g, "Dash_Body", V3(1.7, 3.05, 7.4), V3(20.75, 6.375, 0), C.Console, SP, true)
	slabXY(g, "Dash_SlopePanel", DASH_X0, DASH_Y0, DASH_X1, DASH_Y1, 0.15, 7.4, 0, C.Panel, SP)
	box(g, "Dash_Fill", V3(0.55, 0.1, 7.4), V3(20.225, 7.95, 0), C.Console, SP)
	box(g, "Dash_Fill", V3(0.5, 0.35, 7.4), V3(20.75, 8.075, 0), C.Console, SP)
	box(g, "Dash_Fill", V3(0.6, 0.6, 7.4), V3(21.3, 8.2, 0), C.Console, SP)
	box(g, "Dash_Fill", V3(0.2, 0.45, 7.4), V3(21.5, 8.725, 0), C.Console, SP)
	box(g, "Dash_Cowl", V3(0.3, 0.12, 7.4), V3(21.45, 8.98, 0), C.Console, SP)
	cyl(g, "Dash_LipRail", 7.4, 0.1, V3(19.97, 7.95, 0), AXIS_Z, C.Steel, MT)

	box(g, "Dash_KickPanel", V3(0.05, 0.8, 7.0), V3(19.875, 5.35, 0), C.Panel, SP)
	for i = 0, 11 do
		box(g, "Dash_VentSlot", V3(0.04, 0.1, 0.5), V3(19.88, 6.4, -3.3 + i * 0.6), C.Black, SP)
	end
	for i = 0, 8 do
		box(g, "Dash_DefrostSlot", V3(0.12, 0.02, 0.4), V3(21.45, 9.05, -3.2 + i * 0.8), C.Black, SP)
	end
	for i = 0, 13 do
		dashCyl(g, "Dash_Bolt", 0.06, -3.4 + i * 0.52, 0.03, 0.09, C.Steel, MT)
	end

	-- indikator analog (sisi masinis, z positif)
	gauge(g, "Speedometer", 1.05, 2.85, 0.7, 0.35)
	gauge(g, "Tachometer", 1.05, 1.95, 0.62, 0.3)
	gauge(g, "AirPressureMR", 0.45, 3.2, 0.42, 0.8)
	gauge(g, "AirPressureBP", 0.45, 2.7, 0.42, 0.7)
	gauge(g, "EngineTemp", 0.45, 2.2, 0.42, 0.45)
	gauge(g, "FuelLevel", 0.45, 1.7, 0.42, 0.6)
	gauge(g, "Ammeter", 0.45, 1.2, 0.42, 0.4)

	local lampColors = { C.Green, C.Amber, C.Red }
	for i = 0, 10 do
		indicator(g, 1.57, 1.2 + i * 0.2, lampColors[(i % 3) + 1])
	end

	knob(g, "Knob_Wiper", 1.0, 1.2, 0.25, rad(300))
	knob(g, "Knob_Headlight", 1.0, 0.85, 0.25, rad(60))

	-- radio komunikasi (tengah)
	dashBox(g, "Radio_Body", 0.95, 0, 0.9, 0.12, 1.2, C.Black, MT)
	dashBox(g, "Radio_Display", 1.2, -0.25, 0.22, 0.02, 0.55, Color3.fromRGB(20, 110, 60), NEON, 0.12)
	for r = 0, 3 do
		for c = 0, 2 do
			dashBox(g, "Radio_Key", 0.65 + r * 0.13, 0.15 + c * 0.15, 0.1, 0.04, 0.12, C.Steel, SP, 0.12)
		end
	end
	for _, kz in ipairs({ 0.35, 0.5 }) do
		dashCyl(g, "Radio_Knob", 1.25, kz, 0.1, 0.16, C.Steel, MT, 0.12)
	end
	dashBox(g, "Handset_Cradle", 0.3, 0.1, 0.55, 0.08, 0.22, C.Black, SP)
	dashBox(g, "Handset_Body", 0.3, 0.1, 0.5, 0.1, 0.14, C.DarkSteel, SP, 0.08)
	for i = 0, 4 do
		ball(g, "Handset_Cord", 0.06, dashPos(0.55 + i * 0.1, 0.25 + 0.15 * math.sin(i), DASH_TOP + 0.15), C.Cable, SP)
	end

	dashCyl(g, "EmergencyStop_Base", 0.3, -0.9, 0.1, 0.36, C.Amber, SP)
	dashCyl(g, "EmergencyStop_Button", 0.3, -0.9, 0.14, 0.26, C.Red, SP, 0.1)

	-- sisi asisten (z negatif)
	monitor(g, "Monitor1", 1.1, -1.9, 0.75, 1.0)
	monitor(g, "Monitor2", 1.1, -3.0, 0.75, 0.9)
	for i = 0, 5 do
		toggle(g, 0.55, -1.5 - i * 0.4, (i % 2 == 0) and C.Red or C.Blue)
	end
	local btnColors = { C.Black, C.Green, C.White, C.Amber, C.Black, C.Red }
	for i = 0, 5 do
		pushButton(g, 0.2, -1.6 - i * 0.36, btnColors[i + 1])
	end
end

----------------------------------------------------------------------
-- TUAS & KONTROL LOKOMOTIF (stand masinis di z +2.0, stand asisten di z -2.0)
----------------------------------------------------------------------
local function lever(parent, name, p0, p1, knobColor, knobDia)
	cyl(parent, name .. "_Housing", 0.14, 0.38, p0, AXIS_Y, C.DarkSteel, MT)
	pipe(parent, name .. "_Arm", p0, p1, 0.09, C.Steel, MT)
	ball(parent, name .. "_Knob", knobDia, p1, knobColor, SP)
end

local function buildControls()
	local g = F.Controls

	for _, s in ipairs(SIDES) do
		local z0 = s * 2.0
		box(g, "Stand_Body", V3(0.6, 0.7, 1.7), V3(19.6, 7.15, z0), C.Console, SP)
		box(g, "Stand_TopPlate", V3(0.62, 0.06, 1.72), V3(19.6, 7.53, z0), C.DarkSteel, MT)
		for _, bx in ipairs({ -0.22, 0.22 }) do
			for _, bz in ipairs({ -0.75, 0.75 }) do
				cyl(g, "Stand_Bolt", 0.04, 0.1, V3(19.6 + bx, 7.58, z0 + bz), AXIS_Y, C.Steel, MT)
			end
		end
	end

	-- stand masinis
	lever(g, "Throttle", V3(19.65, 7.62, 2.55), V3(19.3, 8.3, 2.55), C.Black, 0.26)
	lever(g, "Reverser", V3(19.65, 7.62, 2.15), V3(19.65, 8.0, 2.15), C.Blue, 0.2)
	lever(g, "AutoBrake", V3(19.65, 7.62, 1.75), V3(19.3, 8.15, 1.75), C.Green, 0.24)
	lever(g, "IndependentBrake", V3(19.65, 7.62, 1.3), V3(19.45, 7.98, 1.3), C.Amber, 0.22)
	for i = 0, 7 do
		box(g, "Throttle_Notch", V3(0.04, 0.02, 0.14), V3(19.35 + i * 0.09, 7.57, 2.78), C.Steel, MT)
	end
	cyl(g, "Horn_Ring", 0.04, 0.3, V3(19.8, 7.58, 1.95), AXIS_Y, C.DarkSteel, MT)
	cyl(g, "Horn_Button", 0.1, 0.2, V3(19.8, 7.63, 1.95), AXIS_Y, C.Red, SP)

	-- pedal pengaman (dead-man) di lantai
	box(g, "Pedal_Base", V3(0.6, 0.12, 0.8), V3(19.6, 4.97, 2.0), C.DarkSteel, MT)
	boxCF(g, "Pedal_Plate", V3(0.55, 0.06, 0.7), CF(19.55, 5.1, 2.0) * ANG(0, 0, rad(15)), C.Steel, MT, false)
	cyl(g, "Pedal_Stem", 0.2, 0.1, V3(19.85, 5.1, 2.0), AXIS_Y, C.Steel, MT)

	-- stand asisten: knob wiper, sakelar lampu, tuas bantu
	cyl(g, "WiperControl_Base", 0.05, 0.44, V3(19.6, 7.585, -2.5), AXIS_Y, C.DarkSteel, MT)
	cyl(g, "WiperControl_Knob", 0.12, 0.34, V3(19.6, 7.65, -2.5), AXIS_Y, C.Black, SP)
	box(g, "WiperControl_Pointer", V3(0.2, 0.02, 0.04), V3(19.68, 7.72, -2.5), C.White, SP)
	for i = 0, 2 do
		box(g, "LightSwitch_Rocker", V3(0.16, 0.1, 0.22), V3(19.85, 7.62, -1.45 - i * 0.3), C.Black, SP)
		ball(g, "LightSwitch_Dot", 0.06, V3(19.85, 7.69, -1.45 - i * 0.3), C.Amber, NEON)
	end
	lever(g, "AssistLever", V3(19.5, 7.62, -2.7), V3(19.35, 7.95, -2.7), C.Blue, 0.2)
end


----------------------------------------------------------------------
-- KURSI MASINIS & ASISTEN (menghadap +X)
----------------------------------------------------------------------
local function buildSeats()
	local g = F.Seats

	local function seat(x0, z0, tag)
		cyl(g, tag .. "_BasePlate", 0.08, 1.1, V3(x0, 4.89, z0), AXIS_Y, C.DarkSteel, MT)
		cyl(g, tag .. "_Sleeve", 0.55, 0.5, V3(x0, 5.2, z0), AXIS_Y, C.DarkSteel, MT)
		cyl(g, tag .. "_Column", 0.9, 0.3, V3(x0, 5.65, z0), AXIS_Y, C.Steel, MT)
		cyl(g, tag .. "_Collar", 0.18, 0.6, V3(x0, 6.05, z0), AXIS_Y, C.DarkSteel, MT)
		for _, dz in ipairs({ -0.55, 0.55 }) do
			box(g, tag .. "_SlideRail", V3(1.5, 0.1, 0.12), V3(x0, 6.18, z0 + dz), C.SeatFrame, MT)
		end
		box(g, tag .. "_SeatPan", V3(1.55, 0.1, 1.6), V3(x0, 6.28, z0), C.SeatFrame, MT)
		box(g, tag .. "_Cushion", V3(1.45, 0.3, 1.45), V3(x0, 6.48, z0), C.Seat, FAB)
		cyl(g, tag .. "_CushionFront", 1.45, 0.3, V3(x0 + 0.72, 6.48, z0), AXIS_Z, C.Seat, FAB)
		for k = 0, 2 do
			box(g, tag .. "_CushionSeam", V3(0.03, 0.02, 1.3), V3(x0 - 0.35 + k * 0.35, 6.64, z0), C.Black, SP)
		end
		for _, dz in ipairs({ -0.65, 0.65 }) do
			box(g, tag .. "_Bolster", V3(1.3, 0.14, 0.18), V3(x0 - 0.05, 6.7, z0 + dz), C.Seat, FAB)
		end

		slabXY(g, tag .. "_Backrest", x0 - 0.7, 6.6, x0 - 0.98, 8.85, 0.32, 1.4, z0, C.Seat, FAB)
		slabXY(g, tag .. "_BackFrame", x0 - 0.88, 6.6, x0 - 1.16, 8.85, 0.08, 1.5, z0, C.SeatFrame, MT)
		slabXY(g, tag .. "_Headrest", x0 - 0.99, 8.9, x0 - 1.03, 9.55, 0.3, 0.95, z0, C.Seat, FAB)
		for _, dz in ipairs({ -0.25, 0.25 }) do
			pipe(g, tag .. "_HeadrestPost", V3(x0 - 0.98, 8.7, z0 + dz), V3(x0 - 1.01, 9.0, z0 + dz), 0.07, C.Steel, MT)
		end

		for _, dz in ipairs({ -0.88, 0.88 }) do
			pipe(g, tag .. "_ArmPost", V3(x0 - 0.6, 6.4, z0 + dz), V3(x0 - 0.6, 7.2, z0 + dz), 0.1, C.SeatFrame, MT)
			box(g, tag .. "_ArmPad", V3(0.95, 0.12, 0.28), V3(x0 - 0.2, 7.26, z0 + dz), C.Seat, FAB)
		end

		local lv0, lv1 = V3(x0 + 0.2, 6.15, z0 + 0.85), V3(x0 + 0.65, 6.0, z0 + 1.0)
		pipe(g, tag .. "_AdjLever", lv0, lv1, 0.06, C.Steel, MT)
		ball(g, tag .. "_AdjKnob", 0.14, lv1, C.Black, SP)
	end

	seat(18.4, 2.0, "Seat_Driver")
	seat(18.4, -2.0, "Seat_Assistant")
end
-- POTONGAN 6/9  (tempel berurutan jadi SATU script; jangan ubah isinya)
----------------------------------------------------------------------
-- DETAIL KABIN: wiper, pegangan, lampu, ventilasi, panel listrik, baut
----------------------------------------------------------------------
local function buildCabDetails()
	local g = F.Details

	for _, z in ipairs({ -2.05, 2.05 }) do
		box(g, "Visor_Board", V3(0.7, 0.06, 3.0), V3(21.15, 12.2, z), C.Panel, SP)
		cyl(g, "Visor_Hinge", 3.0, 0.1, V3(21.5, 12.2, z), AXIS_Z, C.Steel, MT)
		box(g, "Visor_Clip", V3(0.12, 0.1, 0.2), V3(20.85, 12.2, z), C.Steel, MT)
	end

	for _, s in ipairs(SIDES) do
		cyl(g, "WiperMotor", 0.45, 0.3, V3(21.45, 9.15, s * 1.4), AXIS_Y, C.DarkSteel, MT)
		cyl(g, "WiperShaft", 0.2, 0.08, V3(21.58, 9.15, s * 1.4), AXIS_X, C.Steel, MT)
		box(g, "WiperCrank", V3(0.05, 0.05, 0.5), V3(21.45, 9.4, s * 1.65), C.Steel, MT)
		pipe(g, "WiperLink", V3(21.45, 9.3, s * 1.4), V3(21.45, 9.3, s * 2.7), 0.05, C.Steel, MT)
	end

	for _, s in ipairs(SIDES) do
		for _, rx in ipairs({ 16.95, 20.15 }) do
			cyl(g, "Grabrail", 5.2, 0.14, V3(rx, 7.5, s * 3.55), AXIS_Y, C.Steel, MT)
			for _, by in ipairs({ 5.3, 9.9 }) do
				box(g, "Grabrail_Bracket", V3(0.12, 0.12, 0.3), V3(rx, by, s * 3.7), C.DarkSteel, MT)
			end
		end
		cyl(g, "Grabrail_Bulkhead", 5.0, 0.12, V3(14.6, 7.4, s * 1.55), AXIS_Y, C.Steel, MT)
		for _, by in ipairs({ 5.2, 9.6 }) do
			box(g, "Grabrail_BulkheadBracket", V3(0.2, 0.1, 0.1), V3(14.5, by, s * 1.55), C.DarkSteel, MT)
		end
	end

	for _, x in ipairs({ 15.9, 19.2 }) do
		cyl(g, "CabLamp_Housing", 0.1, 0.95, V3(x, 12.25, 0), AXIS_Y, C.Steel, MT)
		local lens = cyl(g, "CabLamp_Lens", 0.08, 0.75, V3(x, 12.17, 0), AXIS_Y, C.Cream, NEON)
	end

	for _, z in ipairs({ -2.3, 2.3 }) do
		box(g, "CeilingVent_Plate", V3(1.2, 0.05, 0.9), V3(17.6, 12.27, z), C.DarkSteel, MT)
		for k = 0, 4 do
			box(g, "CeilingVent_Slat", V3(1.1, 0.03, 0.06), V3(17.6, 12.245, z - 0.3 + k * 0.15), C.Steel, MT)
		end
	end
	for _, s in ipairs(SIDES) do
		box(g, "WallVent_Plate", V3(0.9, 0.5, 0.04), V3(15.6, 5.55, s * 3.775), C.DarkSteel, MT)
		for k = 0, 3 do
			box(g, "WallVent_Slat", V3(0.8, 0.03, 0.05), V3(15.6, 5.4 + k * 0.1, s * 3.76), C.Steel, MT)
		end
	end

	for _, s in ipairs(SIDES) do
		for x = 14.7, 21.3, 0.9 do
			cyl(g, "Wall_Bolt", 0.04, 0.1, V3(x, 6.15, s * 3.79), AXIS_Z, C.Steel, MT)
		end
	end
	for _, x in ipairs({ 15.2, 16.8, 18.4, 20.0 }) do
		for _, z in ipairs({ -3.4, 3.4 }) do
			cyl(g, "Ceiling_Bolt", 0.04, 0.12, V3(x, 12.21, z), AXIS_Y, C.Steel, MT)
		end
	end

	-- panel listrik di sekat (sisi z positif)
	box(g, "ElecCabinet_Body", V3(0.4, 2.6, 1.3), V3(14.6, 7.35, 3.05), C.DarkSteel, MT)
	box(g, "ElecCabinet_Door", V3(0.04, 2.3, 1.1), V3(14.82, 7.35, 3.05), C.Cream, SP)
	box(g, "ElecCabinet_Handle", V3(0.08, 0.5, 0.1), V3(14.87, 6.9, 3.5), C.Steel, MT)
	box(g, "ElecCabinet_Warning", V3(0.04, 0.3, 0.5), V3(14.85, 6.4, 3.05), C.Amber, SP)
	for r = 0, 1 do
		for c = 0, 3 do
			box(g, "ElecCabinet_Breaker", V3(0.06, 0.2, 0.1), V3(14.87, 8.2 - r * 0.4, 2.55 + c * 0.25), C.Black, SP)
		end
	end
	local panelLamps = { C.Green, C.Amber, C.Red }
	for i = 0, 2 do
		cyl(g, "ElecCabinet_Lamp", 0.05, 0.14, V3(14.86, 7.3, 2.65 + i * 0.35), AXIS_X, panelLamps[i + 1], NEON)
	end

	-- alat pemadam api, kotak P3K, jam dinding (sisi z negatif)
	cyl(g, "Extinguisher_Body", 1.6, 0.5, V3(14.75, 6.2, -2.8), AXIS_Y, C.Red, SP)
	cyl(g, "Extinguisher_Neck", 0.2, 0.2, V3(14.75, 7.1, -2.8), AXIS_Y, C.Steel, MT)
	box(g, "Extinguisher_Handle", V3(0.3, 0.08, 0.1), V3(14.75, 7.25, -2.8), C.Black, MT)
	pipe(g, "Extinguisher_Hose", V3(14.75, 7.15, -2.65), V3(14.95, 6.4, -2.55), 0.08, C.Black, SP)
	for _, by in ipairs({ 5.7, 6.7 }) do
		cyl(g, "Extinguisher_Strap", 0.08, 0.56, V3(14.75, by, -2.8), AXIS_Y, C.Steel, MT)
	end
	box(g, "Extinguisher_MountPlate", V3(0.05, 1.9, 0.6), V3(14.43, 6.2, -2.8), C.DarkSteel, MT)
	box(g, "FirstAid_Box", V3(0.2, 0.6, 0.7), V3(14.5, 8.1, -2.8), C.White, SP)
	box(g, "FirstAid_CrossV", V3(0.04, 0.4, 0.1), V3(14.62, 8.1, -2.8), C.Red, SP)
	box(g, "FirstAid_CrossH", V3(0.04, 0.1, 0.4), V3(14.62, 8.1, -2.8), C.Red, SP)
	cyl(g, "Clock_Bezel", 0.04, 0.92, V3(14.42, 10.0, -1.9), AXIS_X, C.Black, MT)
	cyl(g, "Clock_Face", 0.06, 0.8, V3(14.43, 10.0, -1.9), AXIS_X, C.White, SP)
	box(g, "Clock_HourHand", V3(0.02, 0.28, 0.04), V3(14.47, 10.14, -1.9), C.Black, SP)
	box(g, "Clock_MinuteHand", V3(0.02, 0.04, 0.32), V3(14.47, 10.0, -1.74), C.Black, SP)
end

----------------------------------------------------------------------
-- KULIT RUANG MESIN (lantai, dinding, plafon, pintu dari kabin, aki, panel)
----------------------------------------------------------------------
local function buildEngineShell()
	local g = F.Engine
	local L = K.ER_X1 - K.ER_X0
	local XM = (K.ER_X0 + K.ER_X1) / 2
	local d = K.ZH * 2

	box(g, "ER_FloorPlate", V3(L, 0.15, d), V3(XM, 4.775, 0), C.Floor, MT, true)
	for x = K.ER_X0 + 0.4, K.ER_X1 - 0.3, 0.8 do
		box(g, "ER_FloorGrating", V3(0.1, 0.04, d - 0.3), V3(x, 4.87, 0), C.DarkSteel, MT)
	end
	for _, s in ipairs(SIDES) do
		box(g, "ER_WalkLine", V3(L - 1, 0.02, 0.15), V3(XM, 4.86, s * 2.45), C.Amber, SP)
	end

	for _, s in ipairs(SIDES) do
		box(g, "ER_SideLining", V3(L, 5.45, 0.12), V3(XM, 7.575, s * 3.91), C.Wall, SP)
		box(g, "ER_SideDado", V3(L, 1.2, 0.05), V3(XM, 5.45, s * 3.825), C.WallLower, SP)
		for i = 0, 17 do
			box(g, "ER_WallRib", V3(0.15, 5.45, 0.2), V3(-21.4 + i * 2.0, 7.575, s * 3.75), C.DarkSteel, MT)
		end
		for _, y in ipairs({ 5.6, 9.2 }) do
			box(g, "ER_WallRail", V3(L, 0.12, 0.15), V3(XM, y, s * 3.76), C.Steel, MT)
		end
	end

	box(g, "ER_Ceiling", V3(L, 0.2, d), V3(XM, 10.4, 0), C.Ceiling, SP)
	for i = 0, 11 do
		box(g, "ER_CeilingRib", V3(0.2, 0.2, 7.5), V3(-21.0 + i * 3.0, 10.2, 0), C.DarkSteel, MT)
	end

	box(g, "ER_RearLining", V3(0.12, 5.45, d), V3(K.ER_X0 - 0.06, 7.575, 0), C.Wall, SP)
	for _, z in ipairs({ -3.0, -1.5, 0, 1.5, 3.0 }) do
		box(g, "ER_RearRib", V3(0.2, 5.45, 0.15), V3(K.ER_X0 + 0.1, 7.575, z), C.DarkSteel, MT)
	end

	for _, s in ipairs(SIDES) do
		box(g, "ER_DoorJamb", V3(0.2, 5.45, 0.12), V3(14.1, 7.575, s * 1.26), C.DarkSteel, MT)
	end
	box(g, "ER_DoorHeader", V3(0.2, 0.12, 2.64), V3(14.1, 10.24, 0), C.DarkSteel, MT)
	panelWithHoles(g, "ER_DoorLeaf", CF(12.95, 7.55, 1.4), 2.3, 5.4, 0.08, { { x = 0.2, y = 1.4, w = 0.9, h = 0.8 } }, C.Cream, SP)
	for _, y in ipairs({ 5.6, 7.6, 9.6 }) do
		cyl(g, "ER_DoorHinge", 0.5, 0.14, V3(14.05, y, 1.4), AXIS_Y, C.Black, MT)
	end
	box(g, "ER_DoorHandle", V3(0.3, 0.1, 0.14), V3(12.4, 7.4, 1.48), C.Steel, MT)

	for i = 0, 3 do
		local x = 2.0 + i * 2.0
		box(g, "Battery_Case", V3(1.7, 1.3, 0.9), V3(x, 5.55, -3.25), C.DarkSteel, MT)
		box(g, "Battery_Lid", V3(1.7, 0.12, 0.9), V3(x, 6.26, -3.25), C.Black, MT)
		cyl(g, "Battery_TerminalPos", 0.15, 0.18, V3(x + 0.5, 6.4, -3.25), AXIS_Y, C.Red, MT)
		cyl(g, "Battery_TerminalNeg", 0.15, 0.18, V3(x - 0.5, 6.4, -3.25), AXIS_Y, C.Black, MT)
		cyl(g, "Battery_Handle", 0.5, 0.06, V3(x, 6.35, -2.78), AXIS_X, C.Steel, MT)
	end

	box(g, "ER_Cabinet_Body", V3(1.8, 4.2, 1.1), V3(10.5, 7.05, 3.2), C.DarkSteel, MT)
	box(g, "ER_Cabinet_Door", V3(1.7, 4.0, 0.05), V3(10.5, 7.05, 2.62), C.Cream, SP)
	box(g, "ER_Cabinet_Handle", V3(0.1, 0.6, 0.1), V3(11.2, 7.0, 2.56), C.Steel, MT)
	box(g, "ER_Cabinet_Warning", V3(0.5, 0.3, 0.03), V3(10.5, 9.0, 2.6), C.Amber, SP)
	for r = 0, 1 do
		for c = 0, 5 do
			box(g, "ER_Cabinet_Breaker", V3(0.14, 0.22, 0.05), V3(9.8 + c * 0.28, 8.2 - r * 0.45, 2.59), C.Black, SP)
		end
	end
	local cabLamps = { C.Green, C.Amber, C.Red, C.Green }
	for i = 0, 3 do
		cyl(g, "ER_Cabinet_Lamp", 0.05, 0.14, V3(9.9 + i * 0.4, 7.0, 2.6), AXIS_Z, cabLamps[i + 1], NEON)
	end
	for i = 0, 4 do
		box(g, "ER_Cabinet_VentSlot", V3(0.9, 0.05, 0.05), V3(10.5, 5.6 + i * 0.12, 2.6), C.Black, SP)
	end
end

----------------------------------------------------------------------
-- MESIN DIESEL V16 (model dekoratif, x -12.9 .. -1.5)
----------------------------------------------------------------------
local function buildEngine()
	local g = F.Engine
	local XE = -7.2

	box(g, "Engine_Skid", V3(12.4, 0.5, 3.4), V3(XE, 5.1, 0), C.EngineDark, MT, true)
	box(g, "Engine_Crankcase", V3(11.4, 1.5, 3.0), V3(XE, 6.1, 0), C.Engine, MT)
	for i = 0, 9 do
		box(g, "Engine_CaseRib", V3(0.12, 1.4, 3.1), V3(XE - 5.4 + i * 1.2, 6.1, 0), C.EngineDark, MT)
	end
	for _, bx in ipairs({ -5.4, -2.7, 0, 2.7, 5.4 }) do
		for _, s in ipairs(SIDES) do
			cyl(g, "Engine_SkidBolt", 0.1, 0.2, V3(XE + bx, 5.4, s * 1.6), AXIS_Y, C.Steel, MT)
		end
	end
	cyl(g, "Engine_IntakePlenum", 9.6, 0.9, V3(XE, 7.3, 0), AXIS_X, C.PipeGrey, MT)

	for _, s in ipairs(SIDES) do
		local bank = CF(XE, 7.4, s * 0.55) * ANG(rad(22 * s), 0, 0)
		boxCF(g, "Engine_Bank", V3(11.0, 1.9, 1.5), bank, C.Engine, MT, false)
		for k = 0, 7 do
			local xo = -4.9 + k * 1.4
			cylCF(g, "Engine_Cylinder", 0.7, 0.85, bank * CF(xo, 1.3, 0) * AXIS_Y, C.Engine, MT, false)
			cylCF(g, "Engine_ValveCover", 0.2, 0.7, bank * CF(xo, 1.75, 0) * AXIS_Y, C.EngineDark, MT, false)
			cylCF(g, "Engine_RockerBolt", 0.1, 0.16, bank * CF(xo, 1.9, 0) * AXIS_Y, C.Steel, MT, false)
		end
		cylCF(g, "Engine_OilRail", 10.2, 0.14, bank * CF(0, 2.05, 0), C.Brass, MT, false)
		cylCF(g, "Engine_ExhaustManifold", 10.6, 0.5, bank * CF(0, 0.5, s * 0.95), C.EngineDark, MT, false)
		for i = 0, 3 do
			cylCF(g, "Engine_ManifoldClamp", 0.12, 0.62, bank * CF(-3.9 + i * 2.6, 0.5, s * 0.95), C.Steel, MT, false)
		end
		local mEnd = (bank * CF(5.3, 0.5, s * 0.95)).Position
		pipe(g, "Engine_ExhaustLink", mEnd, V3(-1.2, 8.4, 0), 0.5, C.EngineDark, MT)
	end

	cyl(g, "Engine_ExhaustDuct", 2.2, 0.9, V3(-1.2, 9.2, 0), AXIS_Y, C.PipeGrey, MT)
	cyl(g, "Engine_ExhaustFlangeLow", 0.12, 1.3, V3(-1.2, 8.15, 0), AXIS_Y, C.Steel, MT)
	cyl(g, "Engine_ExhaustFlangeTop", 0.12, 1.3, V3(-1.2, 10.2, 0), AXIS_Y, C.Steel, MT)

	box(g, "Engine_GearCase", V3(1.2, 2.6, 3.0), V3(-13.4, 6.15, 0), C.Engine, MT)
	for k = 0, 2 do
		local z = -0.9 + k * 0.9
		cyl(g, "Engine_OilFilter", 1.0, 0.55, V3(-13.4, 7.95, z), AXIS_Y, C.Blue, MT)
		cyl(g, "Engine_OilFilterCap", 0.1, 0.3, V3(-13.4, 8.5, z), AXIS_Y, C.Steel, MT)
	end
	pipe(g, "Engine_OilLine", V3(-13.4, 7.4, 0.9), V3(-12.5, 6.6, 1.5), 0.14, C.Brass, MT)
	pipe(g, "Engine_OilLine", V3(-13.4, 7.4, -0.9), V3(-12.5, 6.6, -1.5), 0.14, C.Brass, MT)
	box(g, "Engine_DataPlate", V3(0.9, 0.45, 0.02), V3(XE + 1.0, 6.1, -1.51), C.Brass, MT)
end

----------------------------------------------------------------------
-- GENERATOR UTAMA & ALTERNATOR BANTU
----------------------------------------------------------------------
local function buildGenerator()
	local g = F.Engine
	cyl(g, "Coupling_Housing", 1.0, 1.4, V3(-1.0, 6.1, 0), AXIS_X, C.EngineDark, MT)
	box(g, "Generator_Base", V3(4.6, 0.4, 3.0), V3(1.6, 5.05, 0), C.DarkSteel, MT, true)
	cyl(g, "Generator_Body", 4.2, 2.6, V3(1.6, 6.5, 0), AXIS_X, C.Generator, MT)
	for i = 0, 5 do
		cyl(g, "Generator_Band", 0.15, 2.7, V3(-0.2 + i * 0.72, 6.5, 0), AXIS_X, C.DarkSteel, MT)
	end
	cyl(g, "Generator_EndCap", 0.3, 2.0, V3(3.85, 6.5, 0), AXIS_X, C.Steel, MT)
	cyl(g, "Generator_Blower", 0.9, 1.5, V3(4.4, 6.5, 0), AXIS_X, C.EngineDark, MT)
	for _, s in ipairs(SIDES) do
		box(g, "Generator_Foot", V3(3.6, 0.5, 0.3), V3(1.6, 5.45, s * 1.2), C.DarkSteel, MT)
	end
	box(g, "Generator_TerminalBox", V3(1.3, 0.7, 1.0), V3(1.6, 8.15, 0), C.DarkSteel, MT)
	for i = 0, 2 do
		cyl(g, "Generator_Lug", 0.35, 0.2, V3(1.1 + i * 0.5, 8.675, 0), AXIS_Y, C.Brass, MT)
	end
	for _, bx in ipairs({ -0.5, 0.5 }) do
		for _, bz in ipairs({ -0.35, 0.35 }) do
			cyl(g, "Generator_CoverBolt", 0.05, 0.1, V3(1.6 + bx, 8.52, bz), AXIS_Y, C.Steel, MT)
		end
	end
	box(g, "Generator_DataPlate", V3(0.7, 0.4, 0.02), V3(1.6, 6.5, -1.31), C.Brass, MT)

	box(g, "Aux_Base", V3(2.0, 0.3, 1.8), V3(6.0, 5.0, 0), C.DarkSteel, MT)
	cyl(g, "Aux_Body", 1.8, 1.5, V3(6.0, 5.95, 0), AXIS_X, C.Engine, MT)
	cyl(g, "Aux_Shaft", 0.6, 0.4, V3(4.95, 5.95, 0), AXIS_X, C.Steel, MT)
	box(g, "Aux_TerminalBox", V3(0.6, 0.4, 0.6), V3(6.0, 6.9, 0), C.DarkSteel, MT)
end
-- POTONGAN 7/9  (tempel berurutan jadi SATU script; jangan ubah isinya)
----------------------------------------------------------------------
-- RADIATOR + KIPAS PENDINGIN (di bawah kipas atap pada x -15)
----------------------------------------------------------------------
local function buildRadiator()
	local g = F.Engine
	local rx = -17.2

	box(g, "Radiator_Core", V3(4.8, 1.6, 5.4), V3(rx, 8.3, 0), C.Radiator, MT)
	for i = 0, 23 do
		box(g, "Radiator_Fin", V3(0.04, 1.5, 5.5), V3(rx - 2.3 + i * 0.2, 8.3, 0), C.Steel, MT)
	end
	box(g, "Radiator_TankTop", V3(5.0, 0.3, 5.6), V3(rx, 9.25, 0), C.EngineDark, MT)
	box(g, "Radiator_TankBottom", V3(5.0, 0.3, 5.6), V3(rx, 7.35, 0), C.EngineDark, MT)
	for _, sx in ipairs(SIDES) do
		box(g, "Radiator_SideFrame", V3(0.2, 2.4, 5.6), V3(rx + sx * 2.5, 8.3, 0), C.DarkSteel, MT)
	end

	pipe(g, "Radiator_HoseTop", V3(-14.8, 9.25, 1.8), V3(-13.0, 8.0, 1.8), 0.45, C.Rubber, SP)
	pipe(g, "Radiator_HoseBottom", V3(-14.8, 7.35, -1.8), V3(-13.4, 6.6, -1.5), 0.45, C.Rubber, SP)
	for _, t in ipairs({ 0.25, 0.75 }) do
		local a, b = V3(-14.8, 9.25, 1.8), V3(-13.0, 8.0, 1.8)
		cyl(g, "Radiator_HoseClamp", 0.1, 0.55, a:Lerp(b, t), AXIS_X, C.Steel, MT)
	end

	cyl(g, "Expansion_Tank", 2.4, 0.7, V3(rx, 9.85, 1.8), AXIS_X, C.EngineDark, MT)
	for _, dx in ipairs({ -0.8, 0.8 }) do
		cyl(g, "Expansion_Strap", 0.1, 0.78, V3(rx + dx, 9.85, 1.8), AXIS_X, C.Steel, MT)
	end

	local fx = -15.0
	for i = 0, 15 do
		local a = i / 16 * 2 * PI
		boxCF(
			g,
			"Fan_Shroud",
			V3(1.0, 0.6, 0.15),
			CF(fx + 2.5 * math.cos(a), 9.95, 2.5 * math.sin(a)) * ANG(0, -a - PI / 2, 0),
			C.DarkSteel,
			MT,
			false
		)
	end
	cyl(g, "Fan_Hub", 0.5, 0.9, V3(fx, 10.05, 0), AXIS_Y, C.Steel, MT)
	cyl(g, "Fan_Shaft", 0.8, 0.3, V3(fx, 9.9, 0), AXIS_Y, C.DarkSteel, MT)
	for i = 0, 5 do
		local a = i / 6 * 2 * PI
		boxCF(
			g,
			"Fan_Blade",
			V3(2.0, 0.07, 0.6),
			CF(fx, 10.0, 0) * ANG(0, -a, 0) * CF(1.45, 0, 0) * ANG(rad(20), 0, 0),
			C.WheelPlate,
			MT,
			false
		)
	end
	for i = 0, 2 do
		boxCF(g, "Fan_GuardBar", V3(4.8, 0.06, 0.08), CF(fx, 9.7, 0) * ANG(0, i / 3 * PI, 0), C.DarkSteel, MT, false)
	end
end

----------------------------------------------------------------------
-- KOMPRESOR UDARA & TANGKI UDARA
----------------------------------------------------------------------
local function buildAuxiliary()
	local g = F.Engine
	local cx, cz = 8.7, -1.4

	box(g, "Compressor_Base", V3(2.4, 0.3, 1.5), V3(cx, 5.0, cz), C.DarkSteel, MT)
	box(g, "Compressor_Crankcase", V3(2.0, 1.0, 1.2), V3(cx, 5.65, cz), C.Engine, MT)
	for _, dx in ipairs({ -0.55, 0.55 }) do
		cyl(g, "Compressor_Cylinder", 1.3, 0.8, V3(cx + dx, 6.8, cz), AXIS_Y, C.EngineDark, MT)
		for k = 0, 3 do
			cyl(g, "Compressor_Fin", 0.06, 1.0, V3(cx + dx, 6.35 + k * 0.3, cz), AXIS_Y, C.Steel, MT)
		end
	end
	pipe(g, "Compressor_Intercooler", V3(cx - 0.55, 7.5, cz), V3(cx + 0.55, 7.5, cz), 0.2, C.Pipe, MT)
	cyl(g, "Compressor_Flywheel", 0.2, 1.3, V3(cx + 1.3, 5.7, cz), AXIS_Z, C.DarkSteel, MT)
	cyl(g, "Compressor_FlywheelHub", 0.3, 0.3, V3(cx + 1.3, 5.7, cz), AXIS_Z, C.Steel, MT)

	cyl(g, "AirTank_Body", 3.0, 0.9, V3(8.6, 5.3, 1.7), AXIS_X, C.PipeGrey, MT)
	ball(g, "AirTank_CapFront", 0.9, V3(10.1, 5.3, 1.7), C.PipeGrey, MT)
	ball(g, "AirTank_CapRear", 0.9, V3(7.1, 5.3, 1.7), C.PipeGrey, MT)
	for _, x in ipairs({ 7.8, 9.4 }) do
		cyl(g, "AirTank_Strap", 0.15, 1.0, V3(x, 5.3, 1.7), AXIS_X, C.Black, MT)
	end
	cyl(g, "AirTank_Gauge", 0.08, 0.3, V3(8.6, 5.3, 2.19), AXIS_Z, C.White, SP)
	cyl(g, "AirTank_Drain", 0.25, 0.12, V3(8.6, 4.95, 1.7), AXIS_Y, C.Steel, MT)
	pipe(g, "Compressor_AirLine", V3(cx, 7.5, cz), V3(8.6, 5.8, 1.7), 0.18, C.Pipe, MT)
end

----------------------------------------------------------------------
-- PIPA & KABEL
----------------------------------------------------------------------
local function buildPiping()
	local g = F.Engine

	cyl(g, "Pipe_Water", 22, 0.28, V3(-8.0, 5.7, 3.45), AXIS_X, C.Pipe, MT)
	cyl(g, "Pipe_Fuel", 20, 0.22, V3(-9.0, 7.0, -3.5), AXIS_X, C.PipeGrey, MT)
	cyl(g, "Pipe_Air", 26, 0.2, V3(-5.0, 8.8, 3.5), AXIS_X, C.PipeGrey, MT)
	for i = 0, 7 do
		box(g, "Pipe_Bracket", V3(0.08, 0.5, 0.35), V3(-18.0 + i * 3.0, 5.7, 3.62), C.DarkSteel, MT)
	end
	for i = 0, 5 do
		box(g, "Pipe_Bracket", V3(0.08, 0.35, 0.3), V3(-18.0 + i * 3.6, 7.0, -3.65), C.DarkSteel, MT)
	end

	pipe(g, "Pipe_WaterBranch", V3(-12.0, 5.7, 3.45), V3(-11.0, 6.5, 1.7), 0.22, C.Pipe, MT)
	pipe(g, "Pipe_WaterBranch", V3(-6.0, 5.7, 3.45), V3(-6.0, 6.3, 1.6), 0.22, C.Pipe, MT)
	pipe(g, "Pipe_FuelBranch", V3(-10.0, 7.0, -3.5), V3(-9.5, 7.8, -1.5), 0.18, C.PipeGrey, MT)
	pipe(g, "Pipe_FuelBranch", V3(-4.0, 7.0, -3.5), V3(-4.0, 7.9, -1.5), 0.18, C.PipeGrey, MT)

	for _, s in ipairs(SIDES) do
		box(g, "CableTray", V3(30, 0.08, 0.7), V3(-4.5, 10.12, s * 2.9), C.DarkSteel, MT)
		for _, dz in ipairs({ -0.35, 0.35 }) do
			box(g, "CableTray_Flange", V3(30, 0.15, 0.05), V3(-4.5, 10.17, s * 2.9 + dz), C.DarkSteel, MT)
		end
		for k = 0, 3 do
			cyl(g, "Cable", 30, 0.12, V3(-4.5, 10.22, s * 2.9 - 0.25 + k * 0.17), AXIS_X, C.Cable, SP)
		end
		for i = 0, 7 do
			box(g, "CableTray_Hanger", V3(0.06, 0.2, 0.7), V3(-18.0 + i * 4.0, 10.2, s * 2.9), C.DarkSteel, MT)
		end
	end

	pipe(g, "CableDrop", V3(1.6, 8.7, 0.3), V3(1.6, 10.1, 2.7), 0.14, C.Cable, SP)
	pipe(g, "CableDrop", V3(6.0, 7.1, 0), V3(6.0, 10.1, -2.7), 0.14, C.Cable, SP)
	pipe(g, "CableDrop", V3(5.0, 6.4, -3.25), V3(5.0, 10.1, -2.8), 0.12, C.Cable, SP)
	pipe(g, "CableDrop", V3(10.5, 9.15, 3.0), V3(10.5, 10.1, 2.8), 0.14, C.Cable, SP)
end

----------------------------------------------------------------------
-- DETAIL AKHIR RUANG MESIN: pagar, lampu, panel akses, pemadam, plakat
----------------------------------------------------------------------
local function buildEngineDetails()
	local g = F.Engine

	for _, s in ipairs(SIDES) do
		for i = 0, 6 do
			cyl(g, "Guard_Post", 1.3, 0.1, V3(-13.0 + i * 2.0, 5.5, s * 2.1), AXIS_Y, C.Amber, MT)
		end
		cyl(g, "Guard_RailTop", 12.2, 0.1, V3(-7.0, 6.15, s * 2.1), AXIS_X, C.Amber, MT)
		cyl(g, "Guard_RailMid", 12.2, 0.08, V3(-7.0, 5.6, s * 2.1), AXIS_X, C.Amber, MT)
	end

	for _, x in ipairs({ -20.6, -9.6, -4.4, 4.8, 9.4 }) do
		cyl(g, "ER_Lamp_Base", 0.12, 0.55, V3(x, 10.24, 0), AXIS_Y, C.Steel, MT)
		local bulb = cyl(g, "ER_Lamp_Bulb", 0.18, 0.4, V3(x, 10.09, 0), AXIS_Y, C.Cream, NEON)
	end

	for _, s in ipairs(SIDES) do
		for _, x in ipairs({ -19.0, -10.0, 0.0, 6.0 }) do
			box(g, "AccessPanel", V3(1.6, 1.2, 0.05), V3(x, 7.9, s * 3.825), C.Cream, SP)
			box(g, "AccessPanel_Handle", V3(0.3, 0.1, 0.08), V3(x + 0.5, 7.9, s * 3.78), C.Steel, MT)
			for _, bx in ipairs({ -0.7, 0.7 }) do
				for _, by in ipairs({ -0.5, 0.5 }) do
					cyl(g, "AccessPanel_Bolt", 0.04, 0.1, V3(x + bx, 7.9 + by, s * 3.795), AXIS_Z, C.Steel, MT)
				end
			end
		end
	end

	cyl(g, "ER_Extinguisher_Body", 1.5, 0.5, V3(12.3, 5.6, -3.4), AXIS_Y, C.Red, SP)
	cyl(g, "ER_Extinguisher_Neck", 0.2, 0.2, V3(12.3, 6.45, -3.4), AXIS_Y, C.Steel, MT)
	box(g, "ER_Extinguisher_Handle", V3(0.3, 0.08, 0.1), V3(12.3, 6.6, -3.4), C.Black, MT)
	for _, by in ipairs({ 5.2, 6.1 }) do
		cyl(g, "ER_Extinguisher_Strap", 0.08, 0.56, V3(12.3, by, -3.4), AXIS_Y, C.Steel, MT)
	end

	box(g, "Sign_Warning", V3(0.04, 0.6, 1.0), V3(K.ER_X0 + 0.04, 8.6, 0), C.Amber, SP)
	box(g, "Sign_WarningBorder", V3(0.03, 0.7, 1.1), V3(K.ER_X0 + 0.035, 8.6, 0), C.Black, SP)
	box(g, "Sign_Door", V3(0.04, 0.4, 0.9), V3(14.1, 9.6, -1.0), C.Red, SP)
end

----------------------------------------------------------------------
-- SUSUN SEMUA PART CC201 (eksterior + interior opsional)
----------------------------------------------------------------------
local function generateAll(withInterior)
	SPECS = {}
	buildFrameAndDeck()
	buildUndercarriage()
	local bogies = group(model, "Bogies")
	buildBogie(bogies, 14.0, "Bogie_Front")
	buildBogie(bogies, -14.0, "Bogie_Rear")
	buildHood()
	buildCab()
	buildRoofDetails()
	buildEnd(1)
	buildEnd(-1)
	if withInterior then
		buildCabFloor()
		buildCabCeiling()
		buildCabWalls()
		buildBulkhead()
		buildDashboard()
		buildControls()
		buildSeats()
		buildCabDetails()
		buildEngineShell()
		buildEngine()
		buildGenerator()
		buildRadiator()
		buildAuxiliary()
		buildPiping()
		buildEngineDetails()
	end
end

----------------------------------------------------------------------
-- LAPISAN F3X (memanggil ServerEndpoint milik Building Tools)
----------------------------------------------------------------------
local F3X = { endpoint = nil, builtModel = nil, builtParts = nil, busy = false }

function F3X.call(...)
	local args = table.pack(...)
	return pcall(function()
		return F3X.endpoint:InvokeServer(table.unpack(args, 1, args.n))
	end)
end

function F3X.find()
	local roots = {}
	if LocalPlayer.Character then
		table.insert(roots, LocalPlayer.Character)
	end
	local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
	if bp then
		table.insert(roots, bp)
	end
	for _, r in ipairs(roots) do
		for _, d in ipairs(r:GetDescendants()) do
			if d:IsA("RemoteFunction") and d.Name == "ServerEndpoint" then
				return d, d:FindFirstAncestorOfClass("Tool")
			end
		end
	end
	return nil, nil
end
-- POTONGAN 8/9  (tempel berurutan jadi SATU script; jangan ubah isinya)
function F3X.equip(tool)
	local char = LocalPlayer.Character
	if tool and char and tool.Parent ~= char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			pcall(function()
				hum:EquipTool(tool)
			end)
			task.wait(0.3)
		end
	end
end

-- posisi model: DISTANCE_AHEAD di depan karakter, sisi samping menghadap kamu
function F3X.rootCF()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end
	local look = hrp.CFrame.LookVector
	local flat = V3(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then
		flat = V3(0, 0, -1)
	end
	flat = flat.Unit
	local right = V3(-flat.Z, 0, flat.X)
	local target = hrp.Position + flat * DISTANCE_AHEAD
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local hit = Workspace:Raycast(V3(target.X, target.Y + 60, target.Z), V3(0, -300, 0), params)
	local gy = hit and hit.Position.Y or (hrp.Position.Y - 3)
	return CFrame.fromMatrix(V3(target.X, gy, target.Z), right, V3(0, 1, 0))
end

-- buat `count` part sejenis: 1 CreatePart lalu digandakan dengan Clone
function F3X.create(kind, count, origin, tick)
	local ok, first = F3X.call("CreatePart", kind, origin, Workspace)
	if not ok or typeof(first) ~= "Instance" then
		return nil, "CreatePart '" .. kind .. "' gagal: " .. tostring(first)
	end
	local list = { first }
	tick(1)

	if USE_CLONE then
		while #list < count do
			local take = math.min(#list, count - #list, CLONE_CHUNK)
			local chunk = table.move(list, 1, take, 1, {})
			local okc, res = F3X.call("Clone", chunk, Workspace)
			if not (okc and type(res) == "table" and #res > 0) then
				break
			end
			local added = 0
			for _, p in ipairs(res) do
				if typeof(p) == "Instance" and #list < count then
					list[#list + 1] = p
					added += 1
				end
			end
			tick(added)
			if added == 0 then
				break
			end
		end
	end

	if #list < count then
		-- cadangan: buat satu per satu (8 paralel)
		local pending = count - #list
		local running = 0
		local failed = false
		for _ = 1, math.min(8, pending) do
			running += 1
			task.spawn(function()
				while pending > 0 and not failed do
					pending -= 1
					local okp, res = F3X.call("CreatePart", kind, origin, Workspace)
					if okp and typeof(res) == "Instance" then
						list[#list + 1] = res
						tick(1)
					else
						failed = true
					end
				end
				running -= 1
			end)
		end
		while running > 0 do
			task.wait(0.05)
		end
	end

	if #list < count then
		return nil, string.format("Hanya %d dari %d part '%s' berhasil dibuat.", #list, count, kind)
	end
	return list
end

-- kirim perubahan dalam batch; progress dari p0 ke p1
function F3X.sync(action, changes, ui, p0, p1)
	local n = #changes
	for i = 1, n, BATCH_SIZE do
		local last = math.min(i + BATCH_SIZE - 1, n)
		local slice = table.move(changes, i, last, 1, {})
		local ok, err = F3X.call(action, slice)
		if not ok then
			warn("[CC201] " .. action .. " gagal: " .. tostring(err))
			return false
		end
		ui.progress(p0 + (p1 - p0) * last / n)
		task.wait(BATCH_DELAY)
	end
	return true
end

local REVEAL_NAMES = {
	["Cab_Upper_White"] = true,
	["Cab_Lower_Red"] = true,
	["Cab_Roof"] = true,
	["Cab_Roof_RoundFront"] = true,
	["Cab_Roof_RoundRear"] = true,
	["Hood_Upper_White"] = true,
	["Hood_Lower_Red"] = true,
	["Hood_Roof_Plate"] = true,
	["Windshield_Glass"] = true,
	["Cab_RearSideWindow_Glass"] = true,
	["Cab_DoorWindow_Glass"] = true,
	["Cab_FrontSideWindow_Glass"] = true,
	["Cab_RearGlass_Glass"] = true,
}

function F3X.build(options, ui)
	ui.progress(0)
	ui.status("Mencari Building Tools (F3X)...")
	local ep, tool = F3X.find()
	if not ep then
		ui.status("Building Tools (F3X) tidak ditemukan di Backpack/karakter. Ambil tool-nya dulu dari game.")
		return
	end
	F3X.endpoint = ep
	F3X.equip(tool)

	ui.status("Menyusun data model CC201...")
	generateAll(options.interior)
	if options.reveal then
		for _, s in ipairs(SPECS) do
			if REVEAL_NAMES[s.Name] then
				s.Transparency = REVEAL_TRANSPARENCY
			end
		end
	end
	local total = #SPECS

	local root = F3X.rootCF()
	if not root then
		ui.status("Karakter belum siap.")
		return
	end

	local counts = { Normal = 0, Cylinder = 0, Ball = 0 }
	for _, s in ipairs(SPECS) do
		counts[s.Kind] += 1
	end

	-- 1) buat part (0% - 50%)
	local origin = root * CF(0, 25, 0)
	local pools = {}
	local created = 0
	local function tick(n)
		created += n
		ui.progress(0.5 * created / total)
	end
	for _, kind in ipairs({ "Normal", "Cylinder", "Ball" }) do
		if counts[kind] > 0 then
			ui.status(string.format("Membuat %d part '%s'...", counts[kind], kind))
			local list, err = F3X.create(kind, counts[kind], origin, tick)
			if not list then
				ui.status(err)
				return
			end
			pools[kind] = list
		end
	end

	local nextIdx = { Normal = 0, Cylinder = 0, Ball = 0 }
	local allParts = {}
	for _, s in ipairs(SPECS) do
		nextIdx[s.Kind] += 1
		s.Part = pools[s.Kind][nextIdx[s.Kind]]
		allParts[#allParts + 1] = s.Part
	end
	F3X.builtParts = allParts

	-- 2) ukuran + posisi, warna, material, anchor, collision (50% - 95%)
	local resize, color, material, anchor, collide = {}, {}, {}, {}, {}
	for i, s in ipairs(SPECS) do
		resize[i] = { Part = s.Part, CFrame = root * s.CF, Size = s.Size }
		color[i] = { Part = s.Part, Color = s.Color, UnionColoring = false }
		material[i] = { Part = s.Part, Material = s.Material, Transparency = s.Transparency, Reflectance = s.Reflectance }
		anchor[i] = { Part = s.Part, Anchored = true }
		collide[i] = { Part = s.Part, CanCollide = s.Collide }
	end

	ui.status("Mengatur ukuran & posisi...")
	if not F3X.sync("SyncResize", resize, ui, 0.50, 0.68) then
		ui.status("SyncResize gagal. Versi F3X di game ini mungkin berbeda. Cek Output/console.")
		return
	end
	ui.status("Mewarnai...")
	F3X.sync("SyncColor", color, ui, 0.68, 0.78)
	ui.status("Mengatur material...")
	F3X.sync("SyncMaterial", material, ui, 0.78, 0.86)
	ui.status("Mengunci (anchor) & collision...")
	F3X.sync("SyncAnchor", anchor, ui, 0.86, 0.91)
	F3X.sync("SyncCollision", collide, ui, 0.91, 0.95)

	-- 3) nama part (opsional)
	if NAME_PARTS then
		local byName, names = {}, {}
		for _, s in ipairs(SPECS) do
			if not byName[s.Name] then
				byName[s.Name] = {}
				names[#names + 1] = s.Name
			end
			table.insert(byName[s.Name], s.Part)
		end
		for i, nm in ipairs(names) do
			ui.status(string.format("Memberi nama part (%d/%d)...", i, #names))
			F3X.call("SetName", byName[nm], nm)
		end
	end

	-- 4) kelompokkan per bagian lalu jadi satu Model (95% - 100%)
	ui.status("Mengelompokkan menjadi Model...")
	local byGroup, order = {}, {}
	for _, s in ipairs(SPECS) do
		local key = topGroup(s.Group).Name
		if not byGroup[key] then
			byGroup[key] = {}
			order[#order + 1] = key
		end
		table.insert(byGroup[key], s.Part)
	end
	local groups = {}
	for _, key in ipairs(order) do
		local okg, grp = F3X.call("CreateGroup", "Model", Workspace, byGroup[key])
		if okg and typeof(grp) == "Instance" then
			F3X.call("SetName", { grp }, key)
			groups[#groups + 1] = grp
		end
	end
	F3X.builtModel = nil
	if #groups > 0 then
		local okm, finalModel = F3X.call("CreateGroup", "Model", Workspace, groups)
		if okm and typeof(finalModel) == "Instance" then
			F3X.call("SetName", { finalModel }, MODEL_NAME)
			F3X.builtModel = finalModel
		end
	end
	ui.progress(1)
	ui.status(string.format("Selesai! %d part dibuat (%s).", total, F3X.builtModel and "jadi 1 Model" or "part dibiarkan lepas, grouping gagal"))
end

function F3X.remove(ui)
	if not F3X.endpoint then
		local ep, tool = F3X.find()
		if not ep then
			ui.status("Building Tools (F3X) tidak ditemukan.")
			return
		end
		F3X.endpoint = ep
		F3X.equip(tool)
	end
	if F3X.builtModel and F3X.builtModel.Parent then
		ui.status("Menghapus model...")
		local ok, err = F3X.call("Remove", { F3X.builtModel })
		if not ok then
			ui.status("Hapus gagal: " .. tostring(err))
			return
		end
	elseif F3X.builtParts then
		ui.status("Menghapus part...")
		for i = 1, #F3X.builtParts, 200 do
			local slice = table.move(F3X.builtParts, i, math.min(i + 199, #F3X.builtParts), 1, {})
			F3X.call("Remove", slice)
			task.wait(BATCH_DELAY)
		end
	else
		ui.status("Belum ada model hasil build dari sesi ini.")
		return
	end
	F3X.builtModel, F3X.builtParts = nil, nil
	ui.progress(0)
	ui.status("Model dihapus.")
end
-- POTONGAN 9/9  (tempel berurutan jadi SATU script; jangan ubah isinya)
----------------------------------------------------------------------
-- UI (bisa digeser, cocok untuk layar sentuh)
----------------------------------------------------------------------
local function main()
	local UserInputService = game:GetService("UserInputService")
	local options = { interior = true, reveal = false }

	local guiParent
	do
		local ok, res = pcall(function()
			if typeof(gethui) == "function" then
				return gethui()
			end
			return game:GetService("CoreGui")
		end)
		guiParent = (ok and res) or LocalPlayer:WaitForChild("PlayerGui")
	end
	pcall(function()
		for _, g in ipairs(guiParent:GetChildren()) do
			if g.Name == "CC201_F3X_Builder" then
				g:Destroy()
			end
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "CC201_F3X_Builder"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local okParent = pcall(function()
		gui.Parent = guiParent
	end)
	if not okParent or not gui.Parent then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	local function corner(obj, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, r)
		c.Parent = obj
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 270, 0, 316)
	frame.Position = UDim2.new(0, 20, 0, 90)
	frame.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	corner(frame, 12)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 34)
	title.BackgroundColor3 = Color3.fromRGB(196, 28, 36)
	title.BorderSizePixel = 0
	title.Text = "  CC201 Auto Builder (F3X)"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame
	corner(title, 12)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 26)
	closeBtn.Position = UDim2.new(1, -34, 0, 4)
	closeBtn.BackgroundColor3 = Color3.fromRGB(120, 16, 22)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.Parent = title
	corner(closeBtn, 8)

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -20, 0, 64)
	statusLabel.Position = UDim2.new(0, 10, 0, 42)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Pegang Building Tools (F3X), lalu tekan Build otomatis."
	statusLabel.TextColor3 = Color3.fromRGB(220, 224, 230)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 13
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextYAlignment = Enum.TextYAlignment.Top
	statusLabel.Parent = frame

	local barBack = Instance.new("Frame")
	barBack.Size = UDim2.new(1, -20, 0, 10)
	barBack.Position = UDim2.new(0, 10, 0, 112)
	barBack.BackgroundColor3 = Color3.fromRGB(50, 54, 64)
	barBack.BorderSizePixel = 0
	barBack.Parent = frame
	corner(barBack, 5)

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(50, 200, 90)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBack
	corner(barFill, 5)

	local function newButton(text, y, color)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, -20, 0, 38)
		b.Position = UDim2.new(0, 10, 0, y)
		b.BackgroundColor3 = color
		b.Text = text
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 14
		b.Parent = frame
		corner(b, 8)
		return b
	end

	local buildBtn = newButton("Build otomatis", 132, Color3.fromRGB(40, 140, 70))
	local interiorBtn = newButton("Interior: ON", 178, Color3.fromRGB(50, 90, 160))
	local revealBtn = newButton("Tembus pandang: OFF", 220, Color3.fromRGB(70, 74, 86))
	local deleteBtn = newButton("Hapus model", 262, Color3.fromRGB(150, 40, 40))

	local ui = {}
	function ui.status(text)
		statusLabel.Text = text
	end
	function ui.progress(f)
		barFill.Size = UDim2.new(math.clamp(f, 0, 1), 0, 1, 0)
	end

	-- geser jendela lewat judul (mouse & sentuh)
	local dragging, dragStart, startPos = false, nil, nil
	title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	interiorBtn.MouseButton1Click:Connect(function()
		options.interior = not options.interior
		interiorBtn.Text = options.interior and "Interior: ON" or "Interior: OFF"
	end)

	revealBtn.MouseButton1Click:Connect(function()
		options.reveal = not options.reveal
		revealBtn.Text = options.reveal and "Tembus pandang: ON" or "Tembus pandang: OFF"
		revealBtn.BackgroundColor3 = options.reveal and Color3.fromRGB(50, 90, 160) or Color3.fromRGB(70, 74, 86)
	end)

	local function guarded(fn)
		if F3X.busy then
			ui.status("Masih bekerja, tunggu sampai selesai.")
			return
		end
		F3X.busy = true
		task.spawn(function()
			local ok, err = pcall(fn)
			if not ok then
				ui.status("Error: " .. tostring(err))
				warn("[CC201] " .. tostring(err))
			end
			F3X.busy = false
		end)
	end

	buildBtn.MouseButton1Click:Connect(function()
		guarded(function()
			F3X.build(options, ui)
		end)
	end)

	deleteBtn.MouseButton1Click:Connect(function()
		guarded(function()
			F3X.remove(ui)
		end)
	end)
end

main()
