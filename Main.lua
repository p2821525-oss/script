-- ==========================================
-- Phupha💀💀 Hub v14.1 (Fixed Clean Core)
-- แก้จาก v14.0: ตัวแปรที่ไม่ได้ประกาศ, Unload จริง, restore ค่าโลกทั้งหมด,
-- ESP/Animation/Fly/Swim/Lighting และอื่นๆ (ดูรายการท้ายไฟล์)
-- ==========================================

local env = (getgenv and getgenv()) or _G

-- Guard: โหลดซ้ำ = Unload ของเก่าก่อน
if env.PhuphaHubV14 then
pcall(env.PhuphaHubV14.Unload)
env.PhuphaHubV14 = nil
end

local okLoad, Rayfield = pcall(function()
return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not okLoad or not Rayfield then
warn("[Phupha Hub] โหลด Rayfield ไม่สำเร็จ: " .. tostring(Rayfield))
return
end

local Window = Rayfield:CreateWindow({
Name = "Phupha💀💀 [MATRIX HUB v14.1]",
LoadingTitle = "Phupha💀💀 Fixed Clean Core",
LoadingSubtitle = "กำลังโหลดระบบสถาปัตยกรรมและ Global Cleanup...",
ConfigurationSaving = { Enabled = true, FolderName = "PhuphaHubConfigs", FileName = "PhuphaMatrixv14" },
KeySystem = false,
Theme = {
TextColor = Color3.fromRGB(0, 255, 100),
Background = Color3.fromRGB(8, 10, 8),
Topbar = Color3.fromRGB(12, 18, 12),
Shadow = Color3.fromRGB(0, 0, 0),
NotificationBackground = Color3.fromRGB(12, 18, 12),
NotificationActionsBackground = Color3.fromRGB(20, 35, 20),
TabBackground = Color3.fromRGB(15, 22, 15),
TabStroke = Color3.fromRGB(0, 255, 60),
TabBackgroundSelected = Color3.fromRGB(0, 200, 50),
TabTextColor = Color3.fromRGB(150, 255, 180),
SelectedTabTextColor = Color3.fromRGB(0, 0, 0),
ElementBackground = Color3.fromRGB(18, 25, 18),
ElementBackgroundHover = Color3.fromRGB(25, 38, 25),
SecondaryElementBackground = Color3.fromRGB(12, 16, 12),
ElementStroke = Color3.fromRGB(0, 255, 80),
SecondaryElementStroke = Color3.fromRGB(0, 150, 40),
SliderBackground = Color3.fromRGB(25, 35, 25),
SliderProgress = Color3.fromRGB(0, 255, 100),
SliderStroke = Color3.fromRGB(0, 200, 80),
ToggleBackground = Color3.fromRGB(20, 30, 20),
ToggleEnabled = Color3.fromRGB(0, 255, 100),
ToggleDisabled = Color3.fromRGB(60, 75, 60),
ToggleEnabledStroke = Color3.fromRGB(0, 255, 100),
ToggleDisabledStroke = Color3.fromRGB(40, 50, 40),
ToggleEnabledOuterStroke = Color3.fromRGB(0, 180, 70),
ToggleDisabledOuterStroke = Color3.fromRGB(30, 40, 30),
DropdownSelected = Color3.fromRGB(20, 35, 20),
DropdownUnselected = Color3.fromRGB(15, 22, 15),
InputBackground = Color3.fromRGB(15, 20, 15),
InputStroke = Color3.fromRGB(0, 255, 80),
PlaceholderColor = Color3.fromRGB(80, 150, 100)
}
})

-- Services & Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- MATRIX CORE SYSTEM (Unified Management)
-- ==========================================
local Core = {
Connections = {},
Instances = {},
Tasks = {},
Restorers = {},   -- ฟังก์ชันคืนค่าโลก (เรียกก่อนล้าง connection)
Shutdown = false,
}

function Core:RegisterConnection(name, connection)
if self.Shutdown then
if connection then pcall(function() connection:Disconnect() end) end
return false
end
if self.Connections[name] then
pcall(function() self.Connections[name]:Disconnect() end)
end
self.Connections[name] = connection
return true
end

function Core:ClearConnection(name)
local conn = self.Connections[name]
self.Connections[name] = nil
if conn then pcall(function() conn:Disconnect() end) end
end

function Core:RegisterInstance(name, object)
if self.Shutdown then
if object then pcall(function() object:Destroy() end) end
return false
end
if self.Instances[name] and self.Instances[name] ~= object then
pcall(function() self.Instances[name]:Destroy() end)
end
self.Instances[name] = object
return true
end

function Core:RegisterTask(name, thread)
if self.Shutdown then
if thread then pcall(task.cancel, thread) end
return false
end
if self.Tasks[name] then pcall(task.cancel, self.Tasks[name]) end
self.Tasks[name] = thread
return true
end

function Core:CancelTask(name)
local thread = self.Tasks[name]
self.Tasks[name] = nil
if thread then pcall(task.cancel, thread) end
end

function Core:OnCleanup(name, fn)
self.Restorers[name] = fn
end

function Core:Cleanup()
if self.Shutdown then return end
self.Shutdown = true

-- 1) คืนค่าโลก/ตัวละคร ก่อน
for name, fn in pairs(self.Restorers) do
local ok, err = pcall(fn)
if not ok then warn("[Phupha Hub] restorer '" .. name .. "' error: " .. tostring(err)) end
end
table.clear(self.Restorers)

-- 2) connections
for name, conn in pairs(self.Connections) do
pcall(function() conn:Disconnect() end)
self.Connections[name] = nil
end
-- 3) tasks
for name, thread in pairs(self.Tasks) do
pcall(task.cancel, thread)
self.Tasks[name] = nil
end
-- 4) instances
for name, obj in pairs(self.Instances) do
pcall(function() obj:Destroy() end)
self.Instances[name] = nil
end
print("[Phupha Hub] Global Cleanup Executed Successfully.")
end

-- ==========================================
-- Helpers
-- ==========================================
local function weak()
return setmetatable({}, { __mode = "k" })
end

local function GuiParent()
local ok, p = pcall(function()
return (gethui and gethui()) or game:GetService("CoreGui")
end)
if ok and p then return p end
return LocalPlayer:WaitForChild("PlayerGui")
end

local function getChar() return LocalPlayer.Character end
local function getHum()
local c = LocalPlayer.Character
return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
local c = LocalPlayer.Character
return c and c:FindFirstChild("HumanoidRootPart")
end

local function ForEachChunked(list, fn, cancelled)
for i, v in ipairs(list) do
if cancelled and cancelled() then return end
fn(v)
if i % 500 == 0 then task.wait() end
end
end

local toolCounter = 0
local function TrackTool(tool)
toolCounter += 1
Core:RegisterInstance("Tool_" .. toolCounter, tool)
end

local function Unload()
Core:Cleanup()
pcall(function() Rayfield:Destroy() end)
if env.PhuphaHubV14 then env.PhuphaHubV14 = nil end
end
env.PhuphaHubV14 = { Unload = Unload }

-- ==========================================
-- Hub Variables & Folders
-- ==========================================
local WalkSpeedValue, JumpPowerValue, FlySpeedValue = 16, 50, 50
local Flying, Noclip, InfJump = false, false, false
local ESPEnabled, NameESPEnabled = false, false
local SwimEnabled = false
local ClickTPEnabled = false
local AuraEnabled = false
local SpinSpeed, Spinning = 20, false
-- (แก้) ตัวแปร Aimbot ที่เดิมไม่ได้ประกาศ → เป็น nil/global รั่ว
local AimbotEnabled, ShowCircle, CircleRadius, AimbotStrength = false, true, 100, 5

