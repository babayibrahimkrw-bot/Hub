-- ==========================================
-- LINA KEY SYSTEM (ENGLISH VERSION)
-- ==========================================
local KEY_SAH = "TheBest-Hub-LethalApe"
-- PASTIKAN URL INI MENUJU KE FILE PANEL UTAMA LU
local URL_SCRIPT = "https://raw.githubusercontent.com/babayibrahimkrw-bot/Hub/refs/heads/main/LINA.lua"

local keyGui = Instance.new("ScreenGui")
keyGui.Name = "LINA_KeySystem"
keyGui.ResetOnSpawn = false
keyGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui")

local keyFrame = Instance.new("Frame", keyGui)
keyFrame.Size = UDim2.fromOffset(280, 180)
keyFrame.Position = UDim2.new(0.5, -140, 0.5, -90)
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

local box = Instance.new("TextBox", keyFrame)
box.Size = UDim2.fromOffset(240, 34)
box.Position = UDim2.new(0.5, -120, 0, 60)
box.BackgroundColor3 = Color3.fromRGB(34, 34, 48)
box.Text = ""
box.PlaceholderText = "Enter Key here..."
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.Font = Enum.Font.GothamMedium
box.TextSize = 13
box.ClearTextOnFocus = false

local btn = Instance.new("TextButton", keyFrame)
btn.Size = UDim2.fromOffset(240, 34)
btn.Position = UDim2.new(0.5, -120, 0, 110)
btn.BackgroundColor3 = Color3.fromRGB(235, 70, 50)
btn.Text = "CHECK KEY"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14

local status = Instance.new("TextLabel", keyFrame)
status.Size = UDim2.new(1, 0, 0, 20)
status.Position = UDim2.new(0, 0, 0, 155)
status.BackgroundTransparency = 1
status.Text = "Don't have a key? Contact Admin!"
status.TextColor3 = Color3.fromRGB(160, 165, 180)
status.Font = Enum.Font.GothamMedium
status.TextSize = 11

btn.MouseButton1Click:Connect(function()
	if box.Text == KEY_SAH then
		btn.Text = "SUCCESS!"
		btn.BackgroundColor3 = Color3.fromRGB(60, 255, 120)
		task.wait(1)
		keyGui:Destroy() 
		
		-- Load Main Panel
		loadstring(game:HttpGet(URL_SCRIPT))()
		
	else
		btn.Text = "WRONG KEY!"
		btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		box.Text = ""
		task.wait(1)
		btn.Text = "CHECK KEY"
		btn.BackgroundColor3 = Color3.fromRGB(235, 70, 50)
	end
end)
