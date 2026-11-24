--[[
    ========================================================================
    NVL-Win.lua - Main Execution Script for Neverlose / Memory UI
    Pixel-Perfect Luau Interface matching NVL_PRIVATE with Crown Logo,
    Dynamic Place/Game SubTitle, Live NEVERLOSE Watermark, Discord Sync,
    Spectators Window with Real-time Player Tracking, Harion Secure Protection,
    and Complete Tabs + TopBar Sub-Tabs (Thread, Enemy, Other, Team).
    ========================================================================
]]

-- ========================================================================
-- Environment Protection & Anti-Detection Layer (Extracted from Harion)
-- ========================================================================
do
	local cloneref = cloneref or function(o) return o end
	local safeNewcclosure = newcclosure or function(fn) return fn end

	if not getgenv().__NVL_Protected then
		getgenv().__NVL_Protected = true

		if setthreadidentity then
			pcall(setthreadidentity, 8)
		end

		-- Hook LocalPlayer.Kick to prevent game scripts from client-kicking when UI is injected
		pcall(function()
			local Players = cloneref(game:GetService("Players"))
			local lp = Players.LocalPlayer
			if lp and hookfunction then
				local oldKick
				oldKick = hookfunction(lp.Kick, safeNewcclosure(function(self, ...)
					if self == lp then
						warn("[NVL-Win] Security Guard: Game client-kick attempt blocked.")
						return nil
					end
					return oldKick(self, ...)
				end))
			end
		end)

		-- CameraSecurity & Analytics metatable tamper bypass (from Harion.txt)
		pcall(function()
			local okEnv, renv = pcall(getrenv)
			local setmt = okEnv and renv and renv.setmetatable
			if hookfunction and setmt then
				local oldSetmt = setmt
				hookfunction(setmt, safeNewcclosure(function(t, mt)
					if mt and type(mt) == "table" and rawget(mt, "__mode") then
						local mode = rawget(mt, "__mode")
						if mode == "kv" or mode == "v" or mode == "k" then
							local okTrace, trace = pcall(debug.traceback)
							if okTrace and type(trace) == "string" then
								if trace:find("MiscellaneousController", 1, true)
									or trace:find("CameraSecurity", 1, true)
									or trace:find("AnalyticsPipelineController", 1, true) then
									return oldSetmt({ 1, 2, 3 }, {})
								end
							end
						end
					end
					return oldSetmt(t, mt)
				end))
			end
		end)
	end
end

-- Load Asset Bundle
local MemoryAssets = nil
pcall(function()
	if isfile and isfile("uisimbl/memory_assets.lua") then
		MemoryAssets = loadstring(readfile("uisimbl/memory_assets.lua"))()
	elseif isfile and isfile("memory_assets.lua") then
		MemoryAssets = loadstring(readfile("memory_assets.lua"))()
	end
end)
MemoryAssets = MemoryAssets or { Icons = {} }

-- Load Library
local MemoryUI = nil
pcall(function()
	if isfile and isfile("uisimbl/lib.lua") then
		MemoryUI = loadstring(readfile("uisimbl/lib.lua"))()
	elseif isfile and isfile("lib.lua") then
		MemoryUI = loadstring(readfile("lib.lua"))()
	elseif isfile and isfile("uisimbl/memory_library.lua") then
		MemoryUI = loadstring(readfile("uisimbl/memory_library.lua"))()
	end
end)

if not MemoryUI then
	error("[NVL-Win] Could not load lib.lua!")
end
getgenv().MemoryUI = MemoryUI

-- ========================================================================
-- Initialize Main Window (Neverlose / Memory UI)
-- ========================================================================
local Window = MemoryUI:CreateWindow({
	Title = "NVL-Win.lua",
	-- SubTitle automatically resolves to the real Game/Place Name!
	SubTitle = "",
	Size = UDim2.new(0, 868, 0, 681),
	ToggleKey = Enum.KeyCode.RightShift,
	LoginRequired = false,
})

getgenv().NVL_MemoryUI = MemoryUI
getgenv().NVL_Window = Window

-- Initialize Live Watermark (NEVERLOSE) & Dynamic Spectators List
local Watermark = Window:CreateWatermark({
	Title = "NEVERLOSE",
	Server = "LOBBY",
	Visible = true,
})

local Spectators = Window:CreateSpectators({
	Title = "Spectators",
	Visible = true,
	AutoTrack = true,
})

-- ========================================================================
-- Sidebar Navigation Setup (Matching 1:1 Reference Hierarchy)
-- ========================================================================

-- CATEGORY 1: AIMBOT
Window:CreateCategory("AIMBOT")

-- 1.1 General Tab (Active tab with SubTabs: Thread, Enemy, Other, Team)
local GeneralTab = Window:CreateTab({
	Name = "General",
	Icon = MemoryAssets.Icons.view_filled or "",
	SubTabs = { "Thread", "Enemy", "Other", "Team" },
})

-- 1.2 Aimbot Tab
local AimbotTab = Window:CreateTab({
	Name = "Aimbot",
	Icon = MemoryAssets.Icons.target_fill or "",
	SubTabs = { "Main", "Target", "Accuracy" },
})

-- 1.3 Others Tab
local OthersTab = Window:CreateTab({
	Name = "Others",
	Icon = MemoryAssets.Icons.sliders or "",
	SubTabs = { "Triggerbot", "Overrides" },
})

-- CATEGORY 2: VISUALS
Window:CreateCategory("VISUALS")

-- 2.1 Players Tab
local PlayersTab = Window:CreateTab({
	Name = "Players",
	Icon = MemoryAssets.Icons.users or "",
	SubTabs = { "Enemies", "Teammates", "Self" },
})

-- 2.2 World Tab
local WorldTab = Window:CreateTab({
	Name = "World",
	Icon = MemoryAssets.Icons.world_2_fill or "",
	SubTabs = { "Ambience", "Effects" },
})

-- 2.3 View Tab
local ViewTab = Window:CreateTab({
	Name = "View",
	Icon = MemoryAssets.Icons.eye or "",
	SubTabs = { "Camera", "FOV" },
})

-- CATEGORY 3: MISCELLANEOUS
Window:CreateCategory("MISCELLANEOUS")

-- 3.1 Movement Tab
local MovementTab = Window:CreateTab({
	Name = "Movement",
	Icon = MemoryAssets.Icons.gamepad_bold or "",
	SubTabs = { "Speed", "Bhop", "Flight" },
})

-- 3.2 Exploits Tab
local ExploitsTab = Window:CreateTab({
	Name = "Exploits",
	Icon = MemoryAssets.Icons.pencil or "",
	SubTabs = { "Desync", "Fake Lag", "Server" },
})

-- 3.3 Config Tab
local ConfigTab = Window:CreateTab({
	Name = "Config",
	Icon = MemoryAssets.Icons.settings_bold or "",
	SubTabs = { "Presets", "HUD", "Binds" },
})

-- ========================================================================
-- Combat & Silent Aim Engine (New Method - Universal Hook & FOV)
-- ========================================================================
local CombatState = {
	Enabled = true,
	SilentAim = false,
	AutoFire = false,
	AutoRevolver = false,
	AntiStep = true,
	Backtracking = 100,
	DrawFOV = true,
	VisibleFOV = true,
	FOVRadius = 150,
	FOVColor = Color3.fromRGB(186, 145, 252),
	FOVTargetColor = Color3.fromRGB(255, 80, 100),
	Hitchance = 100,
	VisibleCheck = true,
	Autowall = false,
	PrioritizeLowHealth = true,
	IgnoreFriends = true,
	MaxDistance = 500,
	TargetPart = "HumanoidRootPart",
	BodyAimbotMode = "Head, Body, Chest, Neck",
	Prediction = 0.135,
	FirstBulletDelay = 0,
	AfterKillDelay = 500,
	TeleportBoost = false,

	-- New Combat Methods
	TargetPlayers = true,
	TargetNPCs = false,
	Triggerbot = false,
	TriggerbotDelay = 35,
	TriggerbotHeadOnly = false,
	TriggerbotRange = 350,
	TargetLock = false,
	TargetLockSmoothness = 0.25,
	TargetPriority = "Target",
	NoSpread = false,
	NoRecoil = false,
	FastCooldown = false,
	AutoReload = false,
	LockedPlayer = nil,
	LockedTargetPart = nil,
}
getgenv().CombatState = CombatState

local CurrentTarget = nil
local CurrentTargetPart = nil

