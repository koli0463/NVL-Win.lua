--[[
    ========================================================================
    NVL-Win.lua - Main Execution Script for Neverlose / Memory UI
    Pixel-Perfect Luau Interface matching NVL_PRIVATE with Crown Logo,
    Dynamic Place/Game SubTitle, Live NEVERLOSE Watermark, Discord Sync,
    Spectators Window with Real Avatars, Gear Settings (No 'X' button),
    and Complete Tabs + TopBar Sub-Tabs (Thread, Enemy, Other, Team).
    ========================================================================
]]

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

local initialSpectators = {
	{ Name = "Raxxys", DisplayName = "Raxxys", UserId = 10542009861, Mode = "Watching" },
	{ Name = "Sammill", DisplayName = "Sammill", UserId = 1138506088, Mode = "Watching" },
	{ Name = "Johhnyy", DisplayName = "Johhnyy", UserId = 1284562089, Mode = "Watching" },
	{ Name = "killstroy", DisplayName = "killstroy", UserId = 1849203847, Mode = "Watching" },
	{ Name = "Anton Var", DisplayName = "Anton Var", UserId = 1981141314, Mode = "Watching" },
	{ Name = "Layla1970", DisplayName = "Layla1970", UserId = 2039485721, Mode = "Watching" },
}

-- Append real server players so clicking 'Watching' can spectate live targets in the game
for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
	if p ~= game:GetService("Players").LocalPlayer then
		table.insert(initialSpectators, {
			Name = p.Name,
			DisplayName = p.DisplayName,
			UserId = p.UserId,
			Mode = "Watching",
		})
	end
end

local Spectators = Window:CreateSpectators({
	Title = "Spectators",
	Players = initialSpectators,
	Visible = true,
	AutoTrack = false,
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
-- Populate Players Tab (Visuals)
-- ========================================================================
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
})
VisualsMainCard:CreateToggle({
	Name = "Name Tags",
	Default = true,
	Callback = function(v) print("[NVL-Win] Name Tags:", v) end,
})
VisualsMainCard:CreateToggle({
	Name = "Health Bar",
	Default = true,
	Callback = function(v) print("[NVL-Win] Health Bar:", v) end,
})
VisualsMainCard:CreateToggle({
	Name = "Armor Bar",
	Default = false,
	Callback = function(v) print("[NVL-Win] Armor Bar:", v) end,
})

local VisualsEffectsCard = PlayersTab:CreateCard({
	Title = "Chams & Effects",
	Side = "right",
	Icon = MemoryAssets.Icons.view_filled or "",
})
VisualsEffectsCard:CreateToggle({
	Name = "Chams Glow",
	Default = true,
	ColorBadge = true,
	ColorValue = Color3.fromRGB(186, 145, 252),
	Callback = function(v) print("[NVL-Win] Chams:", v) end,
})
VisualsEffectsCard:CreateToggle({
	Name = "Hit FX",
	Default = true,
	Callback = function(v) print("[NVL-Win] Hit FX:", v) end,
})
VisualsEffectsCard:CreateColorPicker({
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