local HubFolder = workspace:FindFirstChild("PhuphaHubObjects")
if HubFolder then HubFolder:ClearAllChildren() else
HubFolder = Instance.new("Folder")
HubFolder.Name = "PhuphaHubObjects"
HubFolder.Parent = workspace
end
Core:RegisterInstance("HubFolder", HubFolder)

local guiParent = GuiParent()

-- FOV Circle GUI
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "PhuphaFOVCircle"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true -- (แก้) ให้ศูนย์วงกลมตรงกับ ViewportSize/2 ที่ aimbot ใช้
FOVGui.Parent = guiParent
Core:RegisterInstance("FOVGui", FOVGui)

local FOVFrame = Instance.new("Frame")
FOVFrame.Name = "Circle"
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.Size = UDim2.new(0, CircleRadius * 2, 0, CircleRadius * 2)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = false
FOVFrame.Parent = FOVGui

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 100)
UIStroke.Thickness = 2
UIStroke.Parent = FOVFrame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = FOVFrame

-- Mobile Toggle Button
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "PhuphaToggleUI"
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = guiParent
Core:RegisterInstance("ToggleGui", ToggleGui)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 70, 0, 70)
ToggleBtn.Position = UDim2.new(0.03, 0, 0.2, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(8, 12, 8)
ToggleBtn.BorderColor3 = Color3.fromRGB(0, 255, 100)
ToggleBtn.BorderSizePixel = 2
ToggleBtn.Text = "Phupha💀"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Parent = ToggleGui

local UICornerBtn = Instance.new("UICorner")
UICornerBtn.CornerRadius = UDim.new(1, 0)
UICornerBtn.Parent = ToggleBtn

local function ToggleRayfieldUI()
if Rayfield.SetVisibility and Rayfield.IsVisible then
Rayfield:SetVisibility(not Rayfield:IsVisible())
return
end
-- fallback: หาใน gethui และ CoreGui
for _, parent in ipairs({ guiParent, game:GetService("CoreGui") }) do
local ui = parent:FindFirstChild("Rayfield")
if ui then ui.Enabled = not ui.Enabled return end
end
end
Core:RegisterConnection("ToggleBtnClick", ToggleBtn.MouseButton1Click:Connect(ToggleRayfieldUI))

-- ==========================================
-- Lighting Manager (FPS Boost <-> FullBright ใช้ร่วมกันได้)
-- ==========================================
local LightingState = {
original = nil,
owners = { FPSBoost = false, FullBright = false },
}

local function RecomputeLighting()
local o = LightingState.original
if not o then return end
local owners = LightingState.owners
if owners.FullBright then
Lighting.Brightness = 2
Lighting.ClockTime = 14
Lighting.GlobalShadows = false
Lighting.FogEnd = 100000
elseif owners.FPSBoost then
Lighting.Brightness = o.Brightness
Lighting.ClockTime = o.ClockTime
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
else
Lighting.Brightness = o.Brightness
Lighting.ClockTime = o.ClockTime
Lighting.GlobalShadows = o.GlobalShadows
Lighting.FogEnd = o.FogEnd
LightingState.original = nil
end
end

local function SetLightingOwner(name, val)
local owners = LightingState.owners
if val and not (owners.FPSBoost or owners.FullBright) then
LightingState.original = {
Brightness = Lighting.Brightness,
ClockTime = Lighting.ClockTime,
GlobalShadows = Lighting.GlobalShadows,
FogEnd = Lighting.FogEnd,
}
end
owners[name] = val and true or false
RecomputeLighting()
end

Core:OnCleanup("Lighting", function()
LightingState.owners.FPSBoost = false
LightingState.owners.FullBright = false
RecomputeLighting()
end)

-- ==========================================
-- 1. แท็บเมนูหลัก: การเคลื่อนที่ (Movement & Aura)
-- ==========================================
local MainTab = Window:CreateTab("เมนูหลัก ⚡", 4483362458)

MainTab:CreateSlider({
Name = "ความเร็วในการวิ่ง (WalkSpeed)",
Range = {1, 500},
Increment = 1,
Suffix = " Speed",
CurrentValue = 16,
Flag = "WalkSpeedSlider",
Callback = function(Value)
WalkSpeedValue = Value
local hum = getHum()
if hum then hum.WalkSpeed = WalkSpeedValue end
end,
})

MainTab:CreateSlider({
Name = "พลังกระโดดสูง (JumpPower)",
Range = {1, 500},
Increment = 1,
Suffix = " Jump",
CurrentValue = 50,
Flag = "JumpPowerSlider",
Callback = function(Value)
JumpPowerValue = Value
local hum = getHum()
if hum then
hum.UseJumpPower = true
hum.JumpPower = JumpPowerValue
end
end,
})

MainTab:CreateSection("เอฟเฟกต์ออร่าเดิน (Optimized Aura)")

local function RemoveAura(char)
local hrp = char and char:FindFirstChild("HumanoidRootPart")
local old = hrp and hrp:FindFirstChild("PhuphaAuraParticles")
if old then old:Destroy() end
end

local function UpdateAura(char)
local hrp = char and char:FindFirstChild("HumanoidRootPart")
if not hrp then return end
RemoveAura(char)
if AuraEnabled then
local e = Instance.new("ParticleEmitter")
e.Name = "PhuphaAuraParticles"
e.Color = ColorSequence.new(Color3.fromRGB(0, 255, 100))
e.Size = NumberSequence.new(1, 0)
e.Texture = "rbxassetid://6063452445"
e.Lifetime = NumberRange.new(0.4, 0.8)
e.Rate = 35
e.Speed = NumberRange.new(0, 1)
e.Parent = hrp
end
end
Core:OnCleanup("Aura", function() RemoveAura(getChar()) end)

MainTab:CreateToggle({
Name = "เปิด/ปิด ออร่าเดินเรืองแสง (Walk Aura)",
CurrentValue = false,
Flag = "AuraToggle",
Callback = function(Value)
AuraEnabled = Value
if getChar() then UpdateAura(getChar()) end
end,
})

MainTab:CreateToggle({
Name = "กระโดดกลางอากาศ (Infinite Jump)",
CurrentValue = false,
Flag = "InfJumpToggle",
Callback = function(Value) InfJump = Value end,
})

Core:RegisterConnection("JumpRequest", UserInputService.JumpRequest:Connect(function()
if InfJump then
local hum = getHum()
if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end
end))

local storedCanCollide = weak()

local function RestoreNoclip()
Core:ClearConnection("Noclip")
for part, canCol in pairs(storedCanCollide) do
if part.Parent then part.CanCollide = canCol end
end
table.clear(storedCanCollide)
end
Core:OnCleanup("Noclip", RestoreNoclip)

MainTab:CreateToggle({
Name = "เดินทะลุกำแพง (Noclip)",
CurrentValue = false,
Flag = "NoclipToggle",
Callback = function(Value)
Noclip = Value
if not Noclip then
RestoreNoclip()
else
Core:RegisterConnection("Noclip", RunService.Stepped:Connect(function()
local char = getChar()
if Noclip and char then
for _, part in ipairs(char:GetDescendants()) do
if part:IsA("BasePart") then
if storedCanCollide[part] == nil then
storedCanCollide[part] = part.CanCollide
end
part.CanCollide = false
end
end
end
end))
end
end,
})

Core:RegisterConnection("GlobalStatsLoop", RunService.Heartbeat:Connect(function()
local hum = getHum()
if hum then
if WalkSpeedValue ~= 16 then hum.WalkSpeed = WalkSpeedValue end
if JumpPowerValue ~= 50 then
hum.UseJumpPower = true
hum.JumpPower = JumpPowerValue
end
end
end))

MainTab:CreateSection("ระบบบิน (Fly)")
local BV, BG

-- หยุดเฉพาะ "ฟิสิกส์" (ไม่แตะค่า Flying เพื่อให้ respawn แล้วบินต่อได้)
local function StopFlyPhysics()
if BV then BV:Destroy(); BV = nil end
if BG then BG:Destroy(); BG = nil end
Core:ClearConnection("Fly")
local hum = getHum()
if hum then hum.PlatformStand = false end
end

local function StartFly()
StopFlyPhysics()
local char = getChar()
local hrp = getHRP()
local hum = getHum()
if not char or not hrp or not hum then return end

BG = Instance.new("BodyGyro")
BG.P = 9e4
BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
BG.CFrame = hrp.CFrame
BG.Parent = hrp

BV = Instance.new("BodyVelocity")
BV.Velocity = Vector3.zero
BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
BV.Parent = hrp

hum.PlatformStand = true

Core:RegisterConnection("Fly", RunService.RenderStepped:Connect(function()
local cam = workspace.CurrentCamera
if not Flying or not char.Parent or hum.Health <= 0 or not cam or not BV or not BG then
StopFlyPhysics() -- ตายแล้วหยุดฟิสิกส์ ถ้า Flying ยัง true จะบินต่อหลัง respawn
return
end
local md = hum.MoveDirection
local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
local flatLook = Vector3.new(look.X, 0, look.Z)
local flatRight = Vector3.new(right.X, 0, right.Z)
local vel = Vector3.zero
if md.Magnitude > 0 and flatLook.Magnitude > 0 and flatRight.Magnitude > 0 then
-- แยกทิศเดินเป็นหน้า/ข้าง แล้วใช้เวกเตอร์กล้องจริง (ขึ้น/ลงตามมุมกล้องได้)
vel = look * md:Dot(flatLook.Unit) + right * md:Dot(flatRight.Unit)
end
if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.yAxis end
if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel -= Vector3.yAxis end
if vel.Magnitude > 1 then vel = vel.Unit end
BV.Velocity = vel * FlySpeedValue
BG.CFrame = cam.CFrame
end))
end
Core:OnCleanup("Fly", function() Flying = false; StopFlyPhysics() end)

MainTab:CreateToggle({
Name = "เปิด/ปิด บิน (Fly)",
CurrentValue = false,
Flag = "FlyToggle",
Callback = function(Value)
Flying = Value
if Flying then StartFly() else StopFlyPhysics() end
end,
})

MainTab:CreateSlider({
Name = "ความเร็วในการบิน (Fly Speed)",
Range = {1, 500},
Increment = 1,
Suffix = " Speed",
CurrentValue = 50,
Flag = "FlySpeedSlider",
Callback = function(Value) FlySpeedValue = Value end,
})

-- ==========================================
-- 2. แท็บระบบต่อสู้ (Combat)
-- ==========================================
local CombatTab = Window:CreateTab("ระบบต่อสู้ 🎯", 4483362458)

CombatTab:CreateSection("ระบบล็อกหัวในวงกลม (Circle Aimbot)")

CombatTab:CreateToggle({
Name = "เปิด/ปิด ล็อกหัววงกลม (Aimbot)",
CurrentValue = false,
Flag = "AimbotToggle",
Callback = function(Value)
AimbotEnabled = Value
FOVFrame.Visible = AimbotEnabled and ShowCircle
end,
})

CombatTab:CreateToggle({
Name = "แสดงวงกลมล็อกเป้า (Show FOV Circle)",
CurrentValue = true,
Flag = "ShowCircleToggle",
Callback = function(Value)
ShowCircle = Value
FOVFrame.Visible = AimbotEnabled and ShowCircle
end,
})

CombatTab:CreateSlider({
Name = "ขนาดวงกลม (Circle Radius)",
Range = {20, 400},
Increment = 5,
Suffix = " Size",
CurrentValue = 100,
Flag = "CircleSizeSlider",
Callback = function(Value)
CircleRadius = Value
FOVFrame.Size = UDim2.new(0, CircleRadius * 2, 0, CircleRadius * 2)
end,
})

CombatTab:CreateSlider({
Name = "ระดับความแรงการล็อก (Strength)",
Range = {1, 20},
Increment = 1,
Suffix = " Level",
CurrentValue = 5,
Flag = "AimbotStrengthSlider",
Callback = function(Value) AimbotStrength = math.max(1, Value) end,
})

local function GetTargetInCircle()
local cam = workspace.CurrentCamera
if not cam then return nil end
local target = nil
local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
local shortest = CircleRadius

for _, p in ipairs(Players:GetPlayers()) do
local char = p ~= LocalPlayer and p.Character
local head = char and char:FindFirstChild("Head")
local hum = char and char:FindFirstChildOfClass("Humanoid")
if head and hum and hum.Health > 0 then
local pos, onScreen = cam:WorldToViewportPoint(head.Position)
if onScreen then
local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
if dist < shortest then
shortest = dist
target = head
end
end
end
end
return target
end

Core:RegisterConnection("AimbotRender", RunService.RenderStepped:Connect(function()
local cam = workspace.CurrentCamera
if AimbotEnabled and cam then
local head = GetTargetInCircle()
if head then
local goal = CFrame.new(cam.CFrame.Position, head.Position)
cam.CFrame = cam.CFrame:Lerp(goal, 1 / AimbotStrength)
end
end
end))

CombatTab:CreateSection("อาวุธปืน (Client Tool)")

CombatTab:CreateButton({
Name = "เสกปืนพกกล (Phupha Pistol)",
Callback = function()
local tool = Instance.new("Tool")
tool.Name = "Phupha Pistol"
tool.RequiresHandle = true

local handle = Instance.new("Part")  
  handle.Name = "Handle"  
  handle.Size = Vector3.new(0.6, 1.2, 2)  
  handle.BrickColor = BrickColor.new("Dark stone grey")  
  handle.Material = Enum.Material.Metal  
  handle.Parent = tool  

  tool.Parent = LocalPlayer.Backpack  
  TrackTool(tool)  

  tool.Activated:Connect(function()  
     local char = getChar()  
     if char and char:FindFirstChild("Head") and handle.Parent then  
        local sound = Instance.new("Sound")  
        sound.SoundId = "rbxassetid://131590145"  
        sound.Volume = 2  
        sound.Parent = handle  
        sound:Play()  
        game:GetService("Debris"):AddItem(sound, 3)  

        local bullet = Instance.new("Part")  
        bullet.Size = Vector3.new(0.2, 0.2, 2)  
        bullet.BrickColor = BrickColor.new("Lime green")  
        bullet.Material = Enum.Material.Neon  
        bullet.CFrame = handle.CFrame * CFrame.new(0, 0, -2)  
        bullet.Anchored = true  
        bullet.CanCollide = false  
        bullet.Parent = HubFolder  

        task.spawn(function()  
           for _ = 1, 30 do  
              if not bullet.Parent then return end  
              bullet.CFrame = bullet.CFrame + (bullet.CFrame.LookVector * 5)  
              task.wait(0.02)  
           end  
           bullet:Destroy()  
        end)  
     end  
  end)  
  Rayfield:Notify({ Title = "SYSTEM", Content = "โหลดอาวุธไซเบอร์เรียบร้อย!", Duration = 3 })

end,
})

-- ==========================================
-- 3. แท็บอนิเมชั่นและตัวละคร (Animation & Morph)
-- ==========================================
local AnimMorphTab = Window:CreateTab("อนิเมชั่น & ตัวละคร 🎭", 4483362458)

AnimMorphTab:CreateSection("ระบบเปลี่ยนท่าเดิน (Custom Walk Animation)")

-- (หมายเหตุ) Animation ID ด้านล่างยกมาจากสคริปต์เดิม ยังไม่ได้ตรวจว่ายังใช้ได้
local WalkAnimations = {
["Zombie Walk"] = 616158038,
["Robot Walk"] = 616160682,
["Funny Walk"] = 616159239,
["Moonwalk"] = 616162294,
["Ninja Walk"] = 656118852,
["Stylish Walk"] = 616163682,
["Cartoon Walk"] = 616157476,
}

local IdleAnimations = {
["Robot Idle"] = 616160870,
["Zombie Idle"] = 616158929,
["Funny Idle"] = 616159813,
["Hero Pose"] = 616161104,
["Relax Pose"] = 616162608,
}

local origAnim = weak()                 -- Animation instance -> id เดิม
local chosenAnim = { walk = nil, idle = nil }

local function SetAnim(inst, id)
if inst and inst:IsA("Animation") then
if origAnim[inst] == nil then origAnim[inst] = inst.AnimationId end
inst.AnimationId = "rbxassetid://" .. tostring(id)
end
end

local function RefreshTracks()
local hum = getHum()
if hum then
for _, t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
end
end

local function ApplyChosenAnims(char)
local animate = char and char:FindFirstChild("Animate")
if not animate then return false end
if chosenAnim.walk then
-- (แก้) เดิมตั้ง walk.RunAnim ซึ่งไม่มีอยู่จริง: ท่าเดินคือ walk.WalkAnim, ท่าวิ่งคือ run.RunAnim
local walk, run = animate:FindFirstChild("walk"), animate:FindFirstChild("run")
SetAnim(walk and walk:FindFirstChild("WalkAnim"), chosenAnim.walk)
SetAnim(run and run:FindFirstChild("RunAnim"), chosenAnim.walk)
end
if chosenAnim.idle then
local idle = animate:FindFirstChild("idle")
if idle then
for _, a in ipairs(idle:GetChildren()) do SetAnim(a, chosenAnim.idle) end
end
end
RefreshTracks()
return true
end

local function ResetAnims()
for inst, id in pairs(origAnim) do
if inst.Parent then inst.AnimationId = id end
end
table.clear(origAnim)
chosenAnim.walk, chosenAnim.idle = nil, nil
RefreshTracks()
end
Core:OnCleanup("Animations", ResetAnims)

for name, id in pairs(WalkAnimations) do
AnimMorphTab:CreateButton({
Name = "ท่าเดิน: " .. name,
Callback = function()
chosenAnim.walk = id
local ok = ApplyChosenAnims(getChar())
Rayfield:Notify({ Title = "🎭 ANIMATION", Content = ok and "เปลี่ยนท่าเดินเรียบร้อย!" or "ไม่พบสคริปต์ Animate ในตัวละคร", Duration = 2 })
end,
})
end

AnimMorphTab:CreateSection("ระบบเปลี่ยนท่าหยุดยืน (Custom Idle Animation)")

for name, id in pairs(IdleAnimations) do
AnimMorphTab:CreateButton({
Name = "ท่ายืน: " .. name,
Callback = function()
chosenAnim.idle = id
local ok = ApplyChosenAnims(getChar())
Rayfield:Notify({ Title = "🎭 ANIMATION", Content = ok and "เปลี่ยนท่ายืนเรียบร้อย!" or "ไม่พบสคริปต์ Animate ในตัวละคร", Duration = 2 })
end,
})
end

AnimMorphTab:CreateButton({
Name = "รีเซ็ตอนิเมชั่นทั้งหมด (Reset Animations)",
Callback = function()
-- (แก้) เดิมสลับ Character=nil/Parent=nil เสี่ยงพัง: คืน AnimationId เดิมที่จำไว้แทน
ResetAnims()
Rayfield:Notify({ Title = "🎭 ANIMATION", Content = "คืนค่าอนิเมชั่นเดิมแล้ว!", Duration = 2 })
end,
})

AnimMorphTab:CreateSection("ระบบแปลงร่างตัวละคร (Character Morph)")

local selectedMorphPlayer = nil
local MorphDropdown = AnimMorphTab:CreateDropdown({
Name = "เลือกตัวละครในเซิร์ฟเวอร์",
Options = {},
CurrentOption = {},
MultipleOptions = false,
Flag = "MorphDropdown",
Callback = function(Option)
selectedMorphPlayer = type(Option) == "table" and Option[1] or Option
end,
})

AnimMorphTab:CreateButton({
Name = "แปลงร่างเป็นตัวละครที่เลือก (Morph)",
Callback = function()
if not selectedMorphPlayer or selectedMorphPlayer == "" then
Rayfield:Notify({ Title = "🎭 MORPH", Content = "กรุณาเลือกผู้เล่นก่อน!", Duration = 2 })
return
end
local target = Players:FindFirstChild(selectedMorphPlayer)
local targetHum = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
local myHum = getHum()
if targetHum and myHum then
local ok, desc = pcall(function() return targetHum:GetAppliedDescription() end)
if ok and desc then
myHum:ApplyDescription(desc)
Rayfield:Notify({ Title = "🎭 MORPH", Content = "แปลงร่างสำเร็จ!", Duration = 3 })
end
end
end,
})

AnimMorphTab:CreateButton({
Name = "รีเซ็ตตัวละครกลับร่างเดิม (Reset Character)",
Callback = function()
-- (แก้) LocalPlayer:LoadCharacter() เรียกจากฝั่ง client ไม่ได้ → ดึง Description ของบัญชีตัวเองมา apply
local hum = getHum()
if hum then
local ok, desc = pcall(function()
return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
end)
if ok and desc then
hum:ApplyDescription(desc)
Rayfield:Notify({ Title = "🎭 MORPH", Content = "รีเซ็ตตัวละครเรียบร้อย!", Duration = 2 })
return
end
end
Rayfield:Notify({ Title = "🎭 MORPH", Content = "รีเซ็ตไม่สำเร็จ", Duration = 2 })
end,
})

AnimMorphTab:CreateSection("จัดการชื่อที่แสดง (Display Name Manager)")

local customDisplayNameInput = ""
AnimMorphTab:CreateInput({
Name = "กำหนดชื่อ Display Name ของคุณ",
PlaceholderText = "พิมพ์ชื่อใหม่ที่นี่...",
RemoveTextAfterFocusLost = false,
Flag = "DisplayNameInput",
Callback = function(Text) customDisplayNameInput = Text end,
})

AnimMorphTab:CreateButton({
Name = "เปลี่ยน Display Name",
Callback = function()
local hum = getHum()
if hum and customDisplayNameInput ~= "" then
hum.DisplayName = customDisplayNameInput
Rayfield:Notify({ Title = "🏷️ NAME", Content = "เปลี่ยนชื่อเป็น: " .. customDisplayNameInput, Duration = 2 })
end
end,
})

AnimMorphTab:CreateButton({
Name = "คืนค่าชื่อเดิม",
Callback = function()
local hum = getHum()
if hum then
hum.DisplayName = LocalPlayer.DisplayName
Rayfield:Notify({ Title = "🏷️ NAME", Content = "คืนค่าชื่อเดิมเรียบร้อย", Duration = 2 })
end
end,
})

-- ==========================================
-- 4. แท็บท่าทาง & เสกตึก (Weird Poses & Buildings)
-- ==========================================
local BuildTab = Window:CreateTab("ท่าทาง & เสกตึก 🏢", 4483362458)

BuildTab:CreateSection("ท่าทางประหลาด")

BuildTab:CreateButton({
Name = "ท่าลอยตัวนอนหงายกลางอากาศ (Floating Pose)",
Callback = function()
local hrp = getHRP()
if hrp then
hrp.CFrame = hrp.CFrame + Vector3.new(0, 5, 0)
hrp.Anchored = true
Rayfield:Notify({ Title = "SYSTEM", Content = "เปิดโหมดลอยตัว Matrix แล้ว!", Duration = 3 })
end
end,
})

BuildTab:CreateButton({
Name = "ยกเลิกท่าลอยตัว / ปลดแช่แข็ง",
Callback = function()
local hrp = getHRP()
if hrp then
hrp.Anchored = false
Rayfield:Notify({ Title = "SYSTEM", Content = "ยกเลิกท่าลอยตัวเรียบร้อย!", Duration = 3 })
end
end,
})

BuildTab:CreateButton({
Name = "ท่าย่อตัวมุดดิน (Underground Crouch Pose)",
Callback = function()
local hrp = getHRP()
if hrp then
hrp.CFrame = hrp.CFrame - Vector3.new(0, 3, 0)
Rayfield:Notify({ Title = "SYSTEM", Content = "มุดลงใต้ระบบเรียบร้อย!", Duration = 3 })
end
end,
})

BuildTab:CreateSection("ระบบเสกสิ่งก่อสร้าง")

BuildTab:CreateButton({
Name = "เสกกำแพงบังเกอร์ป้องกันตัว (Spawn Wall)",
Callback = function()
local hrp = getHRP()
if hrp then
local wall = Instance.new("Part")
wall.Size = Vector3.new(10, 10, 2)
wall.CFrame = hrp.CFrame + (hrp.CFrame.LookVector * 10) + Vector3.new(0, 3, 0)
wall.BrickColor = BrickColor.new("Dark stone grey")
wall.Material = Enum.Material.Neon
wall.Anchored = false
wall.Parent = HubFolder
Rayfield:Notify({ Title = "SYSTEM", Content = "เสกกำแพงนีออนเรียบร้อย!", Duration = 3 })
end
end,
})

BuildTab:CreateButton({
Name = "เสกตึกสูงจำลอง (Spawn Mini Tower)",
Callback = function()
local hrp = getHRP()
if hrp then
local pos = hrp.Position + (hrp.CFrame.LookVector * 15)
for i = 1, 5 do
if Core.Shutdown then return end
local floor = Instance.new("Part")
floor.Size = Vector3.new(8, 2, 8)
floor.Position = pos + Vector3.new(0, (i * 2) - 1, 0)
floor.BrickColor = BrickColor.new("Lime green")
floor.Material = Enum.Material.Neon
floor.Anchored = false
floor.Parent = HubFolder
task.wait(0.05)
end
Rayfield:Notify({ Title = "SYSTEM", Content = "เสกตึกไซเบอร์เรียบร้อย!", Duration = 3 })
end
end,
})

BuildTab:CreateButton({
Name = "เคลียร์สิ่งของที่ Hub สร้างขึ้นทั้งหมด",
Callback = function()
HubFolder:ClearAllChildren()
Rayfield:Notify({ Title = "SYSTEM", Content = "ล้างข้อมูลวัตถุทั้งหมดที่ Hub สร้างแล้ว", Duration = 3 })
end,
})

BuildTab:CreateSection("ไอเทมแก้วน้ำดื่ม")

BuildTab:CreateButton({
Name = "เสกแก้วน้ำดื่ม (Drink Cup)",
Callback = function()
local tool = Instance.new("Tool")
tool.Name = "Drink Cup"
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.8, 1.2, 0.8)
handle.BrickColor = BrickColor.new("Lime green")
handle.Material = Enum.Material.Glass
handle.Parent = tool
tool.Parent = LocalPlayer.Backpack
TrackTool(tool)

tool.Activated:Connect(function()  
     local char = getChar()  
     local head = char and char:FindFirstChild("Head")  
     if head then  
        Rayfield:Notify({ Title = "🥤 สดชื่น!", Content = "กำลังโหลดพลังงาน...", Duration = 2 })  
        local sound = Instance.new("Sound")  
        sound.SoundId = "rbxassetid://9114221371"  
        sound.Volume = 1  
        sound.Parent = head  
        sound:Play()  
        game:GetService("Debris"):AddItem(sound, 3)  
     end  
  end)  
  Rayfield:Notify({ Title = "SYSTEM", Content = "รับไอเทมเข้ากระเป๋าแล้ว!", Duration = 3 })

end,
})