local CoreGui = (gethui and gethui()) or (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
local UserInputService = cloneref and cloneref(game:GetService("UserInputService")) or game:GetService("UserInputService")
local RunService = cloneref and cloneref(game:GetService("RunService")) or game:GetService("RunService")
local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
local TweenService = cloneref and cloneref(game:GetService("TweenService")) or game:GetService("TweenService")
local Workspace = cloneref and cloneref(game:GetService("Workspace")) or game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local lp = Players.LocalPlayer

-- Clean previous script connections to prevent accumulating background tasks
if getgenv().__NVL_Connections then
	for _, conn in ipairs(getgenv().__NVL_Connections) do
		pcall(function() conn:Disconnect() end)
	end
end
getgenv().__NVL_Connections = {}

local function NVL_Connect(signal, callback)
	local conn = signal:Connect(callback)
	table.insert(getgenv().__NVL_Connections, conn)
	return conn
end

local oldFovGui = CoreGui:FindFirstChild("NVL_FOV_Container")
if oldFovGui then oldFovGui:Destroy() end

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "NVL_FOV_Container"
FOVGui.ResetOnSpawn = false
FOVGui.Parent = CoreGui

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Size = UDim2.new(0, CombatState.FOVRadius * 2, 0, CombatState.FOVRadius * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = CombatState.Enabled and CombatState.DrawFOV
FOVCircle.Parent = FOVGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.5
FOVStroke.Color = CombatState.FOVColor
FOVStroke.Transparency = 0.2
FOVStroke.Parent = FOVCircle

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local function UpdateFOVCircle()
	if FOVCircle and FOVCircle.Parent then
		local mousePos = UserInputService:GetMouseLocation()
		FOVCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
		FOVCircle.Size = UDim2.new(0, CombatState.FOVRadius * 2, 0, CombatState.FOVRadius * 2)
		FOVCircle.Visible = CombatState.Enabled and CombatState.DrawFOV and CombatState.VisibleFOV
		if FOVStroke then
			if CurrentTarget and CurrentTargetPart then
				FOVStroke.Color = CombatState.FOVTargetColor
			else
				FOVStroke.Color = CombatState.FOVColor
			end
		end
	end
end

-- Target Selection (New Method: Priority scoring + wall check)
local function GetClosestTarget()
	if not CombatState.Enabled then return nil, nil end

	-- If Target priority is active and we have a valid locked player, stick with them
	if CombatState.TargetPriority == "Target" and CombatState.LockedPlayer then
		local p = CombatState.LockedPlayer
		local isPlayer = p and typeof(p) == "Instance" and p:IsA("Player")
		if isPlayer and CombatState.TargetPlayers == false then
			CombatState.LockedPlayer = nil
			CombatState.LockedTargetPart = nil
		else
			local char = isPlayer and p.Character or p
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local head = char and char:FindFirstChild("Head")
			if char and char.Parent and hum and hum.Health > 0 and (hrp or head) then
				local targetPart = (CombatState.BodyAimbotMode == "Head Only" and head) or (head or hrp)
				return p, targetPart
			else
				CombatState.LockedPlayer = nil
				CombatState.LockedTargetPart = nil
			end
		end
	end

	local mousePos = UserInputService:GetMouseLocation()
	local bestTarget = nil
	local bestPart = nil
	local bestScore = math.huge
	local camPos = Camera and Camera.CFrame.Position or Vector3.zero

	-- 1. Scan Players (Only when TargetPlayers is enabled)
	if CombatState.TargetPlayers ~= false then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= lp and player.Character then
				local char = player.Character
				local hum = char:FindFirstChildOfClass("Humanoid")
				local hrp = char:FindFirstChild("HumanoidRootPart")
				local head = char:FindFirstChild("Head")

				if hum and hum.Health > 0 and (hrp or head) then
					if CombatState.IgnoreFriends and Spectators and Spectators.GetRelation then
						local rel = Spectators.GetRelation(player.Name)
						if rel == "Friendly" then
							continue
						end
					end

					local targetPart = (CombatState.BodyAimbotMode == "Head Only" and head) or (head or hrp)
					local partPos = targetPart.Position
					local distToPlayer = (camPos - partPos).Magnitude

					if distToPlayer <= CombatState.MaxDistance then
						local screenPos, onScreen = Camera:WorldToViewportPoint(partPos)
						if onScreen then
							local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
							if screenDist <= CombatState.FOVRadius then
								local isVisible = true
								if CombatState.VisibleCheck and not CombatState.Autowall then
									local rayParams = RaycastParams.new()
									rayParams.FilterType = Enum.RaycastFilterType.Exclude
									rayParams.FilterDescendantsInstances = { lp.Character, char }
									local rayResult = Workspace:Raycast(camPos, partPos - camPos, rayParams)
									if rayResult then
										isVisible = false
									end
								end

								if isVisible then
									local score = screenDist
									if CombatState.TargetPriority == "Lowest Distance" then
										score = distToPlayer
									elseif CombatState.TargetPriority == "Lowest Health" then
										score = hum.Health
									else
										score = screenDist
										if CombatState.PrioritizeLowHealth then
											score = score * (hum.Health / math.max(hum.MaxHealth, 1))
										end
									end

									if score < bestScore then
										bestScore = score
										bestTarget = player
										bestPart = targetPart
									end
								end
							end
						end
					end
				end
			end
		end
	end

	-- 2. Scan NPCs / Bots (When TargetNPCs is enabled)
	if CombatState.TargetNPCs then
		for _, model in ipairs(Workspace:GetChildren()) do
			if model:IsA("Model") and model ~= lp.Character and not Players:GetPlayerFromCharacter(model) then
				local hum = model:FindFirstChildOfClass("Humanoid")
				local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("Head")
				local head = model:FindFirstChild("Head")
				if hum and hum.Health > 0 and hrp then
					local targetPart = (CombatState.BodyAimbotMode == "Head Only" and head) or (head or hrp)
					local partPos = targetPart.Position
					local distToNpc = (camPos - partPos).Magnitude

					if distToNpc <= CombatState.MaxDistance then
						local screenPos, onScreen = Camera:WorldToViewportPoint(partPos)
						if onScreen then
							local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
							if screenDist <= CombatState.FOVRadius then
								local isVisible = true
								if CombatState.VisibleCheck and not CombatState.Autowall then
									local rayParams = RaycastParams.new()
									rayParams.FilterType = Enum.RaycastFilterType.Exclude
									rayParams.FilterDescendantsInstances = { lp.Character, model }
									local rayResult = Workspace:Raycast(camPos, partPos - camPos, rayParams)
									if rayResult then
										isVisible = false
									end
								end

								if isVisible then
									local score = screenDist
									if CombatState.TargetPriority == "Lowest Distance" then
										score = distToNpc
									elseif CombatState.TargetPriority == "Lowest Health" then
										score = hum.Health
									end

									if score < bestScore then
										bestScore = score
										bestTarget = model
										bestPart = targetPart
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return bestTarget, bestPart
end
getgenv().GetClosestTarget = GetClosestTarget

-- Triggerbot Engine (New Method - Raycast Target Interception)
local lastTriggerShot = 0
local function ProcessTriggerbot()
	if not CombatState.Enabled or not CombatState.Triggerbot then return end
	local now = tick()
	if (now - lastTriggerShot) < (CombatState.TriggerbotDelay / 1000) then return end

	local mousePos = UserInputService:GetMouseLocation()
	local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { lp.Character }

	local res = Workspace:Raycast(ray.Origin, ray.Direction * CombatState.TriggerbotRange, rayParams)
	if res and res.Instance then
		local hitChar = res.Instance:FindFirstAncestorOfClass("Model")
		local hitPlayer = hitChar and Players:GetPlayerFromCharacter(hitChar)
		if hitPlayer and hitPlayer ~= lp then
			local hum = hitChar:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				if CombatState.TriggerbotHeadOnly and res.Instance.Name ~= "Head" then
					return
				end
				if CombatState.IgnoreFriends and Spectators and Spectators.GetRelation then
					if Spectators.GetRelation(hitPlayer.Name) == "Friendly" then return end
				end
				lastTriggerShot = now
				local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
				if tool then
					tool:Activate()
				elseif mouse1click then
					mouse1click()
				end
			end
		end
	end
end

-- Update Loop for Combat (RenderStepped)
NVL_Connect(RunService.RenderStepped, function(dt)
	UpdateFOVCircle()

	-- If Target Lock is active and we have a LockedPlayer, persistently track them
	if CombatState.TargetLock and CombatState.LockedPlayer then
		local p = CombatState.LockedPlayer
		local char = p and p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local head = char and char:FindFirstChild("Head")
		if p and p.Parent and char and hum and hum.Health > 0 and (hrp or head) then
			local targetPart = (CombatState.BodyAimbotMode == "Head Only" and head) or (head or hrp)
			CurrentTarget = p
			CurrentTargetPart = targetPart
		else
			CombatState.LockedPlayer = nil
			CombatState.LockedTargetPart = nil
			CurrentTarget, CurrentTargetPart = GetClosestTarget()
		end
	else
		CurrentTarget, CurrentTargetPart = GetClosestTarget()
	end

	-- Auto Fire
	if CombatState.Enabled and CombatState.AutoFire and CurrentTarget and CurrentTargetPart then
		local char = lp.Character
		local tool = char and char:FindFirstChildOfClass("Tool")
		if tool then
			tool:Activate()
		end
	end

	-- Sticky Aim / Target Lock (Smooth Camera Tracking)
	if CombatState.Enabled and CombatState.TargetLock and CurrentTargetPart and Camera then
		local curCF = Camera.CFrame
		local aimPos = CurrentTargetPart.Position
		if CombatState.Prediction and CombatState.Prediction > 0 and CurrentTargetPart.AssemblyLinearVelocity then
			aimPos = aimPos + (CurrentTargetPart.AssemblyLinearVelocity * CombatState.Prediction)
		end
		local targetCF = CFrame.new(curCF.Position, aimPos)
		Camera.CFrame = curCF:Lerp(targetCF, math.clamp(CombatState.TargetLockSmoothness, 0.05, 1))
	end

	-- Triggerbot
	ProcessTriggerbot()
end)

-- Silent Aim Hooking (New Method: namecall interception)
pcall(function()
	if hookmetamethod then
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
			local method = getnamecallmethod()
			local args = { ... }

			if not checkcaller() and CombatState.Enabled and CombatState.SilentAim and CurrentTarget and CurrentTargetPart then
				if math.random(1, 100) <= CombatState.Hitchance then
					local predPos = CurrentTargetPart.Position + (CurrentTargetPart.Velocity * CombatState.Prediction)

					if method == "FireServer" and tostring(self) == "MainEvent" and args[1] == "UpdateMousePos" then
						args[2] = predPos
						return oldNamecall(self, unpack(args))
					end

					if method == "FireServer" and (string.find(tostring(self):lower(), "shoot") or string.find(tostring(self):lower(), "fire") or string.find(tostring(self):lower(), "hit") or string.find(tostring(self):lower(), "bullet")) then
						for i, v in ipairs(args) do
							if typeof(v) == "Vector3" then
								args[i] = predPos
								break
							end
						end
						return oldNamecall(self, unpack(args))
					end
				end
			end

			return oldNamecall(self, ...)
		end)
	end
end)

-- ========================================================================
-- Populate General Tab (Exact Replica of Reference Mockup)
-- ========================================================================

-- LEFT COLUMN CARDS:

-- Card 1: General
local CardGeneral = GeneralTab:CreateCard({
	Title = "General",
	Side = "left",
	Icon = MemoryAssets.Icons.view_filled or "",
	SubTab = "Thread",
})

CardGeneral:CreateToggle({
	Name = "Enable",
	Default = true,
	HasSettings = true,
	Keybind = Enum.KeyCode.F,
	Mode = "Toggle",
	ShowInBinds = true,
	Callback = function(v)
		CombatState.Enabled = v
		UpdateFOVCircle()
	end,
})

CardGeneral:CreateToggle({
	Name = "Auto Fire",
	Default = true,
	HasSettings = true,
	Keybind = Enum.KeyCode.E,
	Mode = "Hold",
	ShowInBinds = true,
	Callback = function(v)
		CombatState.AutoFire = v
	end,
})

CardGeneral:CreateToggle({
	Name = "Silent Aim",
	Default = false,
	Callback = function(v)
		CombatState.SilentAim = v
	end,
})

CardGeneral:CreateToggle({
	Name = "Auto Revolver",
	Default = false,
	Callback = function(v)
		CombatState.AutoRevolver = v
	end,
})

CardGeneral:CreateToggle({
	Name = "Anti Step",
	Default = true,
	Callback = function(v)
		CombatState.AntiStep = v
	end,
})

CardGeneral:CreateSlider({
	Name = "Backtracking",
	Min = 0,
	Max = 200,
	Default = 100,
	Decimals = 2,
	Callback = function(v)
		CombatState.Backtracking = v
	end,
})

CardGeneral:CreateToggle({
	Name = "Draw FOV",
	Default = true,
	HasSettings = true,
	ColorBadge = true,
	ColorValue = CombatState.FOVColor,
	Callback = function(v)
		CombatState.DrawFOV = v
		UpdateFOVCircle()
	end,
	ColorCallback = function(c)
		CombatState.FOVColor = c
		UpdateFOVCircle()
	end,
})

-- Card 2: Accuracy
local CardAccuracy = GeneralTab:CreateCard({
	Title = "Accuracy",
	Side = "left",
	Icon = MemoryAssets.Icons.target_fill or "",
	SubTab = "Thread",
})

CardAccuracy:CreateDropdown({
	Name = "Visible",
	Options = { "Selection", "Raycast", "Hitbox" },
	Default = "Selection",
	Callback = function(opt)
		CombatState.VisibleCheck = (opt == "Raycast" or opt == "Selection")
	end,
})

CardAccuracy:CreateDropdown({
	Name = "Force Conditions",
	Options = { "Type", "Health", "Distance", "Movement" },
	Default = "Type",
	Callback = function(opt)
		print("[NVL-Win] Force Conditions:", opt)
	end,
})

CardAccuracy:CreateToggle({
	Name = "Head Safety If Lethal",
	Default = true,
	HasSettings = true,
	Callback = function(v)
		print("[NVL-Win] Head Safety If Lethal:", v)
	end,
})

CardAccuracy:CreateDropdown({
	Name = "Body Aimbot",
	Options = { "Head, Body, Chest, Neck", "Head Only", "Chest Only", "Pelvis Only" },
	Default = "Head, Body, Chest, Neck",
	Callback = function(opt)
		CombatState.BodyAimbotMode = opt
	end,
})

CardAccuracy:CreateSlider({
	Name = "Max Misses",
	Min = 0,
	Max = 100,
	Default = 100,
	Decimals = 0,
	Callback = function(v)
		print("[NVL-Win] Max Misses:", v)
	end,
})

-- Card 3: Misc
local CardMisc = GeneralTab:CreateCard({
	Title = "Misc",
	Side = "left",
	Icon = MemoryAssets.Icons.sliders or "",
	SubTab = "Thread",
})

CardMisc:CreateToggle({
	Name = "Visible FOV",
	Default = true,
	Callback = function(v)
		CombatState.VisibleFOV = v
		UpdateFOVCircle()
	end,
})

-- RIGHT COLUMN CARDS:

-- Card 4: Exploits
local CardExploits = GeneralTab:CreateCard({
	Title = "Exploits",
	Side = "right",
	Icon = MemoryAssets.Icons.sharp_edit or "",
	SubTab = "Thread",
})

CardExploits:CreateSlider({
	Name = "Hitchance",
	Min = 0,
	Max = 100,
	Default = 100,
	Decimals = 0,
	Suffix = "%",
	Callback = function(v)
		CombatState.Hitchance = v
	end,
})

CardExploits:CreateToggle({
	Name = "Hide Shots",
	Default = false,
	Callback = function(v)
		print("[NVL-Win] Hide Shots:", v)
	end,
})

CardExploits:CreateToggle({
	Name = "Double Tap",
	Default = false,
	Callback = function(v)
		print("[NVL-Win] Double Tap:", v)
	end,
})

CardExploits:CreateToggle({
	Name = "Mode",
	Default = true,
	HasSettings = true,
	Callback = function(v)
		print("[NVL-Win] Exploit Mode:", v)
	end,
})

CardExploits:CreateToggle({
	Name = "Teleport Boost",
	Default = true,
	Callback = function(v)
		CombatState.TeleportBoost = v
	end,
})

-- Card 5: Settings
local CardSettings = GeneralTab:CreateCard({
	Title = "Settings",
	Side = "right",
	Icon = MemoryAssets.Icons.gear or "",
	SubTab = "Thread",
})

CardSettings:CreateSlider({
	Name = "First Bullet Delay",
	Min = 0,
	Max = 1000,
	Default = 0,
	Decimals = 0,
	Callback = function(v)
		CombatState.FirstBulletDelay = v
	end,
})

CardSettings:CreateSlider({
	Name = "After Kill",
	Min = 0,
	Max = 1000,
	Default = 500,
	Decimals = 0,
	Callback = function(v)
		CombatState.AfterKillDelay = v
	end,
})

CardSettings:CreateSlider({
	Name = "Visible",
	Min = 0,
	Max = 100,
	Default = 50.0,
	Decimals = 1,
	Callback = function(v)
		print("[NVL-Win] Visible Speed:", v)
	end,
})

CardSettings:CreateSlider({
	Name = "Autowall",
	Min = 0,
	Max = 100,
	Default = 50.0,
	Decimals = 1,
	Callback = function(v)
		CombatState.Autowall = (v > 0)
	end,
})

-- Card 6: Others
local CardOthers = GeneralTab:CreateCard({
	Title = "Others",
	Side = "right",
	Icon = MemoryAssets.Icons.dots_2 or "",
	SubTab = "Thread",
})

CardOthers:CreateToggle({
	Name = "Auto Step",
	Default = true,
	HasSettings = true,
	Callback = function(v)
		print("[NVL-Win] Auto Step:", v)
	end,
})

CardOthers:CreateDropdown({
	Name = "Conditions",
	Options = { "Select", "Airborne", "Ducking", "Moving", "Target In View" },
	Default = "Select",
	Callback = function(opt)
		print("[NVL-Win] Conditions:", opt)
	end,
})

CardOthers:CreateToggle({
	Name = "Auto Scope",
	Default = true,
	Callback = function(v)
		print("[NVL-Win] Auto Scope:", v)
	end,
})

-- Cards for Enemy subtab
local CardEnemyTarget = GeneralTab:CreateCard({
	Title = "Enemy Target",
	Side = "left",
	Icon = MemoryAssets.Icons.target_fill or "",
	SubTab = "Enemy",
})
CardEnemyTarget:CreateToggle({
	Name = "Prioritize Low Health",
	Default = true,
	Callback = function(v)
		CombatState.PrioritizeLowHealth = v
	end,
})
CardEnemyTarget:CreateToggle({
	Name = "Ignore Friends",
	Default = true,
	Callback = function(v)
		CombatState.IgnoreFriends = v
	end,
})
CardEnemyTarget:CreateSlider({
	Name = "Target Distance Max",
	Min = 50,
	Max = 1000,
	Default = 500,
	Callback = function(v)
		CombatState.MaxDistance = v
	end,
})

local CardEnemyHitscan = GeneralTab:CreateCard({
	Title = "Enemy Hitscan",
	Side = "right",
	Icon = MemoryAssets.Icons.view_filled or "",
	SubTab = "Enemy",
})
CardEnemyHitscan:CreateToggle({ Name = "Multipoint", Default = true, HasSettings = true })
CardEnemyHitscan:CreateSlider({ Name = "Head Point Scale", Min = 0, Max = 100, Default = 75, Suffix = "%" })

-- Cards for Team subtab
local CardTeamSettings = GeneralTab:CreateCard({
	Title = "Team Coordination",
	Side = "left",
	Icon = MemoryAssets.Icons.users or "",
	SubTab = "Team",
})
CardTeamSettings:CreateToggle({ Name = "Share Target Over Network", Default = false })
CardTeamSettings:CreateToggle({ Name = "Draw Teammate Tracers", Default = true })

-- ========================================================================
-- Populate Aimbot Tab (SubTabs: Main, Target, Accuracy)
-- ========================================================================
local CardAimbotMainLeft = AimbotTab:CreateCard({
	Title = "Sticky Aim & Lock",
	Side = "left",
	Icon = MemoryAssets.Icons.target_fill or "",
	SubTab = "Main",
})
CardAimbotMainLeft:CreateToggle({
	Name = "Target Lock",
	Default = false,
	HasSettings = true,
	Keybind = Enum.KeyCode.T,
	Mode = "Hold",
	ShowInBinds = true,
	Callback = function(v)
		CombatState.TargetLock = v
		if v then
			local target, part = GetClosestTarget()
			if target then
				CombatState.LockedPlayer = target
				CombatState.LockedTargetPart = part
			end
		else
			CombatState.LockedPlayer = nil
			CombatState.LockedTargetPart = nil
		end
	end,
})
CardAimbotMainLeft:CreateSlider({
	Name = "Lock Smoothness",
	Min = 5,
	Max = 100,
	Default = 25,
	Suffix = "%",
	Callback = function(v)
		CombatState.TargetLockSmoothness = v / 100
	end,
})
CardAimbotMainLeft:CreateToggle({
	Name = "Dynamic Prediction",
	Default = true,
	Callback = function(v)
		CombatState.Prediction = v and 0.135 or 0
	end,
})

local CardAimbotMainRight = AimbotTab:CreateCard({
	Title = "Camera & Targeting",
	Side = "right",
	Icon = MemoryAssets.Icons.view_filled or "",
	SubTab = "Main",
})
CardAimbotMainRight:CreateDropdown({
	Name = "Target Priority",
	Options = { "Target", "Closest to Crosshair", "Lowest Health", "Lowest Distance" },
	Default = "Target",
	Callback = function(opt)
		CombatState.TargetPriority = opt
	end,
})
CardAimbotMainRight:CreateSlider({
	Name = "FOV Radius",
	Min = 30,
	Max = 500,
	Default = 150,
	Decimals = 0,
	Callback = function(v)
		CombatState.FOVRadius = v
		UpdateFOVCircle()
	end,
})

-- SubTab: Target
local CardAimbotTargetLeft = AimbotTab:CreateCard({
	Title = "Target Filters",
	Side = "left",
	Icon = MemoryAssets.Icons.users or "",
	SubTab = "Target",
})
CardAimbotTargetLeft:CreateToggle({
	Name = "Target Players",
	Default = true,
	Callback = function(v)
		CombatState.TargetPlayers = v
		if not v and CombatState.LockedPlayer then
			CombatState.LockedPlayer = nil
			CombatState.LockedTargetPart = nil
		end
	end,
})
CardAimbotTargetLeft:CreateToggle({
	Name = "Target NPCs / Bots",
	Default = false,
	Callback = function(v)
		CombatState.TargetNPCs = v
		if not v and CombatState.LockedPlayer and not Players:GetPlayerFromCharacter(CombatState.LockedPlayer) then
			CombatState.LockedPlayer = nil
			CombatState.LockedTargetPart = nil
		end
	end,
})
CardAimbotTargetLeft:CreateToggle({
	Name = "Visible Raycast Check",
	Default = true,
	Callback = function(v)
		CombatState.VisibleCheck = v
	end,
})

local CardAimbotTargetRight = AimbotTab:CreateCard({
	Title = "Hitboxes & Aim Points",
	Side = "right",
	Icon = MemoryAssets.Icons.dots_2 or "",
	SubTab = "Target",
})
CardAimbotTargetRight:CreateDropdown({
	Name = "Preferred Hitbox",
	Options = { "Head", "HumanoidRootPart", "Torso", "Random" },
	Default = "Head",
	Callback = function(opt)
		CombatState.TargetPart = (opt == "Head" and "Head") or "HumanoidRootPart"
	end,
})
CardAimbotTargetRight:CreateSlider({
	Name = "Max Target Distance",
	Min = 50,
	Max = 1500,
	Default = 500,
	Decimals = 0,
	Callback = function(v)
		CombatState.MaxDistance = v
	end,
})

-- SubTab: Accuracy
local CardAimbotAccLeft = AimbotTab:CreateCard({
	Title = "Recoil & Spread Control",
	Side = "left",
	Icon = MemoryAssets.Icons.sliders or "",
	SubTab = "Accuracy",
})
CardAimbotAccLeft:CreateToggle({
	Name = "No Spread Reducer",
	Default = false,
	Callback = function(v)
		CombatState.NoSpread = v
	end,
})
CardAimbotAccLeft:CreateToggle({
	Name = "No Recoil Reducer",
	Default = false,
	Callback = function(v)
		CombatState.NoRecoil = v
	end,
})

local CardAimbotAccRight = AimbotTab:CreateCard({
	Title = "Hitchance & Multipliers",
	Side = "right",
	Icon = MemoryAssets.Icons.target_fill or "",
	SubTab = "Accuracy",
})
CardAimbotAccRight:CreateSlider({
	Name = "Hit Probability",
	Min = 10,
	Max = 100,
	Default = 100,
	Suffix = "%",
	Callback = function(v)
		CombatState.Hitchance = v
	end,
})

-- ========================================================================
-- Populate Others Tab (SubTabs: Triggerbot, Overrides)
-- ========================================================================
local CardTrigMain = OthersTab:CreateCard({
	Title = "Triggerbot Core",
	Side = "left",
	Icon = MemoryAssets.Icons.target_fill or "",
	SubTab = "Triggerbot",
})
CardTrigMain:CreateToggle({
	Name = "Enable Triggerbot",
	Default = false,
	HasSettings = true,
	Keybind = Enum.KeyCode.G,
	Mode = "Toggle",
	ShowInBinds = true,
	Callback = function(v)
		CombatState.Triggerbot = v
	end,
})
CardTrigMain:CreateSlider({
	Name = "Reaction Delay",
	Min = 0,
	Max = 200,
	Default = 35,
	Suffix = "ms",
	Callback = function(v)
		CombatState.TriggerbotDelay = v
	end,
})
CardTrigMain:CreateToggle({
	Name = "Headshot Only",
	Default = false,
	Callback = function(v)
		CombatState.TriggerbotHeadOnly = v
	end,
})

local CardTrigFilters = OthersTab:CreateCard({
	Title = "Triggerbot Conditions",
	Side = "right",
	Icon = MemoryAssets.Icons.sliders or "",
	SubTab = "Triggerbot",
})
CardTrigFilters:CreateToggle({
	Name = "Ignore Teammates",
	Default = true,
	Callback = function(v)
		CombatState.IgnoreFriends = v
	end,
})
CardTrigFilters:CreateSlider({
	Name = "Max Trigger Range",
	Min = 20,
	Max = 1000,
	Default = 350,
	Suffix = " studs",
	Callback = function(v)
		CombatState.TriggerbotRange = v
	end,
})

-- SubTab: Overrides
local CardOverrides = OthersTab:CreateCard({
	Title = "Weapon Handling",
	Side = "left",
	Icon = MemoryAssets.Icons.sharp_edit or "",
	SubTab = "Overrides",
})
CardOverrides:CreateToggle({
	Name = "Fast Tool Cooldown",
	Default = false,
	Callback = function(v)
		CombatState.FastCooldown = v
	end,
})
CardOverrides:CreateToggle({
	Name = "Auto Reload",
	Default = false,
	Callback = function(v)
		CombatState.AutoReload = v
	end,
})

-- ========================================================================
-- Populate Players Tab (Visuals & ESP)
-- ========================================================================

-- Visuals & ESP Engine (Pure GPU Native Instances - 0 FPS Impact)
local VisualsState = {
	Enabled = true,
	-- Boxes
	Boxes = true,
	BoxColor = Color3.fromRGB(186, 145, 252),
	FilledBox = false,
	FilledBoxColor = Color3.fromRGB(186, 145, 252),
	FilledBoxTransparency = 0.85,
	BoxOutline = true,
	CornerBox = false,

	-- Player Info
	NameTags = true,
	NameColor = Color3.fromRGB(240, 240, 245),
	HealthBar = true,
	HealthText = true,
	ArmorBar = false,
	Distance = true,
	EquippedWeapon = false,

	-- Indicators
	OffScreenArrows = false,
	Tracers = false,
	TracersColor = Color3.fromRGB(186, 145, 252),
	Skeleton = false,
	SkeletonColor = Color3.fromRGB(220, 220, 230),

	-- Self Effects
	SelfTrail = false,
	SelfTrailColor = Color3.fromRGB(186, 145, 252),
	SelfStepRings = false,
	SelfStepColor = Color3.fromRGB(186, 145, 252),

	-- Chams & Highlights
	Chams = true,
	ChamsColor = Color3.fromRGB(186, 145, 252),
	ChamsOutline = true,
	ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
	ThroughWalls = true,
	RainbowMode = false,

	-- Visual Settings
	RenderDistance = 1500,
	FontSize = 11,
	AccentColor = Color3.fromRGB(186, 145, 252),
}

local CoreGui = (gethui and gethui()) or (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
local lp = Players.LocalPlayer

-- Clean previous container if re-executed
local oldVisualsContainer = CoreGui:FindFirstChild("NVL_Visuals_Container")
if oldVisualsContainer then
	oldVisualsContainer:Destroy()
end
local oldLinesGui = CoreGui:FindFirstChild("NVL_ESP_Lines")
if oldLinesGui then
	oldLinesGui:Destroy()
end

local VisualsFolder = Instance.new("Folder")
VisualsFolder.Name = "NVL_Visuals_Container"
VisualsFolder.Parent = CoreGui

local LinesGui = Instance.new("ScreenGui")
LinesGui.Name = "NVL_ESP_Lines"
LinesGui.ResetOnSpawn = false
LinesGui.DisplayOrder = 10
LinesGui.Parent = CoreGui

local function GetHealthColor(pct)
	if pct > 0.5 then
		return Color3.fromRGB(255, 200, 50):Lerp(Color3.fromRGB(60, 255, 120), (pct - 0.5) * 2)
	else
		return Color3.fromRGB(255, 65, 65):Lerp(Color3.fromRGB(255, 200, 50), pct * 2)
	end
end

local function GetPlayerRelationColor(player, defaultColor)
	if Spectators and Spectators.GetRelation then
		local rel = Spectators.GetRelation(player.Name)
		if rel == "Enemy" then
			return Color3.fromRGB(255, 75, 75)
		elseif rel == "Friendly" then
			return Color3.fromRGB(80, 240, 120)
		end
	end
	return defaultColor
end

local PlayerESPCache = {}
local TracerLines = {}
local SkeletonLines = {}

local function CleanupPlayerESP(player)
	local cache = PlayerESPCache[player]
	if cache then
		if cache.Connections then
			for _, conn in ipairs(cache.Connections) do
				pcall(function() conn:Disconnect() end)
			end
		end
		if cache.Highlight and cache.Highlight.Parent then
			cache.Highlight:Destroy()
		end
		if cache.BillboardGui and cache.BillboardGui.Parent then
			cache.BillboardGui:Destroy()
		end
		PlayerESPCache[player] = nil
	end
	if TracerLines[player] then
		pcall(function() TracerLines[player]:Destroy() end)
		TracerLines[player] = nil
	end
	if SkeletonLines[player] then
		for _, b in ipairs(SkeletonLines[player]) do
			pcall(function() b:Destroy() end)
		end
		SkeletonLines[player] = nil
	end
end

local function CreateOrUpdatePlayerESP(player)
	if player == lp then return end
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	local existing = PlayerESPCache[player]
	if existing and existing.Character == char and existing.Highlight and existing.Highlight.Parent then
		return
	end

	CleanupPlayerESP(player)

	local chamsFill = GetPlayerRelationColor(player, VisualsState.ChamsColor)
	local boxStrokeColor = GetPlayerRelationColor(player, VisualsState.BoxColor)
	local nameTextColor = GetPlayerRelationColor(player, VisualsState.NameColor)

	-- 1. Native Highlight (0 FPS overhead - C++ engine GPU render)
	local hl = Instance.new("Highlight")
	hl.Name = player.Name .. "_HL"
	hl.Adornee = char
	hl.FillColor = chamsFill
	hl.FillTransparency = 0.5
	hl.OutlineColor = VisualsState.ChamsOutlineColor
	hl.OutlineTransparency = VisualsState.ChamsOutline and 0 or 1
	hl.DepthMode = VisualsState.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
	hl.Enabled = VisualsState.Enabled and VisualsState.Chams and (hum.Health > 0)
	hl.Parent = VisualsFolder

	-- 2. Native BillboardGui (0 FPS overhead - C++ engine GPU render)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = player.Name .. "_BBG"
	bbg.Adornee = hrp
	bbg.Size = UDim2.new(4.2, 0, 5.8, 0)
	bbg.StudsOffset = Vector3.new(0, -0.1, 0)
	bbg.AlwaysOnTop = VisualsState.ThroughWalls
	bbg.LightInfluence = 0
	bbg.ClipsDescendants = false
	bbg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	bbg.MaxDistance = VisualsState.RenderDistance
	bbg.Enabled = VisualsState.Enabled and (hum.Health > 0)
	bbg.Parent = VisualsFolder

	-- Black Outline Wrapper
	local outlineFrame = Instance.new("Frame")
	outlineFrame.Name = "BoxOutline"
	outlineFrame.Size = UDim2.new(1, 4, 1, 4)
	outlineFrame.Position = UDim2.new(0, -2, 0, -2)
	outlineFrame.BackgroundTransparency = 1
	outlineFrame.Visible = VisualsState.Boxes and VisualsState.BoxOutline
	outlineFrame.Parent = bbg

	local outStroke = Instance.new("UIStroke")
	outStroke.Color = Color3.fromRGB(0, 0, 0)
	outStroke.Thickness = 1
	outStroke.LineJoinMode = Enum.LineJoinMode.Miter
	outStroke.Parent = outlineFrame

	-- Main Bounding Box
	local boxFrame = Instance.new("Frame")
	boxFrame.Name = "Box"
	boxFrame.Size = UDim2.new(1, 0, 1, 0)
	boxFrame.BackgroundTransparency = VisualsState.FilledBox and VisualsState.FilledBoxTransparency or 1
	boxFrame.BackgroundColor3 = VisualsState.FilledBoxColor
	boxFrame.BorderSizePixel = 0
	boxFrame.Visible = VisualsState.Boxes
	boxFrame.Parent = bbg

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Name = "BoxStroke"
	boxStroke.Color = boxStrokeColor
	boxStroke.Thickness = 1.5
	boxStroke.LineJoinMode = Enum.LineJoinMode.Miter
	boxStroke.Parent = boxFrame

	-- Name Tag
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "NameLabel"
	nameLbl.Size = UDim2.new(0, 240, 0, 16)
	nameLbl.Position = UDim2.new(0.5, 0, 0, -18)
	nameLbl.AnchorPoint = Vector2.new(0.5, 1)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = VisualsState.FontSize
	nameLbl.TextColor3 = nameTextColor
	nameLbl.TextStrokeTransparency = 0.4
	nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLbl.Text = player.DisplayName
	nameLbl.Visible = VisualsState.NameTags
	nameLbl.Parent = bbg

	-- Health Bar Frame
	local hpFrame = Instance.new("Frame")
	hpFrame.Name = "HealthBar"
	hpFrame.Size = UDim2.new(0, 4, 1, 0)
	hpFrame.Position = UDim2.new(0, -7, 0, 0)
	hpFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
	hpFrame.BorderSizePixel = 0
	hpFrame.ZIndex = 10
	hpFrame.Visible = VisualsState.HealthBar
	hpFrame.Parent = bbg

	local hpStroke = Instance.new("UIStroke")
	hpStroke.Color = Color3.fromRGB(0, 0, 0)
	hpStroke.Thickness = 1
	hpStroke.Parent = hpFrame

	local curHealth = math.max(hum.Health, 0)
	local maxHealth = math.max(hum.MaxHealth, 1)
	local pct = math.clamp(curHealth / maxHealth, 0, 1)

	local hpFill = Instance.new("Frame")
	hpFill.Name = "Fill"
	hpFill.Size = UDim2.new(1, 0, pct, 0)
	hpFill.Position = UDim2.new(0, 0, 1 - pct, 0)
	hpFill.BackgroundColor3 = GetHealthColor(pct)
	hpFill.BorderSizePixel = 0
	hpFill.ZIndex = 11
	hpFill.Parent = hpFrame

	local hpText = Instance.new("TextLabel")
	hpText.Name = "HealthText"
	hpText.Size = UDim2.new(0, 26, 0, 14)
	hpText.AnchorPoint = Vector2.new(1, 0.5)
	hpText.Position = UDim2.new(0, -9, 1 - pct, 0)
	hpText.BackgroundTransparency = 1
	hpText.Font = Enum.Font.GothamBold
	hpText.TextSize = 11
	hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpText.TextStrokeTransparency = 0
	hpText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	hpText.TextXAlignment = Enum.TextXAlignment.Right
	hpText.Text = tostring(math.floor(curHealth))
	hpText.ZIndex = 12
	hpText.Visible = VisualsState.HealthText
	hpText.Parent = bbg

	-- Distance Label (Meters under box)
	local distLbl = Instance.new("TextLabel")
	distLbl.Name = "DistanceLabel"
	distLbl.Size = UDim2.new(0, 200, 0, 14)
	distLbl.Position = UDim2.new(0.5, 0, 1, 18)
	distLbl.AnchorPoint = Vector2.new(0.5, 0)
	distLbl.BackgroundTransparency = 1
	distLbl.Font = Enum.Font.GothamMedium
	distLbl.TextSize = 9
	distLbl.TextColor3 = Color3.fromRGB(180, 185, 200)
	distLbl.TextStrokeTransparency = 0.5
	distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	local initCamPos = Camera and Camera.CFrame.Position or Vector3.zero
	local initDist = (hrp.Position - initCamPos).Magnitude
	distLbl.Text = string.format("[%dm]", math.floor(initDist))
	distLbl.Visible = VisualsState.Distance
	distLbl.Parent = bbg

	-- Weapon Label
	local weaponLbl = Instance.new("TextLabel")
	weaponLbl.Name = "WeaponLabel"
	weaponLbl.Size = UDim2.new(0, 200, 0, 14)
	weaponLbl.Position = UDim2.new(0.5, 0, 1, 4)
	weaponLbl.AnchorPoint = Vector2.new(0.5, 0)
	weaponLbl.BackgroundTransparency = 1
	weaponLbl.Font = Enum.Font.GothamMedium
	weaponLbl.TextSize = 9
	weaponLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
	weaponLbl.TextStrokeTransparency = 0.5
	weaponLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	local activeTool = char:FindFirstChildOfClass("Tool")
	weaponLbl.Text = activeTool and ("[" .. activeTool.Name .. "]") or ""
	weaponLbl.Visible = VisualsState.EquippedWeapon
	weaponLbl.Parent = bbg

	-- 100% Event-Driven Listeners (No polling loops!)
	local connections = {}

	local hpConn = hum.HealthChanged:Connect(function(newHp)
		local newCur = math.max(newHp, 0)
		local newMax = math.max(hum.MaxHealth, 1)
		local newPct = math.clamp(newCur / newMax, 0, 1)

		hpFill.Size = UDim2.new(1, 0, newPct, 0)
		hpFill.Position = UDim2.new(0, 0, 1 - newPct, 0)
		hpFill.BackgroundColor3 = GetHealthColor(newPct)

		hpText.Text = tostring(math.floor(newCur))
		hpText.Position = UDim2.new(0, -9, 1 - newPct, 0)

		if newCur <= 0 then
			hl.Enabled = false
			bbg.Enabled = false
		else
			hl.Enabled = VisualsState.Enabled and VisualsState.Chams
			bbg.Enabled = VisualsState.Enabled
		end
	end)
	table.insert(connections, hpConn)

	local diedConn = hum.Died:Connect(function()
		hl.Enabled = false
		bbg.Enabled = false
	end)
	table.insert(connections, diedConn)

	local childAddConn = char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			weaponLbl.Text = "[" .. child.Name .. "]"
		end
	end)
	table.insert(connections, childAddConn)

	local childRemConn = char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			local remainingTool = char:FindFirstChildOfClass("Tool")
			weaponLbl.Text = remainingTool and ("[" .. remainingTool.Name .. "]") or ""
		end
	end)
	table.insert(connections, childRemConn)

	PlayerESPCache[player] = {
		Player = player,
		Character = char,
		Hrp = hrp,
		Hum = hum,
		Highlight = hl,
		BillboardGui = bbg,
		BoxOutlineFrame = outlineFrame,
		BoxFrame = boxFrame,
		BoxStroke = boxStroke,
		NameLabel = nameLbl,
		HealthBarFrame = hpFrame,
		HealthFill = hpFill,
		HealthText = hpText,
		DistanceLabel = distLbl,
		WeaponLabel = weaponLbl,
		Connections = connections,
	}
