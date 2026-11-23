if getgenv()._NVL_CLEANUP then
	pcall(getgenv()._NVL_CLEANUP)
end

local _nvl_conns = {}
getgenv()._NVL_CLEANUP = function()
	for _, c in ipairs(_nvl_conns) do
		pcall(function() c:Disconnect() end)
	end
	_nvl_conns = {}
	pcall(function() game:GetService("RunService"):UnbindFromRenderStep("DesyncClientRestore") end)
	for _, c in ipairs(workspace:GetChildren()) do
		if c.Name == "SafePlatform" or c.Name == "CFrameFixPart" or c.Name == "BodyCloneDesync" or c.Name == "UGFadePart" or c.Name == "NVL_WeatherEmitter" then
			pcall(function() c:Destroy() end)
		end
	end
	pcall(function()
		local Lighting = game:GetService("Lighting")
		for _, name in ipairs({"NVL_Atmosphere", "NVL_Skybox", "NVL_ColorCorrection", "NVL_Bloom", "NVL_Blur", "NVL_SunRays"}) do
			local obj = Lighting:FindFirstChild(name)
			if obj then obj:Destroy() end
		end
	end)
	if getgenv().NVL_library and getgenv().NVL_library.gui then
		pcall(function() getgenv().NVL_library.gui:Destroy() end)
	end
	if getgenv().NVL_SplashGui then
		pcall(function() getgenv().NVL_SplashGui:Destroy() end)
	end
end

local library
if isfile("uisimbl/library.lua") then
	library = loadstring(readfile("uisimbl/library.lua"))()
elseif isfile("library.lua") then
	library = loadstring(readfile("library.lua"))()
else
	library = loadstring(game:HttpGet("https://raw.githubusercontent.com/koli0463/liuuuzuuu/refs/heads/main/librarry.lua"))()
end
local flags = library.flags -- Access flags from here
getgenv().NVL_flags = flags
getgenv().NVL_library = library

-- Ẩn toàn bộ GUI của cheat ngay từ đầu để chờ Splash Screen kết thúc
if library and library.gui then
	library.gui.Enabled = false
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")
local camera = workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()

table.insert(_nvl_conns, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
end))

local local_parts = {}
local local_knocked = false

local function on_character_added(character)
	local_parts = {}
	local_knocked = false
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if hrp and humanoid then
		local_parts["HumanoidRootPart"] = hrp
		local_parts["Humanoid"] = humanoid
		
		local body_effects = character:FindFirstChild("BodyEffects")
		if body_effects then
			local ko = body_effects:FindFirstChild("K.O")
			if ko then
				ko.Changed:Connect(function(val)
					local_knocked = val
				end)
				local_knocked = ko.Value
			end
		end
	end
end

if LocalPlayer.Character then
	task.spawn(on_character_added, LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(on_character_added)

local function get_flag_color(flag_name, default_color)
	local def = default_color or Color3.fromRGB(0, 255, 100)
	local data = flags[flag_name]
	if typeof(data) == "Color3" then
		return data
	elseif type(data) == "table" then
		if typeof(data.Color) == "Color3" then
			return data.Color
		elseif type(data.Color) == "table" and #data.Color >= 3 then
			return Color3.fromRGB(data.Color[1], data.Color[2], data.Color[3])
		elseif #data >= 3 and type(data[1]) == "number" then
			return Color3.fromRGB(data[1], data[2], data[3])
		end
	end
	return def
end

local function get_flag_transparency(flag_name)
	local data = flags[flag_name]
	if type(data) == "table" and data.Transparency then
		return data.Transparency
	end
	return 0.3
end

local window = library:window({
	name = "Neverlose - NVL",
	size = UDim2.fromOffset(500, 650),
})

-- Tạm thời ẩn UI chính để chạy Splash Screen Intro trước (hoặc chạy stealth trong Silentmode)
if window.window_frame then window.window_frame.Visible = false end
if window.watermark_frame then window.watermark_frame.Visible = false end
if window.keybinds_frame then window.keybinds_frame.Visible = false end
if window.playerlist_frame then window.playerlist_frame.Visible = false end

-- Đảm bảo khi toggle Menu Key thì CHỈ CÓ window_frame bật/tắt, không bao giờ tự ý bật keybinds list hay playerlist
local original_window_set_vis = window.set_menu_visibility
window.set_menu_visibility = function(bool)
	if window.window_frame then
		window.window_frame.Visible = bool
	end
	if window.playerlist_frame then
		window.playerlist_frame.Visible = bool and (flags["player_list"] == true)
	end
	if window.keybinds_frame then
		window.keybinds_frame.Visible = (flags["keybinds_enabled"] == true)
	end
	if window.watermark_frame then
		window.watermark_frame.Visible = (flags["watermark_enabled"] == true)
	end
end

-- Tạo 6 mục (Tab) theo thứ tự: Aimbot, Anti-aim, Esp, Visuals, Mics, Config
local aimbot = window:tab({ name = "Aimbot" })
local antiaim = window:tab({ name = "Anti-aim" })
local esp = window:tab({ name = "Esp" })
local visuals = window:tab({ name = "Visuals" })
local mics = window:tab({ name = "Mics" })
local config_tab = window:tab({ name = "Config" })

-- ==========================================
-- 1. Tab Aimbot (Matches Gamesense Universal Tab 3 100%)
-- ==========================================
do
	-- Section 1: Aimbot settings (Left side)
	local aimbot_section = aimbot:section({ name = "Aimbot settings", side = "left" })

	aimbot_section:toggle({
		name = "Enabled",
		flag = "aimbot",
		default = false
	}):keybind({
		flag = "aimbot_keybind"
	})

	aimbot_section:toggle({
		name = "Auto select target",
		flag = "auto_select_target",
		default = false
	})

	aimbot_section:keybind({
		name = "Lock bind",
		flag = "lock_bind"
	})

	aimbot_section:toggle({
		name = "Anti aim viewer",
		flag = "anti_aim_viewer",
		default = false
	})

	aimbot_section:toggle({
		name = "Aim backtrack",
		flag = "aim_backtrack",
		default = false
	})

	aimbot_section:slider({
		name = "Max distance",
		flag = "backtrack_max_distance",
		min = 0,
		max = 500,
		default = 100
	})

	aimbot_section:slider({
		name = "Lifetime",
		flag = "backtrack_lifetime",
		min = 0,
		max = 1,
		default = 0.1
	})

	aimbot_section:dropdown({
		name = "Fallback",
		flag = "backtrack_fallback",
		items = { "Mouse", "Target" },
		multi = false,
		default = "Mouse"
	})

	aimbot_section:toggle({
		name = "Y threshold",
		flag = "clamp_y",
		default = false
	})

	aimbot_section:slider({
		name = "Y threshold value",
		flag = "clamp_y_value",
		min = -40,
		max = 0,
		default = -20
	})

	aimbot_section:slider({
		name = "Multiplier",
		flag = "clamp_multiplier",
		min = 0,
		max = 1,
		default = 0.15
	})

	aimbot_section:toggle({
		name = "Multipoint",
		flag = "multipoint",
		default = false
	})

	aimbot_section:slider({
		name = "Multipoint value",
		flag = "multipoint_value",
		min = 1,
		max = 100,
		default = 50
	})

	aimbot_section:toggle({
		name = "Resolver",
		flag = "resolver",
		default = false
	})

	aimbot_section:toggle({
		name = "Not on vehicles",
		flag = "not_on_vehicles",
		default = false
	})

	aimbot_section:slider({
		name = "Refresh rate",
		flag = "resolver_refresh",
		min = 1,
		max = 200,
		default = 18
	})

	aimbot_section:toggle({
		name = "Silent aim",
		flag = "silent_aim",
		default = false
	})

	aimbot_section:toggle({
		name = "Bullet tp",
		flag = "bullet_tp",
		default = false
	})

	aimbot_section:toggle({
		name = "Max curve",
		flag = "max_curve",
		default = false
	})

	aimbot_section:slider({
		name = "Max curve value",
		flag = "max_curve_value",
		min = 1,
		max = 100,
		default = 100
	})

	aimbot_section:toggle({
		name = "Don't curve vertically",
		flag = "dont_curve_y",
		default = false
	})

	aimbot_section:slider({
		name = "Hit chance",
		flag = "hit_chance",
		min = 1,
		max = 100,
		default = 100
	})

	aimbot_section:dropdown({
		name = "Disable when",
		flag = "silent_aim_disable_when",
		items = { "Out of fov", "Behind wall", "Off screen" },
		multi = true,
		default = {}
	})

	aimbot_section:toggle({
		name = "Aim assist",
		flag = "aim_assist",
		default = false
	}):dropdown({
		flag = "aim_assist_style",
		items = { "Mouse", "Camera" },
		multi = false,
		default = "Camera"
	}):keybind({
		flag = "aim_assist_keybind"
	})

	aimbot_section:dropdown({
		name = "Disable when",
		flag = "aim_assist_disable_when",
		items = { "Not holding gun", "In third person", "Out of fov", "Off screen", "Behind wall", "Typing" },
		multi = true,
		default = {}
	})

	aimbot_section:toggle({
		name = "Camera 360",
		flag = "camera_360",
		default = false
	}):keybind({
		flag = "camera_360_bind"
	})

	aimbot_section:slider({
		name = "360 Speed",
		flag = "360_speed",
		min = 1,
		max = 100,
		default = 50
	})

	aimbot_section:slider({
		name = "Max target distance",
		flag = "max_target_distance",
		min = 50,
		max = 2500,
		default = 150
	})

	aimbot_section:dropdown({
		name = "Target checks",
		flag = "target_checks",
		items = { "Behind wall", "Forcefield", "Grabbed", "Knocked" },
		multi = true,
		default = {}
	})

	aimbot_section:dropdown({
		name = "Untarget when",
		flag = "untarget",
		items = { "Target knocked", "Self knocked", "Typing" },
		multi = true,
		default = {}
	})

	-- Section 2: Aimbot visualization (Left side bottom)
	local vis_section = aimbot:section({ name = "Aimbot visualization", side = "left" })

	vis_section:toggle({
		name = "Show aim assist fov",
		flag = "aim_assist_fov",
		default = false
	}):colorpicker({
		flag = "aim_assist_fov_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	vis_section:toggle({
		name = "Filled aim assist fov",
		flag = "aim_assist_fov_filled",
		default = false
	})

	vis_section:toggle({
		name = "Show silent aim fov",
		flag = "show_fov",
		default = false
	}):colorpicker({
		flag = "fov_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	vis_section:toggle({
		name = "Filled silent aim fov",
		flag = "show_fov_filled",
		default = false
	})

	vis_section:toggle({
		name = "Gradient overlay",
		flag = "gradient_overlay",
		default = false
	}):colorpicker({
		flag = "gradient_overlay_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	vis_section:toggle({
		name = "Glow",
		flag = "gradient_glow",
		default = false
	})

	vis_section:toggle({
		name = "Position line",
		flag = "position_line",
		default = false
	}):colorpicker({
		flag = "line_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	vis_section:dropdown({
		name = "Origin",
		flag = "line_origin",
		items = { "Character", "Mouse" },
		multi = false,
		default = "Character"
	})

	vis_section:dropdown({
		name = "Position",
		flag = "line_position",
		items = { "Predicted position", "Character position" },
		multi = false,
		default = "Character position"
	})

	vis_section:toggle({
		name = "Position body",
		flag = "position_body",
		default = false
	}):colorpicker({
		flag = "position_body_color",
		color = Color3.fromRGB(0, 255, 100),
		transparency = 0.4
	}):dropdown({
		flag = "position_body_material",
		items = { "ForceField", "Neon", "SmoothPlastic" },
		multi = false,
		default = "Neon"
	})

	vis_section:toggle({
		name = "Bounding box",
		flag = "bounding_box",
		default = false
	}):colorpicker({
		flag = "bounding_box_color",
		color = Color3.fromRGB(255, 255, 255),
		transparency = 0.5
	})

	vis_section:toggle({
		name = "Bounding box filled",
		flag = "bounding_box_filled",
		default = false
	})

	-- Section 3: Gun settings (Right side)
	local gun_settings = aimbot:section({ name = "Gun settings", side = "right" })

	gun_settings:dropdown({
		name = "Selected gun",
		flag = "selected_gun",
		items = { "Default", "Pistols", "Shotguns", "Automatics" },
		multi = false,
		default = "Default"
	})

	gun_settings:toggle({
		name = "Override general config",
		flag = "gun_override_general",
		default = false
	})

	gun_settings:slider({
		name = "Silent aim field of view",
		flag = "gun_silent_fov",
		min = 5,
		max = 350,
		default = 20
	})

	gun_settings:slider({
		name = "Silent aim horizontal prediction",
		flag = "gun_silent_h_pred",
		min = 0,
		max = 0.4,
		decimal = 0.001,
		min_text = "Auto",
		default = 0
	})

	gun_settings:slider({
		name = "Silent aim vertical prediction",
		flag = "gun_silent_v_pred",
		min = 0,
		max = 0.4,
		decimal = 0.001,
		min_text = "Auto",
		default = 0
	})

	gun_settings:dropdown({
		name = "Silent aim air hitbox",
		flag = "gun_silent_air_hitbox",
		items = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Closest" },
		multi = false,
		default = "LowerTorso"
	})

	gun_settings:dropdown({
		name = "Silent aim hitbox",
		flag = "gun_silent_hitbox",
		items = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Closest" },
		multi = false,
		default = "Head"
	})

	gun_settings:slider({
		name = "Aim assist field of view",
		flag = "gun_assist_fov",
		min = 5,
		max = 350,
		default = 20,
		suffix = "°"
	})

	gun_settings:slider({
		name = "Aim assist horizontal prediction",
		flag = "gun_assist_h_pred",
		min = 0,
		max = 0.4,
		decimal = 0.001,
		min_text = "Auto",
		default = 0
	})

	gun_settings:slider({
		name = "Aim assist vertical prediction",
		flag = "gun_assist_v_pred",
		min = 0,
		max = 0.4,
		decimal = 0.001,
		min_text = "Auto",
		default = 0
	})

	gun_settings:slider({
		name = "Aim assist horizontal smoothness",
		flag = "gun_assist_h_smooth",
		min = 1,
		max = 100,
		default = 90
	})

	gun_settings:slider({
		name = "Aim assist vertical smoothness",
		flag = "gun_assist_v_smooth",
		min = 1,
		max = 100,
		default = 90
	})

	gun_settings:slider({
		name = "Aim assist horizontal shake",
		flag = "gun_assist_h_shake",
		min = 0,
		max = 100,
		default = 0
	})

	gun_settings:slider({
		name = "Aim assist vertical shake",
		flag = "gun_assist_v_shake",
		min = 0,
		max = 100,
		default = 0
	})

	gun_settings:dropdown({
		name = "Aim assist smoothing direction",
		flag = "gun_assist_smooth_dir",
		items = { "InOut", "Out", "In" },
		multi = false,
		default = "Out"
	})

	gun_settings:dropdown({
		name = "Aim assist smoothing style",
		flag = "gun_assist_smooth_style",
		items = { "Linear", "Circular", "Sine", "Quad", "Quint", "Bounce", "Exponential", "Back", "Cubic", "Elastic" },
		multi = false,
		default = "Linear"
	})

	gun_settings:dropdown({
		name = "Aim assist air hitbox",
		flag = "gun_assist_air_hitbox",
		items = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Closest" },
		multi = false,
		default = "LowerTorso"
	})

	gun_settings:dropdown({
		name = "Aim assist hitbox",
		flag = "gun_assist_hitbox",
		items = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Closest" },
		multi = false,
		default = "Head"
	})

	gun_settings:toggle({
		name = "Jump offset",
		flag = "gun_jump_offset",
		default = false
	})

	gun_settings:slider({
		name = "Jump offset value",
		flag = "gun_jump_offset_value",
		min = 0,
		max = 1.25,
		default = 0
	})
end

-- ==========================================
-- Tab 1 Core Engine (Gamesense & Potassium Engine)
-- ==========================================
do
	local vector2new = Vector2.new
	local vector3new = Vector3.new
	local cframenew = CFrame.new
	local mathrandom = math.random
	local mathclamp = math.clamp
	local mathfloor = math.floor
	local mathrad = math.rad
	local tick = tick
	local raycast = workspace.Raycast
	local mousemoverel = mousemoverel or (Input and Input.mousemoverel) or mouse_moverel

	local Drawing = Drawing
	local newDrawing = Drawing and Drawing.new

	-- State tables
	local lplr_data = {
		gun = nil,
		tool = nil,
		ping = 60,
		typing = false,
		third_person = false,
		gradient_visible = false,
		position_body = nil
	}

	local player_data = {}

	-- Helper function to map character parts for both R6 and R15
	local function getCharacterParts(character)
		if not character then return {} end
		local parts = {}
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("BasePart") then
				parts[child.Name] = child
			end
		end
		if not parts["UpperTorso"] and parts["Torso"] then parts["UpperTorso"] = parts["Torso"] end
		if not parts["LowerTorso"] and parts["Torso"] then parts["LowerTorso"] = parts["Torso"] end
		if not parts["LeftUpperArm"] and parts["Left Arm"] then parts["LeftUpperArm"] = parts["Left Arm"] end
		if not parts["RightUpperArm"] and parts["Right Arm"] then parts["RightUpperArm"] = parts["Right Arm"] end
		if not parts["LeftUpperLeg"] and parts["Left Leg"] then parts["LeftUpperLeg"] = parts["Left Leg"] end
		if not parts["RightUpperLeg"] and parts["Right Leg"] then parts["RightUpperLeg"] = parts["Right Leg"] end
		if not parts["LeftFoot"] and parts["Left Leg"] then parts["LeftFoot"] = parts["Left Leg"] end
		if not parts["RightFoot"] and parts["Right Leg"] then parts["RightFoot"] = parts["Right Leg"] end
		if not parts["LeftHand"] and parts["Left Arm"] then parts["LeftHand"] = parts["Left Arm"] end
		if not parts["RightHand"] and parts["Right Arm"] then parts["RightHand"] = parts["Right Arm"] end
		return parts
	end

	local function trackPlayer(player)
		if player == LocalPlayer then return end
		local data = {
			character = player.Character,
			character_parts = getCharacterParts(player.Character),
			knocked = false,
			grabbed = false,
			forcefield = false
		}
		player_data[player] = data

		local function updateChar(char)
			data.character = char
			data.character_parts = getCharacterParts(char)
			if not char then return end

			char.ChildAdded:Connect(function(child)
				if child:IsA("BasePart") then
					data.character_parts[child.Name] = child
				elseif child:IsA("ForceField") then
					data.forcefield = true
				end
			end)
			char.ChildRemoved:Connect(function(child)
				if child:IsA("BasePart") then
					data.character_parts[child.Name] = nil
				elseif child:IsA("ForceField") then
					data.forcefield = false
				end
			end)

			local body_effects = char:FindFirstChild("BodyEffects")
			if body_effects then
				local ko = body_effects:FindFirstChild("K.O")
				if ko then
					data.knocked = ko.Value
					ko.Changed:Connect(function(val) data.knocked = val end)
				end
				local grabbed = body_effects:FindFirstChild("Grabbed")
				if grabbed then
					data.grabbed = grabbed.Value
					grabbed.Changed:Connect(function(val) data.grabbed = val end)
				end
			end
			if char:FindFirstChildOfClass("ForceField") then
				data.forcefield = true
			end
		end

		if player.Character then updateChar(player.Character) end
		player.CharacterAdded:Connect(updateChar)
	end

	for _, p in ipairs(Players:GetPlayers()) do trackPlayer(p) end
	Players.PlayerAdded:Connect(trackPlayer)
	Players.PlayerRemoving:Connect(function(p) player_data[p] = nil end)

	-- Safe Drawing Objects Constructor
	local function createCircle()
		if Drawing and Drawing.new then
			local ok, c = pcall(function() return Drawing.new("Circle") end)
			if ok and c then return c end
		end
		return nil
	end

	local function createLine()
		if Drawing and Drawing.new then
			local ok, l = pcall(function() return Drawing.new("Line") end)
			if ok and l then return l end
		end
		return nil
	end

	local aimbot = {
		circle_outline = createCircle(),
		circle = createCircle(),
		assist_circle_outline = createCircle(),
		assist_circle = createCircle(),
		line_outline = createLine(),
		line = createLine(),
		target = nil,
		target_position = nil,
		target_velocity = vector3new(0, 0, 0),
		last_position = nil,
		last_refresh = tick(),
		do_tp = false,
		silent_aim_fov = 67,
		aim_assist_fov = 67
	}

	if aimbot.circle_outline then
		aimbot.circle_outline.Filled = false
		aimbot.circle_outline.Radius = 67
		aimbot.circle_outline.Thickness = 4
		aimbot.circle_outline.ZIndex = 14
		aimbot.circle_outline.Color = Color3.fromRGB(0, 0, 0)
		aimbot.circle_outline.NumSides = 33
		aimbot.circle_outline.Visible = false
	end

	if aimbot.circle then
		aimbot.circle.Filled = false
		aimbot.circle.Radius = 67
		aimbot.circle.ZIndex = 15
		aimbot.circle.Thickness = 2
		aimbot.circle.Color = Color3.fromRGB(255, 255, 255)
		aimbot.circle.NumSides = 33
		aimbot.circle.Visible = false
	end

	if aimbot.assist_circle_outline then
		aimbot.assist_circle_outline.Filled = false
		aimbot.assist_circle_outline.Radius = 67
		aimbot.assist_circle_outline.Thickness = 4
		aimbot.assist_circle_outline.ZIndex = 14
		aimbot.assist_circle_outline.Color = Color3.fromRGB(0, 0, 0)
		aimbot.assist_circle_outline.NumSides = 33
		aimbot.assist_circle_outline.Visible = false
	end

	if aimbot.assist_circle then
		aimbot.assist_circle.Filled = false
		aimbot.assist_circle.Radius = 67
		aimbot.assist_circle.ZIndex = 15
		aimbot.assist_circle.Thickness = 2
		aimbot.assist_circle.Color = Color3.fromRGB(255, 255, 255)
		aimbot.assist_circle.NumSides = 33
		aimbot.assist_circle.Visible = false
	end

	if aimbot.line_outline then
		aimbot.line_outline.Thickness = 4
		aimbot.line_outline.ZIndex = 12
		aimbot.line_outline.Color = Color3.fromRGB(0, 0, 0)
		aimbot.line_outline.Visible = false
	end

	if aimbot.line then
		aimbot.line.Thickness = 2
		aimbot.line.ZIndex = 13
		aimbot.line.Color = Color3.fromRGB(255, 255, 255)
		aimbot.line.Visible = false
	end

	-- GUI Fallback Folder for executors lacking Drawing API
	local gui_folder = Instance.new("ScreenGui")
	gui_folder.Name = "NVL_Visualizers"
	gui_folder.ResetOnSpawn = false
	gui_folder.DisplayOrder = 999
	pcall(function() gui_folder.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)

	local ui_fov_circle = Instance.new("Frame")
	ui_fov_circle.AnchorPoint = Vector2.new(0.5, 0.5)
	ui_fov_circle.BackgroundTransparency = 1
	ui_fov_circle.BorderSizePixel = 0
	ui_fov_circle.Visible = false
	ui_fov_circle.Parent = gui_folder

	local ui_fov_stroke = Instance.new("UIStroke")
	ui_fov_stroke.Thickness = 2
	ui_fov_stroke.Color = Color3.fromRGB(255, 255, 255)
	ui_fov_stroke.Parent = ui_fov_circle

	local ui_fov_corner = Instance.new("UICorner")
	ui_fov_corner.CornerRadius = UDim.new(1, 0)
	ui_fov_corner.Parent = ui_fov_circle

	local ui_assist_circle = Instance.new("Frame")
	ui_assist_circle.AnchorPoint = Vector2.new(0.5, 0.5)
	ui_assist_circle.BackgroundTransparency = 1
	ui_assist_circle.BorderSizePixel = 0
	ui_assist_circle.Visible = false
	ui_assist_circle.Parent = gui_folder

	local ui_assist_stroke = Instance.new("UIStroke")
	ui_assist_stroke.Thickness = 2
	ui_assist_stroke.Color = Color3.fromRGB(255, 255, 255)
	ui_assist_stroke.Parent = ui_assist_circle

	local ui_assist_corner = Instance.new("UICorner")
	ui_assist_corner.CornerRadius = UDim.new(1, 0)
	ui_assist_corner.Parent = ui_assist_circle

	local bounding_box_object = Instance.new("SelectionBox")
	bounding_box_object.LineThickness = 0.01
	bounding_box_object.SurfaceColor3 = Color3.fromRGB(255, 255, 255)
	bounding_box_object.SurfaceTransparency = 1
	bounding_box_object.Color3 = Color3.fromRGB(255, 255, 255)
	pcall(function() bounding_box_object.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)

	local ignored_folder = workspace:FindFirstChild("Ignored") or workspace:FindFirstChildOfClass("Folder") or workspace

	-- Flexible Gun Types Categorization
	local function getGunType(tool_name)
		if not tool_name or type(tool_name) ~= "string" then return "Default" end
		local lower_name = string.lower(tool_name)
		if string.find(lower_name, "revolver") or string.find(lower_name, "glock") or string.find(lower_name, "silencer") or string.find(lower_name, "deagle") or string.find(lower_name, "pistol") then
			return "Pistols"
		elseif string.find(lower_name, "shotgun") or string.find(lower_name, "double-barrel") or string.find(lower_name, "db") or string.find(lower_name, "tactical") then
			return "Shotguns"
		elseif string.find(lower_name, "smg") or string.find(lower_name, "ar") or string.find(lower_name, "rifle") or string.find(lower_name, "ak47") or string.find(lower_name, "p90") or string.find(lower_name, "aug") or string.find(lower_name, "lmg") or string.find(lower_name, "drumgun") then
			return "Automatics"
		end
		return "Default"
	end

	-- Comprehensive Flag Lookup Mapping for NVL.lua UI Elements
	local function getFlag(gun_category, short_name, fallback_default)
		local mappings = {
			override_general = { gun_category .. "_override_general", "gun_override_general" },
			silent_fov = { gun_category .. "_silent_field_of_view", gun_category .. "_silent_fov", "gun_silent_fov", "Default_silent_field_of_view", "Default_silent_fov" },
			silent_h_pred = { gun_category .. "_silent_aim_horizontal_prediction", gun_category .. "_silent_h_pred", "gun_silent_h_pred" },
			silent_v_pred = { gun_category .. "_silent_aim_vertical_prediction", gun_category .. "_silent_v_pred", "gun_silent_v_pred" },
			air_hitbox = { gun_category .. "_air_hitbox", "gun_silent_air_hitbox", "gun_air_hitbox" },
			hitbox = { gun_category .. "_hitbox", "gun_silent_hitbox" },
			assist_fov = { gun_category .. "_aim_assist_field_of_view", gun_category .. "_assist_fov", "gun_assist_fov" },
			assist_h_pred = { gun_category .. "_aim_assist_horizontal_prediction", gun_category .. "_assist_h_pred", "gun_assist_h_pred" },
			assist_v_pred = { gun_category .. "_aim_assist_vertical_prediction", gun_category .. "_assist_v_pred", "gun_assist_v_pred" },
			assist_h_smooth = { gun_category .. "_aim_assist_horizontal_smoothness", gun_category .. "_assist_h_smooth", "gun_assist_h_smooth" },
			assist_v_smooth = { gun_category .. "_aim_assist_vertical_smoothness", gun_category .. "_assist_v_smooth", "gun_assist_v_smooth" },
			assist_h_shake = { gun_category .. "_aim_assist_horizontal_shake", gun_category .. "_assist_h_shake", "gun_assist_h_shake" },
			assist_v_shake = { gun_category .. "_aim_assist_vertical_shake", gun_category .. "_assist_v_shake", "gun_assist_v_shake" },
			smooth_dir = { gun_category .. "_smoothing_direction", gun_category .. "_smooth_dir", "gun_assist_smooth_dir" },
			smooth_style = { gun_category .. "_smoothing_style", gun_category .. "_smooth_style", "gun_assist_smooth_style" },
			cam_air_hitbox = { gun_category .. "_cam_air_hitbox", "gun_assist_air_hitbox" },
			cam_hitbox = { gun_category .. "_cam_hitbox", "gun_assist_hitbox" },
			jump_offset = { gun_category .. "_jump_offset", "gun_jump_offset" },
			jump_offset_value = { gun_category .. "_jump_offset_value", "gun_jump_offset_value" }
		}

		local keys_to_check = mappings[short_name]
		if keys_to_check then
			for _, k in ipairs(keys_to_check) do
				if flags[k] ~= nil then
					return flags[k]
				end
			end
		end

		if flags[short_name] ~= nil then
			return flags[short_name]
		end

		return fallback_default
	end

	local function wtvp(cam, pos3d)
		local screen_pos, on_screen = cam:WorldToViewportPoint(pos3d)
		return vector2new(screen_pos.X, screen_pos.Y), on_screen
	end

	local part_list = {"Head", "UpperTorso", "Torso", "LowerTorso", "LeftFoot", "LeftUpperLeg", "RightFoot", "RightUpperLeg", "LeftHand", "LeftUpperArm", "RightHand", "RightUpperArm", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

	local function getClosestHitbox(mouse_pos, character_parts)
		local closest = math.huge
		local closest_part = character_parts["HumanoidRootPart"] or character_parts["Head"] or character_parts["Torso"]

		for i = 1, #part_list do
			local part_name = part_list[i]
			local part = character_parts[part_name]
			if part then
				local pos, on_screen = wtvp(camera, part.Position)
				if on_screen then
					local distance = (mouse_pos - pos).magnitude
					if distance < closest then
						closest = distance
						closest_part = part
					end
				end
			end
		end

		return closest_part
	end

	local function hasCheck(checks, check_name)
		if type(checks) ~= "table" then return false end
		for k, v in pairs(checks) do
			if v == check_name or k == check_name then return true end
		end
		return false
	end

	-- Target candidate selection matching gamesenseuniversal.lua getAimbotCandidate
	local function getAimbotCandidate(mouse_position)
		local closest = math.huge
		local candidate = nil
		local position = nil
		local camera_pos = camera.CFrame.Position
		local max_target_distance = flags["max_target_distance"] or 2500
		local checks = flags["target_checks"] or {}
		local fov = math.max(aimbot.silent_aim_fov or 67, aimbot.aim_assist_fov or 67)

		for player, info in pairs(player_data) do
			local char = info.character
			if not char or not char.Parent then continue end

			local char_parts = info.character_parts
			local target_part = char_parts["Head"] or char_parts["UpperTorso"] or char_parts["Torso"] or char_parts["HumanoidRootPart"] or char:FindFirstChild("HumanoidRootPart")
			if not target_part then continue end

			local pos, on_screen = wtvp(camera, target_part.Position)
			if not on_screen then continue end

			local distance = (mouse_position - pos).magnitude
			if distance > fov then continue end

			local obj_distance = (camera_pos - target_part.Position).magnitude
			if obj_distance > max_target_distance then continue end

			local stop = false
			if hasCheck(checks, "Knocked") and info.knocked then stop = true end
			if not stop and hasCheck(checks, "Grabbed") and info.grabbed then stop = true end
			if not stop and hasCheck(checks, "Forcefield") and (info.forcefield or char:FindFirstChildOfClass("ForceField")) then stop = true end
			if not stop and hasCheck(checks, "Behind wall") then
				local ray_params = RaycastParams.new()
				ray_params.FilterDescendantsInstances = {char, LocalPlayer.Character, ignored_folder}
				ray_params.FilterType = Enum.RaycastFilterType.Exclude
				ray_params.IgnoreWater = true
				if raycast(workspace, camera_pos, (target_part.Position - camera_pos).unit * obj_distance, ray_params) then
					stop = true
				end
			end

			if stop then continue end

			if distance < closest then
				closest = distance
				candidate = player
				position = pos
			end
		end

		return candidate, position
	end

	-- Resolver Velocity Refresh Loop
	local function fixVelocity()
		if not flags["resolver"] or not aimbot.target then return end
		local target_info = player_data[aimbot.target]
		if not target_info or not target_info.character_parts then return end
		local hrp = target_info.character_parts["HumanoidRootPart"] or target_info.character_parts["Torso"]
		if not hrp then return end

		local refresh_interval = (flags["resolver_refresh"] or 18) / 1000
		local refresh_time = tick() - aimbot.last_refresh

		if refresh_time > refresh_interval then
			if not aimbot.last_position then
				aimbot.last_position = hrp.Position
			else
				aimbot.target_velocity = (hrp.Position - aimbot.last_position) / refresh_time
				aimbot.last_position = hrp.Position
			end
			aimbot.last_refresh = tick()
		end
	end

	-- Lock Bind Connection
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or getgenv()._nvl_suppress_keybind then return end
		local lock_key = flags["lock_bind"]
		if type(lock_key) == "table" and lock_key.key then lock_key = lock_key.key end
		if lock_key and input.KeyCode == lock_key then
			local mouse_pos = UserInputService:GetMouseLocation()
			local candidate = getAimbotCandidate(mouse_pos)
			if candidate == aimbot.target then
				aimbot.target = nil
			else
				aimbot.target = candidate
				aimbot.last_position = nil
				aimbot.target_velocity = vector3new(0, 0, 0)
			end
		end
	end)

	-- Tool Activation for Bullet TP and Anti-Aim Viewer
	local function onToolActivated(tool)
		tool.Activated:Connect(function()
			if flags["bullet_tp"] and aimbot.target and player_data[aimbot.target] then
				local target_parts = player_data[aimbot.target].character_parts
				local target_hrp = target_parts["HumanoidRootPart"] or target_parts["Torso"]
				local local_hrp = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Torso"))
				if target_hrp and local_hrp and tool:IsA("Tool") then
					local old_grip = tool.Grip
					tool.Grip = cframenew(target_hrp.Position):ToObjectSpace(local_hrp.CFrame)
					tool.Parent = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer
					task.wait(lplr_data.ping / 1000)
					if LocalPlayer.Character then
						tool.Parent = LocalPlayer.Character
					end
					tool.Grip = old_grip
				end
			end

			if flags["anti_aim_viewer"] and aimbot.target and player_data[aimbot.target] then
				local main_event = game:GetService("ReplicatedStorage"):FindFirstChild("MainEvent")
				if main_event then
					local target_parts = player_data[aimbot.target].character_parts
					local target_hrp = target_parts["HumanoidRootPart"] or target_parts["Torso"]
					if target_hrp then
						main_event:FireServer("UpdateMousePos", target_hrp.Position + vector3new(25, 100, 25))
					end
				end
			end
		end)
	end

	local function setupToolListeners(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				lplr_data.tool = child
				lplr_data.gun = getGunType(child.Name)
				onToolActivated(child)
			end
		end)
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				if lplr_data.tool == child then
					lplr_data.tool = nil
					lplr_data.gun = nil
				end
			end
		end)
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				lplr_data.tool = child
				lplr_data.gun = getGunType(child.Name)
				onToolActivated(child)
			end
		end
	end

	if LocalPlayer.Character then setupToolListeners(LocalPlayer.Character) end
	LocalPlayer.CharacterAdded:Connect(setupToolListeners)

	-- Main Execution Loop: RenderStepped
	table.insert(_nvl_conns, RunService.RenderStepped:Connect(function(dt)
		local mouse_position = UserInputService:GetMouseLocation()

		-- 1. Gun Category & Flag Resolution
		local gun = lplr_data.gun or "Default"
		local override = getFlag(gun, "override_general", false)
		local gun_prefix = (override and gun ~= "Default") and gun or "Default"

		local silent_fov_val = getFlag(gun_prefix, "silent_fov", 20)
		local assist_fov_val = getFlag(gun_prefix, "assist_fov", 20)

		aimbot.silent_aim_fov = silent_fov_val * 3.33
		aimbot.aim_assist_fov = assist_fov_val * 3.33

		local is_silent_aim_enabled = flags["silent_aim"] or flags["aimbot"] or (type(flags["aimbot_keybind"]) == "table" and flags["aimbot_keybind"].active)
		local is_assist_enabled = flags["aim_assist"] or (type(flags["aim_assist_keybind"]) == "table" and flags["aim_assist_keybind"].active)

		-- 2. FOV Visualizers Update (Drawing + ScreenGui Fallback)
		local show_silent_fov = (flags["show_fov"] == true) or (flags["show_fov"] ~= false and is_silent_aim_enabled)
		local show_assist_fov = (flags["aim_assist_fov"] == true) or (flags["aim_assist_fov"] ~= false and is_assist_enabled)

		-- Drawing circles
		if aimbot.circle then
			aimbot.circle.Position = mouse_position
			aimbot.circle.Radius = aimbot.silent_aim_fov
			aimbot.circle.Visible = show_silent_fov
			aimbot.circle.Filled = flags["show_fov_filled"] or false
			if flags["fov_color"] then aimbot.circle.Color = get_flag_color("fov_color") end
		end

		if aimbot.circle_outline then
			aimbot.circle_outline.Position = mouse_position
			aimbot.circle_outline.Radius = aimbot.silent_aim_fov
			aimbot.circle_outline.Visible = show_silent_fov
		end

		if aimbot.assist_circle then
			aimbot.assist_circle.Position = mouse_position
			aimbot.assist_circle.Radius = aimbot.aim_assist_fov
			aimbot.assist_circle.Visible = show_assist_fov
			aimbot.assist_circle.Filled = flags["aim_assist_fov_filled"] or false
			if flags["aim_assist_fov_color"] then aimbot.assist_circle.Color = get_flag_color("aim_assist_fov_color") end
		end

		if aimbot.assist_circle_outline then
			aimbot.assist_circle_outline.Position = mouse_position
			aimbot.assist_circle_outline.Radius = aimbot.aim_assist_fov
			aimbot.assist_circle_outline.Visible = show_assist_fov
		end

		-- ScreenGui fallback circles
		pcall(function()
			if setthreadidentity then pcall(setthreadidentity, 8) end
			if ui_fov_circle and ui_fov_circle.Parent then
				ui_fov_circle.Visible = show_silent_fov
				if show_silent_fov then
					ui_fov_circle.Position = UDim2.new(0, mouse_position.X, 0, mouse_position.Y)
					ui_fov_circle.Size = UDim2.new(0, aimbot.silent_aim_fov * 2, 0, aimbot.silent_aim_fov * 2)
					ui_fov_stroke.Color = flags["fov_color"] or Color3.fromRGB(255, 255, 255)
				end
			end
		end)

		pcall(function()
			if setthreadidentity then pcall(setthreadidentity, 8) end
			if ui_assist_circle and ui_assist_circle.Parent then
				ui_assist_circle.Visible = show_assist_fov
				if show_assist_fov then
					ui_assist_circle.Position = UDim2.new(0, mouse_position.X, 0, mouse_position.Y)
					ui_assist_circle.Size = UDim2.new(0, aimbot.aim_assist_fov * 2, 0, aimbot.aim_assist_fov * 2)
					ui_assist_stroke.Color = flags["aim_assist_fov_color"] or Color3.fromRGB(255, 255, 255)
				end
			end
		end)

		-- Reset line visibility by default
		if aimbot.line then aimbot.line.Visible = false end
		if aimbot.line_outline then aimbot.line_outline.Visible = false end

		fixVelocity()

		-- 3. Target Candidate Selection (Throttled: only compute candidate if aimbot/assist active)
		if is_silent_aim_enabled or is_assist_enabled then
			aimbot.target = getAimbotCandidate(mouse_position)
		else
			aimbot.target = nil
		end

		local target = aimbot.target
		local target_info = target and player_data[target]
		if not target or not target_info or not target_info.character then
			aimbot.target_position = nil
			bounding_box_object.Adornee = nil
			return
		end

		local target_char = target_info.character
		local character_parts = target_info.character_parts
		local humanoid = target_char:FindFirstChild("Humanoid")
		local hrp = character_parts["HumanoidRootPart"] or character_parts["Torso"] or character_parts["UpperTorso"]

		if not humanoid or not hrp then
			aimbot.target_position = nil
			bounding_box_object.Adornee = nil
			return
		end

		-- 4. Bounding Box Visualizer
		if flags["bounding_box"] then
			bounding_box_object.Adornee = target_char
			if flags["bounding_box_color"] then
				bounding_box_object.Color3 = flags["bounding_box_color"]
				bounding_box_object.SurfaceColor3 = flags["bounding_box_color"]
			end
			bounding_box_object.SurfaceTransparency = flags["bounding_box_filled"] and 0.5 or 1
		else
			bounding_box_object.Adornee = nil
		end

		-- 5. Hitbox Resolution & Physics Prediction
		local is_air = (humanoid.FloorMaterial == Enum.Material.Air)
		local hitbox_setting = is_air and getFlag(gun_prefix, "air_hitbox", "LowerTorso") or getFlag(gun_prefix, "hitbox", "Head")
		if type(hitbox_setting) == "table" then hitbox_setting = hitbox_setting[1] end

		local target_part = (hitbox_setting == "Closest") and getClosestHitbox(mouse_position, character_parts) or character_parts[hitbox_setting]
		if not target_part then target_part = hrp end

		local old_velocity = hrp.Velocity
		if flags["resolver"] then
			old_velocity = aimbot.target_velocity or hrp.Velocity
		end

		local velocity = old_velocity

		-- Y threshold clamp
		if flags["clamp_y"] and old_velocity.Y < (flags["clamp_y_value"] or -20) then
			velocity = velocity * vector3new(1, flags["clamp_multiplier"] or 0.15, 1)
		end

		local ping = (lplr_data.ping or 60) / 500
		local part_position = target_part.Position

		-- Multipoint
		if flags["multipoint"] then
			local multipoint_val = (flags["multipoint_value"] or 50) / 200
			local local_mouse = mouse.Hit and mouse.Hit.Position or part_position
			local cf = target_part.CFrame:PointToObjectSpace(local_mouse)
			local size = target_part.Size * multipoint_val
			part_position = target_part.CFrame * vector3new(mathclamp(cf.X, -size.X, size.X), mathclamp(cf.Y, -size.Y, size.Y), mathclamp(cf.Z, -size.Z, size.Z))
		end

		-- Jump Offset
		local use_jump_offset = getFlag(gun_prefix, "jump_offset", false)
		if use_jump_offset and old_velocity.Y > 12 then
			local jump_offset_val = getFlag(gun_prefix, "jump_offset_value", 0)
			part_position = part_position - vector3new(0, jump_offset_val, 0)
		end

		local aimbot_pos = nil

		-- 6. Silent Aim Branch
		if is_silent_aim_enabled then
			local stop = false
			local disable_when = flags["silent_aim_disable_when"] or {}

			if type(disable_when) == "table" then
				if hasCheck(disable_when, "Out of fov") then
					local pos = wtvp(camera, part_position)
					if (pos - mouse_position).magnitude > aimbot.silent_aim_fov then stop = true end
				end
				if not stop and hasCheck(disable_when, "Off screen") then
					local _, on_screen = wtvp(camera, part_position)
					if not on_screen then stop = true end
				end
				if not stop and hasCheck(disable_when, "Behind wall") then
					local ray_params = RaycastParams.new()
					ray_params.FilterDescendantsInstances = {target_char, LocalPlayer.Character, ignored_folder}
					ray_params.FilterType = Enum.RaycastFilterType.Exclude
					ray_params.IgnoreWater = true
					if raycast(workspace, camera.CFrame.Position, (part_position - camera.CFrame.Position).unit * (part_position - camera.CFrame.Position).magnitude, ray_params) then
						stop = true
					end
				end
			end

			if not stop then
				local h_pred = getFlag(gun_prefix, "silent_h_pred", 0)
				local v_pred = getFlag(gun_prefix, "silent_v_pred", 0)

				local pred_vec_h = (h_pred == 0) and vector3new(ping, 1, ping) or vector3new(h_pred, 1, h_pred)
				local pred_vec_v = (v_pred == 0) and vector3new(1, ping / 3, 1) or vector3new(1, v_pred, 1)

				velocity = velocity * pred_vec_h * pred_vec_v
				aimbot_pos = part_position + velocity

				-- Max curve calculation
				if flags["max_curve"] then
					local pos = wtvp(camera, aimbot_pos)
					local curve_val = (flags["max_curve_value"] or 100) / 100
					local world_position = mouse_position + ((pos - mouse_position) * curve_val)
					local ray = camera:ViewportPointToRay(world_position.X, flags["dont_curve_y"] and mouse_position.Y or world_position.Y)
					aimbot_pos = ray.Origin + ray.Direction * (ray.Origin - part_position).magnitude
				end
			end
		end

		-- 7. Position Line Visualizer (Runs independently if position_line is enabled)
		if flags["position_line"] and aimbot.line then
			local origin = mouse_position
			local dest_pos, dest_onscreen = wtvp(camera, aimbot_pos or (part_position + velocity))
			if dest_onscreen then
				aimbot.line.Visible = true
				aimbot.line.From = origin
				aimbot.line.To = dest_pos
				if flags["line_color"] then aimbot.line.Color = flags["line_color"] end

				if aimbot.line_outline then
					aimbot.line_outline.Visible = true
					aimbot.line_outline.From = origin
					aimbot.line_outline.To = dest_pos
				end
			end
		end

		-- 8. Aim Assist Logic (Runs independently if aim_assist is enabled)
		if is_assist_enabled then
			local disable_when = flags["aim_assist_disable_when"] or {}
			local stop_assist = false

			if type(disable_when) == "table" then
				if hasCheck(disable_when, "Not holding gun") and not lplr_data.gun then stop_assist = true end
				if not stop_assist and hasCheck(disable_when, "Out of fov") then
					local pos = wtvp(camera, part_position)
					if (pos - mouse_position).magnitude > aimbot.aim_assist_fov then stop_assist = true end
				end
				if not stop_assist and hasCheck(disable_when, "Off screen") then
					local _, on_screen = wtvp(camera, part_position)
					if not on_screen then stop_assist = true end
				end
				if not stop_assist and hasCheck(disable_when, "Behind wall") then
					local ray_params = RaycastParams.new()
					ray_params.FilterDescendantsInstances = {target_char, LocalPlayer.Character, ignored_folder}
					ray_params.FilterType = Enum.RaycastFilterType.Exclude
					ray_params.IgnoreWater = true
					if raycast(workspace, camera.CFrame.Position, (part_position - camera.CFrame.Position).unit * (part_position - camera.CFrame.Position).magnitude, ray_params) then
						stop_assist = true
					end
				end
			end

			if not stop_assist then
				local cam_hitbox = is_air and getFlag(gun_prefix, "cam_air_hitbox", "LowerTorso") or getFlag(gun_prefix, "cam_hitbox", "Head")
				if type(cam_hitbox) == "table" then cam_hitbox = cam_hitbox[1] end

				local cam_part = (cam_hitbox == "Closest") and getClosestHitbox(mouse_position, character_parts) or character_parts[cam_hitbox]
				if not cam_part then cam_part = hrp end

				local cam_pos = cam_part.Position
				local h_pred = getFlag(gun_prefix, "assist_h_pred", 0)
				local v_pred = getFlag(gun_prefix, "assist_v_pred", 0)
				local h_smooth = getFlag(gun_prefix, "assist_h_smooth", 90)

				local assist_velocity = old_velocity * ((h_pred == 0) and vector3new(ping, 1, ping) or vector3new(h_pred, 1, h_pred)) * ((v_pred == 0) and vector3new(1, ping / 3, 1) or vector3new(1, v_pred, 1))

				-- Add shake offset if set
				local h_shake = getFlag(gun_prefix, "assist_h_shake", 0)
				local v_shake = getFlag(gun_prefix, "assist_v_shake", 0)
				if h_shake > 0 then
					assist_velocity = assist_velocity + vector3new(mathrandom(1, h_shake + 1) / (mathrandom(2) == 1 and -50 or 50), 0, mathrandom(1, h_shake + 1) / (mathrandom(2) == 1 and -50 or 50))
				end
				if v_shake > 0 then
					assist_velocity = assist_velocity + vector3new(0, mathrandom(1, v_shake + 1) / (mathrandom(2) == 1 and -50 or 50), 0)
				end

				local final_assist_pos = cam_pos + assist_velocity
				local smooth_factor = (100.01 - h_smooth) / 100

				local style_str = flags["aim_assist_style"]
				if type(style_str) == "table" then style_str = style_str[1] end

				if style_str == "Mouse" and mousemoverel then
					local screen_pos = wtvp(camera, final_assist_pos)
					local delta = screen_pos - mouse_position
					mousemoverel(delta.X * smooth_factor, delta.Y * smooth_factor)
				else
					camera.CFrame = camera.CFrame:Lerp(cframenew(camera.CFrame.Position, final_assist_pos), smooth_factor)
				end
			end
		end

		aimbot.target_position = aimbot_pos or (part_position + velocity)
	end))

	-- Standard Metatable hooks for Silent Aim
	local old_namecall
	local old_index

	local function namecall_hook(self, ...)
		local method = getnamecallmethod and getnamecallmethod()
		local args = {...}

		if flags["silent_aim"] and aimbot.target_position then
			if method == "FireServer" or method == "InvokeServer" then
				local arg1 = args[1]
				if type(arg1) == "string" and (arg1 == "UpdateMousePos" or arg1 == "MousePos" or arg1 == "MousePosUpdate" or arg1 == "MOUSE" or arg1 == "Shoot" or arg1 == "Hit") then
					args[2] = aimbot.target_position
					return old_namecall(self, unpack(args))
				end

				for i, arg in ipairs(args) do
					if type(arg) == "Vector3" then
						args[i] = aimbot.target_position
					elseif type(arg) == "table" then
						for k, v in pairs(arg) do
							if type(v) == "Vector3" then
								arg[k] = aimbot.target_position
							end
						end
					end
				end
				return old_namecall(self, unpack(args))
			end
		end

		return old_namecall(self, ...)
	end

	local function index_hook(self, k)
		if flags["silent_aim"] and aimbot.target_position then
			if self == mouse then
				if k == "Hit" or k == "hit" then
					return cframenew(aimbot.target_position)
				elseif k == "Target" or k == "target" then
					if aimbot.target and player_data[aimbot.target] then
						local target_parts = player_data[aimbot.target].character_parts
						return target_parts["HumanoidRootPart"] or target_parts["Torso"] or target_parts["Head"]
					end
				end
			end
		end
		return old_index(self, k)
	end

	if hookmetamethod then
		old_namecall = hookmetamethod(game, "__namecall", newcclosure(namecall_hook))
		old_index = hookmetamethod(game, "__index", newcclosure(index_hook))
	elseif getrawmetatable and setreadonly then
		local gmt = getrawmetatable(game)
		setreadonly(gmt, false)
		old_namecall = gmt.__namecall
		old_index = gmt.__index
		gmt.__namecall = newcclosure(namecall_hook)
		gmt.__index = newcclosure(index_hook)
		setreadonly(gmt, true)
	end
end

-- ==========================================
-- 2. Tab Anti-aim (Ảnh 3)
-- ==========================================
do
	local main_aa = antiaim:section({ name = "Anti aim", side = "left" })

	local function get_flag_color(flag_name, default_color)
		local def = default_color or Color3.fromRGB(0, 255, 100)
		local data = flags[flag_name]
		if typeof(data) == "Color3" then
			return data
		elseif type(data) == "table" then
			if typeof(data.Color) == "Color3" then
				return data.Color
			elseif type(data.Color) == "table" and #data.Color >= 3 then
				return Color3.fromRGB(data.Color[1], data.Color[2], data.Color[3])
			elseif #data >= 3 and type(data[1]) == "number" then
				return Color3.fromRGB(data[1], data[2], data[3])
			end
		end
		return def
	end

	local function get_flag_transparency(flag_name)
		local data = flags[flag_name]
		if type(data) == "table" and data.Transparency then
			local t = data.Transparency
			if t >= 0.99 then
				return 0.3
			elseif t <= 0.01 then
				return 0.9
			else
				return math.clamp(1 - t, 0.05, 0.95)
			end
		end
		return 0.3
	end

	main_aa:toggle({
		name = "Destroy cheaters",
		flag = "aa_destroy_cheaters",
		default = false
	}):keybind({
		flag = "aa_destroy_cheaters_bind"
	})

	-- BodyCloneDesync Visualization Logic (cloned directly from LocalPlayer to accurately preserve female / custom avatars)
	local BodyCloneDesync = nil
	local BodyCloneDesyncHighlight = nil
	local GlowLight = nil

	local function setup_body_clone()
		pcall(function()
			if BodyCloneDesync then
				BodyCloneDesync:Destroy()
				BodyCloneDesync = nil
			end
		end)

		local char = LocalPlayer.Character
		if not char then return end

		local prev_archivable = char.Archivable
		char.Archivable = true
		local clone = char:Clone()
		char.Archivable = prev_archivable

		if not clone then return end
		clone.Name = "BodyCloneDesync"

		for _, child in ipairs(clone:GetChildren()) do
			if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("Sound") or child:IsA("ParticleEmitter") then
				pcall(function() child:Destroy() end)
			end
		end

		local hum = clone:FindFirstChildOfClass("Humanoid")
		if hum then
			pcall(function() hum:Destroy() end)
		end

		local head = clone:FindFirstChild("Head")
		if head then
			local face = head:FindFirstChild("face") or head:FindFirstChild("Face")
			if face then pcall(function() face:Destroy() end) end
		end

		local hrp = clone:FindFirstChild("HumanoidRootPart")
		if hrp then
			clone.PrimaryPart = hrp
			hrp.Transparency = 1
			hrp.CanCollide = false
			hrp.Velocity = Vector3.zero
		end

		for _, v in pairs(clone:GetDescendants()) do
			if v:IsA("BasePart") or v:IsA("MeshPart") then
				v.CanCollide = false
				v.Anchored = true
				v.CastShadow = false
				v.Transparency = 1 -- Hide until visualization is active
			end
		end

		BodyCloneDesyncHighlight = Instance.new("Highlight")
		BodyCloneDesyncHighlight.Enabled = false
		BodyCloneDesyncHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		BodyCloneDesyncHighlight.FillColor = Color3.fromRGB(0, 255, 100)
		BodyCloneDesyncHighlight.OutlineColor = Color3.fromRGB(0, 255, 100)
		BodyCloneDesyncHighlight.FillTransparency = 0.3
		BodyCloneDesyncHighlight.OutlineTransparency = 0
		BodyCloneDesyncHighlight.Adornee = clone
		BodyCloneDesyncHighlight.Parent = clone

		GlowLight = Instance.new("PointLight")
		GlowLight.Color = Color3.fromRGB(0, 255, 100)
		GlowLight.Brightness = 4
		GlowLight.Range = 2
		if hrp then
			GlowLight.Parent = hrp
		end

		clone.Parent = workspace
		pcall(function()
			clone:SetPrimaryPartCFrame(CFrame.new(9999, 9999, 9999))
		end)
		BodyCloneDesync = clone
	end

	pcall(setup_body_clone)
	table.insert(_nvl_conns, LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.5)
		pcall(setup_body_clone)
	end))

	local DesyncLine1 = Drawing.new('Line')
	DesyncLine1.Thickness = 2
	DesyncLine1.Color = Color3.fromRGB(0, 255, 100)
	DesyncLine1.Visible = false
	DesyncLine1.Transparency = 1

	local DesyncDot = Drawing.new('Circle')
	DesyncDot.Radius = 6
	DesyncDot.Thickness = 1.5
	DesyncDot.NumSides = 16
	DesyncDot.Color = Color3.fromRGB(0, 255, 100)
	DesyncDot.Filled = true
	DesyncDot.Transparency = 1
	DesyncDot.Visible = false

	local DesyncStatus = Drawing.new('Text')
	DesyncStatus.Text = 'Desync: FALSE'
	DesyncStatus.Size = 16
	DesyncStatus.Font = 2
	DesyncStatus.Color = Color3.fromRGB(255, 0, 0)
	DesyncStatus.Outline = true
	DesyncStatus.OutlineColor = Color3.fromRGB(0, 0, 0)
	DesyncStatus.Center = false
	DesyncStatus.Visible = false
	DesyncStatus.Position = Vector2.new(100, 100)

	-- Smooth Camera Fix Part (Matches cframe_fix method from V2unIersIsAl.lua & Skeet.lua)
	local cframe_fix = Instance.new("Part")
	cframe_fix.Name = "CFrameFixPart"
	cframe_fix.Size = Vector3.new(0.001, 0.001, 0.001)
	cframe_fix.Transparency = 1
	cframe_fix.CanCollide = false
	cframe_fix.Anchored = true
	cframe_fix.Parent = workspace

	-- Safe Platform Part for Underground & Custom Part
	local safe_platform = Instance.new("Part")
	safe_platform.Name = "SafePlatform"
	safe_platform.Size = Vector3.new(14, 1, 14)
	safe_platform.Transparency = 0.4
	safe_platform.CanCollide = false
	safe_platform.Anchored = true
	safe_platform.Material = Enum.Material.Neon
	safe_platform.Color = Color3.fromRGB(0, 255, 120)
	safe_platform.TopSurface = Enum.SurfaceType.Smooth
	safe_platform.BottomSurface = Enum.SurfaceType.Smooth
	safe_platform.CFrame = CFrame.new(9999, 9999, 9999)
	safe_platform.Parent = workspace

	local _underground_locked_y = nil
	local _last_part_shape = nil
	local _last_part_mat = nil
	local _last_part_color = nil
	local _last_part_trans = nil
	local _last_part_size = nil
	local _part_special_mesh = nil

	local function hide_safe_platform()
		if safe_platform.CanCollide or safe_platform.Position.X < 9000 then
			safe_platform.CFrame = CFrame.new(9999, 9999, 9999)
			safe_platform.CanCollide = false
			_underground_locked_y = nil
		end
	end

	-- Underground Part mode: Fade Part helper (create fading clone of current platform)
	local _ug_fade_parts = {}
	local MAX_UG_FADE_PARTS = 5

	local function create_ug_fade_part(cf, size_v, mat_e, col_3, trans_v, shape_str)
		local fp = Instance.new("Part")
		fp.Name = "UGFadePart"
		fp.Anchored = true
		fp.CanCollide = false
		fp.Size = size_v
		fp.Material = mat_e
		fp.Color = col_3
		fp.Transparency = trans_v
		fp.CFrame = cf
		fp.TopSurface = Enum.SurfaceType.Smooth
		fp.BottomSurface = Enum.SurfaceType.Smooth
		if shape_str == "Circle" or shape_str == "Hexagon" then
			fp.Shape = Enum.PartType.Cylinder
		elseif shape_str == "Shield" then
			fp.Shape = Enum.PartType.Ball
		else
			fp.Shape = Enum.PartType.Block
		end
		fp.Parent = workspace
		local tw = TweenService:Create(fp, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 })
		tw:Play()
		tw.Completed:Connect(function()
			pcall(function() fp:Destroy() end)
		end)
		table.insert(_ug_fade_parts, fp)
		while #_ug_fade_parts > MAX_UG_FADE_PARTS do
			local old = table.remove(_ug_fade_parts, 1)
			if old and old.Parent then pcall(function() old:Destroy() end) end
		end
	end

	local function cleanup_ug_fade_parts()
		for _, p in ipairs(_ug_fade_parts) do
			if p and p.Parent then pcall(function() p:Destroy() end) end
		end
		_ug_fade_parts = {}
	end

	local function update_safe_platform_properties(shape, mat_enum, color_3, trans, size_vec)
		if _last_part_mat ~= mat_enum then
			_last_part_mat = mat_enum
			safe_platform.Material = mat_enum
		end
		if _last_part_color ~= color_3 then
			_last_part_color = color_3
			safe_platform.Color = color_3
		end
		if _last_part_trans ~= trans then
			_last_part_trans = trans
			safe_platform.Transparency = trans
		end

		if _last_part_shape ~= shape or _last_part_size ~= size_vec then
			local shape_changed = (_last_part_shape ~= shape)
			_last_part_shape = shape
			_last_part_size = size_vec

			if shape_changed and _part_special_mesh then
				_part_special_mesh:Destroy()
				_part_special_mesh = nil
			end

			if shape == "Circle" then
				safe_platform.Shape = Enum.PartType.Cylinder
				safe_platform.Size = size_vec
			elseif shape == "Square" then
				safe_platform.Shape = Enum.PartType.Block
				safe_platform.Size = size_vec
			elseif shape == "Hexagon" then
				safe_platform.Shape = Enum.PartType.Cylinder
				safe_platform.Size = size_vec
				if not _part_special_mesh then
					_part_special_mesh = Instance.new("SpecialMesh")
					_part_special_mesh.MeshType = Enum.MeshType.Cylinder
					_part_special_mesh.Parent = safe_platform
				end
			elseif shape == "Shield" then
				safe_platform.Shape = Enum.PartType.Ball
				safe_platform.Size = size_vec
			elseif shape == "Star" then
				safe_platform.Shape = Enum.PartType.Block
				safe_platform.Size = size_vec
				if not _part_special_mesh then
					_part_special_mesh = Instance.new("SpecialMesh")
					_part_special_mesh.MeshType = Enum.MeshType.FileMesh
					_part_special_mesh.MeshId = "rbxassetid://6015505199"
					_part_special_mesh.Parent = safe_platform
				end
				_part_special_mesh.Scale = Vector3.new(size_vec.X / 4, size_vec.Y, size_vec.Z / 4)
			elseif shape == "Ring" then
				safe_platform.Shape = Enum.PartType.Block
				safe_platform.Size = size_vec
				if not _part_special_mesh then
					_part_special_mesh = Instance.new("SpecialMesh")
					_part_special_mesh.MeshType = Enum.MeshType.FileMesh
					_part_special_mesh.MeshId = "rbxassetid://3270017"
					_part_special_mesh.Parent = safe_platform
				end
				_part_special_mesh.Scale = Vector3.new(size_vec.X / 2, size_vec.Z / 2, size_vec.Y * 2)
			else
				safe_platform.Shape = Enum.PartType.Block
				safe_platform.Size = size_vec
			end
		end
	end

	local freeze_locked_cframe = nil

	-- Character part cache for transparency (avoid GetDescendants every frame)
	local _cached_char_parts = {}
	local _cached_char_ref = nil
	local _cached_fp_state = nil

	local function refresh_char_parts_cache()
		local char = LocalPlayer.Character
		if not char or char == _cached_char_ref then return end
		_cached_char_ref = char
		_cached_fp_state = nil
		_cached_char_parts = {}
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				table.insert(_cached_char_parts, part)
			end
		end
		-- Listen for new parts added to character (tools, accessories equipped mid-game)
		char.DescendantAdded:Connect(function(part)
			if (part:IsA("BasePart") or part:IsA("Decal")) and _cached_char_ref == char then
				table.insert(_cached_char_parts, part)
			end
		end)
	end

	local function set_transparency(is_first_person)
		if _cached_fp_state == is_first_person then return end
		_cached_fp_state = is_first_person
		local val = is_first_person and 1 or 0
		for i = #_cached_char_parts, 1, -1 do
			local part = _cached_char_parts[i]
			if part and part.Parent then
				part.LocalTransparencyModifier = val
			else
				table.remove(_cached_char_parts, i)
			end
		end
	end

	local function resetCamera()
		-- Don't destroy platform when Custom Part or Underground Part is active
		if not flags["aa_custom_part"] and not _ug_part_active then
			hide_safe_platform()
		end
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid') then
			if library and library.viewing_player and library.viewing_player.Character and library.viewing_player.Character:FindFirstChildOfClass("Humanoid") then
				if camera.CameraSubject ~= library.viewing_player.Character:FindFirstChildOfClass("Humanoid") then
					camera.CameraSubject = library.viewing_player.Character:FindFirstChildOfClass("Humanoid")
				end
			else
				if camera.CameraSubject ~= LocalPlayer.Character.Humanoid then
					camera.CameraSubject = LocalPlayer.Character.Humanoid
				end
			end
			refresh_char_parts_cache()
			set_transparency(false)
		end
	end

	local function hide_desync_clone()
		if BodyCloneDesync then
			if BodyCloneDesyncHighlight then
				BodyCloneDesyncHighlight.Enabled = false
			end
			for _, v in pairs(BodyCloneDesync:GetDescendants()) do
				if v:IsA("BasePart") or v:IsA("MeshPart") then
					v.Transparency = 1
				end
			end
			pcall(function()
				BodyCloneDesync:SetPrimaryPartCFrame(CFrame.new(9999, 9999, 9999))
			end)
		end
	end

	-- Shared state between Heartbeat (set desync) and BindToRenderStep (restore client)
	local _desync_old_cf = nil
	local _desync_old_vel = nil
	local _desync_cam_mode = nil
	local _desync_mode_cache = nil
	local _desync_frame_active = false
	local _last_viz_mat = nil

	-- Underground Part mode state
	local _ug_part_active = false
	local _ug_part_last_offset = Vector3.zero
	local _ug_jump_in_progress = false

	-- Desync Main Heartbeat Loop: Set desync CFrame for server replication
	-- Runs AFTER physics → CFrame persists until next frame's BindToRenderStep restores it
	table.insert(_nvl_conns, RunService.Heartbeat:Connect(function()
		local desync_mode = flags["desync_mode"] or "Custom"

		if not LocalPlayer.Character then
			freeze_locked_cframe = nil
			_desync_frame_active = false
			_ug_part_active = false
			_ug_part_last_offset = Vector3.zero
			hide_desync_clone()
			DesyncLine1.Visible = false
			DesyncDot.Visible = false
			DesyncStatus.Visible = false
			resetCamera()
			return
		end

		local hrp = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
		if not hrp then
			freeze_locked_cframe = nil
			_desync_frame_active = false
			_ug_part_active = false
			_ug_part_last_offset = Vector3.zero
			DesyncDot.Visible = false
			return
		end

		local oldCFrame = hrp.CFrame
		local oldVelocity = hrp.AssemblyLinearVelocity
		local desyncCFrame = oldCFrame

		-- Underground Part mode: Physically move character to offset position (separate from desync system)
		local _ug_mode_str = flags["aa_underground_mode"] or "Underground"
		if type(_ug_mode_str) == "table" then _ug_mode_str = _ug_mode_str[1] end
		local is_ug_part_mode = flags["aa_underground"] and (_ug_mode_str == "Underground Part")

		if is_ug_part_mode then
			local off_x = flags["aa_underground_x"] or 0
			local off_y = flags["aa_underground_y"] or 0
			local off_z = flags["aa_underground_z"] or 0
			local new_offset = Vector3.new(off_x, off_y, off_z)
			local delta = new_offset - _ug_part_last_offset
			if delta.Magnitude > 0.001 then
				pcall(function()
					hrp.CFrame = hrp.CFrame + delta
				end)
				_ug_part_last_offset = new_offset
			end
			_ug_part_active = true
		elseif _ug_part_active then
			-- Was in Underground Part mode, now switching back: remove last applied offset
			pcall(function()
				hrp.CFrame = hrp.CFrame - _ug_part_last_offset
			end)
			_ug_part_last_offset = Vector3.zero
			_ug_part_active = false
			_ug_jump_in_progress = false
			cleanup_ug_fade_parts()
		end

		-- Exclude Underground Part from desync (it's handled above, not via ghost CFrame)
		local is_desync_enabled = not is_ug_part_mode and (flags["desync_enabled"] or flags["aa_underground"] or flags["aa_random_teleport"] or flags["aa_velocity_desync"] or flags["aa_orbit"] or flags["aa_void_spam"])

		if is_desync_enabled then
			if desync_mode == "Freeze" then
				if not freeze_locked_cframe then
					freeze_locked_cframe = oldCFrame
				end
				desyncCFrame = freeze_locked_cframe
			else
				freeze_locked_cframe = nil
			end

			if flags["aa_underground"] then
				local off_x = flags["aa_underground_x"] or 0
				local off_y = flags["aa_underground_y"] or 0
				local off_z = flags["aa_underground_z"] or 0
				local x_body = flags["aa_underground_x_body"] or flags["aa_underground_xyz_body"] or 0
				local y_body = flags["aa_underground_y_body"] or 0
				desyncCFrame = (hrp.CFrame + Vector3.new(off_x, off_y, off_z)) * CFrame.Angles(math.rad(y_body), math.rad(x_body), 0)
			elseif flags["aa_random_teleport"] then
				local h_off = flags["aa_horizontal_offset"] or 5
				local v_off = flags["aa_vertical_offset"] or 5
				desyncCFrame = hrp.CFrame - Vector3.new(math.random(-h_off, h_off), math.random(-v_off, v_off), math.random(-h_off, h_off))
			elseif flags["aa_orbit"] then
				local speed = flags["aa_orbit_speed"] or 10
				local rad_x = flags["aa_orbit_x"] or 10
				local off_y = flags["aa_orbit_y"] or 0
				local t = tick() * (speed * 0.1)
				local offset = Vector3.new(math.cos(t) * rad_x, off_y, math.sin(t) * rad_x)
				local spin = CFrame.Angles(0, math.rad((tick() * 10) % 360), 0)
				desyncCFrame = CFrame.new(oldCFrame.Position + offset) * spin
			elseif flags["aa_velocity_desync"] then
				desyncCFrame = hrp.CFrame + Vector3.new(0, -100, 0)
			elseif flags["aa_void_spam"] then
				desyncCFrame = (math.random(1, 2) == 1) and oldCFrame or CFrame.new(math.random(10000, 50000), math.random(10000, 50000), math.random(10000, 50000)) * oldCFrame.Rotation
			elseif desync_mode == 'Destroy Cheaters' then
				desyncCFrame = CFrame.new(9e9, 1, 1) * oldCFrame.Rotation
			elseif desync_mode == 'Underground' then
				local off_x = flags["aa_underground_x"] or 0
				local off_y = flags["aa_underground_y"] or 0
				local off_z = flags["aa_underground_z"] or 0
				local x_body = flags["aa_underground_x_body"] or flags["aa_underground_xyz_body"] or 0
				local y_body = flags["aa_underground_y_body"] or 0
				desyncCFrame = (hrp.CFrame + Vector3.new(off_x, off_y, off_z)) * CFrame.Angles(math.rad(y_body), math.rad(x_body), 0)
			elseif desync_mode == 'Void' then
				desyncCFrame = (oldCFrame + Vector3.new(math.random(-444444, 444444), math.random(-444444, 444444), math.random(-44444, 44444))) * oldCFrame.Rotation
			elseif desync_mode == 'Random' then
				local amount = flags["desync_random_amount"] or 20
				local offset = Vector3.new(math.random(-amount, amount), math.random(-amount / 2, amount / 2), math.random(-amount, amount))
				desyncCFrame = CFrame.new(oldCFrame.Position + offset) * oldCFrame.Rotation
			elseif desync_mode == 'Safe Shoot' then
				desyncCFrame = CFrame.new(hrp.Position - Vector3.new(0, 5, 0)) * CFrame.Angles(math.random(0, 360), math.random(0, 360), math.rad(180))
			elseif desync_mode == 'Custom' then
				local cx = flags["desync_custom_x"] or 0
				local cy = flags["desync_custom_y"] or 0
				local cz = flags["desync_custom_z"] or 0
				-- Local-space offset: follows character look direction, perfectly aligned at 0
				desyncCFrame = oldCFrame * CFrame.new(-cx, -cy, -cz)
			elseif desync_mode == 'Orbit' then
				local speed = flags["aa_orbit_speed"] or 10
				local rad_x = flags["aa_orbit_x"] or 10
				local off_y = flags["aa_orbit_y"] or 0
				local t = tick() * (speed * 0.1)
				local offset = Vector3.new(math.cos(t) * rad_x, off_y, math.sin(t) * rad_x)
				local spin = CFrame.Angles(0, math.rad((tick() * 10) % 360), 0)
				desyncCFrame = CFrame.new(oldCFrame.Position + offset) * spin
			end

			-- Active Anti-Sleep Physics Keep-Alive (Only spins when spinbot is enabled with desync)
			local is_orbit_mode = flags["aa_orbit"] or (desync_mode == 'Orbit')
			local is_spin_active = flags["char_spinbot"] == true
			if is_spin_active then
				local spd = flags["char_spinbot_speed"] or 1
				local deg_per_sec = spd * 360
				pcall(function()
					sethiddenproperty(hrp, "NetworkIsSleeping", false)
					hrp.AssemblyAngularVelocity = Vector3.new(0, math.rad(deg_per_sec), 0)
				end)
				if not is_orbit_mode then
					local anti_sleep_spin = CFrame.Angles(0, math.rad((tick() * deg_per_sec) % 360), 0)
					desyncCFrame = desyncCFrame * anti_sleep_spin
				end
			else
				pcall(function()
					sethiddenproperty(hrp, "NetworkIsSleeping", false)
					hrp.AssemblyAngularVelocity = Vector3.zero
				end)
			end

			hrp.CFrame = desyncCFrame
			local_parts["DesyncedCF"] = desyncCFrame

			-- Save state for BindToRenderStep to restore client
			_desync_old_cf = oldCFrame
			local raw_cam_mode = flags["aa_underground_camera_mode"] or "Camera"
			if type(raw_cam_mode) == "table" then raw_cam_mode = raw_cam_mode[1] end
			_desync_cam_mode = raw_cam_mode or "Camera"
			_desync_mode_cache = desync_mode
			_desync_frame_active = true
		else
			freeze_locked_cframe = nil
			_desync_frame_active = false
			pcall(function()
				hrp.AssemblyAngularVelocity = Vector3.zero
			end)
			resetCamera()
		end

		local visualizeCFrame = is_desync_enabled and desyncCFrame or hrp.CFrame
		local is_visualize_active = is_desync_enabled and (flags["desync_visualize"] or flags["aa_underground_visualize"] or flags["aa_random_teleport_visualize"] or flags["aa_orbit_visualize"] or flags["position_body"])

		-- Visualize Body Clone
		if is_visualize_active and BodyCloneDesync then
			local viz_color = get_flag_color("desync_viz_color")
			if flags["desync_viz_color"] == nil then
				viz_color = get_flag_color("position_body_color")
			end
			local viz_trans = get_flag_transparency("desync_viz_color")

			local mat_str = flags["desync_viz_material"] or flags["position_body_material"]
			if type(mat_str) == "table" then mat_str = mat_str[1] end
			local target_mat = Enum.Material[mat_str or "ForceField"]

			if _last_viz_mat ~= target_mat then
				_last_viz_mat = target_mat
				for _, v in pairs(BodyCloneDesync:GetDescendants()) do
					if v:IsA("BasePart") or v:IsA("MeshPart") then
						v.Material = target_mat
					end
				end
			end

			for _, v in pairs(BodyCloneDesync:GetDescendants()) do
				if v:IsA("BasePart") or v:IsA("MeshPart") then
					v.Transparency = (v.Name == "HumanoidRootPart") and 1 or viz_trans
				end
			end

			if BodyCloneDesyncHighlight then
				BodyCloneDesyncHighlight.FillColor = viz_color
				BodyCloneDesyncHighlight.OutlineColor = viz_color
				BodyCloneDesyncHighlight.FillTransparency = viz_trans
				BodyCloneDesyncHighlight.OutlineTransparency = 0
				BodyCloneDesyncHighlight.Enabled = true
			end
			if GlowLight then
				GlowLight.Color = viz_color
			end
			pcall(function()
				BodyCloneDesync:SetPrimaryPartCFrame(visualizeCFrame)
			end)
		else
			hide_desync_clone()
		end

		-- Line Desync
		if is_desync_enabled and flags["desync_line"] then
			local screenRoot, onScreenRoot = camera:WorldToViewportPoint(visualizeCFrame.Position)
			local mouseLocation = UserInputService:GetMouseLocation()
			if onScreenRoot then
				DesyncLine1.From = mouseLocation
				DesyncLine1.To = Vector2.new(screenRoot.X, screenRoot.Y)
				DesyncLine1.Color = get_flag_color("desync_line_color")
				DesyncLine1.Visible = true
			else
				DesyncLine1.Visible = false
			end
		else
			DesyncLine1.Visible = false
		end

		-- Dot Desync
		if is_desync_enabled and flags["desync_dot"] then
			local screenPos, onScreen = camera:WorldToViewportPoint(visualizeCFrame.Position)
			if onScreen then
				DesyncDot.Position = Vector2.new(screenPos.X, screenPos.Y)
				DesyncDot.Color = get_flag_color("desync_dot_color")
				DesyncDot.Visible = true
			else
				DesyncDot.Visible = false
			end
		else
			DesyncDot.Visible = false
		end

		-- Desync Status Text
		if flags["desync_status"] then
			DesyncStatus.Text = 'Desync: ' .. (is_desync_enabled and 'TRUE' or 'FALSE')
			DesyncStatus.Color = is_desync_enabled and get_flag_color("desync_status_color") or Color3.fromRGB(255, 0, 0)
			DesyncStatus.Visible = true
		else
			DesyncStatus.Visible = false
		end
	end))

	-- Desync Client Restore: BindToRenderStep runs BEFORE rendering
	-- Restores client CFrame so player sees correct position, while server already received desync CFrame from Heartbeat
	local _current_evolator_y = 0
	local _last_evolator_time = tick()

	RunService:BindToRenderStep("DesyncClientRestore", 1, function()
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild('HumanoidRootPart')

		if _desync_frame_active and hrp and _desync_old_cf then
			_desync_frame_active = false
			hrp.CFrame = _desync_old_cf
		end

		if not char or not hrp then return end

		-- Update Safe Platform / Custom Part / Underground Part platform
		local is_custom = flags["aa_custom_part"] == true
		local is_plat_needed = _ug_part_active or is_custom

		if is_plat_needed then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local hip = (humanoid and humanoid.HipHeight) or 2
			if hip <= 0 then hip = 2 end
			local half_h = hrp.Size.Y / 2
			local feet_y = hrp.Position.Y - (half_h + hip)

			-- Styling parameters: Underground Part and Custom Part both configure from Custom Part settings (radius, color, shape, etc.)
			local shape = flags["aa_custom_part_shape"] or "Circle"
			local mat_str = flags["aa_custom_part_material"] or "Neon"
			if type(mat_str) == "table" then mat_str = mat_str[1] end
			local mat_enum = Enum.Material[mat_str or "Neon"] or Enum.Material.Neon
			local radius = flags["aa_custom_part_radius"] or 8
			local thick = flags["aa_custom_part_thickness"] or 1
			local y_off = flags["aa_custom_part_y_offset"] or 0
			local trans = ((flags["aa_custom_part_transparency"] or 30) / 100)
			local col = get_flag_color("aa_custom_part_color")
			local spin_speed = flags["aa_custom_part_spin"] or 0

			local is_cyl = (shape == "Circle" or shape == "Hexagon")
			local size_vec = is_cyl and Vector3.new(thick, radius * 2, radius * 2) or Vector3.new(radius * 2, thick, radius * 2)

			update_safe_platform_properties(shape, mat_enum, col, trans, size_vec)

			local state = humanoid and humanoid:GetState()
			local vel = hrp.AssemblyLinearVelocity

			-- Initial placement
			if not _underground_locked_y then
				_underground_locked_y = feet_y + y_off + (thick / 2) + 0.02
			end

			if _ug_part_active then
				-- Underground Part mode
				local fade_enabled = flags["aa_ug_fade_part"] == true
				local is_jumping = (state == Enum.HumanoidStateType.Jumping) or (humanoid and humanoid.Jump)

				if fade_enabled then
					if is_jumping and not _ug_jump_in_progress then
						_ug_jump_in_progress = true
						-- Old platform fades out
						local old_cf = safe_platform.CFrame
						create_ug_fade_part(old_cf, safe_platform.Size, safe_platform.Material, safe_platform.Color, safe_platform.Transparency, shape)
					end

					if _ug_jump_in_progress and (vel.Y <= 2) then
						-- Character near jump peak or landing: spawn new platform and fade it in
						_ug_jump_in_progress = false
						_underground_locked_y = feet_y + y_off - (thick / 2)
						safe_platform.Transparency = 0.9
						TweenService:Create(safe_platform, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = trans }):Play()
					end
				else
					_underground_locked_y = feet_y + y_off - (thick / 2)
				end

				-- Camera: keep natural (Humanoid subject, no cframe_fix)
				cframe_fix.CFrame = CFrame.new(9999, 9999, 9999)
				_current_evolator_y = 0
				_last_evolator_time = tick()
				if camera.CameraSubject ~= (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")) then
					local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					if hum then camera.CameraSubject = hum end
				end
			else
				-- Custom Part mode standalone:
				-- Use downward Raycast to detect real map floor (Baseplate, stairs, ground, pavement, rooftop)
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = {char, safe_platform, cframe_fix}
				for _, p in ipairs(_ug_fade_parts) do
					table.insert(rayParams.FilterDescendantsInstances, p)
				end

				local floor_hit = workspace:Raycast(hrp.Position, Vector3.new(0, -35, 0), rayParams)
				if floor_hit then
					local map_floor_y = floor_hit.Position.Y
					local target_plat_y = map_floor_y + (thick / 2) + 0.02 + y_off
					local target_plat_top = map_floor_y + thick + 0.02 + y_off
					_underground_locked_y = target_plat_y

					-- Seamless auto-elevation: If character is standing on the map floor below the platform top,
					-- instantly elevate character to stand cleanly on top of the platform (no need to press Space!)
					local dist_h = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(safe_platform.Position.X, safe_platform.Position.Z)).Magnitude
					if feet_y < (target_plat_top - 0.02) and (dist_h <= radius + 2) then
						local desired_y = target_plat_top + half_h + hip
						hrp.CFrame = CFrame.new(hrp.Position.X, desired_y, hrp.Position.Z) * hrp.CFrame.Rotation
						if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Running then
							humanoid:ChangeState(Enum.HumanoidStateType.Running)
						end
					end
				else
					-- If flying or in the air, follow elevation
					local is_flying = (state == Enum.HumanoidStateType.RunningNoPhysics) or (state == Enum.HumanoidStateType.PlatformStanding) or (hrp:FindFirstChildOfClass("BodyVelocity") ~= nil) or (hrp:FindFirstChildOfClass("LinearVelocity") ~= nil)
					if is_flying or not _underground_locked_y then
						_underground_locked_y = feet_y + y_off + (thick / 2) + 0.02
					end
				end
			end

			-- Update Platform CFrame
			local orient = is_cyl and CFrame.Angles(0, 0, math.rad(90)) or CFrame.identity
			local spin = (spin_speed > 0) and CFrame.Angles(0, math.rad((tick() * spin_speed * 18) % 360), 0) or CFrame.identity

			safe_platform.CFrame = CFrame.new(hrp.Position.X, _underground_locked_y, hrp.Position.Z) * spin * orient
			safe_platform.CanCollide = true

			-- ==========================================
			-- Rock-Solid Catch & Anti-Tunneling Engine
			-- ==========================================
			-- Ensures character NEVER sinks into platform, NEVER falls through like noclip
			local plat_top = _underground_locked_y + (thick / 2)
			local dist_h = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(safe_platform.Position.X, safe_platform.Position.Z)).Magnitude

			if dist_h <= (radius + 2) then
				if feet_y <= (plat_top + 0.4) and feet_y >= (plat_top - 2.5) then
					if vel.Y < 0 then
						hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
						local desired_y = plat_top + half_h + hip
						hrp.CFrame = CFrame.new(hrp.Position.X, desired_y, hrp.Position.Z) * hrp.CFrame.Rotation
						if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Running then
							humanoid:ChangeState(Enum.HumanoidStateType.Running)
						end
					end
				end
			end
		else
			hide_safe_platform()
		end

		-- Camera fix & evolator handling (skip for Underground Part mode - uses natural camera)
		if not _ug_part_active then
			local is_underground_active = flags["aa_underground"] or (_desync_mode_cache == "Underground")
			local current_cam_mode = flags["aa_underground_camera_mode"] or "Camera"
			if type(current_cam_mode) == "table" then current_cam_mode = current_cam_mode[1] end

			if _desync_mode_cache == "Freeze" or (is_underground_active and current_cam_mode == "Fix camera") then
				local ref_cf = _desync_old_cf or hrp.CFrame
				cframe_fix.CFrame = ref_cf * CFrame.new(0, hrp.Size.Y / 2 + 0.5, 0)
				if camera.CameraSubject ~= cframe_fix then
					camera.CameraSubject = cframe_fix
				end
				refresh_char_parts_cache()
				local cam_dist = (camera.CFrame.Position - cframe_fix.Position).Magnitude
				set_transparency(cam_dist < 2.2)
			elseif is_underground_active and current_cam_mode == "Camera evolator" then
				-- Follows character movement naturally, smoothly elevates/descends Y to target
				local now = tick()
				local dt = math.clamp(now - _last_evolator_time, 0, 0.1)
				_last_evolator_time = now

				local y_pos = flags["aa_evolator_y_pos"] or 30
				local y_neg = flags["aa_evolator_y_neg"] or 0
				local target_y = y_pos - y_neg
				local speed = flags["aa_evolator_speed"] or 20

				if _current_evolator_y < target_y then
					_current_evolator_y = math.min(target_y, _current_evolator_y + speed * dt)
				elseif _current_evolator_y > target_y then
					_current_evolator_y = math.max(target_y, _current_evolator_y - speed * dt)
				end

				local base_y = hrp.Position.Y + (hrp.Size.Y / 2) + 0.5
				cframe_fix.CFrame = CFrame.new(hrp.Position.X, base_y + _current_evolator_y, hrp.Position.Z) * hrp.CFrame.Rotation
				if camera.CameraSubject ~= cframe_fix then
					camera.CameraSubject = cframe_fix
				end

				refresh_char_parts_cache()
				local cam_dist = (camera.CFrame.Position - cframe_fix.Position).Magnitude
				set_transparency(cam_dist < 2.2)
			elseif is_underground_active and current_cam_mode == "Camera" then
				-- Camera follows the Underground X, Y, Z offset dynamically (positive or negative) as character moves!
				local off_x = flags["aa_underground_x"] or 0
				local off_y = flags["aa_underground_y"] or 0
				local off_z = flags["aa_underground_z"] or 0
				local cam_pos = hrp.Position + Vector3.new(off_x, off_y + (hrp.Size.Y / 2) + 0.5, off_z)
				cframe_fix.CFrame = CFrame.new(cam_pos) * hrp.CFrame.Rotation
				if camera.CameraSubject ~= cframe_fix then
					camera.CameraSubject = cframe_fix
				end

				refresh_char_parts_cache()
				local cam_dist = (camera.CFrame.Position - cframe_fix.Position).Magnitude
				set_transparency(cam_dist < 2.2)
			else
				cframe_fix.CFrame = CFrame.new(9999, 9999, 9999)
				_current_evolator_y = 0
				_last_evolator_time = tick()
				local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
				if hum and camera.CameraSubject == cframe_fix then
					camera.CameraSubject = hum
				end
				if not is_custom and not _ug_part_active and not flags["desync_enabled"] and not flags["aa_random_teleport"] and not flags["aa_orbit"] and not flags["aa_velocity_desync"] and not flags["aa_void_spam"] then
					resetCamera()
				end
			end
		end

		-- Velocity desync
		if flags["aa_velocity_desync"] then
			hrp.Velocity = Vector3.new(0, -10000, 0)
		end
	end)

	-- Desync Status Dragging Listener
	local status_dragging = false
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and flags["desync_status"] then
			local mousePos = UserInputService:GetMouseLocation()
			local textPos = DesyncStatus.Position
			local textSize = DesyncStatus.TextBounds
			if mousePos.X >= textPos.X and mousePos.X <= textPos.X + textSize.X and mousePos.Y >= textPos.Y and mousePos.Y <= textPos.Y + textSize.Y then
				status_dragging = true
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			status_dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if status_dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			DesyncStatus.Position = UserInputService:GetMouseLocation()
		end
	end)

	-- Desync UI Controls
	local set_orbit_sliders_visible

	main_aa:toggle({
		name = "Enable Desync",
		flag = "desync_enabled",
		default = false,
		callback = function(val)
			if not val and not flags["aa_underground"] and not flags["aa_random_teleport"] and not flags["aa_velocity_desync"] and not flags["aa_orbit"] and not flags["aa_void_spam"] then
				resetCamera()
				hide_desync_clone()
			end
		end
	}):keybind({
		flag = "desync_keybind",
		callback = function()
			if not flags["desync_enabled"] and not flags["aa_underground"] and not flags["aa_random_teleport"] and not flags["aa_velocity_desync"] and not flags["aa_orbit"] and not flags["aa_void_spam"] then
				resetCamera()
				hide_desync_clone()
			end
		end
	})

	main_aa:dropdown({
		name = "Desync Mode",
		flag = "desync_mode",
		items = {
			"Destroy Cheaters",
			"Underground",
			"Void",
			"Random",
			"Safe Shoot",
			"Custom",
			"Freeze",
			"Orbit"
		},
		multi = false,
		default = "Custom",
		callback = function(val)
			if set_orbit_sliders_visible then
				if val == "Orbit" then
					set_orbit_sliders_visible(true)
				elseif not flags["aa_orbit"] then
					set_orbit_sliders_visible(false)
				end
			end
		end
	})

	main_aa:slider({
		name = "Custom X",
		flag = "desync_custom_x",
		min = -500,
		max = 500,
		default = 0
	})

	main_aa:slider({
		name = "Custom Y",
		flag = "desync_custom_y",
		min = -500,
		max = 500,
		default = 0
	})

	main_aa:slider({
		name = "Custom Z",
		flag = "desync_custom_z",
		min = -500,
		max = 500,
		default = 0
	})

	main_aa:slider({
		name = "Random Amount",
		flag = "desync_random_amount",
		min = 1,
		max = 500,
		default = 20
	})

	main_aa:toggle({
		name = "Visualize Desync",
		flag = "desync_visualize",
		default = false
	}):colorpicker({
		flag = "desync_viz_color",
		color = Color3.fromRGB(0, 255, 100),
		transparency = 0.3
	})

	main_aa:dropdown({
		name = "Visualize Material",
		flag = "desync_viz_material",
		items = {
			"ForceField",
			"Neon",
			"SmoothPlastic",
			"Glass",
			"Foil",
			"Metal",
			"Granite",
			"Ice",
			"Wood",
			"Brick",
			"Plastic",
			"Cobblestone",
			"DiamondPlate"
		},
		multi = false,
		default = "ForceField",
		callback = function(val)
			if BodyCloneDesync then
				local mat_str = val
				if type(mat_str) == "table" then mat_str = mat_str[1] end
				local mat = Enum.Material[mat_str or "ForceField"]
				for _, v in pairs(BodyCloneDesync:GetDescendants()) do
					if v:IsA("BasePart") or v:IsA("MeshPart") then
						v.Material = mat
					end
				end
			end
		end
	})

	main_aa:toggle({
		name = "Line Desync",
		flag = "desync_line",
		default = false
	}):colorpicker({
		flag = "desync_line_color",
		color = Color3.fromRGB(0, 255, 100)
	})

	main_aa:toggle({
		name = "Desync Status",
		flag = "desync_status",
		default = false
	}):colorpicker({
		flag = "desync_status_color",
		color = Color3.fromRGB(0, 255, 0)
	})

	main_aa:toggle({
		name = "Dot Desync",
		flag = "desync_dot",
		default = false
	}):colorpicker({
		flag = "desync_dot_color",
		color = Color3.fromRGB(0, 255, 100)
	})

	-- Velocity desync
	main_aa:toggle({
		name = "Velocity desync",
		flag = "aa_velocity_desync",
		default = false,
		callback = function(val)
			if not val and not flags["desync_enabled"] and not flags["aa_random_teleport"] and not flags["aa_underground"] and not flags["aa_orbit"] and not flags["aa_void_spam"] then
				resetCamera()
				hide_desync_clone()
			end
		end
	}):keybind({
		flag = "aa_velocity_desync_bind"
	})

	main_aa:toggle({
		name = "Random teleport",
		flag = "aa_random_teleport",
		default = false,
		callback = function(val)
			if not val and not flags["desync_enabled"] and not flags["aa_velocity_desync"] and not flags["aa_underground"] and not flags["aa_orbit"] and not flags["aa_void_spam"] then
				resetCamera()
				hide_desync_clone()
			end
		end
	}):keybind({
		flag = "aa_random_teleport_bind",
		default = Enum.KeyCode.H
	})

	main_aa:slider({
		name = "Horizontal offset",
		flag = "aa_horizontal_offset",
		min = 0,
		max = 20,
		default = 5
	})

	main_aa:slider({
		name = "Vertical offset",
		flag = "aa_vertical_offset",
		min = 0,
		max = 20,
		default = 5
	})

	-- Orbit mode
	main_aa:toggle({
		name = "Orbit",
		flag = "aa_orbit",
		default = false,
		callback = function(val)
			if set_orbit_sliders_visible then
				set_orbit_sliders_visible(val)
			end
			if not val and not flags["desync_enabled"] and not flags["aa_velocity_desync"] and not flags["aa_random_teleport"] and not flags["aa_underground"] and not flags["aa_void_spam"] then
				resetCamera()
				hide_desync_clone()
			end
		end
	}):keybind({
		flag = "aa_orbit_bind",
		default = Enum.KeyCode.J,
		callback = function()
			if set_orbit_sliders_visible then
				set_orbit_sliders_visible(flags["aa_orbit"])
			end
			if not flags["desync_enabled"] and not flags["aa_velocity_desync"] and not flags["aa_random_teleport"] and not flags["aa_underground"] and not flags["aa_orbit"] and not flags["aa_void_spam"] then
				resetCamera()
				hide_desync_clone()
			end
		end
	})

	-- Orbit Sliders Container with Ultra-Lightweight Slide Down/Up Fade Animation (0.75s)
	local orbit_anim_id = 0
	local orbit_container = Instance.new("CanvasGroup")
	orbit_container.Name = "OrbitSlidersContainer"
	orbit_container.BackgroundTransparency = 1
	orbit_container.BorderSizePixel = 0
	orbit_container.Size = UDim2.new(1, 0, 0, 0)
	orbit_container.Visible = false
	orbit_container.GroupTransparency = 1
	orbit_container.Parent = main_aa.holder

	local orbit_inner = Instance.new("Frame")
	orbit_inner.Name = "OrbitInner"
	orbit_inner.BackgroundTransparency = 1
	orbit_inner.BorderSizePixel = 0
	orbit_inner.Size = UDim2.new(1, 0, 0, 78)
	orbit_inner.Position = UDim2.new(0, 0, 0, -25)
	orbit_inner.Parent = orbit_container

	local orbit_layout = Instance.new("UIListLayout")
	orbit_layout.Padding = UDim.new(0, 3)
	orbit_layout.SortOrder = Enum.SortOrder.LayoutOrder
	orbit_layout.Parent = orbit_inner

	set_orbit_sliders_visible = function(show)
		orbit_anim_id = orbit_anim_id + 1
		local current_id = orbit_anim_id

		if show then
			orbit_container.Visible = true
			local tween_info = TweenInfo.new(0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(orbit_container, tween_info, {
				Size = UDim2.new(1, 0, 0, 78),
				GroupTransparency = 0
			}):Play()
			TweenService:Create(orbit_inner, tween_info, {
				Position = UDim2.new(0, 0, 0, 0)
			}):Play()
		else
			local tween_info = TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(orbit_container, tween_info, {
				Size = UDim2.new(1, 0, 0, 0),
				GroupTransparency = 1
			}):Play()
			TweenService:Create(orbit_inner, tween_info, {
				Position = UDim2.new(0, 0, 0, -25)
			}):Play()
			task.delay(0.65, function()
				if orbit_anim_id == current_id and not flags["aa_orbit"] and flags["desync_mode"] ~= "Orbit" then
					orbit_container.Visible = false
				end
			end)
		end
	end

	local orbit_x = main_aa:slider({
		name = "Orbit X",
		flag = "aa_orbit_x",
		min = 1,
		max = 200,
		default = 10
	})

	local orbit_y = main_aa:slider({
		name = "Orbit Y",
		flag = "aa_orbit_y",
		min = -200,
		max = 200,
		default = 0
	})

	local orbit_speed = main_aa:slider({
		name = "Orbit Speed",
		flag = "aa_orbit_speed",
		min = 1,
		max = 50,
		default = 10
	})

	orbit_x.element_frame.Parent = orbit_inner
	orbit_y.element_frame.Parent = orbit_inner
	orbit_speed.element_frame.Parent = orbit_inner

	if flags["aa_orbit"] or flags["desync_mode"] == "Orbit" then
		orbit_container.Visible = true
		orbit_container.Size = UDim2.new(1, 0, 0, 78)
		orbit_container.GroupTransparency = 0
		orbit_inner.Position = UDim2.new(0, 0, 0, 0)
	end

	-- Underground Feature
	local set_ug_visible
	local evolator_y_pos, evolator_y_neg, evolator_speed
	local ug_container
	local ug_mode, cam_mode
	local ug_fade_part
	local x_body, y_body
	local update_ug_mode_visibility
	local set_cp_visible

	local function get_ug_target_height()
		local mode = flags["aa_underground_mode"] or "Underground"
		if type(mode) == "table" then mode = mode[1] end
		if mode == "Underground Part" then
			return 116
		else
			local is_evolator = (flags["aa_underground_camera_mode"] == "Camera evolator")
			return is_evolator and 224 or 140
		end
	end

	main_aa:toggle({
		name = "Underground",
		flag = "aa_underground",
		default = false,
		callback = function(val)
			if update_ug_mode_visibility then
				update_ug_mode_visibility()
			end
			if set_ug_visible then
				set_ug_visible(val)
			end
			if not val and not flags["desync_enabled"] and not flags["aa_velocity_desync"] and not flags["aa_random_teleport"] and not flags["aa_orbit"] and not flags["aa_void_spam"] then
				resetCamera()
				hide_desync_clone()
			end
		end
	}):keybind({
		flag = "aa_underground_bind",
		default = Enum.KeyCode.L,
		callback = function()
			if update_ug_mode_visibility then
				update_ug_mode_visibility()
			end
			if set_ug_visible then
				set_ug_visible(flags["aa_underground"])
			end
			if not flags["desync_enabled"] and not flags["aa_velocity_desync"] and not flags["aa_random_teleport"] and not flags["aa_orbit"] and not flags["aa_void_spam"] then
				resetCamera()
				hide_desync_clone()
			end
		end
	})

	ug_mode = main_aa:dropdown({
		name = "Underground mode",
		flag = "aa_underground_mode",
		items = { "Underground", "Underground Part" },
		multi = false,
		default = "Underground",
		callback = function(val)
			if update_ug_mode_visibility then
				update_ug_mode_visibility()
			end
		end
	})

	cam_mode = main_aa:dropdown({
		name = "Camera mode",
		flag = "aa_underground_camera_mode",
		items = { "Fix camera", "Camera", "Camera evolator" },
		multi = false,
		default = "Camera",
		callback = function(val)
			if update_ug_mode_visibility then
				update_ug_mode_visibility()
			end
		end
	})

	-- Underground Sub-controls Container (from Camera mode downwards) with Ultra-Lightweight Slide Down/Up Fade Animation (0.75s)
	local ug_anim_id = 0
	ug_container = Instance.new("CanvasGroup")
	ug_container.Name = "UndergroundSlidersContainer"
	ug_container.BackgroundTransparency = 1
	ug_container.BorderSizePixel = 0
	ug_container.Size = UDim2.new(1, 0, 0, 0)
	ug_container.Visible = false
	ug_container.GroupTransparency = 1
	ug_container.Parent = main_aa.holder

	local ug_inner = Instance.new("Frame")
	ug_inner.Name = "UndergroundInner"
	ug_inner.BackgroundTransparency = 1
	ug_inner.BorderSizePixel = 0
	ug_inner.Size = UDim2.new(1, 0, 0, 0)
	ug_inner.AutomaticSize = Enum.AutomaticSize.Y
	ug_inner.Position = UDim2.new(0, 0, 0, -25)
	ug_inner.Parent = ug_container

	local ug_layout = Instance.new("UIListLayout")
	ug_layout.Padding = UDim.new(0, 3)
	ug_layout.SortOrder = Enum.SortOrder.LayoutOrder
	ug_layout.Parent = ug_inner

	set_ug_visible = function(show)
		ug_anim_id = ug_anim_id + 1
		local current_id = ug_anim_id

		if show then
			ug_container.Visible = true
			local target_h = get_ug_target_height()
			local tween_info = TweenInfo.new(0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(ug_container, tween_info, {
				Size = UDim2.new(1, 0, 0, target_h),
				GroupTransparency = 0
			}):Play()
			TweenService:Create(ug_inner, tween_info, {
				Position = UDim2.new(0, 0, 0, 0)
			}):Play()
		else
			local tween_info = TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(ug_container, tween_info, {
				Size = UDim2.new(1, 0, 0, 0),
				GroupTransparency = 1
			}):Play()
			TweenService:Create(ug_inner, tween_info, {
				Position = UDim2.new(0, 0, 0, -25)
			}):Play()
			task.delay(0.65, function()
				if ug_anim_id == current_id and not flags["aa_underground"] then
					ug_container.Visible = false
				end
			end)
		end
	end

	ug_fade_part = main_aa:toggle({
		name = "Fade part",
		flag = "aa_ug_fade_part",
		default = false
	})

	local ug_x = main_aa:slider({
		name = "Underground X",
		flag = "aa_underground_x",
		min = -100,
		max = 100,
		default = 0
	})

	local ug_y = main_aa:slider({
		name = "Underground Y",
		flag = "aa_underground_y",
		min = -100,
		max = 100,
		default = 0
	})

	local ug_z = main_aa:slider({
		name = "Underground Z",
		flag = "aa_underground_z",
		min = -100,
		max = 100,
		default = 0
	})

	x_body = main_aa:slider({
		name = "X Body",
		flag = "aa_underground_x_body",
		min = -360,
		max = 360,
		default = 0
	})

	y_body = main_aa:slider({
		name = "Y Body",
		flag = "aa_underground_y_body",
		min = -360,
		max = 360,
		default = 0
	})

	evolator_y_pos = main_aa:slider({
		name = "Evolator Y positive",
		flag = "aa_evolator_y_pos",
		min = 0,
		max = 100,
		default = 30
	})

	evolator_y_neg = main_aa:slider({
		name = "Evolator Y negative",
		flag = "aa_evolator_y_neg",
		min = 0,
		max = 100,
		default = 0
	})

	evolator_speed = main_aa:slider({
		name = "Evolator Speed",
		flag = "aa_evolator_speed",
		min = 5,
		max = 100,
		default = 20
	})

	ug_fade_part.element_frame.Parent = ug_inner
	ug_x.element_frame.Parent = ug_inner
	ug_y.element_frame.Parent = ug_inner
	ug_z.element_frame.Parent = ug_inner
	x_body.element_frame.Parent = ug_inner
	y_body.element_frame.Parent = ug_inner
	evolator_y_pos.element_frame.Parent = ug_inner
	evolator_y_neg.element_frame.Parent = ug_inner
	evolator_speed.element_frame.Parent = ug_inner

	update_ug_mode_visibility = function()
		local is_ug = flags["aa_underground"] == true
		local mode = flags["aa_underground_mode"] or "Underground"
		if type(mode) == "table" then mode = mode[1] end
		local is_part_mode = (mode == "Underground Part")

		if ug_mode and ug_mode.element_frame then
			ug_mode.element_frame.Visible = is_ug
		end

		if cam_mode and cam_mode.element_frame then
			cam_mode.element_frame.Visible = is_ug and not is_part_mode
		end

		if ug_fade_part and ug_fade_part.element_frame then
			ug_fade_part.element_frame.Visible = is_part_mode
		end

		if x_body and x_body.element_frame then
			x_body.element_frame.Visible = not is_part_mode
		end
		if y_body and y_body.element_frame then
			y_body.element_frame.Visible = not is_part_mode
		end

		local is_evolator = not is_part_mode and (flags["aa_underground_camera_mode"] == "Camera evolator")
		if evolator_y_pos and evolator_y_pos.element_frame then
			evolator_y_pos.element_frame.Visible = is_evolator
			evolator_y_neg.element_frame.Visible = is_evolator
			evolator_speed.element_frame.Visible = is_evolator
		end

		if ug_container and ug_container.Visible and is_ug then
			TweenService:Create(ug_container, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, get_ug_target_height())
			}):Play()
		end

		-- Underground Part shares Custom Part sliders: open custom part sliders so user can configure radius, color, shape, etc.
		if set_cp_visible then
			local should_cp_open = (flags["aa_custom_part"] == true) or (is_ug and is_part_mode)
			set_cp_visible(should_cp_open)
		end
	end

	update_ug_mode_visibility()

	if flags["aa_underground"] then
		ug_container.Visible = true
		ug_container.Size = UDim2.new(1, 0, 0, get_ug_target_height())
		ug_container.GroupTransparency = 0
		ug_inner.Position = UDim2.new(0, 0, 0, 0)
	else
		ug_container.Visible = false
		ug_container.Size = UDim2.new(1, 0, 0, 0)
		ug_container.GroupTransparency = 1
	end

	-- Custom Part Feature
	main_aa:toggle({
		name = "Custom part",
		flag = "aa_custom_part",
		default = false,
		callback = function(val)
			if set_cp_visible then
				local is_ug = flags["aa_underground"] == true
				local mode = flags["aa_underground_mode"] or "Underground"
				if type(mode) == "table" then mode = mode[1] end
				local is_part_mode = (mode == "Underground Part")
				set_cp_visible(val or (is_ug and is_part_mode))
			end
			if not val and not _ug_part_active then
				hide_safe_platform()
			end
		end
	}):colorpicker({
		flag = "aa_custom_part_color",
		color = Color3.fromRGB(0, 255, 170)
	})

	local cp_shape = main_aa:dropdown({
		name = "Part shape",
		flag = "aa_custom_part_shape",
		items = { "Circle", "Square", "Hexagon", "Shield", "Star", "Ring" },
		multi = false,
		default = "Circle"
	})

	local cp_material = main_aa:dropdown({
		name = "Part material",
		flag = "aa_custom_part_material",
		items = {
			"Neon",
			"ForceField",
			"Glass",
			"Ice",
			"DiamondPlate",
			"Foil",
			"SmoothPlastic",
			"Metal",
			"Cobblestone",
			"Granite"
		},
		multi = false,
		default = "Neon"
	})

	-- Custom Part Sliders Container with Ultra-Lightweight Slide Down/Up Fade Animation (0.75s)
	local cp_anim_id = 0
	local cp_container = Instance.new("CanvasGroup")
	cp_container.Name = "CustomPartSlidersContainer"
	cp_container.BackgroundTransparency = 1
	cp_container.BorderSizePixel = 0
	cp_container.Size = UDim2.new(1, 0, 0, 0)
	cp_container.Visible = false
	cp_container.GroupTransparency = 1
	cp_container.Parent = main_aa.holder

	local cp_inner = Instance.new("Frame")
	cp_inner.Name = "CustomPartInner"
	cp_inner.BackgroundTransparency = 1
	cp_inner.BorderSizePixel = 0
	cp_inner.Size = UDim2.new(1, 0, 0, 0)
	cp_inner.AutomaticSize = Enum.AutomaticSize.Y
	cp_inner.Position = UDim2.new(0, 0, 0, -25)
	cp_inner.Parent = cp_container

	local cp_layout = Instance.new("UIListLayout")
	cp_layout.Padding = UDim.new(0, 3)
	cp_layout.SortOrder = Enum.SortOrder.LayoutOrder
	cp_layout.Parent = cp_inner

	local cp_radius = main_aa:slider({
		name = "Part Radius",
		flag = "aa_custom_part_radius",
		min = 2,
		max = 50,
		default = 8
	})

	local cp_thick = main_aa:slider({
		name = "Part Thickness",
		flag = "aa_custom_part_thickness",
		min = 1,
		max = 10,
		default = 1
	})

	local cp_y_offset = main_aa:slider({
		name = "Part Y Offset",
		flag = "aa_custom_part_y_offset",
		min = -20,
		max = 20,
		default = 0
	})

	local cp_trans = main_aa:slider({
		name = "Part Transparency",
		flag = "aa_custom_part_transparency",
		min = 0,
		max = 100,
		default = 30
	})

	local cp_spin = main_aa:slider({
		name = "Part Spin Speed",
		flag = "aa_custom_part_spin",
		min = 0,
		max = 50,
		default = 0
	})

	cp_radius.element_frame.Parent = cp_inner
	cp_thick.element_frame.Parent = cp_inner
	cp_y_offset.element_frame.Parent = cp_inner
	cp_trans.element_frame.Parent = cp_inner
	cp_spin.element_frame.Parent = cp_inner

	local cp_target_height = 138
	set_cp_visible = function(show)
		cp_anim_id = cp_anim_id + 1
		local current_id = cp_anim_id

		if show then
			cp_container.Visible = true
			local tween_info = TweenInfo.new(0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(cp_container, tween_info, {
				Size = UDim2.new(1, 0, 0, cp_target_height),
				GroupTransparency = 0
			}):Play()
			TweenService:Create(cp_inner, tween_info, {
				Position = UDim2.new(0, 0, 0, 0)
			}):Play()
		else
			local tween_info = TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(cp_container, tween_info, {
				Size = UDim2.new(1, 0, 0, 0),
				GroupTransparency = 1
			}):Play()
			TweenService:Create(cp_inner, tween_info, {
				Position = UDim2.new(0, 0, 0, -25)
			}):Play()
			task.delay(0.65, function()
				if cp_anim_id == current_id and not flags["aa_custom_part"] then
					cp_container.Visible = false
				end
			end)
		end
	end

	if flags["aa_custom_part"] then
		cp_container.Visible = true
		cp_container.Size = UDim2.new(1, 0, 0, cp_target_height)
		cp_container.GroupTransparency = 0
		cp_inner.Position = UDim2.new(0, 0, 0, 0)
	else
		cp_container.Visible = false
		cp_container.Size = UDim2.new(1, 0, 0, 0)
		cp_container.GroupTransparency = 1
	end

	-- Network desync (non-blocking: Heartbeat sets desync, BindToRenderStep restores)
	local nd_connection
	local _nd_old_pos = nil
	local _nd_active = false
	local _nd_render_bound = false

	main_aa:toggle({
		name = "Network desync",
		flag = "aa_network_desync",
		default = false,
		callback = function(val)
			if nd_connection then
				nd_connection:Disconnect()
				nd_connection = nil
			end
			if val then
				-- Bind render step once (unbind on toggle off)
				if not _nd_render_bound then
					_nd_render_bound = true
					RunService:BindToRenderStep("NDDesyncRestore", 2, function()
						if not _nd_active then return end
						_nd_active = false
						local hrp = local_parts["HumanoidRootPart"]
						if hrp and _nd_old_pos then
							hrp.CFrame = _nd_old_pos
						end
					end)
				end

				nd_connection = RunService.Heartbeat:Connect(function()
					local hrp = local_parts["HumanoidRootPart"]
					local humanoid = local_parts["Humanoid"]
					if not hrp or not humanoid or local_knocked or humanoid.Health <= 0 then
						return
					end

					_nd_old_pos = hrp.CFrame
					local desync_type = flags["aa_network_desync_type"] or "Simple"

					local offset = Vector3.new(0, 0, 0)
					if desync_type == "Simple" then
						offset = Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
					elseif desync_type == "Jitter" then
						offset = Vector3.new(math.random(-25, 25), math.random(-10, 10), math.random(-25, 25))
					elseif desync_type == "Alternative" then
						offset = Vector3.new(math.random(-10, 10), -15, math.random(-10, 10))
					end

					pcall(function()
						sethiddenproperty(hrp, "NetworkIsSleeping", false)
						hrp.AssemblyAngularVelocity = Vector3.new(0, 90, 0)
					end)
					local anti_sleep_spin = CFrame.Angles(0, math.rad((tick() * 90) % 360), 0)
					local desync_cf = (_nd_old_pos + offset) * anti_sleep_spin
					local_parts["DesyncedCF"] = desync_cf

					hrp.CFrame = desync_cf
					_nd_active = true
				end)
			else
				_nd_active = false
				if _nd_render_bound then
					pcall(function() RunService:UnbindFromRenderStep("NDDesyncRestore") end)
					_nd_render_bound = false
				end
				if not flags["aa_random_teleport"] and not flags["aa_underground"] and not flags["aa_velocity_desync"] and not flags["aa_orbit"] then
					local_parts["DesyncedCF"] = nil
				end
			end
		end
	}):keybind({
		flag = "aa_network_desync_bind"
	})

	main_aa:dropdown({
		flag = "aa_network_desync_type",
		items = { "Simple", "Jitter", "Alternative" },
		multi = false,
		default = "Simple"
	})

	main_aa:toggle({
		name = "Void spam",
		flag = "aa_void_spam",
		default = false
	}):keybind({
		flag = "aa_void_spam_bind"
	})

	-- Right Side: Character & Otras razones
	local char_section = antiaim:section({ name = "Character", side = "right" })

	char_section:toggle({
		name = "Client side pitch",
		flag = "char_clientside_pitch",
		default = false
	})

	char_section:toggle({
		name = "Face backwards",
		flag = "char_face_backwards",
		default = false
	})

	char_section:toggle({
		name = "Position body",
		flag = "position_body",
		default = false
	}):colorpicker({
		flag = "position_body_color",
		color = Color3.fromRGB(0, 255, 100),
		transparency = 0.3
	}):dropdown({
		flag = "position_body_material",
		items = { "ForceField", "Neon", "SmoothPlastic", "Glass", "Foil", "Metal", "Granite", "Ice", "Wood", "Brick", "Plastic", "Cobblestone", "DiamondPlate" },
		multi = false,
		default = "ForceField",
		callback = function(val)
			if BodyCloneDesync then
				local mat_str = val
				if type(mat_str) == "table" then mat_str = mat_str[1] end
				local mat = Enum.Material[mat_str or "ForceField"]
				for _, v in pairs(BodyCloneDesync:GetDescendants()) do
					if v:IsA("BasePart") or v:IsA("MeshPart") then
						v.Material = mat
					end
				end
			end
		end
	})

	char_section:toggle({
		name = "Animation spam",
		flag = "char_anim_spam",
		default = false
	})

	char_section:toggle({
		name = "Animation lag",
		flag = "char_anim_lag",
		default = false
	})
	-- Real Spinbot Engine (Neverlose style with decimal 0.x speed)
	local _spinbot_connection = nil
	local function update_spinbot(enabled)
		if _spinbot_connection then
			_spinbot_connection:Disconnect()
			_spinbot_connection = nil
		end
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not enabled then
			if hum then
				hum.AutoRotate = true
			end
			return
		end

		if hum then
			hum.AutoRotate = false
		end

		_spinbot_connection = RunService.Heartbeat:Connect(function(dt)
			if not flags["char_spinbot"] then
				if _spinbot_connection then
					_spinbot_connection:Disconnect()
					_spinbot_connection = nil
				end
				local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
				if h then h.AutoRotate = true end
				return
			end
			local c = LocalPlayer.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			local root = c and c:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local is_desync_on = flags["desync_enabled"] or flags["aa_underground"] or flags["aa_random_teleport"] or flags["aa_velocity_desync"] or flags["aa_orbit"] or flags["aa_void_spam"]
			if not is_desync_on then
				if root then
					pcall(function() root.AssemblyAngularVelocity = Vector3.zero end)
				end
				if h and not h.AutoRotate then
					h.AutoRotate = true
				end
				return
			end
			if h and h.AutoRotate then
				h.AutoRotate = false
			end
			local spd = flags["char_spinbot_speed"] or 1
			local deg_per_sec = spd * 360
			local rad_step = math.rad(deg_per_sec) * (dt or 0.016)
			root.CFrame = root.CFrame * CFrame.Angles(0, rad_step, 0)
			pcall(function()
				sethiddenproperty(root, "NetworkIsSleeping", false)
				root.AssemblyAngularVelocity = Vector3.new(0, math.rad(deg_per_sec), 0)
			end)
		end)
	end

	table.insert(_nvl_conns, LocalPlayer.CharacterAdded:Connect(function(new_char)
		if flags["char_spinbot"] then
			task.wait(0.2)
			local hum = new_char:FindFirstChildOfClass("Humanoid")
			if hum then hum.AutoRotate = false end
			update_spinbot(true)
		end
	end))

	char_section:toggle({
		name = "Spinbot",
		flag = "char_spinbot",
		default = false,
		callback = function(val)
			update_spinbot(val)
		end
	})

	char_section:slider({
		name = "Spinbot Speed",
		flag = "char_spinbot_speed",
		min = 0.01,
		max = 1.00,
		interval = 0.01,
		default = 0.03
	})

	local aa_other = antiaim:section({ name = "Otras razones", side = "right" })

	aa_other:toggle({
		name = "Anti stomp",
		flag = "aa_anti_stomp",
		default = false
	})

	-- Advanced Anti Fling (Optimized: only runs when enabled and checks nearby threats)
	local function do_anti_fling()
		if not flags["aa_anti_fling"] then return end
		local my_char = LocalPlayer.Character
		if not my_char then return end
		local my_hrp = my_char:FindFirstChild("HumanoidRootPart")
		if not my_hrp then return end

		-- Nullify velocity if current character gets flung
		if my_hrp.AssemblyLinearVelocity.Magnitude > 250 or my_hrp.AssemblyAngularVelocity.Magnitude > 250 then
			my_hrp.AssemblyLinearVelocity = Vector3.zero
			my_hrp.AssemblyAngularVelocity = Vector3.zero
			my_hrp.Velocity = Vector3.zero
			my_hrp.RotVelocity = Vector3.zero
		end

		-- Disable collisions with high-velocity/spin enemy parts in proximity (< 35 studs)
		local my_pos = my_hrp.Position
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				local char = player.Character
				local enemy_hrp = char:FindFirstChild("HumanoidRootPart")
				if enemy_hrp and (enemy_hrp.Position - my_pos).Magnitude < 35 then
					if enemy_hrp.AssemblyAngularVelocity.Magnitude > 100 or enemy_hrp.AssemblyLinearVelocity.Magnitude > 250 then
						for _, enemy_part in ipairs(char:GetChildren()) do
							if enemy_part:IsA("BasePart") then
								enemy_part.CanCollide = false
								enemy_part.AssemblyLinearVelocity = Vector3.zero
								enemy_part.AssemblyAngularVelocity = Vector3.zero
							end
						end
					end
				end
			end
		end
	end

	-- Connect Anti Fling permanently to Stepped
	RunService.Stepped:Connect(do_anti_fling)

	aa_other:toggle({
		name = "Anti fling",
		flag = "aa_anti_fling",
		default = true
	})

	aa_other:toggle({
		name = "Auto peek",
		flag = "aa_autopeek",
		default = false
	}):keybind({
		flag = "aa_autopeek_bind"
	}):colorpicker({
		flag = "aa_autopeek_color",
		color = Color3.fromRGB(153, 255, 0)
	})

	aa_other:slider({
		name = "Buy amount",
		flag = "aa_buy_amount",
		min = 1,
		max = 20,
		default = 5,
		suffix = "x"
	})
end

-- ==========================================
-- 3. Tab Esp (Ảnh 4)
-- ==========================================
do
	local player_esp = esp:section({ name = "Player ESP", side = "left" })

	player_esp:dropdown({
		name = "Render for",
		flag = "esp_render_for",
		items = { "All", "Enemy", "Team" },
		multi = false,
		default = "All"
	})

	player_esp:toggle({
		name = "Enabled",
		flag = "esp_enabled",
		default = false
	})

	player_esp:toggle({
		name = "Box",
		flag = "esp_box",
		default = false
	}):colorpicker({
		flag = "esp_box_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	player_esp:toggle({
		name = "Fill",
		flag = "esp_fill",
		default = false
	}):colorpicker({
		flag = "esp_fill_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	player_esp:toggle({
		name = "Tool",
		flag = "esp_tool",
		default = false
	}):colorpicker({
		flag = "esp_tool_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	player_esp:toggle({
		name = "Nombre",
		flag = "esp_nombre",
		default = false
	}):colorpicker({
		flag = "esp_nombre_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	player_esp:toggle({
		name = "Highlight",
		flag = "esp_highlight",
		default = false
	}):colorpicker({
		flag = "esp_highlight_color",
		color = Color3.fromRGB(0, 153, 255)
	})

	player_esp:toggle({
		name = "Armor bar",
		flag = "esp_armor_bar",
		default = false
	}):colorpicker({
		flag = "esp_armor_bar_color",
		color = Color3.fromRGB(0, 204, 255)
	})

	player_esp:toggle({
		name = "Health bar",
		flag = "esp_health_bar",
		default = false
	}):colorpicker({
		flag = "esp_health_bar_color",
		color = Color3.fromRGB(0, 255, 0)
	})

	player_esp:toggle({
		name = "Health text",
		flag = "esp_health_text",
		default = false
	}):colorpicker({
		flag = "esp_health_text_color",
		color = Color3.fromRGB(0, 255, 0)
	})

	player_esp:toggle({
		name = "Weapon icon",
		flag = "esp_weapon_icon",
		default = false
	}):colorpicker({
		flag = "esp_weapon_icon_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	player_esp:toggle({
		name = "Super gun warning",
		flag = "esp_super_gun_warning",
		default = false
	}):colorpicker({
		flag = "esp_super_gun_warning_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	player_esp:dropdown({
		name = "Name font",
		flag = "esp_name_font",
		items = { "Bold", "Regular", "Pixel", "UI" },
		multi = false,
		default = "Bold"
	})

	player_esp:dropdown({
		name = "Small font",
		flag = "esp_small_font",
		items = { "Small", "Regular" },
		multi = false,
		default = "Small"
	})

	-- Right Side: Models & On hit
	local models_esp = esp:section({ name = "Models", side = "right" })

	models_esp:toggle({
		name = "Forcefield hats",
		flag = "esp_forcefield_hats",
		default = false
	}):colorpicker({
		flag = "esp_forcefield_hats_color",
		color = Color3.fromRGB(204, 255, 0)
	})

	models_esp:toggle({
		name = "Body material",
		flag = "esp_body_material",
		default = false
	}):colorpicker({
		flag = "esp_body_material_color",
		color = Color3.fromRGB(204, 255, 0)
	})

	local on_hit = esp:section({ name = "On hit", side = "right" })

	on_hit:toggle({
		name = "Damage number",
		flag = "esp_hit_damage",
		default = false
	}):colorpicker({
		flag = "esp_hit_damage_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	on_hit:toggle({
		name = "Hit skeleton",
		flag = "esp_hit_skeleton",
		default = false
	}):colorpicker({
		flag = "esp_hit_skeleton_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	on_hit:toggle({
		name = "Hit particle",
		flag = "esp_hit_particle",
		default = false
	}):colorpicker({
		flag = "esp_hit_particle_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	on_hit:toggle({
		name = "Hit marker",
		flag = "esp_hit_marker",
		default = false
	}):colorpicker({
		flag = "esp_hit_marker_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	on_hit:toggle({
		name = "Hit chams",
		flag = "esp_hit_chams",
		default = false
	}):colorpicker({
		flag = "esp_hit_chams_color",
		color = Color3.fromRGB(255, 255, 255)
	})

	on_hit:toggle({
		name = "Hit sound",
		flag = "esp_hit_sound",
		default = false
	})
end

-- ==========================================
-- ESP Logic Implementation
-- ==========================================
do
	local esp_cache = {}
	local highlight_cache = {}
	local prev_health_cache = {}
	local hit_marker_drawings = {}
	local damage_number_queue = {}
	local material_applied = {}

	local HIT_MARKER_DURATION = 0.4
	local DAMAGE_NUMBER_DURATION = 1.2
	local HIT_CHAMS_DURATION = 0.5
	local HIT_SOUND_ID = "rbxassetid://6333183385"

	local font_map = {
		["Bold"] = 2,
		["Regular"] = 2,
		["Pixel"] = 3,
		["UI"] = 0,
		["Small"] = 3,
	}

	local function get_flag_color(flag_name)
		local data = flags[flag_name]
		if type(data) == "table" and data.Color then
			return data.Color
		elseif typeof(data) == "Color3" then
			return data
		end
		return Color3.new(1, 1, 1)
	end

	local function get_flag_transparency(flag_name)
		local data = flags[flag_name]
		if type(data) == "table" and data.Transparency then
			return data.Transparency
		end
		return 0
	end

	local function should_render_player(player)
		local render_for = flags["esp_render_for"] or "All"
		if render_for == "All" then
			return true
		end
		local local_team = LocalPlayer.Team
		if render_for == "Enemy" then
			return player.Team ~= local_team
		elseif render_for == "Team" then
			return player.Team == local_team
		end
		return true
	end

	local function get_esp_font()
		local name_font_flag = flags["esp_name_font"] or "Bold"
		return font_map[name_font_flag] or 2
	end

	local function get_small_font()
		local small_font_flag = flags["esp_small_font"] or "Small"
		return font_map[small_font_flag] or 3
	end

	local function create_esp_drawings()
		local t = {}

		-- Box
		t.box_outline = Drawing.new("Square")
		t.box_outline.Thickness = 3
		t.box_outline.Filled = false
		t.box_outline.Color = Color3.new(0, 0, 0)
		t.box_outline.Visible = false

		t.box = Drawing.new("Square")
		t.box.Thickness = 1
		t.box.Filled = false
		t.box.Visible = false

		-- Fill
		t.fill = Drawing.new("Square")
		t.fill.Filled = true
		t.fill.Visible = false

		-- Name
		t.name_text = Drawing.new("Text")
		t.name_text.Center = true
		t.name_text.Outline = true
		t.name_text.OutlineColor = Color3.new(0, 0, 0)
		t.name_text.Size = 13
		t.name_text.Visible = false

		-- Tool name
		t.tool_text = Drawing.new("Text")
		t.tool_text.Center = true
		t.tool_text.Outline = true
		t.tool_text.OutlineColor = Color3.new(0, 0, 0)
		t.tool_text.Size = 13
		t.tool_text.Visible = false

		-- Health bar (left side, vertical)
		t.hbar_outline = Drawing.new("Square")
		t.hbar_outline.Thickness = 1
		t.hbar_outline.Filled = true
		t.hbar_outline.Color = Color3.new(0, 0, 0)
		t.hbar_outline.Visible = false

		t.hbar_bg = Drawing.new("Square")
		t.hbar_bg.Thickness = 1
		t.hbar_bg.Filled = true
		t.hbar_bg.Color = Color3.fromRGB(40, 40, 40)
		t.hbar_bg.Visible = false

		t.hbar_fill = Drawing.new("Square")
		t.hbar_fill.Thickness = 1
		t.hbar_fill.Filled = true
		t.hbar_fill.Visible = false

		-- Health text
		t.health_text = Drawing.new("Text")
		t.health_text.Center = false
		t.health_text.Outline = true
		t.health_text.OutlineColor = Color3.new(0, 0, 0)
		t.health_text.Size = 12
		t.health_text.Visible = false

		-- Armor bar (right side, vertical)
		t.abar_outline = Drawing.new("Square")
		t.abar_outline.Thickness = 1
		t.abar_outline.Filled = true
		t.abar_outline.Color = Color3.new(0, 0, 0)
		t.abar_outline.Visible = false

		t.abar_bg = Drawing.new("Square")
		t.abar_bg.Thickness = 1
		t.abar_bg.Filled = true
		t.abar_bg.Color = Color3.fromRGB(40, 40, 40)
		t.abar_bg.Visible = false

		t.abar_fill = Drawing.new("Square")
		t.abar_fill.Thickness = 1
		t.abar_fill.Filled = true
		t.abar_fill.Visible = false

		-- Weapon icon text (below box)
		t.weapon_icon_text = Drawing.new("Text")
		t.weapon_icon_text.Center = true
		t.weapon_icon_text.Outline = true
		t.weapon_icon_text.OutlineColor = Color3.new(0, 0, 0)
		t.weapon_icon_text.Size = 12
		t.weapon_icon_text.Visible = false

		-- Super gun warning
		t.super_warning = Drawing.new("Text")
		t.super_warning.Center = true
		t.super_warning.Outline = true
		t.super_warning.OutlineColor = Color3.new(0, 0, 0)
		t.super_warning.Size = 14
		t.super_warning.Visible = false

		return t
	end

	-- Fast hide: use ordered list to avoid pairs() + pcall overhead
	local drawing_keys = {
		"box_outline", "box", "fill", "name_text", "tool_text",
		"hbar_outline", "hbar_bg", "hbar_fill", "health_text",
		"abar_outline", "abar_bg", "abar_fill",
		"weapon_icon_text", "super_warning",
	}

	local function hide_all_drawings(t)
		for i = 1, #drawing_keys do
			local obj = t[drawing_keys[i]]
			if obj then
				obj.Visible = false
			end
		end
	end

	local function remove_all_drawings(t)
		for i = 1, #drawing_keys do
			local obj = t[drawing_keys[i]]
			if obj then
				obj:Remove()
			end
		end
	end

	local function get_bounding_box(character)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return nil
		end

		local root_pos, on_screen = camera:WorldToViewportPoint(hrp.Position)
		if not on_screen then
			return nil
		end

		local head = character:FindFirstChild("Head")
		if head then
			local top_pos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0))
			local bot_pos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
			local height = math.abs(bot_pos.Y - top_pos.Y)
			local width = height / 1.8

			return {
				x = math.floor(root_pos.X - width / 2),
				y = math.floor(top_pos.Y),
				w = math.floor(width),
				h = math.floor(height),
				cx = math.floor(root_pos.X),
				cy = math.floor((top_pos.Y + bot_pos.Y) / 2),
				dist = root_pos.Z,
			}
		end

		-- Fallback calculation
		local scale = 1 / (root_pos.Z * math.tan(math.rad(camera.FieldOfView / 2)) * 2) * 1000
		local w = math.floor(4.5 * scale)
		local h = math.floor(6 * scale)

		return {
			x = math.floor(root_pos.X - w / 2),
			y = math.floor(root_pos.Y - h / 2),
			w = w,
			h = h,
			cx = math.floor(root_pos.X),
			cy = math.floor(root_pos.Y),
			dist = root_pos.Z,
		}
	end

	local function get_player_armor(character)
		local body_effects = character:FindFirstChild("BodyEffects")
		if body_effects then
			local armor = body_effects:FindFirstChild("Armor") or body_effects:FindFirstChild("armor")
			if armor and armor:IsA("ValueBase") then
				return armor.Value
			end
		end
		return 0
	end

	local function is_player_knocked(character)
		local body_effects = character:FindFirstChild("BodyEffects")
		if body_effects then
			local ko = body_effects:FindFirstChild("K.O")
			if ko and ko:IsA("ValueBase") then
				return ko.Value
			end
		end
		return false
	end

	local function get_equipped_tool(character)
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				return child
			end
		end
		return nil
	end

	local function is_super_gun(tool)
		if not tool then
			return false
		end
		local name_lower = string.lower(tool.Name)
		local super_keywords = { "revolver", "shotgun", "ak", "ar", "rpg", "lmg", "sniper", "rifle", "smg" }
		for _, kw in ipairs(super_keywords) do
			if string.find(name_lower, kw) then
				-- Check if tool has unusual properties suggesting modification
				local conf = tool:FindFirstChild("Configuration") or tool:FindFirstChild("GunStates")
				if conf then
					local dmg = conf:FindFirstChild("Damage") or conf:FindFirstChild("damage")
					if dmg and dmg:IsA("ValueBase") and dmg.Value > 80 then
						return true
					end
				end
			end
		end
		return false
	end

	-- ===== HIT MARKER SYSTEM =====
	local hit_marker_active = false
	local hit_marker_time = 0
	local hit_marker_lines = {}
	for i = 1, 4 do
		hit_marker_lines[i] = Drawing.new("Line")
		hit_marker_lines[i].Thickness = 2
		hit_marker_lines[i].Color = Color3.new(1, 1, 1)
		hit_marker_lines[i].Visible = false
	end

	local function show_hit_marker(color)
		hit_marker_active = true
		hit_marker_time = tick()
		for i = 1, 4 do
			hit_marker_lines[i].Color = color or Color3.new(1, 1, 1)
			hit_marker_lines[i].Visible = true
		end
	end

	local function update_hit_marker()
		if not hit_marker_active then
			return
		end
		local elapsed = tick() - hit_marker_time
		if elapsed > HIT_MARKER_DURATION then
			hit_marker_active = false
			for i = 1, 4 do
				hit_marker_lines[i].Visible = false
			end
			return
		end

		local alpha = 1 - (elapsed / HIT_MARKER_DURATION)
		local vp = camera.ViewportSize
		local cx, cy = vp.X / 2, vp.Y / 2
		local inner = 5
		local outer = 12

		-- Top-left
		hit_marker_lines[1].From = Vector2.new(cx - inner, cy - inner)
		hit_marker_lines[1].To = Vector2.new(cx - outer, cy - outer)
		hit_marker_lines[1].Transparency = alpha
		-- Top-right
		hit_marker_lines[2].From = Vector2.new(cx + inner, cy - inner)
		hit_marker_lines[2].To = Vector2.new(cx + outer, cy - outer)
		hit_marker_lines[2].Transparency = alpha
		-- Bottom-left
		hit_marker_lines[3].From = Vector2.new(cx - inner, cy + inner)
		hit_marker_lines[3].To = Vector2.new(cx - outer, cy + outer)
		hit_marker_lines[3].Transparency = alpha
		-- Bottom-right
		hit_marker_lines[4].From = Vector2.new(cx + inner, cy + inner)
		hit_marker_lines[4].To = Vector2.new(cx + outer, cy + outer)
		hit_marker_lines[4].Transparency = alpha
	end

	-- ===== DAMAGE NUMBER SYSTEM =====
	local function spawn_damage_number(world_pos, damage, color)
		local text_obj = Drawing.new("Text")
		text_obj.Text = "-" .. tostring(math.floor(damage))
		text_obj.Size = 16
		text_obj.Center = true
		text_obj.Outline = true
		text_obj.OutlineColor = Color3.new(0, 0, 0)
		text_obj.Color = color or Color3.new(1, 1, 1)
		text_obj.Visible = true

		table.insert(damage_number_queue, {
			drawing = text_obj,
			world_pos = world_pos,
			start_time = tick(),
			offset_y = 0,
		})
	end

	local function update_damage_numbers()
		local i = 1
		while i <= #damage_number_queue do
			local entry = damage_number_queue[i]
			local elapsed = tick() - entry.start_time

			if elapsed > DAMAGE_NUMBER_DURATION then
				entry.drawing:Remove()
				table.remove(damage_number_queue, i)
			else
				local alpha = 1 - (elapsed / DAMAGE_NUMBER_DURATION)
				entry.offset_y = entry.offset_y - 0.8 -- float upward

				local screen_pos, on_screen = camera:WorldToViewportPoint(
					entry.world_pos + Vector3.new(0, -entry.offset_y / 30, 0)
				)
				if on_screen then
					entry.drawing.Position = Vector2.new(screen_pos.X, screen_pos.Y)
					entry.drawing.Transparency = alpha
					entry.drawing.Visible = true
				else
					entry.drawing.Visible = false
				end
				i = i + 1
			end
		end
	end

	-- ===== HIT CHAMS SYSTEM =====
	local hit_chams_cache = {}

	local function apply_hit_chams(character, color)
		if hit_chams_cache[character] then
			hit_chams_cache[character].hl:Destroy()
		end

		local hl = Instance.new("Highlight")
		hl.FillColor = color
		hl.OutlineColor = color
		hl.FillTransparency = 0.3
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = character
		hl.Parent = character
		hl.Name = "HitChams"

		hit_chams_cache[character] = {
			hl = hl,
			start_time = tick(),
		}
	end

	local function update_hit_chams()
		for char, data in pairs(hit_chams_cache) do
			local elapsed = tick() - data.start_time
			if elapsed > HIT_CHAMS_DURATION then
				pcall(function()
					data.hl:Destroy()
				end)
				hit_chams_cache[char] = nil
			else
				local alpha = elapsed / HIT_CHAMS_DURATION
				pcall(function()
					data.hl.FillTransparency = 0.3 + (alpha * 0.7)
					data.hl.OutlineTransparency = alpha
				end)
			end
		end
	end

	-- ===== HIT SOUND =====
	local function play_hit_sound()
		local sound = Instance.new("Sound")
		sound.SoundId = HIT_SOUND_ID
		sound.Volume = 1
		sound.PlayOnRemove = false
		sound.Parent = game:GetService("SoundService")
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 2)
	end

	-- ===== HIT PARTICLE =====
	local function spawn_hit_particle(world_pos, color)
		-- Create small particle dots that scatter from hit position
		local particle_count = 6
		local particles = {}

		for p = 1, particle_count do
			local circle = Drawing.new("Circle")
			circle.Radius = math.random(2, 4)
			circle.Filled = true
			circle.Color = color
			circle.Visible = true
			circle.Thickness = 0
			table.insert(particles, {
				drawing = circle,
				velocity = Vector3.new(
					(math.random() - 0.5) * 8,
					(math.random() - 0.5) * 8,
					(math.random() - 0.5) * 4
				),
				world_pos = world_pos,
				offset = Vector3.new(0, 0, 0),
			})
		end

		task.spawn(function()
			local start = tick()
			while tick() - start < 0.6 do
				local dt = task.wait()
				local alpha = 1 - ((tick() - start) / 0.6)
				for _, pt in ipairs(particles) do
					pt.offset = pt.offset + pt.velocity * dt
					local sp, vis = camera:WorldToViewportPoint(pt.world_pos + pt.offset)
					if vis then
						pt.drawing.Position = Vector2.new(sp.X, sp.Y)
						pt.drawing.Transparency = alpha
						pt.drawing.Visible = true
					else
						pt.drawing.Visible = false
					end
				end
			end
			for _, pt in ipairs(particles) do
				pt.drawing:Remove()
			end
		end)
	end

	-- ===== HEALTH CHANGE DETECTION (for on-hit effects) =====
	local health_connections = {}

	local function setup_health_tracking(player)
		if player == LocalPlayer then
			return
		end

		local function on_char(character)
			if not character then
				return
			end
			local humanoid = character:WaitForChild("Humanoid", 10)
			if not humanoid then
				return
			end

			prev_health_cache[player] = humanoid.Health

			if health_connections[player] then
				health_connections[player]:Disconnect()
			end

			health_connections[player] = humanoid.HealthChanged:Connect(function(new_health)
				local old_health = prev_health_cache[player] or humanoid.MaxHealth
				local damage = old_health - new_health
				prev_health_cache[player] = new_health

				if damage > 0 and damage < 200 then
					-- Someone took damage - trigger on-hit effects
					local head = character:FindFirstChild("Head")
					local hit_pos = head and head.Position or (character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position)

					if hit_pos then
						-- Damage number
						if flags["esp_hit_damage"] then
							local dmg_color = get_flag_color("esp_hit_damage_color")
							spawn_damage_number(hit_pos + Vector3.new(0, 2, 0), damage, dmg_color)
						end

						-- Hit marker
						if flags["esp_hit_marker"] then
							local mk_color = get_flag_color("esp_hit_marker_color")
							show_hit_marker(mk_color)
						end

						-- Hit chams
						if flags["esp_hit_chams"] then
							local hc_color = get_flag_color("esp_hit_chams_color")
							apply_hit_chams(character, hc_color)
						end

						-- Hit sound
						if flags["esp_hit_sound"] then
							play_hit_sound()
						end

						-- Hit particle
						if flags["esp_hit_particle"] then
							local hp_color = get_flag_color("esp_hit_particle_color")
							spawn_hit_particle(hit_pos, hp_color)
						end
					end
				end
			end)
		end

		if player.Character then
			task.spawn(on_char, player.Character)
		end
		player.CharacterAdded:Connect(on_char)
	end

	-- Setup tracking for existing & new players
	for _, player in ipairs(Players:GetPlayers()) do
		setup_health_tracking(player)
	end
	Players.PlayerAdded:Connect(setup_health_tracking)

	-- ===== MATERIAL / HIGHLIGHT MANAGEMENT =====
	local prev_forcefield_state = {}
	local prev_body_material_state = {}
	local orig_materials = {}
	local orig_colors = {}

	local function apply_forcefield_hats(character, color)
		for _, acc in ipairs(character:GetChildren()) do
			if acc:IsA("Accessory") then
				local handle = acc:FindFirstChild("Handle")
				if handle and handle:IsA("BasePart") then
					if not orig_materials[handle] then
						orig_materials[handle] = handle.Material
						orig_colors[handle] = handle.Color
					end
					handle.Material = Enum.Material.ForceField
					handle.Color = color
				end
			end
		end
	end

	local function remove_forcefield_hats(character)
		for _, acc in ipairs(character:GetChildren()) do
			if acc:IsA("Accessory") then
				local handle = acc:FindFirstChild("Handle")
				if handle and orig_materials[handle] then
					handle.Material = orig_materials[handle]
					handle.Color = orig_colors[handle]
					orig_materials[handle] = nil
					orig_colors[handle] = nil
				end
			end
		end
	end

	local function apply_body_material(character, color)
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				if not orig_materials[part] then
					orig_materials[part] = part.Material
					orig_colors[part] = part.Color
				end
				part.Material = Enum.Material.ForceField
				part.Color = color
			end
		end
	end

	local function remove_body_material(character)
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				if orig_materials[part] then
					part.Material = orig_materials[part]
					part.Color = orig_colors[part]
					orig_materials[part] = nil
					orig_colors[part] = nil
				end
			end
		end
	end

	-- Pre-create drawings for all existing players at init (avoid first-frame stutter)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			esp_cache[player] = create_esp_drawings()
		end
	end

	-- Auto-create drawings when new players join
	Players.PlayerAdded:Connect(function(player)
		if player ~= LocalPlayer and not esp_cache[player] then
			esp_cache[player] = create_esp_drawings()
		end
	end)

	-- Track previous ESP enabled state to avoid redundant hide calls
	local prev_esp_enabled = false

	-- ===== MAIN ESP RENDER LOOP =====
	local esp_render_connection = RunService.RenderStepped:Connect(function()
		-- Update hit effects regardless of ESP enabled state
		update_hit_marker()
		update_damage_numbers()
		update_hit_chams()

		local esp_enabled = flags["esp_enabled"]

		-- If ESP is globally off, hide everything (only once on transition)
		if not esp_enabled then
			if prev_esp_enabled then
				for _, data in pairs(esp_cache) do
					hide_all_drawings(data)
				end
				for _, hl in pairs(highlight_cache) do
					hl.Enabled = false
				end
				for player, _ in pairs(prev_forcefield_state) do
					local char = player.Character
					if char then
						remove_forcefield_hats(char)
					end
					prev_forcefield_state[player] = nil
				end
				for player, _ in pairs(prev_body_material_state) do
					local char = player.Character
					if char then
						remove_body_material(char)
					end
					prev_body_material_state[player] = nil
				end
				prev_esp_enabled = false
			end
			return
		end

		prev_esp_enabled = true
		local current_font = get_esp_font()
		local current_small_font = get_small_font()

		for _, player in ipairs(Players:GetPlayers()) do
			if player == LocalPlayer then
				continue
			end

			local d = esp_cache[player]
			if not d then
				esp_cache[player] = create_esp_drawings()
				d = esp_cache[player]
			end

			local character = player.Character

			if not character or not should_render_player(player) then
				hide_all_drawings(d)
				-- Clean highlight
				if highlight_cache[player] then
					highlight_cache[player].Enabled = false
				end
				-- Revert materials
				if prev_forcefield_state[player] and character then
					remove_forcefield_hats(character)
					prev_forcefield_state[player] = nil
				end
				if prev_body_material_state[player] and character then
					remove_body_material(character)
					prev_body_material_state[player] = nil
				end
				continue
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				hide_all_drawings(d)
				if highlight_cache[player] then
					highlight_cache[player].Enabled = false
				end
				continue
			end

			local bounds = get_bounding_box(character)
			if not bounds then
				hide_all_drawings(d)
				if highlight_cache[player] then
					highlight_cache[player].Enabled = false
				end
				continue
			end

			local bottom_y_offset = 2 -- tracks items drawn below box

			-- ===== BOX =====
			if flags["esp_box"] then
				local box_color = get_flag_color("esp_box_color")
				d.box_outline.Position = Vector2.new(bounds.x, bounds.y)
				d.box_outline.Size = Vector2.new(bounds.w, bounds.h)
				d.box_outline.Visible = true

				d.box.Position = Vector2.new(bounds.x, bounds.y)
				d.box.Size = Vector2.new(bounds.w, bounds.h)
				d.box.Color = box_color
				d.box.Visible = true
			else
				d.box.Visible = false
				d.box_outline.Visible = false
			end

			-- ===== FILL =====
			if flags["esp_fill"] then
				local fill_color = get_flag_color("esp_fill_color")
				local fill_trans = get_flag_transparency("esp_fill_color")
				d.fill.Position = Vector2.new(bounds.x + 1, bounds.y + 1)
				d.fill.Size = Vector2.new(bounds.w - 2, bounds.h - 2)
				d.fill.Color = fill_color
				d.fill.Transparency = 1 - math.clamp(fill_trans, 0, 1)
				d.fill.Visible = true
			else
				d.fill.Visible = false
			end

			-- ===== NAME =====
			if flags["esp_nombre"] then
				local name_color = get_flag_color("esp_nombre_color")
				d.name_text.Position = Vector2.new(bounds.cx, bounds.y - 16)
				d.name_text.Text = player.DisplayName
				d.name_text.Color = name_color
				d.name_text.Font = current_font
				d.name_text.Visible = true
			else
				d.name_text.Visible = false
			end

			-- ===== TOOL NAME =====
			local tool = get_equipped_tool(character)
			if flags["esp_tool"] and tool then
				local tool_color = get_flag_color("esp_tool_color")
				d.tool_text.Position = Vector2.new(bounds.cx, bounds.y + bounds.h + bottom_y_offset)
				d.tool_text.Text = tool.Name
				d.tool_text.Color = tool_color
				d.tool_text.Font = current_small_font
				d.tool_text.Visible = true
				bottom_y_offset = bottom_y_offset + 14
			else
				d.tool_text.Visible = false
			end

			-- ===== HEALTH BAR (left side, vertical, bottom-to-top) =====
			local health = humanoid.Health
			local max_health = humanoid.MaxHealth
			local health_ratio = math.clamp(health / max_health, 0, 1)

			if flags["esp_health_bar"] then
				local bar_w = 2
				local bar_x = bounds.x - bar_w - 4

				d.hbar_outline.Position = Vector2.new(bar_x - 1, bounds.y - 1)
				d.hbar_outline.Size = Vector2.new(bar_w + 2, bounds.h + 2)
				d.hbar_outline.Visible = true

				d.hbar_bg.Position = Vector2.new(bar_x, bounds.y)
				d.hbar_bg.Size = Vector2.new(bar_w, bounds.h)
				d.hbar_bg.Visible = true

				local fill_h = math.floor(bounds.h * health_ratio)
				-- Gradient from red (0%) to green (100%)
				local r = math.floor(255 * (1 - health_ratio))
				local g = math.floor(255 * health_ratio)
				d.hbar_fill.Position = Vector2.new(bar_x, bounds.y + (bounds.h - fill_h))
				d.hbar_fill.Size = Vector2.new(bar_w, fill_h)
				d.hbar_fill.Color = Color3.fromRGB(r, g, 0)
				d.hbar_fill.Visible = true
			else
				d.hbar_outline.Visible = false
				d.hbar_bg.Visible = false
				d.hbar_fill.Visible = false
			end

			-- ===== HEALTH TEXT =====
			if flags["esp_health_text"] then
				local ht_color = get_flag_color("esp_health_text_color")
				local bar_x = bounds.x - 6 - 14
				d.health_text.Position = Vector2.new(bar_x, bounds.y + (bounds.h * (1 - health_ratio)) - 6)
				d.health_text.Text = tostring(math.floor(health))
				d.health_text.Color = ht_color
				d.health_text.Font = current_small_font
				d.health_text.Visible = health_ratio < 1 -- Only show when not full HP
			else
				d.health_text.Visible = false
			end

			-- ===== ARMOR BAR (right side, vertical) =====
			local armor_value = get_player_armor(character)
			if flags["esp_armor_bar"] and armor_value > 0 then
				local armor_color = get_flag_color("esp_armor_bar_color")
				local bar_w = 2
				local bar_x = bounds.x + bounds.w + 4
				local armor_ratio = math.clamp(armor_value / 100, 0, 1)

				d.abar_outline.Position = Vector2.new(bar_x - 1, bounds.y - 1)
				d.abar_outline.Size = Vector2.new(bar_w + 2, bounds.h + 2)
				d.abar_outline.Visible = true

				d.abar_bg.Position = Vector2.new(bar_x, bounds.y)
				d.abar_bg.Size = Vector2.new(bar_w, bounds.h)
				d.abar_bg.Visible = true

				local fill_h = math.floor(bounds.h * armor_ratio)
				d.abar_fill.Position = Vector2.new(bar_x, bounds.y + (bounds.h - fill_h))
				d.abar_fill.Size = Vector2.new(bar_w, fill_h)
				d.abar_fill.Color = armor_color
				d.abar_fill.Visible = true
			else
				d.abar_outline.Visible = false
				d.abar_bg.Visible = false
				d.abar_fill.Visible = false
			end

			-- ===== WEAPON ICON =====
			if flags["esp_weapon_icon"] and tool then
				local icon_color = get_flag_color("esp_weapon_icon_color")
				d.weapon_icon_text.Position = Vector2.new(bounds.cx, bounds.y + bounds.h + bottom_y_offset)
				d.weapon_icon_text.Text = "[" .. tool.Name .. "]"
				d.weapon_icon_text.Color = icon_color
				d.weapon_icon_text.Font = current_small_font
				d.weapon_icon_text.Visible = true
				bottom_y_offset = bottom_y_offset + 14
			else
				d.weapon_icon_text.Visible = false
			end

			-- ===== SUPER GUN WARNING =====
			if flags["esp_super_gun_warning"] and tool then
				if is_super_gun(tool) then
					local warn_color = get_flag_color("esp_super_gun_warning_color")
					d.super_warning.Position = Vector2.new(bounds.cx, bounds.y - 30)
					d.super_warning.Text = "!! SUPER GUN !!"
					d.super_warning.Color = warn_color
					d.super_warning.Visible = true
				else
					d.super_warning.Visible = false
				end
			else
				d.super_warning.Visible = false
			end

			-- ===== HIGHLIGHT (Roblox Highlight Instance) =====
			if flags["esp_highlight"] then
				local hl_color = get_flag_color("esp_highlight_color")
				local hl_trans = get_flag_transparency("esp_highlight_color")

				if not highlight_cache[player] then
					local hl = Instance.new("Highlight")
					hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					hl.Name = "ESP_Highlight"
					highlight_cache[player] = hl
				end

				local hl = highlight_cache[player]
				hl.FillColor = hl_color
				hl.OutlineColor = hl_color
				hl.FillTransparency = math.clamp(hl_trans, 0, 1)
				hl.OutlineTransparency = 0
				hl.Adornee = character
				hl.Parent = character
				hl.Enabled = true
			else
				if highlight_cache[player] then
					pcall(function()
						highlight_cache[player].Enabled = false
					end)
				end
			end

			-- ===== FORCEFIELD HATS =====
			if flags["esp_forcefield_hats"] then
				local ff_color = get_flag_color("esp_forcefield_hats_color")
				if not prev_forcefield_state[player] then
					apply_forcefield_hats(character, ff_color)
					prev_forcefield_state[player] = true
				end
			else
				if prev_forcefield_state[player] then
					remove_forcefield_hats(character)
					prev_forcefield_state[player] = nil
				end
			end

			-- ===== BODY MATERIAL =====
			if flags["esp_body_material"] then
				local bm_color = get_flag_color("esp_body_material_color")
				if not prev_body_material_state[player] then
					apply_body_material(character, bm_color)
					prev_body_material_state[player] = true
				end
			else
				if prev_body_material_state[player] then
					remove_body_material(character)
					prev_body_material_state[player] = nil
				end
			end
		end
	end)

	-- Rebuild position body ghost model on local player respawn
	LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.5)
		if flags["position_body"] then
			create_position_body()
		end
	end)

	-- Cleanup when a player leaves
	Players.PlayerRemoving:Connect(function(player)
		if esp_cache[player] then
			remove_all_drawings(esp_cache[player])
			esp_cache[player] = nil
		end
		if highlight_cache[player] then
			pcall(function()
				highlight_cache[player]:Destroy()
			end)
			highlight_cache[player] = nil
		end
		if health_connections[player] then
			health_connections[player]:Disconnect()
			health_connections[player] = nil
		end
		prev_health_cache[player] = nil
		prev_forcefield_state[player] = nil
		prev_body_material_state[player] = nil
	end)

	-- Register connection for library unload
	table.insert(library.connections, esp_render_connection)

	-- Store cleanup function
	local old_unload = library._unload_cheat
	library._unload_cheat = function()
		-- Clean ESP
		if esp_render_connection then
			esp_render_connection:Disconnect()
		end
		for _, data in pairs(esp_cache) do
			remove_all_drawings(data)
		end
		for _, hl in pairs(highlight_cache) do
			pcall(function()
				hl:Destroy()
			end)
		end
		for _, conn in pairs(health_connections) do
			conn:Disconnect()
		end
		for i = 1, 4 do
			hit_marker_lines[i]:Remove()
		end
		for _, entry in ipairs(damage_number_queue) do
			entry.drawing:Remove()
		end
		for _, data in pairs(hit_chams_cache) do
			pcall(function()
				data.hl:Destroy()
			end)
		end
		-- Revert materials
		for player, _ in pairs(prev_forcefield_state) do
			local char = player.Character
			if char then
				pcall(function()
					remove_forcefield_hats(char)
				end)
			end
		end
		for player, _ in pairs(prev_body_material_state) do
			local char = player.Character
			if char then
				pcall(function()
					remove_body_material(char)
				end)
			end
		end

		esp_cache = {}
		highlight_cache = {}
		health_connections = {}
		hit_chams_cache = {}
		damage_number_queue = {}

		if cleanup_rt_camera then
			cleanup_rt_camera()
		end

		if old_unload then
			old_unload()
		end
	end
end

-- ==========================================
-- 4. Tab Visuals (World Modulation, Atmosphere, Weather, Skybox, Post-Processing)
-- ==========================================
do
	local Lighting = game:GetService("Lighting")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local SoundService = game:GetService("SoundService")

	-- 1. Backup original Lighting settings
	local orig_lighting = {
		ClockTime = Lighting.ClockTime,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Brightness = Lighting.Brightness,
		ExposureCompensation = Lighting.ExposureCompensation,
		ShadowSoftness = Lighting.ShadowSoftness,
		GlobalShadows = Lighting.GlobalShadows,
		FogColor = Lighting.FogColor,
		FogStart = Lighting.FogStart,
		FogEnd = Lighting.FogEnd,
	}

	local nvl_atmosphere = nil
	local nvl_skybox = nil
	local nvl_color_correction = nil
	local nvl_bloom = nil
	local nvl_blur = nil
	local nvl_sunrays = nil
	local nvl_weather_emitter = nil
	local nvl_weather_particle = nil
	local nvl_weather_sound = nil
	local nvl_lightning_timer = 0
	local nvl_lightning_active = false
	local last_weather_type = nil

	-- Atmosphere Presets Table
	local atmosphere_presets = {
		["Vaporwave Violet"] = { Color = Color3.fromRGB(180, 100, 255), Decay = Color3.fromRGB(255, 120, 200), Density = 0.45, Glare = 3.0, Haze = 4.5 },
		["Cyberpunk Cyan"] = { Color = Color3.fromRGB(0, 230, 255), Decay = Color3.fromRGB(255, 0, 128), Density = 0.4, Glare = 4.0, Haze = 3.5 },
		["Blood Moon Red"] = { Color = Color3.fromRGB(220, 30, 30), Decay = Color3.fromRGB(60, 0, 0), Density = 0.55, Glare = 2.0, Haze = 5.0 },
		["Silent Hill Fog"] = { Color = Color3.fromRGB(180, 185, 195), Decay = Color3.fromRGB(120, 125, 135), Density = 0.75, Glare = 0.5, Haze = 8.0 },
		["Toxic Wasteland"] = { Color = Color3.fromRGB(120, 255, 40), Decay = Color3.fromRGB(50, 100, 20), Density = 0.5, Glare = 2.5, Haze = 4.0 },
		["Sunset Amber"] = { Color = Color3.fromRGB(255, 160, 60), Decay = Color3.fromRGB(180, 40, 80), Density = 0.38, Glare = 5.0, Haze = 3.0 },
		["Ethereal Dream"] = { Color = Color3.fromRGB(220, 210, 255), Decay = Color3.fromRGB(255, 230, 240), Density = 0.3, Glare = 3.5, Haze = 2.5 },
		["Deep Void"] = { Color = Color3.fromRGB(20, 15, 35), Decay = Color3.fromRGB(5, 5, 15), Density = 0.7, Glare = 0, Haze = 7.0 },
	}

	-- Skybox Presets Table (Verified working Roblox Asset IDs)
	local skybox_presets = {
		["Purple Day"] = { Bk = "rbxassetid://296908715", Dn = "rbxassetid://296908724", Ft = "rbxassetid://296908740", Lf = "rbxassetid://296908755", Rt = "rbxassetid://296908764", Up = "rbxassetid://296908769" },
		["Red Blood Sky"] = { Bk = "rbxassetid://401664839", Dn = "rbxassetid://401664862", Ft = "rbxassetid://401664960", Lf = "rbxassetid://401664881", Rt = "rbxassetid://401664901", Up = "rbxassetid://401664936" },
		["Blue Space"] = { Bk = "rbxassetid://15536110634", Dn = "rbxassetid://15536112543", Ft = "rbxassetid://15536116141", Lf = "rbxassetid://15536114370", Rt = "rbxassetid://15536118762", Up = "rbxassetid://15536117282" },
		["Pink Blossom"] = { Bk = "rbxassetid://12216109205", Dn = "rbxassetid://12216109875", Ft = "rbxassetid://12216109489", Lf = "rbxassetid://12216110170", Rt = "rbxassetid://12216110471", Up = "rbxassetid://12216108877" },
		["Black Storm"] = { Bk = "rbxassetid://15502511288", Dn = "rbxassetid://15502508460", Ft = "rbxassetid://15502510289", Lf = "rbxassetid://15502507918", Rt = "rbxassetid://15502509398", Up = "rbxassetid://15502511911" },
		["Realistic Sunset"] = { Bk = "rbxassetid://653719502", Dn = "rbxassetid://653718790", Ft = "rbxassetid://653719067", Lf = "rbxassetid://653719190", Rt = "rbxassetid://653718931", Up = "rbxassetid://653719321" },
		["Minecraft Day"] = { Bk = "rbxassetid://1876545003", Dn = "rbxassetid://1876544331", Ft = "rbxassetid://1876542941", Lf = "rbxassetid://1876543392", Rt = "rbxassetid://1876543764", Up = "rbxassetid://1876544642" },
		["Deep Space Stars"] = { Bk = "rbxassetid://149397692", Dn = "rbxassetid://149397686", Ft = "rbxassetid://149397697", Lf = "rbxassetid://149397684", Rt = "rbxassetid://149397688", Up = "rbxassetid://149397702" },
		["Vibe Morning"] = { Bk = "rbxassetid://1417494030", Dn = "rbxassetid://1417494146", Ft = "rbxassetid://1417494253", Lf = "rbxassetid://1417494402", Rt = "rbxassetid://1417494499", Up = "rbxassetid://1417494643" },
		["Vibe Night"] = { Bk = "rbxassetid://5084575798", Dn = "rbxassetid://5084575916", Ft = "rbxassetid://5103949679", Lf = "rbxassetid://5103948542", Rt = "rbxassetid://5103948784", Up = "rbxassetid://5084576140" },
	}

	-- Weather Presets Table
	local weather_presets = {
		["Rain Storm"] = {
			Texture = "rbxassetid://241594419",
			Color = Color3.fromRGB(190, 215, 255),
			Size = NumberSequence.new(0.35, 0.6),
			Speed = 50,
			Spread = Vector2.new(6, 6),
			Lifetime = NumberRange.new(1.1, 1.6),
			Acceleration = Vector3.new(0, -90, 0),
			EmissionDirection = Enum.NormalId.Bottom,
			LightEmission = 0.2,
		},
		["Winter Snow"] = {
			Texture = "rbxassetid://1347648356",
			Color = Color3.fromRGB(245, 250, 255),
			Size = NumberSequence.new(0.3, 0.8),
			Speed = 12,
			Spread = Vector2.new(18, 18),
			Lifetime = NumberRange.new(3.5, 5.5),
			Acceleration = Vector3.new(5, -15, 2),
			EmissionDirection = Enum.NormalId.Bottom,
			RotSpeed = NumberRange.new(-50, 50),
			LightEmission = 0.1,
		},
		["Sakura Petals"] = {
			Texture = "rbxassetid://6810237739",
			Color = Color3.fromRGB(255, 182, 193),
			Size = NumberSequence.new(0.4, 0.85),
			Speed = 8,
			Spread = Vector2.new(22, 22),
			Lifetime = NumberRange.new(4, 6.5),
			Acceleration = Vector3.new(8, -8, 5),
			EmissionDirection = Enum.NormalId.Bottom,
			RotSpeed = NumberRange.new(-70, 70),
			LightEmission = 0.15,
		},
		["Hell Embers"] = {
			Texture = "rbxassetid://258128463",
			Color = Color3.fromRGB(255, 120, 20),
			Size = NumberSequence.new(0.3, 0.65),
			Speed = 14,
			Spread = Vector2.new(25, 25),
			Lifetime = NumberRange.new(2.5, 4.5),
			Acceleration = Vector3.new(0, 15, 0),
			EmissionDirection = Enum.NormalId.Top,
			RotSpeed = NumberRange.new(-100, 100),
			LightEmission = 1.0,
		},
		["Cosmic Stardust"] = {
			Texture = "rbxassetid://258127529",
			Color = Color3.fromRGB(170, 120, 255),
			Size = NumberSequence.new(0.25, 0.75),
			Speed = 6,
			Spread = Vector2.new(30, 30),
			Lifetime = NumberRange.new(3, 5),
			Acceleration = Vector3.new(0, -3, 0),
			EmissionDirection = Enum.NormalId.Bottom,
			RotSpeed = NumberRange.new(-40, 40),
			LightEmission = 1.0,
		},
		["Acid Rain"] = {
			Texture = "rbxassetid://241594419",
			Color = Color3.fromRGB(70, 255, 90),
			Size = NumberSequence.new(0.35, 0.6),
			Speed = 50,
			Spread = Vector2.new(6, 6),
			Lifetime = NumberRange.new(1.1, 1.6),
			Acceleration = Vector3.new(0, -90, 0),
			EmissionDirection = Enum.NormalId.Bottom,
			LightEmission = 0.6,
		},
		["Blood Rain"] = {
			Texture = "rbxassetid://241594419",
			Color = Color3.fromRGB(210, 25, 35),
			Size = NumberSequence.new(0.4, 0.65),
			Speed = 55,
			Spread = Vector2.new(6, 6),
			Lifetime = NumberRange.new(1.1, 1.6),
			Acceleration = Vector3.new(0, -95, 0),
			EmissionDirection = Enum.NormalId.Bottom,
			LightEmission = 0.35,
		},
		["Night Fireflies"] = {
			Texture = "rbxassetid://258127045",
			Color = Color3.fromRGB(220, 255, 80),
			Size = NumberSequence.new(0.3, 0.7),
			Speed = 4,
			Spread = Vector2.new(45, 45),
			Lifetime = NumberRange.new(4, 7),
			Acceleration = Vector3.new(0, 0, 0),
			EmissionDirection = Enum.NormalId.Top,
			LightEmission = 1.0,
		},
	}

	-- Color Correction Presets
	local cc_presets = {
		["Vibrant Contrast"] = { Saturation = 0.8, Contrast = 0.4, Tint = Color3.fromRGB(255, 255, 255) },
		["Cinematic Noir"] = { Saturation = -0.9, Contrast = 0.5, Tint = Color3.fromRGB(230, 235, 245) },
		["Cold Winter"] = { Saturation = -0.2, Contrast = 0.25, Tint = Color3.fromRGB(180, 215, 255) },
		["Warm Sunset"] = { Saturation = 0.5, Contrast = 0.3, Tint = Color3.fromRGB(255, 210, 180) },
		["Matrix Green"] = { Saturation = 0.2, Contrast = 0.45, Tint = Color3.fromRGB(140, 255, 160) },
		["Cyber Glitch"] = { Saturation = 1.2, Contrast = 0.6, Tint = Color3.fromRGB(255, 180, 240) },
		["Vintage Pastel"] = { Saturation = -0.3, Contrast = -0.1, Tint = Color3.fromRGB(255, 245, 220) },
	}

	-- SECTION 1: Atmosphere & Lighting (Left Side)
	local atmo_section = visuals:section({ name = "Atmosphere & Lighting", side = "left" })

	atmo_section:toggle({
		name = "Atmosphere modulation",
		flag = "atmosphere_enabled",
		default = false
	}):colorpicker({
		flag = "atmosphere_color",
		color = Color3.fromRGB(140, 110, 240)
	})

	atmo_section:dropdown({
		name = "Atmosphere preset",
		flag = "atmosphere_preset",
		items = { "Custom", "Vaporwave Violet", "Cyberpunk Cyan", "Blood Moon Red", "Silent Hill Fog", "Toxic Wasteland", "Sunset Amber", "Ethereal Dream", "Deep Void" },
		multi = false,
		default = "Vaporwave Violet"
	})

	atmo_section:slider({
		name = "Density",
		flag = "atmosphere_density",
		min = 0,
		max = 1,
		decimal = 0.01,
		default = 0.35
	})

	atmo_section:slider({
		name = "Glare",
		flag = "atmosphere_glare",
		min = 0,
		max = 10,
		decimal = 0.1,
		default = 1.5
	})

	atmo_section:slider({
		name = "Haze",
		flag = "atmosphere_haze",
		min = 0,
		max = 10,
		decimal = 0.1,
		default = 2.0
	})

	atmo_section:toggle({
		name = "Atmosphere decay",
		flag = "atmosphere_decay",
		default = false
	}):colorpicker({
		flag = "atmosphere_decay_color",
		color = Color3.fromRGB(255, 180, 220)
	})

	atmo_section:toggle({
		name = "Time changer",
		flag = "time_changer",
		default = false
	})

	atmo_section:slider({
		name = "Time of day",
		flag = "time_changer_value",
		min = 0,
		max = 24,
		decimal = 0.1,
		default = 0,
		suffix = "h"
	})

	atmo_section:toggle({
		name = "Ambient changer",
		flag = "ambient_changer",
		default = false
	}):colorpicker({
		flag = "ambient_color",
		color = Color3.fromRGB(120, 120, 150)
	})

	atmo_section:toggle({
		name = "Outdoor ambient",
		flag = "outdoor_ambient_changer",
		default = false
	}):colorpicker({
		flag = "outdoor_ambient_color",
		color = Color3.fromRGB(80, 80, 100)
	})

	atmo_section:toggle({
		name = "Brightness changer",
		flag = "brightness_changer",
		default = false
	})

	atmo_section:slider({
		name = "Brightness",
		flag = "brightness_value",
		min = -5,
		max = 10,
		decimal = 0.1,
		default = 1
	})

	atmo_section:toggle({
		name = "Exposure changer",
		flag = "exposure_changer",
		default = false
	})

	atmo_section:slider({
		name = "Exposure",
		flag = "exposure_value",
		min = -5,
		max = 5,
		decimal = 0.1,
		default = 0
	})

	atmo_section:slider({
		name = "Shadow softness",
		flag = "shadow_softness",
		min = 0,
		max = 1,
		decimal = 0.05,
		default = 0.2
	})

	atmo_section:toggle({
		name = "Global shadows",
		flag = "global_shadows",
		default = true
	})

	-- SECTION 2: Post-Processing & Shaders (Left Side)
	local post_section = visuals:section({ name = "Post-Processing & Shaders", side = "left" })

	post_section:toggle({
		name = "Color correction",
		flag = "color_correction_enabled",
		default = false
	}):colorpicker({
		flag = "color_correction_tint",
		color = Color3.fromRGB(255, 255, 255)
	})

	post_section:dropdown({
		name = "Color preset",
		flag = "color_correction_preset",
		items = { "Custom", "Vibrant Contrast", "Cinematic Noir", "Cold Winter", "Warm Sunset", "Matrix Green", "Cyber Glitch", "Vintage Pastel" },
		multi = false,
		default = "Vibrant Contrast"
	})

	post_section:slider({
		name = "Saturation",
		flag = "color_correction_saturation",
		min = -2,
		max = 5,
		decimal = 0.1,
		default = 0.4
	})

	post_section:slider({
		name = "Contrast",
		flag = "color_correction_contrast",
		min = -2,
		max = 5,
		decimal = 0.1,
		default = 0.2
	})

	post_section:toggle({
		name = "Bloom effect",
		flag = "bloom_enabled",
		default = false
	})

	post_section:slider({
		name = "Bloom intensity",
		flag = "bloom_intensity",
		min = 0,
		max = 5,
		decimal = 0.1,
		default = 1.0
	})

	post_section:slider({
		name = "Bloom size",
		flag = "bloom_size",
		min = 0,
		max = 56,
		default = 24
	})

	post_section:slider({
		name = "Bloom threshold",
		flag = "bloom_threshold",
		min = 0,
		max = 4,
		decimal = 0.1,
		default = 1.2
	})

	post_section:toggle({
		name = "Sun rays",
		flag = "sunrays_enabled",
		default = false
	})

	post_section:slider({
		name = "Sun rays intensity",
		flag = "sunrays_intensity",
		min = 0,
		max = 1,
		decimal = 0.05,
		default = 0.25
	})

	post_section:slider({
		name = "Sun rays spread",
		flag = "sunrays_spread",
		min = 0,
		max = 1,
		decimal = 0.05,
		default = 0.8
	})

	post_section:toggle({
		name = "Depth blur",
		flag = "blur_enabled",
		default = false
	})

	post_section:slider({
		name = "Blur size",
		flag = "blur_size",
		min = 0,
		max = 30,
		default = 4
	})

	-- SECTION 3: Custom Skybox & Space (Right Side)
	local sky_section = visuals:section({ name = "Custom Skybox & Space", side = "right" })

	sky_section:toggle({
		name = "Skybox changer",
		flag = "skybox_enabled",
		default = false
	})

	sky_section:dropdown({
		name = "Skybox preset",
		flag = "skybox_preset",
		items = { "Purple Day", "Red Blood Sky", "Blue Space", "Pink Blossom", "Black Storm", "Realistic Sunset", "Minecraft Day", "Deep Space Stars", "Vibe Morning", "Vibe Night", "Custom" },
		multi = false,
		default = "Purple Day"
	})

	sky_section:slider({
		name = "Star density",
		flag = "skybox_stars",
		min = 0,
		max = 5000,
		default = 3000
	})

	sky_section:toggle({
		name = "Sun & Moon visible",
		flag = "skybox_celestial",
		default = true
	})

	sky_section:textbox({
		name = "SkyboxBk",
		flag = "skybox_bk",
		default = ""
	})

	sky_section:textbox({
		name = "SkyboxDn",
		flag = "skybox_dn",
		default = ""
	})

	sky_section:textbox({
		name = "SkyboxFt",
		flag = "skybox_ft",
		default = ""
	})

	sky_section:textbox({
		name = "SkyboxLf",
		flag = "skybox_lf",
		default = ""
	})

	sky_section:textbox({
		name = "SkyboxRt",
		flag = "skybox_rt",
		default = ""
	})

	sky_section:textbox({
		name = "SkyboxUp",
		flag = "skybox_up",
		default = ""
	})

	-- SECTION 4: Dynamic Weather System (Right Side)
	local weather_section = visuals:section({ name = "Dynamic Weather System", side = "right" })

	weather_section:toggle({
		name = "Weather simulation",
		flag = "weather_enabled",
		default = false
	})

	weather_section:dropdown({
		name = "Weather type",
		flag = "weather_type",
		items = { "Rain Storm", "Winter Snow", "Sakura Petals", "Hell Embers", "Cosmic Stardust", "Acid Rain", "Blood Rain", "Night Fireflies" },
		multi = false,
		default = "Rain Storm"
	})

	weather_section:slider({
		name = "Emission rate",
		flag = "weather_intensity",
		min = 10,
		max = 500,
		default = 150,
		suffix = " pt/s"
	})

	weather_section:slider({
		name = "Falling speed",
		flag = "weather_speed",
		min = 1,
		max = 60,
		default = 35
	})

	weather_section:toggle({
		name = "Custom particle color",
		flag = "weather_custom_color",
		default = false
	}):colorpicker({
		flag = "weather_color",
		color = Color3.fromRGB(200, 225, 255)
	})

	weather_section:toggle({
		name = "Thunder & lightning",
		flag = "weather_lightning",
		default = false
	})

	weather_section:toggle({
		name = "Ambient weather audio",
		flag = "weather_audio",
		default = false
	})

	weather_section:slider({
		name = "Audio volume",
		flag = "weather_audio_volume",
		min = 0.1,
		max = 3,
		decimal = 0.1,
		default = 1
	})

	-- SECTION 5: World & Viewport (Right Side)
	local world_section = visuals:section({ name = "World & Viewport", side = "right" })

	world_section:toggle({
		name = "Custom FOV",
		flag = "custom_fov_enabled",
		default = false
	})

	world_section:slider({
		name = "Field of view",
		flag = "custom_fov_value",
		min = 60,
		max = 130,
		default = 90,
		suffix = "°"
	})

	world_section:toggle({
		name = "Unlock max zoom distance",
		flag = "unlock_zoom",
		default = false
	})

	world_section:toggle({
		name = "Fullbright (Nightvision)",
		flag = "fullbright",
		default = false
	})

	world_section:toggle({
		name = "Remove world fog",
		flag = "no_fog",
		default = false
	})

	world_section:toggle({
		name = "Custom fog",
		flag = "custom_fog_enabled",
		default = false
	}):colorpicker({
		flag = "custom_fog_color",
		color = Color3.fromRGB(150, 160, 180)
	})

	world_section:slider({
		name = "Fog start",
		flag = "custom_fog_start",
		min = 0,
		max = 5000,
		default = 0
	})

	world_section:slider({
		name = "Fog end",
		flag = "custom_fog_end",
		min = 50,
		max = 5000,
		default = 1000
	})

	world_section:toggle({
		name = "Clean world (FPS Boost)",
		flag = "clean_world",
		default = false
	})

	-- =========================================================================
	-- CORE LOGIC RUNTIME
	-- =========================================================================

	-- Helper: update Atmosphere
	local function update_atmosphere()
		if flags["atmosphere_enabled"] then
			if not nvl_atmosphere or not nvl_atmosphere.Parent then
				nvl_atmosphere = Lighting:FindFirstChild("NVL_Atmosphere") or Instance.new("Atmosphere")
				nvl_atmosphere.Name = "NVL_Atmosphere"
				nvl_atmosphere.Parent = Lighting
			end

			local preset_name = flags["atmosphere_preset"]
			if type(preset_name) == "table" then preset_name = preset_name[1] end

			if preset_name and atmosphere_presets[preset_name] and preset_name ~= "Custom" then
				local p = atmosphere_presets[preset_name]
				nvl_atmosphere.Color = flags["atmosphere_color"] and get_flag_color("atmosphere_color") or p.Color
				nvl_atmosphere.Decay = flags["atmosphere_decay"] and get_flag_color("atmosphere_decay_color") or p.Decay
				nvl_atmosphere.Density = flags["atmosphere_density"] or p.Density
				nvl_atmosphere.Glare = flags["atmosphere_glare"] or p.Glare
				nvl_atmosphere.Haze = flags["atmosphere_haze"] or p.Haze
			else
				nvl_atmosphere.Color = get_flag_color("atmosphere_color")
				if flags["atmosphere_decay"] then
					nvl_atmosphere.Decay = get_flag_color("atmosphere_decay_color")
				end
				nvl_atmosphere.Density = flags["atmosphere_density"] or 0.35
				nvl_atmosphere.Glare = flags["atmosphere_glare"] or 1.5
				nvl_atmosphere.Haze = flags["atmosphere_haze"] or 2.0
			end
		else
			if nvl_atmosphere then
				pcall(function() nvl_atmosphere:Destroy() end)
				nvl_atmosphere = nil
			end
		end
	end

	-- Helper: update Skybox
	local function update_skybox()
		if flags["skybox_enabled"] then
			if not nvl_skybox or not nvl_skybox.Parent then
				nvl_skybox = Lighting:FindFirstChild("NVL_Skybox") or Instance.new("Sky")
				nvl_skybox.Name = "NVL_Skybox"
				nvl_skybox.Parent = Lighting
			end

			local preset_name = flags["skybox_preset"]
			if type(preset_name) == "table" then preset_name = preset_name[1] end

			if preset_name == "Custom" then
				if flags["skybox_bk"] and flags["skybox_bk"] ~= "" then nvl_skybox.SkyboxBk = flags["skybox_bk"] end
				if flags["skybox_dn"] and flags["skybox_dn"] ~= "" then nvl_skybox.SkyboxDn = flags["skybox_dn"] end
				if flags["skybox_ft"] and flags["skybox_ft"] ~= "" then nvl_skybox.SkyboxFt = flags["skybox_ft"] end
				if flags["skybox_lf"] and flags["skybox_lf"] ~= "" then nvl_skybox.SkyboxLf = flags["skybox_lf"] end
				if flags["skybox_rt"] and flags["skybox_rt"] ~= "" then nvl_skybox.SkyboxRt = flags["skybox_rt"] end
				if flags["skybox_up"] and flags["skybox_up"] ~= "" then nvl_skybox.SkyboxUp = flags["skybox_up"] end
			elseif preset_name and skybox_presets[preset_name] then
				local p = skybox_presets[preset_name]
				nvl_skybox.SkyboxBk = p.Bk
				nvl_skybox.SkyboxDn = p.Dn
				nvl_skybox.SkyboxFt = p.Ft
				nvl_skybox.SkyboxLf = p.Lf
				nvl_skybox.SkyboxRt = p.Rt
				nvl_skybox.SkyboxUp = p.Up
			end

			nvl_skybox.StarCount = flags["skybox_stars"] or 3000
			nvl_skybox.CelestialBodiesShown = flags["skybox_celestial"] ~= false
		else
			if nvl_skybox then
				pcall(function() nvl_skybox:Destroy() end)
				nvl_skybox = nil
			end
		end
	end

	-- Helper: update Post Processing
	local function update_post_processing()
		-- Color Correction
		if flags["color_correction_enabled"] then
			if not nvl_color_correction or not nvl_color_correction.Parent then
				nvl_color_correction = Lighting:FindFirstChild("NVL_ColorCorrection") or Instance.new("ColorCorrectionEffect")
				nvl_color_correction.Name = "NVL_ColorCorrection"
				nvl_color_correction.Parent = Lighting
			end

			local preset_name = flags["color_correction_preset"]
			if type(preset_name) == "table" then preset_name = preset_name[1] end

			if preset_name and cc_presets[preset_name] and preset_name ~= "Custom" then
				local p = cc_presets[preset_name]
				nvl_color_correction.TintColor = p.Tint
				nvl_color_correction.Saturation = flags["color_correction_saturation"] or p.Saturation
				nvl_color_correction.Contrast = flags["color_correction_contrast"] or p.Contrast
			else
				nvl_color_correction.TintColor = get_flag_color("color_correction_tint")
				nvl_color_correction.Saturation = flags["color_correction_saturation"] or 0.4
				nvl_color_correction.Contrast = flags["color_correction_contrast"] or 0.2
			end
		else
			if nvl_color_correction then
				pcall(function() nvl_color_correction:Destroy() end)
				nvl_color_correction = nil
			end
		end

		-- Bloom
		if flags["bloom_enabled"] then
			if not nvl_bloom or not nvl_bloom.Parent then
				nvl_bloom = Lighting:FindFirstChild("NVL_Bloom") or Instance.new("BloomEffect")
				nvl_bloom.Name = "NVL_Bloom"
				nvl_bloom.Parent = Lighting
			end
			nvl_bloom.Intensity = flags["bloom_intensity"] or 1.0
			nvl_bloom.Size = flags["bloom_size"] or 24
			nvl_bloom.Threshold = flags["bloom_threshold"] or 1.2
		else
			if nvl_bloom then
				pcall(function() nvl_bloom:Destroy() end)
				nvl_bloom = nil
			end
		end

		-- Blur
		if flags["blur_enabled"] then
			if not nvl_blur or not nvl_blur.Parent then
				nvl_blur = Lighting:FindFirstChild("NVL_Blur") or Instance.new("BlurEffect")
				nvl_blur.Name = "NVL_Blur"
				nvl_blur.Parent = Lighting
			end
			nvl_blur.Size = flags["blur_size"] or 4
		else
			if nvl_blur then
				pcall(function() nvl_blur:Destroy() end)
				nvl_blur = nil
			end
		end

		-- SunRays
		if flags["sunrays_enabled"] then
			if not nvl_sunrays or not nvl_sunrays.Parent then
				nvl_sunrays = Lighting:FindFirstChild("NVL_SunRays") or Instance.new("SunRaysEffect")
				nvl_sunrays.Name = "NVL_SunRays"
				nvl_sunrays.Parent = Lighting
			end
			nvl_sunrays.Intensity = flags["sunrays_intensity"] or 0.25
			nvl_sunrays.Spread = flags["sunrays_spread"] or 0.8
		else
			if nvl_sunrays then
				pcall(function() nvl_sunrays:Destroy() end)
				nvl_sunrays = nil
			end
		end
	end

	-- Helper: update Weather
	local function update_weather()
		if flags["weather_enabled"] then
			if not nvl_weather_emitter or not nvl_weather_emitter.Parent then
				nvl_weather_emitter = workspace:FindFirstChild("NVL_WeatherEmitter") or Instance.new("Part")
				nvl_weather_emitter.Name = "NVL_WeatherEmitter"
				nvl_weather_emitter.Transparency = 1
				nvl_weather_emitter.CanCollide = false
				nvl_weather_emitter.CanTouch = false
				nvl_weather_emitter.CanQuery = false
				nvl_weather_emitter.Anchored = true
				nvl_weather_emitter.Size = Vector3.new(130, 2, 130)
				nvl_weather_emitter.Parent = workspace
			end

			if not nvl_weather_particle or not nvl_weather_particle.Parent then
				nvl_weather_particle = nvl_weather_emitter:FindFirstChild("NVL_WeatherParticle") or Instance.new("ParticleEmitter")
				nvl_weather_particle.Name = "NVL_WeatherParticle"
				nvl_weather_particle.Parent = nvl_weather_emitter
			end

			local w_type = flags["weather_type"]
			if type(w_type) == "table" then w_type = w_type[1] end

			local cfg = weather_presets[w_type] or weather_presets["Rain Storm"]

			if last_weather_type ~= w_type then
				last_weather_type = w_type
				nvl_weather_particle.Texture = cfg.Texture
				nvl_weather_particle.Size = cfg.Size
				nvl_weather_particle.SpreadAngle = cfg.Spread
				nvl_weather_particle.Lifetime = cfg.Lifetime
				nvl_weather_particle.Acceleration = cfg.Acceleration
				nvl_weather_particle.EmissionDirection = cfg.EmissionDirection
				nvl_weather_particle.LightEmission = cfg.LightEmission
				if cfg.RotSpeed then
					nvl_weather_particle.RotSpeed = cfg.RotSpeed
				else
					nvl_weather_particle.RotSpeed = NumberRange.new(0, 0)
				end
			end

			local spd = flags["weather_speed"] or cfg.Speed
			nvl_weather_particle.Speed = NumberRange.new(spd * 0.85, spd * 1.15)
			nvl_weather_particle.Rate = flags["weather_intensity"] or 150

			if flags["weather_custom_color"] then
				local c = get_flag_color("weather_color")
				nvl_weather_particle.Color = ColorSequence.new(c)
			else
				nvl_weather_particle.Color = ColorSequence.new(cfg.Color)
			end

			-- Audio
			if flags["weather_audio"] then
				if not nvl_weather_sound or not nvl_weather_sound.Parent then
					nvl_weather_sound = Instance.new("Sound")
					nvl_weather_sound.Name = "NVL_WeatherSound"
					nvl_weather_sound.Looped = true
					nvl_weather_sound.SoundId = (w_type == "Rain Storm" or w_type == "Acid Rain" or w_type == "Blood Rain") and "rbxassetid://9114223171" or "rbxassetid://9114221768"
					nvl_weather_sound.Parent = SoundService
					nvl_weather_sound:Play()
				end
				nvl_weather_sound.Volume = flags["weather_audio_volume"] or 1
			else
				if nvl_weather_sound then
					pcall(function() nvl_weather_sound:Stop(); nvl_weather_sound:Destroy() end)
					nvl_weather_sound = nil
				end
			end
		else
			if nvl_weather_emitter then
				pcall(function() nvl_weather_emitter:Destroy() end)
				nvl_weather_emitter = nil
				nvl_weather_particle = nil
				last_weather_type = nil
			end
			if nvl_weather_sound then
				pcall(function() nvl_weather_sound:Stop(); nvl_weather_sound:Destroy() end)
				nvl_weather_sound = nil
			end
		end
	end

	-- Master Render Connection
	local visuals_connection
	visuals_connection = RunService.RenderStepped:Connect(function(dt)
		-- 1. Camera FOV
		if flags["custom_fov_enabled"] and camera then
			camera.FieldOfView = flags["custom_fov_value"] or 90
		end

		-- 2. Unlock Zoom
		if flags["unlock_zoom"] and LocalPlayer then
			LocalPlayer.CameraMaxZoomDistance = 10000
		end

		-- 3. Weather Emitter Position
		if nvl_weather_emitter and camera then
			nvl_weather_emitter.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 35, 0))
		end

		-- 4. Thunder & Lightning Random Flash
		if flags["weather_enabled"] and flags["weather_lightning"] and not nvl_lightning_active then
			nvl_lightning_timer = nvl_lightning_timer + dt
			if nvl_lightning_timer >= 6 then
				nvl_lightning_timer = 0
				if math.random(1, 100) <= 40 then
					nvl_lightning_active = true
					task.spawn(function()
						local prev_b = Lighting.Brightness
						local prev_a = Lighting.Ambient
						Lighting.Brightness = 8
						Lighting.Ambient = Color3.fromRGB(255, 255, 255)
						task.wait(0.06)
						Lighting.Brightness = 2
						Lighting.Ambient = Color3.fromRGB(150, 150, 180)
						task.wait(0.04)
						Lighting.Brightness = 6
						task.wait(0.08)
						Lighting.Brightness = prev_b
						Lighting.Ambient = prev_a
						nvl_lightning_active = false
					end)
				end
			end
		end

		-- 5. Lighting Overrides
		if flags["fullbright"] then
			Lighting.Brightness = 2
			Lighting.ClockTime = 14
			Lighting.FogEnd = 100000
			Lighting.GlobalShadows = false
			Lighting.Ambient = Color3.fromRGB(255, 255, 255)
			Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		else
			if flags["time_changer"] then
				Lighting.ClockTime = flags["time_changer_value"] or 0
			end
			if flags["ambient_changer"] then
				Lighting.Ambient = get_flag_color("ambient_color")
			end
			if flags["outdoor_ambient_changer"] then
				Lighting.OutdoorAmbient = get_flag_color("outdoor_ambient_color")
			end
			if flags["brightness_changer"] then
				Lighting.Brightness = flags["brightness_value"] or 1
			end
			if flags["exposure_changer"] then
				Lighting.ExposureCompensation = flags["exposure_value"] or 0
			end
			Lighting.ShadowSoftness = flags["shadow_softness"] or 0.2
			Lighting.GlobalShadows = flags["global_shadows"] ~= false

			-- Fog
			if flags["no_fog"] then
				Lighting.FogEnd = 100000
				Lighting.FogStart = 0
			elseif flags["custom_fog_enabled"] then
				Lighting.FogColor = get_flag_color("custom_fog_color")
				Lighting.FogStart = flags["custom_fog_start"] or 0
				Lighting.FogEnd = flags["custom_fog_end"] or 1000
			end
		end

		-- 6. Clean World
		if flags["clean_world"] then
			pcall(function()
				workspace.Terrain.Decoration = false
			end)
		end
	end)
	table.insert(_nvl_conns, visuals_connection)

	-- Periodic Subsystem Sync (Atmosphere, Skybox, PostProcessing, Weather)
	local visual_sync_thread = task.spawn(function()
		while true do
			pcall(update_atmosphere)
			pcall(update_skybox)
			pcall(update_post_processing)
			pcall(update_weather)
			task.wait(0.25)
		end
	end)

	-- Hook Unload for Visuals
	local prev_cheat_unload = library._unload_cheat
	library._unload_cheat = function()
		if visuals_connection then
			visuals_connection:Disconnect()
		end
		pcall(function() task.cancel(visual_sync_thread) end)

		-- Restore Lighting
		pcall(function()
			for prop, val in pairs(orig_lighting) do
				Lighting[prop] = val
			end
			if nvl_atmosphere then nvl_atmosphere:Destroy() end
			if nvl_skybox then nvl_skybox:Destroy() end
			if nvl_color_correction then nvl_color_correction:Destroy() end
			if nvl_bloom then nvl_bloom:Destroy() end
			if nvl_blur then nvl_blur:Destroy() end
			if nvl_sunrays then nvl_sunrays:Destroy() end
			if nvl_weather_emitter then nvl_weather_emitter:Destroy() end
			if nvl_weather_sound then nvl_weather_sound:Destroy() end
			if camera then camera.FieldOfView = 70 end
			if LocalPlayer then LocalPlayer.CameraMaxZoomDistance = 128 end
		end)

		if prev_cheat_unload then
			prev_cheat_unload()
		end
	end
end

-- ==========================================
-- 5. Tab Mics (Ảnh 5)
-- ==========================================
do
	local movement = mics:section({ name = "Movement", side = "left" })

	-- WalkSpeed Modifier (1/1000 precision)
	local _ws_original_speed = 16
	local _ws_override_conn = nil
	local _ws_override_value = 0

	movement:toggle({
		name = "WalkSpeed Modifier",
		flag = "misc_ws_override",
		default = false,
		callback = function(val)
			if _ws_override_conn then
				_ws_override_conn:Disconnect()
				_ws_override_conn = nil
			end
			if val then
				local hum = local_parts["Humanoid"]
				if hum then
					_ws_original_speed = hum.WalkSpeed
					if _ws_original_speed <= 0 then _ws_original_speed = 16 end
				else
					_ws_original_speed = 16
				end
				_ws_override_conn = RunService.Heartbeat:Connect(function()
					local humanoid = local_parts["Humanoid"]
					if humanoid and not local_knocked and humanoid.Health > 0 then
						-- 0 = tốc độ gốc; âm = đi chậm hơn; dương = đi nhanh hơn
						local target_speed = _ws_original_speed + _ws_override_value
						if target_speed < 0 then target_speed = 0 end
						humanoid.WalkSpeed = target_speed
					end
				end)
				table.insert(_nvl_conns, _ws_override_conn)
			else
				local hum = local_parts["Humanoid"]
				if hum and _ws_original_speed then
					hum.WalkSpeed = _ws_original_speed
				end
			end
		end
	}):keybind({
		flag = "misc_ws_override_bind",
		default = Enum.KeyCode.V
	})

	movement:slider({
		name = "Speed Offset (+/-)",
		flag = "misc_ws_override_value",
		min = -16,
		max = 1000,
		default = 0,
		interval = 0.001,
		callback = function(val)
			_ws_override_value = val
		end
	})

	local speed_multiplier = 35 * 16
	local speed_style = "normal"
	local speed_slippery_velocity = Vector3.new(0, 0, 0)
	local speed_connection
	movement:toggle({
		name = "CFrame speed",
		flag = "misc_cframe_speed",
		default = false,
		callback = function(val)
			if speed_connection then
				speed_connection:Disconnect()
				speed_connection = nil
			end
			speed_slippery_velocity = Vector3.new(0, 0, 0)
			if val then
				speed_connection = RunService.Heartbeat:Connect(function(dt)
					local hrp = local_parts["HumanoidRootPart"]
					local humanoid = local_parts["Humanoid"]
					if hrp and humanoid and not local_knocked and humanoid.Health > 0 then
						local move_direction = humanoid.MoveDirection
						if speed_style == "normal" then
							hrp.CFrame = hrp.CFrame + (Vector3.new(move_direction.X, 0, move_direction.Z) * dt * speed_multiplier)
						elseif speed_style == "bhop" then
							hrp.CFrame = hrp.CFrame + (Vector3.new(move_direction.X, 0, move_direction.Z) * dt * speed_multiplier)
							if humanoid:GetState() == Enum.HumanoidStateType.Running and move_direction.Magnitude > 0 then
								humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
							end
						elseif speed_style == "minecraft" then
							hrp.CFrame = hrp.CFrame + (Vector3.new(move_direction.X, 0, move_direction.Z) * dt * speed_multiplier)
							if humanoid:GetState() == Enum.HumanoidStateType.Running and move_direction.Magnitude > 0 then
								humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								hrp.Velocity = Vector3.new(hrp.Velocity.X, hrp.Velocity.Y * 1.5, hrp.Velocity.Z)
								task.wait(humanoid.JumpPower / 500)
								if hrp then
									hrp.Velocity = Vector3.new(hrp.Velocity.X, hrp.Velocity.Y * -1.1, hrp.Velocity.Z)
								end
							end
						elseif speed_style == "slippery" then
							local old = hrp.Velocity
							if move_direction.Magnitude > 0 then
								speed_slippery_velocity = speed_slippery_velocity:Lerp(move_direction * dt * speed_multiplier * 150, 0.35) * (1 + dt)
							end
							speed_slippery_velocity = speed_slippery_velocity * (1 - (dt * 4))
							hrp.Velocity = Vector3.new(speed_slippery_velocity.X, old.Y, speed_slippery_velocity.Z)
						end
					end
				end)
			end
		end
	}):keybind({
		flag = "misc_cframe_speed_bind",
		default = Enum.KeyCode.C
	})

	movement:slider({
		name = "Speed value",
		flag = "misc_speed_value",
		min = 1,
		max = 100,
		default = 5,
		suffix = "%",
		callback = function(val)
			speed_multiplier = val * 16
		end
	})

	movement:dropdown({
		name = "Speed style",
		flag = "misc_speed_style",
		items = { "normal", "bhop", "minecraft", "slippery" },
		multi = false,
		default = "normal",
		callback = function(val)
			speed_style = val
			speed_slippery_velocity = Vector3.new(0, 0, 0)
		end
	})

	local fly_multiplier = 35 * 50
	local fly_connection
	movement:toggle({
		name = "CFrame fly",
		flag = "misc_cframe_fly",
		default = false,
		callback = function(val)
			if fly_connection then
				fly_connection:Disconnect()
				fly_connection = nil
			end
			if val then
				fly_connection = RunService.Heartbeat:Connect(function(dt)
					local hrp = local_parts["HumanoidRootPart"]
					local humanoid = local_parts["Humanoid"]
					if hrp and humanoid and not local_knocked and humanoid.Health > 0 then
						local move_direction = humanoid.MoveDirection
						hrp.Velocity = Vector3.new(0, math.pi - 2, 0)

						local y_move = 0
						if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
							y_move = 1
						elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
							y_move = -1
						else
							local cam_look = camera.CFrame.lookVector.Y
							if UserInputService:IsKeyDown(Enum.KeyCode.W) then
								y_move = cam_look
							elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
								y_move = -cam_look
							end
							y_move = y_move * math.clamp(move_direction.Magnitude, 0, 1)
						end

						local move_dir = Vector3.new(move_direction.X, y_move, move_direction.Z)
						hrp.CFrame = hrp.CFrame + (move_dir * dt * fly_multiplier)
					end
				end)
			end
		end
	}):keybind({
		flag = "misc_cframe_fly_bind",
		default = Enum.KeyCode.X
	})

	movement:slider({
		name = "Fly speed",
		flag = "misc_fly_value",
		min = 1,
		max = 100,
		default = 5,
		suffix = "%",
		callback = function(val)
			fly_multiplier = val * 50
		end
	})

	movement:toggle({
		name = "Noclip",
		flag = "misc_noclip",
		default = false
	})

	-- >> Animation & Emote System (Integrated from animation.lua & get_rbxassetid.lua)
	local InsertService = (cloneref and cloneref(game:GetService("InsertService"))) or game:GetService("InsertService")
	local MarketplaceService = (cloneref and cloneref(game:GetService("MarketplaceService"))) or game:GetService("MarketplaceService")

	local function copy_to_clipboard(text)
		if setclipboard then
			setclipboard(text)
		elseif toclipboard then
			toclipboard(text)
		elseif Synapse and Synapse.set_clipboard then
			Synapse.set_clipboard(text)
		end
	end

	-- Remove Anti Gun Macro
	local function do_remove_anti_gun_macro()
		if not getgc or not getinfo or not setconstant or not getconstants or not islclosure then return end
		local new_constant = "_!_"
		pcall(function()
			local gc = getgc()
			for i = 1, #gc do
				local obj = gc[i]
				if type(obj) == "function" and islclosure(obj) then
					local info = getinfo(obj)
					if info and info.source and info.source:find("BaseCamera") then
						local constants = getconstants(obj)
						for idx, constant in pairs(constants) do
							if constant == "HoldGunBool" or constant == "_!_" then
								setconstant(obj, idx, new_constant)
							end
						end
					end
				end
			end
		end)
	end
	task.spawn(do_remove_anti_gun_macro)
	LocalPlayer.CharacterAdded:Connect(function()
		task.wait(1)
		do_remove_anti_gun_macro()
	end)

	local function get_rbx_asset_id(catalogId)
		local id_str = tostring(catalogId):match("%d+")
		if not id_str then return "" end

		-- Method 1: game:GetObjects
		local ok, objects = pcall(function()
			return game:GetObjects("rbxassetid://" .. id_str)
		end)
		if ok and objects and #objects > 0 then
			for _, obj in pairs(objects) do
				local function search(o, depth)
					if depth > 10 then return nil end
					if o:IsA("Animation") and o.AnimationId ~= "" then
						return o.AnimationId
					end
					if o:IsA("KeyframeSequence") then
						return "rbxassetid://" .. id_str
					end
					pcall(function()
						if o.AnimationId and o.AnimationId ~= "" then
							return o.AnimationId
						end
					end)
					for _, child in pairs(o:GetChildren()) do
						local r = search(child, (depth or 0) + 1)
						if r then return r end
					end
					return nil
				end
				local result = search(obj, 0)
				if result then return result end
			end
			return "rbxassetid://" .. id_str
		end

		-- Method 2: InsertService
		local ok2, model = pcall(function()
			return InsertService:LoadAsset(tonumber(id_str))
		end)
		if ok2 and model then
			local found = nil
			local function findAnim(parent, depth)
				if depth > 10 or found then return end
				for _, child in pairs(parent:GetChildren()) do
					if child:IsA("Animation") and child.AnimationId ~= "" then
						found = child.AnimationId
						return
					end
					if child:IsA("KeyframeSequence") then
						found = "rbxassetid://" .. id_str
						return
					end
					findAnim(child, depth + 1)
				end
			end
			findAnim(model, 0)
			pcall(function() model:Destroy() end)
			if found then return found end
		end

		-- Method 3: MarketplaceService
		local ok3, info = pcall(function()
			return MarketplaceService:GetProductInfo(tonumber(id_str))
		end)
		if ok3 and info then
			local animTypes = {[24] = true, [61] = true}
			if animTypes[info.AssetTypeId] then
				return "rbxassetid://" .. id_str
			end
		end

		return "rbxassetid://" .. id_str
	end

	local HttpService = (cloneref and cloneref(game:GetService("HttpService"))) or game:GetService("HttpService")

	local popular_emotes = {
		["Beat Da Koto Nai"] = "rbxassetid://122639636262924",
		["Chinese Dance: Da Koto Nai"] = "rbxassetid://131564504226925",
		["Mega Poop Aura"] = "rbxassetid://120062749676884",
		["Hype Dance"] = "rbxassetid://81108310619663",
		["Hype Dance 2"] = "rbxassetid://100241629262397",
		["Illusionary Daytime"] = "rbxassetid://108423029518590",
		["Brazilian Dance Viral Trend"] = "rbxassetid://138980897636026",
		["Jamal's Passinho"] = "rbxassetid://135877894695218",
		["TYLA - CHANEL"] = "rbxassetid://119696276842469",
		["OG Tylil Dance"] = "rbxassetid://130884257276358",
		["Bye Bye Jawline Mog"] = "rbxassetid://101417495109275",
		["NSYNC - Bye Bye Bye"] = "rbxassetid://112539507729065",
		["Griddy Meme Dance"] = "rbxassetid://114931199677542",
		["Sturdy Meme Dance"] = "rbxassetid://78110949113284",
		["Caramelldansen Dance"] = "rbxassetid://131412443156874",
		["Toothless Meme Dance"] = "rbxassetid://71355156510509",
		["Hatsune Miku Popipo"] = "rbxassetid://96838064213668",
		["New Jeans - Hype Boy"] = "rbxassetid://108649417466825",
		["Shikanoko Nokonoko Meme"] = "rbxassetid://114211239095414",
		["Headless Aura Emote"] = "rbxassetid://129642587443672",
		["Flying Floating Aura"] = "rbxassetid://91757204092310",
		["Kawaii Bouncy Anime Girl"] = "rbxassetid://77949063578180",
	}

	local popular_emotes_list = {
		"Beat Da Koto Nai",
		"Chinese Dance: Da Koto Nai",
		"Mega Poop Aura",
		"Hype Dance",
		"Hype Dance 2",
		"Illusionary Daytime",
		"Brazilian Dance Viral Trend",
		"Jamal's Passinho",
		"TYLA - CHANEL",
		"OG Tylil Dance",
		"Bye Bye Jawline Mog",
		"NSYNC - Bye Bye Bye",
		"Griddy Meme Dance",
		"Sturdy Meme Dance",
		"Caramelldansen Dance",
		"Toothless Meme Dance",
		"Hatsune Miku Popipo",
		"New Jeans - Hype Boy",
		"Shikanoko Nokonoko Meme",
		"Headless Aura Emote",
		"Flying Floating Aura",
		"Kawaii Bouncy Anime Girl",
	}

	-- Persistent Custom Emotes System
	local CUSTOM_EMOTE_FILE = "neverlose_custom_emotes.json"
	local custom_emotes_dict = {}

	local function save_custom_emotes_to_file()
		pcall(function()
			if not writefile then return end
			local enc = HttpService:JSONEncode(custom_emotes_dict)
			writefile(CUSTOM_EMOTE_FILE, enc)
		end)
	end

	local function load_custom_emotes_from_file()
		pcall(function()
			if not (isfile and isfile(CUSTOM_EMOTE_FILE) and readfile) then return end
			local raw = readfile(CUSTOM_EMOTE_FILE)
			if not raw or raw == "" then return end
			local data = HttpService:JSONDecode(raw)
			if type(data) == "table" then
				for name, id in pairs(data) do
					if type(name) == "string" and type(id) == "string" and name ~= "" and id ~= "" then
						custom_emotes_dict[name] = id
						popular_emotes[name] = id
						if not table.find(popular_emotes_list, name) then
							table.insert(popular_emotes_list, name)
						end
					end
				end
			end
		end)
	end
	load_custom_emotes_from_file()

	local active_anim_tracks = {}
	local current_anim_id = popular_emotes["Beat Da Koto Nai"]
	local current_anim_instance = nil
	local current_track_instance = nil

	local function stop_character_animation()
		for _, tr in ipairs(active_anim_tracks) do
			pcall(function() tr:Stop(0) end)
		end
		table.clear(active_anim_tracks)
		if current_track_instance then
			pcall(function() current_track_instance:Stop(0) end)
			current_track_instance = nil
		end
		if current_anim_instance then
			pcall(function() current_anim_instance:Destroy() end)
			current_anim_instance = nil
		end
	end

	local function play_character_animation(anim_id)
		stop_character_animation()
		if not anim_id or anim_id == "" then return end
		local char = LocalPlayer.Character
		if not char then return end
		local humanoid = char:FindFirstChild("Humanoid")
		if not humanoid then return end

		pcall(function()
			current_anim_instance = Instance.new("Animation")
			current_anim_instance.AnimationId = anim_id
			current_track_instance = humanoid:LoadAnimation(current_anim_instance)
			current_track_instance.Looped = true
			local cur_spd = (flags["misc_anim_speed"] or 100) / 100
			current_track_instance:AdjustSpeed(cur_spd)
			table.insert(active_anim_tracks, current_track_instance)
			current_track_instance:Play()
		end)
	end

	LocalPlayer.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid", 10)
		if flags["misc_emote"] and current_anim_id then
			task.wait(0.5)
			play_character_animation(current_anim_id)
		end
	end)

	movement:toggle({
		name = "Emote",
		flag = "misc_emote",
		default = false,
		callback = function(val)
			if val then
				play_character_animation(current_anim_id)
			else
				stop_character_animation()
			end
		end
	}):keybind({
		flag = "misc_emote_bind",
		default = Enum.KeyCode.V,
		mode = "hold"
	})

	local emote_dropdown
	emote_dropdown = movement:dropdown({
		name = "Emote Presets",
		flag = "misc_emote_list",
		items = popular_emotes_list,
		multi = false,
		default = "Beat Da Koto Nai",
		callback = function(val)
			if type(val) == "table" then val = val[1] end
			if val and popular_emotes[val] then
				current_anim_id = popular_emotes[val]
				if flags["misc_emote"] then
					play_character_animation(current_anim_id)
				end
			end
		end
	})

	-- Add Custom Animation to Dropdown with Persistent Save
	movement:textbox({
		flag = "misc_custom_emote_name",
		placeholder = "Custom Emote Name (e.g. My Dance)",
		default = "",
	})

	movement:textbox({
		flag = "misc_catalog_id_input",
		placeholder = "Enter Catalog ID or Asset ID (e.g. 120062749676884)",
		default = "120062749676884",
	})

	local last_resolved_asset_id = "rbxassetid://15609995579"
	local copy_id_display_btn = nil

	local function update_copy_display(new_id)
		last_resolved_asset_id = new_id
		pcall(function()
			if copy_id_display_btn and copy_id_display_btn.element_frame then
				local tb = copy_id_display_btn.element_frame:FindFirstChildWhichIsA("TextButton")
				if tb then
					tb.Text = new_id
				end
			end
		end)
	end

	movement:button({
		name = "Add Animation To Dropdown",
		callback = function()
			local input = flags["misc_catalog_id_input"] or "120062749676884"
			local id_num = tostring(input):match("%d+")
			if not id_num then
				library:notification({ text = "⚠ Please enter a valid ID!", time = 3 })
				return
			end

			local name_input = flags["misc_custom_emote_name"]
			local emote_name
			if name_input and name_input:gsub("%s+", "") ~= "" then
				emote_name = name_input:match("^%s*(.-)%s*$")
			else
				-- Auto-fetch the real emote name from MarketplaceService
				local fetchOk, fetchInfo = pcall(function()
					return MarketplaceService:GetProductInfo(tonumber(id_num))
				end)
				if fetchOk and fetchInfo and fetchInfo.Name and fetchInfo.Name ~= "" then
					emote_name = fetchInfo.Name:match("^%s*(.-)%s*$")
				else
					emote_name = "Emote " .. id_num
				end
			end

			local asset_id = get_rbx_asset_id(id_num)
			if not asset_id or asset_id == "" then
				asset_id = "rbxassetid://" .. id_num
			end

			popular_emotes[emote_name] = asset_id
			custom_emotes_dict[emote_name] = asset_id
			if not table.find(popular_emotes_list, emote_name) then
				table.insert(popular_emotes_list, emote_name)
			end

			save_custom_emotes_to_file()

			if emote_dropdown and emote_dropdown.refresh_options then
				emote_dropdown:refresh_options(popular_emotes_list)
				emote_dropdown.set(emote_name)
			end

			current_anim_id = asset_id
			update_copy_display(asset_id)

			if flags["misc_emote"] then
				play_character_animation(current_anim_id)
			end

			library:notification({ text = "✅ Added & Saved: " .. emote_name, time = 3 })
		end
	})

	movement:button({
		name = "Delete Custom Emote",
		callback = function()
			local selected = flags["misc_emote_list"]
			if type(selected) == "table" then selected = selected[1] end
			if selected and custom_emotes_dict[selected] then
				custom_emotes_dict[selected] = nil
				popular_emotes[selected] = nil
				local idx = table.find(popular_emotes_list, selected)
				if idx then
					table.remove(popular_emotes_list, idx)
				end
				save_custom_emotes_to_file()
				if emote_dropdown and emote_dropdown.refresh_options then
					emote_dropdown:refresh_options(popular_emotes_list)
					emote_dropdown.set(popular_emotes_list[1] or "")
				end
				library:notification({ text = "🗑 Deleted: " .. selected, time = 2.5 })
			else
				library:notification({ text = "⚠ Cannot delete built-in emote!", time = 2.5 })
			end
		end
	})

	movement:button({
		name = "Get & Copy RbxAssetId",
		callback = function()
			local input = flags["misc_catalog_id_input"] or "120062749676884"
			local id_num = tostring(input):match("%d+")
			if not id_num then
				library:notification({ text = "⚠ Please enter a valid ID!", time = 3 })
				return
			end
			local asset_id = get_rbx_asset_id(id_num)
			copy_to_clipboard(asset_id)
			current_anim_id = asset_id
			update_copy_display(asset_id)
			library:notification({ text = "📋 Auto-Copied: " .. asset_id, time = 3.5 })
			if flags["misc_emote"] then
				play_character_animation(current_anim_id)
			end
		end
	})

	copy_id_display_btn = movement:button({
		name = last_resolved_asset_id,
		callback = function()
			if last_resolved_asset_id and last_resolved_asset_id ~= "" then
				copy_to_clipboard(last_resolved_asset_id)
				library:notification({ text = "📋 Copied: " .. last_resolved_asset_id, time = 2.5 })
			end
		end
	})

	-- Animation Speed & Animation Lag Engine (Adapted from Neverlose V3 with increased limits)
	local anim_lag_data = {}
	local anim_last_freeze_tick = os.clock()
	local anim_last_update = os.clock()
	local anim_last_freeze = os.clock()
	local anim_freeze = false
	local anim_conn = nil

	local function update_anim_modifiers()
		local speed_pct = flags["misc_anim_speed"] or 100
		local cur_speed = speed_pct / 100
		local lag_pct = flags["misc_anim_lag"] or 0
		local lag_amount = lag_pct > 0 and (lag_pct / 150) or nil

		local is_active = (cur_speed ~= 1) or (lag_amount ~= nil)

		if is_active and not anim_conn then
			anim_last_freeze_tick = os.clock()
			anim_last_update = os.clock()
			anim_last_freeze = os.clock()
			anim_freeze = false
			table.clear(anim_lag_data)

			anim_conn = RunService.Heartbeat:Connect(function()
				local char = LocalPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if not hum then return end

				local spd = (flags["misc_anim_speed"] or 100) / 100
				local lag = flags["misc_anim_lag"] or 0
				local lag_amt = lag > 0 and (lag / 150) or nil

				local now = os.clock()
				if now - anim_last_update > 0.025 then
					anim_last_update = now
					local tracks = hum:GetPlayingAnimationTracks()

					if lag_amt then
						if now - anim_last_freeze_tick > lag_amt then
							anim_last_freeze_tick = now
							task.defer(function()
								anim_last_freeze = os.clock()
							end)
							anim_freeze = false
						else
							anim_freeze = true
						end

						for i = 1, #tracks do
							local track = tracks[i]
							pcall(function()
								if not anim_freeze then
									anim_lag_data[track] = track.TimePosition + (now - anim_last_freeze) * spd
								else
									track.TimePosition = anim_lag_data[track] or 0
								end
							end)
						end
					end

					for i = 1, #tracks do
						local track = tracks[i]
						pcall(function()
							if track.Speed ~= spd then
								track:AdjustSpeed(spd)
							end
						end)
					end
				end
			end)
			table.insert(_nvl_conns, anim_conn)
		elseif not is_active and anim_conn then
			anim_conn:Disconnect()
			anim_conn = nil
			pcall(function()
				local char = LocalPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then
					for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
						track:AdjustSpeed(1)
					end
				end
			end)
		else
			pcall(function()
				local char = LocalPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then
					for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
						track:AdjustSpeed(cur_speed)
					end
				end
			end)
		end
	end

	movement:slider({
		name = "Animation speed",
		flag = "misc_anim_speed",
		min = 0,
		max = 1000,
		default = 100,
		suffix = "%",
		interval = 1,
		callback = function(val)
			update_anim_modifiers()
		end
	})

	movement:slider({
		name = "Animation lag",
		flag = "misc_anim_lag",
		min = 0,
		max = 250,
		default = 0,
		suffix = "%",
		min_text = "Off",
		interval = 1,
		callback = function(val)
			update_anim_modifiers()
		end
	})

	-- Unlock Animation Pack
	local anim_pack_char_conn = nil
	local function unlock_anim_packs()
		local pgui = LocalPlayer:FindFirstChild("PlayerGui")
		if not pgui then return end
		local main_gui = pgui:WaitForChild("MainScreenGui", 5)
		if not main_gui then return end
		local pack = main_gui:WaitForChild("AnimationPack", 5)
		local plus_pack = main_gui:WaitForChild("AnimationPlusPack", 5)
		if pack and plus_pack then
			pack.Visible = true
			plus_pack.Visible = true
		end
	end

	movement:toggle({
		name = "Unlock Animation Packs",
		flag = "misc_unlock_anim_pack",
		default = false,
		callback = function(val)
			if val then
				unlock_anim_packs()
				if anim_pack_char_conn then anim_pack_char_conn:Disconnect() end
				anim_pack_char_conn = LocalPlayer.CharacterAdded:Connect(function()
					task.wait(1)
					if flags["misc_unlock_anim_pack"] then unlock_anim_packs() end
				end)
				library:notification({ text = "🔓 Animation Packs Unlocked!", time = 3 })
			else
				if anim_pack_char_conn then anim_pack_char_conn:Disconnect(); anim_pack_char_conn = nil end
			end
		end
	})

	-- Dedicated High-Performance Auto Click Section in Mics Tab
	local autoclick_sec = mics:section({ name = "Auto Click", side = "left" })

	local is_lmb_down = false

	local function is_cursor_over_protected_ui()
		if UserInputService:GetFocusedTextBox() then
			return true
		end
		if GuiService.MenuIsOpen then
			return true
		end
		local mouse_pos = UserInputService:GetMouseLocation()
		local lp = LocalPlayer
		local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
		if pg then
			local objs = pg:GetGuiObjectsAtPosition(mouse_pos.X, mouse_pos.Y)
			for _, obj in ipairs(objs) do
				if obj.Visible and (obj:IsA("GuiButton") or obj:IsA("TextBox") or obj.Active) then
					return true
				end
			end
		end
		pcall(function()
			local cg = game:GetService("CoreGui")
			local objs = cg:GetGuiObjectsAtPosition(mouse_pos.X, mouse_pos.Y)
			for _, obj in ipairs(objs) do
				if obj.Visible and (obj:IsA("GuiButton") or obj:IsA("TextBox") or obj.Active) then
					return true
				end
			end
		end)
		return false
	end

	local function perform_autoclick_action()
		local method = flags["misc_autoclick_method"] or "Tool Activate"
		if type(method) == "table" then method = method[1] end
		local ignore_ui = flags["misc_autoclick_ignore_ui"] ~= false

		local over_ui = ignore_ui and is_cursor_over_protected_ui()

		-- Method 1: Tool Activate (Native tool activation, zero mouse simulation, 100% immune to UI/chat clicks)
		local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
		if (method == "Tool Activate" or method == "Combined") and tool then
			pcall(function()
				tool:Activate()
			end)
		end

		-- Method 2: Smart Mouse Click (For gun frameworks that listen directly to mouse input, silenced when hovering UI)
		if (method == "Smart Click" or method == "Combined") and not over_ui then
			pcall(function()
				if mouse1click then
					mouse1click()
				elseif mouse1press and mouse1release then
					mouse1press()
					mouse1release()
				elseif VirtualUser and VirtualUser.ClickButton1 then
					VirtualUser:ClickButton1(Vector2.zero)
				end
			end)
		end
	end

	table.insert(_nvl_conns, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not gameProcessed then
				is_lmb_down = true
			end
		end
	end))

	table.insert(_nvl_conns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			is_lmb_down = false
		end
	end))

	task.spawn(function()
		while true do
			if flags["misc_autoclick"] then
				local mode = flags["misc_autoclick_mode"] or "Hold LMB"
				if type(mode) == "table" then mode = mode[1] end
				local should_click = false

				if mode == "Hold LMB" then
					should_click = is_lmb_down and not is_cursor_over_protected_ui()
				else
					should_click = not is_cursor_over_protected_ui()
				end

				if should_click then
					perform_autoclick_action()
				end

				local cps = flags["misc_autoclick_cps"] or 25
				local delay = 1 / math.clamp(cps, 1, 100)
				task.wait(delay)
			else
				task.wait(0.1)
			end
		end
	end)

	autoclick_sec:toggle({
		name = "Auto click",
		flag = "misc_autoclick",
		default = false
	}):keybind({
		flag = "misc_autoclick_bind"
	})

	autoclick_sec:dropdown({
		name = "Click mode",
		flag = "misc_autoclick_mode",
		items = { "Hold LMB", "Always Active" },
		multi = false,
		default = "Hold LMB"
	})

	autoclick_sec:dropdown({
		name = "Method",
		flag = "misc_autoclick_method",
		items = { "Tool Activate", "Smart Click", "Combined" },
		multi = false,
		default = "Tool Activate"
	})

	autoclick_sec:slider({
		name = "Click Speed (CPS)",
		flag = "misc_autoclick_cps",
		min = 5,
		max = 60,
		default = 25,
		suffix = " CPS"
	})

	autoclick_sec:toggle({
		name = "Smart UI bypass",
		flag = "misc_autoclick_ignore_ui",
		default = true
	})

	-- Hitsound & Misc Other Section
	local hitsounds = {
		["Rust Headshot"] = "rbxassetid://138750331387064",
		["Neverlose"] = "rbxassetid://110168723447153",
		["Bubble"] = "rbxassetid://6534947588",
		["Laser"] = "rbxassetid://7837461331",
		["Steve"] = "rbxassetid://4965083997",
		["Call of Duty"] = "rbxassetid://5952120301",
		["Bat"] = "rbxassetid://3333907347",
		["TF2 Critical"] = "rbxassetid://296102734",
		["Saber"] = "rbxassetid://8415678813",
		["Bameware"] = "rbxassetid://3124331820",
		["Money"] = "rbxassetid://13956013041",
		["Notif"] = "rbxassetid://6696469190",
		["Shutter"] = "rbxassetid://10066921516",
		["RIFK7"] = "rbxassetid://9102080552",
		["LazerBeam"] = "rbxassetid://130791043",
		["WindowsXPError"] = "rbxassetid://160715357",
		["TF2Hitsound"] = "rbxassetid://3455144981",
		["TF2Bat"] = "rbxassetid://3333907347",
		["BowHit"] = "rbxassetid://1053296915",
		["Bow"] = "rbxassetid://3442683707",
		["OSU"] = "rbxassetid://7147454322",
		["OneNN"] = "rbxassetid://7349055654",
		["Rust"] = "rbxassetid://6565371338",
		["TF2Pan"] = "rbxassetid://3431749479",
		["Mario"] = "rbxassetid://5709456554",
		["Bell"] = "rbxassetid://6534947240",
		["Pick"] = "rbxassetid://1347140027",
		["Pop"] = "rbxassetid://198598793",
		["Sans"] = "rbxassetid://3188795283",
		["Fart"] = "rbxassetid://130833677",
		["Big"] = "rbxassetid://5332005053",
		["Vine"] = "rbxassetid://5332680810",
		["Bruh"] = "rbxassetid://4578740568",
		["Skeet"] = "rbxassetid://5633695679",
		["Fatality"] = "rbxassetid://6534947869",
		["Bonk"] = "rbxassetid://5766898159",
		["Minecraft"] = "rbxassetid://5869422451",
		["Gamesense"] = "rbxassetid://4817809188",
		["Bamboo"] = "rbxassetid://3769434519",
		["Crowbar"] = "rbxassetid://546410481",
		["Weeb"] = "rbxassetid://6442965016",
		["Beep"] = "rbxassetid://8177256015",
		["Bambi"] = "rbxassetid://8437203821",
		["Stone"] = "rbxassetid://3581383408",
		["Old Fatality"] = "rbxassetid://6607142036",
		["Click"] = "rbxassetid://8053704437",
		["Ding"] = "rbxassetid://7149516994",
		["Snow"] = "rbxassetid://6455527632",
		["Osu"] = "rbxassetid://7149255551",
		["TF2"] = "rbxassetid://2868331684",
		["Slime"] = "rbxassetid://6916371803",
		["Among Us"] = "rbxassetid://5700183626",
		["One"] = "rbxassetid://7380502345",
		["BulletDeflect"] = "rbxassetid://1657157666",
		["Default"] = "rbxassetid://330595293",
		["UwU"] = "rbxassetid://8679659744",
		["Cod"] = "rbxassetid://160432334",
		["Blood SFX"] = "rbxassetid://8164951181",
		["Blood Burst"] = "rbxassetid://3781479909",
		["Blood Hit"] = "rbxassetid://429400881",
	}

	local hitsound_list = {}
	for name, _ in pairs(hitsounds) do
		table.insert(hitsound_list, name)
	end
	table.sort(hitsound_list)

	local SoundService = game:GetService("SoundService")
	local function play_hitsound()
		local name = flags["misc_hitsound_voice"] or "Default"
		if type(name) == "table" then name = name[1] end
		local sound_id = hitsounds[name] or "rbxassetid://330595293"

		local sound = Instance.new("Sound")
		sound.SoundId = sound_id
		sound.Volume = ((flags["misc_hitsound_volume"] or 100) / 100)
		sound.Parent = SoundService
		sound:Play()
		task.delay(2, function()
			sound:Destroy()
		end)
	end

	-- Hit Listener on enemies
	local tracked_healths = {}
	local function track_player(plr)
		if plr == LocalPlayer then return end
		local function on_char(char)
			local humanoid = char:WaitForChild("Humanoid", 5)
			if humanoid then
				tracked_healths[plr] = humanoid.Health
				humanoid.HealthChanged:Connect(function(new_hp)
					local old_hp = tracked_healths[plr] or new_hp
					if new_hp < old_hp and flags["misc_hitsound_enabled"] then
						play_hitsound()
					end
					tracked_healths[plr] = new_hp
				end)
			end
		end
		if plr.Character then task.spawn(on_char, plr.Character) end
		plr.CharacterAdded:Connect(on_char)
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		track_player(plr)
	end
	Players.PlayerAdded:Connect(track_player)

	-- Right Side: Spam Hotkey
	local spam_sec = mics:section({ name = "Spam Hotkey", side = "right" })

	spam_sec:toggle({
		name = "Spam hotkey",
		flag = "misc_spam_hotkey",
		default = false
	})

	spam_sec:slider({
		name = "Spam Delay",
		flag = "misc_spam_delay",
		min = 10,
		max = 1000,
		default = 100,
		float = 1,
		unit = "ms"
	})

	-- Dynamic Custom Hotkeys Manager UI
	local active_hotkeys = {}

	local header_frame = library:create("Frame", {
		Parent = spam_sec.holder,
		Name = "HotkeyHeader",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -26, 0, 20),
	})

	local header_label = library:create("TextLabel", {
		Parent = header_frame,
		Name = "HeaderTitle",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "Hotkeys List",
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -26, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 12,
	})

	local add_btn = library:create("TextButton", {
		Parent = header_frame,
		Name = "AddButton",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(135, 145, 255),
		BorderColor3 = Color3.fromRGB(56, 56, 70),
		Text = "+",
		TextStrokeTransparency = 0.5,
		Position = UDim2.new(1, -20, 0, 1),
		Size = UDim2.new(0, 20, 0, 18),
		TextSize = 13,
		BackgroundColor3 = Color3.fromRGB(34, 34, 42),
	})

	add_btn.MouseEnter:Connect(function()
		add_btn.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
		add_btn.TextColor3 = Color3.fromRGB(180, 190, 255)
	end)

	add_btn.MouseLeave:Connect(function()
		add_btn.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
		add_btn.TextColor3 = Color3.fromRGB(135, 145, 255)
	end)

	local list_container = library:create("Frame", {
		Parent = spam_sec.holder,
		Name = "HotkeyListContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -26, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})

	local list_layout = library:create("UIListLayout", {
		Parent = list_container,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 4),
	})

	local function add_hotkey_entry(default_key, animate)
		local entry_data = { key = default_key or "", enabled = true }
		table.insert(active_hotkeys, entry_data)

		local row = Instance.new("CanvasGroup")
		row.Name = "HotkeyRow"
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.Size = animate and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 0, 22)
		row.GroupTransparency = animate and 1 or 0
		row.Parent = list_container

		-- TextBox Container (Width adjusted to make room for Tick, X, Trash buttons)
		local tb_inline = library:create("Frame", {
			Parent = row,
			Name = "InputInline",
			Position = UDim2.new(0, 0, 0, 0),
			BorderColor3 = Color3.fromRGB(19, 19, 19),
			Size = UDim2.new(1, -70, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(8, 8, 8),
		})

		local tb = library:create("TextBox", {
			Parent = tb_inline,
			Name = "InputKey",
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(220, 220, 220),
			BorderColor3 = Color3.fromRGB(50, 50, 56),
			Text = default_key or "",
			TextStrokeTransparency = 0.5,
			Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			ClearTextOnFocus = false,
			PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
			CursorPosition = -1,
			PlaceholderText = "Key (e.g. E)",
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(26, 26, 30),
		})

		tb:GetPropertyChangedSignal("Text"):Connect(function()
			local val = tb.Text:gsub("%s+", ""):upper()
			if #val > 10 then val = val:sub(1, 10) end
			if tb.Text ~= val then tb.Text = val end
			entry_data.key = val
		end)

		-- 1. Tick Button Container (Green Checkmark when active)
		local tick_inline = library:create("Frame", {
			Parent = row,
			Name = "TickInline",
			Position = UDim2.new(1, -66, 0, 0),
			BorderColor3 = Color3.fromRGB(19, 19, 19),
			Size = UDim2.new(0, 20, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(8, 8, 8),
		})

		local tick_btn = library:create("TextButton", {
			Parent = tick_inline,
			Name = "TickBtn",
			Text = "",
			Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = Color3.fromRGB(20, 48, 25),
			BorderColor3 = Color3.fromRGB(35, 100, 48),
		})

		local tick_icon = library:create("ImageLabel", {
			Parent = tick_btn,
			Name = "TickIcon",
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 11, 0, 11),
			Image = "rbxassetid://10709790644",
			ImageColor3 = Color3.fromRGB(80, 230, 110),
		})

		-- 2. X Button Container (Red Cross when inactive)
		local x_inline = library:create("Frame", {
			Parent = row,
			Name = "XInline",
			Position = UDim2.new(1, -43, 0, 0),
			BorderColor3 = Color3.fromRGB(19, 19, 19),
			Size = UDim2.new(0, 20, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(8, 8, 8),
		})

		local x_btn = library:create("TextButton", {
			Parent = x_inline,
			Name = "XBtn",
			Text = "",
			Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = Color3.fromRGB(26, 26, 30),
			BorderColor3 = Color3.fromRGB(45, 45, 52),
		})

		local x_icon = library:create("ImageLabel", {
			Parent = x_btn,
			Name = "XIcon",
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 11, 0, 11),
			Image = "rbxassetid://10747384394",
			ImageColor3 = Color3.fromRGB(100, 100, 110),
		})

		-- 3. Delete / Red Trash Container
		local del_inline = library:create("Frame", {
			Parent = row,
			Name = "DeleteInline",
			Position = UDim2.new(1, -20, 0, 0),
			BorderColor3 = Color3.fromRGB(19, 19, 19),
			Size = UDim2.new(0, 20, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(8, 8, 8),
		})

		local del_btn = library:create("TextButton", {
			Parent = del_inline,
			Name = "DeleteBtn",
			Text = "",
			Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = Color3.fromRGB(45, 18, 18),
			BorderColor3 = Color3.fromRGB(90, 30, 30),
		})

		local trash_icon = library:create("ImageLabel", {
			Parent = del_btn,
			Name = "TrashIcon",
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 12, 0, 12),
			Image = "rbxassetid://10747362241",
			ImageColor3 = Color3.fromRGB(255, 75, 75),
		})

		local function update_state_visual()
			if entry_data.enabled then
				tick_btn.BackgroundColor3 = Color3.fromRGB(20, 48, 25)
				tick_btn.BorderColor3 = Color3.fromRGB(35, 100, 48)
				tick_icon.ImageColor3 = Color3.fromRGB(80, 230, 110)

				x_btn.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
				x_btn.BorderColor3 = Color3.fromRGB(45, 45, 52)
				x_icon.ImageColor3 = Color3.fromRGB(100, 100, 110)
			else
				tick_btn.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
				tick_btn.BorderColor3 = Color3.fromRGB(45, 45, 52)
				tick_icon.ImageColor3 = Color3.fromRGB(100, 100, 110)

				x_btn.BackgroundColor3 = Color3.fromRGB(48, 20, 20)
				x_btn.BorderColor3 = Color3.fromRGB(105, 35, 35)
				x_icon.ImageColor3 = Color3.fromRGB(255, 80, 80)
			end
		end

		tick_btn.MouseButton1Click:Connect(function()
			entry_data.enabled = true
			update_state_visual()
		end)

		x_btn.MouseButton1Click:Connect(function()
			entry_data.enabled = false
			update_state_visual()
		end)

		tick_btn.MouseEnter:Connect(function()
			if entry_data.enabled then
				tick_btn.BackgroundColor3 = Color3.fromRGB(28, 68, 35)
				tick_btn.BorderColor3 = Color3.fromRGB(50, 140, 68)
				tick_icon.ImageColor3 = Color3.fromRGB(110, 255, 140)
			else
				tick_btn.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
				tick_btn.BorderColor3 = Color3.fromRGB(60, 60, 70)
				tick_icon.ImageColor3 = Color3.fromRGB(150, 150, 160)
			end
		end)
		tick_btn.MouseLeave:Connect(update_state_visual)

		x_btn.MouseEnter:Connect(function()
			if not entry_data.enabled then
				x_btn.BackgroundColor3 = Color3.fromRGB(72, 25, 25)
				x_btn.BorderColor3 = Color3.fromRGB(140, 45, 45)
				x_icon.ImageColor3 = Color3.fromRGB(255, 120, 120)
			else
				x_btn.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
				x_btn.BorderColor3 = Color3.fromRGB(60, 60, 70)
				x_icon.ImageColor3 = Color3.fromRGB(150, 150, 160)
			end
		end)
		x_btn.MouseLeave:Connect(update_state_visual)

		del_btn.MouseEnter:Connect(function()
			del_btn.BackgroundColor3 = Color3.fromRGB(75, 25, 25)
			del_btn.BorderColor3 = Color3.fromRGB(140, 45, 45)
			trash_icon.ImageColor3 = Color3.fromRGB(255, 110, 110)
		end)

		del_btn.MouseLeave:Connect(function()
			del_btn.BackgroundColor3 = Color3.fromRGB(45, 18, 18)
			del_btn.BorderColor3 = Color3.fromRGB(90, 30, 30)
			trash_icon.ImageColor3 = Color3.fromRGB(255, 75, 75)
		end)

		local is_deleting = false
		del_btn.MouseButton1Click:Connect(function()
			if is_deleting then return end
			is_deleting = true

			for idx, itm in ipairs(active_hotkeys) do
				if itm == entry_data then
					table.remove(active_hotkeys, idx)
					break
				end
			end

			local fadeOut = TweenService:Create(row, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(1, 0, 0, 0),
				GroupTransparency = 1,
			})
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				row:Destroy()
			end)
		end)

		if animate then
			local fadeIn = TweenService:Create(row, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, 22),
				GroupTransparency = 0,
			})
			fadeIn:Play()
		end
	end

	add_btn.MouseButton1Click:Connect(function()
		add_hotkey_entry("", true)
	end)

	-- Default entries matching skills in game (E, R, Q)
	add_hotkey_entry("E", false)
	add_hotkey_entry("R", false)
	add_hotkey_entry("Q", false)

	-- KeyCode Parser
	local hotkey_aliases = {
		["0"] = Enum.KeyCode.Zero, ["1"] = Enum.KeyCode.One, ["2"] = Enum.KeyCode.Two,
		["3"] = Enum.KeyCode.Three, ["4"] = Enum.KeyCode.Four, ["5"] = Enum.KeyCode.Five,
		["6"] = Enum.KeyCode.Six, ["7"] = Enum.KeyCode.Seven, ["8"] = Enum.KeyCode.Eight,
		["9"] = Enum.KeyCode.Nine, ["SPACE"] = Enum.KeyCode.Space, ["SPC"] = Enum.KeyCode.Space,
		["SHIFT"] = Enum.KeyCode.LeftShift, ["LSHIFT"] = Enum.KeyCode.LeftShift, ["RSHIFT"] = Enum.KeyCode.RightShift,
		["CTRL"] = Enum.KeyCode.LeftControl, ["LCTRL"] = Enum.KeyCode.LeftControl, ["RCTRL"] = Enum.KeyCode.RightControl,
		["ALT"] = Enum.KeyCode.LeftAlt, ["LALT"] = Enum.KeyCode.LeftAlt, ["RALT"] = Enum.KeyCode.RightAlt,
		["TAB"] = Enum.KeyCode.Tab, ["ENTER"] = Enum.KeyCode.Return, ["RETURN"] = Enum.KeyCode.Return,
	}

	local function parse_hotkey(str)
		if not str or str == "" then return nil end
		str = str:gsub("%s+", ""):upper()
		if hotkey_aliases[str] then return hotkey_aliases[str] end
		local ok, kc = pcall(function() return Enum.KeyCode[str] end)
		if ok and kc then return kc end
		return nil
	end

	-- Spammer Background Loop
	local spam_running = true
	table.insert(_nvl_conns, {
		Disconnect = function()
			spam_running = false
			getgenv()._nvl_suppress_keybind = false
		end
	})

	local vim = (cloneref and cloneref(game:GetService("VirtualInputManager"))) or game:GetService("VirtualInputManager")

	task.spawn(function()
		while spam_running do
			task.wait(0.01)
			if flags["misc_spam_hotkey"] then
				local delay_ms = flags["misc_spam_delay"] or 100
				local delay_sec = math.max((delay_ms / 1000), 0.01)

				local focused_tb = UserInputService:GetFocusedTextBox()
				local menu_open = GuiService.MenuIsOpen
				local char = LocalPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local alive = hum and hum.Health > 0 and not local_knocked

				if not focused_tb and not menu_open and alive then
					for _, item in ipairs(active_hotkeys) do
						if not flags["misc_spam_hotkey"] or not spam_running then break end
						if item.enabled == false then continue end
						local kc = parse_hotkey(item.key)
						if kc then
							getgenv()._nvl_suppress_keybind = true
							pcall(function()
								if vim then
									vim:SendKeyEvent(true, kc, false, game)
									task.wait(0.01)
									vim:SendKeyEvent(false, kc, false, game)
								elseif keypress and keyrelease then
									keypress(kc.Value)
									task.wait(0.01)
									keyrelease(kc.Value)
								end
							end)
							getgenv()._nvl_suppress_keybind = false
						end
						task.wait(delay_sec)
					end
				else
					task.wait(0.1)
				end
			else
				task.wait(0.1)
			end
		end
	end)

	-- =========================================================================
	-- TAB MICS: CUSTOM CHARACTER SECTION (FAITHFUL NEVERLOSE V3 ENGINE)
	-- =========================================================================
	local custom_char_sec = mics:section({ name = "Custom character", side = "right" })

	local get_obj = getobjects or (game and function(url) return game:GetObjects(url) end)
	local asset_cache = {}
	local desc_cache = {}
	local apply_token = 0
	local active_custom_desc = nil
	local last_selected_preset_id = "2909212097"

	local function cached_get_obj(assetId)
		if not assetId or assetId == 0 then return nil end
		local key = tostring(assetId)
		if asset_cache[key] then
			local cloned = {}
			for _, item in ipairs(asset_cache[key]) do
				table.insert(cloned, item:Clone())
			end
			return cloned
		end
		local ok, res = pcall(function() return get_obj("rbxassetid://" .. key) end)
		if ok and res and #res > 0 then
			local proto = {}
			for _, item in ipairs(res) do
				table.insert(proto, item:Clone())
			end
			asset_cache[key] = proto
			return res
		end
		return nil
	end

	local function safe_destroy_item(item)
		if not item then return end
		pcall(function()
			item.Parent = nil
			item:Destroy()
		end)
	end

	local default_avatar_state = {
		captured = false,
		head_mesh_id = "rbxasset://avatar/heads/head.mesh",
		head_texture_id = "",
		face_texture = "rbxasset://textures/face.png",
		animations = {
			idle = {
				{ name = "Animation1", id = "http://www.roblox.com/asset/?id=507766388" },
				{ name = "Animation2", id = "http://www.roblox.com/asset/?id=507766666" }
			},
			walk = {
				{ name = "WalkAnim", id = "http://www.roblox.com/asset/?id=913402848" }
			},
			run = {
				{ name = "RunAnim", id = "http://www.roblox.com/asset/?id=913376220" }
			},
			jump = {
				{ name = "JumpAnim", id = "http://www.roblox.com/asset/?id=507765000" }
			},
			fall = {
				{ name = "FallAnim", id = "http://www.roblox.com/asset/?id=507767968" }
			},
			climb = {
				{ name = "ClimbAnim", id = "http://www.roblox.com/asset/?id=507765644" }
			},
			swim = {
				{ name = "Swim", id = "http://www.roblox.com/asset/?id=913384386" }
			},
		}
	}

	local function snapshot_default_avatar(char)
		if not char then return end
		local head = char:FindFirstChild("Head")
		local animate = char:FindFirstChild("Animate")
		if head and not default_avatar_state.captured then
			if head:IsA("MeshPart") then
				if not head.TextureID:find("111092388") and not head.MeshId:find("123480233") and head.MeshId ~= "" then
					default_avatar_state.head_mesh_id = head.MeshId
					default_avatar_state.head_texture_id = head.TextureID
				end
			end
			local f = head:FindFirstChild("face") or head:FindFirstChild("Face")
			if f and f:IsA("Decal") and f.Texture ~= "" and not f.Texture:find("111092388") then
				default_avatar_state.face_texture = f.Texture
			end
		end
		local limbNames = {
			"UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand",
			"RightUpperArm", "RightLowerArm", "RightHand",
			"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
			"RightUpperLeg", "RightLowerLeg", "RightFoot"
		}
		if not default_avatar_state.limbs then
			default_avatar_state.limbs = {}
			for _, name in ipairs(limbNames) do
				local p = char:FindFirstChild(name)
				if p and p:IsA("MeshPart") and p.MeshId ~= "" then
					local atts = {}
					for _, a in ipairs(p:GetChildren()) do
						if a:IsA("Attachment") then
							atts[a.Name] = a.CFrame
						end
					end
					default_avatar_state.limbs[name] = {
						meshId = p.MeshId,
						textureId = p.TextureID,
						size = p.Size,
						attachments = atts,
					}
				end
			end
		end

		if animate and not default_avatar_state.captured then
			for slotName, _ in pairs(default_avatar_state.animations) do
				local slot = animate:FindFirstChild(slotName)
				if slot then
					local list = {}
					for _, a in ipairs(slot:GetChildren()) do
						if a:IsA("Animation") and a.AnimationId ~= "" then
							table.insert(list, { name = a.Name, id = a.AnimationId })
						end
					end
					if #list > 0 then
						default_avatar_state.animations[slotName] = list
					end
				end
			end
			default_avatar_state.captured = true
		end
	end

	local function align_joints(character)
		if not character then return end
		for _, motor in ipairs(character:GetDescendants()) do
			if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
				local attName = motor.Name .. "RigAttachment"
				local att0 = motor.Part0:FindFirstChild(attName)
				local att1 = motor.Part1:FindFirstChild(attName)
				if att0 and att1 then
					motor.C0 = att0.CFrame
					motor.C1 = att1.CFrame
				end
			end
		end
	end

	local function apply_custom_character(description)
		if not description then return end
		local char = LocalPlayer.Character
		if not char or not char.Parent then return end

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		local head = char:FindFirstChild("Head")
		if not humanoid then return end

		if not default_avatar_state.captured then
			snapshot_default_avatar(char)
		end

		apply_token = apply_token + 1
		local current_token = apply_token
		active_custom_desc = description

		-- 1. Clear existing accessories, clothing, and face decals (Identical to Neverlose V3)
		humanoid:RemoveAccessories()

		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("Accessory") then
				pcall(function() item:Destroy() end)
			end
		end

		if head then
			for _, item in ipairs(head:GetChildren()) do
				if item:IsA("Decal") and item.Name:lower() == "face" then
					pcall(function() item:Destroy() end)
				end
			end
		end

		-- 2. Apply Body Colors
		local bc = char:FindFirstChildOfClass("BodyColors")
		if not bc then
			bc = Instance.new("BodyColors", char)
		end
		if description.HeadColor then bc.HeadColor3 = description.HeadColor end
		if description.TorsoColor then bc.TorsoColor3 = description.TorsoColor end
		if description.LeftArmColor then bc.LeftArmColor3 = description.LeftArmColor end
		if description.RightArmColor then bc.RightArmColor3 = description.RightArmColor end
		if description.LeftLegColor then bc.LeftLegColor3 = description.LeftLegColor end
		if description.RightLegColor then bc.RightLegColor3 = description.RightLegColor end

		-- 3. Apply Scales (Preserve tool grip & height)
		local scaleMap = {
			BodyHeightScale = description.HeightScale,
			BodyWidthScale = description.WidthScale,
			BodyDepthScale = description.DepthScale,
			HeadScale = description.HeadScale,
			BodyTypeScale = description.BodyTypeScale,
			BodyProportionScale = description.ProportionScale,
		}
		for sName, sVal in pairs(scaleMap) do
			if sVal and tonumber(sVal) then
				local sv = humanoid:FindFirstChild(sName)
				if sv and sv:IsA("NumberValue") then
					sv.Value = sVal
				end
			end
		end

		-- 4. Apply Limbs
		local limbAssetIds = {
			Torso = description.Torso,
			LeftArm = description.LeftArm,
			RightArm = description.RightArm,
			LeftLeg = description.LeftLeg,
			RightLeg = description.RightLeg,
		}

		local limbPartMapping = {
			Torso = { "UpperTorso", "LowerTorso" },
			LeftArm = { "LeftUpperArm", "LeftLowerArm", "LeftHand" },
			RightArm = { "RightUpperArm", "RightLowerArm", "RightHand" },
			LeftLeg = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
			RightLeg = { "RightUpperLeg", "RightLowerLeg", "RightFoot" },
		}

		for lKey, pId in pairs(limbAssetIds) do
			if pId and pId > 0 then
				task.spawn(function()
					local res = cached_get_obj(pId)
					if current_token ~= apply_token or not char or not char.Parent then return end
					if res and #res > 0 then
						local container = res[1]
						for _, child in ipairs(container:GetChildren()) do
							if child:IsA("MeshPart") then
								local charPart = char:FindFirstChild(child.Name)
								if charPart and charPart:IsA("MeshPart") then
									charPart.MeshId = child.MeshId
									charPart.TextureID = child.TextureID
									charPart.Transparency = 0
								end
							end
						end
					end
				end)
			else
				-- If ID has no custom mesh for this limb group, restore the default limb meshes!
				if default_avatar_state.limbs and limbPartMapping[lKey] then
					for _, partName in ipairs(limbPartMapping[lKey]) do
						local defLimb = default_avatar_state.limbs[partName]
						local charPart = char:FindFirstChild(partName)
						if defLimb and charPart and charPart:IsA("MeshPart") then
							charPart.MeshId = defLimb.meshId
							charPart.TextureID = defLimb.textureId
							if defLimb.size then
								charPart.Size = defLimb.size
								local orig = charPart:FindFirstChild("OriginalSize")
								if orig and orig:IsA("Vector3Value") then orig.Value = defLimb.size end
							end
							if defLimb.attachments then
								for attName, cf in pairs(defLimb.attachments) do
									local a = charPart:FindFirstChild(attName)
									if a and a:IsA("Attachment") then
										a.CFrame = cf
									end
								end
							end
							charPart.Transparency = 0
						end
					end
				end
			end
		end

		-- 5. Apply Head, Dynamic Face & Headless (With default restore for Head mesh/texture)
		local is_headless = (description.Head == 134082579 or description.Head == 134082578 or description.Head == 249965654 or description.Head == 15093053680)
		if head then
			if is_headless then
				head.Transparency = 1
				local face = head:FindFirstChild("face") or head:FindFirstChild("Face")
				if face then face.Transparency = 1 end
			else
				head.Transparency = 0
				if description.Head and description.Head > 0 then
					task.spawn(function()
						local res = cached_get_obj(description.Head)
						if current_token ~= apply_token or not head or not head.Parent then return end
						if res and #res > 0 then
							local headItem = res[1]
							local mId = headItem:IsA("SpecialMesh") and headItem.MeshId or (headItem:IsA("MeshPart") and headItem.MeshId)
							local tId = headItem:IsA("SpecialMesh") and headItem.TextureId or (headItem:IsA("MeshPart") and headItem.TextureID)

							if mId == "rbxassetid://134079402" or (headItem:IsA("SpecialMesh") and headItem.Scale == Vector3.zero) then
								head.Transparency = 1
								local face = head:FindFirstChild("face") or head:FindFirstChild("Face")
								if face then face.Transparency = 1 end
								return
							end

							if head:IsA("MeshPart") then
								if mId and mId ~= "" then head.MeshId = mId end
								if tId and tId ~= "" then head.TextureID = tId end
							else
								local existingMesh = head:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh", head)
								if mId and mId ~= "" then existingMesh.MeshId = mId end
								if tId and tId ~= "" then existingMesh.TextureId = tId end
							end

							if tId and tId ~= "" and (not description.Face or description.Face == 0) then
								for _, d in ipairs(head:GetChildren()) do
									if d:IsA("Decal") and d.Name:lower() == "face" then
										d.Transparency = 1
									end
								end
							end
						end
					end)
				else
					-- Reset to default head mesh and wipe custom face texture
					if head:IsA("MeshPart") then
						head.MeshId = default_avatar_state.head_mesh_id
						head.TextureID = default_avatar_state.head_texture_id
					else
						local existingMesh = head:FindFirstChildOfClass("SpecialMesh")
						if existingMesh then
							existingMesh.MeshId = default_avatar_state.head_mesh_id
							existingMesh.TextureId = default_avatar_state.head_texture_id
						end
					end
				end
			end
		end

		-- 6. Apply Clothing (Shirt, Pants, GraphicTShirt)
		if description.Shirt and description.Shirt > 0 then
			task.spawn(function()
				local res = cached_get_obj(description.Shirt)
				if current_token ~= apply_token or not char or not char.Parent then return end
				if res and #res > 0 then
					for _, obj in ipairs(res) do
						if obj:IsA("Shirt") then
							obj.Parent = char
							break
						end
					end
				end
			end)
		end

		if description.Pants and description.Pants > 0 then
			task.spawn(function()
				local res = cached_get_obj(description.Pants)
				if current_token ~= apply_token or not char or not char.Parent then return end
				if res and #res > 0 then
					for _, obj in ipairs(res) do
						if obj:IsA("Pants") then
							obj.Parent = char
							break
						end
					end
				end
			end)
		end

		if description.GraphicTShirt and description.GraphicTShirt > 0 then
			task.spawn(function()
				local res = cached_get_obj(description.GraphicTShirt)
				if current_token ~= apply_token or not char or not char.Parent then return end
				if res and #res > 0 then
					for _, obj in ipairs(res) do
						if obj:IsA("ShirtGraphic") then
							obj.Parent = char
							break
						end
					end
				end
			end)
		end

		-- 7. Apply Face Decal (Classic Faces from Asset ID or Default Restore)
		if head and not is_headless then
			if description.Face and description.Face > 0 then
				task.spawn(function()
					local res = cached_get_obj(description.Face)
					if current_token ~= apply_token or not head or not head.Parent then return end
					if res and #res > 0 then
						local decal = res[1]:IsA("Decal") and res[1] or res[1]:FindFirstChildOfClass("Decal")
						if decal then
							local existingFace = head:FindFirstChild("face") or head:FindFirstChild("Face")
							if not existingFace then
								existingFace = Instance.new("Decal", head)
								existingFace.Name = "face"
							end
							existingFace.Texture = decal.Texture
							existingFace.Transparency = 0
						end
					end
				end)
			else
				-- If ID has no custom Face Decal AND head is not using a dynamic face texture (head.TextureID == "")
				-- Restore default Roblox face so head is not blank!
				task.defer(function()
					if current_token ~= apply_token or not head or not head.Parent then return end
					local is_mesh_textured = (head:IsA("MeshPart") and head.TextureID ~= "") or (head:FindFirstChildOfClass("SpecialMesh") and head:FindFirstChildOfClass("SpecialMesh").TextureId ~= "")
					if not is_mesh_textured and not is_headless then
						local existingFace = head:FindFirstChild("face") or head:FindFirstChild("Face")
						if not existingFace then
							existingFace = Instance.new("Decal", head)
							existingFace.Name = "face"
						end
						existingFace.Texture = default_avatar_state.face_texture
						existingFace.Transparency = 0
					end
				end)
			end
		end

		-- 8. Apply Accessories with Attachment Welding
		local accList = description:GetAccessories(true)
		for _, accData in ipairs(accList) do
			task.spawn(function()
				local res = cached_get_obj(accData.AssetId)
				if current_token ~= apply_token or not char or not char.Parent then return end
				if res and #res > 0 then
					local inst = res[1]
					if inst:IsA("Accessory") then
						local handle = inst:FindFirstChild("Handle")
						if handle and handle:IsA("BasePart") then
							handle.CanCollide = false
							handle.Massless = true

							local att = handle:FindFirstChildOfClass("Attachment")
							local targetAtt = nil
							if att then
								for _, part in ipairs(char:GetChildren()) do
									if part:IsA("BasePart") then
										local found = part:FindFirstChild(att.Name)
										if found and found:IsA("Attachment") then
											targetAtt = found
											break
										end
									end
								end
							end

							if att and targetAtt then
								handle.CFrame = targetAtt.Parent.CFrame * targetAtt.CFrame * att.CFrame:Inverse()
								local weld = Instance.new("Weld")
								weld.Name = "AccessoryWeld"
								weld.Part0 = handle
								weld.Part1 = targetAtt.Parent
								weld.C0 = att.CFrame
								weld.C1 = targetAtt.CFrame
								weld.Parent = handle
							elseif head then
								handle.CFrame = head.CFrame * CFrame.new(0, 0.5, 0)
								local weld = Instance.new("Weld")
								weld.Name = "AccessoryWeld"
								weld.Part0 = handle
								weld.Part1 = head
								weld.C0 = CFrame.new(0, -0.5, 0)
								weld.C1 = CFrame.new()
								weld.Parent = handle
							end

							inst.Parent = char
						end
					end
				end
			end)
		end

		-- 9. Universal Animation Engine (Idle, Walk, Run, Jump, Fall, Climb, Swim, Mood)
		local animate = char:FindFirstChild("Animate")
		local animProps = {
			{description.IdleAnimation, "idle"},
			{description.WalkAnimation, "walk"},
			{description.RunAnimation, "run"},
			{description.JumpAnimation, "jump"},
			{description.FallAnimation, "fall"},
			{description.ClimbAnimation, "climb"},
			{description.SwimAnimation, "swim"},
		}

		task.spawn(function()
			local anyAnimUpdated = false

			-- Handle Mood slot if present (Dynamic facial animations)
			if animate then
				local moodSlot = animate:FindFirstChild("mood")
				if moodSlot then
					if description.MoodAnimation and description.MoodAnimation > 0 then
						local res = cached_get_obj(description.MoodAnimation)
						if res and #res > 0 then
							for _, c in ipairs(moodSlot:GetChildren()) do
								if c:IsA("Animation") then
									local root = res[1]
									c.AnimationId = root:IsA("Animation") and root.AnimationId or ("rbxassetid://" .. description.MoodAnimation)
								end
							end
						end
					else
						for _, c in ipairs(moodSlot:GetChildren()) do
							if c:IsA("Animation") then
								c.AnimationId = ""
							end
						end
					end
				end
			end

			for _, item in ipairs(animProps) do
				local animAssetId, slotName = item[1], item[2]
				if animate then
					local targetSlot = animate:FindFirstChild(slotName)
					if targetSlot then
						if animAssetId and animAssetId > 0 then
							local res = cached_get_obj(animAssetId)
							if current_token ~= apply_token or not animate or not animate.Parent then return end

							local extractedAnims = {}
							if res and #res > 0 then
								local root = res[1]
								local slotFolder = root:FindFirstChild(slotName)
								if not slotFolder then
									for _, child in ipairs(root:GetChildren()) do
										if (child:IsA("StringValue") or child:IsA("Folder")) and child.Name:lower() == slotName:lower() then
											slotFolder = child
											break
										end
									end
								end
								if slotFolder then
									for _, c in ipairs(slotFolder:GetChildren()) do
										if c:IsA("Animation") then
											table.insert(extractedAnims, c)
										end
									end
								end
								if #extractedAnims == 0 and root:IsA("Animation") then
									table.insert(extractedAnims, root)
								end
							end

							-- Clean up leftover custom animations from previous morphs
							local keepNames = {}
							for _, a in ipairs(extractedAnims) do
								keepNames[a.Name] = true
							end
							for _, c in ipairs(targetSlot:GetChildren()) do
								if c:IsA("Animation") and not keepNames[c.Name] and c.Name ~= "Animation1" and c.Name ~= "WalkAnim" and c.Name ~= "RunAnim" and c.Name ~= "JumpAnim" and c.Name ~= "FallAnim" and c.Name ~= "ClimbAnim" and c.Name ~= "Swim" then
									pcall(function() c:Destroy() end)
								end
							end

							if #extractedAnims > 0 then
								if #extractedAnims == 1 then
									for _, c in ipairs(targetSlot:GetChildren()) do
										if c:IsA("Animation") then
											c.AnimationId = extractedAnims[1].AnimationId
										end
									end
								else
									for _, anim in ipairs(extractedAnims) do
										local existingAnim = targetSlot:FindFirstChild(anim.Name)
										if existingAnim and existingAnim:IsA("Animation") then
											existingAnim.AnimationId = anim.AnimationId
										else
											local clone = anim:Clone()
											clone.Parent = targetSlot
										end
									end
								end
								anyAnimUpdated = true
							else
								local fallbackUrl = "rbxassetid://" .. animAssetId
								for _, c in ipairs(targetSlot:GetChildren()) do
									if c:IsA("Animation") then
										c.AnimationId = fallbackUrl
									end
								end
								anyAnimUpdated = true
							end
						else
							-- ID has no animation for this slot -> restore default animation
							local defSlot = default_avatar_state.animations[slotName]
							if defSlot and #defSlot > 0 then
								for _, c in ipairs(targetSlot:GetChildren()) do
									if c:IsA("Animation") then
										local matched = false
										for _, d in ipairs(defSlot) do
											if c.Name == d.name then
												c.AnimationId = d.id
												matched = true
												break
											end
										end
										if not matched and #defSlot == 1 then
											c.AnimationId = defSlot[1].id
										end
									end
								end
								anyAnimUpdated = true
							end
						end
					end
				end
			end

			-- Stop all playing tracks so previous animations do not bleed through
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					track:Stop(0)
				end
			end

			-- Seamlessly restart animate script
			if anyAnimUpdated and animate and animate:IsA("LocalScript") then
				animate.Disabled = true
				task.wait(0.04)
				if current_token == apply_token and animate and animate.Parent then
					animate.Disabled = false
				end
			end
		end)

		-- 10. Joint Realignment & Anti-Sink Floor Recalibration
		align_joints(char)

		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.35, 0)
		end
		if humanoid and humanoid.Parent then
			task.delay(0.05, function()
				if humanoid and humanoid.Parent then
					humanoid:ChangeState(Enum.HumanoidStateType.Landed)
				end
			end)
		end
	end

	local default_rbm_presets = {
		"2909212097_ixvail_Emo_Boy.rbm",
		"1981141314_B3timesx_Da_Hood_Trench_Boy.rbm",
		"2241517565_Aiokes_Slender_Boy.rbm",
		"2837492019_Denis_Da_Hood_Street_Boy.rbm",
		"1849203847_nilk_Casual_Da_Hood_Boy.rbm",
		"432168393_vccaga_Da_Hood_Hoodie_Boy.rbm",
		"1284562089_TuNutella_Streetwear_Jacket.rbm",
		"2039485721_UDYX_Dark_Trench_Male.rbm",
		"5361979849_MOPKOBKA_Da_Hood_Star_Crop.rbm",
		"7330533246_Bellaaa_Preppy_Barbie.rbm",
		"10542009861_bellaandrew_Chibi_Baddie.rbm",
		"9639447735_regretsmj_Da_Hood_Gothic_Girl.rbm",
		"1138506088_0Sinay_Da_Hood_Y2K_Baddie.rbm",
		"3420846205_Mia_Soft_Da_Hood_E_Girl.rbm",
		"2583272991_Chloe_Y2K_Pink_Preppy.rbm",
		"4491717904_Kira_Grunge_Aesthetic_Girl.rbm"
	}

	local function parse_rbm_to_description(json_str)
		local ok, raw = pcall(function() return HttpService:JSONDecode(json_str) end)
		if not ok or type(raw) ~= "table" then return nil end

		local avData = raw.avatarData or raw
		local scales = avData.scales or {}
		local bodyColors = avData.bodyColors or {}
		local assets = avData.assets or {}

		local function get_bc_color(val, fallback)
			if not val then return fallback end
			local s, c = pcall(function() return BrickColor.new(val).Color end)
			return (s and c) and c or fallback
		end

		local desc = {
			Head = 0,
			Torso = 0,
			LeftArm = 0,
			RightArm = 0,
			LeftLeg = 0,
			RightLeg = 0,
			Shirt = 0,
			Pants = 0,
			GraphicTShirt = 0,
			Face = 0,
			IdleAnimation = 0,
			WalkAnimation = 0,
			RunAnimation = 0,
			JumpAnimation = 0,
			FallAnimation = 0,
			ClimbAnimation = 0,
			SwimAnimation = 0,
			MoodAnimation = 0,
			HeadColor = get_bc_color(bodyColors.headColorId, Color3.fromRGB(240, 240, 240)),
			TorsoColor = get_bc_color(bodyColors.torsoColorId, Color3.fromRGB(240, 240, 240)),
			LeftArmColor = get_bc_color(bodyColors.leftArmColorId, Color3.fromRGB(240, 240, 240)),
			RightArmColor = get_bc_color(bodyColors.rightArmColorId, Color3.fromRGB(240, 240, 240)),
			LeftLegColor = get_bc_color(bodyColors.leftLegColorId, Color3.fromRGB(240, 240, 240)),
			RightLegColor = get_bc_color(bodyColors.rightLegColorId, Color3.fromRGB(240, 240, 240)),
			HeightScale = scales.height or 1,
			WidthScale = scales.width or 1,
			DepthScale = scales.depth or 1,
			HeadScale = scales.head or 1,
			BodyTypeScale = scales.bodyType or 0,
			ProportionScale = scales.proportion or 0,
			_accessories = {},
		}

		function desc:GetAccessories(includeRigid)
			return self._accessories
		end

		for _, ast in ipairs(assets) do
			local astId = tonumber(ast.id)
			if astId and astId > 0 then
				local typeName = ast.assetType and ast.assetType.name or ""
				local typeId = ast.assetType and tonumber(ast.assetType.id) or 0

				if typeName == "Head" or typeId == 17 or typeName == "DynamicHead" or typeId == 79 then
					desc.Head = astId
				elseif typeName == "Torso" or typeId == 27 then
					desc.Torso = astId
				elseif typeName == "RightArm" or typeId == 28 then
					desc.RightArm = astId
				elseif typeName == "LeftArm" or typeId == 29 then
					desc.LeftArm = astId
				elseif typeName == "LeftLeg" or typeId == 30 then
					desc.LeftLeg = astId
				elseif typeName == "RightLeg" or typeId == 31 then
					desc.RightLeg = astId
				elseif typeName == "Shirt" or typeId == 11 then
					desc.Shirt = astId
				elseif typeName == "Pants" or typeId == 12 then
					desc.Pants = astId
				elseif typeName == "TShirt" or typeName == "GraphicTShirt" or typeId == 2 then
					desc.GraphicTShirt = astId
				elseif typeName == "Face" or typeId == 18 then
					desc.Face = astId
				elseif typeName == "IdleAnimation" or typeId == 51 then
					desc.IdleAnimation = astId
				elseif typeName == "WalkAnimation" or typeId == 53 then
					desc.WalkAnimation = astId
				elseif typeName == "RunAnimation" or typeId == 54 then
					desc.RunAnimation = astId
				elseif typeName == "JumpAnimation" or typeId == 52 then
					desc.JumpAnimation = astId
				elseif typeName == "FallAnimation" or typeId == 50 then
					desc.FallAnimation = astId
				elseif typeName == "ClimbAnimation" or typeId == 48 then
					desc.ClimbAnimation = astId
				elseif typeName == "SwimAnimation" or typeId == 55 then
					desc.SwimAnimation = astId
				elseif typeName == "MoodAnimation" or typeId == 78 then
					desc.MoodAnimation = astId
				else
					table.insert(desc._accessories, { AssetId = astId })
				end
			end
		end

		return desc
	end

	local function load_rbm_file_content(file_name)
		if not file_name or file_name == "" then return nil, nil end
		if not file_name:match("%.rbm$") then
			file_name = file_name .. ".rbm"
		end

		local paths_to_check = {
			"assets/Character/" .. file_name,
			"assest/Character/" .. file_name,
			"assets/" .. file_name,
			"assest/" .. file_name,
			file_name,
		}

		for _, p in ipairs(paths_to_check) do
			if isfile and isfile(p) and readfile then
				local ok, content = pcall(readfile, p)
				if ok and content and content ~= "" then
					return content, "local"
				end
			end
		end

		local github_urls = {
			"https://raw.githubusercontent.com/koli0463/liuuuzuuu/refs/heads/main/assets/Character/" .. file_name,
			"https://raw.githubusercontent.com/koli0463/liuuuzuuu/refs/heads/main/assest/Character/" .. file_name,
		}

		for _, url in ipairs(github_urls) do
			local ok, content = pcall(function()
				return game:HttpGet(url)
			end)
			if ok and content and content ~= "" and not content:find("404: Not Found") then
				pcall(function()
					if makefolder then
						if not (isfolder and isfolder("assets")) then pcall(makefolder, "assets") end
						if not (isfolder and isfolder("assets/Character")) then pcall(makefolder, "assets/Character") end
						if not (isfolder and isfolder("assest")) then pcall(makefolder, "assest") end
						if not (isfolder and isfolder("assest/Character")) then pcall(makefolder, "assest/Character") end
					end
					if writefile then
						pcall(writefile, "assets/Character/" .. file_name, content)
						pcall(writefile, "assest/Character/" .. file_name, content)
					end
				end)
				return content, "downloaded"
			end
		end

		return nil, nil
	end

	local function get_available_rbm_files()
		local file_list = {}
		for _, f in ipairs(default_rbm_presets) do
			table.insert(file_list, f)
		end

		local scan_fn = listfiles or (syn and syn.listfiles) or (fluxus and fluxus.listfiles)
		if scan_fn then
			local scan_folders = { "assets/Character", "assest/Character" }
			for _, folder in ipairs(scan_folders) do
				pcall(function()
					local found = scan_fn(folder)
					if type(found) == "table" then
						for _, item in ipairs(found) do
							local fname = item:match("([^/\\]+%.rbm)$")
							if fname and not table.find(file_list, fname) then
								table.insert(file_list, fname)
							end
						end
					end
				end)
			end
		end
		return file_list
	end

	local function get_target_description(overrideId)
		if flags["custom_char_model_type"] == "File" and not overrideId then
			local chosen_file = flags["custom_char_selected_file"]
			if type(chosen_file) == "table" then chosen_file = chosen_file[1] end
			if not chosen_file or chosen_file == "" then
				chosen_file = default_rbm_presets[1]
			end
			if desc_cache[chosen_file] then
				return desc_cache[chosen_file]
			end
			library:notification({ text = "Loading .rbm file: " .. chosen_file .. "...", time = 2.5 })
			local content, source = load_rbm_file_content(chosen_file)
			if content then
				local desc = parse_rbm_to_description(content)
				if desc then
					desc_cache[chosen_file] = desc
					if source == "downloaded" then
						library:notification({ text = "✔ Downloaded & applied character: " .. chosen_file, time = 3.5 })
					else
						library:notification({ text = "✔ Loaded character from file: " .. chosen_file, time = 3 })
					end
					return desc
				end
			end
			library:notification({ text = "❌ Failed to load file: " .. tostring(chosen_file), time = 3 })
			return nil
		end

		local rawId = overrideId or (flags["custom_char_model_type"] == "Custom id" and flags["custom_char_userid"]) or last_selected_preset_id
		if not rawId then return nil end
		local strId = tostring(rawId):match("%d+")
		if not strId then
			library:notification({ text = "Please enter a valid player User ID", time = 3 })
			return nil
		end
		local uid = tonumber(strId)
		if desc_cache[uid] then
			return desc_cache[uid]
		end
		local ok, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(uid)
		end)
		if ok and desc then
			desc_cache[uid] = desc
			return desc
		else
			library:notification({ text = "Failed to load User ID: " .. tostring(uid), time = 3 })
		end
		return nil
	end

	local function apply_current_target(overrideId)
		local desc = get_target_description(overrideId)
		if desc then
			apply_custom_character(desc)
		end
	end

	-- =========================================================================
	-- UI: CUSTOM CHARACTER CONTROLLER (REUSABLE TICK & X, NONE DEFAULT)
	-- =========================================================================

	-- File persistence for custom user-added character IDs and notes
	local custom_ids_save_file = library.directory .. "/custom_char_presets.json"
	local notes_save_file = library.directory .. "/custom_char_notes.json"

	local function load_char_notes()
		if isfile and isfile(notes_save_file) and readfile then
			local ok, content = pcall(readfile, notes_save_file)
			if ok and content and content ~= "" then
				local ok_dec, data = pcall(function() return game:GetService("HttpService"):JSONDecode(content) end)
				if ok_dec and type(data) == "table" then
					return data
				end
			end
		end
		return {}
	end

	local function save_char_note(id_str, tag_str)
		if not writefile then return end
		if isfolder and not isfolder(library.directory) then
			pcall(makefolder, library.directory)
		end
		local notes = load_char_notes()
		local num = tostring(id_str):match("%d+")
		if not num then return end
		if tag_str and tag_str ~= "" then
			notes[num] = tag_str
		else
			notes[num] = nil
		end
		local payload = ""
		pcall(function() payload = game:GetService("HttpService"):JSONEncode(notes) end)
		if payload ~= "" then
			pcall(function() writefile(notes_save_file, payload) end)
		end
	end

	local function apply_tag_to_item(item_str, tag)
		if not tag or tag == "" then return item_str end
		local bracket_part = item_str:match("^(.-%b[])")
		if bracket_part then
			return bracket_part .. " - " .. tag
		else
			local base = item_str:match("^(.-)%s+%-%s+[^%-]+$") or item_str
			return base .. " - " .. tag
		end
	end

	-- 1. Action Row with Label + Note Button + Reusable Tick & X Buttons
	local custom_row = library:create("Frame", {
		Parent = custom_char_sec.holder,
		Name = "CustomCharRow",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -26, 0, 20),
	})

	local custom_label = library:create("TextLabel", {
		Parent = custom_row,
		Name = "Label",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "Custom character",
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -74, 1, 0),
		TextSize = 12,
	})

	-- Note Ghi Chú Button (Dropdown Arrow Icon - Image 2)
	local note_inline = library:create("Frame", {
		Parent = custom_row,
		Name = "NoteInline",
		Position = UDim2.new(1, -68, 0, 0),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(0, 20, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local note_btn = library:create("TextButton", {
		Parent = note_inline,
		Name = "NoteBtn",
		Text = "",
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(26, 26, 30),
		BorderColor3 = Color3.fromRGB(45, 45, 52),
		AutoButtonColor = false,
	})

	local note_icon = library:create("ImageLabel", {
		Parent = note_btn,
		Name = "NoteIcon",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 9, 0, 9),
		Image = "rbxassetid://10747363621",
		Rotation = 180,
		ImageColor3 = Color3.fromRGB(150, 150, 165),
	})

	-- Tick Button Container (Green Checkmark when active)
	local tick_inline = library:create("Frame", {
		Parent = custom_row,
		Name = "TickInline",
		Position = UDim2.new(1, -44, 0, 0),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(0, 20, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local tick_btn = library:create("TextButton", {
		Parent = tick_inline,
		Name = "TickBtn",
		Text = "",
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(26, 26, 30),
		BorderColor3 = Color3.fromRGB(45, 45, 52),
	})

	local tick_icon = library:create("ImageLabel", {
		Parent = tick_btn,
		Name = "TickIcon",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 11, 0, 11),
		Image = "rbxassetid://10709790644",
		ImageColor3 = Color3.fromRGB(100, 100, 110),
	})

	-- X Button Container (Red Cross when inactive)
	local x_inline = library:create("Frame", {
		Parent = custom_row,
		Name = "XInline",
		Position = UDim2.new(1, -20, 0, 0),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(0, 20, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local x_btn = library:create("TextButton", {
		Parent = x_inline,
		Name = "XBtn",
		Text = "",
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(48, 20, 20),
		BorderColor3 = Color3.fromRGB(105, 35, 35),
	})

	local x_icon = library:create("ImageLabel", {
		Parent = x_btn,
		Name = "XIcon",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 11, 0, 11),
		Image = "rbxassetid://10747384394",
		ImageColor3 = Color3.fromRGB(255, 80, 80),
	})

	local function update_custom_char_visual()
		if flags["custom_character"] then
			tick_btn.BackgroundColor3 = Color3.fromRGB(20, 48, 25)
			tick_btn.BorderColor3 = Color3.fromRGB(35, 100, 48)
			tick_icon.ImageColor3 = Color3.fromRGB(80, 230, 110)

			x_btn.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
			x_btn.BorderColor3 = Color3.fromRGB(45, 45, 52)
			x_icon.ImageColor3 = Color3.fromRGB(100, 100, 110)
		else
			tick_btn.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
			tick_btn.BorderColor3 = Color3.fromRGB(45, 45, 52)
			tick_icon.ImageColor3 = Color3.fromRGB(100, 100, 110)

			x_btn.BackgroundColor3 = Color3.fromRGB(48, 20, 20)
			x_btn.BorderColor3 = Color3.fromRGB(105, 35, 35)
			x_icon.ImageColor3 = Color3.fromRGB(255, 80, 80)
		end
	end

	local function set_custom_character_state(enabled)
		flags["custom_character"] = enabled
		update_custom_char_visual()
		if enabled then
			apply_current_target()
		else
			active_custom_desc = nil
			local char = LocalPlayer.Character
			local ok, orig = pcall(function()
				return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
			end)
			if ok and orig then
				apply_custom_character(orig)
			else
				local fallbackDesc = Instance.new("HumanoidDescription")
				apply_custom_character(fallbackDesc)
			end
			if char then
				align_joints(char)
			end
		end
	end

	tick_btn.MouseButton1Click:Connect(function()
		set_custom_character_state(true)
	end)

	x_btn.MouseButton1Click:Connect(function()
		set_custom_character_state(false)
	end)

	tick_btn.MouseEnter:Connect(function()
		if flags["custom_character"] then
			tick_btn.BackgroundColor3 = Color3.fromRGB(28, 68, 35)
			tick_btn.BorderColor3 = Color3.fromRGB(50, 140, 68)
			tick_icon.ImageColor3 = Color3.fromRGB(110, 255, 140)
		else
			tick_btn.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
			tick_btn.BorderColor3 = Color3.fromRGB(60, 60, 70)
			tick_icon.ImageColor3 = Color3.fromRGB(150, 150, 160)
		end
	end)
	tick_btn.MouseLeave:Connect(update_custom_char_visual)

	x_btn.MouseEnter:Connect(function()
		if not flags["custom_character"] then
			x_btn.BackgroundColor3 = Color3.fromRGB(72, 25, 25)
			x_btn.BorderColor3 = Color3.fromRGB(140, 45, 45)
			x_icon.ImageColor3 = Color3.fromRGB(255, 120, 120)
		else
			x_btn.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
			x_btn.BorderColor3 = Color3.fromRGB(60, 60, 70)
			x_icon.ImageColor3 = Color3.fromRGB(150, 150, 160)
		end
	end)
	x_btn.MouseLeave:Connect(update_custom_char_visual)

	-- 1.5. Note Dropdown Drawer (Animated Drawer for "Rich", "Furry", "Egirl", "custom type")
	local note_drawer_open = false
	local selected_note_type = "Rich"
	local custom_note_text = ""

	local function get_active_tag()
		if selected_note_type == "custom type" then
			local clean = custom_note_text:match("^%s*(.-)%s*$")
			return (clean and clean ~= "") and clean or "Custom"
		else
			return selected_note_type
		end
	end

	local note_container = Instance.new("CanvasGroup")
	note_container.Name = "CustomCharNoteContainer"
	note_container.BackgroundTransparency = 1
	note_container.BorderSizePixel = 0
	note_container.Size = UDim2.new(1, -26, 0, 0)
	note_container.Visible = false
	note_container.GroupTransparency = 1
	note_container.Parent = custom_char_sec.holder

	local note_inner = Instance.new("Frame")
	note_inner.Name = "NoteInner"
	note_inner.BackgroundTransparency = 1
	note_inner.BorderSizePixel = 0
	note_inner.Size = UDim2.new(1, 0, 0, 22)
	note_inner.Position = UDim2.new(0, 0, 0, -15)
	note_inner.Parent = note_container

	local note_layout = Instance.new("UIListLayout")
	note_layout.Padding = UDim.new(0, 3)
	note_layout.SortOrder = Enum.SortOrder.LayoutOrder
	note_layout.Parent = note_inner

	local note_type_btn = Instance.new("TextButton")
	note_type_btn.Name = "NoteTypeBtn"
	note_type_btn.Size = UDim2.new(1, 0, 0, 20)
	note_type_btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	note_type_btn.BorderColor3 = Color3.fromRGB(50, 50, 62)
	note_type_btn.BorderSizePixel = 1
	note_type_btn.Text = "Note tag: Rich"
	note_type_btn.TextColor3 = Color3.fromRGB(220, 220, 230)
	note_type_btn.TextSize = 11
	note_type_btn.FontFace = library.font
	note_type_btn.TextXAlignment = Enum.TextXAlignment.Left
	note_type_btn.AutoButtonColor = false
	note_type_btn.Parent = note_inner

	local note_type_pad = Instance.new("UIPadding")
	note_type_pad.PaddingLeft = UDim.new(0, 6)
	note_type_pad.Parent = note_type_btn

	local note_type_arrow = Instance.new("ImageLabel")
	note_type_arrow.Name = "Arrow"
	note_type_arrow.BackgroundTransparency = 1
	note_type_arrow.Position = UDim2.new(1, -12, 0.5, 0)
	note_type_arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	note_type_arrow.Size = UDim2.new(0, 7, 0, 7)
	note_type_arrow.Image = "rbxassetid://10747363621"
	note_type_arrow.Rotation = 180
	note_type_arrow.ImageColor3 = Color3.fromRGB(150, 150, 165)
	note_type_arrow.Parent = note_type_btn

	local custom_type_holder = Instance.new("Frame")
	custom_type_holder.Name = "CustomTypeHolder"
	custom_type_holder.Size = UDim2.new(1, 0, 0, 20)
	custom_type_holder.BackgroundTransparency = 1
	custom_type_holder.BorderSizePixel = 0
	custom_type_holder.Visible = false
	custom_type_holder.Parent = note_inner

	local custom_type_tb = Instance.new("TextBox")
	custom_type_tb.Name = "CustomTypeTextBox"
	custom_type_tb.Size = UDim2.new(1, 0, 1, 0)
	custom_type_tb.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	custom_type_tb.BorderColor3 = Color3.fromRGB(45, 55, 75)
	custom_type_tb.BorderSizePixel = 1
	custom_type_tb.PlaceholderText = "Type custom tag (e.g. Slender)..."
	custom_type_tb.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
	custom_type_tb.Text = ""
	custom_type_tb.TextColor3 = Color3.fromRGB(235, 235, 245)
	custom_type_tb.TextSize = 11
	custom_type_tb.FontFace = library.font
	custom_type_tb.ClearTextOnFocus = false
	custom_type_tb.Parent = custom_type_holder

	local custom_type_pad = Instance.new("UIPadding")
	custom_type_pad.PaddingLeft = UDim.new(0, 6)
	custom_type_pad.Parent = custom_type_tb

	custom_type_tb:GetPropertyChangedSignal("Text"):Connect(function()
		custom_note_text = custom_type_tb.Text
		if selected_note_type == "custom type" then
			note_type_btn.Text = "Note tag: " .. ((custom_note_text ~= "") and custom_note_text or "custom type")
		end
	end)

	-- Floating popup menu for note types
	local note_popup = Instance.new("Frame")
	note_popup.Name = "NoteTypeDropdownPopup"
	note_popup.Visible = false
	note_popup.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
	note_popup.BorderColor3 = Color3.fromRGB(45, 45, 55)
	note_popup.BorderSizePixel = 1
	note_popup.ZIndex = 250
	note_popup.Parent = library.gui

	local note_popup_layout = Instance.new("UIListLayout")
	note_popup_layout.Padding = UDim.new(0, 1)
	note_popup_layout.SortOrder = Enum.SortOrder.LayoutOrder
	note_popup_layout.Parent = note_popup

	local function update_note_drawer_height()
		if not note_drawer_open then return end
		local target_h = (selected_note_type == "custom type") and 46 or 22
		note_inner.Size = UDim2.new(1, 0, 0, target_h)
		TweenService:Create(note_container, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, -26, 0, target_h)
		}):Play()
	end

	local note_type_options = { "Rich", "Furry", "Egirl", "custom type" }
	for _, opt in ipairs(note_type_options) do
		local opt_btn = Instance.new("TextButton")
		opt_btn.Name = "Opt_" .. opt
		opt_btn.Size = UDim2.new(1, 0, 0, 18)
		opt_btn.BackgroundTransparency = 1
		opt_btn.BackgroundColor3 = Color3.fromRGB(38, 42, 54)
		opt_btn.BorderSizePixel = 0
		opt_btn.Text = opt
		opt_btn.TextColor3 = Color3.fromRGB(180, 180, 195)
		opt_btn.TextSize = 11
		opt_btn.FontFace = library.font
		opt_btn.TextXAlignment = Enum.TextXAlignment.Left
		opt_btn.ZIndex = 251
		opt_btn.AutoButtonColor = false
		opt_btn.Parent = note_popup

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 6)
		pad.Parent = opt_btn

		opt_btn.MouseEnter:Connect(function()
			opt_btn.BackgroundTransparency = 0
			opt_btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		end)
		opt_btn.MouseLeave:Connect(function()
			opt_btn.BackgroundTransparency = 1
			opt_btn.TextColor3 = Color3.fromRGB(180, 180, 195)
		end)

		opt_btn.MouseButton1Click:Connect(function()
			selected_note_type = opt
			note_popup.Visible = false
			if opt == "custom type" then
				custom_type_holder.Visible = true
				note_type_btn.Text = "Note tag: " .. ((custom_note_text ~= "") and custom_note_text or "custom type")
				update_note_drawer_height()
				custom_type_tb:CaptureFocus()
			else
				custom_type_holder.Visible = false
				note_type_btn.Text = "Note tag: " .. opt
				update_note_drawer_height()
			end
			library:notification({ text = "🏷 Active note: [" .. get_active_tag() .. "]. Select ID 1 / ID 2 to tag.", time = 3 })
		end)
	end

	local function set_note_drawer_visible(show)
		note_drawer_open = show
		if show then
			note_container.Visible = true
			local target_h = (selected_note_type == "custom type") and 46 or 22
			local tween_info = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(note_container, tween_info, {
				Size = UDim2.new(1, -26, 0, target_h),
				GroupTransparency = 0
			}):Play()
			TweenService:Create(note_inner, tween_info, {
				Size = UDim2.new(1, 0, 0, target_h),
				Position = UDim2.new(0, 0, 0, 0)
			}):Play()
			TweenService:Create(note_icon, tween_info, { Rotation = 0 }):Play()
			note_btn.BackgroundColor3 = Color3.fromRGB(25, 38, 55)
			note_btn.BorderColor3 = Color3.fromRGB(45, 80, 140)
			note_icon.ImageColor3 = Color3.fromRGB(100, 180, 255)
		else
			if note_popup.Visible then note_popup.Visible = false end
			local tween_info = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			local tw = TweenService:Create(note_container, tween_info, {
				Size = UDim2.new(1, -26, 0, 0),
				GroupTransparency = 1
			})
			tw:Play()
			TweenService:Create(note_inner, tween_info, {
				Position = UDim2.new(0, 0, 0, -15)
			}):Play()
			TweenService:Create(note_icon, tween_info, { Rotation = 180 }):Play()
			note_btn.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
			note_btn.BorderColor3 = Color3.fromRGB(45, 45, 52)
			note_icon.ImageColor3 = Color3.fromRGB(150, 150, 165)
			tw.Completed:Connect(function()
				if not note_drawer_open then
					note_container.Visible = false
				end
			end)
		end
	end

	note_btn.MouseEnter:Connect(function()
		note_btn.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
		note_icon.ImageColor3 = Color3.fromRGB(220, 220, 240)
	end)
	note_btn.MouseLeave:Connect(function()
		if note_drawer_open then
			note_btn.BackgroundColor3 = Color3.fromRGB(25, 38, 55)
			note_btn.BorderColor3 = Color3.fromRGB(45, 80, 140)
			note_icon.ImageColor3 = Color3.fromRGB(100, 180, 255)
		else
			note_btn.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
			note_btn.BorderColor3 = Color3.fromRGB(45, 45, 52)
			note_icon.ImageColor3 = Color3.fromRGB(150, 150, 165)
		end
	end)
	note_btn.MouseButton1Click:Connect(function()
		set_note_drawer_visible(not note_drawer_open)
	end)

	note_type_btn.MouseButton1Click:Connect(function()
		note_popup.Visible = not note_popup.Visible
		if note_popup.Visible then
			local h = #note_type_options * 18 + 4
			note_popup.Size = UDim2.new(0, note_type_btn.AbsoluteSize.X, 0, h)
			note_popup.Position = UDim2.new(0, note_type_btn.AbsolutePosition.X, 0, note_type_btn.AbsolutePosition.Y + note_type_btn.AbsoluteSize.Y + 2)
		end
	end)

	-- 2. Dropdown: Model Type (Reordered: "Available" first as requested)
	local set_presets_visible
	local set_custom_tb_visible
	local set_file_container_visible

	custom_char_sec:dropdown({
		name = "Model type",
		flag = "custom_char_model_type",
		items = { "Available", "Custom id", "File", "None" },
		default = "Available",
		multi = false,
		callback = function(val)
			local mode = type(val) == "table" and val[1] or val
			if mode == "Available" then
				if set_presets_visible then set_presets_visible(true) end
				if set_custom_tb_visible then set_custom_tb_visible(false) end
				if set_file_container_visible then set_file_container_visible(false) end
				if flags["custom_character"] then
					apply_current_target()
				end
			elseif mode == "Custom id" then
				if set_presets_visible then set_presets_visible(false) end
				if set_custom_tb_visible then set_custom_tb_visible(true) end
				if set_file_container_visible then set_file_container_visible(false) end
				if flags["custom_character"] then
					apply_current_target()
				end
			elseif mode == "File" then
				if set_presets_visible then set_presets_visible(false) end
				if set_custom_tb_visible then set_custom_tb_visible(false) end
				if set_file_container_visible then set_file_container_visible(true) end
				if flags["custom_character"] then
					apply_current_target()
				end
			else -- "None"
				if set_presets_visible then set_presets_visible(false) end
				if set_custom_tb_visible then set_custom_tb_visible(false) end
				if set_file_container_visible then set_file_container_visible(false) end
			end
		end
	})

	-- 3. Presets Container (ID 1 Nam & ID 2 Nữ) - Starts visible since default is Available
	local preset_anim_id = 0
	local preset_container = Instance.new("CanvasGroup")
	preset_container.Name = "CustomCharPresetsContainer"
	preset_container.BackgroundTransparency = 1
	preset_container.BorderSizePixel = 0
	preset_container.Position = UDim2.new(0, -6, 0, 0)
	preset_container.Size = UDim2.new(1, 18, 0, 80)
	preset_container.Visible = true
	preset_container.GroupTransparency = 0
	preset_container.Parent = custom_char_sec.holder

	local preset_inner = Instance.new("Frame")
	preset_inner.Name = "PresetInner"
	preset_inner.BackgroundTransparency = 1
	preset_inner.BorderSizePixel = 0
	preset_inner.Size = UDim2.new(1, 0, 0, 80)
	preset_inner.Position = UDim2.new(0, 0, 0, 0)
	preset_inner.Parent = preset_container

	local preset_layout = Instance.new("UIListLayout")
	preset_layout.Padding = UDim.new(0, 3)
	preset_layout.SortOrder = Enum.SortOrder.LayoutOrder
	preset_layout.Parent = preset_inner

	set_presets_visible = function(show)
		preset_anim_id = preset_anim_id + 1
		local current_id = preset_anim_id
		if show then
			preset_container.Visible = true
			local tween_info = TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(preset_container, tween_info, {
				Size = UDim2.new(1, 18, 0, 80),
				GroupTransparency = 0
			}):Play()
			TweenService:Create(preset_inner, tween_info, {
				Position = UDim2.new(0, 0, 0, 0)
			}):Play()
		else
			local tween_info = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(preset_container, tween_info, {
				Size = UDim2.new(1, 18, 0, 0),
				GroupTransparency = 1
			}):Play()
			TweenService:Create(preset_inner, tween_info, {
				Position = UDim2.new(0, 0, 0, -25)
			}):Play()
			task.delay(0.55, function()
				if preset_anim_id == current_id and flags["custom_char_model_type"] ~= "Available" then
					preset_container.Visible = false
				end
			end)
		end
	end

	local note_tb = nil
	local last_selected_preset_id = nil

	local function restyle_preset_dropdown(dropdown_obj)
		if not dropdown_obj or not dropdown_obj.element_frame then return end
		dropdown_obj.element_frame.Position = UDim2.new(0, 0, 0, 0)
		dropdown_obj.element_frame.Size = UDim2.new(1, 0, 0, 12)
		for _, child in ipairs(dropdown_obj.element_frame:GetDescendants()) do
			if child:IsA("TextButton") and child.Parent:IsA("Frame") then
				local inline = child.Parent
				inline.Position = UDim2.new(0, 0, 0, 2)
				inline.Size = UDim2.new(1, 0, 0, 16)
			end
		end
	end

	local function handle_preset_selection(dropdown_obj, gender_key, val)
		local item = type(val) == "table" and val[1] or val
		if not item or item == "" then return end

		local id = tostring(item):match("%d+")
		if not id then return end
		last_selected_preset_id = id

		-- If note drawer is currently open, apply the active note tag to this character preset!
		-- The dropdown stays open so user can tag multiple items continuously.
		if note_drawer_open then
			local active_tag = get_active_tag()
			local updated_item = item
			if active_tag and active_tag ~= "" then
				updated_item = apply_tag_to_item(item, active_tag)
				save_char_note(id, active_tag)
				library:notification({ text = "🏷 Tagged [" .. active_tag .. "] to: " .. updated_item, time = 3 })
			else
				local bracket_part = item:match("^(.-%b[])")
				updated_item = bracket_part or item:match("^(.-)%s+%-%s+[^%-]+$") or item
				save_char_note(id, nil)
				library:notification({ text = "🗑 Removed note from: " .. updated_item, time = 3 })
			end

			for idx, itm in ipairs(dropdown_obj.items) do
				if tostring(itm):match("%d+") == id then
					dropdown_obj.items[idx] = updated_item
					break
				end
			end
			dropdown_obj:refresh_options(dropdown_obj.items)
			restyle_preset_dropdown(dropdown_obj)

			-- Re-open the dropdown so user can continue tagging more items
			task.defer(function()
				if note_drawer_open then
					dropdown_obj.open = true
					dropdown_obj.set_visible(true)
				end
			end)

			-- In tagging mode, don't load note into textbox or apply character
			return
		end

		if note_tb then
			local notes = load_char_notes()
			if notes[id] then
				note_tb.Text = notes[id]
			else
				note_tb.Text = ""
			end
		end

		if flags["custom_character"] and flags["custom_char_model_type"] == "Available" then
			apply_current_target(id)
		end
	end


	local id1_dropdown = custom_char_sec:dropdown({
		name = "ID 1 (Nam)",
		flag = "custom_char_id1",
		items = {
			"2909212097 [ixvail - Emo Boy]",
			"1981141314 [B3timesx - Da Hood Trench Boy]",
			"2241517565 [Aiokes - Slender Boy]",
			"2837492019 [Denis - Da Hood Street Boy]",
			"1849203847 [nilk - Casual Da Hood Boy]",
			"432168393 [vccaga - Da Hood Hoodie Boy]",
			"1284562089 [TuNutella - Streetwear Jacket]",
			"2039485721 [UDYX - Dark Trench Male]"
		},
		default = "2909212097 [ixvail - Emo Boy]",
		multi = false,
		callback = function(val)
			handle_preset_selection(id1_dropdown, "id1", val)
		end
	})
	id1_dropdown.element_frame.Parent = preset_inner
	restyle_preset_dropdown(id1_dropdown)

	local id2_dropdown = custom_char_sec:dropdown({
		name = "ID 2 (Nữ)",
		flag = "custom_char_id2",
		items = {
			"5361979849 [MOPKOBKA - Da Hood Star Crop]",
			"7330533246 [Bellaaa - Preppy Barbie]",
			"10542009861 [bellaandrew - Chibi Baddie]",
			"9639447735 [regretsmj - Da Hood Gothic Girl]",
			"1138506088 [0Sinay - Da Hood Y2K Baddie]",
			"3420846205 [Mia - Soft Da Hood E-Girl]",
			"2583272991 [Chloe - Y2K Pink Preppy]",
			"4491717904 [Kira - Grunge Aesthetic Girl]"
		},
		default = "7330533246 [Bellaaa - Preppy Barbie]",
		multi = false,
		callback = function(val)
			handle_preset_selection(id2_dropdown, "id2", val)
		end
	})
	id2_dropdown.element_frame.Parent = preset_inner
	restyle_preset_dropdown(id2_dropdown)

	-- 4. Orbit-Style Animated Custom ID Textbox Container - Initially Hidden
	local custom_anim_id = 0
	local custom_container = Instance.new("CanvasGroup")
	custom_container.Name = "CustomCharTextboxContainer"
	custom_container.BackgroundTransparency = 1
	custom_container.BorderSizePixel = 0
	custom_container.Size = UDim2.new(1, -26, 0, 0)
	custom_container.Visible = false
	custom_container.GroupTransparency = 1
	custom_container.Parent = custom_char_sec.holder

	local custom_inner = Instance.new("Frame")
	custom_inner.Name = "CustomInner"
	custom_inner.BackgroundTransparency = 1
	custom_inner.BorderSizePixel = 0
	custom_inner.Size = UDim2.new(1, 0, 0, 68)
	custom_inner.Position = UDim2.new(0, 0, 0, -20)
	custom_inner.Parent = custom_container

	local custom_layout = Instance.new("UIListLayout")
	custom_layout.Padding = UDim.new(0, 4)
	custom_layout.SortOrder = Enum.SortOrder.LayoutOrder
	custom_layout.Parent = custom_inner

	local sub_panel_open = false
	local del_sub_open = false

	local function get_custom_target_h()
		local h = 90
		if note_drawer_open then h = h + 26 end
		if sub_panel_open then h = h + 26 end
		if del_sub_open then h = h + 26 end
		return h
	end

	local update_custom_container_height

	set_custom_tb_visible = function(show)
		custom_anim_id = custom_anim_id + 1
		local current_id = custom_anim_id
		if show then
			custom_container.Visible = true
			local target_h = get_custom_target_h()
			local tween_info = TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(custom_container, tween_info, {
				Size = UDim2.new(1, -26, 0, target_h),
				GroupTransparency = 0
			}):Play()
			TweenService:Create(custom_inner, tween_info, {
				Size = UDim2.new(1, 0, 0, target_h),
				Position = UDim2.new(0, 0, 0, 0)
			}):Play()
		else
			local tween_info = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(custom_container, tween_info, {
				Size = UDim2.new(1, -26, 0, 0),
				GroupTransparency = 1
			}):Play()
			TweenService:Create(custom_inner, tween_info, {
				Position = UDim2.new(0, 0, 0, -20)
			}):Play()
			task.delay(0.55, function()
				if custom_anim_id == current_id and flags["custom_char_model_type"] ~= "Custom id" then
					custom_container.Visible = false
				end
			end)
		end
	end

	local custom_id_tb = custom_char_sec:textbox({
		placeholder = "Enter User ID (e.g. 2909212097)...",
		flag = "custom_char_userid",
		default = "",
		callback = function(val)
			if flags["custom_character"] and flags["custom_char_model_type"] == "Custom id" then
				local str = tostring(val):match("%d+")
				if str then
					apply_current_target(str)
				end
			end
		end
	})
	custom_id_tb.element_frame.Parent = custom_inner
	custom_id_tb.element_frame.Position = UDim2.new(0, 0, 0, 0)
	custom_id_tb.element_frame.Size = UDim2.new(1, 0, 0, 20)
	custom_id_tb.element_frame.BorderSizePixel = 0
	custom_id_tb.element_frame.BackgroundTransparency = 1
	local tb_inner = custom_id_tb.element_frame:FindFirstChildOfClass("TextBox")
	if tb_inner then
		tb_inner.Position = UDim2.new(0, 0, 0, 0)
		tb_inner.Size = UDim2.new(1, 0, 1, 0)
		tb_inner.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
		tb_inner.BorderColor3 = Color3.fromRGB(50, 50, 60)
		tb_inner.BorderSizePixel = 1
		tb_inner.TextColor3 = Color3.fromRGB(220, 220, 220)
		tb_inner.TextSize = 11
	end

	-- Collapsible Note Drawer for adding custom names/tags to IDs
	local note_holder = Instance.new("Frame")
	note_holder.Name = "CharNoteHolder"
	note_holder.BackgroundTransparency = 1
	note_holder.BorderSizePixel = 0
	note_holder.Size = UDim2.new(1, 0, 0, 18)
	note_holder.ClipsDescendants = true
	note_holder.Parent = custom_inner

	local note_toggle_btn = Instance.new("TextButton")
	note_toggle_btn.Name = "NoteToggleBtn"
	note_toggle_btn.Size = UDim2.new(1, 0, 0, 18)
	note_toggle_btn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
	note_toggle_btn.BorderColor3 = Color3.fromRGB(44, 44, 54)
	note_toggle_btn.BorderSizePixel = 1
	note_toggle_btn.Text = "✎ Note name (optional) ▼"
	note_toggle_btn.TextColor3 = Color3.fromRGB(180, 175, 140)
	note_toggle_btn.TextSize = 11
	note_toggle_btn.FontFace = library.font
	note_toggle_btn.AutoButtonColor = false
	note_toggle_btn.Parent = note_holder

	note_tb = Instance.new("TextBox")
	note_tb.Name = "NoteInputBox"
	note_tb.Size = UDim2.new(1, 0, 0, 20)
	note_tb.Position = UDim2.new(0, 0, 0, 22)
	note_tb.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	note_tb.BorderColor3 = Color3.fromRGB(55, 52, 44)
	note_tb.BorderSizePixel = 1
	note_tb.PlaceholderText = "Enter note for this ID..."
	note_tb.PlaceholderColor3 = Color3.fromRGB(110, 105, 95)
	note_tb.Text = ""
	note_tb.TextColor3 = Color3.fromRGB(245, 235, 180)
	note_tb.TextSize = 11
	note_tb.FontFace = library.font
	note_tb.ClearTextOnFocus = false
	note_tb.Parent = note_holder

	note_toggle_btn.MouseButton1Click:Connect(function()
		note_drawer_open = not note_drawer_open
		if note_drawer_open then
			note_toggle_btn.Text = "✎ Note name ▲"
			note_toggle_btn.BorderColor3 = Color3.fromRGB(90, 80, 50)
			note_toggle_btn.TextColor3 = Color3.fromRGB(255, 235, 150)
			TweenService:Create(note_holder, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, 44)
			}):Play()
		else
			note_toggle_btn.Text = "✎ Note name (optional) ▼"
			note_toggle_btn.BorderColor3 = Color3.fromRGB(44, 44, 54)
			note_toggle_btn.TextColor3 = Color3.fromRGB(180, 175, 140)
			TweenService:Create(note_holder, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, 18)
			}):Play()
		end
		if update_custom_container_height then
			update_custom_container_height()
		end
	end)

	note_tb.FocusLost:Connect(function(enter_pressed)
		local raw = flags["custom_char_userid"]
		local num_id = (raw and tostring(raw):match("%d+")) or last_selected_preset_id
		if num_id and note_tb.Text ~= "" and note_tb.Text ~= "Enter note for this ID..." then
			save_char_note(num_id, note_tb.Text)
			local updated = false
			for i, itm in ipairs(id1_dropdown.items) do
				if tostring(itm):match("%d+") == num_id then
					id1_dropdown.items[i] = apply_tag_to_item(itm, note_tb.Text)
					updated = true
				end
			end
			for i, itm in ipairs(id2_dropdown.items) do
				if tostring(itm):match("%d+") == num_id then
					id2_dropdown.items[i] = apply_tag_to_item(itm, note_tb.Text)
					updated = true
				end
			end
			if updated then
				id1_dropdown:refresh_options(id1_dropdown.items)
				restyle_preset_dropdown(id1_dropdown)
				id2_dropdown:refresh_options(id2_dropdown.items)
				restyle_preset_dropdown(id2_dropdown)
				library:notification({ text = "✔ Updated note: " .. note_tb.Text, time = 2.5 })
			end
		end
	end)

	local function load_saved_custom_char_ids()
		if isfile and isfile(custom_ids_save_file) and readfile then
			local ok, content = pcall(readfile, custom_ids_save_file)
			if ok and content and content ~= "" then
				local ok_decode, data = pcall(function() return game:GetService("HttpService"):JSONDecode(content) end)
				if ok_decode and type(data) == "table" then
					return data.id1 or {}, data.id2 or {}
				end
			end
		end
		return {}, {}
	end

	local function save_custom_char_id(gender_type, item_text)
		if not writefile then return end
		if isfolder and not isfolder(library.directory) then
			pcall(makefolder, library.directory)
		end
		local s1, s2 = load_saved_custom_char_ids()
		if gender_type == "id1" then
			if not table.find(s1, item_text) then table.insert(s1, item_text) end
		elseif gender_type == "id2" then
			if not table.find(s2, item_text) then table.insert(s2, item_text) end
		end
		local payload = ""
		pcall(function() payload = game:GetService("HttpService"):JSONEncode({ id1 = s1, id2 = s2 }) end)
		if payload ~= "" then
			pcall(function() writefile(custom_ids_save_file, payload) end)
		end
	end

	local function remove_custom_char_id(gender_type, item_text)
		if not writefile then return end
		if isfolder and not isfolder(library.directory) then
			pcall(makefolder, library.directory)
		end
		local s1, s2 = load_saved_custom_char_ids()
		local target_list = (gender_type == "id1") and s1 or s2
		local num = tostring(item_text):match("%d+")
		for i = #target_list, 1, -1 do
			if target_list[i] == item_text or (num and tostring(target_list[i]):match("%d+") == num) then
				table.remove(target_list, i)
			end
		end
		local payload = ""
		pcall(function() payload = game:GetService("HttpService"):JSONEncode({ id1 = s1, id2 = s2 }) end)
		if payload ~= "" then
			pcall(function() writefile(custom_ids_save_file, payload) end)
		end
	end

	-- Auto-load previously saved IDs & notes into dropdowns
	task.spawn(function()
		local init_s1, init_s2 = load_saved_custom_char_ids()
		for _, item in ipairs(init_s1) do
			if not table.find(id1_dropdown.items, item) then
				table.insert(id1_dropdown.items, item)
			end
		end

		for _, item in ipairs(init_s2) do
			if not table.find(id2_dropdown.items, item) then
				table.insert(id2_dropdown.items, item)
			end
		end

		-- Apply saved notes to all preset items
		local saved_notes = load_char_notes()
		for i, itm in ipairs(id1_dropdown.items) do
			local num = tostring(itm):match("%d+")
			if num and saved_notes[num] then
				id1_dropdown.items[i] = apply_tag_to_item(itm, saved_notes[num])
			end
		end
		for i, itm in ipairs(id2_dropdown.items) do
			local num = tostring(itm):match("%d+")
			if num and saved_notes[num] then
				id2_dropdown.items[i] = apply_tag_to_item(itm, saved_notes[num])
			end
		end

		id1_dropdown:refresh_options(id1_dropdown.items)
		restyle_preset_dropdown(id1_dropdown)

		id2_dropdown:refresh_options(id2_dropdown.items)
		restyle_preset_dropdown(id2_dropdown)
	end)

	-- Button "Add id to dropdown"
	local add_btn_holder = Instance.new("Frame")
	add_btn_holder.Name = "AddIdBtnHolder"
	add_btn_holder.BackgroundTransparency = 1
	add_btn_holder.BorderSizePixel = 0
	add_btn_holder.Size = UDim2.new(1, 0, 0, 20)
	add_btn_holder.Parent = custom_inner

	local add_toggle_btn = Instance.new("TextButton")
	add_toggle_btn.Name = "AddIdToggleBtn"
	add_toggle_btn.Size = UDim2.new(1, 0, 1, 0)
	add_toggle_btn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	add_toggle_btn.BorderColor3 = Color3.fromRGB(50, 50, 60)
	add_toggle_btn.BorderSizePixel = 1
	add_toggle_btn.Text = "Add id to dropdown ▼"
	add_toggle_btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	add_toggle_btn.TextSize = 11
	add_toggle_btn.FontFace = library.font
	add_toggle_btn.AutoButtonColor = false
	add_toggle_btn.Parent = add_btn_holder

	-- Sub-panel drawer containing ID 1 (Nam) & ID 2 (Nữ) for Add
	local sub_panel = Instance.new("Frame")
	sub_panel.Name = "AddIdSubPanel"
	sub_panel.BackgroundTransparency = 1
	sub_panel.BorderSizePixel = 0
	sub_panel.Size = UDim2.new(1, 0, 0, 0)
	sub_panel.ClipsDescendants = true
	sub_panel.Visible = false
	sub_panel.Parent = custom_inner

	local sub_layout = Instance.new("UIListLayout")
	sub_layout.FillDirection = Enum.FillDirection.Horizontal
	sub_layout.Padding = UDim.new(0, 4)
	sub_layout.SortOrder = Enum.SortOrder.LayoutOrder
	sub_layout.Parent = sub_panel

	local btn_add_id1 = Instance.new("TextButton")
	btn_add_id1.Name = "BtnAddID1"
	btn_add_id1.Size = UDim2.new(0.5, -2, 0, 22)
	btn_add_id1.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
	btn_add_id1.BorderColor3 = Color3.fromRGB(55, 55, 70)
	btn_add_id1.BorderSizePixel = 1
	btn_add_id1.Text = "ID 1 (Nam)"
	btn_add_id1.TextColor3 = Color3.fromRGB(180, 205, 255)
	btn_add_id1.TextSize = 11
	btn_add_id1.FontFace = library.font
	btn_add_id1.AutoButtonColor = false
	btn_add_id1.Parent = sub_panel

	local btn_add_id2 = Instance.new("TextButton")
	btn_add_id2.Name = "BtnAddID2"
	btn_add_id2.Size = UDim2.new(0.5, -2, 0, 22)
	btn_add_id2.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
	btn_add_id2.BorderColor3 = Color3.fromRGB(55, 55, 70)
	btn_add_id2.BorderSizePixel = 1
	btn_add_id2.Text = "ID 2 (Nữ)"
	btn_add_id2.TextColor3 = Color3.fromRGB(255, 180, 215)
	btn_add_id2.TextSize = 11
	btn_add_id2.FontFace = library.font
	btn_add_id2.AutoButtonColor = false
	btn_add_id2.Parent = sub_panel

	-- Button "Delete id dropdown"
	local del_btn_holder = Instance.new("Frame")
	del_btn_holder.Name = "DelIdBtnHolder"
	del_btn_holder.BackgroundTransparency = 1
	del_btn_holder.BorderSizePixel = 0
	del_btn_holder.Size = UDim2.new(1, 0, 0, 20)
	del_btn_holder.Parent = custom_inner

	local del_toggle_btn = Instance.new("TextButton")
	del_toggle_btn.Name = "DelIdToggleBtn"
	del_toggle_btn.Size = UDim2.new(1, 0, 1, 0)
	del_toggle_btn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	del_toggle_btn.BorderColor3 = Color3.fromRGB(65, 45, 50)
	del_toggle_btn.BorderSizePixel = 1
	del_toggle_btn.Text = "Delete id dropdown ▼"
	del_toggle_btn.TextColor3 = Color3.fromRGB(215, 175, 180)
	del_toggle_btn.TextSize = 11
	del_toggle_btn.FontFace = library.font
	del_toggle_btn.AutoButtonColor = false
	del_toggle_btn.Parent = del_btn_holder

	-- Sub-panel drawer containing ID 1 (Nam) & ID 2 (Nữ) for Delete
	local del_sub_panel = Instance.new("Frame")
	del_sub_panel.Name = "DelIdSubPanel"
	del_sub_panel.BackgroundTransparency = 1
	del_sub_panel.BorderSizePixel = 0
	del_sub_panel.Size = UDim2.new(1, 0, 0, 0)
	del_sub_panel.ClipsDescendants = true
	del_sub_panel.Visible = false
	del_sub_panel.Parent = custom_inner

	local del_sub_layout = Instance.new("UIListLayout")
	del_sub_layout.FillDirection = Enum.FillDirection.Horizontal
	del_sub_layout.Padding = UDim.new(0, 4)
	del_sub_layout.SortOrder = Enum.SortOrder.LayoutOrder
	del_sub_layout.Parent = del_sub_panel

	local btn_del_id1 = Instance.new("TextButton")
	btn_del_id1.Name = "BtnDelID1"
	btn_del_id1.Size = UDim2.new(0.5, -2, 0, 22)
	btn_del_id1.BackgroundColor3 = Color3.fromRGB(40, 30, 32)
	btn_del_id1.BorderColor3 = Color3.fromRGB(75, 45, 50)
	btn_del_id1.BorderSizePixel = 1
	btn_del_id1.Text = "ID 1 (Nam)"
	btn_del_id1.TextColor3 = Color3.fromRGB(255, 140, 140)
	btn_del_id1.TextSize = 11
	btn_del_id1.FontFace = library.font
	btn_del_id1.AutoButtonColor = false
	btn_del_id1.Parent = del_sub_panel

	local btn_del_id2 = Instance.new("TextButton")
	btn_del_id2.Name = "BtnDelID2"
	btn_del_id2.Size = UDim2.new(0.5, -2, 0, 22)
	btn_del_id2.BackgroundColor3 = Color3.fromRGB(40, 30, 32)
	btn_del_id2.BorderColor3 = Color3.fromRGB(75, 45, 50)
	btn_del_id2.BorderSizePixel = 1
	btn_del_id2.Text = "ID 2 (Nữ)"
	btn_del_id2.TextColor3 = Color3.fromRGB(255, 140, 180)
	btn_del_id2.TextSize = 11
	btn_del_id2.FontFace = library.font
	btn_del_id2.AutoButtonColor = false
	btn_del_id2.Parent = del_sub_panel

	update_custom_container_height = function()
		if flags["custom_char_model_type"] == "Custom id" then
			local target_h = get_custom_target_h()
			custom_inner.Size = UDim2.new(1, 0, 0, target_h)
			TweenService:Create(custom_container, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, -26, 0, target_h)
			}):Play()
		end
	end

	-- Hover effects for toggle buttons
	add_toggle_btn.MouseEnter:Connect(function()
		add_toggle_btn.BorderColor3 = Color3.fromRGB(80, 80, 100)
		if not sub_panel_open then
			add_toggle_btn.TextColor3 = Color3.fromRGB(240, 240, 240)
		end
	end)
	add_toggle_btn.MouseLeave:Connect(function()
		add_toggle_btn.BorderColor3 = Color3.fromRGB(50, 50, 60)
		if not sub_panel_open then
			add_toggle_btn.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end)

	del_toggle_btn.MouseEnter:Connect(function()
		del_toggle_btn.BorderColor3 = Color3.fromRGB(100, 50, 60)
		if not del_sub_open then
			del_toggle_btn.TextColor3 = Color3.fromRGB(255, 140, 150)
		end
	end)
	del_toggle_btn.MouseLeave:Connect(function()
		del_toggle_btn.BorderColor3 = Color3.fromRGB(65, 45, 50)
		if not del_sub_open then
			del_toggle_btn.TextColor3 = Color3.fromRGB(215, 175, 180)
		end
	end)

	-- Hover effects for sub buttons
	btn_add_id1.MouseEnter:Connect(function() btn_add_id1.BackgroundColor3 = Color3.fromRGB(45, 45, 58) end)
	btn_add_id1.MouseLeave:Connect(function() btn_add_id1.BackgroundColor3 = Color3.fromRGB(36, 36, 44) end)
	btn_add_id2.MouseEnter:Connect(function() btn_add_id2.BackgroundColor3 = Color3.fromRGB(45, 45, 58) end)
	btn_add_id2.MouseLeave:Connect(function() btn_add_id2.BackgroundColor3 = Color3.fromRGB(36, 36, 44) end)

	btn_del_id1.MouseEnter:Connect(function() btn_del_id1.BackgroundColor3 = Color3.fromRGB(55, 38, 42) end)
	btn_del_id1.MouseLeave:Connect(function() btn_del_id1.BackgroundColor3 = Color3.fromRGB(40, 30, 32) end)
	btn_del_id2.MouseEnter:Connect(function() btn_del_id2.BackgroundColor3 = Color3.fromRGB(55, 38, 42) end)
	btn_del_id2.MouseLeave:Connect(function() btn_del_id2.BackgroundColor3 = Color3.fromRGB(40, 30, 32) end)

	add_toggle_btn.MouseButton1Click:Connect(function()
		sub_panel_open = not sub_panel_open
		if sub_panel_open then
			if del_sub_open then
				del_sub_open = false
				del_toggle_btn.Text = "Delete id dropdown ▼"
				del_toggle_btn.TextColor3 = Color3.fromRGB(215, 175, 180)
				local tw_close = TweenService:Create(del_sub_panel, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, 0)
				})
				tw_close:Play()
				tw_close.Completed:Connect(function()
					if not del_sub_open then del_sub_panel.Visible = false end
				end)
			end
			add_toggle_btn.Text = "Add id to dropdown ▲"
			add_toggle_btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			sub_panel.Visible = true
			TweenService:Create(sub_panel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, 22)
			}):Play()
		else
			add_toggle_btn.Text = "Add id to dropdown ▼"
			add_toggle_btn.TextColor3 = Color3.fromRGB(200, 200, 200)
			local tw = TweenService:Create(sub_panel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, 0)
			})
			tw:Play()
			tw.Completed:Connect(function()
				if not sub_panel_open then sub_panel.Visible = false end
			end)
		end
		update_custom_container_height()
	end)

	del_toggle_btn.MouseButton1Click:Connect(function()
		del_sub_open = not del_sub_open
		if del_sub_open then
			if sub_panel_open then
				sub_panel_open = false
				add_toggle_btn.Text = "Add id to dropdown ▼"
				add_toggle_btn.TextColor3 = Color3.fromRGB(200, 200, 200)
				local tw_close = TweenService:Create(sub_panel, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, 0)
				})
				tw_close:Play()
				tw_close.Completed:Connect(function()
					if not sub_panel_open then sub_panel.Visible = false end
				end)
			end
			del_toggle_btn.Text = "Delete id dropdown ▲"
			del_toggle_btn.TextColor3 = Color3.fromRGB(255, 120, 130)
			del_sub_panel.Visible = true
			TweenService:Create(del_sub_panel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, 22)
			}):Play()
		else
			del_toggle_btn.Text = "Delete id dropdown ▼"
			del_toggle_btn.TextColor3 = Color3.fromRGB(215, 175, 180)
			local tw = TweenService:Create(del_sub_panel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, 0)
			})
			tw:Play()
			tw.Completed:Connect(function()
				if not del_sub_open then del_sub_panel.Visible = false end
			end)
		end
		update_custom_container_height()
	end)

	local function handle_add_custom_id(target_dropdown, target_label, key)
		local raw = flags["custom_char_userid"]
		local num_id = raw and tostring(raw):match("%d+")
		if not num_id or num_id == "" then
			library:notification({ text = "Please enter a valid User ID in the textbox!", time = 3 })
			return
		end

		task.spawn(function()
			local username = "Custom"
			pcall(function()
				username = Players:GetNameFromUserIdAsync(tonumber(num_id))
			end)
			local item_str = string.format("%s [%s]", num_id, username)
			local current_note = (note_tb and note_tb.Text ~= "" and note_tb.Text ~= "Enter note for this ID...") and note_tb.Text or nil
			if current_note then
				item_str = apply_tag_to_item(item_str, current_note)
				save_char_note(num_id, current_note)
			end
			if not table.find(target_dropdown.items, item_str) then
				table.insert(target_dropdown.items, item_str)
				target_dropdown:refresh_options(target_dropdown.items)
				restyle_preset_dropdown(target_dropdown)
				save_custom_char_id(key, item_str)
				library:notification({ text = "✔ Added to " .. target_label .. ": " .. item_str, time = 3.5 })
			else
				library:notification({ text = "ℹ " .. item_str .. " already exists in " .. target_label, time = 3 })
			end
		end)
	end

	local function handle_delete_custom_id(target_dropdown, target_label, key)
		local raw = flags["custom_char_userid"]
		local num_id = raw and tostring(raw):match("%d+")
		local item_to_remove = nil
		local idx_to_remove = nil

		if num_id and num_id ~= "" then
			for idx, itm in ipairs(target_dropdown.items) do
				if tostring(itm):match("%d+") == num_id then
					item_to_remove = itm
					idx_to_remove = idx
					break
				end
			end
		end

		if not item_to_remove then
			local current_sel = (key == "id1") and flags["custom_char_id1"] or flags["custom_char_id2"]
			if type(current_sel) == "table" then current_sel = current_sel[1] end
			if current_sel then
				for idx, itm in ipairs(target_dropdown.items) do
					if itm == current_sel or (num_id and tostring(itm):match("%d+") == num_id) then
						item_to_remove = itm
						idx_to_remove = idx
						break
					end
				end
			end
		end

		if item_to_remove and idx_to_remove then
			table.remove(target_dropdown.items, idx_to_remove)
			target_dropdown:refresh_options(target_dropdown.items)
			restyle_preset_dropdown(target_dropdown)
			if target_dropdown.set then
				target_dropdown.set(target_dropdown.items[1] or "")
			end
			remove_custom_char_id(key, item_to_remove)
			library:notification({ text = "🗑 Deleted from " .. target_label .. ": " .. item_to_remove, time = 3 })
		else
			library:notification({ text = "⚠ ID not found in " .. target_label .. "!", time = 3 })
		end
	end

	btn_add_id1.MouseButton1Click:Connect(function()
		handle_add_custom_id(id1_dropdown, "ID 1 (Nam)", "id1")
	end)

	btn_add_id2.MouseButton1Click:Connect(function()
		handle_add_custom_id(id2_dropdown, "ID 2 (Nữ)", "id2")
	end)

	btn_del_id1.MouseButton1Click:Connect(function()
		handle_delete_custom_id(id1_dropdown, "ID 1 (Nam)", "id1")
	end)

	btn_del_id2.MouseButton1Click:Connect(function()
		handle_delete_custom_id(id2_dropdown, "ID 2 (Nữ)", "id2")
	end)

	-- 5. Animated File Container for .rbm Files
	local file_anim_id = 0
	local file_container = Instance.new("CanvasGroup")
	file_container.Name = "CustomCharFileContainer"
	file_container.BackgroundTransparency = 1
	file_container.BorderSizePixel = 0
	file_container.Position = UDim2.new(0, -6, 0, 0)
	file_container.Size = UDim2.new(1, 18, 0, 0)
	file_container.Visible = false
	file_container.GroupTransparency = 1
	file_container.Parent = custom_char_sec.holder

	local file_inner = Instance.new("Frame")
	file_inner.Name = "FileInner"
	file_inner.BackgroundTransparency = 1
	file_inner.BorderSizePixel = 0
	file_inner.Size = UDim2.new(1, 0, 0, 52)
	file_inner.Position = UDim2.new(0, 0, 0, -20)
	file_inner.Parent = file_container

	local file_layout = Instance.new("UIListLayout")
	file_layout.Padding = UDim.new(0, 4)
	file_layout.SortOrder = Enum.SortOrder.LayoutOrder
	file_layout.Parent = file_inner

	set_file_container_visible = function(show)
		file_anim_id = file_anim_id + 1
		local current_id = file_anim_id
		if show then
			file_container.Visible = true
			local tween_info = TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(file_container, tween_info, {
				Size = UDim2.new(1, 18, 0, 52),
				GroupTransparency = 0
			}):Play()
			TweenService:Create(file_inner, tween_info, {
				Position = UDim2.new(0, 0, 0, 0)
			}):Play()
		else
			local tween_info = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(file_container, tween_info, {
				Size = UDim2.new(1, 18, 0, 0),
				GroupTransparency = 1
			}):Play()
			TweenService:Create(file_inner, tween_info, {
				Position = UDim2.new(0, 0, 0, -20)
			}):Play()
			task.delay(0.55, function()
				if file_anim_id == current_id and flags["custom_char_model_type"] ~= "File" then
					file_container.Visible = false
				end
			end)
		end
	end

	local file_dropdown = custom_char_sec:dropdown({
		name = "File (.rbm)",
		flag = "custom_char_selected_file",
		items = get_available_rbm_files(),
		default = default_rbm_presets[1],
		multi = false,
		callback = function(val)
			local chosen = type(val) == "table" and val[1] or val
			if chosen and flags["custom_character"] and flags["custom_char_model_type"] == "File" then
				apply_current_target()
			end
		end
	})
	file_dropdown.element_frame.Parent = file_inner
	restyle_preset_dropdown(file_dropdown)

	-- Refresh files action button
	local file_action_holder = Instance.new("Frame")
	file_action_holder.Name = "FileActionHolder"
	file_action_holder.BackgroundTransparency = 1
	file_action_holder.BorderSizePixel = 0
	file_action_holder.Size = UDim2.new(1, 0, 0, 20)
	file_action_holder.Parent = file_inner

	local btn_refresh_files = Instance.new("TextButton")
	btn_refresh_files.Name = "BtnRefreshFiles"
	btn_refresh_files.Size = UDim2.new(1, 0, 1, 0)
	btn_refresh_files.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	btn_refresh_files.BorderColor3 = Color3.fromRGB(50, 50, 65)
	btn_refresh_files.BorderSizePixel = 1
	btn_refresh_files.Text = "Refresh files ↻"
	btn_refresh_files.TextColor3 = Color3.fromRGB(180, 200, 240)
	btn_refresh_files.TextSize = 11
	btn_refresh_files.FontFace = library.font
	btn_refresh_files.AutoButtonColor = false
	btn_refresh_files.Parent = file_action_holder

	btn_refresh_files.MouseEnter:Connect(function()
		btn_refresh_files.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
		btn_refresh_files.TextColor3 = Color3.fromRGB(220, 235, 255)
	end)
	btn_refresh_files.MouseLeave:Connect(function()
		btn_refresh_files.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
		btn_refresh_files.TextColor3 = Color3.fromRGB(180, 200, 240)
	end)
	btn_refresh_files.MouseButton1Click:Connect(function()
		local updated_files = get_available_rbm_files()
		file_dropdown.items = updated_files
		file_dropdown:refresh_options(updated_files)
		restyle_preset_dropdown(file_dropdown)
		table.clear(desc_cache)
		library:notification({ text = "↻ Refreshed .rbm files list (" .. #updated_files .. " found)", time = 2.5 })
	end)

	-- =========================================================================
	-- KORBLOX (HIGH-FIDELITY RESTORATION ENGINE - ZERO BLOATING)
	-- =========================================================================
	local pre_korblox_leg_state = nil

	local function setRigAttachment(part, attName, cf)
		if not part then return end
		local a = part:FindFirstChild(attName)
		if not a then
			a = Instance.new("Attachment", part)
			a.Name = attName
		end
		a.CFrame = cf
	end

	local function do_korblox(bool)
		local char = LocalPlayer.Character
		if not char then return end

		local rul = char:FindFirstChild("RightUpperLeg")
		local rll = char:FindFirstChild("RightLowerLeg")
		local rf = char:FindFirstChild("RightFoot")
		local r6_rl = char:FindFirstChild("Right Leg")

		if rul and rll and rf then
			if bool then
				local function snapshot_part(part)
					local atts = {}
					for _, a in ipairs(part:GetChildren()) do
						if a:IsA("Attachment") then
							atts[a.Name] = a.CFrame
						end
					end
					return {
						meshId = part.MeshId,
						textureId = part.TextureID,
						size = part.Size,
						transparency = part.Transparency,
						attachments = atts,
					}
				end

				-- Snapshot current leg state (supports Default avatar, Man, Woman, or custom packages!)
				if not pre_korblox_leg_state then
					pre_korblox_leg_state = {
						RightUpperLeg = snapshot_part(rul),
						RightLowerLeg = snapshot_part(rll),
						RightFoot = snapshot_part(rf),
					}
				end

				-- Apply Official Korblox Right Leg Mesh, Texture, Size & Attachments
				rul.MeshId = "rbxassetid://9598310133"
				rul.TextureID = "rbxassetid://902843398"
				rul.Transparency = 0
				rul.Size = Vector3.new(0.314232, 0.8622, 0.39055)

				rll.MeshId = "rbxassetid://9598310138"
				rll.TextureID = "rbxassetid://902843398"
				rll.Transparency = 1
				rll.Size = Vector3.new(0.350067, 0.596516, 0.299322)

				rf.MeshId = "rbxassetid://9598310128"
				rf.TextureID = "rbxassetid://902843398"
				rf.Transparency = 1
				rf.Size = Vector3.new(0.263557, 0.263558, 0.263558)

				local origRul = rul:FindFirstChild("OriginalSize")
				if origRul and origRul:IsA("Vector3Value") then origRul.Value = rul.Size end
				local origRll = rll:FindFirstChild("OriginalSize")
				if origRll and origRll:IsA("Vector3Value") then origRll.Value = rll.Size end
				local origRf = rf:FindFirstChild("OriginalSize")
				if origRf and origRf:IsA("Vector3Value") then origRf.Value = rf.Size end

				setRigAttachment(rul, "RightHipRigAttachment", CFrame.new(0.018765986, 0.241751954, 0.0299788769))
				setRigAttachment(rul, "RightKneeRigAttachment", CFrame.new(0.116765976, -0.703246176, -0.107915573))

				setRigAttachment(rll, "RightKneeRigAttachment", CFrame.new(0.0102564692, 0.264691859, -0.0670935661))
				setRigAttachment(rll, "RightAnkleRigAttachment", CFrame.new(0.0102564692, -0.66163975, 0.059778627))

				setRigAttachment(rf, "RightAnkleRigAttachment", CFrame.new(5.96046448e-08, 0, -1.92848966e-05))
				setRigAttachment(rf, "RightFootAttachment", CFrame.new(5.96046448e-08, -0.251945049, -0.000109526329))

				align_joints(char)
			else
				local legParts = { "RightUpperLeg", "RightLowerLeg", "RightFoot" }
				for _, partName in ipairs(legParts) do
					local part = char:FindFirstChild(partName)
					local saved = (pre_korblox_leg_state and pre_korblox_leg_state[partName])
						or (default_avatar_state.limbs and default_avatar_state.limbs[partName])

					if part and part:IsA("MeshPart") and saved then
						part.MeshId = saved.meshId or ""
						part.TextureID = saved.textureId or ""
						if saved.size then
							part.Size = saved.size
							local orig = part:FindFirstChild("OriginalSize")
							if orig and orig:IsA("Vector3Value") then
								orig.Value = saved.size
							end
						end
						if saved.attachments then
							for attName, cf in pairs(saved.attachments) do
								setRigAttachment(part, attName, cf)
							end
						end
						part.Transparency = saved.transparency or 0
					end
				end
				pre_korblox_leg_state = nil

				-- If custom character is active and had a custom RightLeg package (e.g. Woman / Man), re-sync cleanly
				if flags["custom_character"] and active_custom_desc and active_custom_desc.RightLeg and active_custom_desc.RightLeg > 0 then
					task.spawn(function()
						local res = cached_get_obj(active_custom_desc.RightLeg)
						if not char or not char.Parent then return end
						if res and #res > 0 then
							local container = res[1]
							for _, child in ipairs(container:GetChildren()) do
								if child:IsA("MeshPart") then
									local charPart = char:FindFirstChild(child.Name)
									if charPart and charPart:IsA("MeshPart") then
										charPart.MeshId = child.MeshId
										charPart.TextureID = child.TextureID
										charPart.Size = child.Size
										local orig = charPart:FindFirstChild("OriginalSize")
										if orig and orig:IsA("Vector3Value") then orig.Value = child.Size end
										for _, att in ipairs(child:GetChildren()) do
											if att:IsA("Attachment") then
												setRigAttachment(charPart, att.Name, att.CFrame)
											end
										end
										charPart.Transparency = 0
									end
								end
							end
							align_joints(char)
						end
					end)
				end

				local cm = char:FindFirstChild("KorbloxCharacterMesh")
				if cm then cm:Destroy() end

				align_joints(char)
			end
		elseif r6_rl then
			if bool then
				local cm = char:FindFirstChild("KorbloxCharacterMesh") or Instance.new("CharacterMesh")
				cm.Name = "KorbloxCharacterMesh"
				cm.BodyPart = Enum.BodyPart.RightLeg
				cm.MeshId = 101851696
				cm.OverlayTextureId = 902843398
				cm.Parent = char
			else
				local cm = char:FindFirstChild("KorbloxCharacterMesh")
				if cm then cm:Destroy() end
			end
		end
	end

	custom_char_sec:toggle({
		name = "Korblox",
		flag = "misc_korblox",
		default = false,
		callback = function(val)
			do_korblox(val)
		end
	})

	-- Persistent Accessory Adder System (Emote-styled design)
	local CUSTOM_ACC_FILE = "neverlose_custom_accessories.json"
	local popular_accessories = {
		["Valkyrie Helm"] = "13655554",
		["Dominus Infernus"] = "21070012",
		["Dominus Frigidus"] = "96103379",
		["Dominus Astra"] = "162067148",
		["Clockwork's Headphones"] = "14815761",
		["Silver King of the Night"] = "49429114",
		["Void Sword"] = "20419356",
		["Black Iron Horns"] = "215718515",
	}
	local popular_accessories_list = {
		"Valkyrie Helm",
		"Dominus Infernus",
		"Dominus Frigidus",
		"Dominus Astra",
		"Clockwork's Headphones",
		"Silver King of the Night",
		"Void Sword",
		"Black Iron Horns",
	}
	local custom_accessories_dict = {}
	local equipped_accessory_instances = {}
	local active_equipped_ids = {}

	local function save_custom_accessories_to_file()
		pcall(function()
			if not writefile then return end
			local enc = HttpService:JSONEncode(custom_accessories_dict)
			writefile(CUSTOM_ACC_FILE, enc)
		end)
	end

	local function load_custom_accessories_from_file()
		pcall(function()
			if not (isfile and isfile(CUSTOM_ACC_FILE) and readfile) then return end
			local raw = readfile(CUSTOM_ACC_FILE)
			if not raw or raw == "" then return end
			local data = HttpService:JSONDecode(raw)
			if type(data) == "table" then
				for name, id in pairs(data) do
					if type(name) == "string" and type(id) == "string" and name ~= "" and id ~= "" then
						custom_accessories_dict[name] = id
						popular_accessories[name] = id
						if not table.find(popular_accessories_list, name) then
							table.insert(popular_accessories_list, name)
						end
					end
				end
			end
		end)
	end
	load_custom_accessories_from_file()

	local function remove_all_added_accessories()
		for id, inst in pairs(equipped_accessory_instances) do
			if inst and inst.Parent then
				pcall(function() inst:Destroy() end)
			end
		end
		table.clear(equipped_accessory_instances)
		local char = LocalPlayer.Character
		if char then
			for _, item in ipairs(char:GetChildren()) do
				if item:IsA("Accessory") and item:GetAttribute("NVL_Accessory") then
					pcall(function() item:Destroy() end)
				end
			end
		end
	end

	local accessory_asset_cache = {}

	local function get_accessory_prototype(asset_id)
		local num = tostring(asset_id):match("%d+")
		if not num then return nil end

		if accessory_asset_cache[num] and accessory_asset_cache[num].Parent == nil then
			return accessory_asset_cache[num]
		end

		local function find_acc_recursive(root)
			if not root then return nil end
			if root:IsA("Accessory") then return root end
			for _, child in ipairs(root:GetChildren()) do
				local r = find_acc_recursive(child)
				if r then return r end
			end
			return nil
		end

		local found_acc = nil

		-- Method 1: game:GetObjects
		pcall(function()
			local objects = game:GetObjects("rbxassetid://" .. num)
			if objects and #objects > 0 then
				for _, obj in ipairs(objects) do
					local a = find_acc_recursive(obj)
					if a then
						found_acc = a:Clone()
						break
					end
				end
			end
		end)

		-- Method 2: InsertService:LoadAsset
		if not found_acc then
			pcall(function()
				local model = InsertService:LoadAsset(tonumber(num))
				if model then
					local a = find_acc_recursive(model)
					if a then
						found_acc = a:Clone()
					end
					pcall(function() model:Destroy() end)
				end
			end)
		end

		if found_acc then
			found_acc.Parent = nil
			accessory_asset_cache[num] = found_acc
			return found_acc
		end

		return nil
	end

	local function attach_custom_accessory(asset_id)
		local char = LocalPlayer.Character
		if not char then return nil end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		local head = char:FindFirstChild("Head")

		local proto = get_accessory_prototype(asset_id)
		if not proto then return nil end

		local clone = proto:Clone()
		local id_str = tostring(asset_id):match("%d+") or tostring(asset_id)
		clone.Name = "NVL_Acc_" .. id_str
		clone:SetAttribute("NVL_Accessory", true)
		clone:SetAttribute("NVL_Accessory_ID", id_str)

		local handle = clone:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			handle.CanCollide = false
			handle.Massless = true

			local att = handle:FindFirstChildOfClass("Attachment")
			local targetAtt = nil
			if att then
				for _, part in ipairs(char:GetChildren()) do
					if part:IsA("BasePart") then
						local found = part:FindFirstChild(att.Name)
						if found and found:IsA("Attachment") then
							targetAtt = found
							break
						end
					end
				end
			end

			if humanoid then
				humanoid:AddAccessory(clone)
			else
				clone.Parent = char
			end

			if att and targetAtt then
				handle.CFrame = targetAtt.Parent.CFrame * targetAtt.CFrame * att.CFrame:Inverse()
				local weld = Instance.new("Weld")
				weld.Name = "AccessoryWeld"
				weld.Part0 = handle
				weld.Part1 = targetAtt.Parent
				weld.C0 = att.CFrame
				weld.C1 = targetAtt.CFrame
				weld.Parent = handle
			elseif head then
				handle.CFrame = head.CFrame * CFrame.new(0, 0.6, 0)
				local weld = Instance.new("Weld")
				weld.Name = "AccessoryWeld"
				weld.Part0 = handle
				weld.Part1 = head
				weld.C0 = CFrame.new(0, -0.6, 0)
				weld.C1 = CFrame.new()
				weld.Parent = handle
			end
		else
			if humanoid then
				humanoid:AddAccessory(clone)
			else
				clone.Parent = char
			end
		end

		return clone
	end

	local function sync_equipped_accessories()
		if not flags["misc_accessory_adder"] then
			remove_all_added_accessories()
			return
		end

		local selected = flags["misc_accessory_list"]
		local desired_ids = {}

		if type(selected) == "table" then
			for _, name in ipairs(selected) do
				local id = popular_accessories[name]
				if id then
					local num = tostring(id):match("%d+")
					if num then
						desired_ids[num] = name
					end
				end
			end
		elseif type(selected) == "string" and selected ~= "" then
			local id = popular_accessories[selected]
			if id then
				local num = tostring(id):match("%d+")
				if num then
					desired_ids[num] = selected
				end
			end
		end

		-- 1. Remove accessories that are no longer selected
		for id, inst in pairs(equipped_accessory_instances) do
			if not desired_ids[id] then
				if inst and inst.Parent then
					pcall(function() inst:Destroy() end)
				end
				equipped_accessory_instances[id] = nil
				active_equipped_ids[id] = nil
			end
		end

		-- 2. Equip all newly selected accessories simultaneously
		for id, name in pairs(desired_ids) do
			active_equipped_ids[id] = true
			if not equipped_accessory_instances[id] or not equipped_accessory_instances[id].Parent then
				local inst = attach_custom_accessory(id)
				if inst then
					equipped_accessory_instances[id] = inst
				end
			end
		end
	end

	custom_char_sec:toggle({
		name = "Accessory adder",
		flag = "misc_accessory_adder",
		default = false,
		callback = function(val)
			if val then
				sync_equipped_accessories()
			else
				remove_all_added_accessories()
			end
		end
	})

	local acc_dropdown = nil

	acc_dropdown = custom_char_sec:dropdown({
		name = "Accessories (Multi-Select)",
		flag = "misc_accessory_list",
		items = popular_accessories_list,
		multi = true,
		default = { "Valkyrie Helm" },
		callback = function(val)
			sync_equipped_accessories()
		end
	})

	custom_char_sec:textbox({
		flag = "misc_custom_acc_name",
		placeholder = "Custom Hat Name (Optional, auto-detects)",
		default = "",
	})

	custom_char_sec:textbox({
		flag = "misc_custom_acc_id",
		placeholder = "Enter Hat / Asset ID (e.g. 13655554)",
		default = "13655554",
	})

	custom_char_sec:button({
		name = "Add Accessory To Dropdown",
		callback = function()
			local input = flags["misc_custom_acc_id"] or "13655554"
			local id_num = tostring(input):match("%d+")
			if not id_num then
				library:notification({ text = "⚠ Please enter a valid ID!", time = 3 })
				return
			end

			local name_input = flags["misc_custom_acc_name"]
			local acc_name
			if name_input and name_input:gsub("%s+", "") ~= "" then
				acc_name = name_input:match("^%s*(.-)%s*$")
			else
				local fetchOk, fetchInfo = pcall(function()
					return MarketplaceService:GetProductInfo(tonumber(id_num))
				end)
				if fetchOk and fetchInfo and fetchInfo.Name and fetchInfo.Name ~= "" then
					acc_name = fetchInfo.Name:match("^%s*(.-)%s*$")
				else
					acc_name = "Accessory " .. id_num
				end
			end

			popular_accessories[acc_name] = id_num
			custom_accessories_dict[acc_name] = id_num
			if not table.find(popular_accessories_list, acc_name) then
				table.insert(popular_accessories_list, acc_name)
			end

			save_custom_accessories_to_file()

			-- Refresh dropdown and add to current multi-selection
			local cur_selected = flags["misc_accessory_list"]
			local new_selected = {}
			if type(cur_selected) == "table" then
				for _, v in ipairs(cur_selected) do table.insert(new_selected, v) end
			elseif type(cur_selected) == "string" and cur_selected ~= "" then
				table.insert(new_selected, cur_selected)
			end
			if not table.find(new_selected, acc_name) then
				table.insert(new_selected, acc_name)
			end

			if acc_dropdown and acc_dropdown.refresh_options then
				acc_dropdown:refresh_options(popular_accessories_list)
				acc_dropdown.set(new_selected)
			end

			sync_equipped_accessories()
			library:notification({ text = "🎩 Added & Equipped: " .. acc_name, time = 2.5 })
		end
	})

	custom_char_sec:button({
		name = "Equip All Selected",
		callback = function()
			if not flags["misc_accessory_adder"] then
				flags["misc_accessory_adder"] = true
			end
			sync_equipped_accessories()
			library:notification({ text = "✅ Synchronized all selected accessories!", time = 2 })
		end
	})

	custom_char_sec:button({
		name = "Delete Custom Accessory",
		callback = function()
			local cur_sel = flags["misc_accessory_list"]
			local to_delete = {}

			if type(cur_sel) == "table" then
				for _, item in ipairs(cur_sel) do
					if custom_accessories_dict[item] then
						table.insert(to_delete, item)
					end
				end
			elseif type(cur_sel) == "string" and custom_accessories_dict[cur_sel] then
				table.insert(to_delete, cur_sel)
			end

			if #to_delete == 0 then
				library:notification({ text = "⚠ No custom accessory selected to delete!", time = 2.5 })
				return
			end

			for _, item in ipairs(to_delete) do
				custom_accessories_dict[item] = nil
				popular_accessories[item] = nil
				local idx = table.find(popular_accessories_list, item)
				if idx then
					table.remove(popular_accessories_list, idx)
				end
			end
			save_custom_accessories_to_file()

			local remaining_selected = {}
			if type(cur_sel) == "table" then
				for _, item in ipairs(cur_sel) do
					if not table.find(to_delete, item) then
						table.insert(remaining_selected, item)
					end
				end
			end

			if acc_dropdown and acc_dropdown.refresh_options then
				acc_dropdown:refresh_options(popular_accessories_list)
				acc_dropdown.set(remaining_selected)
			end
			sync_equipped_accessories()
			library:notification({ text = "🗑 Deleted " .. #to_delete .. " custom accessory(ies)!", time = 2.5 })
		end
	})

	custom_char_sec:button({
		name = "Clear All Accessories",
		callback = function()
			if acc_dropdown and acc_dropdown.set then
				acc_dropdown.set({})
			end
			table.clear(active_equipped_ids)
			remove_all_added_accessories()
			library:notification({ text = "🧹 Cleared all added accessories!", time = 2 })
		end
	})

	-- Re-apply on character respawn
	table.insert(_nvl_conns, LocalPlayer.CharacterAdded:Connect(function(char)
		task.wait(0.4)
		if flags["custom_character"] then
			local d = active_custom_desc or get_target_description()
			if d then
				apply_custom_character(d)
			end
		end
		if flags["misc_korblox"] then
			do_korblox(true)
		end
		if flags["misc_accessory_adder"] then
			table.clear(equipped_accessory_instances)
			sync_equipped_accessories()
		end
	end))

	-- Right Side: Otras razones & Hitsound
	local misc_other = mics:section({ name = "Otras razones & Hitsound", side = "right" })

	misc_other:toggle({
		name = "Hitsound",
		flag = "misc_hitsound_enabled",
		default = false
	})

	misc_other:dropdown({
		name = "Hitsound Voice",
		flag = "misc_hitsound_voice",
		items = hitsound_list,
		multi = false,
		default = "Default"
	})

	misc_other:slider({
		name = "Hitsound Volume",
		flag = "misc_hitsound_volume",
		min = 0,
		max = 100,
		default = 100
	})

	misc_other:button({
		name = "Test Hitsound",
		callback = function()
			play_hitsound()
		end
	})

	misc_other:toggle({
		name = "Remove jump cooldown",
		flag = "misc_remove_jump_cooldown",
		default = false
	})

	misc_other:toggle({
		name = "Remove slowdowns",
		flag = "misc_remove_slowdowns",
		default = false
	})

	misc_other:toggle({
		name = "Instant stand",
		flag = "misc_instant_stand",
		default = false
	})

	misc_other:toggle({
		name = "No void kill",
		flag = "misc_no_void_kill",
		default = false
	})

	misc_other:toggle({
		name = "No sit",
		flag = "misc_no_sit",
		default = false
	})

	misc_other:button({
		name = "Force reset",
		callback = function()
			if game.Players.LocalPlayer.Character then
				game.Players.LocalPlayer.Character:BreakJoints()
			end
		end
	})
end

-- ==========================================
-- 5. Tab Config
-- ==========================================
do
	local set_clip = setclipboard or toclipboard or (Synapse and Synapse.set_clipboard) or function() end

	-- Teleport / Server Hop Helpers (Enhanced & Rewritten)
	local TeleportService = (cloneref and cloneref(game:GetService("TeleportService"))) or game:GetService("TeleportService")
	local HttpService = (cloneref and cloneref(game:GetService("HttpService"))) or game:GetService("HttpService")
	local req_func = request or http_request or (syn and syn.request) or (http and http.request)

	local function get_public_servers(cursor)
		local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
		if cursor then url = url .. "&cursor=" .. cursor end
		if req_func then
			local res = req_func({ Url = url, Method = "GET" })
			if res and res.StatusCode == 200 then
				local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
				if ok and data and data.data then
					return data.data, data.nextPageCursor
				end
			end
		end
		-- Fallback to game:HttpGet
		local success, response = pcall(function() return game:HttpGet(url) end)
		if success and response and response ~= "" then
			local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
			if ok and data and data.data then
				return data.data, data.nextPageCursor
			end
		end
		return nil, nil
	end

	local function server_hop(mode)
		task.spawn(function()
			library:notification({ text = "Scanning servers for Place ID: " .. tostring(game.PlaceId) .. "..." })
			local servers, nextPage = get_public_servers()
			if not servers or #servers == 0 then
				library:notification({ text = "No public servers found (Private/VIP Place or API limit)" })
				return
			end

			local valid_servers = {}
			for _, s in ipairs(servers) do
				if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
					table.insert(valid_servers, s)
				end
			end

			if #valid_servers == 0 and nextPage then
				servers = get_public_servers(nextPage)
				if servers then
					for _, s in ipairs(servers) do
						if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
							table.insert(valid_servers, s)
						end
					end
				end
			end

			if #valid_servers == 0 then
				library:notification({ text = "No alternate server found with free slots!" })
				return
			end

			local target_server = nil
			if mode == "less_people" then
				table.sort(valid_servers, function(a, b) return a.playing < b.playing end)
				target_server = valid_servers[1]
			elseif mode == "more_people" then
				table.sort(valid_servers, function(a, b) return a.playing > b.playing end)
				target_server = valid_servers[1]
			elseif mode == "low_ping" then
				table.sort(valid_servers, function(a, b)
					local pingA = a.ping or 999
					local pingB = b.ping or 999
					return pingA < pingB
				end)
				target_server = valid_servers[1]
			else
				target_server = valid_servers[math.random(1, #valid_servers)]
			end

			if target_server then
				local pingStr = target_server.ping and (tostring(target_server.ping) .. "ms") or "N/A"
				library:notification({
					text = string.format("Hop -> [%s] (%d/%d players) Ping: %s", string.sub(target_server.id, 1, 8), target_server.playing, target_server.maxPlayers, pingStr),
					time = 4
				})
				TeleportService:TeleportToPlaceInstance(game.PlaceId, target_server.id, LocalPlayer)
			end
		end)
	end

	local function rejoin_server()
		library:notification({ text = "Rejoining current server..." })
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end

	local function join_by_job_id(targetJobId)
		local cleaned = tostring(targetJobId):gsub("%s+", "")
		if not cleaned or cleaned == "" then
			library:notification({ text = "Please enter a valid Job ID!" })
			return
		end
		library:notification({ text = "Teleporting to Job ID: " .. string.sub(cleaned, 1, 8) .. "..." })
		TeleportService:TeleportToPlaceInstance(game.PlaceId, cleaned, LocalPlayer)
	end

	-- Left side: Configuration System
	local configs_section = config_tab:section({ name = "Configuration System", side = "left" })
	local dir = library.directory .. "/configs/"

	if isfolder and not isfolder(library.directory) then
		pcall(makefolder, library.directory)
	end
	if isfolder and not isfolder(dir) then
		pcall(makefolder, dir)
	end

	-- Autoload Status Card (Hiển thị trực quan config nào đang được Autoload)
	local autoload_card = library:create("Frame", {
		Parent = configs_section.holder,
		Name = "AutoloadStatusCard",
		Position = UDim2.new(0, -15, 0, 2),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 26),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local autoload_inner = library:create("Frame", {
		Parent = autoload_card,
		Name = "Inner",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(24, 24, 28),
	})

	local autoload_status_dot = library:create("Frame", {
		Parent = autoload_inner,
		Name = "StatusDot",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(0, 6, 0, 6),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(100, 100, 110),
	})
	local dot_corner = library:create("UICorner", {
		Parent = autoload_status_dot,
		CornerRadius = UDim.new(1, 0),
	})

	local autoload_status_label = library:create("TextLabel", {
		Parent = autoload_inner,
		Name = "StatusText",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "Autoload: None (Disabled)",
		TextStrokeTransparency = 0.5,
		Position = UDim2.new(0, 20, 0, 0),
		Size = UDim2.new(1, -28, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 11,
		BackgroundTransparency = 1,
	})

	local function update_autoload_display()
		local current = library:get_autoload_config()
		if current and current ~= "" then
			autoload_inner.BorderColor3 = Color3.fromRGB(35, 110, 50)
			autoload_inner.BackgroundColor3 = Color3.fromRGB(16, 32, 20)
			autoload_status_dot.BackgroundColor3 = Color3.fromRGB(80, 230, 110)
			autoload_status_label.TextColor3 = Color3.fromRGB(80, 230, 110)
			autoload_status_label.Text = "⚡ Autoload: " .. current .. " (Active)"
		else
			autoload_inner.BorderColor3 = Color3.fromRGB(50, 50, 56)
			autoload_inner.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
			autoload_status_dot.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
			autoload_status_label.TextColor3 = Color3.fromRGB(130, 130, 140)
			autoload_status_label.Text = "○ Autoload: None (Disabled)"
		end
	end

	update_autoload_display()

	library.config_holder = configs_section:dropdown({ name = "Configs", items = {}, flag = "config_name_list" })
	configs_section:textbox({ flag = "config_name_text_box" })

	configs_section:button({
		name = "Create",
		callback = function()
			local name = flags["config_name_text_box"]
			if name and name ~= "" then
				library:save_config(name)
			end
		end,
	})

	configs_section:button({
		name = "Load",
		callback = function()
			local selected = flags["config_name_list"]
			if type(selected) == "table" then selected = selected[1] end
			if selected and selected ~= "" then
				library:load_config(selected)
			end
		end,
	})

	configs_section:button({
		name = "Set as Autoload",
		callback = function()
			local selected = flags["config_name_list"]
			if type(selected) == "table" then selected = selected[1] end
			if selected and selected ~= "" then
				library:set_autoload_config(selected)
				update_autoload_display()
			else
				library:notification({ text = "Please select a config from the dropdown first!" })
			end
		end,
	})

	configs_section:button({
		name = "Clear Autoload",
		callback = function()
			library:clear_autoload_config()
			update_autoload_display()
		end,
	})

	configs_section:button({
		name = "Update",
		callback = function()
			local selected = flags["config_name_list"]
			if type(selected) == "table" then selected = selected[1] end
			if selected and selected ~= "" then
				library:update_config(selected)
			end
		end,
	})

	configs_section:button({
		name = "Delete",
		callback = function()
			local selected = flags["config_name_list"]
			if type(selected) == "table" then selected = selected[1] end
			if selected and selected ~= "" then
				library:delete_config(selected)
				update_autoload_display()
			end
		end,
	})

	configs_section:button({
		name = "Refresh List",
		callback = function()
			library:config_list_update()
			update_autoload_display()
		end,
	})

	configs_section:button({
		name = "Unload Menu",
		callback = function()
			if library._unload_cheat then
				library._unload_cheat()
			end
			library:unload()
		end,
	})

	-- Right Side 1: Server Hop & Tools (Full Rewrite)
	local server_section = config_tab:section({ name = "Server Hop & Tools", side = "right" })

	server_section:button({
		name = "Hop Server (Random)",
		callback = function()
			server_hop("random")
		end
	})

	server_section:button({
		name = "Hop Server Low Ping",
		callback = function()
			server_hop("low_ping")
		end
	})

	server_section:button({
		name = "Hop Server Less People",
		callback = function()
			server_hop("less_people")
		end
	})

	server_section:button({
		name = "Hop Server More People",
		callback = function()
			server_hop("more_people")
		end
	})

	server_section:button({
		name = "Rejoin Current Server",
		callback = function()
			rejoin_server()
		end
	})

	server_section:textbox({
		placeholder = "Enter target Job ID...",
		flag = "config_custom_job_id",
		default = "",
	})

	server_section:button({
		name = "Join Server by Job ID",
		callback = function()
			join_by_job_id(flags["config_custom_job_id"])
		end
	})

	server_section:button({
		name = "Copy Job ID Server",
		callback = function()
			set_clip(tostring(game.JobId))
			library:notification({ text = "Copied Job ID to clipboard!" })
		end
	})

	server_section:button({
		name = "Copy Place ID",
		callback = function()
			set_clip(tostring(game.PlaceId))
			library:notification({ text = "Copied Place ID to clipboard!" })
		end
	})

	server_section:button({
		name = "Copy Join Script",
		callback = function()
			local join_code = string.format('cloneref(game:GetService("TeleportService")):TeleportToPlaceInstance(%d, "%s")', game.PlaceId, game.JobId)
			set_clip(join_code)
			library:notification({ text = "Copied join script to clipboard!" })
		end
	})

	-- Right Side 2: Section Menu (Expanded 35 HvH UI Modes, 21 Animation Modes, 20 Color Modes, 33 Master Menu Modes)
	local menu_section = config_tab:section({ name = "Menu", side = "right" })

	local menu_mode_presets = {
		["Nemesis Elite"] = {
			ui_mode = "Nemesis",
			ui_accent = Color3.fromRGB(220, 20, 60),
			ui_anim_mode = "Gradient Slide",
			ui_color_mode = "Theme Accent",
			ui_anim_color = Color3.fromRGB(75, 90, 255),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Reverse Typing",
			wm_color_mode = "Blood Crimson",
			wm_anim_color = Color3.fromRGB(75, 90, 255),
			wm_anim_speed = 1,
		},
		["Neverlose CS:GO"] = {
			ui_mode = "Neverlose Classic",
			ui_accent = Color3.fromRGB(0, 150, 255),
			ui_anim_mode = "Wave",
			ui_color_mode = "RGB Spectrum",
			ui_anim_color = Color3.fromRGB(0, 180, 255),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Typing",
			wm_color_mode = "Cyberpunk Neon",
			wm_anim_color = Color3.fromRGB(0, 220, 255),
			wm_anim_speed = 1,
		},
		["Gamesense Skeet"] = {
			ui_mode = "Skeet / Gamesense",
			ui_accent = Color3.fromRGB(168, 255, 60),
			ui_anim_mode = "Shimmer",
			ui_color_mode = "Toxic Matrix",
			ui_anim_color = Color3.fromRGB(140, 255, 50),
			ui_anim_speed = 1.2,
			watermark_enabled = true,
			wm_anim_mode = "Typing",
			wm_color_mode = "Toxic Matrix",
			wm_anim_color = Color3.fromRGB(140, 255, 50),
			wm_anim_speed = 1,
		},
		["Fatality Berserk"] = {
			ui_mode = "Fatality.win",
			ui_accent = Color3.fromRGB(235, 45, 125),
			ui_anim_mode = "Pulse",
			ui_color_mode = "Cyberpunk Neon",
			ui_anim_color = Color3.fromRGB(255, 50, 150),
			ui_anim_speed = 1.5,
			watermark_enabled = true,
			wm_anim_mode = "Reverse Typing",
			wm_color_mode = "Blood Crimson",
			wm_anim_color = Color3.fromRGB(255, 50, 150),
			wm_anim_speed = 1,
		},
		["Aimware Racing"] = {
			ui_mode = "Aimware V5",
			ui_accent = Color3.fromRGB(255, 110, 20),
			ui_anim_mode = "Bounce",
			ui_color_mode = "Sunset Horizon",
			ui_anim_color = Color3.fromRGB(255, 140, 30),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Typing",
			wm_color_mode = "Royal Gold",
			wm_anim_color = Color3.fromRGB(255, 180, 40),
			wm_anim_speed = 1,
		},
		["Onetap Electric"] = {
			ui_mode = "Onetap V4",
			ui_accent = Color3.fromRGB(255, 140, 0),
			ui_anim_mode = "Glitch Hacker",
			ui_color_mode = "Sunset Horizon",
			ui_anim_color = Color3.fromRGB(255, 160, 20),
			ui_anim_speed = 1.2,
			watermark_enabled = true,
			wm_anim_mode = "Reverse Typing",
			wm_color_mode = "Royal Gold",
			wm_anim_color = Color3.fromRGB(255, 200, 50),
			wm_anim_speed = 1,
		},
		["Primordial Frost"] = {
			ui_mode = "Primordial.dev",
			ui_accent = Color3.fromRGB(80, 180, 255),
			ui_anim_mode = "Wave",
			ui_color_mode = "Ice & Frost",
			ui_anim_color = Color3.fromRGB(120, 210, 255),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Typing",
			wm_color_mode = "Ice & Frost",
			wm_anim_color = Color3.fromRGB(120, 210, 255),
			wm_anim_speed = 1,
		},
		["Pandora Deep Sea"] = {
			ui_mode = "Pandora.gg",
			ui_accent = Color3.fromRGB(30, 220, 200),
			ui_anim_mode = "Gradient Slide",
			ui_color_mode = "Ice & Frost",
			ui_anim_color = Color3.fromRGB(50, 240, 220),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Shimmer",
			wm_color_mode = "Pastel Dream",
			wm_anim_color = Color3.fromRGB(200, 130, 255),
			wm_anim_speed = 1,
		},
		["Monolith Void"] = {
			ui_mode = "Monolith",
			ui_accent = Color3.fromRGB(140, 70, 255),
			ui_anim_mode = "Pulse",
			ui_color_mode = "Galaxy Nebula",
			ui_anim_color = Color3.fromRGB(160, 90, 255),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Bounce",
			wm_color_mode = "Galaxy Nebula",
			wm_anim_color = Color3.fromRGB(160, 90, 255),
			wm_anim_speed = 1,
		},
		["Evawa Weave"] = {
			ui_mode = "Evawa / Weave",
			ui_accent = Color3.fromRGB(255, 90, 95),
			ui_anim_mode = "Wave",
			ui_color_mode = "Pastel Dream",
			ui_anim_color = Color3.fromRGB(255, 120, 130),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Fade",
			wm_color_mode = "Pastel Dream",
			wm_anim_color = Color3.fromRGB(255, 120, 130),
			wm_anim_speed = 1,
		},
		["Nixware Indigo"] = {
			ui_mode = "Nixware Indigo",
			ui_accent = Color3.fromRGB(95, 75, 240),
			ui_anim_mode = "Neon Flicker",
			ui_color_mode = "Galaxy Nebula",
			ui_anim_color = Color3.fromRGB(120, 90, 255),
			ui_anim_speed = 1.2,
			watermark_enabled = true,
			wm_anim_mode = "Glitch Shake",
			wm_color_mode = "Galaxy Nebula",
			wm_anim_color = Color3.fromRGB(120, 90, 255),
			wm_anim_speed = 1.2,
		},
		["Legendware Crimson"] = {
			ui_mode = "Legendware Crimson",
			ui_accent = Color3.fromRGB(230, 30, 45),
			ui_anim_mode = "Heartbeat",
			ui_color_mode = "Blood Crimson",
			ui_anim_color = Color3.fromRGB(255, 40, 55),
			ui_anim_speed = 1.2,
			watermark_enabled = true,
			wm_anim_mode = "Reverse Typing",
			wm_color_mode = "Blood Crimson",
			wm_anim_color = Color3.fromRGB(255, 40, 55),
			wm_anim_speed = 1,
		},
		["Rifk7 Poison"] = {
			ui_mode = "Rifk7 Poison",
			ui_accent = Color3.fromRGB(175, 255, 30),
			ui_anim_mode = "Scanline",
			ui_color_mode = "Toxic Matrix",
			ui_anim_color = Color3.fromRGB(190, 255, 40),
			ui_anim_speed = 1.5,
			watermark_enabled = true,
			wm_anim_mode = "Glitch Hacker",
			wm_color_mode = "Electric Lime",
			wm_anim_color = Color3.fromRGB(190, 255, 40),
			wm_anim_speed = 1.5,
		},
		["Interverse Amethyst"] = {
			ui_mode = "Interverse Amethyst",
			ui_accent = Color3.fromRGB(180, 80, 255),
			ui_anim_mode = "Shimmer",
			ui_color_mode = "Eldritch Amethyst",
			ui_anim_color = Color3.fromRGB(200, 100, 255),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Vapor Float",
			wm_color_mode = "Eldritch Amethyst",
			wm_anim_color = Color3.fromRGB(200, 100, 255),
			wm_anim_speed = 1,
		},
		["Midnight Synthwave"] = {
			ui_mode = "Midnight Synthwave",
			ui_accent = Color3.fromRGB(255, 0, 153),
			ui_anim_mode = "Liquid Wave",
			ui_color_mode = "Synthwave 80s",
			ui_anim_color = Color3.fromRGB(0, 255, 204),
			ui_anim_speed = 1.2,
			watermark_enabled = true,
			wm_anim_mode = "Wave",
			wm_color_mode = "Synthwave 80s",
			wm_anim_color = Color3.fromRGB(0, 255, 204),
			wm_anim_speed = 1.2,
		},
		["Cyberpunk 2077"] = {
			ui_mode = "Cyberpunk 2077",
			ui_accent = Color3.fromRGB(255, 34, 0),
			ui_anim_mode = "Glitch Shake",
			ui_color_mode = "Cyberpunk Neon",
			ui_anim_color = Color3.fromRGB(255, 204, 0),
			ui_anim_speed = 1.5,
			watermark_enabled = true,
			wm_anim_mode = "Glitch Hacker",
			wm_color_mode = "Cyberpunk Neon",
			wm_anim_color = Color3.fromRGB(255, 204, 0),
			wm_anim_speed = 1.5,
		},
		["Matrix Overdrive"] = {
			ui_mode = "Matrix Overdrive",
			ui_accent = Color3.fromRGB(0, 255, 65),
			ui_anim_mode = "Glitch Hacker",
			ui_color_mode = "Toxic Matrix",
			ui_anim_color = Color3.fromRGB(0, 255, 65),
			ui_anim_speed = 1.6,
			watermark_enabled = true,
			wm_anim_mode = "Scanline",
			wm_color_mode = "Toxic Matrix",
			wm_anim_color = Color3.fromRGB(0, 255, 65),
			wm_anim_speed = 1.5,
		},
		["Vaporwave 1984"] = {
			ui_mode = "Vaporwave 1984",
			ui_accent = Color3.fromRGB(255, 106, 213),
			ui_anim_mode = "Vapor Float",
			ui_color_mode = "Pastel Dream",
			ui_anim_color = Color3.fromRGB(148, 208, 255),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Shimmer",
			wm_color_mode = "Pastel Dream",
			wm_anim_color = Color3.fromRGB(148, 208, 255),
			wm_anim_speed = 1,
		},
		["Sakura Blossom"] = {
			ui_mode = "Sakura Blossom",
			ui_accent = Color3.fromRGB(255, 165, 185),
			ui_anim_mode = "Breathing Glow",
			ui_color_mode = "Sakura Petals",
			ui_anim_color = Color3.fromRGB(255, 200, 215),
			ui_anim_speed = 0.8,
			watermark_enabled = true,
			wm_anim_mode = "Type & Erase",
			wm_color_mode = "Sakura Petals",
			wm_anim_color = Color3.fromRGB(255, 200, 215),
			wm_anim_speed = 0.8,
		},
		["Golden Sovereign"] = {
			ui_mode = "Golden Sovereign",
			ui_accent = Color3.fromRGB(255, 215, 0),
			ui_anim_mode = "Shimmer",
			ui_color_mode = "Royal Gold",
			ui_anim_color = Color3.fromRGB(255, 180, 0),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Typing",
			wm_color_mode = "Royal Gold",
			wm_anim_color = Color3.fromRGB(255, 180, 0),
			wm_anim_speed = 1,
		},
		["Hellfire Diablo"] = {
			ui_mode = "Hellfire Diablo",
			ui_accent = Color3.fromRGB(255, 70, 0),
			ui_anim_mode = "Strobe Flash",
			ui_color_mode = "Hellfire Blaze",
			ui_anim_color = Color3.fromRGB(255, 200, 0),
			ui_anim_speed = 1.5,
			watermark_enabled = true,
			wm_anim_mode = "Heartbeat",
			wm_color_mode = "Hellfire Blaze",
			wm_anim_color = Color3.fromRGB(255, 200, 0),
			wm_anim_speed = 1.5,
		},
		["Ghost In Shell"] = {
			ui_mode = "Ghost In Shell",
			ui_accent = Color3.fromRGB(210, 235, 255),
			ui_anim_mode = "Type & Erase",
			ui_color_mode = "Ice & Frost",
			ui_anim_color = Color3.fromRGB(0, 220, 255),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Neon Flicker",
			wm_color_mode = "Ice & Frost",
			wm_anim_color = Color3.fromRGB(0, 220, 255),
			wm_anim_speed = 1,
		},
		["Eldritch Void"] = {
			ui_mode = "Eldritch Void",
			ui_accent = Color3.fromRGB(135, 30, 195),
			ui_anim_mode = "Heartbeat",
			ui_color_mode = "Eldritch Amethyst",
			ui_anim_color = Color3.fromRGB(180, 50, 255),
			ui_anim_speed = 1.2,
			watermark_enabled = true,
			wm_anim_mode = "Pulse",
			wm_color_mode = "Eldritch Amethyst",
			wm_anim_color = Color3.fromRGB(180, 50, 255),
			wm_anim_speed = 1.2,
		},
		["Aurora Borealis"] = {
			ui_mode = "Aurora Borealis",
			ui_accent = Color3.fromRGB(0, 255, 180),
			ui_anim_mode = "Liquid Wave",
			ui_color_mode = "Aurora Lights",
			ui_anim_color = Color3.fromRGB(120, 80, 255),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Wave",
			wm_color_mode = "Aurora Lights",
			wm_anim_color = Color3.fromRGB(120, 80, 255),
			wm_anim_speed = 1,
		},
		["Neon Genesis"] = {
			ui_mode = "Neon Genesis",
			ui_accent = Color3.fromRGB(150, 0, 220),
			ui_anim_mode = "Pulse",
			ui_color_mode = "Electric Lime",
			ui_anim_color = Color3.fromRGB(0, 255, 100),
			ui_anim_speed = 1.2,
			watermark_enabled = true,
			wm_anim_mode = "Glitch Shake",
			wm_color_mode = "Toxic Matrix",
			wm_anim_color = Color3.fromRGB(0, 255, 100),
			wm_anim_speed = 1.2,
		},
		["Hyperpop Glitch"] = {
			ui_mode = "Hyperpop Glitch",
			ui_accent = Color3.fromRGB(255, 20, 147),
			ui_anim_mode = "Glitch Shake",
			ui_color_mode = "Cyberpunk Neon",
			ui_anim_color = Color3.fromRGB(0, 240, 255),
			ui_anim_speed = 1.5,
			watermark_enabled = true,
			wm_anim_mode = "Strobe Flash",
			wm_color_mode = "Cyberpunk Neon",
			wm_anim_color = Color3.fromRGB(0, 240, 255),
			wm_anim_speed = 1.5,
		},
		["Blood Moon Demon"] = {
			ui_mode = "Blood Moon",
			ui_accent = Color3.fromRGB(255, 65, 85),
			ui_anim_mode = "Gradient Slide",
			ui_color_mode = "Blood Crimson",
			ui_anim_color = Color3.fromRGB(255, 40, 60),
			ui_anim_speed = 1.2,
			watermark_enabled = true,
			wm_anim_mode = "Typing",
			wm_color_mode = "Blood Crimson",
			wm_anim_color = Color3.fromRGB(255, 40, 60),
			wm_anim_speed = 1,
		},
		["Acid Overload"] = {
			ui_mode = "Acid Toxic",
			ui_accent = Color3.fromRGB(220, 255, 30),
			ui_anim_mode = "Blink",
			ui_color_mode = "Toxic Matrix",
			ui_anim_color = Color3.fromRGB(200, 255, 0),
			ui_anim_speed = 1.5,
			watermark_enabled = true,
			wm_anim_mode = "Glitch Hacker",
			wm_color_mode = "Toxic Matrix",
			wm_anim_color = Color3.fromRGB(200, 255, 0),
			wm_anim_speed = 1.5,
		},
		["Monochrome Shadow"] = {
			ui_mode = "Monochrome Frost",
			ui_accent = Color3.fromRGB(235, 245, 255),
			ui_anim_mode = "Shimmer",
			ui_color_mode = "Monochrome",
			ui_anim_color = Color3.fromRGB(200, 210, 220),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Fade",
			wm_color_mode = "Monochrome",
			wm_anim_color = Color3.fromRGB(200, 210, 220),
			wm_anim_speed = 1,
		},
		["Abyss Sapphire"] = {
			ui_mode = "Abyss Sapphire",
			ui_accent = Color3.fromRGB(30, 100, 255),
			ui_anim_mode = "Liquid Wave",
			ui_color_mode = "Deep Ocean",
			ui_anim_color = Color3.fromRGB(0, 200, 255),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Wave",
			wm_color_mode = "Deep Ocean",
			wm_anim_color = Color3.fromRGB(0, 200, 255),
			wm_anim_speed = 1,
		},
		["Bismuth Iridescent"] = {
			ui_mode = "Bismuth Iridescent",
			ui_accent = Color3.fromRGB(255, 105, 225),
			ui_anim_mode = "Rainbow Cycle",
			ui_color_mode = "Iridescent Pearl",
			ui_anim_color = Color3.fromRGB(80, 230, 255),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Shimmer",
			wm_color_mode = "RGB Spectrum",
			wm_anim_color = Color3.fromRGB(80, 230, 255),
			wm_anim_speed = 1,
		},
		["Obsidian Phantom"] = {
			ui_mode = "Obsidian Phantom",
			ui_accent = Color3.fromRGB(255, 35, 35),
			ui_anim_mode = "Neon Flicker",
			ui_color_mode = "Blood Crimson",
			ui_anim_color = Color3.fromRGB(255, 35, 35),
			ui_anim_speed = 1.2,
			watermark_enabled = true,
			wm_anim_mode = "Glitch Shake",
			wm_color_mode = "Blood Crimson",
			wm_anim_color = Color3.fromRGB(255, 35, 35),
			wm_anim_speed = 1.2,
		},
		["Bloomcore Gloom"] = {
			ui_mode = "Bloomcore Gloom",
			ui_accent = Color3.fromRGB(0, 235, 175),
			ui_anim_mode = "Neon Flicker",
			ui_color_mode = "Bloomcore Teal",
			ui_anim_color = Color3.fromRGB(0, 235, 175),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Breathing Glow",
			wm_color_mode = "Bloomcore Teal",
			wm_anim_color = Color3.fromRGB(0, 235, 175),
			wm_anim_speed = 1,
		},
		["Last Summer"] = {
			ui_mode = "Last Summer",
			ui_accent = Color3.fromRGB(215, 235, 75),
			ui_anim_mode = "Shimmer",
			ui_color_mode = "Summer Nostalgia",
			ui_anim_color = Color3.fromRGB(255, 215, 80),
			ui_anim_speed = 1.1,
			watermark_enabled = true,
			wm_anim_mode = "Liquid Wave",
			wm_color_mode = "Summer Nostalgia",
			wm_anim_color = Color3.fromRGB(255, 215, 80),
			wm_anim_speed = 1,
		},
		["Just A Memory"] = {
			ui_mode = "Just A Memory",
			ui_accent = Color3.fromRGB(110, 130, 255),
			ui_anim_mode = "Fade",
			ui_color_mode = "Twilight Memory",
			ui_anim_color = Color3.fromRGB(175, 95, 240),
			ui_anim_speed = 0.9,
			watermark_enabled = true,
			wm_anim_mode = "Vapor Float",
			wm_color_mode = "Twilight Memory",
			wm_anim_color = Color3.fromRGB(175, 95, 240),
			wm_anim_speed = 1,
		},
		["Hearing Her Voice"] = {
			ui_mode = "Hearing Her Voice",
			ui_accent = Color3.fromRGB(165, 195, 245),
			ui_anim_mode = "Type & Erase",
			ui_color_mode = "Moonlit Meadow",
			ui_anim_color = Color3.fromRGB(165, 195, 245),
			ui_anim_speed = 1,
			watermark_enabled = true,
			wm_anim_mode = "Heartbeat",
			wm_color_mode = "Moonlit Meadow",
			wm_anim_color = Color3.fromRGB(165, 195, 245),
			wm_anim_speed = 1.1,
		},
		["CS2 Sub-Tick Precision"] = {
			ui_mode = "Neverlose Classic",
			ui_accent = Color3.fromRGB(0, 180, 255),
			ui_anim_mode = "CS2 Kinetic Shift",
			ui_color_mode = "Ice & Frost",
			ui_anim_color = Color3.fromRGB(0, 210, 255),
			ui_anim_speed = 1.2,
			watermark_enabled = true,
			wm_anim_mode = "Sub-Tick Jitter",
			wm_color_mode = "Cyberpunk Neon",
			wm_anim_color = Color3.fromRGB(0, 255, 200),
			wm_anim_speed = 1.3,
		},
		["Gamesense Radar Pulse"] = {
			ui_mode = "Skeet / Gamesense",
			ui_accent = Color3.fromRGB(150, 200, 60),
			ui_anim_mode = "Gamesense Skeet Bar",
			ui_color_mode = "Toxic Matrix",
			ui_anim_color = Color3.fromRGB(160, 220, 65),
			ui_anim_speed = 1.1,
			watermark_enabled = true,
			wm_anim_mode = "Gamesense Skeet Bar",
			wm_color_mode = "Electric Lime",
			wm_anim_color = Color3.fromRGB(150, 255, 80),
			wm_anim_speed = 1.0,
		},
		["Neverlose Hyperdrive"] = {
			ui_mode = "Neverlose Classic",
			ui_accent = Color3.fromRGB(0, 150, 255),
			ui_anim_mode = "Neverlose Spark",
			ui_color_mode = "Theme Accent",
			ui_anim_color = Color3.fromRGB(0, 170, 255),
			ui_anim_speed = 1.2,
			watermark_enabled = true,
			wm_anim_mode = "Neverlose Spark",
			wm_color_mode = "RGB Spectrum",
			wm_anim_color = Color3.fromRGB(0, 220, 255),
			wm_anim_speed = 1.2,
		},
		["Primordial Zero-Kelvin"] = {
			ui_mode = "Primordial.dev",
			ui_accent = Color3.fromRGB(110, 170, 240),
			ui_anim_mode = "Primordial Frost Pulse",
			ui_color_mode = "Ice & Frost",
			ui_anim_color = Color3.fromRGB(140, 200, 255),
			ui_anim_speed = 0.9,
			watermark_enabled = true,
			wm_anim_mode = "Primordial Frost Pulse",
			wm_color_mode = "Pastel Dream",
			wm_anim_color = Color3.fromRGB(180, 220, 255),
			wm_anim_speed = 1.0,
		},
		["Fatality Bloodbath Rage"] = {
			ui_mode = "Fatality.win",
			ui_accent = Color3.fromRGB(240, 45, 90),
			ui_anim_mode = "Fatality Rage Strike",
			ui_color_mode = "Blood Crimson",
			ui_anim_color = Color3.fromRGB(255, 30, 70),
			ui_anim_speed = 1.3,
			watermark_enabled = true,
			wm_anim_mode = "Fatality Rage Strike",
			wm_color_mode = "Hellfire Blaze",
			wm_anim_color = Color3.fromRGB(255, 60, 40),
			wm_anim_speed = 1.4,
		},
		["Monolith Abyss Cascade"] = {
			ui_mode = "Monolith",
			ui_accent = Color3.fromRGB(140, 70, 255),
			ui_anim_mode = "Monolith Matrix Cascade",
			ui_color_mode = "Eldritch Amethyst",
			ui_anim_color = Color3.fromRGB(170, 90, 255),
			ui_anim_speed = 1.0,
			watermark_enabled = true,
			wm_anim_mode = "Monolith Matrix Cascade",
			wm_color_mode = "Galaxy Nebula",
			wm_anim_color = Color3.fromRGB(130, 60, 240),
			wm_anim_speed = 1.1,
		},
		["Desync Mirage Phantom"] = {
			ui_mode = "Obsidian Phantom",
			ui_accent = Color3.fromRGB(255, 70, 120),
			ui_anim_mode = "Desync Ghost Mirror",
			ui_color_mode = "Cyberpunk Neon",
			ui_anim_color = Color3.fromRGB(255, 90, 140),
			ui_anim_speed = 1.1,
			watermark_enabled = true,
			wm_anim_mode = "Desync Ghost Mirror",
			wm_color_mode = "Theme Accent",
			wm_anim_color = Color3.fromRGB(255, 50, 100),
			wm_anim_speed = 1.1,
		},
		["Chroma Panorama Velocity"] = {
			ui_mode = "Bismuth Iridescent",
			ui_accent = Color3.fromRGB(255, 90, 200),
			ui_anim_mode = "Chroma Drift",
			ui_color_mode = "RGB Spectrum",
			ui_anim_color = Color3.fromRGB(255, 120, 220),
			ui_anim_speed = 1.3,
			watermark_enabled = true,
			wm_anim_mode = "Chroma Drift",
			wm_color_mode = "Iridescent Pearl",
			wm_anim_color = Color3.fromRGB(100, 220, 255),
			wm_anim_speed = 1.2,
		},
		["Spectrum Borealis Quantum"] = {
			ui_mode = "Aurora Borealis",
			ui_accent = Color3.fromRGB(0, 255, 190),
			ui_anim_mode = "Spectrum Aurora Wave",
			ui_color_mode = "Aurora Lights",
			ui_anim_color = Color3.fromRGB(0, 255, 180),
			ui_anim_speed = 1.1,
			watermark_enabled = true,
			wm_anim_mode = "Spectrum Aurora Wave",
			wm_color_mode = "Aurora Lights",
			wm_anim_color = Color3.fromRGB(120, 100, 255),
			wm_anim_speed = 1.2,
		},
		["Sub-Tick Anti-Aim Jitter"] = {
			ui_mode = "Matrix Overdrive",
			ui_accent = Color3.fromRGB(0, 255, 140),
			ui_anim_mode = "Sub-Tick Jitter",
			ui_color_mode = "Toxic Matrix",
			ui_anim_color = Color3.fromRGB(0, 255, 120),
			ui_anim_speed = 1.5,
			watermark_enabled = true,
			wm_anim_mode = "Sub-Tick Jitter",
			wm_color_mode = "Electric Lime",
			wm_anim_color = Color3.fromRGB(50, 255, 150),
			wm_anim_speed = 1.4,
		},
		["Why Did You Leave"] = {
			ui_mode = "Why Did You Leave",
			ui_accent = Color3.fromRGB(135, 175, 225),
			ui_anim_mode = "Tearful Echo",
			ui_color_mode = "Cold Streetlamp",
			ui_anim_color = Color3.fromRGB(245, 240, 225),
			ui_anim_speed = 1.0,
			watermark_enabled = true,
			wm_anim_mode = "Heartache Whisper",
			wm_color_mode = "Midnight Indigo",
			wm_anim_color = Color3.fromRGB(120, 145, 190),
			wm_anim_speed = 0.9,
			outline_anim_enabled = true,
			outline_anim_mode = "Tearful Echo Wave",
			outline_color_mode = "Tearful Midnight",
			outline_anim_color = Color3.fromRGB(135, 175, 225),
			outline_anim_speed = 1.0,
			keybinds_enabled = true,
			kb_anim_mode = "Shivering Breath",
			kb_color_mode = "Winter Breath Ice",
			kb_anim_color = Color3.fromRGB(165, 205, 245),
			kb_anim_speed = 1.2,
			player_list = true,
			pl_anim_mode = "Fading Footsteps",
			pl_color_mode = "Distant Shadow",
			pl_anim_color = Color3.fromRGB(95, 120, 165),
			pl_anim_speed = 0.8,
		},
		["One Last Stop"] = {
			ui_mode = "One Last Stop",
			ui_accent = Color3.fromRGB(225, 175, 195),
			ui_anim_mode = "Departure Farewell",
			ui_color_mode = "Melancholic Scarf Rose",
			ui_anim_color = Color3.fromRGB(235, 185, 205),
			ui_anim_speed = 0.9,
			watermark_enabled = true,
			wm_anim_mode = "Lonely Streetlamp",
			wm_color_mode = "Station Amber Glow",
			wm_anim_color = Color3.fromRGB(255, 225, 175),
			wm_anim_speed = 0.8,
			outline_anim_enabled = true,
			outline_anim_mode = "Departure Fog Drift",
			outline_color_mode = "Last Train Platform",
			outline_anim_color = Color3.fromRGB(225, 175, 195),
			outline_anim_speed = 0.9,
			keybinds_enabled = true,
			kb_anim_mode = "Signal Light Pulse",
			kb_color_mode = "Signal Amber Red",
			kb_anim_color = Color3.fromRGB(245, 70, 85),
			kb_anim_speed = 1.1,
			player_list = true,
			pl_anim_mode = "Snow Drift Rails",
			pl_color_mode = "Platform Ash Charcoal",
			pl_anim_color = Color3.fromRGB(180, 185, 195),
			pl_anim_speed = 0.85,
		},
		["You Were The Only Light I Needed"] = {
			ui_mode = "You Were The Only Light I Needed",
			ui_accent = Color3.fromRGB(255, 145, 60),
			ui_anim_mode = "Only Light Twilight",
			ui_color_mode = "Only Light Twilight",
			ui_anim_color = Color3.fromRGB(255, 145, 60),
			ui_anim_speed = 1.0,
			watermark_enabled = true,
			wm_anim_mode = "Golden Sunset Flare",
			wm_color_mode = "Golden Amber Sunset",
			wm_anim_color = Color3.fromRGB(255, 185, 70),
			wm_anim_speed = 0.9,
			outline_anim_enabled = true,
			outline_anim_mode = "Sunset Amber Horizon Wave",
			outline_color_mode = "Only Light Twilight",
			outline_anim_color = Color3.fromRGB(255, 145, 60),
			outline_anim_speed = 0.95,
			keybinds_enabled = true,
			kb_anim_mode = "Twilight Whisper Glow",
			kb_color_mode = "Camcorder Twilight Pink",
			kb_anim_color = Color3.fromRGB(215, 120, 255),
			kb_anim_speed = 1.1,
			player_list = true,
			pl_anim_mode = "Nostalgic Sunbeam Drift",
			pl_color_mode = "Golden Amber Sunset",
			pl_anim_color = Color3.fromRGB(255, 170, 60),
			pl_anim_speed = 0.85,
		},
		["Dying For Someone"] = {
			ui_mode = "Dying For Someone",
			ui_accent = Color3.fromRGB(255, 87, 34),
			ui_anim_mode = "Cigarette Smoke Dissolve",
			ui_color_mode = "Muted Twilight Dusk",
			ui_anim_color = Color3.fromRGB(255, 87, 34),
			ui_anim_speed = 0.9,
			watermark_enabled = true,
			wm_anim_mode = "Burning Ember Pulse",
			wm_color_mode = "Dying Cigarette Ember",
			wm_anim_color = Color3.fromRGB(255, 110, 60),
			wm_anim_speed = 0.85,
			outline_anim_enabled = true,
			outline_anim_mode = "Cigarette Ash Dissolve",
			outline_color_mode = "Dying Cigarette Ember",
			outline_anim_color = Color3.fromRGB(255, 87, 34),
			outline_anim_speed = 0.9,
			keybinds_enabled = true,
			kb_anim_mode = "Heartache Inhale Breath",
			kb_color_mode = "Muted Twilight Dusk",
			kb_anim_color = Color3.fromRGB(180, 95, 160),
			kb_anim_speed = 1.0,
			player_list = true,
			pl_anim_mode = "Fading Ash Descent",
			pl_color_mode = "Dying Cigarette Ember",
			pl_anim_color = Color3.fromRGB(200, 100, 70),
			pl_anim_speed = 0.8,
		},
		["Dying for someone who moved on."] = {
			ui_mode = "Dying For Someone",
			ui_accent = Color3.fromRGB(255, 87, 34),
			ui_anim_mode = "Cigarette Smoke Dissolve",
			ui_color_mode = "Muted Twilight Dusk",
			ui_anim_color = Color3.fromRGB(255, 87, 34),
			ui_anim_speed = 0.9,
			watermark_enabled = true,
			wm_anim_mode = "Burning Ember Pulse",
			wm_color_mode = "Dying Cigarette Ember",
			wm_anim_color = Color3.fromRGB(255, 110, 60),
			wm_anim_speed = 0.85,
			outline_anim_enabled = true,
			outline_anim_mode = "Cigarette Ash Dissolve",
			outline_color_mode = "Dying Cigarette Ember",
			outline_anim_color = Color3.fromRGB(255, 87, 34),
			outline_anim_speed = 0.9,
			keybinds_enabled = true,
			kb_anim_mode = "Heartache Inhale Breath",
			kb_color_mode = "Muted Twilight Dusk",
			kb_anim_color = Color3.fromRGB(180, 95, 160),
			kb_anim_speed = 1.0,
			player_list = true,
			pl_anim_mode = "Fading Ash Descent",
			pl_color_mode = "Dying Cigarette Ember",
			pl_anim_color = Color3.fromRGB(200, 100, 70),
			pl_anim_speed = 0.8,
		},
		["Wish We Could Watch Again"] = {
			ui_mode = "Wish We Could Watch Again",
			ui_accent = Color3.fromRGB(240, 65, 105),
			ui_anim_mode = "Fireworks Burst Spark",
			ui_color_mode = "Wool Scarf Crimson",
			ui_anim_color = Color3.fromRGB(240, 65, 105),
			ui_anim_speed = 1.1,
			watermark_enabled = true,
			wm_anim_mode = "Festive Sparkler Trail",
			wm_color_mode = "Fireworks Burst Gold",
			wm_anim_color = Color3.fromRGB(255, 215, 80),
			wm_anim_speed = 1.0,
			outline_anim_enabled = true,
			outline_anim_mode = "Festival Fireworks Ring",
			outline_color_mode = "Fireworks Burst Gold",
			outline_anim_color = Color3.fromRGB(240, 65, 105),
			outline_anim_speed = 1.05,
			keybinds_enabled = true,
			kb_anim_mode = "Wool Scarf Warmth",
			kb_color_mode = "Wool Scarf Crimson",
			kb_anim_color = Color3.fromRGB(235, 45, 85),
			kb_anim_speed = 1.15,
			player_list = true,
			pl_anim_mode = "Starry Ember Fallout",
			pl_color_mode = "Fireworks Burst Gold",
			pl_anim_color = Color3.fromRGB(255, 200, 90),
			pl_anim_speed = 0.9,
		},
		["I wish we could watch them again..."] = {
			ui_mode = "Wish We Could Watch Again",
			ui_accent = Color3.fromRGB(240, 65, 105),
			ui_anim_mode = "Fireworks Burst Spark",
			ui_color_mode = "Wool Scarf Crimson",
			ui_anim_color = Color3.fromRGB(240, 65, 105),
			ui_anim_speed = 1.1,
			watermark_enabled = true,
			wm_anim_mode = "Festive Sparkler Trail",
			wm_color_mode = "Fireworks Burst Gold",
			wm_anim_color = Color3.fromRGB(255, 215, 80),
			wm_anim_speed = 1.0,
			outline_anim_enabled = true,
			outline_anim_mode = "Festival Fireworks Ring",
			outline_color_mode = "Fireworks Burst Gold",
			outline_anim_color = Color3.fromRGB(240, 65, 105),
			outline_anim_speed = 1.05,
			keybinds_enabled = true,
			kb_anim_mode = "Wool Scarf Warmth",
			kb_color_mode = "Wool Scarf Crimson",
			kb_anim_color = Color3.fromRGB(235, 45, 85),
			kb_anim_speed = 1.15,
			player_list = true,
			pl_anim_mode = "Starry Ember Fallout",
			pl_color_mode = "Fireworks Burst Gold",
			pl_anim_color = Color3.fromRGB(255, 200, 90),
			pl_anim_speed = 0.9,
		},
		["Maybe This Sunset"] = {
			ui_mode = "Maybe This Sunset",
			ui_accent = Color3.fromRGB(255, 140, 0),
			ui_anim_mode = "Golden Sunset Serenity",
			ui_color_mode = "Meadow Sorbet Peach",
			ui_anim_color = Color3.fromRGB(255, 140, 0),
			ui_anim_speed = 0.95,
			watermark_enabled = true,
			wm_anim_mode = "Sunbeam Meadow Shimmer",
			wm_color_mode = "Honey Sunset Gold",
			wm_anim_color = Color3.fromRGB(255, 215, 60),
			wm_anim_speed = 0.9,
			outline_anim_enabled = true,
			outline_anim_mode = "Radiant Sunbeam Horizon",
			outline_color_mode = "Honey Sunset Gold",
			outline_anim_color = Color3.fromRGB(255, 140, 0),
			outline_anim_speed = 0.95,
			keybinds_enabled = true,
			kb_anim_mode = "Peach Sorbet Sweetness",
			kb_color_mode = "Meadow Sorbet Peach",
			kb_anim_color = Color3.fromRGB(255, 175, 155),
			kb_anim_speed = 1.0,
			player_list = true,
			pl_anim_mode = "Wind Blowing Wheat",
			pl_color_mode = "Honey Sunset Gold",
			pl_anim_color = Color3.fromRGB(255, 195, 55),
			pl_anim_speed = 0.85,
		},
		["maybe this sunset was all we needed..."] = {
			ui_mode = "Maybe This Sunset",
			ui_accent = Color3.fromRGB(255, 140, 0),
			ui_anim_mode = "Golden Sunset Serenity",
			ui_color_mode = "Meadow Sorbet Peach",
			ui_anim_color = Color3.fromRGB(255, 140, 0),
			ui_anim_speed = 0.95,
			watermark_enabled = true,
			wm_anim_mode = "Sunbeam Meadow Shimmer",
			wm_color_mode = "Honey Sunset Gold",
			wm_anim_color = Color3.fromRGB(255, 215, 60),
			wm_anim_speed = 0.9,
			outline_anim_enabled = true,
			outline_anim_mode = "Radiant Sunbeam Horizon",
			outline_color_mode = "Honey Sunset Gold",
			outline_anim_color = Color3.fromRGB(255, 140, 0),
			outline_anim_speed = 0.95,
			keybinds_enabled = true,
			kb_anim_mode = "Peach Sorbet Sweetness",
			kb_color_mode = "Meadow Sorbet Peach",
			kb_anim_color = Color3.fromRGB(255, 175, 155),
			kb_anim_speed = 1.0,
			player_list = true,
			pl_anim_mode = "Wind Blowing Wheat",
			pl_color_mode = "Honey Sunset Gold",
			pl_anim_color = Color3.fromRGB(255, 195, 55),
			pl_anim_speed = 0.85,
		},
	}

	local menu_modes_list = {
		"Nemesis Elite",
		"Neverlose CS:GO",
		"Gamesense Skeet",
		"Fatality Berserk",
		"Aimware Racing",
		"Onetap Electric",
		"Primordial Frost",
		"Pandora Deep Sea",
		"Monolith Void",
		"Evawa Weave",
		"Nixware Indigo",
		"Legendware Crimson",
		"Rifk7 Poison",
		"Interverse Amethyst",
		"Midnight Synthwave",
		"Cyberpunk 2077",
		"Matrix Overdrive",
		"Vaporwave 1984",
		"Sakura Blossom",
		"Golden Sovereign",
		"Hellfire Diablo",
		"Ghost In Shell",
		"Eldritch Void",
		"Aurora Borealis",
		"Neon Genesis",
		"Hyperpop Glitch",
		"Blood Moon Demon",
		"Acid Overload",
		"Monochrome Shadow",
		"Abyss Sapphire",
		"Bismuth Iridescent",
		"Obsidian Phantom",
		"Bloomcore Gloom",
		"Last Summer",
		"Just A Memory",
		"Hearing Her Voice",
		"Why Did You Leave",
		"One Last Stop",
		"You Were The Only Light I Needed",
		"Dying For Someone",
		"Dying for someone who moved on.",
		"Wish We Could Watch Again",
		"I wish we could watch them again...",
		"Maybe This Sunset",
		"maybe this sunset was all we needed...",
		"CS2 Sub-Tick Precision",
		"Gamesense Radar Pulse",
		"Neverlose Hyperdrive",
		"Primordial Zero-Kelvin",
		"Fatality Bloodbath Rage",
		"Monolith Abyss Cascade",
		"Desync Mirage Phantom",
		"Chroma Panorama Velocity",
		"Spectrum Borealis Quantum",
		"Sub-Tick Anti-Aim Jitter",
		"Custom",
	}

	local ui_modes_list = {
		"Neverlose Classic",
		"Skeet / Gamesense",
		"Fatality.win",
		"Aimware V5",
		"Onetap V4",
		"Primordial.dev",
		"Pandora.gg",
		"Nemesis",
		"Monolith",
		"Evawa / Weave",
		"Midnight Purple",
		"Blood Moon",
		"Emerald Cyber",
		"Sunset Mirage",
		"Monochrome Frost",
		"Acid Toxic",
		"Abyss Sapphire",
		"Nixware Indigo",
		"Legendware Crimson",
		"Rifk7 Poison",
		"Interverse Amethyst",
		"Midnight Synthwave",
		"Cyberpunk 2077",
		"Matrix Overdrive",
		"Vaporwave 1984",
		"Sakura Blossom",
		"Golden Sovereign",
		"Hellfire Diablo",
		"Ghost In Shell",
		"Eldritch Void",
		"Aurora Borealis",
		"Neon Genesis",
		"Hyperpop Glitch",
		"Bismuth Iridescent",
		"Obsidian Phantom",
		"Bloomcore Gloom",
		"Last Summer",
		"Just A Memory",
		"Hearing Her Voice",
		"Why Did You Leave",
		"One Last Stop",
		"You Were The Only Light I Needed",
		"Dying For Someone",
		"Dying for someone who moved on.",
		"Wish We Could Watch Again",
		"I wish we could watch them again...",
		"Maybe This Sunset",
		"maybe this sunset was all we needed..."
	}

	local anim_modes_list = {
		"None",
		"Typing",
		"Reverse Typing",
		"Rainbow Cycle",
		"Pulse",
		"Blink",
		"Wave",
		"Gradient Slide",
		"Glitch Hacker",
		"Shimmer",
		"Fade",
		"Bounce",
		"Heartbeat",
		"Glitch Shake",
		"Neon Flicker",
		"Type & Erase",
		"Liquid Wave",
		"Strobe Flash",
		"Vapor Float",
		"Breathing Glow",
		"Scanline",
		"CS2 Kinetic Shift",
		"Gamesense Skeet Bar",
		"Neverlose Spark",
		"Primordial Frost Pulse",
		"Fatality Rage Strike",
		"Monolith Matrix Cascade",
		"Sub-Tick Jitter",
		"Desync Ghost Mirror",
		"Chroma Drift",
		"Spectrum Aurora Wave",
		"Tearful Echo",
		"Departure Farewell",
		"Heartache Whisper",
		"Shivering Breath",
		"Fading Footsteps",
		"Lonely Streetlamp",
		"Signal Light Pulse",
		"Snow Drift Rails",
		"Only Light Twilight",
		"Camcorder Memory Echo",
		"Golden Sunset Flare",
		"Twilight Whisper Glow",
		"Nostalgic Sunbeam Drift",
		"Cigarette Smoke Dissolve",
		"Burning Ember Pulse",
		"Heartache Inhale Breath",
		"Fading Ash Descent",
		"Fireworks Burst Spark",
		"Festive Sparkler Trail",
		"Wool Scarf Warmth",
		"Starry Ember Fallout",
		"Golden Sunset Serenity",
		"Sunbeam Meadow Shimmer",
		"Peach Sorbet Sweetness",
		"Wind Blowing Wheat"
	}

	local color_modes_list = {
		"Theme Accent",
		"Custom Color",
		"RGB Spectrum",
		"Cyberpunk Neon",
		"Blood Crimson",
		"Toxic Matrix",
		"Sunset Horizon",
		"Ice & Frost",
		"Galaxy Nebula",
		"Royal Gold",
		"Pastel Dream",
		"Monochrome",
		"Synthwave 80s",
		"Aurora Lights",
		"Sakura Petals",
		"Hellfire Blaze",
		"Eldritch Amethyst",
		"Deep Ocean",
		"Electric Lime",
		"Iridescent Pearl",
		"Bloomcore Teal",
		"Summer Nostalgia",
		"Twilight Memory",
		"Moonlit Meadow",
		"Tearful Midnight",
		"Last Train Platform",
		"Cold Streetlamp",
		"Midnight Indigo",
		"Winter Breath Ice",
		"Distant Shadow",
		"Melancholic Scarf Rose",
		"Station Amber Glow",
		"Signal Amber Red",
		"Platform Ash Charcoal",
		"Only Light Twilight",
		"Golden Amber Sunset",
		"Camcorder Twilight Pink",
		"Dying Cigarette Ember",
		"Muted Twilight Dusk",
		"Fireworks Burst Gold",
		"Wool Scarf Crimson",
		"Honey Sunset Gold",
		"Meadow Sorbet Peach"
	}

	local outline_anim_modes_list = {
		"Sync With Accent",
		"RGB Spectrum Flow",
		"Gradient Wave",
		"Breathing Glow",
		"Strobe Pulse",
		"Neon Scanline",
		"CS2 Kinetic Sweep",
		"Neverlose Electric Spark",
		"Aurora Borealis Wave",
		"Cyberpunk Dual-Shift",
		"Heartbeat Surge",
		"Sub-Tick Glitch Spark",
		"Tearful Echo Wave",
		"Departure Fog Drift",
		"Sunset Amber Horizon Wave",
		"Camcorder Memory Scan",
		"Cigarette Ash Dissolve",
		"Festival Fireworks Ring",
		"Radiant Sunbeam Horizon",
		"None"
	}

	local _applying_preset = false
	local function mark_custom_mode()
		if _applying_preset then return end
		if flags["menu_master_mode"] ~= "Custom" then
			flags["menu_master_mode"] = "Custom"
			if library.config_flags and library.config_flags["menu_master_mode"] then
				pcall(function() library.config_flags["menu_master_mode"]({ "Custom" }) end)
			end
		end
	end

	local function apply_menu_mode(mode_name)
		if _applying_preset then return end
		local p = menu_mode_presets[mode_name]
		if not p then return end
		_applying_preset = true

		if p.ui_mode then
			flags["ui_theme_mode"] = p.ui_mode
			if library.set_ui_mode then
				library:set_ui_mode(p.ui_mode)
			end
			if library.config_flags and library.config_flags["ui_theme_mode"] then
				pcall(function() library.config_flags["ui_theme_mode"]({ p.ui_mode }) end)
			end
		end

		if p.ui_accent then
			flags["ui_accent_color"] = p.ui_accent
			library:update_theme("accent", p.ui_accent)
			if library.config_flags and library.config_flags["ui_accent_color"] then
				pcall(function() library.config_flags["ui_accent_color"](p.ui_accent) end)
			end
		end

		if p.ui_anim_mode then
			flags["ui_anim_mode"] = p.ui_anim_mode
			if library.config_flags and library.config_flags["ui_anim_mode"] then
				pcall(function() library.config_flags["ui_anim_mode"]({ p.ui_anim_mode }) end)
			end
		end
		if p.ui_color_mode then
			flags["ui_color_mode"] = p.ui_color_mode
			if library.config_flags and library.config_flags["ui_color_mode"] then
				pcall(function() library.config_flags["ui_color_mode"]({ p.ui_color_mode }) end)
			end
		end
		if p.ui_anim_color then
			flags["ui_anim_color"] = p.ui_anim_color
			if library.config_flags and library.config_flags["ui_anim_color"] then
				pcall(function() library.config_flags["ui_anim_color"](p.ui_anim_color) end)
			end
		end
		if p.ui_anim_speed then
			flags["ui_anim_speed"] = p.ui_anim_speed
			if library.config_flags and library.config_flags["ui_anim_speed"] then
				pcall(function() library.config_flags["ui_anim_speed"](p.ui_anim_speed) end)
			end
		end

		if p.watermark_enabled ~= nil then
			flags["watermark_enabled"] = p.watermark_enabled
			if window.toggle_watermark then
				window.toggle_watermark(p.watermark_enabled)
			end
			if library.config_flags and library.config_flags["watermark_enabled"] then
				pcall(function() library.config_flags["watermark_enabled"](p.watermark_enabled) end)
			end
		end
		if p.wm_anim_mode then
			flags["watermark_anim_mode"] = p.wm_anim_mode
			if library.config_flags and library.config_flags["watermark_anim_mode"] then
				pcall(function() library.config_flags["watermark_anim_mode"]({ p.wm_anim_mode }) end)
			end
		end
		if p.wm_color_mode then
			flags["watermark_color_mode"] = p.wm_color_mode
			if library.config_flags and library.config_flags["watermark_color_mode"] then
				pcall(function() library.config_flags["watermark_color_mode"]({ p.wm_color_mode }) end)
			end
		end
		if p.wm_anim_color then
			flags["watermark_anim_color"] = p.wm_anim_color
			if library.config_flags and library.config_flags["watermark_anim_color"] then
				pcall(function() library.config_flags["watermark_anim_color"](p.wm_anim_color) end)
			end
		end
		if p.wm_anim_speed then
			flags["watermark_anim_speed"] = p.wm_anim_speed
			if library.config_flags and library.config_flags["watermark_anim_speed"] then
				pcall(function() library.config_flags["watermark_anim_speed"](p.wm_anim_speed) end)
			end
		end

		-- Outline / Accent Line settings (Fallback to ui_anim_mode / ui_accent if not specifically set)
		local outline_a = p.outline_anim_mode or "RGB Spectrum Flow"
		local outline_c = p.outline_color_mode or p.ui_color_mode or "Theme Accent"
		local outline_col = p.outline_anim_color or p.ui_accent or Color3.fromRGB(255, 45, 85)
		local outline_spd = p.outline_anim_speed or p.ui_anim_speed or 1
		local outline_enabled = (p.outline_anim_enabled ~= nil) and p.outline_anim_enabled or (flags["outline_anim_enabled"] == true)

		flags["outline_anim_enabled"] = outline_enabled
		flags["outline_anim_mode"] = outline_a
		flags["outline_color_mode"] = outline_c
		flags["outline_anim_color"] = outline_col
		flags["outline_anim_speed"] = outline_spd
		if library.config_flags then
			pcall(function() library.config_flags["outline_anim_enabled"](outline_enabled) end)
			pcall(function() library.config_flags["outline_anim_mode"]({ outline_a }) end)
			pcall(function() library.config_flags["outline_color_mode"]({ outline_c }) end)
			pcall(function() library.config_flags["outline_anim_color"](outline_col) end)
			pcall(function() library.config_flags["outline_anim_speed"](outline_spd) end)
		end

		-- Keybinds settings (Fallback to watermark / UI settings)
		local kb_a = p.kb_anim_mode or p.wm_anim_mode or "Reverse Typing"
		local kb_c = p.kb_color_mode or p.wm_color_mode or "Theme Accent"
		local kb_col = p.kb_anim_color or p.wm_anim_color or p.ui_accent or Color3.fromRGB(75, 90, 255)
		local kb_spd = p.kb_anim_speed or p.wm_anim_speed or 1
		local kb_enabled = (p.keybinds_enabled ~= nil) and p.keybinds_enabled or (flags["keybinds_enabled"] == true)

		flags["keybinds_enabled"] = kb_enabled
		if window.toggle_keybinds then window.toggle_keybinds(kb_enabled) end
		flags["keybinds_anim_mode"] = kb_a
		flags["keybinds_color_mode"] = kb_c
		flags["keybinds_anim_color"] = kb_col
		flags["keybinds_anim_speed"] = kb_spd
		if library.config_flags then
			pcall(function() library.config_flags["keybinds_enabled"](kb_enabled) end)
			pcall(function() library.config_flags["keybinds_anim_mode"]({ kb_a }) end)
			pcall(function() library.config_flags["keybinds_color_mode"]({ kb_c }) end)
			pcall(function() library.config_flags["keybinds_anim_color"](kb_col) end)
			pcall(function() library.config_flags["keybinds_anim_speed"](kb_spd) end)
		end

		-- Playerlist settings (Fallback to UI settings)
		local pl_a = p.pl_anim_mode or p.ui_anim_mode or "Gradient Slide"
		local pl_c = p.pl_color_mode or p.ui_color_mode or "Theme Accent"
		local pl_col = p.pl_anim_color or p.ui_anim_color or p.ui_accent or Color3.fromRGB(75, 90, 255)
		local pl_spd = p.pl_anim_speed or p.ui_anim_speed or 1
		local pl_enabled = (p.player_list ~= nil) and p.player_list or (flags["player_list"] == true)

		flags["player_list"] = pl_enabled
		if window.toggle_playerlist then window.toggle_playerlist(pl_enabled) end
		flags["playerlist_anim_mode"] = pl_a
		flags["playerlist_color_mode"] = pl_c
		flags["playerlist_anim_color"] = pl_col
		flags["playerlist_anim_speed"] = pl_spd
		if library.config_flags then
			pcall(function() library.config_flags["player_list"](pl_enabled) end)
			pcall(function() library.config_flags["playerlist_anim_mode"]({ pl_a }) end)
			pcall(function() library.config_flags["playerlist_color_mode"]({ pl_c }) end)
			pcall(function() library.config_flags["playerlist_anim_color"](pl_col) end)
			pcall(function() library.config_flags["playerlist_anim_speed"](pl_spd) end)
		end

		_applying_preset = false
		library:notification({ text = "👑 Menu Mode: " .. mode_name .. " Applied!", time = 3 })
	end

	-- Cinematic Scenery Presets derived from Menu Mode themes
	local visual_scenery_list = {
		"Hearing Her Voice",
		"Blood Moon Demon",
		"Cyberpunk 2077",
		"Sakura Blossom",
		"Hellfire Diablo",
		"Primordial Frost",
		"Matrix Overdrive",
		"Last Summer",
		"Eldritch Void",
		"Just A Memory",
		"Why Did You Leave",
		"One Last Stop",
		"You Were The Only Light I Needed",
		"Dying for someone who moved on.",
		"I wish we could watch them again...",
		"maybe this sunset was all we needed...",
		"Custom",
	}

	local visual_scenery_presets = {
		["Hearing Her Voice"] = {
			-- Viễn cảnh: Nửa đêm thanh vắng dưới ánh trăng mờ, nỗi buồn man mác, mưa đêm rơi lách tách thì thầm, tone màu xanh xám nhạt (slate blue) u uất
			atmosphere_enabled = true,
			atmosphere_preset = "Custom",
			atmosphere_color = Color3.fromRGB(95, 115, 150),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(140, 155, 185),
			atmosphere_density = 0.42,
			atmosphere_glare = 0.8,
			atmosphere_haze = 3.0,

			skybox_enabled = true,
			skybox_preset = "Vibe Night",
			skybox_stars = 2500,
			skybox_celestial = true, -- Mặt trăng hiện rõ trên bầu trời đêm

			weather_enabled = true,
			weather_type = "Rain Storm",
			weather_intensity = 160,
			weather_speed = 36,
			weather_custom_color = false,
			weather_lightning = false,
			weather_audio = true,
			weather_audio_volume = 1.0,

			time_changer = true,
			time_changer_value = 0.0, -- Nửa đêm trăng sáng tĩnh lặng
			ambient_changer = true,
			ambient_color = Color3.fromRGB(80, 95, 125),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(55, 65, 90),
			brightness_changer = true,
			brightness_value = 0.8,
			exposure_changer = true,
			exposure_value = -0.1,
			shadow_softness = 0.4,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(90, 110, 140),
			custom_fog_start = 20,
			custom_fog_end = 650,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(205, 218, 235), -- Xanh xám nhạt melancholic
			color_correction_saturation = -0.35,
			color_correction_contrast = 0.22,
			bloom_enabled = true,
			bloom_intensity = 0.9,
			bloom_size = 20,
			bloom_threshold = 1.2,
			blur_enabled = true,
			blur_size = 3,
			sunrays_enabled = false,
		},

		["Blood Moon Demon"] = {
			-- Viễn cảnh: Đêm trăng máu tà ác, bầu trời đỏ rực như biển máu, sấm sét xé toạc màn đêm và mưa máu trút xuống
			atmosphere_enabled = true,
			atmosphere_preset = "Blood Moon Red",
			atmosphere_color = Color3.fromRGB(220, 25, 35),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(100, 10, 20),
			atmosphere_density = 0.48,
			atmosphere_glare = 2.5,
			atmosphere_haze = 4.0,

			skybox_enabled = true,
			skybox_preset = "Red Blood Sky",
			skybox_stars = 1500,
			skybox_celestial = true, -- Vầng trăng máu đỏ rực

			weather_enabled = true,
			weather_type = "Blood Rain",
			weather_intensity = 240,
			weather_speed = 48,
			weather_custom_color = false,
			weather_lightning = true, -- Sấm sét giáng liên hồi
			weather_audio = true,
			weather_audio_volume = 1.4,

			time_changer = true,
			time_changer_value = 0.0,
			ambient_changer = true,
			ambient_color = Color3.fromRGB(120, 20, 30),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(80, 10, 20),
			brightness_changer = true,
			brightness_value = 1.2,
			exposure_changer = true,
			exposure_value = 0.1,
			shadow_softness = 0.2,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(130, 20, 30),
			custom_fog_start = 0,
			custom_fog_end = 500,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(255, 160, 170),
			color_correction_saturation = 0.85,
			color_correction_contrast = 0.5,
			bloom_enabled = true,
			bloom_intensity = 2.0,
			bloom_size = 28,
			bloom_threshold = 1.0,
			blur_enabled = false,
			sunrays_enabled = false,
		},

		["Cyberpunk 2077"] = {
			-- Viễn cảnh: Đô thị ngầm Night City tương lai ngập trong ánh đèn neon cyan & magenta, mưa axit lấp lánh phản chiếu mặt đường
			atmosphere_enabled = true,
			atmosphere_preset = "Cyberpunk Cyan",
			atmosphere_color = Color3.fromRGB(0, 240, 255),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(255, 0, 150),
			atmosphere_density = 0.35,
			atmosphere_glare = 2.0,
			atmosphere_haze = 2.8,

			skybox_enabled = true,
			skybox_preset = "Blue Space",
			skybox_stars = 4000,
			skybox_celestial = false,

			weather_enabled = true,
			weather_type = "Acid Rain",
			weather_intensity = 170,
			weather_speed = 40,
			weather_custom_color = false,
			weather_lightning = false,
			weather_audio = true,
			weather_audio_volume = 1.1,

			time_changer = true,
			time_changer_value = 22.0, -- Đêm đô thị tương lai
			ambient_changer = true,
			ambient_color = Color3.fromRGB(30, 80, 110),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(20, 40, 70),
			brightness_changer = true,
			brightness_value = 1.0,
			exposure_changer = true,
			exposure_value = 0.2,
			shadow_softness = 0.2,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(15, 60, 90),
			custom_fog_start = 50,
			custom_fog_end = 850,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(210, 255, 255),
			color_correction_saturation = 1.15,
			color_correction_contrast = 0.45,
			bloom_enabled = true,
			bloom_intensity = 2.2,
			bloom_size = 30,
			bloom_threshold = 1.1,
			blur_enabled = false,
			sunrays_enabled = false,
		},

		["Sakura Blossom"] = {
			-- Viễn cảnh: Buổi chiều tà êm đềm ở Nhật Bản cổ kính, ánh hoàng hôn dịu nhẹ nhuộm hồng không gian, những cánh hoa anh đào bay lượn trong gió chiều
			atmosphere_enabled = true,
			atmosphere_preset = "Custom",
			atmosphere_color = Color3.fromRGB(255, 185, 205),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(255, 220, 235),
			atmosphere_density = 0.22,
			atmosphere_glare = 3.0,
			atmosphere_haze = 1.5,

			skybox_enabled = true,
			skybox_preset = "Pink Blossom",
			skybox_stars = 1000,
			skybox_celestial = true, -- Mặt trời hoàng hôn dịu êm

			weather_enabled = true,
			weather_type = "Sakura Petals",
			weather_intensity = 130,
			weather_speed = 14,
			weather_custom_color = false,
			weather_lightning = false,
			weather_audio = false,

			time_changer = true,
			time_changer_value = 17.5, -- Hoàng hôn chiều tà thanh bình
			ambient_changer = true,
			ambient_color = Color3.fromRGB(150, 110, 130),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(120, 80, 100),
			brightness_changer = true,
			brightness_value = 1.2,
			exposure_changer = true,
			exposure_value = 0.05,
			shadow_softness = 0.5,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(240, 180, 200),
			custom_fog_start = 80,
			custom_fog_end = 1200,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(255, 240, 248),
			color_correction_saturation = 0.35,
			color_correction_contrast = 0.15,
			bloom_enabled = true,
			bloom_intensity = 1.1,
			bloom_size = 22,
			bloom_threshold = 1.2,
			blur_enabled = true,
			blur_size = 2,
			sunrays_enabled = true,
			sunrays_intensity = 0.45,
			sunrays_spread = 0.85,
		},

		["Hellfire Diablo"] = {
			-- Viễn cảnh: Hỏa ngục rực cháy vô tận, tàn tro than hồng và lửa địa ngục bốc lên ngùn ngụt, không khí nung chảy kim loại
			atmosphere_enabled = true,
			atmosphere_preset = "Custom",
			atmosphere_color = Color3.fromRGB(255, 80, 15),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(180, 25, 0),
			atmosphere_density = 0.52,
			atmosphere_glare = 4.5,
			atmosphere_haze = 4.8,

			skybox_enabled = true,
			skybox_preset = "Red Blood Sky",
			skybox_stars = 500,
			skybox_celestial = false,

			weather_enabled = true,
			weather_type = "Hell Embers",
			weather_intensity = 260,
			weather_speed = 16,
			weather_custom_color = false,
			weather_lightning = false,
			weather_audio = true,
			weather_audio_volume = 1.3,

			time_changer = true,
			time_changer_value = 13.0,
			ambient_changer = true,
			ambient_color = Color3.fromRGB(140, 45, 10),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(90, 25, 5),
			brightness_changer = true,
			brightness_value = 1.5,
			exposure_changer = true,
			exposure_value = 0.2,
			shadow_softness = 0.1,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(180, 40, 10),
			custom_fog_start = 10,
			custom_fog_end = 450,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(255, 205, 160),
			color_correction_saturation = 0.75,
			color_correction_contrast = 0.55,
			bloom_enabled = true,
			bloom_intensity = 2.6,
			bloom_size = 35,
			bloom_threshold = 1.0,
			blur_enabled = false,
			sunrays_enabled = false,
		},

		["Primordial Frost"] = {
			-- Viễn cảnh: Kỷ băng hà vĩnh cửu, bão tuyết trắng xóa cuộn trào dưới bầu trời sao băng giá buốt thấu xương
			atmosphere_enabled = true,
			atmosphere_preset = "Custom",
			atmosphere_color = Color3.fromRGB(160, 220, 255),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(210, 240, 255),
			atmosphere_density = 0.42,
			atmosphere_glare = 1.2,
			atmosphere_haze = 3.2,

			skybox_enabled = true,
			skybox_preset = "Blue Space",
			skybox_stars = 4500,
			skybox_celestial = true, -- Mặt trăng băng tuyết

			weather_enabled = true,
			weather_type = "Winter Snow",
			weather_intensity = 200,
			weather_speed = 22,
			weather_custom_color = false,
			weather_lightning = false,
			weather_audio = true,
			weather_audio_volume = 1.0,

			time_changer = true,
			time_changer_value = 20.5, -- Đêm băng tuyết
			ambient_changer = true,
			ambient_color = Color3.fromRGB(90, 130, 170),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(60, 95, 130),
			brightness_changer = true,
			brightness_value = 0.9,
			exposure_changer = true,
			exposure_value = 0.0,
			shadow_softness = 0.3,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(175, 220, 255),
			custom_fog_start = 10,
			custom_fog_end = 700,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Cold Winter",
			color_correction_tint = Color3.fromRGB(190, 225, 255),
			color_correction_saturation = -0.25,
			color_correction_contrast = 0.35,
			bloom_enabled = true,
			bloom_intensity = 1.3,
			bloom_size = 24,
			bloom_threshold = 1.2,
			blur_enabled = false,
			sunrays_enabled = false,
		},

		["Matrix Overdrive"] = {
			-- Viễn cảnh: Không gian ma trận số học thực tế ảo ngập tràn mã nguồn neon xanh lục rơi rải rác giữa bóng tối máy chủ
			atmosphere_enabled = true,
			atmosphere_preset = "Custom",
			atmosphere_color = Color3.fromRGB(20, 255, 110),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(0, 90, 35),
			atmosphere_density = 0.46,
			atmosphere_glare = 2.2,
			atmosphere_haze = 3.6,

			skybox_enabled = true,
			skybox_preset = "Black Storm",
			skybox_stars = 2000,
			skybox_celestial = false,

			weather_enabled = true,
			weather_type = "Acid Rain",
			weather_intensity = 210,
			weather_speed = 42,
			weather_custom_color = true,
			weather_color = Color3.fromRGB(40, 255, 120),
			weather_lightning = false,
			weather_audio = true,
			weather_audio_volume = 1.1,

			time_changer = true,
			time_changer_value = 0.0, -- Nửa đêm số hóa
			ambient_changer = true,
			ambient_color = Color3.fromRGB(20, 80, 40),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(10, 45, 20),
			brightness_changer = true,
			brightness_value = 1.0,
			exposure_changer = true,
			exposure_value = 0.1,
			shadow_softness = 0.1,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(15, 70, 35),
			custom_fog_start = 20,
			custom_fog_end = 600,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Matrix Green",
			color_correction_tint = Color3.fromRGB(150, 255, 170),
			color_correction_saturation = 0.35,
			color_correction_contrast = 0.6,
			bloom_enabled = true,
			bloom_intensity = 2.1,
			bloom_size = 28,
			bloom_threshold = 1.1,
			blur_enabled = false,
			sunrays_enabled = false,
		},

		["Last Summer"] = {
			-- Viễn cảnh: Buổi chiều tà cuối hạ chan chứa hoài niệm, ánh nắng vàng mật ong ấm áp le lói, đom đóm thắp sáng không gian khi hoàng hôn buông xuống
			atmosphere_enabled = true,
			atmosphere_preset = "Sunset Amber",
			atmosphere_color = Color3.fromRGB(255, 185, 75),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(255, 120, 50),
			atmosphere_density = 0.28,
			atmosphere_glare = 3.8,
			atmosphere_haze = 2.0,

			skybox_enabled = true,
			skybox_preset = "Realistic Sunset",
			skybox_stars = 1200,
			skybox_celestial = true, -- Mặt trời hoàng hôn rực rỡ

			weather_enabled = true,
			weather_type = "Night Fireflies",
			weather_intensity = 110,
			weather_speed = 5,
			weather_custom_color = false,
			weather_lightning = false,
			weather_audio = false,

			time_changer = true,
			time_changer_value = 17.2, -- Hoàng hôn vàng ươm
			ambient_changer = true,
			ambient_color = Color3.fromRGB(150, 115, 70),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(110, 80, 45),
			brightness_changer = true,
			brightness_value = 1.3,
			exposure_changer = true,
			exposure_value = 0.1,
			shadow_softness = 0.4,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(220, 160, 90),
			custom_fog_start = 50,
			custom_fog_end = 1100,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Warm Sunset",
			color_correction_tint = Color3.fromRGB(255, 230, 200),
			color_correction_saturation = 0.55,
			color_correction_contrast = 0.3,
			bloom_enabled = true,
			bloom_intensity = 1.4,
			bloom_size = 24,
			bloom_threshold = 1.2,
			blur_enabled = false,
			sunrays_enabled = true,
			sunrays_intensity = 0.6,
			sunrays_spread = 0.85,
		},

		["Eldritch Void"] = {
			-- Viễn cảnh: Vực sâu hư vô vũ trụ cổ đại, tinh vân tím huyền ảo chớp nháy cùng bụi sao ma thuật trôi lơ lửng giữa hư vô
			atmosphere_enabled = true,
			atmosphere_preset = "Deep Void",
			atmosphere_color = Color3.fromRGB(115, 30, 210),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(45, 10, 90),
			atmosphere_density = 0.48,
			atmosphere_glare = 2.8,
			atmosphere_haze = 4.2,

			skybox_enabled = true,
			skybox_preset = "Deep Space Stars",
			skybox_stars = 5000,
			skybox_celestial = false,

			weather_enabled = true,
			weather_type = "Cosmic Stardust",
			weather_intensity = 180,
			weather_speed = 9,
			weather_custom_color = false,
			weather_lightning = false,
			weather_audio = true,
			weather_audio_volume = 1.0,

			time_changer = true,
			time_changer_value = 1.0, -- Đêm huyền bí
			ambient_changer = true,
			ambient_color = Color3.fromRGB(60, 25, 95),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(35, 15, 60),
			brightness_changer = true,
			brightness_value = 0.85,
			exposure_changer = true,
			exposure_value = 0.05,
			shadow_softness = 0.2,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(75, 20, 130),
			custom_fog_start = 30,
			custom_fog_end = 650,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(225, 185, 255),
			color_correction_saturation = 0.65,
			color_correction_contrast = 0.42,
			bloom_enabled = true,
			bloom_intensity = 1.9,
			bloom_size = 28,
			bloom_threshold = 1.1,
			blur_enabled = false,
			sunrays_enabled = false,
		},

		["Just A Memory"] = {
			-- Viễn cảnh: Hồi ức phủ bụi thời gian phai mờ, buổi sớm mờ sương tĩnh lặng, vạn vật gần như đơn sắc hoài cổ, một nét u buồn trầm mặc
			atmosphere_enabled = true,
			atmosphere_preset = "Silent Hill Fog",
			atmosphere_color = Color3.fromRGB(145, 145, 155),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(190, 190, 195),
			atmosphere_density = 0.52,
			atmosphere_glare = 0.6,
			atmosphere_haze = 4.0,

			skybox_enabled = true,
			skybox_preset = "Purple Day",
			skybox_stars = 1000,
			skybox_celestial = false,

			weather_enabled = true,
			weather_type = "Winter Snow",
			weather_intensity = 70,
			weather_speed = 10,
			weather_custom_color = false,
			weather_lightning = false,
			weather_audio = false,

			time_changer = true,
			time_changer_value = 5.6, -- Rạng sáng mờ sương tịch mịch
			ambient_changer = true,
			ambient_color = Color3.fromRGB(110, 110, 115),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(80, 80, 85),
			brightness_changer = true,
			brightness_value = 0.9,
			exposure_changer = true,
			exposure_value = -0.15,
			shadow_softness = 0.5,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(140, 140, 145),
			custom_fog_start = 10,
			custom_fog_end = 550,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Cinematic Noir",
			color_correction_tint = Color3.fromRGB(235, 230, 225),
			color_correction_saturation = -0.75, -- Gần như đơn sắc phủ bụi thời gian
			color_correction_contrast = 0.28,
			bloom_enabled = true,
			bloom_intensity = 0.8,
			bloom_size = 18,
			bloom_threshold = 1.3,
			blur_enabled = true,
			blur_size = 3,
			sunrays_enabled = false,
		},

		["Why Did You Leave"] = {
			-- Viễn cảnh: Nỗi đau chia ly dưới ánh đèn đường mùa đông, đôi mắt ngấn lệ, mưa tuyết buốt giá lất phất, không gian xanh chàm u uất tịch mịch
			atmosphere_enabled = true,
			atmosphere_preset = "Custom",
			atmosphere_color = Color3.fromRGB(75, 95, 145),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(130, 160, 210),
			atmosphere_density = 0.40,
			atmosphere_glare = 1.2,
			atmosphere_haze = 3.2,

			skybox_enabled = true,
			skybox_preset = "Vibe Night",
			skybox_stars = 2800,
			skybox_celestial = true, -- Mặt trăng mờ sau màn mây

			weather_enabled = true,
			weather_type = "Rain Storm",
			weather_intensity = 130,
			weather_speed = 28,
			weather_custom_color = true,
			weather_color = Color3.fromRGB(175, 205, 245), -- Hạt mưa tuyết xanh lạnh lơ lửng
			weather_lightning = false,
			weather_audio = true,
			weather_audio_volume = 0.9,

			time_changer = true,
			time_changer_value = 0.2, -- Nửa đêm lạnh buốt
			ambient_changer = true,
			ambient_color = Color3.fromRGB(65, 80, 120),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(45, 55, 85),
			brightness_changer = true,
			brightness_value = 0.85,
			exposure_changer = true,
			exposure_value = -0.1,
			shadow_softness = 0.4,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(70, 90, 130),
			custom_fog_start = 15,
			custom_fog_end = 620,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(200, 220, 250), -- Tone xanh lệ đẫm lạnh
			color_correction_saturation = -0.30,
			color_correction_contrast = 0.26,
			bloom_enabled = true,
			bloom_intensity = 1.3,
			bloom_size = 24,
			bloom_threshold = 1.1,
			blur_enabled = true,
			blur_size = 3, -- Ánh nhìn nhạt nhòa ngấn lệ
			sunrays_enabled = false,
		},

		["One Last Stop"] = {
			-- Viễn cảnh: Sân ga tuyết rơi hoang vắng lúc nửa đêm, chuyến tàu cuối cùng chia cách đôi ta, khăn len hồng nhạt phất phơ giữa khói sương và đèn tín hiệu đỏ
			atmosphere_enabled = true,
			atmosphere_preset = "Custom",
			atmosphere_color = Color3.fromRGB(110, 115, 130),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(175, 180, 195),
			atmosphere_density = 0.55,
			atmosphere_glare = 1.0,
			atmosphere_haze = 4.5, -- Sương mù dày đặc đường ray

			skybox_enabled = true,
			skybox_preset = "Black Storm",
			skybox_stars = 800,
			skybox_celestial = false,

			weather_enabled = true,
			weather_type = "Winter Snow",
			weather_intensity = 190,
			weather_speed = 16,
			weather_custom_color = true,
			weather_color = Color3.fromRGB(240, 240, 245), -- Tuyết trắng rơi lả tả trên sân ga
			weather_lightning = false,
			weather_audio = false,

			time_changer = true,
			time_changer_value = 23.8, -- Nửa đêm tịch mịch tại sân ga
			ambient_changer = true,
			ambient_color = Color3.fromRGB(80, 82, 92),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(55, 58, 68),
			brightness_changer = true,
			brightness_value = 0.95,
			exposure_changer = true,
			exposure_value = -0.05,
			shadow_softness = 0.5,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(120, 125, 140),
			custom_fog_start = 0,
			custom_fog_end = 480,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(235, 225, 235), -- Hơi ánh sắc khăn len phai màu
			color_correction_saturation = -0.55, -- Điện ảnh noir pha tro bụi
			color_correction_contrast = 0.35,
			bloom_enabled = true,
			bloom_intensity = 1.5, -- Đèn sân ga tỏa sáng cô đơn
			bloom_size = 26,
			bloom_threshold = 1.0,
			blur_enabled = true,
			blur_size = 3,
			sunrays_enabled = false,
		},

		["You Were The Only Light I Needed"] = {
			-- Viễn cảnh: Chiều hoàng hôn tím rực hoài niệm, ánh nắng vàng hổ phách cuối ngày le lói trên mái tóc người con gái, vệt nắng xiên tà qua lăng kính máy quay retro "you were the only light i needed"
			atmosphere_enabled = true,
			atmosphere_preset = "Custom",
			atmosphere_color = Color3.fromRGB(175, 75, 215), -- Tím hoàng hôn mơ màng
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(255, 135, 55), -- Ánh cam hổ phách tà dương
			atmosphere_density = 0.28,
			atmosphere_glare = 3.6, -- Vệt sáng rực chiếu thẳng vào ống kính
			atmosphere_haze = 2.4,

			skybox_enabled = true,
			skybox_preset = "Realistic Sunset",
			skybox_stars = 1500,
			skybox_celestial = true, -- Mặt trời tà dương rực rỡ sắp lặn

			weather_enabled = true,
			weather_type = "Night Fireflies",
			weather_intensity = 120,
			weather_speed = 6,
			weather_custom_color = true,
			weather_color = Color3.fromRGB(255, 210, 120), -- Bụi nắng hoàng hôn vàng óng lơ lửng
			weather_lightning = false,
			weather_audio = false,

			time_changer = true,
			time_changer_value = 17.75, -- 17h45 chiều hoàng hôn rực rỡ nhất
			ambient_changer = true,
			ambient_color = Color3.fromRGB(155, 100, 145),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(125, 70, 105),
			brightness_changer = true,
			brightness_value = 1.35,
			exposure_changer = true,
			exposure_value = 0.1,
			shadow_softness = 0.4,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(210, 130, 175),
			custom_fog_start = 40,
			custom_fog_end = 950,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(255, 228, 238), -- Tone tím hồng cam ấm áp retro anime
			color_correction_saturation = 0.48, -- Màu sắc no nê hoài niệm
			color_correction_contrast = 0.28,
			bloom_enabled = true,
			bloom_intensity = 1.65, -- Tỏa sáng ấm áp quanh nhân vật
			bloom_size = 28,
			bloom_threshold = 1.05,
			blur_enabled = false,
			sunrays_enabled = true,
			sunrays_intensity = 0.78, -- Tia nắng hoàng hôn rọi xiên qua ống kính
			sunrays_spread = 0.90,
		},

		["Dying For Someone"] = {
			-- Viễn cảnh: Chiều tà muộn ảm đạm, cô gái đứng hút thuốc nhìn theo bóng hình người cũ đã bước tiếp, làn khói mỏng manh tan biến vào màn đêm tím than
			atmosphere_enabled = true,
			atmosphere_preset = "Custom",
			atmosphere_color = Color3.fromRGB(120, 80, 115), -- Tím xám khói thuốc
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(180, 65, 40), -- Cam tàn thuốc âm ỉ
			atmosphere_density = 0.40,
			atmosphere_glare = 1.8,
			atmosphere_haze = 3.5,

			skybox_enabled = true,
			skybox_preset = "Realistic Sunset",
			skybox_stars = 2000,
			skybox_celestial = true,

			weather_enabled = true,
			weather_type = "Night Fireflies",
			weather_intensity = 90,
			weather_speed = 4,
			weather_custom_color = true,
			weather_color = Color3.fromRGB(190, 180, 195), -- Tàn tro khói thuốc lơ lửng
			weather_lightning = false,
			weather_audio = false,

			time_changer = true,
			time_changer_value = 18.5, -- Chạng vạng tối vừa tắt nắng
			ambient_changer = true,
			ambient_color = Color3.fromRGB(95, 75, 95),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(65, 50, 70),
			brightness_changer = true,
			brightness_value = 0.95,
			exposure_changer = true,
			exposure_value = -0.05,
			shadow_softness = 0.3,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(115, 85, 110),
			custom_fog_start = 20,
			custom_fog_end = 650,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(220, 205, 215), -- Xám tro tím u uất
			color_correction_saturation = -0.42,
			color_correction_contrast = 0.35,
			bloom_enabled = true,
			bloom_intensity = 1.2,
			bloom_size = 20,
			bloom_threshold = 1.15,
			blur_enabled = false,
			sunrays_enabled = false,
		},
		["Dying for someone who moved on."] = {
			atmosphere_enabled = true,
			atmosphere_preset = "Custom",
			atmosphere_color = Color3.fromRGB(120, 80, 115),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(180, 65, 40),
			atmosphere_density = 0.40,
			atmosphere_glare = 1.8,
			atmosphere_haze = 3.5,
			skybox_enabled = true,
			skybox_preset = "Realistic Sunset",
			skybox_stars = 2000,
			skybox_celestial = true,
			weather_enabled = true,
			weather_type = "Night Fireflies",
			weather_intensity = 90,
			weather_speed = 4,
			weather_custom_color = true,
			weather_color = Color3.fromRGB(190, 180, 195),
			weather_lightning = false,
			weather_audio = false,
			time_changer = true,
			time_changer_value = 18.5,
			ambient_changer = true,
			ambient_color = Color3.fromRGB(95, 75, 95),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(65, 50, 70),
			brightness_changer = true,
			brightness_value = 0.95,
			exposure_changer = true,
			exposure_value = -0.05,
			shadow_softness = 0.3,
			global_shadows = true,
			fullbright = false,
			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(115, 85, 110),
			custom_fog_start = 20,
			custom_fog_end = 650,
			no_fog = false,
			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(220, 205, 215),
			color_correction_saturation = -0.42,
			color_correction_contrast = 0.35,
			bloom_enabled = true,
			bloom_intensity = 1.2,
			bloom_size = 20,
			bloom_threshold = 1.15,
			blur_enabled = false,
			sunrays_enabled = false,
		},

		["Wish We Could Watch Again"] = {
			-- Viễn cảnh: Đêm lễ hội pháo hoa mùa đông, tuyết rơi lấp lánh, cô gái quàng khăn len đỏ níu tay người thương ngắm nhìn pháo hoa rực sáng trời đêm
			atmosphere_enabled = true,
			atmosphere_preset = "Custom",
			atmosphere_color = Color3.fromRGB(135, 30, 85), -- Tím thẫm lễ hội
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(240, 60, 100), -- Ánh pháo hoa đỏ hồng
			atmosphere_density = 0.35,
			atmosphere_glare = 3.8,
			atmosphere_haze = 2.8,

			skybox_enabled = true,
			skybox_preset = "Pink Blossom",
			skybox_stars = 3500,
			skybox_celestial = true,

			weather_enabled = true,
			weather_type = "Winter Snow",
			weather_intensity = 160,
			weather_speed = 14,
			weather_custom_color = true,
			weather_color = Color3.fromRGB(255, 240, 245), -- Tuyết trắng lễ hội
			weather_lightning = false,
			weather_audio = false,

			time_changer = true,
			time_changer_value = 21.2, -- Đêm lễ hội pháo hoa
			ambient_changer = true,
			ambient_color = Color3.fromRGB(120, 45, 80),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(80, 25, 55),
			brightness_changer = true,
			brightness_value = 1.25,
			exposure_changer = true,
			exposure_value = 0.1,
			shadow_softness = 0.3,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(110, 25, 75),
			custom_fog_start = 30,
			custom_fog_end = 800,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(255, 220, 235), -- Đỏ hồng khăn len ấm áp
			color_correction_saturation = 0.55,
			color_correction_contrast = 0.38,
			bloom_enabled = true,
			bloom_intensity = 2.2, -- Pháo hoa bùng sáng lung linh
			bloom_size = 32,
			bloom_threshold = 1.0,
			blur_enabled = false,
			sunrays_enabled = false,
		},
		["I wish we could watch them again..."] = {
			atmosphere_enabled = true,
			atmosphere_preset = "Custom",
			atmosphere_color = Color3.fromRGB(135, 30, 85),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(240, 60, 100),
			atmosphere_density = 0.35,
			atmosphere_glare = 3.8,
			atmosphere_haze = 2.8,
			skybox_enabled = true,
			skybox_preset = "Pink Blossom",
			skybox_stars = 3500,
			skybox_celestial = true,
			weather_enabled = true,
			weather_type = "Winter Snow",
			weather_intensity = 160,
			weather_speed = 14,
			weather_custom_color = true,
			weather_color = Color3.fromRGB(255, 240, 245),
			weather_lightning = false,
			weather_audio = false,
			time_changer = true,
			time_changer_value = 21.2,
			ambient_changer = true,
			ambient_color = Color3.fromRGB(120, 45, 80),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(80, 25, 55),
			brightness_changer = true,
			brightness_value = 1.25,
			exposure_changer = true,
			exposure_value = 0.1,
			shadow_softness = 0.3,
			global_shadows = true,
			fullbright = false,
			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(110, 25, 75),
			custom_fog_start = 30,
			custom_fog_end = 800,
			no_fog = false,
			color_correction_enabled = true,
			color_correction_preset = "Custom",
			color_correction_tint = Color3.fromRGB(255, 220, 235),
			color_correction_saturation = 0.55,
			color_correction_contrast = 0.38,
			bloom_enabled = true,
			bloom_intensity = 2.2,
			bloom_size = 32,
			bloom_threshold = 1.0,
			blur_enabled = false,
			sunrays_enabled = false,
		},

		["Maybe This Sunset"] = {
			-- Viễn cảnh: Chiều hoàng hôn nắng vàng mật ong rót xuống đồng cỏ hoa vàng, cô gái nhâm nhi ly kem tuyết đào, ánh nắng xiên tà chan chứa sự chữa lành
			atmosphere_enabled = true,
			atmosphere_preset = "Sunset Amber",
			atmosphere_color = Color3.fromRGB(255, 195, 70), -- Vàng mật ong rạng ngời
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(255, 120, 30), -- Cam tà dương ấm áp
			atmosphere_density = 0.22,
			atmosphere_glare = 4.2,
			atmosphere_haze = 1.8,

			skybox_enabled = true,
			skybox_preset = "Realistic Sunset",
			skybox_stars = 1200,
			skybox_celestial = true, -- Mặt trời hoàng hôn vàng óng ả

			weather_enabled = true,
			weather_type = "Night Fireflies",
			weather_intensity = 130,
			weather_speed = 5,
			weather_custom_color = true,
			weather_color = Color3.fromRGB(255, 230, 120), -- Bụi phấn hoa vàng óng lơ lửng
			weather_lightning = false,
			weather_audio = false,

			time_changer = true,
			time_changer_value = 17.5, -- Hoàng hôn vàng mật ong đẹp nhất trong ngày
			ambient_changer = true,
			ambient_color = Color3.fromRGB(165, 125, 65),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(130, 90, 45),
			brightness_changer = true,
			brightness_value = 1.45,
			exposure_changer = true,
			exposure_value = 0.12,
			shadow_softness = 0.45,
			global_shadows = true,
			fullbright = false,

			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(245, 185, 95),
			custom_fog_start = 60,
			custom_fog_end = 1200,
			no_fog = false,

			color_correction_enabled = true,
			color_correction_preset = "Warm Sunset",
			color_correction_tint = Color3.fromRGB(255, 245, 215), -- Nắng vàng mật ong ấm áp
			color_correction_saturation = 0.62,
			color_correction_contrast = 0.26,
			bloom_enabled = true,
			bloom_intensity = 1.75,
			bloom_size = 28,
			bloom_threshold = 1.1,
			blur_enabled = false,
			sunrays_enabled = true,
			sunrays_intensity = 0.95, -- Tia nắng rọi xiên tuyệt mỹ
			sunrays_spread = 0.98,
		},
		["maybe this sunset was all we needed..."] = {
			atmosphere_enabled = true,
			atmosphere_preset = "Sunset Amber",
			atmosphere_color = Color3.fromRGB(255, 195, 70),
			atmosphere_decay = true,
			atmosphere_decay_color = Color3.fromRGB(255, 120, 30),
			atmosphere_density = 0.22,
			atmosphere_glare = 4.2,
			atmosphere_haze = 1.8,
			skybox_enabled = true,
			skybox_preset = "Realistic Sunset",
			skybox_stars = 1200,
			skybox_celestial = true,
			weather_enabled = true,
			weather_type = "Night Fireflies",
			weather_intensity = 130,
			weather_speed = 5,
			weather_custom_color = true,
			weather_color = Color3.fromRGB(255, 230, 120),
			weather_lightning = false,
			weather_audio = false,
			time_changer = true,
			time_changer_value = 17.5,
			ambient_changer = true,
			ambient_color = Color3.fromRGB(165, 125, 65),
			outdoor_ambient_changer = true,
			outdoor_ambient_color = Color3.fromRGB(130, 90, 45),
			brightness_changer = true,
			brightness_value = 1.45,
			exposure_changer = true,
			exposure_value = 0.12,
			shadow_softness = 0.45,
			global_shadows = true,
			fullbright = false,
			custom_fog_enabled = true,
			custom_fog_color = Color3.fromRGB(245, 185, 95),
			custom_fog_start = 60,
			custom_fog_end = 1200,
			no_fog = false,
			color_correction_enabled = true,
			color_correction_preset = "Warm Sunset",
			color_correction_tint = Color3.fromRGB(255, 245, 215),
			color_correction_saturation = 0.62,
			color_correction_contrast = 0.26,
			bloom_enabled = true,
			bloom_intensity = 1.75,
			bloom_size = 28,
			bloom_threshold = 1.1,
			blur_enabled = false,
			sunrays_enabled = true,
			sunrays_intensity = 0.95,
			sunrays_spread = 0.98,
		},
	}

	local function apply_visual_scenery(scenery_name)
		local p = visual_scenery_presets[scenery_name]
		if not p then return end

		for flag_name, val in pairs(p) do
			flags[flag_name] = val
			if library.config_flags and library.config_flags[flag_name] then
				pcall(function()
					if type(val) == "string" then
						library.config_flags[flag_name]({ val })
					else
						library.config_flags[flag_name](val)
					end
				end)
			end
		end

		-- Đồng bộ kích hoạt toàn bộ Theme & Animation riêng của Preset tương ứng
		if menu_mode_presets[scenery_name] then
			apply_menu_mode(scenery_name)
		end

		library:notification({ text = "🎬 Visual Scenery: " .. scenery_name .. " Applied!", time = 3 })
	end

	-- 0. Master Preset: Menu Mode (Nằm trên cùng, điều khiển trọn bộ như ảnh)
	menu_section:dropdown({
		name = "Menu Mode",
		flag = "menu_master_mode",
		items = menu_modes_list,
		multi = false,
		default = "Custom",
		callback = function(val)
			if type(val) == "table" then val = val[1] end
			if val and val ~= "Custom" then
				apply_menu_mode(val)
			end
		end
	})

	-- 0.5 Master Visual Scenery: Menu Mode Visual +++ (Dưới dropdown Menu Mode)
	menu_section:dropdown({
		name = "Menu Mode Visual +++",
		flag = "menu_mode_visual_ppp",
		items = visual_scenery_list,
		multi = false,
		default = "Custom",
		callback = function(val)
			if type(val) == "table" then val = val[1] end
			if val and val ~= "Custom" then
				apply_visual_scenery(val)
			end
		end
	})

	-- 1. UI Mode (Preset Themes - 35 HvH Styles)
	menu_section:dropdown({
		name = "Ui mode",
		flag = "ui_theme_mode",
		items = ui_modes_list,
		multi = false,
		default = "Custom",
		callback = function(val)
			if type(val) == "table" then val = val[1] end
			if val and library.set_ui_mode then
				library:set_ui_mode(val)
			end
			mark_custom_mode()
		end
	})

	-- 2. UI Theme Accent (Manual Color Picker)
	menu_section:colorpicker({
		name = "UI Theme Accent",
		flag = "ui_accent_color",
		color = Color3.fromRGB(255, 255, 255),
		callback = function(color)
			library:update_theme("accent", color)
			mark_custom_mode()
		end
	})

	-- 3. Menu Open/Close Key
	menu_section:keybind({
		name = "Menu Key",
		flag = "menu_key",
		default = Enum.KeyCode.RightControl,
		display = "menu",
		callback = window.set_menu_visibility,
	})

	-- 4. Outline / Accent Line Animation Controls
	menu_section:toggle({
		name = "Outline Animation",
		flag = "outline_anim_enabled",
		default = false,
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:dropdown({
		name = "Outline Anim Mode",
		flag = "outline_anim_mode",
		items = outline_anim_modes_list,
		multi = false,
		default = "None",
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:dropdown({
		name = "Color Animation Outline Mode",
		flag = "outline_color_mode",
		items = color_modes_list,
		multi = false,
		default = "Theme Accent",
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:colorpicker({
		name = "Animation Outline Color",
		flag = "outline_anim_color",
		color = Color3.fromRGB(255, 45, 85),
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:slider({
		name = "Animation Outline Speed",
		flag = "outline_anim_speed",
		min = 0.1,
		max = 5,
		default = 1,
		decimal = 0.1,
		callback = function()
			mark_custom_mode()
		end
	})

	-- 5. UI Name Animation Controls
	menu_section:dropdown({
		name = "Animation UI Mode",
		flag = "ui_anim_mode",
		items = anim_modes_list,
		multi = false,
		default = "Gradient Slide",
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:dropdown({
		name = "Color Animation UI Mode",
		flag = "ui_color_mode",
		items = color_modes_list,
		multi = false,
		default = "Theme Accent",
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:colorpicker({
		name = "Animation UI Color",
		flag = "ui_anim_color",
		color = Color3.fromRGB(75, 90, 255),
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:slider({
		name = "Animation UI Speed",
		flag = "ui_anim_speed",
		min = 0.1,
		max = 5,
		default = 1,
		decimal = 0.1,
		callback = function()
			mark_custom_mode()
		end
	})

	-- 6. Watermark Controls (Mặc định tắt trong Silent/Stealth mode)
	menu_section:toggle({
		name = "Watermark",
		flag = "watermark_enabled",
		default = false,
		callback = function(bool)
			flags["watermark_enabled"] = bool
			window.toggle_watermark(bool)
			if window.watermark_frame then
				window.watermark_frame.Visible = bool
			end
			mark_custom_mode()
		end
	})

	menu_section:dropdown({
		name = "Animation Watermark Mode",
		flag = "watermark_anim_mode",
		items = anim_modes_list,
		multi = false,
		default = "None",
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:dropdown({
		name = "Color Animation Watermark Mode",
		flag = "watermark_color_mode",
		items = color_modes_list,
		multi = false,
		default = "Theme Accent",
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:colorpicker({
		name = "Animation Watermark Color",
		flag = "watermark_anim_color",
		color = Color3.fromRGB(255, 255, 255),
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:slider({
		name = "Animation Watermark Speed",
		flag = "watermark_anim_speed",
		min = 0.1,
		max = 5,
		default = 1,
		decimal = 0.1,
		callback = function()
			mark_custom_mode()
		end
	})

	-- 7. Keybinds Controls (Mặc định tắt trong Silent/Stealth mode)
	menu_section:toggle({
		name = "Keybinds list",
		flag = "keybinds_enabled",
		default = false,
		callback = function(bool)
			flags["keybinds_enabled"] = bool
			if window.toggle_keybinds then
				window.toggle_keybinds(bool)
			elseif window.toggle_list then
				window.toggle_list(bool)
			end
			if window.keybinds_frame then
				window.keybinds_frame.Visible = bool
			end
			mark_custom_mode()
		end
	})

	menu_section:dropdown({
		name = "Animation Keybinds Mode",
		flag = "keybinds_anim_mode",
		items = anim_modes_list,
		multi = false,
		default = "None",
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:dropdown({
		name = "Color Animation Keybinds Mode",
		flag = "keybinds_color_mode",
		items = color_modes_list,
		multi = false,
		default = "Theme Accent",
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:colorpicker({
		name = "Animation Keybinds Color",
		flag = "keybinds_anim_color",
		color = Color3.fromRGB(255, 255, 255),
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:slider({
		name = "Animation Keybinds Speed",
		flag = "keybinds_anim_speed",
		min = 0.1,
		max = 5,
		default = 1,
		decimal = 0.1,
		callback = function()
			mark_custom_mode()
		end
	})

	-- 8. Player list Controls (Mặc định tắt trong Silent/Stealth mode)
	menu_section:toggle({
		name = "Player list",
		flag = "player_list",
		default = false,
		callback = function(bool)
			flags["player_list"] = bool
			window.toggle_playerlist(bool)
			if window.playerlist_frame then
				window.playerlist_frame.Visible = bool
			end
			mark_custom_mode()
		end
	})

	menu_section:dropdown({
		name = "Animation Playerlist Mode",
		flag = "playerlist_anim_mode",
		items = anim_modes_list,
		multi = false,
		default = "None",
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:dropdown({
		name = "Color Animation Playerlist Mode",
		flag = "playerlist_color_mode",
		items = color_modes_list,
		multi = false,
		default = "Theme Accent",
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:colorpicker({
		name = "Animation Playerlist Color",
		flag = "playerlist_anim_color",
		color = Color3.fromRGB(255, 255, 255),
		callback = function()
			mark_custom_mode()
		end
	})

	menu_section:slider({
		name = "Animation Playerlist Speed",
		flag = "playerlist_anim_speed",
		min = 0.1,
		max = 5,
		default = 1,
		decimal = 0.1,
		callback = function()
			mark_custom_mode()
		end
	})

	-- High-Performance Quad Animation & Outline Engine (Zero FPS Lag)
	task.spawn(function()
		local full_title = "Neverlose - NVL"
		local full_wm = "Neverlose - NVL | private"
		local full_kb = "keybinds"
		local full_pl = "playerlist"
		local hacker_chars = { "0", "1", "X", "$", "#", "@", "%", "&", "*", "!", "?", "/", "<", ">", "~" }

		local title_state = { typing_idx = 1, typing_dir = 1, was_active = false, offset = 0 }
		local wm_state = { typing_idx = 1, typing_dir = 1, was_active = false, offset = 0.25 }
		local kb_state = { typing_idx = 1, typing_dir = 1, was_active = false, offset = 0.5 }
		local pl_state = { typing_idx = 1, typing_dir = 1, was_active = false, offset = 0.75 }

		local out_state_title = { was_active = false }
		local out_state_wm = { was_active = false }
		local out_state_kb = { was_active = false }
		local out_state_pl = { was_active = false }

		local function process_target(label, gradient, full_text, anim_mode, color_mode, custom_color, speed, target_id, st)
			if not label then return end

			-- FPS Guard 1: Skip UI Title calculation if window is closed
			if target_id == 1 and window and window.window_frame and not window.window_frame.Visible then
				return
			end

			-- FPS Guard 2: Skip Watermark calculation if watermark is disabled or hidden
			if target_id == 2 and window and window.watermark_frame and (not window.watermark_frame.Visible or not flags["watermark_enabled"]) then
				return
			end

			-- FPS Guard 3: Skip Keybinds calculation if keybinds frame is disabled or hidden
			if target_id == 3 and window and window.keybinds_frame and (not window.keybinds_frame.Visible or flags["keybinds_enabled"] == false) then
				return
			end

			-- FPS Guard 4: Skip Playerlist calculation if playerlist frame is disabled or hidden
			if target_id == 4 and window and window.playerlist_frame and (not window.playerlist_frame.Visible or flags["player_list"] == false) then
				return
			end

			local is_active = (anim_mode and anim_mode ~= "None")

			if not is_active then
				if st.was_active then
					if gradient then gradient.Enabled = false end
					label.Text = full_text
					label.TextTransparency = 0
					label.TextStrokeTransparency = 0.5
					if st.base_position then label.Position = st.base_position end
					label.TextColor3 = (target_id == 2) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 170)
					st.typing_idx = 1
					st.typing_dir = 1
					st.was_active = false
				end
				return
			end

			st.was_active = true
			if not st.base_position then
				st.base_position = label.Position
			end

			local curr_color = library.get_color_mode_color(color_mode, custom_color, speed, st.offset or 0)
			local now = tick()

			if anim_mode == "Typing" or anim_mode == "Reverse Typing" then
				if gradient then gradient.Enabled = false end
				label.TextTransparency = 0
				label.TextColor3 = curr_color
				label.Position = st.base_position

				if now - (st.last_step or 0) >= (0.12 / speed) then
					st.last_step = now
					st.typing_idx = (st.typing_idx or 1) + (st.typing_dir or 1)
					if st.typing_idx > #full_text then
						st.typing_dir = -1
						st.typing_idx = #full_text
					elseif st.typing_idx < 1 then
						st.typing_dir = 1
						st.typing_idx = 1
					end
				end

				if anim_mode == "Typing" then
					label.Text = string.sub(full_text, 1, st.typing_idx or 1)
				else
					local idx = st.typing_idx or 1
					local start_pos = math.max(1, #full_text - idx + 1)
					label.Text = string.sub(full_text, start_pos, #full_text)
				end

			elseif anim_mode == "Type & Erase" then
				if gradient then gradient.Enabled = false end
				label.TextTransparency = 0
				label.TextColor3 = curr_color
				label.Position = st.base_position

				if now - (st.last_te or 0) >= (0.09 / speed) then
					st.last_te = now
					st.te_idx = st.te_idx or 1
					st.te_dir = st.te_dir or 1
					st.te_wait = (st.te_wait or 0) - 1
					if st.te_wait <= 0 then
						st.te_idx = st.te_idx + st.te_dir
						if st.te_idx >= #full_text then
							st.te_idx = #full_text
							st.te_dir = -1
							st.te_wait = math.floor(12 * speed)
						elseif st.te_idx <= 1 then
							st.te_idx = 1
							st.te_dir = 1
							st.te_wait = math.floor(6 * speed)
						end
					end
					label.Text = string.sub(full_text, 1, st.te_idx or 1)
				end

			elseif anim_mode == "Rainbow Cycle" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.TextTransparency = 0
				label.Position = st.base_position
				label.TextColor3 = curr_color

			elseif anim_mode == "Pulse" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.Position = st.base_position
				local alpha = 0.3 + 0.7 * math.abs(math.sin(now * speed * 3))
				label.TextColor3 = Color3.new(curr_color.R * alpha, curr_color.G * alpha, curr_color.B * alpha)
				label.TextTransparency = 0

			elseif anim_mode == "Heartbeat" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.TextTransparency = 0
				local beat_t = (now * speed * 1.5) % 1
				local scale = 0
				if beat_t < 0.15 then
					scale = math.sin(beat_t / 0.15 * math.pi) * 2
				elseif beat_t >= 0.22 and beat_t < 0.37 then
					scale = math.sin((beat_t - 0.22) / 0.15 * math.pi) * 1.5
				end
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset, st.base_position.Y.Scale, st.base_position.Y.Offset - scale)
				local col_boost = math.clamp(scale * 0.2, 0, 0.4)
				label.TextColor3 = Color3.new(
					math.clamp(curr_color.R + col_boost, 0, 1),
					math.clamp(curr_color.G + col_boost, 0, 1),
					math.clamp(curr_color.B + col_boost, 0, 1)
				)

			elseif anim_mode == "Blink" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.Position = st.base_position
				label.TextColor3 = curr_color
				local visible = math.floor(now * speed * 2) % 2 == 0
				label.TextTransparency = visible and 0 or 1

			elseif anim_mode == "Strobe Flash" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.Position = st.base_position
				local strobe = (math.floor(now * speed * 10) % 2 == 0)
				label.TextTransparency = strobe and 0 or 0.8
				label.TextColor3 = strobe and Color3.new(1, 1, 1) or curr_color

			elseif anim_mode == "Neon Flicker" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.Position = st.base_position
				local flicker = math.sin(now * speed * 12) + math.cos(now * speed * 27)
				local is_flicker = (flicker < -1.4) or (math.random(1, 40) == 1)
				label.TextTransparency = is_flicker and 0.85 or 0
				local dim = is_flicker and 0.3 or 1
				label.TextColor3 = Color3.new(curr_color.R * dim, curr_color.G * dim, curr_color.B * dim)

			elseif anim_mode == "Breathing Glow" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.Position = st.base_position
				label.TextColor3 = curr_color
				local breath = (math.sin(now * speed * 1.8) + 1) * 0.5
				label.TextTransparency = 0.05 + 0.35 * (1 - breath)
				label.TextStrokeTransparency = 0.2 + 0.6 * (1 - breath)

			elseif anim_mode == "Wave" or anim_mode == "Gradient Slide" then
				label.Text = full_text
				label.TextTransparency = 0
				label.Position = st.base_position
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = (anim_mode == "Gradient Slide") and ((now * speed * 60) % 360) or 0
					local pos = math.abs(math.sin(now * speed * 2))
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 170, 170)),
						ColorSequenceKeypoint.new(math.clamp(pos, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 170, 170)),
					})
				end

			elseif anim_mode == "Liquid Wave" then
				label.Text = full_text
				label.TextTransparency = 0
				local wave_y = math.sin(now * speed * 2.5) * 1.5
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset, st.base_position.Y.Scale, st.base_position.Y.Offset + wave_y)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = math.sin(now * speed * 1.5) * 45
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, curr_color),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 245, 255)),
						ColorSequenceKeypoint.new(1, curr_color),
					})
				end

			elseif anim_mode == "Scanline" then
				label.Text = full_text
				label.TextTransparency = 0
				label.Position = st.base_position
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 90
					local scan_pos = (now * speed * 0.8) % 1
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 120, 120)),
						ColorSequenceKeypoint.new(math.clamp(scan_pos, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 120)),
					})
				end

			elseif anim_mode == "Glitch Hacker" then
				if gradient then gradient.Enabled = false end
				label.TextTransparency = 0
				label.Position = st.base_position
				label.TextColor3 = curr_color

				if now - (st.last_glitch or 0) >= (0.08 / speed) then
					st.last_glitch = now
					local chars = {}
					for i = 1, #full_text do
						local orig = string.sub(full_text, i, i)
						if orig ~= " " and math.random(1, 4) == 1 then
							table.insert(chars, hacker_chars[math.random(1, #hacker_chars)])
						else
							table.insert(chars, orig)
						end
					end
					label.Text = table.concat(chars)
				end

			elseif anim_mode == "Glitch Shake" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.TextTransparency = 0
				label.TextColor3 = curr_color

				if now - (st.last_shake or 0) >= (0.05 / speed) then
					st.last_shake = now
					local jx = (math.random(1, 4) == 1) and math.random(-2, 2) or 0
					local jy = (math.random(1, 4) == 1) and math.random(-1, 1) or 0
					label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + jx, st.base_position.Y.Scale, st.base_position.Y.Offset + jy)
				end

			elseif anim_mode == "Shimmer" then
				label.Text = full_text
				label.TextTransparency = 0
				label.Position = st.base_position
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 45
					local shift = (now * speed * 0.8) % 1
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, curr_color),
						ColorSequenceKeypoint.new(math.clamp(shift, 0.01, 0.99), Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1, curr_color),
					})
				end

			elseif anim_mode == "Fade" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.Position = st.base_position
				label.TextColor3 = curr_color
				label.TextTransparency = math.abs(math.sin(now * speed * 2)) * 0.85

			elseif anim_mode == "Bounce" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.TextTransparency = 0
				label.TextColor3 = curr_color
				local bounce_y = math.sin(now * speed * 4) * 2
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset, st.base_position.Y.Scale, st.base_position.Y.Offset + bounce_y)

			elseif anim_mode == "Vapor Float" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.TextTransparency = 0
				label.TextColor3 = curr_color
				local fx = math.sin(now * speed * 1.6) * 1.5
				local fy = math.cos(now * speed * 2.2) * 1.5
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + fx, st.base_position.Y.Scale, st.base_position.Y.Offset + fy)

			elseif anim_mode == "CS2 Kinetic Shift" then
				label.Text = full_text
				label.TextTransparency = 0
				local shift_t = (now * speed * 3) % 1
				local kx = 0
				if shift_t < 0.18 then
					kx = math.sin(shift_t / 0.18 * math.pi) * 3
				end
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + kx, st.base_position.Y.Scale, st.base_position.Y.Offset)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 35
					local sweep = (now * speed * 1.5) % 1
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, curr_color),
						ColorSequenceKeypoint.new(math.clamp(sweep, 0.01, 0.99), Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1, curr_color),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Gamesense Skeet Bar" then
				label.Text = full_text
				label.TextTransparency = 0
				label.Position = st.base_position
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 0
					local bar_pos = (now * speed * 1.2) % 1
					local skeet_green = Color3.fromRGB(168, 255, 60)
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 110, 110)),
						ColorSequenceKeypoint.new(math.clamp(bar_pos, 0.01, 0.99), skeet_green),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 110, 110)),
					})
				else
					label.TextColor3 = Color3.fromRGB(168, 255, 60)
				end

			elseif anim_mode == "Neverlose Spark" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.Position = st.base_position
				local spark = math.sin(now * speed * 16) * math.cos(now * speed * 23)
				local is_spark = spark > 0.65 or (math.random(1, 25) == 1)
				label.TextColor3 = is_spark and Color3.fromRGB(0, 240, 255) or curr_color
				label.TextStrokeTransparency = is_spark and 0.1 or 0.5
				label.TextTransparency = 0

			elseif anim_mode == "Primordial Frost Pulse" then
				label.Text = full_text
				label.Position = st.base_position
				local frost_pulse = (math.sin(now * speed * 1.5) + 1) * 0.5
				label.TextTransparency = 0.05 + frost_pulse * 0.2
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 90
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 245, 255)),
						ColorSequenceKeypoint.new(0.5, curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 190, 255)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Fatality Rage Strike" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.TextTransparency = 0
				local strike_cycle = (now * speed * 2.8) % 1
				if strike_cycle < 0.14 then
					local rx = math.random(-2, 2)
					local ry = math.random(-1, 1)
					label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + rx, st.base_position.Y.Scale, st.base_position.Y.Offset + ry)
					label.TextColor3 = Color3.fromRGB(255, 35, 75)
					label.TextStrokeTransparency = 0.1
				else
					label.Position = st.base_position
					label.TextColor3 = curr_color
					label.TextStrokeTransparency = 0.5
				end

			elseif anim_mode == "Monolith Matrix Cascade" then
				if gradient then gradient.Enabled = false end
				label.TextTransparency = 0
				label.Position = st.base_position
				label.TextColor3 = Color3.fromRGB(0, 255, 128)
				if now - (st.last_cascade or 0) >= (0.07 / speed) then
					st.last_cascade = now
					local chars = {}
					for i = 1, #full_text do
						local orig = string.sub(full_text, i, i)
						if orig ~= " " and math.random(1, 3) == 1 then
							table.insert(chars, hacker_chars[math.random(1, #hacker_chars)])
						else
							table.insert(chars, orig)
						end
					end
					label.Text = table.concat(chars)
				end

			elseif anim_mode == "Sub-Tick Jitter" then
				if gradient then gradient.Enabled = false end
				label.Text = full_text
				label.TextTransparency = 0
				label.TextColor3 = curr_color
				local jx = (math.sin(now * speed * 45) > 0.3) and 1 or -1
				local jy = (math.cos(now * speed * 35) > 0.3) and 1 or 0
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + jx, st.base_position.Y.Scale, st.base_position.Y.Offset + jy)

			elseif anim_mode == "Desync Ghost Mirror" then
				label.Text = full_text
				label.TextTransparency = 0
				local gx = math.sin(now * speed * 2) * 3
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + gx, st.base_position.Y.Scale, st.base_position.Y.Offset)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 0
					local shift = (math.sin(now * speed * 2) + 1) * 0.5
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 130, 140)),
						ColorSequenceKeypoint.new(math.clamp(shift, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 240, 255)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Chroma Drift" then
				label.Text = full_text
				label.TextTransparency = 0
				label.Position = st.base_position
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = (now * speed * 90) % 360
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 45, 85)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 255, 120)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 150, 255)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Spectrum Aurora Wave" then
				label.Text = full_text
				label.TextTransparency = 0
				local wy = math.sin(now * speed * 2.2) * 1.2
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + wy, st.base_position.Y.Scale, st.base_position.Y.Offset + wy)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = math.sin(now * speed * 1.2) * 60
					local p = (math.sin(now * speed * 1.5) + 1) * 0.5
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 180)),
						ColorSequenceKeypoint.new(math.clamp(p, 0.01, 0.99), Color3.fromRGB(150, 80, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Tearful Echo" then
				label.Text = full_text
				local breathe = (math.sin(now * speed * 1.8) + 1) * 0.5
				local tear_drop = math.sin(now * speed * 2.5) * 0.8
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset, st.base_position.Y.Scale, st.base_position.Y.Offset + tear_drop)
				label.TextTransparency = 0.05 + 0.22 * (1 - breathe)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 90 + math.sin(now * speed * 1.2) * 15
					local shift = (math.sin(now * speed * 1.5) + 1) * 0.5
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 75, 125)),
						ColorSequenceKeypoint.new(math.clamp(shift, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(205, 230, 255)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Departure Farewell" then
				label.Text = full_text
				local sway = math.sin(now * speed * 1.2) * 1.5
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + sway, st.base_position.Y.Scale, st.base_position.Y.Offset)
				local fade = (math.sin(now * speed * 1.6) + 1) * 0.5
				label.TextTransparency = 0.05 + 0.20 * (1 - fade)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 0
					local shift = (math.sin(now * speed * 1.3) + 1) * 0.5
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 75, 88)),
						ColorSequenceKeypoint.new(math.clamp(shift, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 195, 215)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Heartache Whisper" then
				label.Text = full_text
				local cycle = ((now * speed * 0.8) + (st.offset or 0)) % 1
				local alpha = 0.5 * (1 - math.cos(cycle * math.pi * 2))
				label.TextTransparency = 0.08 + 0.40 * (1 - alpha)
				local float_y = math.sin(cycle * math.pi * 2) * 1.0
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset, st.base_position.Y.Scale, st.base_position.Y.Offset + float_y)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 45
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 55, 95)),
						ColorSequenceKeypoint.new(0.5, curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 190, 235)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Shivering Breath" then
				label.Text = full_text
				local shiv_x = (math.sin(now * speed * 32) > 0.4) and 0.8 or ((math.sin(now * speed * 28) < -0.4) and -0.8 or 0)
				local rise_y = -math.abs(math.sin(now * speed * 2.0)) * 1.2
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + shiv_x, st.base_position.Y.Scale, st.base_position.Y.Offset + rise_y)
				local breath_fade = (math.sin(now * speed * 2.2) + 1) * 0.5
				label.TextTransparency = 0.05 + 0.25 * (1 - breath_fade)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 90
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, curr_color),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(235, 245, 255)),
						ColorSequenceKeypoint.new(1, curr_color),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Fading Footsteps" then
				label.Text = full_text
				local step_t = ((now * speed * 0.6) + (st.offset or 0)) % 1
				local drift_x = math.sin(step_t * math.pi * 2) * 1.5
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + drift_x, st.base_position.Y.Scale, st.base_position.Y.Offset)
				label.TextTransparency = 0.06
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 0
					gradient.Offset = Vector2.new(-step_t, 0)
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 65, 95)),
						ColorSequenceKeypoint.new(0.4, curr_color),
						ColorSequenceKeypoint.new(0.8, Color3.fromRGB(150, 180, 220)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 65, 95)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Lonely Streetlamp" then
				label.Text = full_text
				label.Position = st.base_position
				local glow_pulse = (math.sin(now * speed * 1.5) + 1) * 0.5
				label.TextTransparency = 0.04 + 0.18 * (1 - glow_pulse)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 90
					local center_pos = math.clamp(0.5 + math.sin(now * speed * 1.2) * 0.15, 0.1, 0.9)
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 95, 65)),
						ColorSequenceKeypoint.new(center_pos, curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 55, 40)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Signal Light Pulse" then
				label.Text = full_text
				label.Position = st.base_position
				local flash_cycle = ((now * speed * 1.2) + (st.offset or 0)) % 1
				local is_signal = flash_cycle < 0.28
				local intensity = is_signal and math.sin(flash_cycle / 0.28 * math.pi) or 0
				local sig_color = curr_color:Lerp(Color3.fromRGB(255, 110, 125), intensity)
				label.TextTransparency = 0.05 + 0.22 * (1 - intensity)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 0
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 35, 45)),
						ColorSequenceKeypoint.new(0.5, sig_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 35, 45)),
					})
				else
					label.TextColor3 = sig_color
				end

			elseif anim_mode == "Snow Drift Rails" then
				label.Text = full_text
				local drift_t = ((now * speed * 0.7) + (st.offset or 0)) % 1
				local dx = math.sin(drift_t * math.pi * 2) * 1.8
				local dy = math.cos(drift_t * math.pi * 2) * 0.8
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + dx, st.base_position.Y.Scale, st.base_position.Y.Offset + dy)
				local snow_alpha = (math.sin(drift_t * math.pi * 2) + 1) * 0.5
				label.TextTransparency = 0.06 + 0.20 * (1 - snow_alpha)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 25
					gradient.Offset = Vector2.new(-drift_t, 0)
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 80, 92)),
						ColorSequenceKeypoint.new(0.5, curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 235, 245)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Only Light Twilight" then
				label.Text = full_text
				local breathe = (math.sin(now * speed * 1.5) + 1) * 0.5
				local float_y = math.sin(now * speed * 2.0) * 1.0
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset, st.base_position.Y.Scale, st.base_position.Y.Offset + float_y)
				label.TextTransparency = 0.04 + 0.16 * (1 - breathe)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 35 + math.sin(now * speed * 1.2) * 20
					local shift = (math.sin(now * speed * 1.4) + 1) * 0.5
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 75, 235)), -- Dusk Violet
						ColorSequenceKeypoint.new(math.clamp(shift, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 110)), -- Golden Sunbeam
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Camcorder Memory Echo" then
				label.Text = full_text
				local scan = (math.sin(now * speed * 4.0) > 0.92) and 0.5 or 0
				local jit_x = (math.random(1, 20) == 1) and (math.random(-1, 1) * 0.6) or 0
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + jit_x, st.base_position.Y.Scale, st.base_position.Y.Offset)
				local tape_breathe = (math.sin(now * speed * 1.8) + 1) * 0.5
				label.TextTransparency = 0.05 + 0.18 * (1 - tape_breathe) + scan * 0.2
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 90
					local p = ((now * speed * 0.8) + (st.offset or 0)) % 1
					gradient.Offset = Vector2.new(0, -p)
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(65, 35, 95)),
						ColorSequenceKeypoint.new(0.5, curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 175, 205)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Golden Sunset Flare" then
				label.Text = full_text
				label.Position = st.base_position
				local flare_t = ((now * speed * 0.9) + (st.offset or 0)) % 1
				local flare_active = math.sin(flare_t * math.pi)
				label.TextTransparency = 0.04 + 0.12 * (1 - flare_active)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 45
					gradient.Offset = Vector2.new(-flare_t * 1.5, 0)
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 50, 190)),
						ColorSequenceKeypoint.new(0.45, curr_color),
						ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 245, 180)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 50, 190)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Twilight Whisper Glow" then
				label.Text = full_text
				local float_y = math.sin(now * speed * 1.6) * 0.8
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset, st.base_position.Y.Scale, st.base_position.Y.Offset + float_y)
				local glow_t = (math.sin(now * speed * 2.2) + 1) * 0.5
				label.TextTransparency = 0.05 + 0.22 * (1 - glow_t)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 0
					local shift = (math.sin(now * speed * 1.3) + 1) * 0.5
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 45, 140)),
						ColorSequenceKeypoint.new(math.clamp(shift, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 160, 210)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Nostalgic Sunbeam Drift" then
				label.Text = full_text
				local drift = ((now * speed * 0.5) + (st.offset or 0)) % 1
				local dx = math.sin(drift * math.pi * 2) * 1.4
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + dx, st.base_position.Y.Scale, st.base_position.Y.Offset)
				label.TextTransparency = 0.06
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 30
					gradient.Offset = Vector2.new(-drift, 0)
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 40, 115)),
						ColorSequenceKeypoint.new(0.5, curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 120)),
					})
				else
					label.TextColor3 = curr_color
				end

			-- === VIBE 1: Dying for someone who moved on. ===
			elseif anim_mode == "Cigarette Smoke Dissolve" then
				label.Text = full_text
				local t = (now * speed * 1.4) + (st.offset or 0)
				local smoke_x = math.sin(t * 1.8) * 1.8 + math.sin(t * 3.6) * 0.6
				local smoke_y = -math.abs(math.sin(t * 1.2)) * 1.6
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + smoke_x, st.base_position.Y.Scale, st.base_position.Y.Offset + smoke_y)
				local dissolve = (math.sin(t * 1.6) + 1) * 0.5
				label.TextTransparency = 0.04 + 0.32 * (1 - dissolve)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 90 + math.sin(t * 1.2) * 25
					local shift = (math.sin(t * 1.5) + 1) * 0.5
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 30, 50)),
						ColorSequenceKeypoint.new(math.clamp(shift, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 70)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Burning Ember Pulse" then
				label.Text = full_text
				label.Position = st.base_position
				local ember_t = ((now * speed * 0.8) + (st.offset or 0)) % 1
				local is_inhale = ember_t < 0.35
				local ember_flare = is_inhale and math.sin(ember_t / 0.35 * math.pi) or (0.2 * math.cos((ember_t - 0.35) / 0.65 * math.pi * 0.5))
				label.TextTransparency = 0.03 + 0.25 * (1 - ember_flare)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 0
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 25, 15)),
						ColorSequenceKeypoint.new(0.5, curr_color:Lerp(Color3.fromRGB(255, 160, 60), ember_flare)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 25, 15)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Heartache Inhale Breath" then
				label.Text = full_text
				local inhale = (math.sin(now * speed * 1.2) + 1) * 0.5
				local depth_y = -inhale * 1.4
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset, st.base_position.Y.Scale, st.base_position.Y.Offset + depth_y)
				label.TextTransparency = 0.05 + 0.24 * (1 - inhale)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 45
					local shift = (math.sin(now * speed * 1.1) + 1) * 0.5
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 20, 42)),
						ColorSequenceKeypoint.new(math.clamp(shift, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(195, 140, 185)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Fading Ash Descent" then
				label.Text = full_text
				local ash_cycle = ((now * speed * 0.55) + (st.offset or 0)) % 1
				local drift_x = math.sin(ash_cycle * math.pi * 4) * 1.2
				local fall_y = ash_cycle * 2.2
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + drift_x, st.base_position.Y.Scale, st.base_position.Y.Offset + fall_y)
				local ash_fade = math.sin(ash_cycle * math.pi)
				label.TextTransparency = 0.05 + 0.35 * (1 - ash_fade)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 90
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 65, 80)),
						ColorSequenceKeypoint.new(0.5, curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 150, 165)),
					})
				else
					label.TextColor3 = curr_color
				end

			-- === VIBE 2: I wish we could watch them again... ===
			elseif anim_mode == "Fireworks Burst Spark" then
				label.Text = full_text
				local burst_t = ((now * speed * 1.1) + (st.offset or 0)) % 1
				local is_blast = burst_t < 0.25
				local blast_p = is_blast and math.sin(burst_t / 0.25 * math.pi) or 0
				local spark_shake = is_blast and (math.random(-1, 1) * 0.8) or 0
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + spark_shake, st.base_position.Y.Scale, st.base_position.Y.Offset - blast_p * 1.5)
				label.TextTransparency = 0.03 + 0.18 * (1 - blast_p)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = math.sin(now * speed * 2.5) * 45
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 15, 65)),
						ColorSequenceKeypoint.new(0.48, curr_color),
						ColorSequenceKeypoint.new(0.52, Color3.fromRGB(255, 245, 160)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 130)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Festive Sparkler Trail" then
				label.Text = full_text
				label.Position = st.base_position
				local spark_t = ((now * speed * 1.8) + (st.offset or 0)) % 1
				local jx = (math.random(1, 8) == 1) and (math.random(-1, 1) * 0.7) or 0
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + jx, st.base_position.Y.Scale, st.base_position.Y.Offset)
				label.TextTransparency = 0.04
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 30
					gradient.Offset = Vector2.new(-spark_t, 0)
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 20, 50)),
						ColorSequenceKeypoint.new(0.4, curr_color),
						ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 235, 120)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 20, 50)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Wool Scarf Warmth" then
				label.Text = full_text
				local warmth = (math.sin(now * speed * 1.8) + 1) * 0.5
				label.Position = st.base_position
				label.TextTransparency = 0.04 + 0.18 * (1 - warmth)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 0
					local shift = (math.sin(now * speed * 1.4) + 1) * 0.5
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 25, 45)),
						ColorSequenceKeypoint.new(math.clamp(shift, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 165)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Starry Ember Fallout" then
				label.Text = full_text
				local fall_t = ((now * speed * 0.7) + (st.offset or 0)) % 1
				local fx = math.sin(fall_t * math.pi * 3) * 1.5
				local fy = fall_t * 1.8
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + fx, st.base_position.Y.Scale, st.base_position.Y.Offset + fy)
				local ember_glow = math.sin(fall_t * math.pi)
				label.TextTransparency = 0.05 + 0.28 * (1 - ember_glow)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 45
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 25, 60)),
						ColorSequenceKeypoint.new(0.5, curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 140)),
					})
				else
					label.TextColor3 = curr_color
				end

			-- === VIBE 3: maybe this sunset was all we needed... ===
			elseif anim_mode == "Golden Sunset Serenity" then
				label.Text = full_text
				local wind_t = (now * speed * 1.2) + (st.offset or 0)
				local sway_x = math.sin(wind_t) * 1.8 + math.sin(wind_t * 2) * 0.6
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + sway_x, st.base_position.Y.Scale, st.base_position.Y.Offset)
				local serene_glow = (math.sin(wind_t * 1.4) + 1) * 0.5
				label.TextTransparency = 0.03 + 0.15 * (1 - serene_glow)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 25 + math.sin(wind_t * 0.8) * 15
					local shift = (math.sin(wind_t * 1.3) + 1) * 0.5
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(195, 75, 10)),
						ColorSequenceKeypoint.new(math.clamp(shift, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 245, 160)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Sunbeam Meadow Shimmer" then
				label.Text = full_text
				label.Position = st.base_position
				local beam_cycle = ((now * speed * 0.85) + (st.offset or 0)) % 1
				local beam_intensity = math.sin(beam_cycle * math.pi)
				label.TextTransparency = 0.04 + 0.14 * (1 - beam_intensity)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 45
					gradient.Offset = Vector2.new(-beam_cycle * 1.4, 0)
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 90, 20)),
						ColorSequenceKeypoint.new(0.45, curr_color),
						ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 220)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 90, 20)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Peach Sorbet Sweetness" then
				label.Text = full_text
				local float_y = math.sin(now * speed * 2.0) * 0.9
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset, st.base_position.Y.Scale, st.base_position.Y.Offset + float_y)
				local sweet_glow = (math.sin(now * speed * 1.6) + 1) * 0.5
				label.TextTransparency = 0.04 + 0.18 * (1 - sweet_glow)
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 0
					local shift = (math.sin(now * speed * 1.2) + 1) * 0.5
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 110, 80)),
						ColorSequenceKeypoint.new(math.clamp(shift, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 160)),
					})
				else
					label.TextColor3 = curr_color
				end

			elseif anim_mode == "Wind Blowing Wheat" then
				label.Text = full_text
				local wheat_t = ((now * speed * 0.6) + (st.offset or 0)) % 1
				local wave_x = math.sin(wheat_t * math.pi * 2) * 2.0
				local wave_y = math.cos(wheat_t * math.pi * 2) * 0.6
				label.Position = UDim2.new(st.base_position.X.Scale, st.base_position.X.Offset + wave_x, st.base_position.Y.Scale, st.base_position.Y.Offset + wave_y)
				label.TextTransparency = 0.05
				if gradient then
					gradient.Enabled = true
					gradient.Rotation = 15
					gradient.Offset = Vector2.new(-wheat_t, 0)
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 85, 25)),
						ColorSequenceKeypoint.new(0.5, curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 235, 140)),
					})
				else
					label.TextColor3 = curr_color
				end
			end
		end

		local function process_accent_line(line_frame, line_gradient, glow, is_parent_visible, anim_mode, color_mode, custom_color, speed, phase_offset, st)
			if not line_frame then return end

			-- FPS Guard: skip if parent container is hidden
			if not is_parent_visible then
				return
			end

			local is_active = (flags["outline_anim_enabled"] ~= false) and (anim_mode and anim_mode ~= "None")
			if not is_active then
				if st.was_active then
					if line_gradient then line_gradient.Enabled = false end
					line_frame.BackgroundColor3 = themes.preset.accent
					line_frame.BackgroundTransparency = 0
					if glow then
						glow.ImageColor3 = themes.preset.accent
						glow.ImageTransparency = 0.9
					end
					st.was_active = false
				end
				return
			end

			st.was_active = true
			local curr_color = library.get_color_mode_color(color_mode, custom_color, speed, phase_offset or 0)
			local now = tick()

			if anim_mode == "Sync With Accent" then
				if line_gradient then line_gradient.Enabled = false end
				line_frame.BackgroundColor3 = curr_color
				line_frame.BackgroundTransparency = 0
				if glow then
					glow.ImageColor3 = curr_color
					glow.ImageTransparency = 0.88
				end

			elseif anim_mode == "RGB Spectrum Flow" then
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 0
					local shift = ((now * speed * 0.4) + phase_offset) % 1
					line_gradient.Offset = Vector2.new(-shift, 0)
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0.85, 1)),
						ColorSequenceKeypoint.new(0.2, Color3.fromHSV(0.2, 0.85, 1)),
						ColorSequenceKeypoint.new(0.4, Color3.fromHSV(0.4, 0.85, 1)),
						ColorSequenceKeypoint.new(0.6, Color3.fromHSV(0.6, 0.85, 1)),
						ColorSequenceKeypoint.new(0.8, Color3.fromHSV(0.8, 0.85, 1)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 0.85, 1)),
					})
				else
					line_frame.BackgroundColor3 = curr_color
				end
				if glow then
					local g_hue = ((now * speed * 0.4) + phase_offset) % 1
					glow.ImageColor3 = Color3.fromHSV(g_hue, 0.85, 1)
					glow.ImageTransparency = 0.85
				end

			elseif anim_mode == "Gradient Wave" then
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 0
					local wave_t = ((now * speed * 0.7) + phase_offset) % 1
					local c2 = library.get_color_mode_color(color_mode, custom_color, speed, phase_offset + 0.5)
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, curr_color),
						ColorSequenceKeypoint.new(math.clamp(wave_t, 0.01, 0.99), c2),
						ColorSequenceKeypoint.new(1, curr_color),
					})
				else
					line_frame.BackgroundColor3 = curr_color
				end
				if glow then
					glow.ImageColor3 = curr_color
					glow.ImageTransparency = 0.85
				end

			elseif anim_mode == "Breathing Glow" then
				if line_gradient then line_gradient.Enabled = false end
				local pulse = (math.sin(now * speed * 2.8 + phase_offset * 6.28) + 1) * 0.5
				line_frame.BackgroundColor3 = curr_color
				line_frame.BackgroundTransparency = 0.15 * (1 - pulse)
				if glow then
					glow.ImageColor3 = curr_color
					glow.ImageTransparency = 0.70 + 0.25 * (1 - pulse)
				end

			elseif anim_mode == "Strobe Pulse" then
				if line_gradient then line_gradient.Enabled = false end
				local st_cycle = ((now * speed * 3.5) + phase_offset) % 1
				local is_bright = st_cycle < 0.22
				local c = is_bright and Color3.new(1, 1, 1) or curr_color
				line_frame.BackgroundColor3 = c
				line_frame.BackgroundTransparency = 0
				if glow then
					glow.ImageColor3 = c
					glow.ImageTransparency = is_bright and 0.62 or 0.92
				end

			elseif anim_mode == "Neon Scanline" then
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 0
					local scan_pos = (math.sin(now * speed * 2.2 + phase_offset * 3.14) + 1) * 0.5
					local p1 = math.clamp(scan_pos - 0.12, 0, 0.98)
					local p2 = math.clamp(scan_pos, p1 + 0.01, 0.99)
					local p3 = math.clamp(scan_pos + 0.12, p2 + 0.01, 1)
					local dark_c = Color3.new(curr_color.R * 0.25, curr_color.G * 0.25, curr_color.B * 0.25)
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, dark_c),
						ColorSequenceKeypoint.new(p1, dark_c),
						ColorSequenceKeypoint.new(p2, Color3.new(1, 1, 1)),
						ColorSequenceKeypoint.new(p3, dark_c),
						ColorSequenceKeypoint.new(1, dark_c),
					})
				else
					line_frame.BackgroundColor3 = curr_color
				end
				if glow then
					glow.ImageColor3 = curr_color
					glow.ImageTransparency = 0.82
				end

			elseif anim_mode == "CS2 Kinetic Sweep" then
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 15
					local sweep_t = ((now * speed * 1.8) + phase_offset) % 1
					local sp1 = math.clamp(sweep_t, 0.01, 0.98)
					local sp2 = math.clamp(sweep_t + 0.08, sp1 + 0.01, 0.99)
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, curr_color),
						ColorSequenceKeypoint.new(sp1, curr_color),
						ColorSequenceKeypoint.new(sp2, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1, curr_color),
					})
				else
					line_frame.BackgroundColor3 = curr_color
				end
				if glow then
					glow.ImageColor3 = curr_color
					glow.ImageTransparency = 0.85
				end

			elseif anim_mode == "Neverlose Electric Spark" then
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 0
					local spark_val = math.sin(now * speed * 7.5 + phase_offset * 10)
					local is_spark = spark_val > 0.65
					local spark_c = is_spark and Color3.fromRGB(235, 250, 255) or curr_color
					local spark_pos = math.clamp((math.cos(now * speed * 4.5) + 1) * 0.5, 0.01, 0.99)
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, curr_color),
						ColorSequenceKeypoint.new(spark_pos, spark_c),
						ColorSequenceKeypoint.new(1, curr_color),
					})
					if glow then
						glow.ImageColor3 = spark_c
						glow.ImageTransparency = is_spark and 0.58 or 0.88
					end
				else
					line_frame.BackgroundColor3 = curr_color
				end

			elseif anim_mode == "Aurora Borealis Wave" then
				if line_gradient then
					line_gradient.Enabled = true
					local a_shift = ((now * speed * 0.5) + phase_offset) % 1
					line_gradient.Offset = Vector2.new(-a_shift, 0)
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 180)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 80, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200)),
					})
				else
					line_frame.BackgroundColor3 = curr_color
				end
				if glow then
					glow.ImageColor3 = Color3.fromRGB(150, 80, 255)
					glow.ImageTransparency = 0.82
				end

			elseif anim_mode == "Cyberpunk Dual-Shift" then
				local dual_t = (math.sin(now * speed * 2.8 + phase_offset * 3.14) + 1) * 0.5
				local c_cyan = Color3.fromRGB(0, 240, 255)
				local c_pink = Color3.fromRGB(255, 0, 128)
				local cp1 = math.clamp(dual_t, 0.01, 0.99)
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 0
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, c_cyan),
						ColorSequenceKeypoint.new(cp1, c_pink),
						ColorSequenceKeypoint.new(1, c_cyan),
					})
				else
					line_frame.BackgroundColor3 = (dual_t > 0.5) and c_pink or c_cyan
				end
				if glow then
					glow.ImageColor3 = (dual_t > 0.5) and c_pink or c_cyan
					glow.ImageTransparency = 0.80
				end

			elseif anim_mode == "Heartbeat Surge" then
				if line_gradient then line_gradient.Enabled = false end
				local hb_t = ((now * speed * 1.4) + phase_offset) % 1
				local surge = 0
				if hb_t < 0.15 then
					surge = math.sin(hb_t / 0.15 * math.pi)
				elseif hb_t > 0.22 and hb_t < 0.37 then
					surge = math.sin((hb_t - 0.22) / 0.15 * math.pi) * 0.75
				end
				local hb_color = Color3.new(
					curr_color.R + (1 - curr_color.R) * surge * 0.8,
					curr_color.G + (1 - curr_color.G) * surge * 0.8,
					curr_color.B + (1 - curr_color.B) * surge * 0.8
				)
				line_frame.BackgroundColor3 = hb_color
				line_frame.BackgroundTransparency = 0
				if glow then
					glow.ImageColor3 = hb_color
					glow.ImageTransparency = math.clamp(0.90 - surge * 0.35, 0.45, 0.95)
				end

			elseif anim_mode == "Sub-Tick Glitch Spark" then
				if line_gradient then line_gradient.Enabled = false end
				if now - (st.last_glitch or 0) >= (0.07 / speed) then
					st.last_glitch = now
					st.is_glitched = (math.random(1, 5) == 1)
					st.glitch_c = (math.random(1, 2) == 1) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 45, 85)
				end
				local g_color = st.is_glitched and st.glitch_c or curr_color
				line_frame.BackgroundColor3 = g_color
				line_frame.BackgroundTransparency = 0
				if glow then
					glow.ImageColor3 = g_color
					glow.ImageTransparency = st.is_glitched and 0.65 or 0.89
				end

			elseif anim_mode == "Tearful Echo Wave" then
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 0
					local wave = ((now * speed * 0.5) + phase_offset) % 1
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 65, 110)),
						ColorSequenceKeypoint.new(math.clamp(wave, 0.01, 0.99), curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 220, 255)),
					})
				else
					line_frame.BackgroundColor3 = curr_color
				end
				if glow then
					glow.ImageColor3 = curr_color
					glow.ImageTransparency = 0.84
				end

			elseif anim_mode == "Departure Fog Drift" then
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 0
					local drift = ((now * speed * 0.4) + phase_offset) % 1
					line_gradient.Offset = Vector2.new(-drift, 0)
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 65, 75)),
						ColorSequenceKeypoint.new(0.5, curr_color),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 190, 205)),
					})
				else
					line_frame.BackgroundColor3 = curr_color
				end
				if glow then
					glow.ImageColor3 = curr_color
					glow.ImageTransparency = 0.86
				end

			elseif anim_mode == "Sunset Amber Horizon Wave" then
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 0
					local wave = ((now * speed * 0.45) + phase_offset) % 1
					line_gradient.Offset = Vector2.new(-wave, 0)
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(135, 55, 195)), -- Dusk Violet
						ColorSequenceKeypoint.new(0.5, curr_color), -- Sunset Amber
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 225, 120)), -- Golden Sunbeam
					})
				else
					line_frame.BackgroundColor3 = curr_color
				end
				if glow then
					local g_pulse = (math.sin(now * speed * 1.8) + 1) * 0.5
					glow.ImageColor3 = curr_color
					glow.ImageTransparency = 0.82 - g_pulse * 0.12
				end

			elseif anim_mode == "Camcorder Memory Scan" then
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 90
					local scan_p = ((now * speed * 0.8) + phase_offset) % 1
					line_gradient.Offset = Vector2.new(0, -scan_p)
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 25, 80)),
						ColorSequenceKeypoint.new(0.48, curr_color),
						ColorSequenceKeypoint.new(0.52, Color3.fromRGB(255, 240, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 25, 80)),
					})
				else
					line_frame.BackgroundColor3 = curr_color
				end
				if glow then
					glow.ImageColor3 = curr_color
					glow.ImageTransparency = 0.85
				end

			elseif anim_mode == "Cigarette Ash Dissolve" then
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 0
					local ash_drift = ((now * speed * 0.35) + phase_offset) % 1
					line_gradient.Offset = Vector2.new(-ash_drift, 0)
					local ember_fade = (math.sin(now * speed * 2.2 + phase_offset * 3.14) + 1) * 0.5
					local hot_ember = Color3.fromRGB(255, math.floor(75 + ember_fade * 45), 25)
					local cool_ash = Color3.fromRGB(65, 60, 68)
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, cool_ash),
						ColorSequenceKeypoint.new(0.3, cool_ash),
						ColorSequenceKeypoint.new(0.5, hot_ember),
						ColorSequenceKeypoint.new(0.7, curr_color),
						ColorSequenceKeypoint.new(1, cool_ash),
					})
				else
					line_frame.BackgroundColor3 = curr_color
				end
				if glow then
					local inhale = (math.sin(now * speed * 2.2) + 1) * 0.5
					glow.ImageColor3 = Color3.fromRGB(255, 90, 35)
					glow.ImageTransparency = 0.82 - (inhale * 0.14)
				end

			elseif anim_mode == "Festival Fireworks Ring" then
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 0
					local burst_phase = ((now * speed * 0.85) + phase_offset) % 1
					line_gradient.Offset = Vector2.new(-burst_phase, 0)
					local spark_flash = (math.sin(now * speed * 7.5 + phase_offset * 4) + 1) * 0.5
					local gold_spark = Color3.fromRGB(255, math.floor(210 + spark_flash * 45), math.floor(100 + spark_flash * 155))
					local night_sky = Color3.fromRGB(28, 18, 42)
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, night_sky),
						ColorSequenceKeypoint.new(0.2, Color3.fromRGB(240, 50, 95)),
						ColorSequenceKeypoint.new(0.5, gold_spark),
						ColorSequenceKeypoint.new(0.8, curr_color),
						ColorSequenceKeypoint.new(1, night_sky),
					})
				else
					line_frame.BackgroundColor3 = curr_color
				end
				if glow then
					local burst_glow = (math.sin(now * speed * 5.0) + 1) * 0.5
					glow.ImageColor3 = Color3.fromRGB(255, 195, 75)
					glow.ImageTransparency = 0.78 - (burst_glow * 0.18)
				end

			elseif anim_mode == "Radiant Sunbeam Horizon" then
				if line_gradient then
					line_gradient.Enabled = true
					line_gradient.Rotation = 0
					local sun_sweep = ((now * speed * 0.4) + phase_offset) % 1
					line_gradient.Offset = Vector2.new(-sun_sweep, 0)
					local sun_pulse = (math.sin(now * speed * 1.6) + 1) * 0.5
					local bright_sun = Color3.fromRGB(255, 240, 160)
					local meadow_dusk = Color3.fromRGB(150, 75, 20)
					line_gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, meadow_dusk),
						ColorSequenceKeypoint.new(0.35, curr_color),
						ColorSequenceKeypoint.new(0.5, bright_sun),
						ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 170, 80)),
						ColorSequenceKeypoint.new(1, meadow_dusk),
					})
				else
					line_frame.BackgroundColor3 = curr_color
				end
				if glow then
					local sun_breathe = (math.sin(now * speed * 1.6) + 1) * 0.5
					glow.ImageColor3 = Color3.fromRGB(255, 175, 45)
					glow.ImageTransparency = 0.80 - (sun_breathe * 0.15)
				end
			end
		end

		while true do
			task.wait(0.03)

			-- 1. UI Title Animation (Auto-throttled to 0 CPU if menu is closed)
			local ui_a_mode = flags["ui_anim_mode"] or "Gradient Slide"
			if type(ui_a_mode) == "table" then ui_a_mode = ui_a_mode[1] end
			local ui_c_mode = flags["ui_color_mode"] or "Theme Accent"
			if type(ui_c_mode) == "table" then ui_c_mode = ui_c_mode[1] end
			local ui_col = flags["ui_anim_color"] or Color3.fromRGB(75, 90, 255)
			if typeof(ui_col) == "table" and ui_col.Color then ui_col = ui_col.Color end
			local ui_spd = flags["ui_anim_speed"] or 1

			process_target(window.title_label, window.title_gradient, full_title, ui_a_mode, ui_c_mode, ui_col, ui_spd, 1, title_state)

			-- 2. Watermark Animation (Auto-throttled to 0 CPU if watermark is disabled)
			local wm_a_mode = flags["watermark_anim_mode"] or "Reverse Typing"
			if type(wm_a_mode) == "table" then wm_a_mode = wm_a_mode[1] end
			local wm_c_mode = flags["watermark_color_mode"] or "Blood Crimson"
			if type(wm_c_mode) == "table" then wm_c_mode = wm_c_mode[1] end
			local wm_col = flags["watermark_anim_color"] or Color3.fromRGB(75, 90, 255)
			if typeof(wm_col) == "table" and wm_col.Color then wm_col = wm_col.Color end
			local wm_spd = flags["watermark_anim_speed"] or 1

			process_target(window.watermark_label, window.watermark_gradient, full_wm, wm_a_mode, wm_c_mode, wm_col, wm_spd, 2, wm_state)

			-- 3. Keybinds Title Animation
			local kb_a_mode = flags["keybinds_anim_mode"] or "Reverse Typing"
			if type(kb_a_mode) == "table" then kb_a_mode = kb_a_mode[1] end
			local kb_c_mode = flags["keybinds_color_mode"] or "Theme Accent"
			if type(kb_c_mode) == "table" then kb_c_mode = kb_c_mode[1] end
			local kb_col = flags["keybinds_anim_color"] or Color3.fromRGB(75, 90, 255)
			if typeof(kb_col) == "table" and kb_col.Color then kb_col = kb_col.Color end
			local kb_spd = flags["keybinds_anim_speed"] or 1

			process_target(window.keybinds_label, window.keybinds_gradient, full_kb, kb_a_mode, kb_c_mode, kb_col, kb_spd, 3, kb_state)

			-- 4. Playerlist Title Animation
			local pl_a_mode = flags["playerlist_anim_mode"] or "Gradient Slide"
			if type(pl_a_mode) == "table" then pl_a_mode = pl_a_mode[1] end
			local pl_c_mode = flags["playerlist_color_mode"] or "Theme Accent"
			if type(pl_c_mode) == "table" then pl_c_mode = pl_c_mode[1] end
			local pl_col = flags["playerlist_anim_color"] or Color3.fromRGB(75, 90, 255)
			if typeof(pl_col) == "table" and pl_col.Color then pl_col = pl_col.Color end
			local pl_spd = flags["playerlist_anim_speed"] or 1

			process_target(window.playerlist_label, window.playerlist_gradient, full_pl, pl_a_mode, pl_c_mode, pl_col, pl_spd, 4, pl_state)

			-- 5. Outline / Accent Lines Animation for all 4 panels
			local out_mode = flags["outline_anim_mode"] or "RGB Spectrum Flow"
			if type(out_mode) == "table" then out_mode = out_mode[1] end
			local out_color_mode = flags["outline_color_mode"] or "Theme Accent"
			if type(out_color_mode) == "table" then out_color_mode = out_color_mode[1] end
			local out_col = flags["outline_anim_color"] or Color3.fromRGB(255, 45, 85)
			if typeof(out_col) == "table" and out_col.Color then out_col = out_col.Color end
			local out_spd = flags["outline_anim_speed"] or 1

			local w_vis = (window.window_frame and window.window_frame.Visible)
			local wm_vis = (window.watermark_frame and window.watermark_frame.Visible and flags["watermark_enabled"] ~= false)
			local kb_vis = (window.keybinds_frame and window.keybinds_frame.Visible and flags["keybinds_enabled"] ~= false)
			local pl_vis = (window.playerlist_frame and window.playerlist_frame.Visible and flags["player_list"] ~= false)

			-- Cascaded phase offsets (0, 0.25, 0.5, 0.75) for fluid spectrum/wave propagation across all 4 frames
			process_accent_line(window.title_accent_line, window.title_line_gradient, window.title_glow, w_vis, out_mode, out_color_mode, out_col, out_spd, 0, out_state_title)
			process_accent_line(window.watermark_accent_line, window.watermark_line_gradient, window.watermark_glow, wm_vis, out_mode, out_color_mode, out_col, out_spd, 0.25, out_state_wm)
			process_accent_line(window.keybinds_accent_line, window.keybinds_line_gradient, window.keybinds_glow, kb_vis, out_mode, out_color_mode, out_col, out_spd, 0.5, out_state_kb)
			process_accent_line(window.playerlist_accent_line, window.playerlist_line_gradient, window.playerlist_glow, pl_vis, out_mode, out_color_mode, out_col, out_spd, 0.75, out_state_pl)
		end
	end)

	-- Cập nhật danh sách config khi tải menu
	library:config_list_update()

end

-- ========================================================
-- 8. Splash Screen Intro (E:\fz.gif - 112 Frames Preloaded)
-- ========================================================
local function play_splash_intro(on_complete)
	local CoreGui = game:GetService("CoreGui")
	local ContentProvider = game:GetService("ContentProvider")
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local getasset = getcustomasset or getsynasset

	-- Dọn dẹp triệt để bất kỳ Splash Screen cũ nào còn sót
	pcall(function()
		local old = CoreGui:FindFirstChild("NVL_FZ_Splash", true)
		if old then old:Destroy() end
		if getgenv().NVL_SplashGui then
			getgenv().NVL_SplashGui:Destroy()
			getgenv().NVL_SplashGui = nil
		end
	end)

	-- Xác định parent an toàn
	local parent_gui
	if gethui then
		parent_gui = gethui()
	elseif syn and syn.protect_gui then
		local g = Instance.new("ScreenGui")
		syn.protect_gui(g)
		g.Parent = CoreGui
		parent_gui = g
	elseif CoreGui:FindFirstChild("RobloxGui") then
		parent_gui = CoreGui:FindFirstChild("RobloxGui")
	else
		parent_gui = CoreGui
	end

	local splash_gui = Instance.new("ScreenGui")
	splash_gui.Name = "NVL_FZ_Splash"
	splash_gui.ResetOnSpawn = false
	splash_gui.IgnoreGuiInset = true
	splash_gui.DisplayOrder = 999999
	splash_gui.Parent = parent_gui
	getgenv().NVL_SplashGui = splash_gui

	-- Backdrop làm tối màn hình game
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(4, 6, 10)
	backdrop.BackgroundTransparency = 0.35
	backdrop.BorderSizePixel = 0
	backdrop.Parent = splash_gui

	-- Splash Card trung tâm (Kích thước to, thoáng, chuẩn Cyber Glassmorphism)
	local card = Instance.new("Frame")
	card.Name = "SplashCard"
	card.Size = UDim2.new(0, 420, 0, 390)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
	card.BorderSizePixel = 0
	card.Parent = splash_gui

	local card_corner = Instance.new("UICorner")
	card_corner.CornerRadius = UDim.new(0, 16)
	card_corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(168, 85, 247)
	stroke.Parent = card

	local stroke_gradient = Instance.new("UIGradient")
	stroke_gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(168, 85, 247)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(56, 189, 248)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 85, 247)),
	})
	stroke_gradient.Rotation = 45
	stroke_gradient.Parent = stroke

	-- ĐÚNG 1 ẢNH GIF DUY NHẤT Ở GIỮA, KÍCH THƯỚC TO RÕ (230x230)
	local img_label = Instance.new("ImageLabel")
	img_label.Name = "FZ_SingleAnimation"
	img_label.Size = UDim2.new(0, 230, 0, 230)
	img_label.Position = UDim2.new(0.5, 0, 0, 18)
	img_label.AnchorPoint = Vector2.new(0.5, 0)
	img_label.BackgroundTransparency = 1
	img_label.BorderSizePixel = 0
	img_label.ScaleType = Enum.ScaleType.Fit
	img_label.Parent = card

	-- Tiêu đề Neverlose Universal
	local title = Instance.new("TextLabel")
	title.Text = "NEVERLOSE UNIVERSAL"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(240, 240, 255)
	title.Size = UDim2.new(1, 0, 0, 22)
	title.Position = UDim2.new(0, 0, 0, 260)
	title.BackgroundTransparency = 1
	title.Parent = card

	local title_gradient = Instance.new("UIGradient")
	title_gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(243, 232, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168, 85, 247)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 189, 248)),
	})
	title_gradient.Parent = title

	-- Dòng trạng thái khởi chạy
	local status = Instance.new("TextLabel")
	status.Text = "Preloading cyber assets [FZ]..."
	status.Font = Enum.Font.RobotoMono
	status.TextSize = 11
	status.TextColor3 = Color3.fromRGB(148, 163, 184)
	status.Size = UDim2.new(1, 0, 0, 16)
	status.Position = UDim2.new(0, 0, 0, 288)
	status.BackgroundTransparency = 1
	status.Parent = card

	-- Khung thanh tiến trình
	local p_track = Instance.new("Frame")
	p_track.Size = UDim2.new(0, 320, 0, 4)
	p_track.Position = UDim2.new(0.5, 0, 0, 318)
	p_track.AnchorPoint = Vector2.new(0.5, 0)
	p_track.BackgroundColor3 = Color3.fromRGB(22, 27, 40)
	p_track.BorderSizePixel = 0
	p_track.Parent = card

	local track_corner = Instance.new("UICorner")
	track_corner.CornerRadius = UDim.new(1, 0)
	track_corner.Parent = p_track

	local p_fill = Instance.new("Frame")
	p_fill.Size = UDim2.new(0, 0, 1, 0)
	p_fill.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
	p_fill.BorderSizePixel = 0
	p_fill.Parent = p_track

	local fill_corner = Instance.new("UICorner")
	fill_corner.CornerRadius = UDim.new(1, 0)
	fill_corner.Parent = p_fill

	local fill_gradient = Instance.new("UIGradient")
	fill_gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(168, 85, 247)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 189, 248)),
	})
	fill_gradient.Parent = p_fill

	-- Hướng dẫn Skip
	local skip_label = Instance.new("TextLabel")
	skip_label.Text = "[ Click anywhere or press Space to skip ]"
	skip_label.Font = Enum.Font.Gotham
	skip_label.TextSize = 10
	skip_label.TextColor3 = Color3.fromRGB(100, 116, 139)
	skip_label.Size = UDim2.new(1, 0, 0, 14)
	skip_label.Position = UDim2.new(0, 0, 0, 340)
	skip_label.BackgroundTransparency = 1
	skip_label.Parent = card

	-- Nạp toàn bộ 112 frame độc lập (Đảm bảo chỉ có 1 hình ảnh duy nhất, không bị chia lưới)
	local total_frames = 112
	local frame_assets = {}

	local base_path = "fz_intro/frame_"
	if isfile and isfile("uisimbl/fz_intro/frame_0.png") then
		base_path = "uisimbl/fz_intro/frame_"
	elseif isfile and isfile("fz_intro/frame_0.png") then
		base_path = "fz_intro/frame_"
	elseif isfile and isfile("Project-vibecod/uisimbl/fz_intro/frame_0.png") then
		base_path = "Project-vibecod/uisimbl/fz_intro/frame_"
	end

	-- Đặt frame 0 ngay lập tức để 0ms delay, không bị khoảng trống màu đen
	if getasset then
		pcall(function()
			frame_assets[0] = getasset(base_path .. "0.png")
			img_label.Image = frame_assets[0]
		end)
	end

	local is_done = false
	local skip_conn

	local function finish()
		if is_done then return end
		is_done = true

		if skip_conn then
			pcall(function() skip_conn:Disconnect() end)
			skip_conn = nil
		end

		local fade_info = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(backdrop, fade_info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(card, fade_info, {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.48, 0)
		}):Play()
		TweenService:Create(stroke, fade_info, { Transparency = 1 }):Play()
		TweenService:Create(img_label, fade_info, { ImageTransparency = 1 }):Play()
		TweenService:Create(title, fade_info, { TextTransparency = 1 }):Play()
		TweenService:Create(status, fade_info, { TextTransparency = 1 }):Play()
		TweenService:Create(p_track, fade_info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(p_fill, fade_info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(skip_label, fade_info, { TextTransparency = 1 }):Play()

		task.delay(0.38, function()
			pcall(function()
				img_label.Image = ""
				splash_gui:Destroy()
			end)
			getgenv().NVL_SplashGui = nil
			if on_complete then on_complete() end
		end)
	end

	-- Debounce chống skip ngoài ý muốn khi người dùng vừa click nút Execute hoặc click focus game
	local intro_start_time = os.clock()
	skip_conn = UserInputService.InputBegan:Connect(function(input, gpe)
		if is_done then return end
		-- Bỏ qua 0.6s đầu để click execute/focus cửa sổ không vô tình hủy intro
		if os.clock() - intro_start_time < 0.6 then return end
		if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
			if skip_conn then
				skip_conn:Disconnect()
				skip_conn = nil
			end
			finish()
		end
	end)

	-- Pre-resolve assets ngầm mượt mà (tránh giật lag I/O trong lúc animation đang chạy)
	task.spawn(function()
		for f = 1, total_frames - 1 do
			if is_done then break end
			if not frame_assets[f] and getasset then
				pcall(function()
					frame_assets[f] = getasset(base_path .. f .. ".png")
				end)
			end
		end
	end)

	-- Chạy chuỗi hoạt ảnh 112 frame cực mượt, ổn định FPS tuyệt đối
	task.spawn(function()
		local status_steps = {
			{ f = 0, text = "Verifying binary signature [FZ]..." },
			{ f = 25, text = "Hooking render pipelines & memory..." },
			{ f = 55, text = "Loading Atmosphere & Theme Presets..." },
			{ f = 85, text = "Config matrix validated..." },
			{ f = 105, text = "Launching Neverlose GUI..." },
		}

		for f = 0, total_frames - 1 do
			if is_done then break end

			local asset = frame_assets[f]
			if not asset and getasset then
				asset = getasset(base_path .. f .. ".png")
				frame_assets[f] = asset
			end

			if asset and asset ~= "" then
				img_label.Image = asset
			end
			p_fill.Size = UDim2.new((f + 1) / total_frames, 0, 1, 0)

			for _, step in ipairs(status_steps) do
				if f >= step.f then
					status.Text = step.text
				end
			end

			task.wait(0.024)
		end

		if not is_done then
			task.wait(0.1)
			if skip_conn then
				skip_conn:Disconnect()
				skip_conn = nil
			end
			finish()
		end
	end)
end

local auto_cfg = library:get_autoload_config()
local is_silent_mode = (auto_cfg == "Silentmode") or (getgenv().NVL_SILENT_MODE == true)

local function on_initialization_complete()
	-- 1. Bật CoreGui để lắng nghe UserInputService (Menu Key toggle)
	if library and library.gui then
		library.gui.Enabled = true
	end

	if is_silent_mode then
		-- Trong Silent Mode: Stream-proof 100% - KHÔNG HIỆN BẤT KỲ GIAO DIỆN NÀO KHI EXECUTE
		if window.window_frame then window.window_frame.Visible = false end
		if window.watermark_frame then window.watermark_frame.Visible = false end
		if window.keybinds_frame then window.keybinds_frame.Visible = false end
		if window.playerlist_frame then window.playerlist_frame.Visible = false end

		-- Nạp config Silentmode một cách âm thầm (tạm tắt notification)
		local cfg_to_load = (auto_cfg and auto_cfg ~= "") and auto_cfg or "Silentmode"
		local path = library.directory .. "/configs/" .. cfg_to_load .. ".cfg"
		if isfile and isfile(path) then
			local old_notif = library.notification
			library.notification = function() end
			library:load_config(cfg_to_load)
			library.notification = old_notif
			print(string.format("[Neverlose] ⚡ Silentmode loaded stealthily (Stream-proof)."))
		end

		-- Đảm bảo triệt để các thành phần stealth & tắt orbit / custom part
		flags["keybinds_enabled"] = false
		flags["watermark_enabled"] = false
		flags["player_list"] = false
		flags["aa_orbit"] = false
		flags["aa_custom_part"] = false
		if window.toggle_keybinds then window.toggle_keybinds(false) end
		if window.toggle_watermark then window.toggle_watermark(false) end
		if window.toggle_playerlist then window.toggle_playerlist(false) end
		if set_orbit_sliders_visible then set_orbit_sliders_visible(false) end
		if set_cp_visible then set_cp_visible(false) end

		-- Ép theme trắng đơn sắc (monochrome)
		library:update_theme("accent", Color3.fromRGB(255, 255, 255))
		if window.title_accent_line then
			window.title_accent_line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end

		-- Giữ nguyên trạng thái ẩn hoàn toàn trên màn hình
		if window.window_frame then window.window_frame.Visible = false end
		if window.watermark_frame then window.watermark_frame.Visible = false end
		if window.keybinds_frame then window.keybinds_frame.Visible = false end
		if window.playerlist_frame then window.playerlist_frame.Visible = false end
	else
		-- Chế độ thông thường: Hiển thị window chính
		if window.window_frame then
			window.window_frame.Visible = true
		end
		aimbot.open_tab()

		task.spawn(function()
			if auto_cfg and auto_cfg ~= "" then
				local path = library.directory .. "/configs/" .. auto_cfg .. ".cfg"
				if isfile and isfile(path) then
					library:load_config(auto_cfg)
					print(string.format("[Neverlose] ⚡ Autoloaded config: '%s'", auto_cfg))
					library:notification({
						text = "⚡ [Autoload] Active: '" .. auto_cfg .. "'",
						time = 5,
					})
				end
			end

			-- Đảm bảo trạng thái hiển thị đúng theo flags
			if window.watermark_frame then
				window.watermark_frame.Visible = (flags["watermark_enabled"] == true)
			end
			if window.keybinds_frame then
				window.keybinds_frame.Visible = (flags["keybinds_enabled"] == true)
			end
			if window.playerlist_frame then
				window.playerlist_frame.Visible = (flags["player_list"] == true)
			end
		end)
	end
end

if is_silent_mode then
	-- Nếu đang dùng Silentmode: Bỏ qua Splash Screen intro 100% để stream không bị lộ
	task.spawn(on_initialization_complete)
else
	play_splash_intro(on_initialization_complete)
end
