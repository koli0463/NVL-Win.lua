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
	ColorValue = Color3.fromRGB(186, 145, 252),
	Callback = function(v) print("[NVL-Win] Boxes:", v) end,
	ColorCallback = function(c) print("[NVL-Win] Box Color:", c) end,
})
VisualsMainCard:CreateToggle({
	Name = "Filled Box",
	Default = false,
	ColorBadge = true,
	ColorValue = Color3.fromRGB(186, 145, 252),
	Callback = function(v) print("[NVL-Win] Filled Box:", v) end,
})
VisualsMainCard:CreateToggle({
	Name = "Box Outline",
	Default = true,
	Callback = function(v) print("[NVL-Win] Box Outline:", v) end,
})
VisualsMainCard:CreateToggle({
	Name = "Corner Box",
	Default = false,
	Callback = function(v) print("[NVL-Win] Corner Box:", v) end,
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
	ColorValue = Color3.fromRGB(240, 240, 245),
	Callback = function(v) print("[NVL-Win] Name Tags:", v) end,
	ColorCallback = function(c) print("[NVL-Win] Name Color:", c) end,
})
PlayerInfoCard:CreateToggle({
	Name = "Health Bar",
	Default = true,
	Callback = function(v) print("[NVL-Win] Health Bar:", v) end,
})
PlayerInfoCard:CreateToggle({
	Name = "Health Text",
	Default = true,
	Callback = function(v) print("[NVL-Win] Health Text:", v) end,
})
PlayerInfoCard:CreateToggle({
	Name = "Armor Bar",
	Default = false,
	Callback = function(v) print("[NVL-Win] Armor Bar:", v) end,
})
PlayerInfoCard:CreateToggle({
	Name = "Distance",
	Default = true,
	Callback = function(v) print("[NVL-Win] Distance:", v) end,
})
PlayerInfoCard:CreateToggle({
	Name = "Equipped Weapon",
	Default = false,
	Callback = function(v) print("[NVL-Win] Equipped Weapon:", v) end,
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
	ColorValue = Color3.fromRGB(186, 145, 252),
	Callback = function(v) print("[NVL-Win] Highlight Chams:", v) end,
	ColorCallback = function(c) print("[NVL-Win] Chams Color:", c) end,
})
VisualsChamsCard:CreateToggle({
	Name = "Chams Outline",
	Default = true,
	ColorBadge = true,
	ColorValue = Color3.fromRGB(255, 255, 255),
	Callback = function(v) print("[NVL-Win] Chams Outline:", v) end,
})
VisualsChamsCard:CreateToggle({
	Name = "Through Walls",
	Default = true,
	Callback = function(v) print("[NVL-Win] Through Walls:", v) end,
})
VisualsChamsCard:CreateToggle({
	Name = "Rainbow Mode",
	Default = false,
	Callback = function(v) print("[NVL-Win] Rainbow Mode:", v) end,
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
	Callback = function(v) print("[NVL-Win] Render Distance:", v) end,
})
VisualsSettingsCard:CreateSlider({
	Name = "ESP Font Size",
	Min = 8,
	Max = 16,
	Default = 11,
	Decimals = 0,
	Callback = function(v) print("[NVL-Win] ESP Font Size:", v) end,
})
VisualsSettingsCard:CreateColorPicker({
	Name = "Accent Color",
	Default = Color3.fromRGB(186, 145, 252),
	Callback = function(c)
		print("[NVL-Win] New Accent:", c)
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