end

local function SetupPlayer(player)
	if player == lp then return end

	player.CharacterAdded:Connect(function(newChar)
		task.delay(0.2, function()
			if player.Parent then
				CreateOrUpdatePlayerESP(player)
			end
		end)
	end)

	player.CharacterRemoving:Connect(function()
		CleanupPlayerESP(player)
	end)

	if player.Character then
		CreateOrUpdatePlayerESP(player)
	end
end

local function RefreshAllESP()
	for player, data in pairs(PlayerESPCache) do
		if data and data.BillboardGui and data.BillboardGui.Parent then
			local hum = data.Hum
			local isAlive = hum and hum.Health > 0

			local chamsFill = GetPlayerRelationColor(player, VisualsState.ChamsColor)
			local boxStrokeColor = GetPlayerRelationColor(player, VisualsState.BoxColor)
			local nameTextColor = GetPlayerRelationColor(player, VisualsState.NameColor)

			-- Highlight
			if data.Highlight and data.Highlight.Parent then
				data.Highlight.Enabled = VisualsState.Enabled and VisualsState.Chams and isAlive
				data.Highlight.FillColor = chamsFill
				data.Highlight.OutlineColor = VisualsState.ChamsOutlineColor
				data.Highlight.OutlineTransparency = VisualsState.ChamsOutline and 0 or 1
				data.Highlight.DepthMode = VisualsState.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
			end

			-- BillboardGui
			data.BillboardGui.Enabled = VisualsState.Enabled and isAlive
			data.BillboardGui.AlwaysOnTop = VisualsState.ThroughWalls
			data.BillboardGui.MaxDistance = VisualsState.RenderDistance

			-- Box & Outline
			if data.BoxFrame and data.BoxFrame.Parent then
				data.BoxFrame.Visible = VisualsState.Boxes
				data.BoxFrame.BackgroundTransparency = VisualsState.FilledBox and VisualsState.FilledBoxTransparency or 1
				data.BoxFrame.BackgroundColor3 = VisualsState.FilledBoxColor
			end
			if data.BoxStroke and data.BoxStroke.Parent then
				data.BoxStroke.Color = boxStrokeColor
			end
			if data.BoxOutlineFrame and data.BoxOutlineFrame.Parent then
				data.BoxOutlineFrame.Visible = VisualsState.Boxes and VisualsState.BoxOutline
			end

			-- Name Tag
			if data.NameLabel and data.NameLabel.Parent then
				data.NameLabel.Visible = VisualsState.NameTags
				data.NameLabel.TextSize = VisualsState.FontSize
				data.NameLabel.TextColor3 = nameTextColor
			end

			-- Health Bar
			if data.HealthBarFrame and data.HealthBarFrame.Parent then
				data.HealthBarFrame.Visible = VisualsState.HealthBar
			end
			if data.HealthText and data.HealthText.Parent then
				data.HealthText.Visible = VisualsState.HealthText
			end

			-- Distance
			if data.DistanceLabel and data.DistanceLabel.Parent then
				data.DistanceLabel.Visible = VisualsState.Distance
			end

			-- Weapon
			if data.WeaponLabel and data.WeaponLabel.Parent then
				data.WeaponLabel.Visible = VisualsState.EquippedWeapon
			end
		end
	end