-- ==========================================
-- 5. แท็บฟังก์ชันเสริม (Visual & Fun & FPS Boost)
-- ==========================================
local ExtraTab = Window:CreateTab("ฟังก์ชันเสริม 👁️", 4483362458)

ExtraTab:CreateSection("ระบบเร่งความลื่น (Advanced FPS Boost)")

local originalMaterials, originalReflectance = weak(), weak()
local fpsBoostActive = false
local fpsGen = 0

local function FPSApplyPart(v)
if v:IsA("BasePart") then
if originalMaterials[v] == nil then
originalMaterials[v] = v.Material
originalReflectance[v] = v.Reflectance
end
v.Material = Enum.Material.SmoothPlastic
v.Reflectance = 0
end
end

local function FPSRestore()
fpsGen += 1
Core:ClearConnection("FPSBoostAdded")
for v, mat in pairs(originalMaterials) do
if v.Parent then v.Material = mat end
end
for v, ref in pairs(originalReflectance) do
if v.Parent then v.Reflectance = ref end
end
table.clear(originalMaterials)
table.clear(originalReflectance)
end
Core:OnCleanup("FPSBoost", FPSRestore)

ExtraTab:CreateToggle({
Name = "เปิด/ปิด โหมดเร่งความลื่น (FPS Boost)",
CurrentValue = false,
Flag = "FPSBoostToggle",
Callback = function(Value)
fpsBoostActive = Value
SetLightingOwner("FPSBoost", Value)
if Value then
fpsGen += 1
local my = fpsGen
Core:RegisterConnection("FPSBoostAdded", workspace.DescendantAdded:Connect(function(v)
if fpsBoostActive then FPSApplyPart(v) end
end))
task.spawn(function()
ForEachChunked(workspace:GetDescendants(), FPSApplyPart, function() return fpsGen ~= my end)
end)
Rayfield:Notify({ Title = "🚀 BOOST", Content = "เปิดโหมดเร่งความลื่นเรียบร้อย!", Duration = 3 })
else
FPSRestore()
Rayfield:Notify({ Title = "🚀 BOOST", Content = "คืนค่าแสงและวัสดุดั้งเดิมเรียบร้อย!", Duration = 3 })
end
end,
})

