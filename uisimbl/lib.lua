--[[
    ========================================================================
    MemoryUI / LEYWIN Library - lib.lua (v4.0 Complete Edition)
    Faithfully matching the exact design, assets, and animations of
    C++ DirectX 11 / ImGui "LEYWIN" & "Memory" UI.

    Includes:
      - Native extracted Leywin Logo & Crown Logo with auto-fallback
      - 24 Crisp rendered vector SVG icons + Gear Settings icon
      - Sub-settings Gear Button (⚙) for Toggles with Keybind & Mode popup
      - Slider with enlarged hitbox (32px), animated hover/drag ring,
        snow drifting particles, glowing bloom, and direct editable TextBox
      - Active Tab Vertical Pill Indicator & TopBar Sub-Tabs (Thread, Enemy, Other, Team)
      - Live Watermark: PANDORA | LOBBY | 144FPS | 65PING | 12:15PM
      - Floating Spectators List Window (Raxxys, Sammill, Johhnyy...)
      - Asynchronous Discord avatar & username lookup (Neverlose-dahood logic)
      - Full Interactive HSV ColorPicker with SV Canvas, Hue bar, Hex & presets
      - Real-time search filter across cards and elements
    ========================================================================
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local CoreGui = (gethui and gethui()) or (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")

local safeRequest = (syn and syn.request) or (http and http.request) or http_request or request

-- Load local asset bundle
local Assets = {}
pcall(function()
	if isfile and isfile("uisimbl/memory_assets.lua") then
		Assets = loadstring(readfile("uisimbl/memory_assets.lua"))()
	elseif isfile and isfile("memory_assets.lua") then
		Assets = loadstring(readfile("memory_assets.lua"))()
	end
end)
Assets = Assets or {}
Assets.Icons = Assets.Icons or {}

-- Guarantee reset and human marker icons are loaded (offline custom asset PNG, 0 font dependency)
pcall(function()
	local decode = (crypt and (crypt.base64_decode or crypt.base64decode)) or (base64_decode or base64decode)
	if isfolder and not isfolder('uisimbl') then makefolder('uisimbl') end
	if isfolder and not isfolder('uisimbl/assets') then makefolder('uisimbl/assets') end
	if isfolder and not isfolder('uisimbl/assets/icons') then makefolder('uisimbl/assets/icons') end

	local pReset = 'uisimbl/assets/icons/reset.png'
	local b64Reset = 'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAFDUlEQVR4nO1az6tVVRT+9rnPn0FlSg6URhUWBCGvRDSUQqtJOBIaWhSJBDVxqjMnwgPDiQjSKBT/ABXFQRPTEiyCzIcETYpSU0Oq++OLdV2Lu952n3ffve+e6z33ng8O5559197nfGut/WOtvYEKFSqMEkhmmFRwwsnX9P7axCmC5BK97yd5yitk7EFySu97+BD7ffmkkP+IHbwz9h5AMji3N/JNkg9IbtDybNwI18Ties8i8nW93yb5pNXBuBBH+r8ZZ3lTwFXxjGGSnyqiUSVQCyE0ADRVCRsBbAHwBoDnAEyLKACRNcKzIYS6yjdRRgWQFOLy8Q2SawHsBbAbwEuRqMiYd4giBD/pvZweQHJKrE7yKQCfA/gEwFr7W0mbxX3XMMK/oMR9PdPfb5O87qY1cWnpBvOhqdfm0k2BnEv+QES8lSDbynm+T/JZaxMlJH9MiTRyLN7Qy0jbb5P9keTy0pCPAhgj/1/Cws2o7E5kfakjOF+qBRA7y9iDjnzK6oZzJHeRXENyhz57uS9K0//ZsfxbasW4v7eca18SwjntvEvymsp9VoogiNrvZaojORv145j8jPOUTJfBtiy2sUOWx3tJvmpyKIn1DyrJeo7bf7yA5fDou7uHkgnaj/9IDHBGfkblu67rtb2pUoz+7LjzgcQgZ27/rYv8Rp9UL1BrLSN5I+rrXgHbSune3eAGrel5XP9C2chnfchu1d+pcPUwSoasB1kLWbfrPbhysfifAC5pWQvjqAA+HNTWROVG9jqAv6SrhBBMWeOhAJIhhCBEJc5/MaprZK8o8dFeyETIepQXD2hncxO4jRIi66NOXv8uzci/WA+o5fw32kHMYhQQQrAB8B6AG1Hft9lAsryPZQawJXrRHhA0zX3L3mvlen+Z5BNutigEcduahZZRmhpxhqIXQt/Yu125WH2dKKGPdnuCI9oOrSUFT3IlyadlpnLeWlgY/GYiB2BL4RNetghILBI9Hyb5K8lbJE+TfEbLB6sEaoOaCPlNYwGLByww+pfkCz5ZOqh3q9UlwrwiZwg0rXaUj+KyeEM/3aEXLzieSIaYF9gBh7z1wmLC8H0JwpaFbqkBBB/6ekVEhBtI/jNPVLhH5ZYOkPwrJO/pOyz7HKff63od8nWL8oIvE15gH/W3nPVRub53ex35VSS/T4w9pnS7zAPe8986UFD7FsnnnUW8F9gHyqC025NZiCLiHCLJjbpt7j3MKzzGMX1XcTEJO16wL2dPwFvpiG15aR0bzGrR1S5zcktJfqpKTpG35/MkT5K8aKl1U2RhCojc83SOEnwf/V3ziOvRBXJCRA9M/ZCjUE/+pu5Eo1/ioRfhxIvkkg84C0D6fD0RLfpzAPcBXNbEyXcA7uqCSuq8rocopJ31rm4Wfae1dwfAzhCCJGGXmKyuVocDdmaFVTr/miekdoDj/YP5kLfB6s8S2SD7eKNQzlXCmYSbxopoKBEj2UyUxTAZwc+O/GhEoHQjru4Y1aMPT43WC4EnLviK5Gp9T22UzwpsinZ/zX39qi3lHd5DvIwMiO+7d41u2o1zpzLbBk/1/2Z0pSCLnw9sRVnE+j6gAJiFNJEqzxIm79QjctM6c8yZvgA80OsagK8BnJPQ27Vhp88GioDivaEdo7uyFQAkcSJK8f14VjJOIYS73doYJAKGAPUIudjNil62SOKGgCHD9eF4IBOi7dTWsL+pQoUKFSpUqFABk4j/AVZTYHDzt73MAAAAAElFTkSuQmCC'
	if decode and writefile then
		if not isfile or not isfile(pReset) or (readfile and #readfile(pReset) < 1500) then
			writefile(pReset, decode(b64Reset))
		end
	end
	if getcustomasset and isfile and isfile(pReset) then
		Assets.Icons['reset'] = getcustomasset(pReset)
	end

	local pHuman = 'uisimbl/assets/icons/human_marker.png'
	local b64Human = 'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAD2klEQVR4nO1bvWtUQRD/zd7hBzHgF0FTpFJQiKVaWkgiWPgvCAEbq1hYm97CVrCysBCsLSwSxULFQhEtjHZqjIiNBoO5j5/sZdaMj3vJxbzNvXfrD5bL2+zOvpnZnZmd3Qf8R9qQfg5O8s/4IkKkAJJCsm6Z1/oaSYdBBsla5nkfyb22PttmYEDVLskRkjMkn5H8puUNyVskx7VNX5dmTObPkfzEfKyQnNZlMhgzgcoIyQnDaINki2RbS8vUeczYvpUFVzXpywGSi8psc50Z0NZZ4H/PVF4IXNP+jNH8RggCmvNLp9KegWsu72UP2rezwJdlkmNKJ5oQXEzmNbgZBuAZkR7H8+18v50Ajpi6KHCIj14ZL6rfpuBiEfbaV3++DOCrarXXcNf3awBY0OdoYbKLRTjQFxEvgIfKVLuHPqHNewDvdCn10q/UAdAxNYANNXDr4Zf+Xqy8G8y4wmnj5poZQYRgKDB/T11gtZnvMhOuZbTdMtFfwF3dJHWCKAwKqMyQPEvyAcklw7RfGq9ITmXbx4ZsxyCGmZqINLVuzPj5RQBvRcTPhmCYWfkkCTUS3EL/6EkSiUXYv3hwX2rMhjNj2kDHazq4uqD1FRH5maVVCQFQX5jkKIArAM4DOLxJMj8AzAK4KSI+eeKXTwsVsvinSC5w6/AG8KlXYX9/yjJL8rASib5sZliA6cJHaO8sQHV4JG8bpgvYgZ4PFfhFjoLXMGuzmt6N4ALasyK0FZdaZ0AcFxtS2Hv7VAg1G97ARxSA1uUkQ35gdEwVJl3gwTQCXYioHC6DtWKLwqn65A4HBKHQ+JwSBwOicNFosuq0HWRXFWseL1WWgHI6jmAp/cdwLzu79sFan3JZ43073ZZZ4DTlNedAmm3ldasiHzUvEA5U2XU3RrJXSQfmXR3N7RMijzv0DRsiz+QPBpjNxjzHOB05tLDVrbCV5XmP+cXt9UIcnVrPKlb2ex6DdP3BYA5LY9zNjoh9p9UmoXnBeuIADWIebS9ADwzl0XkaaeC3AHgM4D95v9/vac5bC2/ABQbGaohs559xng95qIZvTr6h7ZJm/ft9NchcTgkDofE4ZA4HBKHQ+JwSBwOicMhcTgkDheZfl4M323Dw0EUgHRhzMf9nZNkUxdOkrM3QKh11bkux7UbIuPmckPTfBXiMU9yyH5BRvK2SYKEbFHoP1X6yxE5QpgyN0UCXpM8GdqZWyUHSd7PtPU3R2/E/HBCEAnmotQIgHEznZ+ISMN8T5Dt54WzRx8XRCRkgqsH5kzZbtrMuxpb2XuCAcqUyyRC2KPQWNmr8v+BauA3EkVxLs2+xjkAAAAASUVORK5CYII='
	if decode and writefile then
		if not isfile or not isfile(pHuman) or (readfile and #readfile(pHuman) < 1000) then
			writefile(pHuman, decode(b64Human))
		end
	end
	if getcustomasset and isfile and isfile(pHuman) then
		Assets.Icons['human_marker'] = getcustomasset(pHuman)
	end
end)

-- Ensure logos are resolved
local function GetLogoAsset(preferLeywin)
	if preferLeywin and Assets['leywin_logo'] and Assets['leywin_logo'] ~= "" then
		return Assets['leywin_logo']
	end
	if preferLeywin and getcustomasset and isfile and isfile("uisimbl/assets/leywin_logo.png") then
		return getcustomasset("uisimbl/assets/leywin_logo.png")
	end
	if Assets['sidebar_crown_logo'] and Assets['sidebar_crown_logo'] ~= "" then
		return Assets['sidebar_crown_logo']
	end
	if Assets['CrownLogo'] and Assets['CrownLogo'] ~= "" then
		return Assets['CrownLogo']
	end
	if getcustomasset and isfile and isfile("uisimbl/assets/sidebar_crown_logo.png") then
		return getcustomasset("uisimbl/assets/sidebar_crown_logo.png")
	end
	return ""
end

-- ========================================================================
-- Theme Definition (Neverlose / Memory Signature Theme)
-- ========================================================================
local Theme = {
	FrameBg        = Color3.fromRGB(15, 15, 18),    -- #0F0F12 (Window clear color)
	Sidebar        = Color3.fromRGB(9, 9, 10),      -- #09090A (Sidebar background)
	Container      = Color3.fromRGB(9, 9, 11),      -- #09090B (Main container)
	Header         = Color3.fromRGB(10, 10, 11),    -- #0A0A0B (Top navigation bar)
	Card           = Color3.fromRGB(11, 11, 13),    -- #0B0B0D (Card background)
	CardAlt        = Color3.fromRGB(12, 12, 13),    -- #0C0C0D (Secondary card)
	CardStroke     = Color3.fromRGB(22, 22, 25),    -- #161619 (Card border)
	CardDivider    = Color3.fromRGB(17, 17, 20),    -- #111114 (Card separator)
	Field          = Color3.fromRGB(14, 14, 16),    -- #0E0E10 (Input fields & pills dark)
	FieldStroke    = Color3.fromRGB(20, 20, 23),    -- #141417 (Field borders)
	BorderOuter    = Color3.fromRGB(24, 24, 27),    -- #18181B (Window outer border)
	BorderPurple   = Color3.fromRGB(59, 51, 76),    -- #3B334C (Active border glow)

	-- Signature Neverlose Lavender Purple Accent
	Accent         = Color3.fromRGB(186, 145, 252), -- #BA91FC (Signature Lavender Purple)
	AccentLight    = Color3.fromRGB(195, 158, 255),
	AccentDark     = Color3.fromRGB(161, 126, 219), -- #A17EDB
	Discord        = Color3.fromRGB(88, 101, 242),  -- #5865F2
	DiscordHover   = Color3.fromRGB(100, 112, 243),

	-- Text Colors
	TextBright     = Color3.fromRGB(240, 240, 245), -- White text active
	TextNormal     = Color3.fromRGB(208, 208, 212),
	TextSubtle     = Color3.fromRGB(189, 189, 192),
	TextMuted      = Color3.fromRGB(130, 130, 139),
	TextDark       = Color3.fromRGB(90, 90, 99),    -- Section titles (COMBAT, GENERAL...)
	TextDarker     = Color3.fromRGB(81, 81, 88),

	-- Status
	Success        = Color3.fromRGB(141, 209, 130),
	Error          = Color3.fromRGB(236, 88, 92),
}

local MemoryUI = {
	Flags = {},
	Connections = {},
	IsOpen = true,
	IsAuthenticated = false,
	NotificationsHolder = nil,
	ScreenGui = nil,
	ActiveColorPicker = nil,
	ActiveSubSettings = nil,
	WatermarkInstance = nil,
	SpectatorInstance = nil,
}

local function Create(className: string, properties: { [string]: any }): Instance
	local inst = Instance.new(className)
	for prop, val in pairs(properties) do
		pcall(function()
			inst[prop] = val
		end)
	end
	return inst
end

local function Tween(inst: Instance, info: TweenInfo, goals: { [string]: any }): Tween
	local tw = TweenService:Create(inst, info, goals)
	tw:Play()
	return tw
end

local function ColorToHex(color: Color3): string
	local r = math.round(color.R * 255)
	local g = math.round(color.G * 255)
	local b = math.round(color.B * 255)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function HexToColor(hex: string): Color3?
	hex = hex:gsub("#", ""):gsub("%s+", "")
	if #hex == 6 then
		local r = tonumber(hex:sub(1, 2), 16)
		local g = tonumber(hex:sub(3, 4), 16)
		local b = tonumber(hex:sub(5, 6), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	end
	return nil
end

-- ========================================================================
-- Toast Notification System
-- ========================================================================
function MemoryUI:Notify(config)
	config = config or {}
	local title = config.Title or "Notification"
	local content = config.Content or ""
	local duration = config.Duration or 3.2

	if not self.ScreenGui then return end

	if not self.NotificationsHolder then
		self.NotificationsHolder = Create("Frame", {
			Name = "NotificationContainer",
			Parent = self.ScreenGui,
			Size = UDim2.new(0, 310, 1, -40),
			Position = UDim2.new(1, -325, 0, 20),
			BackgroundTransparency = 1,
			ZIndex = 200,
		})
		Create("UIListLayout", {
			Parent = self.NotificationsHolder,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 8),
		})
	end

	local ToastWrapper = Create("Frame", {
		Name = "ToastWrapper",
		Parent = self.NotificationsHolder,
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 201,
	})

	local Toast = Create("Frame", {
		Name = "Toast",
		Parent = ToastWrapper,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(1, 60, 0, 0),
		BackgroundColor3 = Color3.fromRGB(15, 15, 18),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 202,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Toast })
	local ToastStroke = Create("UIStroke", { Parent = Toast, Color = Theme.Accent, Thickness = 1.2, Transparency = 1 })

	local LeftAccent = Create("Frame", {
		Parent = Toast,
		Size = UDim2.new(0, 3.5, 1, -16),
		Position = UDim2.new(0, 0, 0.5, -8),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 203,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = LeftAccent })

	local TitleLabel = Create("TextLabel", {
		Parent = Toast,
		Size = UDim2.new(1, -30, 0, 18),
		Position = UDim2.new(0, 14, 0, 9),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.TextBright,
		TextTransparency = 1,
		TextSize = 12.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 203,
	})

	local ContentLabel = Create("TextLabel", {
		Parent = Toast,
		Size = UDim2.new(1, -26, 0, 24),
		Position = UDim2.new(0, 14, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = content,
		TextColor3 = Theme.TextMuted,
		TextTransparency = 1,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 203,
	})

	-- Progress Bar Timer line
	local ProgressBar = Create("Frame", {
		Name = "ProgressBar",
		Parent = Toast,
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 204,
	})

	-- Entrance Animations
	Tween(Toast, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 0.05,
	})
	Tween(ToastStroke, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 0,
		Color = Theme.BorderPurple,
	})
	Tween(TitleLabel, TweenInfo.new(0.3), { TextTransparency = 0 })
	Tween(ContentLabel, TweenInfo.new(0.3), { TextTransparency = 0 })

	-- Progress bar shrinks linearly
	Tween(ProgressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 0, 2),
	})

	-- Dismissal Animation
	task.delay(duration, function()
		if ToastWrapper and ToastWrapper.Parent then
			Tween(Toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1, 70, 0, 0),
				BackgroundTransparency = 1,
			})
			Tween(ToastStroke, TweenInfo.new(0.25), { Transparency = 1 })
			Tween(TitleLabel, TweenInfo.new(0.2), { TextTransparency = 1 })
			Tween(ContentLabel, TweenInfo.new(0.2), { TextTransparency = 1 })
			task.delay(0.22, function()
				if ToastWrapper and ToastWrapper.Parent then
					local shrinkTween = Tween(ToastWrapper, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, 0),
					})
					shrinkTween.Completed:Connect(function()
						pcall(function() ToastWrapper:Destroy() end)
					end)
				end
			end)
		end
	end)