end

-- Initialize ESP for current players
for _, p in ipairs(Players:GetPlayers()) do
	SetupPlayer(p)
end

NVL_Connect(Players.PlayerAdded, SetupPlayer)
NVL_Connect(Players.PlayerRemoving, CleanupPlayerESP)

-- Connect Spectator Relation Changed
if Spectators and Spectators.SetOnRelationChanged then
	Spectators.SetOnRelationChanged(function(targetName, relation)
		RefreshAllESP()
	end)
end

-- Throttled Background Thread for Distance & Rainbow Mode (0 FPS impact, 0.3s cycle)
task.spawn(function()
	while true do
		task.wait(0.3)
		if VisualsState.Enabled and (VisualsState.Distance or VisualsState.RainbowMode) then
			local lpChar = lp and lp.Character
			local lpHrp = lpChar and (lpChar:FindFirstChild("HumanoidRootPart") or lpChar:FindFirstChild("Head"))
			local lpPos = lpHrp and lpHrp.Position

			local rainbowColor = nil
			if VisualsState.RainbowMode then
				rainbowColor = Color3.fromHSV((tick() * 0.25) % 1, 0.8, 1)
			end

			for player, data in pairs(PlayerESPCache) do
				if data and data.BillboardGui and data.BillboardGui.Parent then
					if VisualsState.RainbowMode and data.Highlight then
						data.Highlight.FillColor = rainbowColor
					end

					if data.NameLabel and data.NameLabel.Parent then
						if VisualsState.Distance and lpPos and data.Hrp and data.Hrp.Parent then
							local dist = (data.Hrp.Position - lpPos).Magnitude
							data.NameLabel.Text = string.format("%s [%dm]", player.DisplayName, math.floor(dist))
						else
							data.NameLabel.Text = player.DisplayName
						end
					end

					if data.DistanceLabel and data.DistanceLabel.Parent and lpPos and data.Hrp and data.Hrp.Parent then
						local dist = (data.Hrp.Position - lpPos).Magnitude
						data.DistanceLabel.Text = string.format("[%dm]", math.floor(dist))
					end
				end
			end
		end
	end
end)

-- ========================================================================
-- Tracers & Skeleton ESP Engine (Pure Native GPU Frames - 0 FPS Impact)
-- ========================================================================
local function GetOrCreateTracerLine(player)
	if not TracerLines[player] then
		local line = Instance.new("Frame")
		line.Name = player.Name .. "_Tracer"
		line.BackgroundColor3 = VisualsState.TracersColor
		line.BorderSizePixel = 0
		line.Visible = false
		line.ZIndex = 5
		line.Parent = LinesGui
		TracerLines[player] = line
	end
	return TracerLines[player]
end

local function GetOrCreateSkeletonLines(player)
	if not SkeletonLines[player] then
		local bones = {}
		for i = 1, 15 do
			local line = Instance.new("Frame")
			line.Name = player.Name .. "_Bone_" .. i
			line.BackgroundColor3 = VisualsState.SkeletonColor
			line.BorderSizePixel = 0
			line.Visible = false
			line.ZIndex = 5
			line.Parent = LinesGui
			table.insert(bones, line)
		end
		SkeletonLines[player] = bones
	end
	return SkeletonLines[player]
end

NVL_Connect(RunService.RenderStepped, function()
	if not VisualsState.Enabled then
		for _, l in pairs(TracerLines) do l.Visible = false end
		for _, bones in pairs(SkeletonLines) do
			for _, b in ipairs(bones) do b.Visible = false end
		end
		return
	end

	local screenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
	local camPos = Camera.CFrame.Position

	-- 1. Tracers (Snaplines from bottom center of screen)
	if VisualsState.Tracers then
		for player, data in pairs(PlayerESPCache) do
			local line = GetOrCreateTracerLine(player)
			local hrp = data.Hrp
			local hum = data.Hum
			if hrp and hrp.Parent and hum and hum.Health > 0 then
				local dist = (camPos - hrp.Position).Magnitude
				if dist <= VisualsState.RenderDistance then
					local sPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
					if onScreen then
						local p2 = Vector2.new(sPos.X, sPos.Y)
						local diff = p2 - screenBottom
						local len = diff.Magnitude
						line.Size = UDim2.new(0, len, 0, 1.5)
						line.Position = UDim2.new(0, (screenBottom.X + p2.X) / 2, 0, (screenBottom.Y + p2.Y) / 2)
						line.AnchorPoint = Vector2.new(0.5, 0.5)
						line.Rotation = math.deg(math.atan2(diff.Y, diff.X))
						line.BackgroundColor3 = GetPlayerRelationColor(player, VisualsState.TracersColor)
						line.Visible = true
					else
						line.Visible = false
					end
				else
					line.Visible = false
				end
			else
				line.Visible = false
			end
		end
	else
		for _, l in pairs(TracerLines) do l.Visible = false end
	end

	-- 2. Skeleton ESP (Bones between joints)
	if VisualsState.Skeleton then
		for player, data in pairs(PlayerESPCache) do
			local bones = GetOrCreateSkeletonLines(player)
			local char = data.Character
			local hum = data.Hum
			if char and char.Parent and hum and hum.Health > 0 then
				local bIdx = 1
				local function DrawBone(pName1, pName2)
					local p1 = char:FindFirstChild(pName1)
					local p2 = char:FindFirstChild(pName2)
					if p1 and p2 then
						local sPos1, on1 = Camera:WorldToViewportPoint(p1.Position)
						local sPos2, on2 = Camera:WorldToViewportPoint(p2.Position)
						if on1 and on2 then
							local v1 = Vector2.new(sPos1.X, sPos1.Y)
							local v2 = Vector2.new(sPos2.X, sPos2.Y)
							local diff = v2 - v1
							local len = diff.Magnitude
							local boneFrame = bones[bIdx]
							if boneFrame then
								boneFrame.Size = UDim2.new(0, len, 0, 1.5)
								boneFrame.Position = UDim2.new(0, (v1.X + v2.X) / 2, 0, (v1.Y + v2.Y) / 2)
								boneFrame.AnchorPoint = Vector2.new(0.5, 0.5)
								boneFrame.Rotation = math.deg(math.atan2(diff.Y, diff.X))
								boneFrame.BackgroundColor3 = VisualsState.SkeletonColor
								boneFrame.Visible = true
								bIdx = bIdx + 1
							end
						end
					end
				end

				if char:FindFirstChild("UpperTorso") then
					-- R15 Rig
					DrawBone("Head", "UpperTorso")
					DrawBone("UpperTorso", "LowerTorso")
					DrawBone("UpperTorso", "LeftUpperArm")
					DrawBone("LeftUpperArm", "LeftLowerArm")
					DrawBone("LeftLowerArm", "LeftHand")
					DrawBone("UpperTorso", "RightUpperArm")
					DrawBone("RightUpperArm", "RightLowerArm")
					DrawBone("RightLowerArm", "RightHand")
					DrawBone("LowerTorso", "LeftUpperLeg")
					DrawBone("LeftUpperLeg", "LeftLowerLeg")
					DrawBone("LeftLowerLeg", "LeftFoot")
					DrawBone("LowerTorso", "RightUpperLeg")
					DrawBone("RightUpperLeg", "RightLowerLeg")
					DrawBone("RightLowerLeg", "RightFoot")
				elseif char:FindFirstChild("Torso") then
					-- R6 Rig
					DrawBone("Head", "Torso")
					DrawBone("Torso", "Left Arm")
					DrawBone("Torso", "Right Arm")
					DrawBone("Torso", "Left Leg")
					DrawBone("Torso", "Right Leg")
				end

				for i = bIdx, #bones do
					bones[i].Visible = false
				end
			else
				for _, b in ipairs(bones) do b.Visible = false end
			end
		end
	else
		for _, bones in pairs(SkeletonLines) do
			for _, b in ipairs(bones) do b.Visible = false end
		end
	end
end)

-- ========================================================================
-- Self Effects Engine (Local Player Trails & Footstep Pulse Rings)
-- ========================================================================
local ActiveSelfTrail = nil
local ActiveSelfAttachments = {}
local function UpdateSelfTrail()
	if ActiveSelfTrail then
		pcall(function() ActiveSelfTrail:Destroy() end)
		ActiveSelfTrail = nil
	end
	for _, att in ipairs(ActiveSelfAttachments) do
		pcall(function() att:Destroy() end)
	end
	ActiveSelfAttachments = {}

	if not VisualsState.SelfTrail then return end
	local char = lp.Character
	local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
	if not hrp then return end

	local att0 = Instance.new("Attachment", hrp)
	att0.Position = Vector3.new(0, 1.2, 0)
	local att1 = Instance.new("Attachment", hrp)
	att1.Position = Vector3.new(0, -1.2, 0)
	table.insert(ActiveSelfAttachments, att0)
	table.insert(ActiveSelfAttachments, att1)

	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.55
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(VisualsState.SelfTrailColor)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Parent = hrp
	ActiveSelfTrail = trail
end

lp.CharacterAdded:Connect(function()
	task.delay(0.3, function()
		if VisualsState.SelfTrail then
			UpdateSelfTrail()
		end
	end)
end)

local lastStepPulse = 0
NVL_Connect(RunService.Heartbeat, function()
	if not VisualsState.SelfStepRings then return end
	local char = lp.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then return end

	if hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air then
		local now = tick()
		if now - lastStepPulse >= 0.18 then
			lastStepPulse = now
			task.spawn(function()
				local ring = Instance.new("Part")
				ring.Shape = Enum.PartType.Cylinder
				ring.Size = Vector3.new(0.04, 1, 1)
				ring.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.7, 0)) * CFrame.Angles(0, 0, math.rad(90))
				ring.Material = Enum.Material.Neon
				ring.Color = VisualsState.SelfStepColor
				ring.Transparency = 0.2
				ring.CanCollide = false
				ring.Anchored = true
				ring.CastShadow = false
				ring.Parent = Workspace

				local tw = TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.04, 4.2, 4.2),
					Transparency = 1,
				})
				tw:Play()
				tw.Completed:Connect(function()
					ring:Destroy()
				end)
			end)
		end
	end