ExtraTab:CreateSection("ระบบหายตัว (True Invisibility)")

local invisibilityActive = false
local originalTransparency = weak()

local function SetInvisibility(char, state)
if not char then return end
-- คืนของเดิมก่อนเสมอ (กันค่า "1" ถูกจำเป็นค่าเดิมเวลาเรียกซ้ำ)
for obj, t in pairs(originalTransparency) do
if obj.Parent then obj.Transparency = t end
end
table.clear(originalTransparency)
if state then
for _, obj in ipairs(char:GetDescendants()) do
-- Handle ของ Accessory เป็น BasePart อยู่แล้ว จึงครอบคลุมในเงื่อนไขนี้
if obj:IsA("BasePart") or obj:IsA("Decal") then
originalTransparency[obj] = obj.Transparency
obj.Transparency = 1
end
end
end
end
Core:OnCleanup("Invisibility", function() SetInvisibility(getChar(), false) end)

ExtraTab:CreateToggle({
Name = "เปิด/ปิด โหมดหายตัว (Invisibility)",
CurrentValue = false,
Flag = "InvisibilityToggle",
Callback = function(Value)
invisibilityActive = Value
SetInvisibility(getChar(), invisibilityActive)
Rayfield:Notify({ Title = "👻 SYSTEM", Content = invisibilityActive and "เปิดโหมดหายตัวแล้ว!" or "ปิดโหมดหายตัวแล้ว!", Duration = 3 })
end,
})