end

-- ========================================================================
-- Config Management System
-- ========================================================================
function MemoryUI:EnsureConfigFolder()
	if isfolder and not isfolder("uisimbl") then pcall(makefolder, "uisimbl") end
	if isfolder and not isfolder("uisimbl/configs") then pcall(makefolder, "uisimbl/configs") end
end

function MemoryUI:GetConfigList()
	self:EnsureConfigFolder()
	local list = {}
	if isfolder and isfolder("uisimbl/configs") and listfiles then
		for _, file in ipairs(listfiles("uisimbl/configs")) do
			local name = file:match("([^/\\]+)%.json$")
			if name then
				table.insert(list, name)
			end
		end
	end
	if #list == 0 then
		table.insert(list, "default")
	end
	return list
end

function MemoryUI:SaveConfig(name)
	if not name or name:gsub("%s+", "") == "" then
		self:Notify({ Title = "Config", Content = "Please enter a valid config name!", Duration = 2 })
		return false
	end
	name = name:gsub("[^%w_%-]", "")
	self:EnsureConfigFolder()
	local data = {}
	for flag, obj in pairs(self.Flags) do
		pcall(function()
			data[flag] = obj.Get()
		end)
	end
	local encoded = HttpService:JSONEncode(data)
	if writefile then
		writefile("uisimbl/configs/" .. name .. ".json", encoded)
	end
	self:Notify({ Title = "Config", Content = "Saved config: " .. name, Duration = 2.5 })
	return true
end

function MemoryUI:LoadConfig(name)
	if not name or name == "" then return false end
	name = name:gsub("[^%w_%-]", "")
	local path = "uisimbl/configs/" .. name .. ".json"
	if isfile and isfile(path) then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(readfile(path))
		end)
		if ok and type(decoded) == "table" then
			for flag, val in pairs(decoded) do
				if self.Flags[flag] and self.Flags[flag].Set then
					pcall(self.Flags[flag].Set, val)
				end
			end
			self:Notify({ Title = "Config", Content = "Loaded config: " .. name, Duration = 2.5 })
			return true
		end
	end
	self:Notify({ Title = "Config", Content = "Config not found: " .. name, Duration = 2 })
	return false
end

function MemoryUI:DeleteConfig(name)
	if not name or name == "" then return false end
	name = name:gsub("[^%w_%-]", "")
	local path = "uisimbl/configs/" .. name .. ".json"
	if isfile and isfile(path) and delfile then
		delfile(path)
		if isfile("uisimbl/autoload.txt") then
			local auto = readfile("uisimbl/autoload.txt"):gsub("%s+", "")
			if auto == name then
				delfile("uisimbl/autoload.txt")
			end
		end
		self:Notify({ Title = "Config", Content = "Deleted config: " .. name, Duration = 2.5 })
		return true
	end
	self:Notify({ Title = "Config", Content = "Could not delete: " .. name, Duration = 2 })
	return false
end

function MemoryUI:SetAutoload(name)
	if not name or name == "" then return false end
	name = name:gsub("[^%w_%-]", "")
	self:EnsureConfigFolder()
	if writefile then
		writefile("uisimbl/autoload.txt", name)
	end
	self:Notify({ Title = "Config", Content = "Set '" .. name .. "' as AutoLoad!", Duration = 2.5 })
	return true
end

function MemoryUI:GetAutoload()
	if isfile and isfile("uisimbl/autoload.txt") then
		local name = readfile("uisimbl/autoload.txt"):gsub("%s+", "")
		if name ~= "" then return name end
	end
	return nil
end