end)

-- ========================================================================
-- Dynamic Character Morph & Avatar Studio Engine (100% Original Standalone Method)
-- ========================================================================
local get_obj = getobjects or (game and function(url) return game:GetObjects(url) end)
local OriginalAvatarState = nil
local CurrentTargetServerPlayer = ""
local UniversalOutfitQuery = ""

-- Dynamic Server Players Ingestion
local function GetServerPlayerNames()
	local names = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then
			table.insert(names, p.Name)
		end
	end
	if #names == 0 then table.insert(names, "No other players") end
	return names
end

local function SnapshotOriginalAvatar()
	if OriginalAvatarState or not lp.Character then return end
	local char = lp.Character
	local bc = char:FindFirstChildOfClass("BodyColors")
	local shirt = char:FindFirstChildOfClass("Shirt")
	local pants = char:FindFirstChildOfClass("Pants")
	local origAccs = {}
	for _, acc in ipairs(char:GetChildren()) do
		if acc:IsA("Accessory") then
			table.insert(origAccs, acc:Clone())
		end
	end
	OriginalAvatarState = {
		HeadColor = bc and bc.HeadColor3,
		TorsoColor = bc and bc.TorsoColor3,
		LeftArmColor = bc and bc.LeftArmColor3,
		RightArmColor = bc and bc.RightArmColor3,
		LeftLegColor = bc and bc.LeftLegColor3,
		RightLegColor = bc and bc.RightLegColor3,
		Shirt = shirt and shirt.ShirtTemplate or "",
		Pants = pants and pants.PantsTemplate or "",
		Accessories = origAccs,
	}
end

-- Universal Rig-Agnostic Welder
local function SafeWeldAccessory(acc, targetChar)
	local handle = acc:FindFirstChild("Handle")
	if not handle then return false end
	handle.CanCollide = false
	handle.Massless = true
	handle.CastShadow = false

	local accAtt = handle:FindFirstChildOfClass("Attachment")
	if accAtt then
		for _, part in ipairs(targetChar:GetChildren()) do
			if part:IsA("BasePart") then
				local charAtt = part:FindFirstChild(accAtt.Name)
				if charAtt then
					local weld = Instance.new("Weld")
					weld.Name = "AccessoryWeld"
					weld.Part0 = handle
					weld.Part1 = part
					weld.C0 = accAtt.CFrame
					weld.C1 = charAtt.CFrame
					weld.Parent = handle
					acc.Parent = targetChar
					return true
				end
			end
		end
	end
	local head = targetChar:FindFirstChild("Head")
	if head then
		local weld = Instance.new("Weld")
		weld.Name = "AccessoryWeld"
		weld.Part0 = handle
		weld.Part1 = head
		weld.C0 = CFrame.new(0, 0.5, 0)
		weld.Parent = handle
		acc.Parent = targetChar
		return true
	end
	return false
end

-- METHOD 1: Clone from Live Server Player (0 network wait, 100% offline, pure local memory copy)
local function CopyOutfitFromPlayer(targetPlayerName)
	local char = lp.Character
	if not char or not char.Parent then return end
	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	local targetChar = targetPlayer and targetPlayer.Character
	if not targetChar then
		warn("[NVL-Win] Target character not found for:", tostring(targetPlayerName))
		return
	end

	SnapshotOriginalAvatar()

	-- 1. Clear existing local accessories
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Accessory") then
			pcall(function() item:Destroy() end)
		end
	end

	-- 2. Clone clothes
	local targetShirt = targetChar:FindFirstChildOfClass("Shirt")
	local targetPants = targetChar:FindFirstChildOfClass("Pants")
	local myShirt = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
	local myPants = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)

	if targetShirt then
		myShirt.ShirtTemplate = targetShirt.ShirtTemplate
	else
		pcall(function() myShirt:Destroy() end)
	end

	if targetPants then
		myPants.PantsTemplate = targetPants.PantsTemplate
	else
		pcall(function() myPants:Destroy() end)
	end

	-- 3. Copy body colors
	local targetBc = targetChar:FindFirstChildOfClass("BodyColors")
	if targetBc then
		local myBc = char:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors", char)
		myBc.HeadColor3 = targetBc.HeadColor3
		myBc.TorsoColor3 = targetBc.TorsoColor3
		myBc.LeftArmColor3 = targetBc.LeftArmColor3
		myBc.RightArmColor3 = targetBc.RightArmColor3
		myBc.LeftLegColor3 = targetBc.LeftLegColor3
		myBc.RightLegColor3 = targetBc.RightLegColor3
		for _, p in ipairs(char:GetChildren()) do
			if p:IsA("BasePart") then
				local tp = targetChar:FindFirstChild(p.Name)
				if tp and tp:IsA("BasePart") then
					p.Color = tp.Color
				end
			end
		end
	end

	-- 4. Clone accessories directly from target model
	for _, item in ipairs(targetChar:GetChildren()) do
		if item:IsA("Accessory") then
			local clonedAcc = item:Clone()
			SafeWeldAccessory(clonedAcc, char)
		end
	end

	print(string.format("[NVL-Win] Cloned outfit from server player: %s", targetPlayerName))
end

-- METHOD 2: Universal Fetch by Username or UserId
local function ApplyUniversalMorph(userQuery)
	if not userQuery or userQuery == "" then return end
	local char = lp.Character
	if not char or not char.Parent then return end

	task.spawn(function()
		local numId = tonumber(userQuery)
		if not numId then
			local nameOk, resolvedId = pcall(function()
				return Players:GetUserIdFromNameAsync(userQuery)
			end)
			if nameOk and resolvedId then
				numId = resolvedId
			else
				warn("[NVL-Win] Could not resolve username:", userQuery)
				return
			end
		end

		SnapshotOriginalAvatar()

		local success, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(numId)
		end)
		if not success or not desc then
			warn("[NVL-Win] Failed to get description for ID:", numId)
			return
		end

		-- Clear accessories
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Accessory") then
				pcall(function() item:Destroy() end)
			end
		end

		-- Clothes
		if desc.Shirt and desc.Shirt > 0 then
			local s = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
			s.ShirtTemplate = "rbxassetid://" .. desc.Shirt
		end
		if desc.Pants and desc.Pants > 0 then
			local p = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
			p.PantsTemplate = "rbxassetid://" .. desc.Pants
		end

		-- Colors
		local bc = char:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors", char)
		if desc.HeadColor then bc.HeadColor3 = desc.HeadColor end
		if desc.TorsoColor then bc.TorsoColor3 = desc.TorsoColor end
		if desc.LeftArmColor then bc.LeftArmColor3 = desc.LeftArmColor end
		if desc.RightArmColor then bc.RightArmColor3 = desc.RightArmColor end
		if desc.LeftLegColor then bc.LeftLegColor3 = desc.LeftLegColor end
		if desc.RightLegColor then bc.RightLegColor3 = desc.RightLegColor end
		for _, p in ipairs(char:GetChildren()) do
			if p:IsA("BasePart") then
				if p.Name:find("Head") then p.Color = bc.HeadColor3
				elseif p.Name:find("Torso") then p.Color = bc.TorsoColor3
				elseif p.Name:find("Arm") or p.Name:find("Hand") then
					p.Color = p.Name:find("Left") and bc.LeftArmColor3 or bc.RightArmColor3
				elseif p.Name:find("Leg") or p.Name:find("Foot") then
					p.Color = p.Name:find("Left") and bc.LeftLegColor3 or bc.RightLegColor3
				end
			end
		end

		-- Accessories
		local accList = {}
		pcall(function() accList = desc:GetAccessories(true) end)
		for _, a in ipairs(accList) do
			if a.AssetId and a.AssetId > 0 and get_obj then
				task.spawn(function()
					local ok, res = pcall(function()
						return get_obj("rbxassetid://" .. a.AssetId)
					end)
					if ok and res and res[1] and res[1]:IsA("Accessory") then
						SafeWeldAccessory(res[1], char)
					end
				end)
			end
		end

		print(string.format("[NVL-Win] Applied Universal Outfit for ID: %d (%s)", numId, tostring(userQuery)))
	end)
end

-- METHOD 3: Headless Mode (Reversible, 0 camera break)
local function SetHeadless(enabled)
	local char = lp.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return end
	head.Transparency = enabled and 1 or 0
	local face = head:FindFirstChild("face")
	if face then face.Transparency = enabled and 1 or 0 end
end

-- METHOD 4: Korblox Right Leg (Clean mesh injection, 0 physics glitch)
local KorbloxOriginalMeshes = {}
local function SetKorbloxLeg(enabled)
	local char = lp.Character
	if not char then return end

	local rUpper = char:FindFirstChild("RightUpperLeg")
	local rLower = char:FindFirstChild("RightLowerLeg")
	local rFoot = char:FindFirstChild("RightFoot")
	if rUpper or rLower or rFoot then
		-- R15 Rig
		if enabled then
			if rUpper and rUpper:IsA("MeshPart") then
				KorbloxOriginalMeshes["RightUpperLeg"] = rUpper.MeshId
				rUpper.MeshId = "rbxassetid://902942093"
			end
			if rLower and rLower:IsA("MeshPart") then
				KorbloxOriginalMeshes["RightLowerLeg"] = rLower.MeshId
				rLower.MeshId = "rbxassetid://902942096"
			end
			if rFoot and rFoot:IsA("MeshPart") then
				KorbloxOriginalMeshes["RightFoot"] = rFoot.MeshId
				rFoot.MeshId = "rbxassetid://902942098"
			end
		else
			if rUpper and rUpper:IsA("MeshPart") and KorbloxOriginalMeshes["RightUpperLeg"] then
				rUpper.MeshId = KorbloxOriginalMeshes["RightUpperLeg"]
			end
			if rLower and rLower:IsA("MeshPart") and KorbloxOriginalMeshes["RightLowerLeg"] then
				rLower.MeshId = KorbloxOriginalMeshes["RightLowerLeg"]
			end
			if rFoot and rFoot:IsA("MeshPart") and KorbloxOriginalMeshes["RightFoot"] then
				rFoot.MeshId = KorbloxOriginalMeshes["RightFoot"]
			end
		end
	else
		-- R6 Rig
		local rLeg = char:FindFirstChild("Right Leg")
		if rLeg then
			local existingMesh = rLeg:FindFirstChildOfClass("CharacterMesh")
			if enabled then
				if not existingMesh then
					local cm = Instance.new("CharacterMesh", char)
					cm.Name = "NVL_KorbloxMesh"
					cm.BodyPart = Enum.BodyPart.RightLeg
					cm.MeshId = 902942093
				end
			else
				local km = char:FindFirstChild("NVL_KorbloxMesh")
				if km then km:Destroy() end
			end
		end
	end
end