ExtraTab:CreateSection("มองคน (Unified ESP & Names)")

local espData = {}   -- [player] = { highlight=, gui=, label= }

local function RemoveESP(player)
local e = espData[player]
if not e then return end
if e.highlight then e.highlight:Destroy() end
if e.gui then e.gui:Destroy() end
espData[player] = nil
end

-- yield ได้ (WaitForChild) จึงต้องเรียกผ่าน task.spawn
local function ApplyESP(player)
if player == LocalPlayer or Core.Shutdown then return end
RemoveESP(player)
if not (ESPEnabled or NameESPEnabled) then return end

local char = player.Character
if not char then return end
-- (แก้) เดิม return ทันทีถ้ายังไม่มี HRP → ESP ไม่ติดหลังเกิดใหม่
local hrp = char:WaitForChild("HumanoidRootPart", 5)
local head = char:WaitForChild("Head", 5)
if not hrp or not head or player.Character ~= char or Core.Shutdown then return end
RemoveESP(player) -- กันเรียกซ้อนระหว่างรอ

local entry = {}
if ESPEnabled then
local h = Instance.new("Highlight")
h.Name = "PhuphaESP"
h.Adornee = char
h.FillColor = Color3.fromRGB(0, 255, 100)
h.FillTransparency = 0.5
h.OutlineColor = Color3.fromRGB(255, 255, 255)
h.Parent = char
entry.highlight = h
end
if NameESPEnabled then
local bg = Instance.new("BillboardGui")
bg.Name = "PhuphaNameESP"
bg.Adornee = head
bg.Size = UDim2.new(0, 200, 0, 50)
bg.StudsOffset = Vector3.new(0, 2.5, 0)
bg.AlwaysOnTop = true
bg.Parent = head