-- ========================================================================
-- Live Watermark: PANDORA | LOBBY | 144FPS | 65PING | 12:15PM
-- ========================================================================
function MemoryUI:CreateWatermark(config)
	config = config or {}
	local title = config.Title or "NEVERLOSE"
	local serverName = config.Server or "LOBBY"
	local visible = (config.Visible ~= false)

	if self.WatermarkInstance then
		self.WatermarkInstance:Destroy()
		self.WatermarkInstance = nil
	end

	local Holder = Create("Frame", {
		Name = "Watermark",
		Parent = self.ScreenGui,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 26),
		Position = UDim2.new(1, -12, 0, 12),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Color3.fromRGB(9, 10, 11),
		BorderSizePixel = 0,
		Visible = visible,
		ZIndex = 80,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Holder })
	Create("UIStroke", { Parent = Holder, Color = Color3.fromRGB(20, 23, 28), Thickness = 1 })

	local Layout = Create("UIListLayout", {
		Parent = Holder,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	})
	Create("UIPadding", {
		Parent = Holder,
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local function AddTag(text, isAccent)
		local lbl = Create("TextLabel", {
			Parent = Holder,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = text,
			TextColor3 = isAccent and Theme.Accent or Theme.TextBright,
			TextSize = 11,
			ZIndex = 81,
		})
		return lbl
	end

	local function AddSep()
		Create("Frame", {
			Parent = Holder,
			Size = UDim2.new(0, 1, 0, 12),
			BackgroundColor3 = Color3.fromRGB(42, 45, 55),
			BorderSizePixel = 0,
			ZIndex = 81,
		})
	end

	local TitleTag = AddTag(title, true)
	AddSep()
	local ServerTag = AddTag(serverName, false)
	AddSep()
	local FPSTag = AddTag("144 FPS", false)
	AddSep()
	local PingTag = AddTag("65 PING", false)
	AddSep()
	local TimeTag = AddTag(os.date("%I:%M %p"), false)

	-- Update FPS, Ping, and Time dynamically
	local frameCount = 0
	local lastTime = tick()
	local fpsConn = RunService.RenderStepped:Connect(function()
		frameCount += 1
		local curTime = tick()
		if curTime - lastTime >= 0.5 then
			local fps = math.round(frameCount / (curTime - lastTime))
			FPSTag.Text = tostring(fps) .. " FPS"
			frameCount = 0
			lastTime = curTime

			-- Update Ping
			pcall(function()
				local pingStat = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
				if pingStat then
					PingTag.Text = math.round(pingStat:GetValue()) .. " PING"
				end
			end)

			-- Update Clock
			TimeTag.Text = os.date("%I:%M %p")
		end
	end)
	table.insert(self.Connections, fpsConn)

	self.WatermarkInstance = Holder
	return {
		SetVisible = function(v) Holder.Visible = v end,
		SetTitle = function(t) TitleTag.Text = t end,
		SetServer = function(s) ServerTag.Text = s end,
	}
end

-- ========================================================================
-- Floating Spectators List Window (Dynamic Real-Time Player Tracking)
-- ========================================================================
function MemoryUI:CreateSpectators(config)
	config = config or {}
	local title = config.Title or "Spectators"

	-- Fetch currently connected real players in the server (excluding LocalPlayer)
	local function GetRealPlayers()
		local list = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= LocalPlayer then
				table.insert(list, {
					Name = pl.Name,
					DisplayName = pl.DisplayName,
					UserId = pl.UserId,
					Mode = "Watching",
				})
			end
		end
		return list
	end

	local initialPlayers = config.Players or GetRealPlayers()
	local visible = (config.Visible ~= false)
	local autoTrack = (config.AutoTrack ~= false)

	if self.SpectatorInstance then
		self.SpectatorInstance:Destroy()
		self.SpectatorInstance = nil
	end

	local WindowFrame = Create("Frame", {
		Name = "SpectatorsWindow",
		Parent = self.ScreenGui,
		Size = UDim2.new(0, 225, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 20, 0, 20),
		BackgroundColor3 = Color3.fromRGB(9, 10, 11),
		BorderSizePixel = 0,
		Visible = visible,
		ZIndex = 80,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = WindowFrame })
	Create("UIStroke", { Parent = WindowFrame, Color = Color3.fromRGB(20, 23, 28), Thickness = 1 })

	-- Header
	local Header = Create("Frame", {
		Parent = WindowFrame,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		ZIndex = 81,
	})
	Create("ImageLabel", {
		Parent = Header,
		Size = UDim2.new(0, 14, 0, 14),
		Position = UDim2.new(0, 12, 0.5, -7),
		BackgroundTransparency = 1,
		Image = Assets.Icons.users or "",
		ImageColor3 = Theme.Accent,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 82,
	})
	Create("TextLabel", {
		Parent = Header,
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.new(0, 32, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.TextBright,
		TextSize = 11.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 82,
	})
	Create("ImageLabel", {
		Parent = Header,
		Size = UDim2.new(0, 12, 0, 12),
		Position = UDim2.new(1, -22, 0.5, -6),
		BackgroundTransparency = 1,
		Image = Assets.Icons.dots_2 or "",
		ImageColor3 = Color3.fromRGB(90, 90, 100),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 82,
	})
	Create("Frame", {
		Parent = WindowFrame,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 32),
		BackgroundColor3 = Color3.fromRGB(19, 20, 22),
		BorderSizePixel = 0,
		ZIndex = 81,
	})

	-- Player List Container (ScrollingFrame showing ~4 players, rest scrollable)
	local ListContainer = Create("ScrollingFrame", {
		Parent = WindowFrame,
		Size = UDim2.new(1, 0, 0, 138),
		Position = UDim2.new(0, 0, 0, 33),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 81,
	})
	Create("UIListLayout", {
		Parent = ListContainer,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
	})
	Create("UIPadding", {
		Parent = ListContainer,
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 6),
	})

	local currentList = {}
	local playerRelations = {}
	local ActiveContextMenu = nil
	local ActiveBackdrop = nil

	local function CloseContextMenu()
		if ActiveContextMenu and ActiveContextMenu.Parent then
			ActiveContextMenu:Destroy()
			ActiveContextMenu = nil
		end
		if ActiveBackdrop and ActiveBackdrop.Parent then
			ActiveBackdrop:Destroy()
			ActiveBackdrop = nil
		end
	end

	local function OpenPlayerContextMenu(targetName, nameLabel, mousePos)
		CloseContextMenu()

		-- Invisible backdrop catches clicks outside the menu to dismiss it 100% reliably
		local Backdrop = Create("TextButton", {
			Name = "ContextMenuBackdrop",
			Parent = self.ScreenGui,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 499,
		})
		Backdrop.MouseButton1Click:Connect(CloseContextMenu)
		Backdrop.MouseButton2Click:Connect(CloseContextMenu)
		ActiveBackdrop = Backdrop

		local mouseLoc = UserInputService:GetMouseLocation()
		local guiInset = Vector2.zero
		pcall(function()
			guiInset = game:GetService("GuiService"):GetGuiInset()
		end)
		local posX = math.clamp(mouseLoc.X - guiInset.X, 10, 1800)
		local posY = math.clamp(mouseLoc.Y - guiInset.Y, 10, 1000)

		local menu = Create("Frame", {
			Name = "PlayerContextMenu",
			Parent = self.ScreenGui,
			Size = UDim2.new(0, 105, 0, 84),
			Position = UDim2.new(0, posX, 0, posY),
			BackgroundColor3 = Color3.fromRGB(15, 16, 19),
			BorderSizePixel = 0,
			Active = true,
			ZIndex = 500,
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = menu })
		Create("UIStroke", { Parent = menu, Color = Color3.fromRGB(30, 32, 42), Thickness = 1.2 })

		Create("UIListLayout", {
			Parent = menu,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		})
		Create("UIPadding", {
			Parent = menu,
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		})

		local options = {
			{ Text = "Enemy", Color = Color3.fromRGB(240, 75, 75), Hover = Color3.fromRGB(35, 18, 22) },
			{ Text = "Friendly", Color = Color3.fromRGB(90, 225, 110), Hover = Color3.fromRGB(18, 35, 22) },
			{ Text = "Neutral", Color = Theme.TextNormal, Hover = Color3.fromRGB(24, 25, 30) },
		}

		for _, opt in ipairs(options) do
			local btn = Create("TextButton", {
				Parent = menu,
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = Color3.fromRGB(15, 16, 19),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamMedium,
				Text = "  " .. opt.Text,
				TextColor3 = opt.Color,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				ZIndex = 501,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn })

			btn.MouseEnter:Connect(function()
				Tween(btn, TweenInfo.new(0.12), { BackgroundColor3 = opt.Hover, BackgroundTransparency = 0 })
			end)
			btn.MouseLeave:Connect(function()
				Tween(btn, TweenInfo.new(0.12), { BackgroundTransparency = 1 })
			end)

			btn.MouseButton1Click:Connect(function()
				local cleanKey = targetName:lower()
				playerRelations[cleanKey] = opt.Text
				playerRelations[targetName] = opt.Text

				local targetColor = Theme.TextBright
				if opt.Text == "Enemy" then
					targetColor = Color3.fromRGB(255, 75, 75)
				elseif opt.Text == "Friendly" then
					targetColor = Color3.fromRGB(80, 240, 120)
				else
					targetColor = Theme.TextBright
				end

				if nameLabel and nameLabel.Parent then
					nameLabel.TextColor3 = targetColor
				end

				if self._OnRelationChanged then
					task.spawn(self._OnRelationChanged, targetName, opt.Text)
				end

				MemoryUI:Notify({
					Title = "Spectators",
					Content = targetName .. " set to " .. opt.Text,
					Duration = 2,
				})
				CloseContextMenu()
			end)
		end

		ActiveContextMenu = menu
	end

	local function Populate(list)
		currentList = list or {}
		for _, ch in ipairs(ListContainer:GetChildren()) do
			if ch:IsA("Frame") or ch:IsA("TextLabel") or ch:IsA("TextButton") then ch:Destroy() end
		end

		-- Responsive height: show exact height if <= 4 players, cap at 138px with scrolling if > 4
		local targetH = math.clamp(#currentList * 34 + 8, 36, 138)
		ListContainer.Size = UDim2.new(1, 0, 0, targetH)

		if #currentList == 0 then
			local emptyRow = Create("Frame", {
				Parent = ListContainer,
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundTransparency = 1,
				ZIndex = 82,
			})
			Create("ImageLabel", {
				Parent = emptyRow,
				Size = UDim2.new(0, 12, 0, 12),
				Position = UDim2.new(0, 12, 0.5, -6),
				BackgroundTransparency = 1,
				Image = Assets.Icons.eye or "",
				ImageColor3 = Color3.fromRGB(100, 100, 110),
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 83,
			})
			Create("TextLabel", {
				Parent = emptyRow,
				Size = UDim2.new(1, -36, 1, 0),
				Position = UDim2.new(0, 32, 0, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamMedium,
				Text = "No spectators watching",
				TextColor3 = Color3.fromRGB(110, 110, 120),
				TextSize = 10.5,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 83,
			})
			return
		end

		for i, item in ipairs(currentList) do
			local name = ""
			local displayName = ""
			local uid = 1
			local mode = "Watching"

			if type(item) == "table" then
				name = item.Name or item.Username or "Player"
				displayName = item.DisplayName or name
				uid = item.UserId or 1
				mode = item.Mode or "Watching"
			else
				name = tostring(item)
				displayName = name
				local robloxPlayer = Players:FindFirstChild(name)
				if robloxPlayer then
					displayName = robloxPlayer.DisplayName
					uid = robloxPlayer.UserId
				else
					uid = math.abs(tonumber(string.byte(name, 1) or 1) * 31337) % 50000000 + 1
				end
				mode = "Watching"
			end

			mode = "Watching"

			local rel = playerRelations[name:lower()] or playerRelations[name] or "Neutral"
			local nameColor = Theme.TextBright
			if rel == "Enemy" then
				nameColor = Color3.fromRGB(255, 75, 75)
			elseif rel == "Friendly" then
				nameColor = Color3.fromRGB(80, 240, 120)
			end

			local row = Create("TextButton", {
				Parent = ListContainer,
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 82,
			})

			-- Circular Avatar Thumbnail
			local AvatarImg = Create("ImageLabel", {
				Parent = row,
				Size = UDim2.new(0, 22, 0, 22),
				Position = UDim2.new(0, 10, 0.5, -11),
				BackgroundColor3 = Color3.fromRGB(18, 19, 22),
				BorderSizePixel = 0,
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(uid) .. "&w=48&h=48",
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 83,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = AvatarImg })
			Create("UIStroke", { Parent = AvatarImg, Color = Color3.fromRGB(30, 32, 40), Thickness = 1 })

			-- DisplayName Label
			local DisplayLabel = Create("TextLabel", {
				Parent = row,
				Size = UDim2.new(0, 95, 0, 14),
				Position = UDim2.new(0, 38, 0, 3),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = displayName,
				TextColor3 = nameColor,
				TextSize = 10.5,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Active = false,
				ZIndex = 83,
			})

			-- @Username Label (Click to copy UserId with 3s feedback)
			local UserLabel = Create("TextButton", {
				Parent = row,
				Size = UDim2.new(0, 95, 0, 12),
				Position = UDim2.new(0, 38, 0, 17),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamMedium,
				Text = "@" .. name:lower(),
				TextColor3 = Color3.fromRGB(115, 115, 125),
				TextSize = 9,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Active = true,
				AutoButtonColor = false,
				ZIndex = 83,
			})

			local isCopiedFeedback = false
			local function TriggerCopy()
				if isCopiedFeedback then return end
				isCopiedFeedback = true
				local idStr = tostring(uid)
				pcall(function()
					if setclipboard then
						setclipboard(idStr)
					elseif toclipboard then
						toclipboard(idStr)
					end
				end)

				local origText = "@" .. name:lower()
				UserLabel.Text = "[COPIED ID]"
				UserLabel.TextColor3 = Color3.fromRGB(80, 255, 140)

				MemoryUI:Notify({
					Title = "Clipboard",
					Content = "Copied UserId " .. idStr .. " (@" .. name .. ")",
					Duration = 2,
				})

				task.delay(3, function()
					if UserLabel and UserLabel.Parent then
						UserLabel.Text = origText
						UserLabel.TextColor3 = Color3.fromRGB(115, 115, 125)
					end
					isCopiedFeedback = false
				end)
			end

			UserLabel.MouseButton1Click:Connect(TriggerCopy)
			UserLabel.MouseEnter:Connect(function()
				if not isCopiedFeedback then
					Tween(UserLabel, TweenInfo.new(0.15), { TextColor3 = Theme.Accent })
				end
			end)
			UserLabel.MouseLeave:Connect(function()
				if not isCopiedFeedback then
					Tween(UserLabel, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(115, 115, 125) })
				end
			end)

			-- Right Click Context Menu Handler (Row & Labels)
			local function HandleRightClick(pos)
				OpenPlayerContextMenu(name, DisplayLabel, pos)
			end

			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton2 then
					HandleRightClick(input.Position)
				end
			end)
			row.MouseButton2Click:Connect(function()
				HandleRightClick(UserInputService:GetMouseLocation())
			end)
			UserLabel.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton2 then
					HandleRightClick(input.Position)
				end
			end)

			-- Mode Tag Button (Clicking it spectates this player)
			local ModeBtn = Create("TextButton", {
				Parent = row,
				Size = UDim2.new(0, 68, 0, 18),
				Position = UDim2.new(1, -78, 0.5, -9),
				BackgroundColor3 = Color3.fromRGB(17, 18, 22),
				BorderSizePixel = 0,
				Font = Enum.Font.GothamMedium,
				Text = mode,
				TextColor3 = Theme.Accent,
				TextSize = 9,
				AutoButtonColor = false,
				ZIndex = 84,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ModeBtn })
			local ModeStroke = Create("UIStroke", { Parent = ModeBtn, Color = Color3.fromRGB(28, 30, 38), Thickness = 1 })

			ModeBtn.MouseEnter:Connect(function()
				Tween(ModeBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(25, 27, 35) })
				Tween(ModeStroke, TweenInfo.new(0.15), { Color = Theme.Accent })
			end)
			ModeBtn.MouseLeave:Connect(function()
				Tween(ModeBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(17, 18, 22) })
				Tween(ModeStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(28, 30, 38) })
			end)

			ModeBtn.MouseButton1Click:Connect(function()
				local target = Players:FindFirstChild(name)
				if not target then
					for _, p in ipairs(Players:GetPlayers()) do
						if p.DisplayName:lower() == name:lower() or p.Name:lower() == name:lower() then
							target = p
							break
						end
					end
				end

				local cam = workspace.CurrentCamera
				if target and target.Character and target.Character:FindFirstChild("Humanoid") then
					if cam.CameraSubject == target.Character.Humanoid then
						if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
							cam.CameraSubject = LocalPlayer.Character.Humanoid
							MemoryUI:Notify({ Title = "Spectate", Content = "Camera returned to LocalPlayer", Duration = 2 })
						end
					else
						cam.CameraSubject = target.Character.Humanoid
						MemoryUI:Notify({ Title = "Spectate", Content = "Spectating " .. target.DisplayName .. " (@" .. target.Name .. ")", Duration = 2.5 })
					end
				else
					MemoryUI:Notify({ Title = "Spectate", Content = "Player character not available: " .. name, Duration = 2 })
				end
			end)

			if i < #currentList then
				Create("Frame", {
					Parent = row,
					Size = UDim2.new(1, -20, 0, 1),
					Position = UDim2.new(0, 10, 1, -1),
					BackgroundColor3 = Color3.fromRGB(17, 18, 20),
					BorderSizePixel = 0,
					ZIndex = 83,
				})
			end
		end
	end

	Populate(initialPlayers)

	-- Event-driven Live Player Tracking (Instant removal on leave, zero polling, zero FPS impact!)
	if autoTrack then
		local addConn = Players.PlayerAdded:Connect(function(newPl)
			if newPl ~= LocalPlayer then
				table.insert(currentList, {
					Name = newPl.Name,
					DisplayName = newPl.DisplayName,
					UserId = newPl.UserId,
					Mode = "Watching",
				})
				Populate(currentList)
			end
		end)

		local removeConn = Players.PlayerRemoving:Connect(function(leavingPl)
			for idx = #currentList, 1, -1 do
				local it = currentList[idx]
				local pName = (type(it) == "table" and it.Name) or tostring(it)
				if pName:lower() == leavingPl.Name:lower() then
					table.remove(currentList, idx)
				end
			end
			Populate(currentList)
		end)

		table.insert(self.Connections, addConn)
		table.insert(self.Connections, removeConn)
	end

	-- Make Spectator Window Draggable
	local dragging, dragStart, startPos
	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = WindowFrame.Position
		end
	end)
	local moveConn = UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			WindowFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	local endConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	table.insert(self.Connections, moveConn)
	table.insert(self.Connections, endConn)

	self.SpectatorInstance = WindowFrame
	return {
		SetVisible = function(v) WindowFrame.Visible = v end,
		SetPlayers = Populate,
		Add = function(p)
			table.insert(currentList, p)
			Populate(currentList)
		end,
		Remove = function(pName)
			for idx, item in ipairs(currentList) do
				local n = (type(item) == "table" and (item.Name or item.DisplayName)) or tostring(item)
				if n == pName then
					table.remove(currentList, idx)
					break
				end
			end
			Populate(currentList)
		end,
		GetRelation = function(pName)
			if not pName then return "Neutral" end
			local cleanKey = string.lower(pName)
			return playerRelations[cleanKey] or playerRelations[pName] or "Neutral"
		end,
		SetOnRelationChanged = function(cb)
			self._OnRelationChanged = cb
		end,
	}
end

-- ========================================================================
-- Floating Keybinds HUD Window (Neverlose-Style Dynamic Active Binds Tracker)
-- ========================================================================
MemoryUI.RegisteredKeybinds = {}

function MemoryUI:RegisterKeybind(data)
	if not data or not data.Name then return end
	MemoryUI.RegisteredKeybinds[data.Name] = data
	if self.KeybindsInstance and self.KeybindsInstance.Refresh then
		self.KeybindsInstance:Refresh()
	end
end

function MemoryUI:UnregisterKeybind(name)
	MemoryUI.RegisteredKeybinds[name] = nil
	if self.KeybindsInstance and self.KeybindsInstance.Refresh then
		self.KeybindsInstance:Refresh()
	end
end

function MemoryUI:CreateKeybinds(config)
	config = config or {}
	local title = config.Title or "Keybinds"
	local visible = (config.Visible ~= false)

	if self.KeybindsInstance and self.KeybindsInstance.WindowFrame then
		self.KeybindsInstance.WindowFrame:Destroy()
		self.KeybindsInstance = nil
	end

	local WindowFrame = Create("Frame", {
		Name = "KeybindsWindow",
		Parent = self.ScreenGui,
		Size = UDim2.new(0, 195, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = config.Position or UDim2.new(0, 20, 0, 210),
		BackgroundColor3 = Color3.fromRGB(9, 10, 11),
		BorderSizePixel = 0,
		Visible = visible,
		ZIndex = 80,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = WindowFrame })
	Create("UIStroke", { Parent = WindowFrame, Color = Color3.fromRGB(20, 23, 28), Thickness = 1 })

	-- Header
	local Header = Create("Frame", {
		Parent = WindowFrame,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		ZIndex = 81,
	})
	Create("ImageLabel", {
		Parent = Header,
		Size = UDim2.new(0, 13, 0, 13),
		Position = UDim2.new(0, 10, 0.5, -6.5),
		BackgroundTransparency = 1,
		Image = Assets.Icons.sliders or "rbxassetid://10734941499",
		ImageColor3 = Theme.Accent,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 82,
	})
	Create("TextLabel", {
		Parent = Header,
		Size = UDim2.new(1, -45, 1, 0),
		Position = UDim2.new(0, 28, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.TextBright,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 82,
	})
	Create("ImageLabel", {
		Parent = Header,
		Size = UDim2.new(0, 12, 0, 12),
		Position = UDim2.new(1, -20, 0.5, -6),
		BackgroundTransparency = 1,
		Image = Assets.Icons.dots_2 or "",
		ImageColor3 = Color3.fromRGB(90, 90, 100),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 82,
	})
	Create("Frame", {
		Parent = WindowFrame,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(19, 20, 22),
		BorderSizePixel = 0,
		ZIndex = 81,
	})

	-- Binds Container
	local BindsContainer = Create("Frame", {
		Name = "BindsContainer",
		Parent = WindowFrame,
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 31),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 81,
	})
	Create("UIListLayout", {
		Parent = BindsContainer,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
	})
	Create("UIPadding", {
		Parent = BindsContainer,
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 6),
	})

	-- Empty Placeholder label when no binds are active
	local EmptyLabel = Create("TextLabel", {
		Name = "EmptyLabel",
		Parent = BindsContainer,
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "[no active binds]",
		TextColor3 = Color3.fromRGB(80, 85, 100),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		ZIndex = 82,
	})

	-- Draggable Header
	local dragging, dragStart, startPos
	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = WindowFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			WindowFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	local controller = {
		WindowFrame = WindowFrame,
		Header = Header,
		BindsContainer = BindsContainer,
	}

	function controller:SetVisible(vis)
		WindowFrame.Visible = vis
	end

	function controller:Toggle()
		WindowFrame.Visible = not WindowFrame.Visible
	end

	function controller:Refresh()
		for _, ch in ipairs(BindsContainer:GetChildren()) do
			if ch:IsA("Frame") and ch.Name:sub(1, 5) == "Bind_" then
				ch:Destroy()
			end
		end

		local activeCount = 0
		for name, bindData in pairs(MemoryUI.RegisteredKeybinds) do
			if bindData.ShowInBinds then
				local isActive = false
				if type(bindData.IsActive) == "function" then
					local s, res = pcall(bindData.IsActive)
					isActive = s and res
				elseif bindData.Active ~= nil then
					isActive = bindData.Active
				end

				if isActive then
					activeCount = activeCount + 1
					local row = Create("Frame", {
						Name = "Bind_" .. name,
						Parent = BindsContainer,
						Size = UDim2.new(1, 0, 0, 22),
						BackgroundTransparency = 1,
						ZIndex = 82,
					})

					-- Feature Name (Left)
					Create("TextLabel", {
						Parent = row,
						Size = UDim2.new(1, -65, 1, 0),
						Position = UDim2.new(0, 10, 0, 0),
						BackgroundTransparency = 1,
						Font = Enum.Font.GothamMedium,
						Text = name,
						TextColor3 = Theme.TextWhite,
						TextSize = 10.5,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						ZIndex = 83,
					})

					-- Mode Badge (Right: e.g. [toggle] in Accent color)
					local modeText = string.lower(bindData.Mode or "toggle")
					Create("TextLabel", {
						Parent = row,
						Size = UDim2.new(0, 52, 1, 0),
						Position = UDim2.new(1, -58, 0, 0),
						BackgroundTransparency = 1,
						Font = Enum.Font.GothamBold,
						Text = "[" .. modeText .. "]",
						TextColor3 = Theme.Accent,
						TextSize = 10,
						TextXAlignment = Enum.TextXAlignment.Right,
						ZIndex = 83,
					})
				end
			end
		end

		EmptyLabel.Visible = (activeCount == 0)
	end

	self.KeybindsInstance = controller
	controller:Refresh()
	return controller
end