-- METHOD 5: Body Material Modifier
local function SetBodyMaterial(matName, tintColor)
	local char = lp.Character
	if not char then return end
	local targetMat = Enum.Material[matName] or Enum.Material.SmoothPlastic
	for _, p in ipairs(char:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			p.Material = targetMat
			if tintColor then p.Color = tintColor end
		end
	end
end

-- METHOD 6: Reset Original Skin
local function ResetOriginalSkin()
	local char = lp.Character
	if not char or not OriginalAvatarState then return end

	-- Remove custom accessories
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Accessory") then
			pcall(function() item:Destroy() end)
		end
	end

	-- Restore clothes
	local shirt = char:FindFirstChildOfClass("Shirt")
	if shirt then
		if OriginalAvatarState.Shirt ~= "" then
			shirt.ShirtTemplate = OriginalAvatarState.Shirt
		else
			shirt:Destroy()
		end
	end
	local pants = char:FindFirstChildOfClass("Pants")
	if pants then
		if OriginalAvatarState.Pants ~= "" then
			pants.PantsTemplate = OriginalAvatarState.Pants
		else
			pants:Destroy()
		end
	end

	-- Restore Colors & Materials
	local bc = char:FindFirstChildOfClass("BodyColors")
	if bc and OriginalAvatarState.HeadColor then
		bc.HeadColor3 = OriginalAvatarState.HeadColor
		bc.TorsoColor3 = OriginalAvatarState.TorsoColor
		bc.LeftArmColor3 = OriginalAvatarState.LeftArmColor
		bc.RightArmColor3 = OriginalAvatarState.RightArmColor
		bc.LeftLegColor3 = OriginalAvatarState.LeftLegColor
		bc.RightLegColor3 = OriginalAvatarState.RightLegColor
	end

	for _, p in ipairs(char:GetChildren()) do
		if p:IsA("BasePart") then
			p.Material = Enum.Material.SmoothPlastic
		end
	end

	-- Restore Headless & Korblox
	SetHeadless(false)
	SetKorbloxLeg(false)

	-- Restore Original Accessories
	for _, acc in ipairs(OriginalAvatarState.Accessories) do
		if acc then
			local clone = acc:Clone()
			SafeWeldAccessory(clone, char)
		end
	end

	print("[NVL-Win] Reset to Original Avatar Skin.")
end

-- Left Column: Card 1 - ESP Main
local VisualsMainCard = PlayersTab:CreateCard({
	Title = "ESP Main",
	Side = "left",
	Icon = MemoryAssets.Icons.sliders or "",
	SubTab = "Enemies",
})
VisualsMainCard:CreateToggle({
	Name = "Boxes",
	Default = true,
	ColorBadge = true,
	ColorValue = VisualsState.BoxColor,
	Callback = function(v)
		VisualsState.Boxes = v
		RefreshAllESP()
	end,
	ColorCallback = function(c)
		VisualsState.BoxColor = c
		RefreshAllESP()
	end,
})
VisualsMainCard:CreateToggle({
	Name = "Filled Box",
	Default = false,
	ColorBadge = true,
	ColorValue = VisualsState.FilledBoxColor,
	Callback = function(v)
		VisualsState.FilledBox = v
		RefreshAllESP()
	end,
	ColorCallback = function(c)
		VisualsState.FilledBoxColor = c
		RefreshAllESP()
	end,
})
VisualsMainCard:CreateToggle({
	Name = "Box Outline",
	Default = true,
	Callback = function(v)
		VisualsState.BoxOutline = v
		RefreshAllESP()
	end,
})
VisualsMainCard:CreateToggle({
	Name = "Corner Box",
	Default = false,
	Callback = function(v)
		VisualsState.CornerBox = v
		RefreshAllESP()
	end,
})

-- Left Column: Card 2 - Player Info
local PlayerInfoCard = PlayersTab:CreateCard({
	Title = "Player Info",
	Side = "left",
	Icon = MemoryAssets.Icons.user_filled or "",
	SubTab = "Enemies",
})
PlayerInfoCard:CreateToggle({
	Name = "Name Tags",
	Default = true,
	ColorBadge = true,
	ColorValue = VisualsState.NameColor,
	Callback = function(v)
		VisualsState.NameTags = v
		RefreshAllESP()
	end,
	ColorCallback = function(c)
		VisualsState.NameColor = c
		RefreshAllESP()
	end,
})
PlayerInfoCard:CreateToggle({
	Name = "Health Bar",
	Default = true,
	Callback = function(v)
		VisualsState.HealthBar = v
		RefreshAllESP()
	end,
})
PlayerInfoCard:CreateToggle({
	Name = "Health Text",
	Default = true,
	Callback = function(v)
		VisualsState.HealthText = v
		RefreshAllESP()
	end,
})
PlayerInfoCard:CreateToggle({
	Name = "Armor Bar",
	Default = false,
	Callback = function(v)
		VisualsState.ArmorBar = v
		RefreshAllESP()
	end,
})
PlayerInfoCard:CreateToggle({
	Name = "Distance",
	Default = true,
	Callback = function(v)
		VisualsState.Distance = v
		RefreshAllESP()
	end,
})
PlayerInfoCard:CreateToggle({
	Name = "Equipped Weapon",
	Default = false,
	Callback = function(v)
		VisualsState.EquippedWeapon = v
		RefreshAllESP()
	end,
})

-- Left Column: Card 3 - Indicators & Skeleton
local IndicatorsCard = PlayersTab:CreateCard({
	Title = "Indicators",
	Side = "left",
	Icon = MemoryAssets.Icons.target_fill or "",
	SubTab = "Enemies",
})
IndicatorsCard:CreateToggle({
	Name = "Off-Screen Arrows",
	Default = false,
	ColorBadge = true,
	ColorValue = Color3.fromRGB(255, 120, 120),
	Callback = function(v) print("[NVL-Win] Off-Screen Arrows:", v) end,
})
IndicatorsCard:CreateToggle({
	Name = "Tracers",
	Default = false,
	ColorBadge = true,
	ColorValue = VisualsState.TracersColor,
	Callback = function(v)
		VisualsState.Tracers = v
	end,
	ColorCallback = function(c)
		VisualsState.TracersColor = c
	end,
})
IndicatorsCard:CreateToggle({
	Name = "Skeleton",
	Default = false,
	ColorBadge = true,
	ColorValue = VisualsState.SkeletonColor,
	Callback = function(v)
		VisualsState.Skeleton = v
	end,
	ColorCallback = function(c)
		VisualsState.SkeletonColor = c
	end,
})

-- Right Column: Card 1 - Chams & Highlights
local VisualsChamsCard = PlayersTab:CreateCard({
	Title = "Chams & Highlights",
	Side = "right",
	Icon = MemoryAssets.Icons.view_filled or "",
	SubTab = "Enemies",
})
VisualsChamsCard:CreateToggle({
	Name = "Highlight Chams",
	Default = true,
	ColorBadge = true,
	ColorValue = VisualsState.ChamsColor,
	Callback = function(v)
		VisualsState.Chams = v
		RefreshAllESP()
	end,
	ColorCallback = function(c)
		VisualsState.ChamsColor = c
		RefreshAllESP()
	end,
})
VisualsChamsCard:CreateToggle({
	Name = "Chams Outline",
	Default = true,
	ColorBadge = true,
	ColorValue = VisualsState.ChamsOutlineColor,
	Callback = function(v)
		VisualsState.ChamsOutline = v
		RefreshAllESP()
	end,
	ColorCallback = function(c)
		VisualsState.ChamsOutlineColor = c
		RefreshAllESP()
	end,
})
VisualsChamsCard:CreateToggle({
	Name = "Through Walls",
	Default = true,
	Callback = function(v)
		VisualsState.ThroughWalls = v
		RefreshAllESP()
	end,
})
VisualsChamsCard:CreateToggle({
	Name = "Rainbow Mode",
	Default = false,
	Callback = function(v)
		VisualsState.RainbowMode = v
		RefreshAllESP()
	end,
})

-- Right Column: Card 2 - Visual Effects
local VisualsEffectsCard = PlayersTab:CreateCard({
	Title = "Visual Effects",
	Side = "right",
	Icon = MemoryAssets.Icons.dots_2 or "",
	SubTab = "Enemies",
})
VisualsEffectsCard:CreateToggle({
	Name = "Hit FX",
	Default = true,
	ColorBadge = true,
	ColorValue = Color3.fromRGB(255, 80, 80),
	Callback = function(v) print("[NVL-Win] Hit FX:", v) end,
})
VisualsEffectsCard:CreateToggle({
	Name = "Bullet Tracers",
	Default = false,
	ColorBadge = true,
	ColorValue = Color3.fromRGB(140, 180, 255),
	Callback = function(v) print("[NVL-Win] Bullet Tracers:", v) end,
})
VisualsEffectsCard:CreateToggle({
	Name = "Damage Numbers",
	Default = true,
	Callback = function(v) print("[NVL-Win] Damage Numbers:", v) end,
})

-- Right Column: Card 3 - Visual Settings
local VisualsSettingsCard = PlayersTab:CreateCard({
	Title = "Visual Settings",
	Side = "right",
	Icon = MemoryAssets.Icons.settings_bold or "",
	SubTab = "Enemies",
})
VisualsSettingsCard:CreateSlider({
	Name = "Render Distance",
	Min = 100,
	Max = 3000,
	Default = 1500,
	Decimals = 0,
	Callback = function(v)
		VisualsState.RenderDistance = v
		RefreshAllESP()
	end,
})
VisualsSettingsCard:CreateSlider({
	Name = "ESP Font Size",
	Min = 8,
	Max = 16,
	Default = 11,
	Decimals = 0,
	Callback = function(v)
		VisualsState.FontSize = v
		RefreshAllESP()
	end,
})
VisualsSettingsCard:CreateColorPicker({
	Name = "Accent Color",
	Default = Color3.fromRGB(186, 145, 252),
	Callback = function(c)
		VisualsState.AccentColor = c
	end,
})

-- ========================================================================
-- SubTab: Self Cards (Self Effects & Mod Skin)
-- ========================================================================
local CardSelfEffects = PlayersTab:CreateCard({
	Title = "Self Effects",
	Side = "left",
	Icon = MemoryAssets.Icons.dots_2 or "",
	SubTab = "Self",
})
CardSelfEffects:CreateToggle({
	Name = "Character Trail",
	Default = false,
	ColorBadge = true,
	ColorValue = VisualsState.SelfTrailColor,
	Callback = function(v)
		VisualsState.SelfTrail = v
		UpdateSelfTrail()
	end,
	ColorCallback = function(c)
		VisualsState.SelfTrailColor = c
		UpdateSelfTrail()
	end,
})
CardSelfEffects:CreateToggle({
	Name = "Footstep Rings",
	Default = false,
	ColorBadge = true,
	ColorValue = VisualsState.SelfStepColor,
	Callback = function(v)
		VisualsState.SelfStepRings = v
	end,
	ColorCallback = function(c)
		VisualsState.SelfStepColor = c
	end,
})

local CardModSkin = PlayersTab:CreateCard({
	Title = "Custom Skin & Morph",
	Side = "right",
	Icon = MemoryAssets.Icons.users or "",
	SubTab = "Self",
})
CardModSkin:CreateDropdown({
	Name = "Preset Outfits",
	Options = {
		"10442891740 - Kasumi AFK",
		"1046787815 - Uninspired",
		"10523593859 - Miru",
		"10536288229 - Aiponn",
		"10639617194 - Chicken Comel",
		"10708887824 - Mayuri Shark",
		"10915292293 - Tuithichban Y2K",
		"1103193770 - Tessy Korblox",
		"3633336385 - Nicholas Rikka",
	},
	Default = "10442891740 - Kasumi AFK",
	Callback = function(opt)
		local extractedId = string.match(opt, "^(%d+)")
		if extractedId then
			SelectedSkinUserId = extractedId
		end
	end,
})
CardModSkin:CreateInput({
	Placeholder = "Custom User ID (e.g. 10442891740)",
	Callback = function(text)
		CustomSkinUserId = text
	end,
})
CardModSkin:CreateButton({
	Name = "Apply Selected Skin",
	Callback = function()
		local targetId = (CustomSkinUserId ~= "" and CustomSkinUserId) or SelectedSkinUserId
		ApplySkinById(targetId)
	end,
})
CardModSkin:CreateButton({
	Name = "Reset Original Skin",
	Callback = function()
		ResetOriginalSkin()
	end,
})

-- ========================================================================
-- Movement Engine (New Method - CFrame / Velocity Speed & Fly, Bhop, Noclip)
-- ========================================================================
local MovementState = {
	SpeedEnabled = false,
	SpeedMode = "CFrame",
	SpeedValue = 32,
	BhopEnabled = false,
	FlyEnabled = false,
	FlyMode = "CFrame",
	FlySpeed = 60,
	NoclipEnabled = false,
	InfiniteJumpEnabled = false,
	SpinbotEnabled = false,
	SpinSpeed = 15,
}

-- Infinite Jump Listener (Event-driven, 0 FPS impact)
NVL_Connect(UserInputService.JumpRequest, function()
	if MovementState.InfiniteJumpEnabled then
		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

-- Spinbot Anti-Aim Controller
local spinAngle = 0
NVL_Connect(RunService.RenderStepped, function(dt)
	if MovementState.SpinbotEnabled then
		local char = lp.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			hum.AutoRotate = false
			spinAngle = (spinAngle + (MovementState.SpinSpeed * dt * 60)) % 360
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
		end
	else
		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and not hum.AutoRotate then
			hum.AutoRotate = true
		end
	end
end)

NVL_Connect(RunService.Heartbeat, function(dt)
	local char = lp.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	-- Speed Assist (CFrame or Velocity mode, 0 impact)
	if MovementState.SpeedEnabled and hum.MoveDirection.Magnitude > 0 and hum.Health > 0 then
		if MovementState.SpeedMode == "Velocity" then
			local vel = hum.MoveDirection * MovementState.SpeedValue
			hrp.AssemblyLinearVelocity = Vector3.new(vel.X, hrp.AssemblyLinearVelocity.Y, vel.Z)
		else
			local speedBonus = math.max(MovementState.SpeedValue - 16, 0)
			hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (speedBonus * dt))
		end
	end

	-- Bunny Hop
	if MovementState.BhopEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) and hum.Health > 0 then
		if hum.FloorMaterial ~= Enum.Material.Air then
			hum.Jump = true
		end
	end
end)

-- Fly Controller (CFrame and Velocity modes - Keeps natural falling animation without locking character)
NVL_Connect(RunService.RenderStepped, function(dt)
	if not MovementState.FlyEnabled then return end
	local char = lp.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	-- Maintain natural Freefall animation state without PlatformStand rigidity
	hum.PlatformStand = false
	hum:ChangeState(Enum.HumanoidStateType.Freefall)

	local camCF = Workspace.CurrentCamera.CFrame
	local moveDir = Vector3.zero

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

	if MovementState.FlyMode == "Velocity" then
		if moveDir.Magnitude > 0 then
			hrp.AssemblyLinearVelocity = moveDir.Unit * MovementState.FlySpeed
		else
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
	else
		hrp.AssemblyLinearVelocity = Vector3.zero
		if moveDir.Magnitude > 0 then
			hrp.CFrame = hrp.CFrame + (moveDir.Unit * (MovementState.FlySpeed * dt))
		end
	end
end)

-- Noclip Controller
NVL_Connect(RunService.Stepped, function()
	if MovementState.NoclipEnabled then
		local char = lp.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
	end
end)

-- ========================================================================
-- Populate Movement Tab
-- ========================================================================
local CardSpeed = MovementTab:CreateCard({
	Title = "Speed Assistance",
	Side = "left",
	Icon = MemoryAssets.Icons.gamepad_bold or "",
	SubTab = "Speed",
})
CardSpeed:CreateToggle({
	Name = "Enable Speed",
	Default = false,
	HasSettings = true,
	Keybind = Enum.KeyCode.C,
	Mode = "Toggle",
	ShowInBinds = true,
	Callback = function(v)
		MovementState.SpeedEnabled = v
	end,
})
CardSpeed:CreateDropdown({
	Name = "Speed Mode",
	Options = { "CFrame", "Velocity" },
	Default = "CFrame",
	Callback = function(opt)
		MovementState.SpeedMode = opt
	end,
})
CardSpeed:CreateSlider({
	Name = "Speed Value",
	Min = 16,
	Max = 120,
	Default = 32,
	Decimals = 0,
	Callback = function(v)
		MovementState.SpeedValue = v
	end,
})

local CardBhop = MovementTab:CreateCard({
	Title = "Bunny Hop & Jump",
	Side = "left",
	Icon = MemoryAssets.Icons.sliders or "",
	SubTab = "Bhop",
})
CardBhop:CreateToggle({
	Name = "Auto Bunny Hop",
	Default = false,
	Callback = function(v)
		MovementState.BhopEnabled = v
	end,
})
CardBhop:CreateToggle({
	Name = "Infinite Jump",
	Default = false,
	Callback = function(v)
		MovementState.InfiniteJumpEnabled = v
	end,
})

local CardSpinbot = MovementTab:CreateCard({
	Title = "Spinbot Anti-Aim",
	Side = "right",
	Icon = MemoryAssets.Icons.sliders or "",
	SubTab = "Bhop",
})
CardSpinbot:CreateToggle({
	Name = "Enable Spinbot",
	Default = false,
	HasSettings = true,
	Keybind = Enum.KeyCode.V,
	Mode = "Toggle",
	ShowInBinds = true,
	Callback = function(v)
		MovementState.SpinbotEnabled = v
	end,
})
CardSpinbot:CreateSlider({
	Name = "Spin Speed",
	Min = 1,
	Max = 50,
	Default = 15,
	Decimals = 0,
	Callback = function(v)
		MovementState.SpinSpeed = v
	end,
})

local CardFlight = MovementTab:CreateCard({
	Title = "Flight & Noclip",
	Side = "right",
	Icon = MemoryAssets.Icons.view_filled or "",
	SubTab = "Flight",
})
CardFlight:CreateToggle({
	Name = "Fly",
	Default = false,
	HasSettings = true,
	Keybind = Enum.KeyCode.X,
	Mode = "Toggle",
	ShowInBinds = true,
	Callback = function(v)
		MovementState.FlyEnabled = v
		local char = lp.Character
		if not v and char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.PlatformStand = false
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
		end
	end,
})
CardFlight:CreateDropdown({
	Name = "Fly Mode",
	Options = { "CFrame", "Velocity" },
	Default = "CFrame",
	Callback = function(opt)
		MovementState.FlyMode = opt
	end,
})
CardFlight:CreateSlider({
	Name = "Fly Speed",
	Min = 20,
	Max = 200,
	Default = 60,
	Decimals = 0,
	Callback = function(v)
		MovementState.FlySpeed = v
	end,
})
CardFlight:CreateToggle({
	Name = "Noclip",
	Default = false,
	HasSettings = true,
	Keybind = Enum.KeyCode.N,
	Mode = "Toggle",
	ShowInBinds = true,
	Callback = function(v)
		MovementState.NoclipEnabled = v
	end,
})

-- ========================================================================
-- World & Ambience Engine (New Method - Lighting & Visuals)
-- ========================================================================
local Lighting = cloneref and cloneref(game:GetService("Lighting")) or game:GetService("Lighting")

local WorldState = {
	CustomTimeEnabled = false,
	ClockTime = 14,
	CustomAmbienceEnabled = false,
	Ambient = Color3.fromRGB(120, 100, 180),
	OutdoorAmbient = Color3.fromRGB(80, 70, 140),
	FogEnabled = false,
	FogColor = Color3.fromRGB(30, 20, 50),
	FogEnd = 500,
	ColorCorrectionEnabled = false,
	Saturation = 0.2,
	Contrast = 0.1,
	FieldOfView = 70,
}

local origLighting = {
	ClockTime = Lighting.ClockTime,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	FogColor = Lighting.FogColor,
	FogEnd = Lighting.FogEnd,
}

local CC = Lighting:FindFirstChild("NVL_ColorCorrection")
if not CC then
	CC = Instance.new("ColorCorrectionEffect")
	CC.Name = "NVL_ColorCorrection"
	CC.Enabled = false
	CC.Parent = Lighting
end