local label = Instance.new("TextLabel")  
  label.Size = UDim2.new(1, 0, 1, 0)  
  label.BackgroundTransparency = 1  
  label.TextColor3 = Color3.fromRGB(0, 255, 100)  
  label.TextStrokeTransparency = 0  
  label.Font = Enum.Font.GothamBold  
  label.TextSize = 13  
  label.Text = player.Name  
  label.Parent = bg  
  entry.gui = bg  
  entry.label = label

end
espData[player] = entry
end

local function RefreshAllESP()
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LocalPlayer then task.spawn(ApplyESP, p) end
end
end

local function HookESPPlayer(player)
if player == LocalPlayer then return end
Core:RegisterConnection("ESPChar_" .. player.UserId, player.CharacterAdded:Connect(function()
task.spawn(ApplyESP, player)
end))
task.spawn(ApplyESP, player)
end

for _, p in ipairs(Players:GetPlayers()) do HookESPPlayer(p) end

Core:RegisterConnection("PlayerAddedESP", Players.PlayerAdded:Connect(HookESPPlayer))
Core:RegisterConnection("PlayerRemovingESP", Players.PlayerRemoving:Connect(function(player)
Core:ClearConnection("ESPChar_" .. player.UserId)
RemoveESP(player)
end))

-- ลูปเดียวอัปเดตระยะทุกคน (แทน task ต่อผู้เล่นเดิม)
Core:RegisterTask("ESPLabelLoop", task.spawn(function()
while true do
task.wait(0.2)
if NameESPEnabled then
local mine = getHRP()
for player, e in pairs(espData) do
local c = player.Character
local theirs = c and c:FindFirstChild("HumanoidRootPart")
if e.label and mine and theirs then
e.label.Text = player.Name .. " [" .. math.floor((mine.Position - theirs.Position).Magnitude) .. "m]"
end
end
end
end
end))

Core:OnCleanup("ESP", function()
for player in pairs(espData) do RemoveESP(player) end
end)

ExtraTab:CreateToggle({
Name = "เปิด/ปิด มองคน (ESP)",
CurrentValue = false,
Flag = "ESPToggle",
Callback = function(Value)
ESPEnabled = Value
RefreshAllESP()
end,
})

ExtraTab:CreateToggle({
Name = "แสดงชื่อและระยะห่างผู้เล่น (Name + Distance ESP)",
CurrentValue = false,
Flag = "NameESPToggle",
Callback = function(Value)
NameESPEnabled = Value
RefreshAllESP()
end,
})

ExtraTab:CreateSection("การเคลื่อนไหวพิเศษ")

local function StartSwim()
Core:RegisterConnection("Swim", RunService.Heartbeat:Connect(function()
local hum = getHum()
if hum then
hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
hum:ChangeState(Enum.HumanoidStateType.Swimming)
end
end))
end

local function StopSwim()
Core:ClearConnection("Swim")
local hum = getHum()
if hum then
-- (แก้) เดิมสั่ง SetStateEnabled(Swimming, false) ทำให้ว่ายน้ำจริงในเกมไม่ได้อีก
hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
hum:ChangeState(Enum.HumanoidStateType.GettingUp)
end
end
Core:OnCleanup("Swim", function() SwimEnabled = false; StopSwim() end)

ExtraTab:CreateToggle({
Name = "ว่ายน้ำได้ทุกที่ (Swim Anywhere)",
CurrentValue = false,
Flag = "SwimToggle",
Callback = function(Value)
SwimEnabled = Value
if SwimEnabled then StartSwim() else StopSwim() end
end,
})

ExtraTab:CreateButton({
Name = "เดินกลับหัวครั้งเดียว (Upside Down 180°)",
Callback = function()
local hrp = getHRP()
if hrp then
hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(180), 0, 0)
Rayfield:Notify({ Title = "SYSTEM", Content = "พลิกตัวกลับหัวเรียบร้อย!", Duration = 3 })
end
end,
})

ExtraTab:CreateSection("ปรับแต่งมุมมองและแสง")

local originalFOV = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70
Core:OnCleanup("CameraFOV", function()
local cam = workspace.CurrentCamera
if cam then cam.FieldOfView = originalFOV end
end)

ExtraTab:CreateSlider({
Name = "ปรับมุมมองกว้าง (FOV)",
Range = {70, 120},
Increment = 1,
Suffix = " FOV",
CurrentValue = 70,
Flag = "FOVSlider",
Callback = function(Value)
local cam = workspace.CurrentCamera
if cam then cam.FieldOfView = Value end
end,
})

ExtraTab:CreateToggle({
Name = "เปิดไฟสว่างสุด (FullBright)",
CurrentValue = false,
Flag = "FullBrightToggle",
Callback = function(Value)
-- (แก้) ใช้ Lighting Manager ร่วมกับ FPS Boost: ปิดแล้วคืน GlobalShadows ด้วย
SetLightingOwner("FullBright", Value)
end,
})

