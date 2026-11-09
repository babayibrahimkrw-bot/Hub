-- ==========================================
-- LINA KEY SYSTEM (SIMPLE GET KEY)
-- ==========================================
local KEY_SAH = "TheBest-Hub-LethalApe"
local URL_SCRIPT = "https://raw.githubusercontent.com/babayibrahimkrw-bot/Hub/refs/heads/main/LINA.lua"

-- Link GetKey lu udah gw masukin di sini bre
local LINK_GET_KEY = "https://raw.githubusercontent.com/babayibrahimkrw-bot/Hub/refs/heads/main/GetKey" 

local keyGui = Instance.new("ScreenGui")
keyGui.Name = "LINA_KeySystem"
keyGui.ResetOnSpawn = false
keyGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui")

local keyFrame = Instance.new("Frame", keyGui)
keyFrame.Size = UDim2.fromOffset(300, 210) 
keyFrame.Position = UDim2.new(0.5, -150, 0.5, -105)
keyFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
keyFrame.BorderSizePixel = 0
Instance.new("UICorner", keyFrame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", keyFrame)
stroke.Color = Color3.fromRGB(235, 70, 50)
stroke.Thickness = 1.5

local title = Instance.new("TextLabel", keyFrame)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "LINA v7.2 - KEY SYSTEM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16

-- KOTAK INPUT KEY
local box = Instance.new("TextBox", keyFrame)
box.Size = UDim2.fromOffset(260, 34)
box.Position = UDim2.new(0.5, -130, 0, 50)
box.BackgroundColor3 = Color3.fromRGB(34, 34, 48)
box.Text = ""
box.PlaceholderText = "Masukkan Key di sini..."
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.Font = Enum.Font.GothamMedium
box.TextSize = 13
box.ClearTextOnFocus = false

-- TOMBOL CEK KEY
local btn = Instance.new("TextButton", keyFrame)
btn.Size = UDim2.fromOffset(260, 34)
btn.Position = UDim2.new(0.5, -130, 0, 95)
btn.BackgroundColor3 = Color3.fromRGB(235, 70, 50) 
btn.Text = "CHECK KEY"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14

-- TOMBOL GET KEY (Bawah Check Key)
local getBtn = Instance.new("TextButton", keyFrame)
getBtn.Size = UDim2.fromOffset(260, 34)
getBtn.Position = UDim2.new(0.5, -130, 0, 140)
getBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 235) 
getBtn.Text = "GET KEY (Buka Link)"
getBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
getBtn.Font = Enum.Font.GothamBold
getBtn.TextSize = 14

local status = Instance.new("TextLabel", keyFrame)
status.Size = UDim2.new(1, 0, 0, 20)
status.Position = UDim2.new(0, 0, 0, 180)
status.BackgroundTransparency = 1
status.Text = "Copy link, buka browser, dapetin Key-nya!"
status.TextColor3 = Color3.fromRGB(160, 165, 180)
status.Font = Enum.Font.GothamMedium
status.TextSize = 11

-- FUNGSI GET KEY (Copy Link)
getBtn.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard(LINK_GET_KEY)
		getBtn.Text = "LINK DI-COPY! BUKA BROWSER"
		getBtn.BackgroundColor3 = Color3.fromRGB(60, 255, 120) 
		task.wait(2.5)
		getBtn.Text = "GET KEY (Buka Link)"
		getBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 235) 
	else
		getBtn.Text = "Executor ga support copy!"
		task.wait(2)
		getBtn.Text = "GET KEY (Buka Link)"
	end
end)

-- FUNGSI CEK KEY
btn.MouseButton1Click:Connect(function()
	if box.Text == KEY_SAH then
		btn.Text = "SUCCESS!"
		btn.BackgroundColor3 = Color3.fromRGB(60, 255, 120)
		task.wait(1)
		keyGui:Destroy() 
		
		-- Load Main Panel
		loadstring(game:HttpGet(URL_SCRIPT))()
		
	else
		btn.Text = "KEY SALAH!"
		btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		box.Text = ""
		task.wait(1)
		btn.Text = "CHECK KEY"
		btn.BackgroundColor3 = Color3.fromRGB(235, 70, 50)
	end
end)