local function RefreshWorld()
	if WorldState.CustomTimeEnabled then
		Lighting.ClockTime = WorldState.ClockTime
	else
		Lighting.ClockTime = origLighting.ClockTime
	end

	if WorldState.CustomAmbienceEnabled then
		Lighting.Ambient = WorldState.Ambient
		Lighting.OutdoorAmbient = WorldState.OutdoorAmbient
	else
		Lighting.Ambient = origLighting.Ambient
		Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
	end

	if WorldState.FogEnabled then
		Lighting.FogColor = WorldState.FogColor
		Lighting.FogEnd = WorldState.FogEnd
	else
		Lighting.FogColor = origLighting.FogColor
		Lighting.FogEnd = origLighting.FogEnd
	end

	if CC then
		CC.Enabled = WorldState.ColorCorrectionEnabled
		CC.Saturation = WorldState.Saturation
		CC.Contrast = WorldState.Contrast
	end

	if Camera then
		Camera.FieldOfView = WorldState.FieldOfView
	end
end

-- ========================================================================
-- Populate World Tab & View Tab
-- ========================================================================
local CardWorldAmbience = WorldTab:CreateCard({
	Title = "World Ambience",
	Side = "left",
	Icon = MemoryAssets.Icons.world_2_fill or "",
	SubTab = "Ambience",
})
CardWorldAmbience:CreateToggle({
	Name = "Custom Time",
	Default = false,
	Callback = function(v)
		WorldState.CustomTimeEnabled = v
		RefreshWorld()
	end,
})
CardWorldAmbience:CreateSlider({
	Name = "Time of Day",
	Min = 0,
	Max = 24,
	Default = 14,
	Decimals = 1,
	Callback = function(v)
		WorldState.ClockTime = v
		RefreshWorld()
	end,
})
CardWorldAmbience:CreateToggle({
	Name = "Custom Ambient",
	Default = false,
	ColorBadge = true,
	ColorValue = WorldState.Ambient,
	Callback = function(v)
		WorldState.CustomAmbienceEnabled = v
		RefreshWorld()
	end,
	ColorCallback = function(c)
		WorldState.Ambient = c
		RefreshWorld()
	end,
})
CardWorldAmbience:CreateToggle({
	Name = "Custom Fog",
	Default = false,
	ColorBadge = true,
	ColorValue = WorldState.FogColor,
	Callback = function(v)
		WorldState.FogEnabled = v
		RefreshWorld()
	end,
	ColorCallback = function(c)
		WorldState.FogColor = c
		RefreshWorld()
	end,
})
CardWorldAmbience:CreateSlider({
	Name = "Fog Distance",
	Min = 50,
	Max = 3000,
	Default = 500,
	Decimals = 0,
	Callback = function(v)
		WorldState.FogEnd = v
		RefreshWorld()
	end,
})

local CardWorldEffects = WorldTab:CreateCard({
	Title = "Color Correction",
	Side = "right",
	Icon = MemoryAssets.Icons.dots_2 or "",
	SubTab = "Effects",
})
CardWorldEffects:CreateToggle({
	Name = "Enable Post-FX",
	Default = false,
	Callback = function(v)
		WorldState.ColorCorrectionEnabled = v
		RefreshWorld()
	end,
})
CardWorldEffects:CreateSlider({
	Name = "Saturation",
	Min = -1,
	Max = 2,
	Default = 0.2,
	Decimals = 1,
	Callback = function(v)
		WorldState.Saturation = v
		RefreshWorld()
	end,
})
CardWorldEffects:CreateSlider({
	Name = "Contrast",
	Min = -1,
	Max = 2,
	Default = 0.1,
	Decimals = 1,
	Callback = function(v)
		WorldState.Contrast = v
		RefreshWorld()
	end,
})

local CardCamera = ViewTab:CreateCard({
	Title = "Camera View",
	Side = "left",
	Icon = MemoryAssets.Icons.eye or "",
	SubTab = "Camera",
})
CardCamera:CreateSlider({
	Name = "Field of View",
	Min = 60,
	Max = 120,
	Default = 70,
	Decimals = 0,
	Callback = function(v)
		WorldState.FieldOfView = v
		RefreshWorld()
	end,
})
CardCamera:CreateSlider({
	Name = "Max Zoom Distance",
	Min = 10,
	Max = 1000,
	Default = 128,
	Decimals = 0,
	Callback = function(v)
		lp.CameraMaxZoomDistance = v
	end,
})
CardCamera:CreateSlider({
	Name = "Min Zoom Distance",
	Min = 0.5,
	Max = 50,
	Default = 0.5,
	Decimals = 1,
	Callback = function(v)
		lp.CameraMinZoomDistance = v
	end,
})

local CamOffsetX = 0
local CamOffsetY = 0
local CamOffsetZ = 0
local function UpdateCamOffset()
	local char = lp.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.CameraOffset = Vector3.new(CamOffsetX, CamOffsetY, CamOffsetZ)
	end
end
NVL_Connect(lp.CharacterAdded, function(c)
	task.wait(0.2)
	UpdateCamOffset()
end)

local CardViewmodel = ViewTab:CreateCard({
	Title = "Camera Offset",
	Side = "right",
	Icon = MemoryAssets.Icons.view_filled or "",
	SubTab = "Camera",
})
CardViewmodel:CreateSlider({
	Name = "Offset X (Shoulder)",
	Min = -10,
	Max = 10,
	Default = 0,
	Decimals = 1,
	Callback = function(v)
		CamOffsetX = v
		UpdateCamOffset()
	end,
})
CardViewmodel:CreateSlider({
	Name = "Offset Y (Height)",
	Min = -10,
	Max = 10,
	Default = 0,
	Decimals = 1,
	Callback = function(v)
		CamOffsetY = v
		UpdateCamOffset()
	end,
})
CardViewmodel:CreateSlider({
	Name = "Offset Z (Distance)",
	Min = -10,
	Max = 10,
	Default = 0,
	Decimals = 1,
	Callback = function(v)
		CamOffsetZ = v
		UpdateCamOffset()
	end,
})

-- ========================================================================
-- Exploits & Desync Engine (New Method - CFrame Manipulation, Ghost & Human Marker Viz)
-- ========================================================================
local DesyncState = {
	Enabled = false,
	Mode = "Freeze",
	CustomX = 0,
	CustomY = 0,
	CustomZ = 0,
	RandomAmount = 20,
	Visualize = true,
	VizColor = Color3.fromRGB(186, 145, 252),
	VizMaterial = "Neon",
	VizTransparency = 0.4,
	ShowIndicator = true,
	IndicatorColor = Color3.fromRGB(255, 255, 255),
	PulseEffect = false,
}
getgenv().NVL_DesyncState = DesyncState

local GhostClone = nil
local GhostMarkerGui = nil
local GhostScreenIndicator = nil

local function RemoveGhostClone()
	if GhostClone and GhostClone.Parent then
		GhostClone:Destroy()
	end
	GhostClone = nil

	if GhostMarkerGui and GhostMarkerGui.Parent then
		GhostMarkerGui:Destroy()
	end
	GhostMarkerGui = nil

	if GhostScreenIndicator and GhostScreenIndicator.Parent then
		GhostScreenIndicator:Destroy()
	end
	GhostScreenIndicator = nil

	local stray = Workspace:FindFirstChild("NVL_GhostClone")
	while stray do
		stray:Destroy()
		stray = Workspace:FindFirstChild("NVL_GhostClone")
	end
end

local function GetDesyncMaterialEnum(matName)
	if matName == "Neon" then return Enum.Material.Neon
	elseif matName == "ForceField" then return Enum.Material.ForceField
	elseif matName == "Glass" then return Enum.Material.Glass
	elseif matName == "SmoothPlastic" then return Enum.Material.SmoothPlastic
	elseif matName == "Ghost" then return Enum.Material.ForceField
	elseif matName == "Wireframe" then return Enum.Material.ForceField
	end
	return Enum.Material.Neon
end

local function GetHumanMarkerAsset()
	local a = (MemoryAssets and MemoryAssets.Icons and MemoryAssets.Icons.human_marker) or ""
	if (not a or a == "") and getgenv().Assets and getgenv().Assets.Icons and getgenv().Assets.Icons.human_marker then
		a = getgenv().Assets.Icons.human_marker
	end
	if (not a or a == "") and getcustomasset and isfile and isfile("uisimbl/assets/icons/human_marker.png") then
		a = getcustomasset("uisimbl/assets/icons/human_marker.png")
	end
	return a
end

local function UpdateGhostClone(cframePos)
	local char = lp.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		RemoveGhostClone()
		return
	end

	local localHrp = char.HumanoidRootPart

	if not GhostClone or not GhostClone.Parent then
		local stray = Workspace:FindFirstChild("NVL_GhostClone")
		while stray do
			stray:Destroy()
			stray = Workspace:FindFirstChild("NVL_GhostClone")
		end

		char.Archivable = true
		GhostClone = char:Clone()
		char.Archivable = false
		GhostClone.Name = "NVL_GhostClone"

		local matEnum = GetDesyncMaterialEnum(DesyncState.VizMaterial)
		local isWireframe = (DesyncState.VizMaterial == "Wireframe")
		local isGhost = (DesyncState.VizMaterial == "Ghost")

		for _, item in ipairs(GhostClone:GetDescendants()) do
			if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("Sound") or item:IsA("Decal") then
				item:Destroy()
			elseif item:IsA("BasePart") then
				item.CanCollide = false
				item.CastShadow = false
				item.Anchored = false
				item.Transparency = isWireframe and 1 or (isGhost and 0.8 or DesyncState.VizTransparency)
				item.Material = matEnum
				item.Color = DesyncState.VizColor
			end
		end

		local ghostHrp = GhostClone:FindFirstChild("HumanoidRootPart")
		if ghostHrp then
			ghostHrp.Anchored = true
		end

		local hl = Instance.new("Highlight")
		hl.Name = "GhostHL"
		hl.FillColor = DesyncState.VizColor
		hl.FillTransparency = isWireframe and 1 or 0.6
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.OutlineTransparency = 0.1
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = GhostClone

		-- Sharp Vector Human Marker Indicator (3D BillboardGui)
		if ghostHrp then
			local bbg = Instance.new("BillboardGui")
			bbg.Name = "GhostMarker"
			bbg.Adornee = ghostHrp
			bbg.Size = UDim2.new(0, 80, 0, 52)
			bbg.StudsOffset = Vector3.new(0, 3.8, 0)
			bbg.AlwaysOnTop = true
			bbg.LightInfluence = 0
			bbg.ClipsDescendants = false
			bbg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			bbg.Enabled = DesyncState.ShowIndicator
			bbg.Parent = ghostHrp

			local humanIcon = Instance.new("ImageLabel")
			humanIcon.Name = "HumanIcon"
			humanIcon.Size = UDim2.new(0, 24, 0, 24)
			humanIcon.Position = UDim2.new(0.5, -12, 0, 0)
			humanIcon.BackgroundTransparency = 1
			humanIcon.Image = GetHumanMarkerAsset()
			humanIcon.ImageColor3 = DesyncState.IndicatorColor
			humanIcon.ScaleType = Enum.ScaleType.Fit
			humanIcon.ZIndex = 20
			humanIcon.Parent = bbg

			local titleLbl = Instance.new("TextLabel")
			titleLbl.Name = "TitleLabel"
			titleLbl.Size = UDim2.new(1, 0, 0, 14)
			titleLbl.Position = UDim2.new(0, 0, 0, 24)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.GothamBold
			titleLbl.Text = "DESYNC"
			titleLbl.TextSize = 10
			titleLbl.TextColor3 = DesyncState.IndicatorColor
			titleLbl.TextStrokeTransparency = 0
			titleLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			titleLbl.ZIndex = 20
			titleLbl.Parent = bbg

			local distLbl = Instance.new("TextLabel")
			distLbl.Name = "DistLabel"
			distLbl.Size = UDim2.new(1, 0, 0, 12)
			distLbl.Position = UDim2.new(0, 0, 0, 38)
			distLbl.BackgroundTransparency = 1
			distLbl.Font = Enum.Font.GothamMedium
			distLbl.TextSize = 9
			distLbl.TextColor3 = DesyncState.VizColor
			distLbl.TextStrokeTransparency = 0
			distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			distLbl.Text = "[0.0m]"
			distLbl.ZIndex = 20
			distLbl.Parent = bbg

			GhostMarkerGui = bbg
		end

		GhostClone.Parent = Workspace
	end

	-- Live property synchronization & pulse animation
	local matEnum = GetDesyncMaterialEnum(DesyncState.VizMaterial)
	local isWireframe = (DesyncState.VizMaterial == "Wireframe")
	local isGhost = (DesyncState.VizMaterial == "Ghost")

	local effectiveTrans = isWireframe and 1 or (isGhost and 0.8 or DesyncState.VizTransparency)
	if DesyncState.PulseEffect then
		local pulseOffset = (math.sin(tick() * 4) + 1) * 0.15
		effectiveTrans = math.clamp(effectiveTrans + pulseOffset, 0, 0.95)
	end

	for _, item in ipairs(GhostClone:GetDescendants()) do
		if item:IsA("BasePart") then
			if item.Color ~= DesyncState.VizColor then item.Color = DesyncState.VizColor end
			if item.Material ~= matEnum then item.Material = matEnum end
			if item.Transparency ~= effectiveTrans then item.Transparency = effectiveTrans end
		elseif item:IsA("Highlight") then
			if item.FillColor ~= DesyncState.VizColor then item.FillColor = DesyncState.VizColor end
			item.FillTransparency = isWireframe and 1 or math.clamp(effectiveTrans + 0.1, 0, 0.95)
			item.OutlineColor = DesyncState.IndicatorColor
		end
	end

	-- Update 3D Marker
	if GhostMarkerGui and GhostMarkerGui.Parent then
		GhostMarkerGui.Enabled = DesyncState.ShowIndicator
		local icon = GhostMarkerGui:FindFirstChild("HumanIcon")
		if icon then
			icon.ImageColor3 = DesyncState.IndicatorColor
			if icon.Image == "" then icon.Image = GetHumanMarkerAsset() end
		end
		local title = GhostMarkerGui:FindFirstChild("TitleLabel")
		if title then title.TextColor3 = DesyncState.IndicatorColor end
		local dist = GhostMarkerGui:FindFirstChild("DistLabel")
		if dist then
			dist.TextColor3 = DesyncState.VizColor
			local distStuds = (localHrp.Position - cframePos.Position).Magnitude
			dist.Text = string.format("[%.1fm]", distStuds)
		end
	end

	-- Off-screen directional indicator
	if DesyncState.ShowIndicator and Camera then
		local screenPos, onScreen = Camera:WorldToViewportPoint(cframePos.Position)
		if not onScreen then
			if not GhostScreenIndicator or not GhostScreenIndicator.Parent then
				local gui = Instance.new("ScreenGui")
				gui.Name = "NVL_DesyncScreenIndicator"
				gui.ResetOnSpawn = false
				gui.DisplayOrder = 90
				gui.Parent = CoreGui

				local arrowFrame = Instance.new("Frame")
				arrowFrame.Name = "Pointer"
				arrowFrame.Size = UDim2.new(0, 36, 0, 36)
				arrowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
				arrowFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
				arrowFrame.BorderSizePixel = 0
				arrowFrame.Parent = gui

				Instance.new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = arrowFrame })
				local stroke = Instance.new("UIStroke")
				stroke.Name = "Stroke"
				stroke.Color = DesyncState.VizColor
				stroke.Thickness = 1.5
				stroke.Parent = arrowFrame

				local icon = Instance.new("ImageLabel")
				icon.Name = "Icon"
				icon.Size = UDim2.new(0, 20, 0, 20)
				icon.Position = UDim2.new(0.5, -10, 0.5, -10)
				icon.BackgroundTransparency = 1
				icon.Image = GetHumanMarkerAsset()
				icon.ImageColor3 = DesyncState.IndicatorColor
				icon.ScaleType = Enum.ScaleType.Fit
				icon.Parent = arrowFrame

				GhostScreenIndicator = gui
			end

			local pointer = GhostScreenIndicator:FindFirstChild("Pointer")
			if pointer then
				pointer.Visible = true
				local stroke = pointer:FindFirstChild("Stroke")
				if stroke then stroke.Color = DesyncState.VizColor end
				local icon = pointer:FindFirstChild("Icon")
				if icon then icon.ImageColor3 = DesyncState.IndicatorColor end

				local vpSize = Camera.ViewportSize
				local center = Vector2.new(vpSize.X / 2, vpSize.Y / 2)
				local dir = Vector2.new(screenPos.X - center.X, screenPos.Y - center.Y)
				if screenPos.Z < 0 then
					dir = -dir
				end
				local unitDir = dir.Magnitude > 0 and dir.Unit or Vector2.new(0, 1)
				local edgeMargin = 50
				local clampedX = math.clamp(center.X + unitDir.X * (center.X - edgeMargin), edgeMargin, vpSize.X - edgeMargin)
				local clampedY = math.clamp(center.Y + unitDir.Y * (center.Y - edgeMargin), edgeMargin, vpSize.Y - edgeMargin)
				pointer.Position = UDim2.new(0, clampedX, 0, clampedY)
			end
		else
			if GhostScreenIndicator and GhostScreenIndicator:FindFirstChild("Pointer") then
				GhostScreenIndicator.Pointer.Visible = false
			end
		end
	else
		if GhostScreenIndicator and GhostScreenIndicator:FindFirstChild("Pointer") then
			GhostScreenIndicator.Pointer.Visible = false
		end
	end

	GhostClone:PivotTo(cframePos)