-- ==========================================
-- 6. แท็บเทเลพอร์ต (Teleport)
-- ==========================================
local TeleportTab = Window:CreateTab("เทเลพอร์ต 🌐", 4483362458)

TeleportTab:CreateSection("วาร์ปไปหาผู้เล่น")

local SelectedPlayer = nil
local PlayerDropdown = TeleportTab:CreateDropdown({
Name = "เลือกผู้เล่น",
Options = {},
CurrentOption = {},
MultipleOptions = false,
Flag = "SelectPlayerDropdown",
Callback = function(Option)
SelectedPlayer = type(Option) == "table" and Option[1] or Option
end,
})

-- (แก้) refresh เฉพาะตอนมีคนเข้า/ออก แทน loop ทุก 2 วิ ที่รีเซ็ตตัวเลือกที่เลือกไว้
local function RefreshDropdowns()
local names = {}
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LocalPlayer then table.insert(names, p.Name) end
end
if selectedMorphPlayer and not table.find(names, selectedMorphPlayer) then selectedMorphPlayer = nil end
if SelectedPlayer and not table.find(names, SelectedPlayer) then SelectedPlayer = nil end
pcall(function() MorphDropdown:Refresh(names) end)
pcall(function() PlayerDropdown:Refresh(names) end)
end
RefreshDropdowns()
Core:RegisterConnection("DropdownPlayerAdded", Players.PlayerAdded:Connect(function() task.defer(RefreshDropdowns) end))
Core:RegisterConnection("DropdownPlayerRemoving", Players.PlayerRemoving:Connect(function() task.defer(RefreshDropdowns) end))

TeleportTab:CreateButton({
Name = "วาร์ปไปหาผู้เล่นที่เลือก",
Callback = function()
if SelectedPlayer then
local target = Players:FindFirstChild(SelectedPlayer)
local thrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
local hrp = getHRP()
if thrp and hrp then
hrp.CFrame = thrp.CFrame + Vector3.new(0, 3, 0)
end
end
end,
})

TeleportTab:CreateSection("จุดบันทึกตำแหน่ง (Save Pos)")
local SavedPosition = nil

TeleportTab:CreateButton({
Name = "บันทึกตำแหน่งปัจจุบัน (Save Position)",
Callback = function()
local hrp = getHRP()
if hrp then
SavedPosition = hrp.CFrame
Rayfield:Notify({ Title = "SYSTEM", Content = "บันทึกพิกัด Matrix แล้ว!", Duration = 3 })
end
end,
})

TeleportTab:CreateButton({
Name = "วาร์ปกลับจุดที่บันทึก (Teleport to Saved)",
Callback = function()
local hrp = getHRP()
if SavedPosition and hrp then
hrp.CFrame = SavedPosition
else
Rayfield:Notify({ Title = "SYSTEM", Content = "ยังไม่ได้บันทึกพิกัด!", Duration = 3 })
end
end,
})

-- ==========================================
-- 7. แท็บอำนวยความสะดวก & สายปั่น (Utility & Fun)
-- ==========================================
local UtilityTab = Window:CreateTab("อำนวยความสะดวก 🛠️", 4483362458)

local function SetAntiAFK(Value)
if Value then
local VirtualUser = game:GetService("VirtualUser")
Core:RegisterConnection("AntiAFK", LocalPlayer.Idled:Connect(function()
local cam = workspace.CurrentCamera
if cam then
VirtualUser:Button2Down(Vector2.new(0, 0), cam.CFrame)
task.wait(1)
VirtualUser:Button2Up(Vector2.new(0, 0), cam.CFrame)
end
end))
else
Core:ClearConnection("AntiAFK")
end
end
-- (แก้) CurrentValue = true ไม่ได้เรียก Callback ตอนสร้าง → เปิดจริงตรงนี้เอง (ซ้ำได้ ไม่ซ้อน)
SetAntiAFK(true)

UtilityTab:CreateToggle({
Name = "กันหลุด AFK (Anti-AFK)",
CurrentValue = true,
Flag = "AntiAFKToggle",
Callback = SetAntiAFK,
})

local storedHoldDurations = weak()
local instantInteractActive = false
local interactGen = 0

local function PromptApply(v)
if v:IsA("ProximityPrompt") then
if storedHoldDurations[v] == nil then storedHoldDurations[v] = v.HoldDuration end
v.HoldDuration = 0
end
end

local function PromptRestore()
interactGen += 1
Core:ClearConnection("InstantInteractAdded")
for prompt, dur in pairs(storedHoldDurations) do
if prompt.Parent then prompt.HoldDuration = dur end
end
table.clear(storedHoldDurations)
end
Core:OnCleanup("InstantInteract", PromptRestore)

UtilityTab:CreateToggle({
Name = "กดปุ่ม E แบบไม่ต้องรอ (ครอบคลุมของเกิดใหม่)",
CurrentValue = false,
Flag = "InstantInteractToggle",
Callback = function(Value)
instantInteractActive = Value
if Value then
interactGen += 1
local my = interactGen
Core:RegisterConnection("InstantInteractAdded", workspace.DescendantAdded:Connect(function(v)
if instantInteractActive then PromptApply(v) end
end))
task.spawn(function()
ForEachChunked(workspace:GetDescendants(), PromptApply, function() return interactGen ~= my end)
end)
Rayfield:Notify({ Title = "SYSTEM", Content = "เปิดใช้งาน Instant Interact แล้ว!", Duration = 3 })
else
PromptRestore()
Rayfield:Notify({ Title = "SYSTEM", Content = "คืนค่า HoldDuration เดิมแล้ว!", Duration = 3 })
end
end,
})

local Mouse = LocalPlayer:GetMouse()
UtilityTab:CreateToggle({
Name = "Ctrl + คลิกซ้าย เพื่อวาร์ป (Click TP)",
CurrentValue = false,
Flag = "ClickTPToggle",
Callback = function(Value) ClickTPEnabled = Value end,
})

-- (แก้) ใช้ InputBegan เช็ค gameProcessed (คลิก UI ไม่วาร์ป) และ .Position แทน .p
Core:RegisterConnection("ClickTP", UserInputService.InputBegan:Connect(function(input, processed)
if processed or not ClickTPEnabled then return end
if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
local hrp = getHRP()
local hit = Mouse.Hit
if hrp and hit then
hrp.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
end
end))

UtilityTab:CreateSection("สายปั่น & ลูกเล่น 😈")

UtilityTab:CreateToggle({
Name = "เปิด/ปิด หมุนตัวติ้วๆ (Spin Bot)",
CurrentValue = false,
Flag = "SpinToggle",
Callback = function(Value)
Spinning = Value
if Spinning then
Core:RegisterConnection("SpinBot", RunService.RenderStepped:Connect(function()
local hrp = getHRP()
if Spinning and hrp then
hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SpinSpeed), 0)
end
end))
else
Core:ClearConnection("SpinBot")
end
end,
})

UtilityTab:CreateSlider({
Name = "ความเร็วในการหมุน (Spin Speed)",
Range = {5, 100},
Increment = 5,
Suffix = " Speed",
CurrentValue = 20,
Flag = "SpinSpeedSlider",
Callback = function(Value) SpinSpeed = Value end,
})

local freezeActive = false
local originalAnchored = nil

local function Unfreeze()
local hrp = getHRP()
if hrp and originalAnchored ~= nil then hrp.Anchored = originalAnchored end
originalAnchored = nil
end
Core:OnCleanup("Freeze", function() freezeActive = false; Unfreeze() end)