-- ========================================================================
-- Dropdown Management (Auto-close on tab switch, prevent bleed-through)
-- ========================================================================
function MemoryUI:CloseActiveDropdown()
	if self.ActiveDropdown and typeof(self.ActiveDropdown.Close) == "function" then
		pcall(self.ActiveDropdown.Close)
		self.ActiveDropdown = nil
	end
end

-- ========================================================================
-- Sub-Settings Popout Modal (Toggled via Gear Button ⚙, NO 'X' button)
-- ========================================================================
function MemoryUI:OpenSubSettings(config)
	config = config or {}
	local title = config.Title or "Settings"
	local curKey = config.Keybind or Enum.KeyCode.F
	local curMode = config.Mode or "Toggle"
	local showInBinds = config.ShowInBinds or false
	local callback = config.Callback or function() end
	local owner = config.Owner

	-- Smooth Close Helper
	local function CloseModal()
		if self.ActiveSubSettingsBackdrop and self.ActiveSubSettingsBackdrop.Parent then
			self.ActiveSubSettingsBackdrop:Destroy()
			self.ActiveSubSettingsBackdrop = nil
		end
		if self.ActiveSubSettings and self.ActiveSubSettings.Parent and not self.ActiveSubSettingsClosing then
			self.ActiveSubSettingsClosing = true
			local targetModal = self.ActiveSubSettings
			local targetScale = targetModal:FindFirstChildOfClass("UIScale")
			if targetScale then
				Tween(targetScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.75 })
			end
			Tween(targetModal, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = targetModal.Position + UDim2.new(0, 0, 0, -8),
				BackgroundTransparency = 1,
			})
			task.delay(0.18, function()
				if targetModal and targetModal.Parent then
					targetModal:Destroy()
				end
				if self.ActiveSubSettings == targetModal then
					self.ActiveSubSettings = nil
					self.ActiveSubSettingsOwner = nil
				end
				self.ActiveSubSettingsClosing = false
			end)
		end
	end

	-- Toggle behavior: clicking the same gear button closes the modal with animation
	if self.ActiveSubSettings and self.ActiveSubSettings.Parent then
		local prevOwner = self.ActiveSubSettingsOwner
		CloseModal()
		if prevOwner and prevOwner == owner then
			return
		end
	end

	self.ActiveSubSettingsOwner = owner

	-- Full-screen modal isolation backdrop (blocks click pass-through to background elements)
	local Backdrop = Create("TextButton", {
		Name = "SubSettingsBackdrop",
		Parent = self.ScreenGui,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		ZIndex = 399,
	})
	Backdrop.MouseButton1Click:Connect(function()
		CloseModal()
	end)
	self.ActiveSubSettingsBackdrop = Backdrop

	local targetPos = config.Position or UDim2.new(0.5, -100, 0.5, -70)
	local Modal = Create("Frame", {
		Name = "SubSettingsPopout",
		Parent = self.ScreenGui,
		Size = UDim2.new(0, 200, 0, 140),
		Position = targetPos + UDim2.new(0, 0, 0, -10),
		BackgroundColor3 = Color3.fromRGB(15, 16, 19),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 400,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Modal })
	Create("UIStroke", { Parent = Modal, Color = Theme.BorderPurple, Thickness = 1.5 })

	local ModalScale = Create("UIScale", {
		Parent = Modal,
		Scale = 0.75,
	})

	-- Animate Open with Spring Back easing
	Tween(Modal, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPos,
		BackgroundTransparency = 0,
	})
	Tween(ModalScale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1.0,
	})

	self.ActiveSubSettings = Modal

	-- Header (NO 'X' button - closed strictly by clicking gear icon or outside)
	local Header = Create("Frame", {
		Parent = Modal,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		ZIndex = 251,
	})
	Create("TextLabel", {
		Parent = Header,
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.TextBright,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 252,
	})

	-- 1. Keybind Row
	local KeyRow = Create("Frame", {
		Parent = Modal,
		Size = UDim2.new(1, -20, 0, 26),
		Position = UDim2.new(0, 10, 0, 32),
		BackgroundTransparency = 1,
		ZIndex = 251,
	})
	Create("TextLabel", {
		Parent = KeyRow,
		Size = UDim2.new(0, 60, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "Key",
		TextColor3 = Theme.TextNormal,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 252,
	})
	local KeyBox = Create("TextButton", {
		Parent = KeyRow,
		Size = UDim2.new(0, 80, 1, 0),
		Position = UDim2.new(1, -80, 0, 0),
		BackgroundColor3 = Color3.fromRGB(20, 21, 25),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = (typeof(curKey) == "EnumItem") and curKey.Name or tostring(curKey),
		TextColor3 = Theme.Accent,
		TextSize = 10.5,
		ZIndex = 252,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = KeyBox })
	Create("UIStroke", { Parent = KeyBox, Color = Color3.fromRGB(30, 32, 38), Thickness = 1 })

	local listening = false
	KeyBox.MouseButton1Click:Connect(function()
		listening = true
		KeyBox.Text = "..."
	end)
	local keyConn = UserInputService.InputBegan:Connect(function(input)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			curKey = input.KeyCode
			KeyBox.Text = curKey.Name
			pcall(callback, { Key = curKey, Mode = curMode, ShowInBinds = showInBinds })
		end
	end)
	table.insert(self.Connections, keyConn)

	-- 2. Mode Selector (Hold / Toggle / Always)
	local ModeRow = Create("Frame", {
		Parent = Modal,
		Size = UDim2.new(1, -20, 0, 26),
		Position = UDim2.new(0, 10, 0, 64),
		BackgroundTransparency = 1,
		ZIndex = 251,
	})
	Create("TextLabel", {
		Parent = ModeRow,
		Size = UDim2.new(0, 60, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "Mode",
		TextColor3 = Theme.TextNormal,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 252,
	})
	local ModeBtn = Create("TextButton", {
		Parent = ModeRow,
		Size = UDim2.new(0, 80, 1, 0),
		Position = UDim2.new(1, -80, 0, 0),
		BackgroundColor3 = Color3.fromRGB(20, 21, 25),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = curMode,
		TextColor3 = Theme.TextBright,
		TextSize = 10.5,
		ZIndex = 252,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ModeBtn })
	Create("UIStroke", { Parent = ModeBtn, Color = Color3.fromRGB(30, 32, 38), Thickness = 1 })

	local modes = { "Hold", "Toggle", "Always" }
	local mIdx = table.find(modes, curMode) or 1
	ModeBtn.MouseButton1Click:Connect(function()
		mIdx = (mIdx % #modes) + 1
		curMode = modes[mIdx]
		ModeBtn.Text = curMode
		pcall(callback, { Key = curKey, Mode = curMode, ShowInBinds = showInBinds })
	end)

	-- 3. Show in Binds Checkbox
	local BindRow = Create("Frame", {
		Parent = Modal,
		Size = UDim2.new(1, -20, 0, 26),
		Position = UDim2.new(0, 10, 0, 96),
		BackgroundTransparency = 1,
		ZIndex = 251,
	})
	Create("TextLabel", {
		Parent = BindRow,
		Size = UDim2.new(1, -30, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "Show in Binds",
		TextColor3 = Theme.TextNormal,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 252,
	})
	local CheckBox = Create("TextButton", {
		Parent = BindRow,
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(1, -16, 0.5, -8),
		BackgroundColor3 = showInBinds and Theme.Accent or Color3.fromRGB(20, 21, 25),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = showInBinds and "✓" or "",
		TextColor3 = Theme.TextBright,
		TextSize = 11,
		ZIndex = 252,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = CheckBox })
	Create("UIStroke", { Parent = CheckBox, Color = Color3.fromRGB(35, 38, 45), Thickness = 1 })

	CheckBox.MouseButton1Click:Connect(function()
		showInBinds = not showInBinds
		CheckBox.Text = showInBinds and "✓" or ""
		CheckBox.BackgroundColor3 = showInBinds and Theme.Accent or Color3.fromRGB(20, 21, 25)
		pcall(callback, { Key = curKey, Mode = curMode, ShowInBinds = showInBinds })
	end)

	-- Outside Click Detection to close with animation
	local outsideConn
	outsideConn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if Modal and Modal.Parent then
				local mPos = Modal.AbsolutePosition
				local mSize = Modal.AbsoluteSize
				local x, y = input.Position.X, input.Position.Y
				local insideModal = (x >= mPos.X and x <= mPos.X + mSize.X and y >= mPos.Y and y <= mPos.Y + mSize.Y)
				local insideOwner = false
				if owner and owner.Parent then
					local oPos = owner.AbsolutePosition
					local oSize = owner.AbsoluteSize
					insideOwner = (x >= oPos.X and x <= oPos.X + oSize.X and y >= oPos.Y and y <= oPos.Y + oSize.Y)
				end
				if not insideModal and not insideOwner then
					if outsideConn then outsideConn:Disconnect() end
					CloseModal()
				end
			else
				if outsideConn then outsideConn:Disconnect() end
			end
		end
	end)
	table.insert(self.Connections, outsideConn)

	return Modal
end

-- ========================================================================
-- Full Interactive HSV ColorPicker Modal
-- ========================================================================
function MemoryUI:OpenColorPicker(config)
	config = config or {}
	local initialColor = config.Color or Theme.Accent
	local callback = config.Callback or function() end
	local title = config.Title or "Color Picker"

	if self.ActiveColorPicker and self.ActiveColorPicker.Parent then
		self.ActiveColorPicker:Destroy()
		self.ActiveColorPicker = nil
	end

	local currentH, currentS, currentV = Color3.toHSV(initialColor)

	local ModalHolder = Create("Frame", {
		Name = "ColorPickerModal",
		Parent = self.ScreenGui,
		Size = UDim2.new(0, 260, 0, 310),
		Position = config.Position or UDim2.new(0.5, -130, 0.5, -155),
		BackgroundColor3 = Color3.fromRGB(15, 15, 18),
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 400,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = ModalHolder })
	Create("UIStroke", { Parent = ModalHolder, Color = Theme.BorderPurple, Thickness = 1.5 })

	self.ActiveColorPicker = ModalHolder

	-- Top Header
	local Header = Create("Frame", {
		Parent = ModalHolder,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		ZIndex = 401,
	})
	Create("TextLabel", {
		Parent = Header,
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.TextBright,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 402,
	})

	local CloseBtn = Create("TextButton", {
		Parent = Header,
		Size = UDim2.new(0, 24, 0, 24),
		Position = UDim2.new(1, -28, 0.5, -12),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "×",
		TextColor3 = Theme.TextMuted,
		TextSize = 18,
		ZIndex = 402,
	})
	CloseBtn.MouseButton1Click:Connect(function()
		ModalHolder:Destroy()
		MemoryUI.ActiveColorPicker = nil
		MemoryUI.IsModalInteracting = false
	end)

	-- SV Box (232 x 130)
	local SVBox = Create("Frame", {
		Name = "SVBox",
		Parent = ModalHolder,
		Size = UDim2.new(1, -28, 0, 130),
		Position = UDim2.new(0, 14, 0, 38),
		BackgroundColor3 = Color3.fromHSV(currentH, 1, 1),
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
		ZIndex = 402,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SVBox })

	local WhiteGrad = Create("Frame", {
		Parent = SVBox,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 203,
	})
	Create("UIGradient", {
		Parent = WhiteGrad,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})

	local BlackGrad = Create("Frame", {
		Parent = SVBox,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 204,
	})
	Create("UIGradient", {
		Parent = BlackGrad,
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
	})

	local SVCursor = Create("Frame", {
		Parent = SVBox,
		Size = UDim2.new(0, 10, 0, 10),
		Position = UDim2.new(currentS, -5, 1 - currentV, -5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 205,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SVCursor })
	Create("UIStroke", { Parent = SVCursor, Color = Color3.fromRGB(0, 0, 0), Thickness = 1.5 })

	-- Hue Slider Bar (232 x 14)
	local HueBar = Create("Frame", {
		Name = "HueBar",
		Parent = ModalHolder,
		Size = UDim2.new(1, -28, 0, 14),
		Position = UDim2.new(0, 14, 0, 176),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 402,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = HueBar })
	Create("UIGradient", {
		Parent = HueBar,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
	})

	local HueCursor = Create("Frame", {
		Parent = HueBar,
		Size = UDim2.new(0, 6, 1, 4),
		Position = UDim2.new(currentH, -3, 0.5, -9),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 205,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = HueCursor })
	Create("UIStroke", { Parent = HueCursor, Color = Color3.fromRGB(0, 0, 0), Thickness = 1 })

	-- Info Row
	local InfoRow = Create("Frame", {
		Parent = ModalHolder,
		Size = UDim2.new(1, -28, 0, 28),
		Position = UDim2.new(0, 14, 0, 198),
		BackgroundTransparency = 1,
		ZIndex = 202,
	})

	local SwatchPreview = Create("Frame", {
		Parent = InfoRow,
		Size = UDim2.new(0, 48, 1, 0),
		BackgroundColor3 = initialColor,
		BorderSizePixel = 0,
		ZIndex = 203,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SwatchPreview })
	Create("UIStroke", { Parent = SwatchPreview, Color = Color3.fromRGB(35, 35, 42), Thickness = 1 })

	local HexBox = Create("Frame", {
		Parent = InfoRow,
		Size = UDim2.new(1, -56, 1, 0),
		Position = UDim2.new(0, 56, 0, 0),
		BackgroundColor3 = Color3.fromRGB(12, 12, 14),
		BorderSizePixel = 0,
		ZIndex = 203,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = HexBox })
	local HexStroke = Create("UIStroke", { Parent = HexBox, Color = Color3.fromRGB(25, 25, 30), Thickness = 1 })

	local HexInput = Create("TextBox", {
		Parent = HexBox,
		Size = UDim2.new(1, -8, 1, 0),
		Position = UDim2.new(0, 6, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = ColorToHex(initialColor),
		TextColor3 = Theme.TextBright,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		ClearTextOnFocus = false,
		ZIndex = 204,
	})

	-- Presets
	local PresetsHolder = Create("Frame", {
		Parent = ModalHolder,
		Size = UDim2.new(1, -28, 0, 24),
		Position = UDim2.new(0, 14, 0, 234),
		BackgroundTransparency = 1,
		ZIndex = 202,
	})
	Create("UIListLayout", {
		Parent = PresetsHolder,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	})

	local presets = {
		Color3.fromRGB(140, 155, 253), -- Leywin Accent
		Color3.fromRGB(186, 145, 252), -- Memory Purple
		Color3.fromRGB(88, 101, 242),  -- Discord
		Color3.fromRGB(0, 210, 255),   -- Cyan
		Color3.fromRGB(141, 209, 130), -- Green
		Color3.fromRGB(236, 88, 92),   -- Red
		Color3.fromRGB(255, 255, 255), -- White
	}

	local function UpdateColor(newColor, skipHex)
		local h, s, v = Color3.toHSV(newColor)
		currentH, currentS, currentV = h, s, v
		SVBox.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
		SVCursor.Position = UDim2.new(currentS, -5, 1 - currentV, -5)
		HueCursor.Position = UDim2.new(currentH, -3, 0.5, -9)
		SwatchPreview.BackgroundColor3 = newColor
		if not skipHex then
			HexInput.Text = ColorToHex(newColor)
		end
		pcall(callback, newColor)
	end

	for _, pCol in ipairs(presets) do
		local pBtn = Create("TextButton", {
			Parent = PresetsHolder,
			Size = UDim2.new(0, 22, 0, 22),
			BackgroundColor3 = pCol,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 203,
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pBtn })
		Create("UIStroke", { Parent = pBtn, Color = Color3.fromRGB(30, 30, 36), Thickness = 1 })
		pBtn.MouseButton1Click:Connect(function()
			UpdateColor(pCol)
		end)
	end

	local draggingSV = false
	local function ProcessSV(inputX, inputY)
		local relX = math.clamp((inputX - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
		local relY = math.clamp((inputY - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
		currentS = relX
		currentV = 1 - relY
		local col = Color3.fromHSV(currentH, currentS, currentV)
		UpdateColor(col)
	end

	SVBox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSV = true
			MemoryUI.IsModalInteracting = true
			ProcessSV(input.Position.X, input.Position.Y)
		end
	end)

	local draggingHue = false
	local function ProcessHue(inputX)
		local relX = math.clamp((inputX - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
		currentH = relX
		local col = Color3.fromHSV(currentH, currentS, currentV)
		UpdateColor(col)
	end

	HueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingHue = true
			MemoryUI.IsModalInteracting = true
			ProcessHue(input.Position.X)
		end
	end)

	local moveConn = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if draggingSV then
				ProcessSV(input.Position.X, input.Position.Y)
			elseif draggingHue then
				ProcessHue(input.Position.X)
			end
		end
	end)
	table.insert(MemoryUI.Connections, moveConn)

	local endConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSV = false
			draggingHue = false
			task.delay(0.05, function()
				if not draggingSV and not draggingHue and not draggingModal then
					MemoryUI.IsModalInteracting = false
				end
			end)
		end
	end)
	table.insert(MemoryUI.Connections, endConn)

	HexInput.Focused:Connect(function()
		Tween(HexStroke, TweenInfo.new(0.2), { Color = Theme.Accent })
	end)
	HexInput.FocusLost:Connect(function()
		Tween(HexStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(25, 25, 30) })
		local parsed = HexToColor(HexInput.Text)
		if parsed then
			UpdateColor(parsed, true)
		else
			HexInput.Text = ColorToHex(Color3.fromHSV(currentH, currentS, currentV))
		end
	end)

	-- Make Modal Draggable
	local dragStart, startPos
	local draggingModal = false
	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingModal = true
			MemoryUI.IsModalInteracting = true
			dragStart = input.Position
			startPos = ModalHolder.Position
		end
	end)
	local modalMoveConn = UserInputService.InputChanged:Connect(function(input)
		if draggingModal and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			ModalHolder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	local modalEndConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingModal = false
			task.delay(0.05, function()
				if not draggingSV and not draggingHue and not draggingModal then
					MemoryUI.IsModalInteracting = false
				end
			end)
		end
	end)
	table.insert(MemoryUI.Connections, modalMoveConn)
	table.insert(MemoryUI.Connections, modalEndConn)
	local modalEndConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingModal = false
		end
	end)
	table.insert(MemoryUI.Connections, modalMoveConn)
	table.insert(MemoryUI.Connections, modalEndConn)

	return ModalHolder
end

-- ========================================================================
-- Window Constructor
-- ========================================================================
function MemoryUI:CreateWindow(config)
	config = config or {}
	local title = config.Title or "NVL-Win.lua"
	local subTitle = config.SubTitle or "Roblox"
	local winSize = config.Size or UDim2.new(0, 868, 0, 681)
	local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
	local loginRequired = (config.LoginRequired == true)

	if MemoryUI.ScreenGui then
		pcall(function() MemoryUI.ScreenGui:Destroy() end)
		for _, conn in ipairs(MemoryUI.Connections) do
			pcall(function() conn:Disconnect() end)
		end
		MemoryUI.Connections = {}
	end

	pcall(function()
		local old1 = CoreGui:FindFirstChild("NVL_Memory_UI")
		if old1 then old1:Destroy() end
		local rbxGui = CoreGui:FindFirstChild("RobloxGui")
		if rbxGui then
			local old2 = rbxGui:FindFirstChild("NVL_Memory_UI")
			if old2 then old2:Destroy() end
		end
	end)

	local ScreenGui = Create("ScreenGui", {
		Name = "NVL_Memory_UI",
		Parent = CoreGui,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	MemoryUI.ScreenGui = ScreenGui

	-- Particle Layer for Snow Flakes and Glows
	local ParticleLayer = Create("Frame", {
		Name = "ParticleLayer",
		Parent = ScreenGui,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 90,
	})

	-- Main Window Frame
	local MainFrame = Create("Frame", {
		Name = "MainFrame",
		Parent = ScreenGui,
		Size = winSize,
		Position = UDim2.new(0.5, -winSize.X.Offset / 2, 0.5, -winSize.Y.Offset / 2),
		BackgroundColor3 = Theme.FrameBg,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Visible = not loginRequired,
		ZIndex = 2,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = MainFrame })
	local MainStroke = Create("UIStroke", {
		Parent = MainFrame,
		Color = Theme.BorderOuter,
		Thickness = 1,
	})

	local function EnableDragging(dragHandle, targetFrame)
		local dragging, dragStart, startPos
		dragHandle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = targetFrame.Position
				local upConn
				upConn = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						if upConn then upConn:Disconnect() end
					end
				end)
			end
		end)
		local moveConn = UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStart
				targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
		table.insert(MemoryUI.Connections, moveConn)
	end

	local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == toggleKey then
			MemoryUI.IsOpen = not MemoryUI.IsOpen
			MainFrame.Visible = MemoryUI.IsOpen and MemoryUI.IsAuthenticated
		end
	end)
	table.insert(MemoryUI.Connections, keyConn)

	-- ====================================================================
	-- SIDEBAR (~185px)
	-- ====================================================================
	local sidebarWidth = 185
	local Sidebar = Create("Frame", {
		Name = "Sidebar",
		Parent = MainFrame,
		Size = UDim2.new(0, sidebarWidth, 1, 0),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Sidebar })

	Create("Frame", {
		Name = "Straightener",
		Parent = Sidebar,
		Size = UDim2.new(0, 10, 1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	Create("Frame", {
		Name = "Divider",
		Parent = Sidebar,
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = Color3.fromRGB(19, 20, 22),
		BorderSizePixel = 0,
		ZIndex = 4,
	})

	local SidebarDragZone = Create("Frame", {
		Name = "SidebarDragZone",
		Parent = Sidebar,
		Size = UDim2.new(1, 0, 0, 68),
		BackgroundTransparency = 1,
		ZIndex = 10,
	})
	EnableDragging(SidebarDragZone, MainFrame)

	-- ====================================================================
	-- BRANDING HEADER (Crown Logo + Memory / Roblox)
	-- ====================================================================
	local BrandHeader = Create("Frame", {
		Name = "BrandHeader",
		Parent = Sidebar,
		Size = UDim2.new(1, 0, 0, 68),
		BackgroundTransparency = 1,
		ZIndex = 4,
	})

	local crownAsset = Assets['sidebar_crown_logo'] or Assets['CrownLogo'] or ""
	if crownAsset == "" and getcustomasset and isfile and isfile("uisimbl/assets/sidebar_crown_logo.png") then
		crownAsset = getcustomasset("uisimbl/assets/sidebar_crown_logo.png")
	end

	local CrownLogo = Create("ImageLabel", {
		Name = "CrownLogo",
		Parent = BrandHeader,
		Size = UDim2.new(0, 28, 0, 24),
		Position = UDim2.new(0, 16, 0.5, -12),
		BackgroundTransparency = 1,
		Image = crownAsset,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 5,
	})

	local TitleLabel = Create("TextLabel", {
		Name = "Title",
		Parent = BrandHeader,
		Size = UDim2.new(1, -60, 0, 18),
		Position = UDim2.new(0, 52, 0.5, -15),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.TextBright,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
	})

	local resolvedPlaceName = subTitle
	if not resolvedPlaceName or resolvedPlaceName == "Roblox" or resolvedPlaceName == "" then
		local s, info = pcall(function()
			return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
		end)
		if s and info and info.Name and info.Name ~= "" then
			resolvedPlaceName = info.Name
		elseif game.Name and game.Name ~= "" and game.Name ~= "Game" then
			resolvedPlaceName = game.Name
		else
			resolvedPlaceName = "Universal"
		end
	end

	local SubtitleLabel = Create("TextLabel", {
		Name = "SubTitle",
		Parent = BrandHeader,
		Size = UDim2.new(1, -58, 0, 14),
		Position = UDim2.new(0, 52, 0.5, 3),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = resolvedPlaceName,
		TextColor3 = Color3.fromRGB(110, 110, 118),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
	})

	-- Nav Holder
	local NavHolder = Create("ScrollingFrame", {
		Name = "NavHolder",
		Parent = Sidebar,
		Size = UDim2.new(1, 0, 1, -125),
		Position = UDim2.new(0, 0, 0, 75),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 4,
	})
	Create("UIListLayout", {
		Parent = NavHolder,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	})
	Create("UIPadding", {
		Parent = NavHolder,
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 6),
	})

	-- Footer Profile / Discord Sync
	local Footer = Create("Frame", {
		Name = "Footer",
		Parent = Sidebar,
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 1, -50),
		BackgroundTransparency = 1,
		ZIndex = 4,
	})
	Create("Frame", {
		Name = "Divider",
		Parent = Footer,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(19, 20, 22),
		BorderSizePixel = 0,
	})

	local DiscordBtn = Create("TextButton", {
		Name = "DiscordBtn",
		Parent = Footer,
		Size = UDim2.new(0, 26, 0, 26),
		Position = UDim2.new(0, 14, 0.5, -13),
		BackgroundColor3 = Theme.Discord,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ClipsDescendants = true,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = DiscordBtn })

	local DiscordDefaultLogo = Create("ImageLabel", {
		Name = "DefaultLogo",
		Parent = DiscordBtn,
		Size = UDim2.new(0, 15, 0, 15),
		Position = UDim2.new(0.5, -7.5, 0.5, -7.5),
		BackgroundTransparency = 1,
		Image = Assets.Icons.baseline_discord or "",
		ImageColor3 = Theme.TextWhite,
		ScaleType = Enum.ScaleType.Fit,
	})

	local UserNameLabel = Create("TextLabel", {
		Name = "UserName",
		Parent = Footer,
		Size = UDim2.new(0, sidebarWidth - 85, 0, 14),
		Position = UDim2.new(0, 48, 0.5, -14),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = LocalPlayer and LocalPlayer.Name or "Username",
		TextColor3 = Color3.fromRGB(224, 224, 228),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local UserStatusLabel = Create("TextLabel", {
		Name = "UserStatus",
		Parent = Footer,
		Size = UDim2.new(0, sidebarWidth - 85, 0, 12),
		Position = UDim2.new(0, 48, 0.5, 2),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "Lifetime",
		TextColor3 = Color3.fromRGB(90, 90, 98),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- Discord Lookup Connection
	task.spawn(function()
		local LRM_LinkedDiscordID = getgenv().LRM_LinkedDiscordID or "1011263551387746405"
		if not safeRequest then return end

		local s, data = pcall(function()
			local body = safeRequest({
				Url = "https://discord-lookup-api-pied.vercel.app/v1/user/" .. tostring(LRM_LinkedDiscordID),
				Method = "GET",
				Headers = {
					["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
					["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
				}
			})
			if body and (body.StatusCode == 200 or body.Status == 200) then
				return HttpService:JSONDecode(body.Body or body.body)
			end
		end)

		if s and type(data) == "table" and data.username then
			UserNameLabel.Text = "@" .. data.username
			if data.avatar and data.avatar.link then
				pcall(function()
					local imgBody = safeRequest({
						Url = data.avatar.link,
						Method = "GET"
					})
					if imgBody and (imgBody.Body or imgBody.body) and writefile and getcustomasset then
						local avatarFileName = "uisimbl/assets/discord_avatar_" .. tostring(LRM_LinkedDiscordID) .. ".png"
						writefile(avatarFileName, imgBody.Body or imgBody.body)
						local customUri = getcustomasset(avatarFileName)

						local avatarImg = Create("ImageLabel", {
							Name = "AvatarImage",
							Parent = DiscordBtn,
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
							Image = customUri,
							ScaleType = Enum.ScaleType.Crop,
							ZIndex = 4,
						})
						Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = avatarImg })
						DiscordDefaultLogo.Visible = false
					end
				end)
			end
		end
	end)

	-- ====================================================================
	-- TOP BAR (Sub-Tabs: Thread, Enemy, Other, Team + Search Box)
	-- ====================================================================
	local TopBar = Create("Frame", {
		Name = "TopBar",
		Parent = MainFrame,
		Size = UDim2.new(1, -sidebarWidth, 0, 48),
		Position = UDim2.new(0, sidebarWidth, 0, 0),
		BackgroundColor3 = Theme.Header,
		BorderSizePixel = 0,
		ZIndex = 4,
	})
	Create("Frame", {
		Name = "Divider",
		Parent = TopBar,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = Color3.fromRGB(19, 20, 22),
		BorderSizePixel = 0,
	})
	EnableDragging(TopBar, MainFrame)

	-- Sub-Tabs Holder (Thread, Enemy, Other, Team)
	local SubTabsHolder = Create("Frame", {
		Name = "SubTabsHolder",
		Parent = TopBar,
		Size = UDim2.new(1, -210, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
	})
	Create("UIListLayout", {
		Parent = SubTabsHolder,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 16),
	})

	-- Search Box in TopBar
	local SearchBoxContainer = Create("Frame", {
		Name = "SearchBoxContainer",
		Parent = TopBar,
		Size = UDim2.new(0, 150, 0, 26),
		Position = UDim2.new(1, -166, 0.5, -13),
		BackgroundColor3 = Color3.fromRGB(13, 13, 15),
		BorderSizePixel = 0,
		ZIndex = 5,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SearchBoxContainer })
	local SearchStroke = Create("UIStroke", { Parent = SearchBoxContainer, Color = Color3.fromRGB(22, 22, 26), Thickness = 1 })

	Create("ImageLabel", {
		Parent = SearchBoxContainer,
		Size = UDim2.new(0, 13, 0, 13),
		Position = UDim2.new(0, 8, 0.5, -6.5),
		BackgroundTransparency = 1,
		Image = Assets.Icons.search or "",
		ImageColor3 = Color3.fromRGB(146, 146, 155),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 6,
	})

	local SearchTextBox = Create("TextBox", {
		Name = "SearchTextBox",
		Parent = SearchBoxContainer,
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.new(0, 26, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		PlaceholderText = "Search...",
		PlaceholderColor3 = Color3.fromRGB(80, 80, 88),
		Text = "",
		TextColor3 = Theme.TextBright,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 6,
	})

	SearchTextBox.Focused:Connect(function()
		Tween(SearchStroke, TweenInfo.new(0.2), { Color = Theme.Accent })
		Tween(SearchBoxContainer, TweenInfo.new(0.2), { Size = UDim2.new(0, 180, 0, 26), Position = UDim2.new(1, -196, 0.5, -13) })
	end)
	SearchTextBox.FocusLost:Connect(function()
		Tween(SearchStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(22, 22, 26) })
		if SearchTextBox.Text == "" then
			Tween(SearchBoxContainer, TweenInfo.new(0.2), { Size = UDim2.new(0, 150, 0, 26), Position = UDim2.new(1, -166, 0.5, -13) })
		end
	end)

	-- ====================================================================
	-- CONTENT CONTAINER
	-- ====================================================================
	local ContentContainer = Create("Frame", {
		Name = "ContentContainer",
		Parent = MainFrame,
		Size = UDim2.new(1, -sidebarWidth, 1, -48),
		Position = UDim2.new(0, sidebarWidth, 0, 48),
		BackgroundColor3 = Theme.Container,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})

	if Assets.InterfaceBg and Assets.InterfaceBg ~= "" then
		Create("ImageLabel", {
			Name = "SubtleBgTexture",
			Parent = ContentContainer,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Image = Assets.InterfaceBg,
			ScaleType = Enum.ScaleType.Crop,
			ImageTransparency = 0.25,
			ZIndex = 1,
		})
	end

	-- ====================================================================
	-- TAB MANAGEMENT & REAL-TIME SEARCH FILTER
	-- ====================================================================
	local Tabs = {}
	local CurrentTab = nil

	local Window = {
		MainFrame = MainFrame,
		ParticleLayer = ParticleLayer,
		Tabs = Tabs,
		CreateWatermark = function(self, cfg) return MemoryUI:CreateWatermark(cfg) end,
		CreateSpectators = function(self, cfg) return MemoryUI:CreateSpectators(cfg) end,
		CreateKeybinds = function(self, cfg) return MemoryUI:CreateKeybinds(cfg) end,
		SetKeybindsVisible = function(self, vis)
			if MemoryUI.KeybindsInstance then
				MemoryUI.KeybindsInstance:SetVisible(vis)
			end
		end,
	}

	function Window:FilterSearch(query)
		query = query:lower():gsub("^%s*(.-)%s*$", "%1")
		if not CurrentTab then return end

		for _, card in ipairs(CurrentTab.Cards) do
			local cardTitleMatch = (query == "") or (string.find(card.Title:lower(), query, 1, true) ~= nil)
			local visibleItemCount = 0

			for _, item in ipairs(card.Items) do
				local itemMatch = (query == "") or cardTitleMatch or (string.find(item.Name:lower(), query, 1, true) ~= nil)
				item.Instance.Visible = itemMatch
				if itemMatch then
					visibleItemCount += 1
				end
			end

			card.Instance.Visible = (visibleItemCount > 0)
		end
	end

	SearchTextBox:GetPropertyChangedSignal("Text"):Connect(function()
		Window:FilterSearch(SearchTextBox.Text)
	end)

	function Window:CreateCategory(categoryName: string)
		local Cat = Create("TextLabel", {
			Name = "Cat_" .. categoryName,
			Parent = NavHolder,
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = categoryName,
			TextColor3 = Theme.TextDark,
			TextSize = 9.5,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		Create("UIPadding", { Parent = Cat, PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 8) })
		return Cat
	end

	-- Tab Creator with Vertical Capsule Pill Indicator
	function Window:CreateTab(tabConfig)
		tabConfig = tabConfig or {}
		local tabName = tabConfig.Name or "Tab"
		local tabIcon = tabConfig.Icon or ""

		local TabBtn = Create("TextButton", {
			Name = "Tab_" .. tabName,
			Parent = NavHolder,
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = Color3.fromRGB(15, 16, 18),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 5,
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabBtn })

		local IconImg = Create("ImageLabel", {
			Name = "Icon",
			Parent = TabBtn,
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(0, 12, 0.5, -8),
			BackgroundTransparency = 1,
			Image = tabIcon,
			ImageColor3 = Theme.TextMuted,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 6,
		})

		local TabLabel = Create("TextLabel", {
			Name = "Label",
			Parent = TabBtn,
			Size = UDim2.new(1, -55, 1, 0),
			Position = UDim2.new(0, 38, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = tabName,
			TextColor3 = Theme.TextMuted,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
		})

		-- Active Tab Vertical Pill Indicator (as seen in LEYWIN image)
		local ActivePill = Create("Frame", {
			Name = "ActivePill",
			Parent = TabBtn,
			Size = UDim2.new(0, 3, 0, 18),
			Position = UDim2.new(1, -5, 0.5, -9),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 7,
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ActivePill })

		local TabCanvas = Create("ScrollingFrame", {
			Name = "Canvas_" .. tabName,
			Parent = ContentContainer,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.BorderPurple,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			ZIndex = 2,
		})

		local LeftCol = Create("Frame", {
			Name = "LeftColumn",
			Parent = TabCanvas,
			Size = UDim2.new(0.5, -16, 0, 0),
			Position = UDim2.new(0, 12, 0, 12),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 2,
		})
		Create("UIListLayout", {
			Parent = LeftCol,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
		})

		local RightCol = Create("Frame", {
			Name = "RightColumn",
			Parent = TabCanvas,
			Size = UDim2.new(0.5, -16, 0, 0),
			Position = UDim2.new(0.5, 4, 0, 12),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 2,
		})
		Create("UIListLayout", {
			Parent = RightCol,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
		})

		local subTabs = tabConfig.SubTabs or { "Thread", "Enemy", "Other", "Team" }
		local currentSubTab = subTabs[1] or ""

		local Tab = {
			Name = tabName,
			Icon = tabIcon,
			Button = TabBtn,
			Canvas = TabCanvas,
			LeftCol = LeftCol,
			RightCol = RightCol,
			Cards = {},
			SubTabs = subTabs,
			CurrentSubTab = currentSubTab,
		}
		table.insert(Tabs, Tab)

		local function FilterCardsBySubTab()
			local query = SearchTextBox.Text:lower():gsub("^%s*(.-)%s*$", "%1")
			for _, card in ipairs(Tab.Cards) do
				if query ~= "" then
					local match = (string.find(card.Title:lower(), query, 1, true) ~= nil)
					for _, item in ipairs(card.Items) do
						local itemMatch = match or (string.find(item.Name:lower(), query, 1, true) ~= nil)
						item.Instance.Visible = itemMatch
						if itemMatch then match = true end
					end
					card.Instance.Visible = match
				else
					for _, item in ipairs(card.Items) do item.Instance.Visible = true end
					if card.SubTab then
						card.Instance.Visible = (card.SubTab == Tab.CurrentSubTab)
					else
						card.Instance.Visible = true
					end
				end
			end
		end

		local function RenderSubTabs()
			for _, ch in ipairs(SubTabsHolder:GetChildren()) do
				if ch:IsA("TextButton") or ch:IsA("Frame") or ch:IsA("TextLabel") then
					ch:Destroy()
				end
			end

			if Tab.SubTabs and #Tab.SubTabs > 0 then
				for _, sName in ipairs(Tab.SubTabs) do
					local isAct = (sName == Tab.CurrentSubTab)
					local pBtn = Create("TextButton", {
						Name = "SubTab_" .. sName,
						Parent = SubTabsHolder,
						AutomaticSize = Enum.AutomaticSize.X,
						Size = UDim2.new(0, 0, 0, 26),
						BackgroundColor3 = isAct and Color3.fromRGB(20, 21, 26) or Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = isAct and 0 or 1,
						BorderSizePixel = 0,
						Font = Enum.Font.GothamBold,
						Text = sName,
						TextColor3 = isAct and Theme.TextBright or Color3.fromRGB(120, 120, 130),
						TextSize = 11,
						AutoButtonColor = false,
						ZIndex = 5,
					})
					Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = pBtn })
					Create("UIPadding", {
						Parent = pBtn,
						PaddingLeft = UDim.new(0, 12),
						PaddingRight = UDim.new(0, 12),
					})
					local pStroke = Create("UIStroke", {
						Parent = pBtn,
						Color = isAct and Color3.fromRGB(36, 38, 48) or Color3.fromRGB(0, 0, 0),
						Transparency = isAct and 0 or 1,
						Thickness = 1,
					})

					pBtn.MouseButton1Click:Connect(function()
						MemoryUI:CloseActiveDropdown()
						Tab.CurrentSubTab = sName
						RenderSubTabs()
						FilterCardsBySubTab()
					end)
				end
			end
			MemoryUI:CloseActiveDropdown()
			FilterCardsBySubTab()
		end

		local function SelectTab()
			MemoryUI:CloseActiveDropdown()
			if CurrentTab == Tab then return end
			local oldTab = CurrentTab
			CurrentTab = Tab

			for _, t in ipairs(Tabs) do
				if t == Tab then
					Tween(t.Button, TweenInfo.new(0.2), { BackgroundTransparency = 0 })
					Tween(t.Button.Icon, TweenInfo.new(0.2), { ImageColor3 = Theme.Accent })
					Tween(t.Button.Label, TweenInfo.new(0.2), { TextColor3 = Theme.TextBright })
					Tween(t.Button.ActivePill, TweenInfo.new(0.2), { BackgroundTransparency = 0 })
				else
					Tween(t.Button, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
					Tween(t.Button.Icon, TweenInfo.new(0.2), { ImageColor3 = Theme.TextMuted })
					Tween(t.Button.Label, TweenInfo.new(0.2), { TextColor3 = Theme.TextMuted })
					Tween(t.Button.ActivePill, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
				end
			end

			-- IMMEDIATELY hide all other tab canvases! ZERO OVERLAP!
			for _, t in ipairs(Tabs) do
				if t ~= Tab and t.Canvas then
					t.Canvas.Visible = false
				end
			end

			TabCanvas.Visible = true
			TabCanvas.Position = UDim2.new(0, 0, 0, 6)
			Tween(TabCanvas, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, 0, 0, 0)
			})

			RenderSubTabs()
			Window:FilterSearch(SearchTextBox.Text)
		end

		TabBtn.MouseButton1Click:Connect(SelectTab)
		TabBtn.MouseEnter:Connect(function()
			if CurrentTab ~= Tab then
				Tween(TabBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.5 })
			end
		end)
		TabBtn.MouseLeave:Connect(function()
			if CurrentTab ~= Tab then
				Tween(TabBtn, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
			end
		end)

		if #Tabs == 1 then
			task.spawn(function()
				task.wait(0.05)
				SelectTab()
			end)
		end

		-- Card Creator
		function Tab:CreateCard(cardConfig)
			cardConfig = cardConfig or {}
			local cardTitle = cardConfig.Title or "Card"
			local cardSide = cardConfig.Side or "left"
			local cardIcon = cardConfig.Icon or ""

			local parentCol = (cardSide == "right") and RightCol or LeftCol

			local CardFrame = Create("Frame", {
				Name = "Card_" .. cardTitle,
				Parent = parentCol,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Card,
				BorderSizePixel = 0,
				ZIndex = 2,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CardFrame })
			Create("UIStroke", { Parent = CardFrame, Color = Theme.CardStroke, Thickness = 1 })

			local CardHeader = Create("Frame", {
				Name = "Header",
				Parent = CardFrame,
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundTransparency = 1,
				ZIndex = 3,
			})

			if cardIcon and cardIcon ~= "" then
				Create("ImageLabel", {
					Parent = CardHeader,
					Size = UDim2.new(0, 14, 0, 14),
					Position = UDim2.new(0, 12, 0.5, -7),
					BackgroundTransparency = 1,
					Image = cardIcon,
					ImageColor3 = Theme.Accent,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 4,
				})
			end

			Create("TextLabel", {
				Parent = CardHeader,
				Size = UDim2.new(1, -40, 1, 0),
				Position = UDim2.new(0, (cardIcon and cardIcon ~= "") and 34 or 12, 0, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = cardTitle,
				TextColor3 = Theme.TextBright,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 4,
			})

			-- Grid dots icon on right of card header (matching LEYWIN)
			Create("ImageLabel", {
				Parent = CardHeader,
				Size = UDim2.new(0, 12, 0, 12),
				Position = UDim2.new(1, -22, 0.5, -6),
				BackgroundTransparency = 1,
				Image = Assets.Icons.dots_2 or "",
				ImageColor3 = Color3.fromRGB(60, 65, 75),
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 4,
			})

			Create("Frame", {
				Name = "Divider",
				Parent = CardFrame,
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 0, 34),
				BackgroundColor3 = Theme.CardDivider,
				BorderSizePixel = 0,
				ZIndex = 3,
			})

			local ItemsContainer = Create("Frame", {
				Name = "Items",
				Parent = CardFrame,
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 35),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				ZIndex = 3,
			})
			Create("UIListLayout", {
				Parent = ItemsContainer,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			})
			Create("UIPadding", {
				Parent = ItemsContainer,
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 8),
			})

			local Card = {
				Title = cardTitle,
				Instance = CardFrame,
				Items = {},
				SubTab = cardConfig.SubTab,
			}
			table.insert(Tab.Cards, Card)
			if cardConfig.SubTab and cardConfig.SubTab ~= Tab.CurrentSubTab then
				CardFrame.Visible = false
			end

			-- ============================================================
			-- 1. Toggle Switch (with Gear Button ⚙ Sub-Settings support)
			-- ============================================================
			function Card:CreateToggle(toggleConfig)
				toggleConfig = toggleConfig or {}
				local toggleName = toggleConfig.Name or "Toggle"
				local defaultState = toggleConfig.Default or false
				local callback = toggleConfig.Callback or function() end
				local hasColorBadge = toggleConfig.ColorBadge or false
				local colorVal = toggleConfig.ColorValue or Theme.Accent
				local hasSettings = (toggleConfig.HasSettings or toggleConfig.Settings ~= nil)

				local currentState = defaultState
				local currentKey = toggleConfig.Keybind
				local currentMode = toggleConfig.Mode or "Toggle"
				local showInBinds = toggleConfig.ShowInBinds or false

				local function UpdateBindRegistry()
					if currentKey and showInBinds then
						MemoryUI:RegisterKeybind({
							Name = toggleName,
							Key = currentKey,
							Mode = currentMode,
							ShowInBinds = showInBinds,
							IsActive = function() return currentState end,
						})
					else
						MemoryUI:UnregisterKeybind(toggleName)
					end
				end
				UpdateBindRegistry()

				local Row = Create("Frame", {
					Name = "Toggle_" .. toggleName,
					Parent = ItemsContainer,
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundTransparency = 1,
					ZIndex = 3,
				})
				table.insert(Card.Items, { Name = toggleName, Instance = Row })

				Create("TextLabel", {
					Parent = Row,
					Size = UDim2.new(1, -95, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = toggleName,
					TextColor3 = currentState and Theme.TextBright or Theme.TextMuted,
					TextSize = 11.5,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 4,
				})

				-- Sub-Settings Gear Button (⚙)
				if hasSettings then
					local GearBtn = Create("ImageButton", {
						Name = "GearButton",
						Parent = Row,
						Size = UDim2.new(0, 14, 0, 14),
						Position = UDim2.new(1, -56, 0.5, -7),
						BackgroundTransparency = 1,
						Image = Assets.Icons.gear or "",
						ImageColor3 = Color3.fromRGB(110, 115, 130),
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 5,
					})

					GearBtn.MouseEnter:Connect(function()
						Tween(GearBtn, TweenInfo.new(0.2), { ImageColor3 = Theme.Accent, Rotation = 30 })
					end)
					GearBtn.MouseLeave:Connect(function()
						Tween(GearBtn, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(110, 115, 130), Rotation = 0 })
					end)

					GearBtn.MouseButton1Click:Connect(function()
						local abs = GearBtn.AbsolutePosition
						MemoryUI:OpenSubSettings({
							Owner = GearBtn,
							Title = toggleName .. " Settings",
							Position = UDim2.new(0, math.clamp(abs.X - 190, 20, 1200), 0, math.clamp(abs.Y + 20, 20, 800)),
							Keybind = currentKey or Enum.KeyCode.F,
							Mode = currentMode,
							ShowInBinds = showInBinds,
							Callback = function(settingsData)
								if settingsData.Key ~= nil then currentKey = settingsData.Key end
								if settingsData.Mode ~= nil then currentMode = settingsData.Mode end
								if settingsData.ShowInBinds ~= nil then showInBinds = settingsData.ShowInBinds end
								UpdateBindRegistry()
								if toggleConfig.OnSettings then
									pcall(toggleConfig.OnSettings, settingsData)
								end
							end,
						})
					end)
				end

				-- Color Badge
				if hasColorBadge then
					local Badge = Create("TextButton", {
						Name = "ColorBadge",
						Parent = Row,
						Size = UDim2.new(0, 18, 0, 10),
						Position = UDim2.new(1, hasSettings and -78 or -56, 0.5, -5),
						BackgroundColor3 = colorVal,
						BorderSizePixel = 0,
						Text = "",
						AutoButtonColor = false,
						ZIndex = 5,
					})
					Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Badge })

					Badge.MouseButton1Click:Connect(function()
						local abs = Badge.AbsolutePosition
						MemoryUI:OpenColorPicker({
							Title = toggleName .. " Color",
							Color = colorVal,
							Position = UDim2.new(0, math.clamp(abs.X - 270, 20, 1200), 0, math.clamp(abs.Y - 50, 20, 800)),
							Callback = function(newCol)
								colorVal = newCol
								Badge.BackgroundColor3 = newCol
								if toggleConfig.ColorCallback then
									pcall(toggleConfig.ColorCallback, newCol)
								end
							end
						})
					end)
				end

				-- Pill Switch or Square Checkbox (matching Leywin/Figma)
				local Pill = Create("TextButton", {
					Name = "Pill",
					Parent = Row,
					Size = UDim2.new(0, 30, 0, 18),
					Position = UDim2.new(1, -38, 0.5, -9),
					BackgroundColor3 = currentState and Theme.Accent or Color3.fromRGB(16, 17, 20),
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 4,
				})
				Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Pill })
				local PillStroke = Create("UIStroke", {
					Parent = Pill,
					Color = currentState and Theme.Accent or Color3.fromRGB(24, 26, 32),
					Thickness = 1,
				})

				local Knob = Create("Frame", {
					Name = "Knob",
					Parent = Pill,
					Size = UDim2.new(0, 12, 0, 12),
					Position = currentState and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
					BackgroundColor3 = Theme.TextWhite,
					BorderSizePixel = 0,
					ZIndex = 5,
				})
				Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })

				local function SetState(state: boolean)
					currentState = state
					local rowText = Row:FindFirstChildOfClass("TextLabel")
					if rowText then
						rowText.TextColor3 = currentState and Theme.TextBright or Theme.TextMuted
					end

					if currentState then
						Tween(Pill, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Accent })
						Tween(PillStroke, TweenInfo.new(0.2), { Color = Theme.Accent })
						Tween(Knob, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
							Position = UDim2.new(1, -15, 0.5, -6)
						})
					else
						Tween(Pill, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(16, 17, 20) })
						Tween(PillStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(24, 26, 32) })
						Tween(Knob, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
							Position = UDim2.new(0, 3, 0.5, -6)
						})
					end
					pcall(callback, currentState)
					if MemoryUI.KeybindsInstance then
						MemoryUI.KeybindsInstance:Refresh()
					end
				end

				Pill.MouseButton1Click:Connect(function() SetState(not currentState) end)

				-- Active Keybind Listener (Toggle / Hold / Always modes)
				local keyConnBegan = UserInputService.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					if UserInputService:GetFocusedTextBox() then return end
					if currentKey and input.KeyCode == currentKey then
						if currentMode == "Toggle" then
							SetState(not currentState)
						elseif currentMode == "Hold" then
							SetState(true)
						elseif currentMode == "Always" then
							SetState(true)
						end
					end
				end)
				table.insert(MemoryUI.Connections, keyConnBegan)

				local keyConnEnded = UserInputService.InputEnded:Connect(function(input)
					if UserInputService:GetFocusedTextBox() then return end
					if currentKey and input.KeyCode == currentKey then
						if currentMode == "Hold" then
							SetState(false)
						end
					end
				end)
				table.insert(MemoryUI.Connections, keyConnEnded)

				local toggleObj = {
					Set = function(v, extra)
						local val = (extra ~= nil and extra) or v
						SetState(val == true)
					end,
					Get = function() return currentState end,
					SetKeybind = function(a, b, c, d)
						local key = (typeof(a) == "table" and b) or a
						local mode = (typeof(a) == "table" and c) or b
						local inBinds = (typeof(a) == "table" and d) or c
						if key then currentKey = key end
						if mode then currentMode = mode end
						if inBinds ~= nil then showInBinds = inBinds end
					end,
					GetKeybind = function()
						return { Key = currentKey, Mode = currentMode, ShowInBinds = showInBinds }
					end,
				}

				local flagKey = toggleConfig.Flag or toggleName
				MemoryUI.Flags[flagKey] = {
					Type = "Toggle",
					Get = toggleObj.Get,
					Set = toggleObj.Set,
					GetKeybind = toggleObj.GetKeybind,
					SetKeybind = toggleObj.SetKeybind,
				}

				return toggleObj
			end

			-- ============================================================
			-- 2. Slider (Enlarged 32px Hitbox + Hover/Drag Circle Animation + Snow + Editable Input)
			-- ============================================================
			function Card:CreateSlider(sliderConfig)
				sliderConfig = sliderConfig or {}
				local sliderName = sliderConfig.Name or "Slider"
				local minVal = sliderConfig.Min or 0
				local maxVal = sliderConfig.Max or 100
				local defaultVal = sliderConfig.Default or minVal
				local decimals = math.clamp(math.floor(tonumber(sliderConfig.Decimals) or 1), 0, 4)
				local callback = sliderConfig.Callback or function() end

				local currentValue = math.clamp(defaultVal, minVal, maxVal)
				local originalVal = defaultVal

				local Row = Create("Frame", {
					Name = "Slider_" .. sliderName,
					Parent = ItemsContainer,
					Size = UDim2.new(1, 0, 0, 42),
					BackgroundTransparency = 1,
					ZIndex = 3,
				})
				table.insert(Card.Items, { Name = sliderName, Instance = Row })

				Create("TextLabel", {
					Parent = Row,
					Size = UDim2.new(0, 85, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = sliderName,
					TextColor3 = Theme.TextBright,
					TextSize = 11.5,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 4,
				})

				-- Enlarged Hitbox (Height 32px) for effortless mouse dragging
				local SliderHitbox = Create("TextButton", {
					Name = "SliderHitbox",
					Parent = Row,
					Size = UDim2.new(1, -192, 0, 32),
					Position = UDim2.new(0, 95, 0.5, -16),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 8,
				})

				-- Visual Track Bar (Centered inside Hitbox)
				local Track = Create("Frame", {
					Name = "Track",
					Parent = SliderHitbox,
					Size = UDim2.new(1, 0, 0, 4),
					Position = UDim2.new(0, 0, 0.5, -2),
					BackgroundColor3 = Color3.fromRGB(27, 29, 34),
					BorderSizePixel = 0,
					ZIndex = 4,
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = Track })

				local pct = (currentValue - minVal) / (maxVal - minVal)
				local Fill = Create("Frame", {
					Name = "Fill",
					Parent = Track,
					Size = UDim2.new(pct, 0, 1, 0),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					ZIndex = 4,
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = Fill })

				-- Slider Thumb Point
				local Thumb = Create("Frame", {
					Name = "Thumb",
					Parent = Track,
					Size = UDim2.new(0, 8, 0, 8),
					Position = UDim2.new(pct, -4, 0.5, -4),
					BackgroundColor3 = Theme.TextWhite,
					BorderSizePixel = 0,
					ZIndex = 6,
				})
				Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Thumb })

				-- Hover / Drag Indicator Circle Ring with Smooth Scale Animation
				local HoverRing = Create("Frame", {
					Name = "HoverRing",
					Parent = Thumb,
					Size = UDim2.new(0, 0, 0, 0),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					BackgroundColor3 = Theme.Accent,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 5,
				})
				Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = HoverRing })
				local RingStroke = Create("UIStroke", {
					Parent = HoverRing,
					Color = Theme.AccentLight,
					Thickness = 2,
					Transparency = 1,
				})

				-- Editable Number Value Box on Right
				local ValueBox = Create("Frame", {
					Parent = Row,
					Size = UDim2.new(0, 52, 0, 24),
					Position = UDim2.new(1, -88, 0.5, -12),
					BackgroundColor3 = Color3.fromRGB(14, 15, 17),
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 4,
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ValueBox })
				local ValueBoxStroke = Create("UIStroke", { Parent = ValueBox, Color = Color3.fromRGB(20, 23, 28), Thickness = 1 })

				local ValueInput = Create("TextBox", {
					Parent = ValueBox,
					Size = UDim2.new(1, -4, 1, 0),
					Position = UDim2.new(0, 2, 0, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = string.format("%." .. decimals .. "f", currentValue),
					TextColor3 = Color3.fromRGB(208, 208, 212),
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Center,
					ClearTextOnFocus = false,
					ClipsDescendants = true,
					ZIndex = 5,
				})

				ValueInput.Focused:Connect(function()
					Tween(ValueBoxStroke, TweenInfo.new(0.18), { Color = Theme.Accent })
				end)

				-- Reset Button: Crisp vector reload icon (Lucide rotate-ccw fallback, clean hover & spin)
				local ResetBtn = Create("ImageButton", {
					Name = "ResetBtn",
					Parent = Row,
					Size = UDim2.new(0, 22, 0, 22),
					Position = UDim2.new(1, -30, 0.5, -11),
					BackgroundColor3 = Color3.fromRGB(20, 22, 28),
					BackgroundTransparency = 0.5,
					BorderSizePixel = 0,
					Image = "",
					AutoButtonColor = false,
					ZIndex = 6,
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ResetBtn })
				local ResetStroke = Create("UIStroke", {
					Parent = ResetBtn,
					Color = Color3.fromRGB(36, 40, 52),
					Thickness = 1,
					Transparency = 0.3,
				})
				local resetAsset = (Assets.Icons and Assets.Icons.reset) or ""
				if (not resetAsset or resetAsset == "") and _G.MemoryAssets and _G.MemoryAssets.Icons and _G.MemoryAssets.Icons.reset then
					resetAsset = _G.MemoryAssets.Icons.reset
				end
				if (not resetAsset or resetAsset == "") and getcustomasset and isfile then
					if isfile("uisimbl/assets/icons/reset.png") then
						resetAsset = getcustomasset("uisimbl/assets/icons/reset.png")
					elseif isfile("reset.png") then
						resetAsset = getcustomasset("reset.png")
					end
				end
				if not resetAsset or resetAsset == "" then
					resetAsset = "rbxassetid://10734941499"
				end

				local ResetIcon = Create("ImageLabel", {
					Name = "Icon",
					Parent = ResetBtn,
					Size = UDim2.new(0, 13, 0, 13),
					Position = UDim2.new(0.5, -6, 0.5, -6),
					BackgroundTransparency = 1,
					Image = resetAsset,
					ImageColor3 = Color3.fromRGB(200, 205, 225),
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 7,
				})

				ResetBtn.MouseEnter:Connect(function()
					Tween(ResetBtn, TweenInfo.new(0.18), { BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(30, 34, 46) })
					Tween(ResetStroke, TweenInfo.new(0.18), { Transparency = 0, Color = Theme.Accent })
					Tween(ResetIcon, TweenInfo.new(0.18), { ImageColor3 = Theme.AccentLight or Color3.fromRGB(225, 205, 255) })
				end)

				ResetBtn.MouseLeave:Connect(function()
					Tween(ResetBtn, TweenInfo.new(0.18), { BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(20, 22, 28) })
					Tween(ResetStroke, TweenInfo.new(0.18), { Transparency = 0.3, Color = Color3.fromRGB(36, 40, 52) })
					Tween(ResetIcon, TweenInfo.new(0.18), { ImageColor3 = Color3.fromRGB(200, 205, 225) })
				end)

				-- Snow Particle Effect
				local lastFlakeTime = 0
				local function SpawnSnowFlake(pos)
					local now = tick()
					if now - lastFlakeTime < 0.04 then return end
					lastFlakeTime = now

					local flakeSize = math.random(3, 5)
					local flake = Create("Frame", {
						Name = "SnowFlake",
						Parent = ParticleLayer,
						Size = UDim2.new(0, flakeSize, 0, flakeSize),
						Position = UDim2.new(0, pos.X + math.random(-4, 4), 0, pos.Y + math.random(-4, 4)),
						BackgroundColor3 = (math.random() > 0.4) and Color3.fromRGB(245, 245, 255) or Theme.AccentLight,
						BackgroundTransparency = 0.2,
						BorderSizePixel = 0,
						ZIndex = 95,
					})
					Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = flake })

					local driftX = math.random(-16, 16)
					local fallY = math.random(18, 38)
					local dur = 0.5 + math.random() * 0.35

					Tween(flake, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = UDim2.new(0, pos.X + driftX, 0, pos.Y + fallY),
						BackgroundTransparency = 1,
						Size = UDim2.new(0, flakeSize - 1, 0, flakeSize - 1),
					})
					task.delay(dur, function()
						pcall(function() flake:Destroy() end)
					end)
				end

				-- Hover & Drag Circle Animation Controller
				local isHovered = false
				local isDragging = false

				local function ShowRing()
					Tween(HoverRing, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, 18, 0, 18),
						Position = UDim2.new(0.5, -9, 0.5, -9),
						BackgroundTransparency = 0.65,
					})
					Tween(RingStroke, TweenInfo.new(0.2), { Transparency = 0 })
				end

				local function HideRing()
					Tween(HoverRing, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Size = UDim2.new(0, 0, 0, 0),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						BackgroundTransparency = 1,
					})
					Tween(RingStroke, TweenInfo.new(0.2), { Transparency = 1 })
				end

				SliderHitbox.MouseEnter:Connect(function()
					isHovered = true
					ShowRing()
				end)

				SliderHitbox.MouseLeave:Connect(function()
					isHovered = false
					if not isDragging then
						HideRing()
					end
				end)

				local function UpdateSlider(inputX, fromInput)
					if not fromInput then
						local absPos = Track.AbsolutePosition.X
						local absSize = Track.AbsoluteSize.X
						local rel = math.clamp((inputX - absPos) / absSize, 0, 1)
						currentValue = minVal + (maxVal - minVal) * rel
						ValueInput.Text = string.format("%." .. decimals .. "f", currentValue)
					end

					local r = math.clamp((currentValue - minVal) / (maxVal - minVal), 0, 1)
					Fill.Size = UDim2.new(r, 0, 1, 0)
					Thumb.Position = UDim2.new(r, -4, 0.5, -4)

					if isDragging then
						SpawnSnowFlake(Vector2.new(Thumb.AbsolutePosition.X + 4, Thumb.AbsolutePosition.Y + 4))
					end
					pcall(callback, currentValue)
				end

				local isResetting = false
				ResetBtn.MouseButton1Click:Connect(function()
					if isResetting then return end
					isResetting = true

					-- 360-degree smooth spin animation of the icon and crisp green flash
					ResetIcon.Rotation = 0
					Tween(ResetIcon, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Rotation = -360, ImageColor3 = Color3.fromRGB(80, 220, 120) })
					Tween(ResetBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(20, 42, 28) })
					Tween(ResetStroke, TweenInfo.new(0.15), { Transparency = 0, Color = Color3.fromRGB(80, 220, 120) })

					currentValue = originalVal
					ValueInput.Text = string.format("%." .. decimals .. "f", currentValue)
					UpdateSlider(0, true)

					task.delay(0.36, function()
						ResetIcon.Rotation = 0
						Tween(ResetBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(20, 22, 28) })
						Tween(ResetStroke, TweenInfo.new(0.2), { Transparency = 0.3, Color = Color3.fromRGB(36, 40, 52) })
						Tween(ResetIcon, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(200, 205, 225) })
						isResetting = false
					end)
				end)

				ValueInput.FocusLost:Connect(function()
					Tween(ValueBoxStroke, TweenInfo.new(0.18), { Color = Color3.fromRGB(20, 23, 28) })
					local num = tonumber(ValueInput.Text)
					if num then
						currentValue = math.clamp(num, minVal, maxVal)
						ValueInput.Text = string.format("%." .. decimals .. "f", currentValue)
						UpdateSlider(0, true)
					else
						ValueInput.Text = string.format("%." .. decimals .. "f", currentValue)
					end
				end)

				SliderHitbox.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						isDragging = true
						ShowRing()
						UpdateSlider(input.Position.X, false)
					end
				end)

				local slideConn = UserInputService.InputChanged:Connect(function(input)
					if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						UpdateSlider(input.Position.X, false)
					end
				end)
				table.insert(MemoryUI.Connections, slideConn)

				local endConn = UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
						isDragging = false
						if not isHovered then
							HideRing()
						end
					end
				end)
				table.insert(MemoryUI.Connections, endConn)

				local sliderObj = {
					Set = function(v, extra)
						local val = (extra ~= nil and extra) or v
						currentValue = math.clamp(tonumber(val) or defaultVal, minVal, maxVal)
						ValueInput.Text = string.format("%." .. decimals .. "f", currentValue)
						UpdateSlider(0, true)
					end,
					Get = function() return currentValue end,
					Reset = function()
						currentValue = originalVal
						ValueInput.Text = string.format("%." .. decimals .. "f", currentValue)
						UpdateSlider(0, true)
					end,
				}

				local flagKey = sliderConfig.Flag or sliderName
				MemoryUI.Flags[flagKey] = {
					Type = "Slider",
					Get = sliderObj.Get,
					Set = sliderObj.Set,
					Reset = sliderObj.Reset,
				}

				return sliderObj
			end

			-- ============================================================
			-- 3. Dropdown Menu
			-- ============================================================
			function Card:CreateDropdown(dropdownConfig)
				dropdownConfig = dropdownConfig or {}
				local dropName = dropdownConfig.Name or "Dropdown"
				local options = dropdownConfig.Options or {}
				local defaultOpt = dropdownConfig.Default or options[1] or ""
				local callback = dropdownConfig.Callback or function() end

				local selected = defaultOpt
				local isOpen = false

				local Row = Create("Frame", {
					Name = "Dropdown_" .. dropName,
					Parent = ItemsContainer,
					Size = UDim2.new(1, 0, 0, 42),
					BackgroundTransparency = 1,
					ClipsDescendants = false,
					ZIndex = 10,
				})
				table.insert(Card.Items, { Name = dropName, Instance = Row })

				Create("TextLabel", {
					Parent = Row,
					Size = UDim2.new(0, 80, 0, 32),
					Position = UDim2.new(0, 12, 0.5, -16),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = dropName,
					TextColor3 = Theme.TextBright,
					TextSize = 11.5,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 11,
				})

				local Button = Create("TextButton", {
					Parent = Row,
					Size = UDim2.new(1, -120, 0, 28),
					Position = UDim2.new(0, 108, 0.5, -14),
					BackgroundColor3 = Color3.fromRGB(15, 16, 19),
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 11,
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Button })
				local Stroke = Create("UIStroke", { Parent = Button, Color = Color3.fromRGB(24, 26, 32), Thickness = 1 })

				local SelectLabel = Create("TextLabel", {
					Parent = Button,
					Size = UDim2.new(1, -30, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = tostring(selected),
					TextColor3 = Color3.fromRGB(189, 189, 192),
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 12,
				})

				local Chevron = Create("ImageLabel", {
					Parent = Button,
					Size = UDim2.new(0, 12, 0, 12),
					Position = UDim2.new(1, -20, 0.5, -6),
					BackgroundTransparency = 1,
					Image = Assets.Icons.chevron_down or "",
					ImageColor3 = Color3.fromRGB(130, 130, 140),
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 12,
				})

				local ListBox = Create("Frame", {
					Name = "ListBox",
					Parent = ScreenGui,
					Size = UDim2.new(0, Button.AbsoluteSize.X, 0, #options * 26 + 8),
					BackgroundColor3 = Color3.fromRGB(15, 16, 19),
					BorderSizePixel = 0,
					Active = true,
					Visible = false,
					ZIndex = 150,
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ListBox })
				Create("UIStroke", { Parent = ListBox, Color = Color3.fromRGB(30, 32, 38), Thickness = 1 })

				local ListLayout = Create("UIListLayout", {
					Parent = ListBox,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 2),
				})
				Create("UIPadding", { Parent = ListBox, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) })

				local DropdownBackdrop = nil
				local function CloseDropdown()
					if not isOpen then return end
					isOpen = false
					ListBox.Visible = false
					if DropdownBackdrop and DropdownBackdrop.Parent then
						DropdownBackdrop:Destroy()
						DropdownBackdrop = nil
					end
					Tween(Chevron, TweenInfo.new(0.2), { Rotation = 0 })
					Tween(Stroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(24, 26, 32) })
					if MemoryUI.ActiveDropdown and MemoryUI.ActiveDropdown.Instance == ListBox then
						MemoryUI.ActiveDropdown = nil
					end
				end

				local function OpenDropdown()
					MemoryUI:CloseActiveDropdown()
					isOpen = true
					ListBox.Size = UDim2.new(0, Button.AbsoluteSize.X, 0, #options * 26 + 8)
					ListBox.Position = UDim2.new(0, Button.AbsolutePosition.X, 0, Button.AbsolutePosition.Y + Button.AbsoluteSize.Y + 4)
					ListBox.Visible = true

					-- Full-screen blocker to prevent click pass-through to background sliders/cards
					if not DropdownBackdrop or not DropdownBackdrop.Parent then
						DropdownBackdrop = Create("TextButton", {
							Name = "DropdownBackdrop",
							Parent = ScreenGui,
							Size = UDim2.new(1, 0, 1, 0),
							Position = UDim2.new(0, 0, 0, 0),
							BackgroundTransparency = 1,
							Text = "",
							AutoButtonColor = false,
							Active = true,
							ZIndex = 149,
						})
						DropdownBackdrop.MouseButton1Click:Connect(function()
							CloseDropdown()
						end)
					end

					Tween(Chevron, TweenInfo.new(0.2), { Rotation = 180 })
					Tween(Stroke, TweenInfo.new(0.2), { Color = Theme.Accent })

					MemoryUI.ActiveDropdown = {
						Instance = ListBox,
						Close = CloseDropdown,
					}
				end

				local function Populate()
					for _, ch in ipairs(ListBox:GetChildren()) do
						if ch:IsA("TextButton") then ch:Destroy() end
					end
					for _, opt in ipairs(options) do
						local optBtn = Create("TextButton", {
							Parent = ListBox,
							Size = UDim2.new(1, -8, 0, 24),
							Position = UDim2.new(0, 4, 0, 0),
							BackgroundColor3 = (opt == selected) and Color3.fromRGB(24, 26, 32) or Color3.fromRGB(15, 16, 19),
							BorderSizePixel = 0,
							Font = Enum.Font.GothamMedium,
							Text = "  " .. tostring(opt),
							TextColor3 = (opt == selected) and Theme.Accent or Theme.TextNormal,
							TextSize = 11,
							TextXAlignment = Enum.TextXAlignment.Left,
							AutoButtonColor = false,
							ZIndex = 151,
						})
						Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = optBtn })
						optBtn.MouseButton1Click:Connect(function()
							selected = opt
							SelectLabel.Text = tostring(selected)
							CloseDropdown()
							Populate()
							pcall(callback, selected)
						end)
					end
				end
				Populate()

				Button.MouseButton1Click:Connect(function()
					if MemoryUI.IsModalInteracting then return end
					if MemoryUI.ActiveColorPicker and MemoryUI.ActiveColorPicker.Parent then
						local cpPos = MemoryUI.ActiveColorPicker.AbsolutePosition
						local cpSize = MemoryUI.ActiveColorPicker.AbsoluteSize
						local mouse = UserInputService:GetMouseLocation()
						if mouse.X >= cpPos.X and mouse.X <= cpPos.X + cpSize.X and mouse.Y >= cpPos.Y and mouse.Y <= cpPos.Y + cpSize.Y then
							return
						end
					end
					if MemoryUI.ActiveSubSettings and MemoryUI.ActiveSubSettings.Parent then
						local ssPos = MemoryUI.ActiveSubSettings.AbsolutePosition
						local ssSize = MemoryUI.ActiveSubSettings.AbsoluteSize
						local mouse = UserInputService:GetMouseLocation()
						if mouse.X >= ssPos.X and mouse.X <= ssPos.X + ssSize.X and mouse.Y >= ssPos.Y and mouse.Y <= ssPos.Y + ssSize.Y then
							return
						end
					end
					if isOpen then
						CloseDropdown()
					else
						OpenDropdown()
					end
				end)

				local dropObj = {
					Close = CloseDropdown,
					Set = function(v, extra)
						local opt = (extra ~= nil and extra) or v
						selected = opt
						SelectLabel.Text = tostring(selected)
						Populate()
						pcall(callback, selected)
					end,
					Get = function() return selected end,
					SetOptions = function(newOpts)
						options = newOpts or {}
						if not table.find(options, selected) then
							selected = options[1] or ""
							SelectLabel.Text = tostring(selected)
						end
						Populate()
					end,
				}

				local flagKey = dropdownConfig.Flag or dropName
				MemoryUI.Flags[flagKey] = {
					Type = "Dropdown",
					Get = dropObj.Get,
					Set = dropObj.Set,
				}

				return dropObj
			end

			-- ============================================================
			-- 4. Text Input
			-- ============================================================
			function Card:CreateInput(inputConfig)
				inputConfig = inputConfig or {}
				local placeholder = inputConfig.Placeholder or "Enter text"
				local callback = inputConfig.Callback or function() end

				local Row = Create("Frame", {
					Parent = ItemsContainer,
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundTransparency = 1,
					ZIndex = 3,
				})
				table.insert(Card.Items, { Name = placeholder, Instance = Row })

				local Box = Create("Frame", {
					Parent = Row,
					Size = UDim2.new(1, -24, 0, 28),
					Position = UDim2.new(0, 12, 0.5, -14),
					BackgroundColor3 = Color3.fromRGB(15, 16, 19),
					BorderSizePixel = 0,
					ZIndex = 4,
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Box })
				local Stroke = Create("UIStroke", { Parent = Box, Color = Color3.fromRGB(24, 26, 32), Thickness = 1 })

				local Input = Create("TextBox", {
					Parent = Box,
					Size = UDim2.new(1, -20, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					PlaceholderText = placeholder,
					PlaceholderColor3 = Color3.fromRGB(80, 85, 100),
					Text = "",
					TextColor3 = Color3.fromRGB(208, 208, 212),
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = false,
					ZIndex = 5,
				})

				Input.Focused:Connect(function()
					Tween(Stroke, TweenInfo.new(0.2), { Color = Theme.Accent })
				end)
				Input.FocusLost:Connect(function()
					Tween(Stroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(24, 26, 32) })
					pcall(callback, Input.Text)
				end)
			end

			-- ============================================================
			-- 5. Centered Box / Button (Matching example_field in C++)
			-- ============================================================
			function Card:CreateCenteredBox(boxConfig)
				boxConfig = boxConfig or {}
				local text = boxConfig.Text or boxConfig.Name or "Example"
				local isDanger = (boxConfig.Danger == true) or (boxConfig.Red == true) or (boxConfig.Color == "Red")
				local callback = boxConfig.Callback or function() end

				local defaultBg = isDanger and Color3.fromRGB(28, 14, 16) or Color3.fromRGB(15, 16, 19)
				local hoverBg = isDanger and Color3.fromRGB(45, 18, 22) or Color3.fromRGB(20, 22, 27)
				local defaultTextCol = isDanger and Color3.fromRGB(240, 75, 75) or (boxConfig.TextColor or Theme.TextMuted)
				local hoverTextCol = isDanger and Color3.fromRGB(255, 95, 95) or Theme.TextBright
				local defaultStroke = isDanger and Color3.fromRGB(90, 28, 35) or Color3.fromRGB(24, 26, 32)
				local hoverStroke = isDanger and Color3.fromRGB(160, 45, 55) or Color3.fromRGB(45, 45, 55)

				local Row = Create("Frame", {
					Parent = ItemsContainer,
					Size = UDim2.new(1, 0, 0, 38),
					BackgroundTransparency = 1,
					ZIndex = 3,
				})
				table.insert(Card.Items, { Name = text, Instance = Row })

				local Box = Create("TextButton", {
					Parent = Row,
					Size = UDim2.new(1, -24, 0, 28),
					Position = UDim2.new(0, 12, 0.5, -14),
					BackgroundColor3 = defaultBg,
					BorderSizePixel = 0,
					Font = Enum.Font.GothamMedium,
					Text = text,
					TextColor3 = defaultTextCol,
					TextSize = 11,
					AutoButtonColor = false,
					ZIndex = 4,
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = Box })
				local Stroke = Create("UIStroke", { Parent = Box, Color = defaultStroke, Thickness = 1 })

				Box.MouseEnter:Connect(function()
					Tween(Box, TweenInfo.new(0.15), { BackgroundColor3 = hoverBg, TextColor3 = hoverTextCol })
					Tween(Stroke, TweenInfo.new(0.15), { Color = hoverStroke })
				end)
				Box.MouseLeave:Connect(function()
					Tween(Box, TweenInfo.new(0.15), { BackgroundColor3 = defaultBg, TextColor3 = defaultTextCol })
					Tween(Stroke, TweenInfo.new(0.15), { Color = defaultStroke })
				end)
				Box.MouseButton1Click:Connect(function()
					local clickBg = isDanger and Color3.fromRGB(200, 40, 50) or Theme.Accent
					local clickText = isDanger and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(15, 15, 18)
					Tween(Box, TweenInfo.new(0.08), { BackgroundColor3 = clickBg, TextColor3 = clickText })
					task.delay(0.1, function()
						if Box and Box.Parent then
							Tween(Box, TweenInfo.new(0.15), { BackgroundColor3 = hoverBg, TextColor3 = hoverTextCol })
						end
					end)
					pcall(callback)
				end)

				return {
					SetText = function(newText) Box.Text = tostring(newText) end,
				}
			end

			Card.CreateButton = Card.CreateCenteredBox

			-- ============================================================
			-- 6. Standalone ColorPicker
			-- ============================================================
			function Card:CreateColorPicker(pickerConfig)
				pickerConfig = pickerConfig or {}
				local pickerName = pickerConfig.Name or "Color Picker"
				local defaultColor = pickerConfig.Default or Theme.Accent
				local callback = pickerConfig.Callback or function() end

				local currentColor = defaultColor

				local Row = Create("Frame", {
					Name = "ColorPicker_" .. pickerName,
					Parent = ItemsContainer,
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundTransparency = 1,
					ZIndex = 3,
				})
				table.insert(Card.Items, { Name = pickerName, Instance = Row })

				Create("TextLabel", {
					Parent = Row,
					Size = UDim2.new(1, -60, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = pickerName,
					TextColor3 = Theme.TextBright,
					TextSize = 11.5,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 4,
				})

				local Swatch = Create("TextButton", {
					Parent = Row,
					Size = UDim2.new(0, 24, 0, 16),
					Position = UDim2.new(1, -36, 0.5, -8),
					BackgroundColor3 = currentColor,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 4,
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Swatch })
				Create("UIStroke", { Parent = Swatch, Color = Color3.fromRGB(35, 35, 42), Thickness = 1 })

				Swatch.MouseButton1Click:Connect(function()
					local abs = Swatch.AbsolutePosition
					MemoryUI:OpenColorPicker({
						Title = pickerName,
						Color = currentColor,
						Position = UDim2.new(0, math.clamp(abs.X - 270, 20, 1200), 0, math.clamp(abs.Y - 50, 20, 800)),
						Callback = function(newCol)
							currentColor = newCol
							Swatch.BackgroundColor3 = newCol
							pcall(callback, newCol)
						end
					})
				end)

				return {
					Set = function(col)
						currentColor = col
						Swatch.BackgroundColor3 = col
						pcall(callback, col)
					end,
					Get = function() return currentColor end,
				}
			end

			return Card
		end

		return Tab
	end

	return Window
end

return MemoryUI