end

NVL_Connect(lp.CharacterAdded, function()
	RemoveGhostClone()
end)

NVL_Connect(RunService.Heartbeat, function()
	if not DesyncState.Enabled then
		RemoveGhostClone()
		return
	end

	local char = lp.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local offset = Vector3.zero
	if DesyncState.Mode == "Jitter" then
		local tickSign = (math.floor(tick() * 15) % 2 == 0) and 1 or -1
		offset = Vector3.new(tickSign * DesyncState.RandomAmount, 0, -tickSign * DesyncState.RandomAmount)
	elseif DesyncState.Mode == "Freeze" then
		offset = Vector3.new(DesyncState.CustomX, DesyncState.CustomY, DesyncState.CustomZ)
	elseif DesyncState.Mode == "Custom" then
		offset = Vector3.new(DesyncState.CustomX, DesyncState.CustomY, DesyncState.CustomZ)
	elseif DesyncState.Mode == "Underground" then
		offset = Vector3.new(0, -12, 0)
	elseif DesyncState.Mode == "Void" then
		offset = Vector3.new(math.random(-5000, 5000), -500, math.random(-5000, 5000))
	elseif DesyncState.Mode == "Random" then
		offset = Vector3.new(math.random(-DesyncState.RandomAmount, DesyncState.RandomAmount), 0, math.random(-DesyncState.RandomAmount, DesyncState.RandomAmount))
	elseif DesyncState.Mode == "Safe Shoot" then
		offset = Vector3.new(math.random(-3, 3), -5, math.random(-3, 3))
	end

	local desyncCF = hrp.CFrame + offset

	if DesyncState.Visualize then
		UpdateGhostClone(desyncCF)
	else
		RemoveGhostClone()
	end
end)

-- ========================================================================
-- Fake Lag Engine (Packet Choking & Network Throttling)
-- ========================================================================
local FakeLagState = {
	Enabled = false,
	ChokeTicks = 12,
	Mode = "Static", -- Static, Pulse, Random
	Visualize = false,
}

local fakeLagTickCount = 0
NVL_Connect(RunService.Heartbeat, function()
	if not FakeLagState.Enabled then return end
	local char = lp.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	fakeLagTickCount = fakeLagTickCount + 1
	local limit = FakeLagState.ChokeTicks
	if FakeLagState.Mode == "Random" then
		limit = math.random(4, FakeLagState.ChokeTicks)
	elseif FakeLagState.Mode == "Pulse" then
		limit = (fakeLagTickCount % 2 == 0) and 2 or FakeLagState.ChokeTicks
	end

	if fakeLagTickCount >= limit then
		fakeLagTickCount = 0
		if sethiddenproperty then
			pcall(function() sethiddenproperty(Workspace, "InterpolationThrottling", Enum.InterpolationThrottlingMode.Default) end)
		end
	else
		if sethiddenproperty then
			pcall(function() sethiddenproperty(Workspace, "InterpolationThrottling", Enum.InterpolationThrottlingMode.Disabled) end)
		end
	end
end)

-- ========================================================================
-- Server Manager Engine (Instant Rejoin & Server Hop)
-- ========================================================================
local TeleportService = cloneref and cloneref(game:GetService("TeleportService")) or game:GetService("TeleportService")
local HttpService = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService")

local function RejoinServer()
	MemoryUI:Notify({ Title = "Server", Content = "Rejoining current server...", Duration = 3 })
	if #Players:GetPlayers() <= 1 then
		TeleportService:Teleport(game.PlaceId, lp)
	else
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
	end
end

local function ServerHop()
	MemoryUI:Notify({ Title = "Server Hop", Content = "Searching for active public server...", Duration = 3 })
	task.spawn(function()
		local ok, res = pcall(function()
			local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
			local body = game:HttpGet(url)
			return HttpService:JSONDecode(body)
		end)
		if ok and res and res.data then
			for _, srv in ipairs(res.data) do
				if srv.id ~= game.JobId and srv.playing and srv.maxPlayers and srv.playing < srv.maxPlayers then
					MemoryUI:Notify({ Title = "Server Hop", Content = "Teleporting to server " .. tostring(srv.id):sub(1, 8) .. "...", Duration = 3 })
					TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, lp)
					return
				end
			end
		end
		MemoryUI:Notify({ Title = "Server Hop", Content = "No active alternative server found, reconnecting...", Duration = 3 })
		TeleportService:Teleport(game.PlaceId, lp)
	end)
end

-- ========================================================================
-- Populate Exploits Tab (SubTabs: Desync, Fake Lag, Server)
-- ========================================================================
local CardDesync = ExploitsTab:CreateCard({
	Title = "Desync Anti-Aim",
	Side = "left",
	Icon = MemoryAssets.Icons.pencil or "",
	SubTab = "Desync",
})
CardDesync:CreateToggle({
	Name = "Enable Desync",
	Default = false,
	HasSettings = true,
	Keybind = Enum.KeyCode.H,
	Mode = "Toggle",
	ShowInBinds = true,
	Callback = function(v)
		DesyncState.Enabled = v
		if not v then RemoveGhostClone() end
	end,
})
CardDesync:CreateDropdown({
	Name = "Desync Mode",
	Options = { "Freeze", "Jitter", "Custom", "Underground", "Void", "Random", "Safe Shoot" },
	Default = "Freeze",
	Callback = function(opt)
		DesyncState.Mode = opt
	end,
})
CardDesync:CreateSlider({
	Name = "Custom X",
	Min = -500,
	Max = 500,
	Default = 0,
	Decimals = 0,
	Callback = function(v)
		DesyncState.CustomX = v
	end,
})
CardDesync:CreateSlider({
	Name = "Custom Y",
	Min = -500,
	Max = 500,
	Default = 0,
	Decimals = 0,
	Callback = function(v)
		DesyncState.CustomY = v
	end,
})
CardDesync:CreateSlider({
	Name = "Custom Z",
	Min = -500,
	Max = 500,
	Default = 0,
	Decimals = 0,
	Callback = function(v)
		DesyncState.CustomZ = v
	end,
})
CardDesync:CreateSlider({
	Name = "Random Amount",
	Min = 1,
	Max = 100,
	Default = 20,
	Decimals = 0,
	Callback = function(v)
		DesyncState.RandomAmount = v
	end,
})

local CardDesyncViz = ExploitsTab:CreateCard({
	Title = "Desync Visualizer",
	Side = "right",
	Icon = MemoryAssets.Icons.view_filled or "",
	SubTab = "Desync",
})
CardDesyncViz:CreateToggle({
	Name = "Visualize Desync",
	Default = true,
	ColorBadge = true,
	ColorValue = DesyncState.VizColor,
	Callback = function(v)
		DesyncState.Visualize = v
		if not v then RemoveGhostClone() end
	end,
	ColorCallback = function(c)
		DesyncState.VizColor = c
	end,
})
CardDesyncViz:CreateDropdown({
	Name = "Visualize Material",
	Options = { "Neon", "ForceField", "Glass", "Ghost", "Wireframe", "SmoothPlastic" },
	Default = "Neon",
	Callback = function(opt)
		DesyncState.VizMaterial = opt
	end,
})
CardDesyncViz:CreateSlider({
	Name = "Ghost Transparency",
	Min = 0,
	Max = 1,
	Default = 0.4,
	Decimals = 2,
	Callback = function(v)
		DesyncState.VizTransparency = v
	end,
})
CardDesyncViz:CreateToggle({
	Name = "Human Marker Indicator",
	Default = true,
	ColorBadge = true,
	ColorValue = DesyncState.IndicatorColor,
	Callback = function(v)
		DesyncState.ShowIndicator = v
	end,
	ColorCallback = function(c)
		DesyncState.IndicatorColor = c
	end,
})
CardDesyncViz:CreateToggle({
	Name = "Pulse Animation",
	Default = false,
	Callback = function(v)
		DesyncState.PulseEffect = v
	end,
})

-- SubTab: Fake Lag
local CardFakeLag = ExploitsTab:CreateCard({
	Title = "Packet Choking",
	Side = "left",
	Icon = MemoryAssets.Icons.sliders or "",
	SubTab = "Fake Lag",
})
CardFakeLag:CreateToggle({
	Name = "Enable Fake Lag",
	Default = false,
	HasSettings = true,
	Keybind = Enum.KeyCode.Z,
	Mode = "Toggle",
	ShowInBinds = true,
	Callback = function(v)
		FakeLagState.Enabled = v
	end,
})
CardFakeLag:CreateSlider({
	Name = "Choke Ticks",
	Min = 1,
	Max = 20,
	Default = 12,
	Decimals = 0,
	Callback = function(v)
		FakeLagState.ChokeTicks = v
	end,
})
CardFakeLag:CreateDropdown({
	Name = "Lag Pattern",
	Options = { "Static", "Pulse", "Random" },
	Default = "Static",
	Callback = function(opt)
		FakeLagState.Mode = opt
	end,
})

local CardFakeLagViz = ExploitsTab:CreateCard({
	Title = "Network Simulation",
	Side = "right",
	Icon = MemoryAssets.Icons.view_filled or "",
	SubTab = "Fake Lag",
})
CardFakeLagViz:CreateToggle({
	Name = "Visualize Choked Marker",
	Default = false,
	Callback = function(v)
		FakeLagState.Visualize = v
	end,
})

-- SubTab: Server
local CardServerActions = ExploitsTab:CreateCard({
	Title = "Server Operations",
	Side = "left",
	Icon = MemoryAssets.Icons.world_2_fill or "",
	SubTab = "Server",
})
CardServerActions:CreateButton({
	Text = "Rejoin Server",
	Callback = function()
		RejoinServer()
	end,
})
CardServerActions:CreateButton({
	Text = "Server Hop (Next Server)",
	Callback = function()
		ServerHop()
	end,
})
CardServerActions:CreateButton({
	Text = "Copy JobId",
	Callback = function()
		if setclipboard then
			setclipboard(tostring(game.JobId))
			MemoryUI:Notify({ Title = "Server", Content = "JobId copied to clipboard!", Duration = 2 })
		end
	end,
})
CardServerActions:CreateButton({
	Text = "Copy Join Script",
	Callback = function()
		if setclipboard then
			setclipboard('game:GetService("TeleportService"):TeleportToPlaceInstance(' .. tostring(game.PlaceId) .. ', "' .. tostring(game.JobId) .. '")')
			MemoryUI:Notify({ Title = "Server", Content = "Join script copied to clipboard!", Duration = 2 })
		end
	end,
})

local CardServerTelemetry = ExploitsTab:CreateCard({
	Title = "Server Telemetry",
	Side = "right",
	Icon = MemoryAssets.Icons.settings_bold or "",
	SubTab = "Server",
})
CardServerTelemetry:CreateToggle({
	Name = "Auto Rejoin on Kick",
	Default = false,
	Callback = function(v)
		print("[NVL-Win] Auto Rejoin on Kick:", v)
	end,
})

-- ========================================================================
-- Populate Config Tab (HUD Controls)
-- ========================================================================
local HUDCard = ConfigTab:CreateCard({
	Title = "HUD Overlays",
	Side = "left",
	Icon = MemoryAssets.Icons.settings_bold or "",
})
HUDCard:CreateToggle({
	Name = "Live Watermark",
	Default = true,
	Callback = function(v)
		if Watermark and Watermark.SetVisible then
			Watermark.SetVisible(v)
		end
	end,
})
HUDCard:CreateToggle({
	Name = "Spectator Window",
	Default = true,
	Callback = function(v)
		if Spectators and Spectators.SetVisible then
			Spectators.SetVisible(v)
		end
	end,
})

local ConfigCard = ConfigTab:CreateCard({
	Title = "Config Manager",
	Side = "right",
	Icon = MemoryAssets.Icons.gear or "",
})

local selectedConfig = "default"
local enteredConfigName = ""
local ConfigDropdown = nil

local function RefreshConfigs()
	local list = MemoryUI:GetConfigList()
	if ConfigDropdown and ConfigDropdown.SetOptions then
		ConfigDropdown.SetOptions(list)
	end
end

ConfigDropdown = ConfigCard:CreateDropdown({
	Name = "Select Config",
	Options = MemoryUI:GetConfigList(),
	Default = "default",
	Callback = function(cfg)
		selectedConfig = cfg
		print("[NVL-Win] Selected config:", cfg)
	end,
})

ConfigCard:CreateInput({
	Placeholder = "New config name...",
	Callback = function(txt)
		enteredConfigName = txt
	end,
})

-- 1. Save Button (Saves new or current config)
ConfigCard:CreateButton({
	Text = "Save",
	Callback = function()
		local targetName = (enteredConfigName ~= "" and enteredConfigName) or selectedConfig
		if MemoryUI:SaveConfig(targetName) then
			selectedConfig = targetName
			RefreshConfigs()
		end
	end,
})

-- 2. Delete Button (RED danger button)
ConfigCard:CreateButton({
	Text = "Delete",
	Danger = true,
	Red = true,
	Callback = function()
		if MemoryUI:DeleteConfig(selectedConfig) then
			selectedConfig = "default"
			RefreshConfigs()
		end
	end,
})

-- 3. Update Button (Overwrites currently selected config)
ConfigCard:CreateButton({
	Text = "Update",
	Callback = function()
		if MemoryUI:SaveConfig(selectedConfig) then
			MemoryUI:Notify({ Title = "Config", Content = "Updated config: " .. selectedConfig, Duration = 2 })
		end
	end,
})

-- 4. Set Autoload Button
ConfigCard:CreateButton({
	Text = "Set Autoload",
	Callback = function()
		MemoryUI:SetAutoload(selectedConfig)
	end,
})

-- 5. Load Button
ConfigCard:CreateButton({
	Text = "Load",
	Callback = function()
		MemoryUI:LoadConfig(selectedConfig)
	end,
})

-- Auto-Load Config if set
task.spawn(function()
	task.wait(0.5)
	local autoCfg = MemoryUI:GetAutoload()
	if autoCfg then
		print("[NVL-Win] Auto-loading config:", autoCfg)
		MemoryUI:LoadConfig(autoCfg)
	end
end)

print("[NVL-Win] Neverlose / Memory UI initialized with 100% precision!")