UtilityTab:CreateToggle({
Name = "แช่แข็งตัวละครกลางอากาศ (Freeze)",
CurrentValue = false,
Flag = "FreezeToggle",
Callback = function(Value)
freezeActive = Value
local hrp = getHRP()
if freezeActive then
if hrp then
if originalAnchored == nil then originalAnchored = hrp.Anchored end
hrp.Anchored = true
end
else
Unfreeze()
end
end,
})

local originalGravity = nil
local gravityActive = false
local currentGravityValue = 196

local function RestoreGravity()
if originalGravity ~= nil then
workspace.Gravity = originalGravity
originalGravity = nil
end
end
Core:OnCleanup("Gravity", function() gravityActive = false; RestoreGravity() end)

UtilityTab:CreateToggle({
Name = "เปิด/ปิด ปรับแรงโน้มถ่วง (Custom Gravity)",
CurrentValue = false,
Flag = "GravityToggle",
Callback = function(Value)
gravityActive = Value
if gravityActive then
-- (แก้) จำค่าเดิมตอน "เปิด" ไม่ใช่ตอนโหลดสคริปต์ (เกมอาจเปลี่ยนแรงโน้มถ่วงทีหลัง)
if originalGravity == nil then originalGravity = workspace.Gravity end
workspace.Gravity = currentGravityValue
Rayfield:Notify({ Title = "SYSTEM", Content = "ตั้งค่าแรงโน้มถ่วงเป็น: " .. currentGravityValue, Duration = 2 })
else
local prev = originalGravity
RestoreGravity()
Rayfield:Notify({ Title = "SYSTEM", Content = "คืนค่าแรงโน้มถ่วงเดิมแล้ว (" .. tostring(prev or workspace.Gravity) .. ")", Duration = 3 })
end
end,
})

UtilityTab:CreateSlider({
Name = "ค่าแรงโน้มถ่วง (Gravity Value)",
Range = {0, 500},
Increment = 1,
Suffix = " Grav",
CurrentValue = 196,
Flag = "GravitySlider",
Callback = function(Value)
currentGravityValue = Value
if gravityActive then workspace.Gravity = Value end
end,
})

-- ==========================================
-- 8. แท็บเซิร์ฟเวอร์ (Server)
-- ==========================================
local ServerTab = Window:CreateTab("เซิร์ฟเวอร์ 🔄", 4483362458)

local teleporting = false

ServerTab:CreateButton({
Name = "เข้าเซิร์ฟเดิมใหม่ (Rejoin)",
Callback = function()
if teleporting then return end
teleporting = true
pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
task.delay(5, function() teleporting = false end)
end,
})

ServerTab:CreateButton({
Name = "ย้ายไปเซิร์ฟเวอร์อื่นจริง (Server Hop)",
Callback = function()
if teleporting then return end
teleporting = true
task.delay(8, function() teleporting = false end)
Rayfield:Notify({ Title = "🔄 SYSTEM", Content = "กำลังค้นหาเซิร์ฟเวอร์อื่น...", Duration = 3 })
local success = pcall(function()
local servers = {}
local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
local data = HttpService:JSONDecode(req)
if data and data.data then
for _, s in ipairs(data.data) do
if type(s) == "table" and s.playing < s.maxPlayers and s.id ~= game.JobId then
table.insert(servers, s.id)
end
end
end
if #servers > 0 then
TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
else
TeleportService:Teleport(game.PlaceId, LocalPlayer)
end
end)
if not success then
pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end
end,
})

local defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance
Core:OnCleanup("Zoom", function() LocalPlayer.CameraMaxZoomDistance = defaultMaxZoom end)

ServerTab:CreateButton({
Name = "ซูมกล้องออกได้ไม่จำกัด (Infinite Zoom)",
Callback = function()
LocalPlayer.CameraMaxZoomDistance = 100000
Rayfield:Notify({ Title = "SYSTEM", Content = "ปลดล็อกระยะซูมกล้องแล้ว!", Duration = 3 })
end,
})

ServerTab:CreateButton({
Name = "คืนค่าระยะซูมเดิม (Reset Zoom)",
Callback = function()
LocalPlayer.CameraMaxZoomDistance = defaultMaxZoom
Rayfield:Notify({ Title = "SYSTEM", Content = "คืนค่าซูมกล้องเดิมแล้ว!", Duration = 3 })
end,
})

ServerTab:CreateSection("ปิดสคริปต์")

ServerTab:CreateButton({
Name = "ปิด Hub และคืนค่าทุกอย่าง (Unload)",
Callback = Unload,
})

-- ==========================================
-- Respawn Handler (คืนสถานะที่เปิดไว้ให้ครบ)
-- ==========================================
Core:RegisterConnection("CharacterAddedHandler", LocalPlayer.CharacterAdded:Connect(function(char)
Core:ClearConnection("Fly")

local hum = char:WaitForChild("Humanoid", 10)
local hrp = char:WaitForChild("HumanoidRootPart", 10)
if not hum or not hrp or Core.Shutdown then return end
task.wait(0.5)
if LocalPlayer.Character ~= char then return end

if Flying then StartFly() end
if SwimEnabled then StartSwim() end            -- (แก้) เดิมลบ Swim แล้วไม่คืน
if AuraEnabled then UpdateAura(char) end
if invisibilityActive then SetInvisibility(char, true) end -- (แก้) เดิมไม่คืนหลังเกิดใหม่
if freezeActive then
originalAnchored = hrp.Anchored
hrp.Anchored = true
end
if chosenAnim.walk or chosenAnim.idle then ApplyChosenAnims(char) end
end))

-- ==========================================
-- สรุปการแก้ไขจาก v14.0
-- 1) ตัวแปร Aimbot ไม่ได้ประกาศ (nil ใน GetTargetInCircle / Lerp) → ประกาศ local
-- 2) Core:Cleanup ไม่เคยถูกเรียก → เพิ่มปุ่ม Unload + Restorers คืนค่าโลกทั้งหมด + guard โหลดซ้ำ
-- 3) FullBright ปิดแล้วไม่คืน GlobalShadows / ชนกับ FPS Boost → Lighting Manager แบบ owner
-- 4) ESP: ไม่ติดหลังเกิดใหม่ (HRP ยังไม่มา), connection รั่ว → WaitForChild + ลงทะเบียนใน Core
-- 5) ท่าเดิน: เดิมตั้ง walk.RunAnim (ไม่มีจริง) → WalkAnim/RunAnim, จำค่าเดิมไว้ reset, คืนหลัง respawn
-- 6) Reset Character ใช้ LoadCharacter ฝั่ง client ไม่ได้ → ApplyDescription ของบัญชีตัวเอง
-- 7) Swim ปิดแล้วทำให้ว่ายน้ำจริงไม่ได้ + ไม่คืนหลัง respawn
-- 8) AntiAFK ค่าเริ่ม true แต่ไม่ได้เปิดจริง; Invisibility/Freeze ไม่คืนหลัง respawn
-- 9) Fly: ขึ้น/ลงตามกล้อง + Space/Shift, บินต่อหลังตาย (ไม่ปิด flag เอง)
-- 10) FOV circle เยื้องจาก IgnoreGuiInset, ClickTP ไม่เช็ค gameProcessed, dropdown refresh ทุก 2 วิ
-- 11) ตาราง strong ref → weak table, วนลูป GetDescendants แบบ chunk, ครอบ pcall ตอนโหลด Rayfield
-- ==========================================

Rayfield:Notify({
Title = "Phupha💀💀 Hub v14.1 Ready",
Content = "แก้บั๊กและเพิ่มระบบ Unload เรียบร้อย!",
Duration = 5,
Image = 4483362458,
})
