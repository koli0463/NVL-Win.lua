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
	if isfile and isfile("memory_assets.lua") then
		MemoryAssets = loadstring(readfile("memory_assets.lua"))()
	elseif isfile and isfile("uisimbl/memory_assets.lua") then
		MemoryAssets = loadstring(readfile("uisimbl/memory_assets.lua"))()
	end
end)
MemoryAssets = MemoryAssets or { Icons = {} }

-- Load Library
local MemoryUI = nil
pcall(function()
	if isfile and isfile("lib.lua") then
		MemoryUI = loadstring(readfile("lib.lua"))()
	elseif isfile and isfile("uisimbl/lib.lua") then
		MemoryUI = loadstring(readfile("uisimbl/lib.lua"))()
	elseif isfile and isfile("uisimbl/memory_library.lua") then
		MemoryUI = loadstring(readfile("uisimbl/memory_library.lua"))()
	end
end)

if not MemoryUI then
	error("[NVL-Win] Could not load lib.lua!")
end

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
		print("[NVL-Win] General Enable:", v)
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
		print("[NVL-Win] Auto Fire:", v)
	end,
})

CardGeneral:CreateToggle({
	Name = "Silent Aim",
	Default = false,
	Callback = function(v)
		print("[NVL-Win] Silent Aim:", v)
	end,
})

CardGeneral:CreateToggle({
	Name = "Auto Revolver",
	Default = false,
	Callback = function(v)
		print("[NVL-Win] Auto Revolver:", v)
	end,
})

CardGeneral:CreateToggle({
	Name = "Anti Step",
	Default = true,
	Callback = function(v)
		print("[NVL-Win] Anti Step:", v)
	end,
})

CardGeneral:CreateSlider({
	Name = "Backtracking",
	Min = 0,
	Max = 200,
	Default = 100,
	Decimals = 2,
	Callback = function(v)
		print("[NVL-Win] Backtracking:", v)
	end,
})

CardGeneral:CreateToggle({
	Name = "Draw FOV",
	Default = true,
	HasSettings = true,
	Keybind = Enum.KeyCode.X,
	ColorBadge = true,
	ColorValue = Color3.fromRGB(186, 145, 252),
	Callback = function(v)
		print("[NVL-Win] Draw FOV:", v)
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
		print("[NVL-Win] Visible filter:", opt)
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
		print("[NVL-Win] Body Aimbot:", opt)
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
		print("[NVL-Win] Visible FOV:", v)
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
	Default = 50,
	Decimals = 0,
	Suffix = "%",
	Callback = function(v)
		print("[NVL-Win] Hitchance:", v)
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
		print("[NVL-Win] Teleport Boost:", v)
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
		print("[NVL-Win] First Bullet Delay:", v)
	end,
})

CardSettings:CreateSlider({
	Name = "After Kill",
	Min = 0,
	Max = 1000,
	Default = 500,
	Decimals = 0,
	Callback = function(v)
		print("[NVL-Win] After Kill:", v)
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
		print("[NVL-Win] Autowall:", v)
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
CardEnemyTarget:CreateToggle({ Name = "Prioritize Low Health", Default = true })
CardEnemyTarget:CreateToggle({ Name = "Ignore Friends", Default = true })
CardEnemyTarget:CreateSlider({ Name = "Target Distance Max", Min = 50, Max = 1000, Default = 500 })

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
	Skeleton = false,

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

local VisualsFolder = Instance.new("Folder")
VisualsFolder.Name = "NVL_Visuals_Container"
VisualsFolder.Parent = CoreGui

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
	hpFrame.Size = UDim2.new(0, 3, 1, 0)
	hpFrame.Position = UDim2.new(0, -7, 0, 0)
	hpFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	hpFrame.BorderSizePixel = 0
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
	hpFill.Parent = hpFrame

	local hpText = Instance.new("TextLabel")
	hpText.Name = "HealthText"
	hpText.Size = UDim2.new(0, 20, 0, 12)
	hpText.Position = UDim2.new(0, -22, 1 - pct, -6)
	hpText.BackgroundTransparency = 1
	hpText.Font = Enum.Font.GothamBold
	hpText.TextSize = 9
	hpText.TextColor3 = Color3.fromRGB(240, 240, 245)
	hpText.TextStrokeTransparency = 0.5
	hpText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	hpText.TextXAlignment = Enum.TextXAlignment.Right
	hpText.Text = tostring(math.floor(curHealth))
	hpText.Visible = VisualsState.HealthBar and VisualsState.HealthText
	hpText.Parent = bbg

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
		hpText.Position = UDim2.new(0, -22, 1 - newPct, -6)

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
				data.HealthText.Visible = VisualsState.HealthBar and VisualsState.HealthText
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

Players.PlayerAdded:Connect(SetupPlayer)
Players.PlayerRemoving:Connect(CleanupPlayerESP)

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
				end
			end
		end
	end
end)

-- Left Column: Card 1 - ESP Main
local VisualsMainCard = PlayersTab:CreateCard({
	Title = "ESP Main",
	Side = "left",
	Icon = MemoryAssets.Icons.sliders or "",
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
	ColorValue = Color3.fromRGB(186, 145, 252),
	Callback = function(v) print("[NVL-Win] Tracers:", v) end,
})
IndicatorsCard:CreateToggle({
	Name = "Skeleton",
	Default = false,
	ColorBadge = true,
	ColorValue = Color3.fromRGB(220, 220, 230),
	Callback = function(v) print("[NVL-Win] Skeleton:", v) end,
})

-- Right Column: Card 1 - Chams & Highlights
local VisualsChamsCard = PlayersTab:CreateCard({
	Title = "Chams & Highlights",
	Side = "right",
	Icon = MemoryAssets.Icons.view_filled or "",
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
