local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Containers = require(ReplicatedStorage.Scripts.Packages.Containers)

local UtilComponent = {}

function UtilComponent:FolderToStringedTable(folder, checks)
	local tbl = {}
	local function traverse(parent, string)
		for _, Object in parent:GetChildren() do
			local NewString = string .. Object.Name
			local Function = checks[Object.ClassName]
			if Function then
				tbl[NewString] = Function(Object, NewString)
			end
			if Object:IsA("Folder") then
				NewString = NewString .. "/"
				traverse(Object, NewString)
			end
		end
	end
	traverse(folder, "")
	return tbl
end

function UtilComponent:Weld(a: BasePart, b: BasePart, name: string?): WeldConstraint
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = a
	weld.Part1 = b
	if name then
		weld.Name = name
	end
	weld.Parent = a
	return weld
end

function UtilComponent:FormatNumber(num)
	local formatted = tostring(num)
	while true do
		local k = formatted:match("^(-?%d+)(%d%d%d)")
		if not k then break end
		formatted = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
	end
	return formatted
end

function UtilComponent:DeepClone(Table)
	local clone = table.clone(Table)

	for key, value in Table do
		if type(value) == "table" then
			clone[key] = self:DeepClone(value)
		end
	end

	return clone
end

function UtilComponent:TableCount(Table)
	local Count = 0
	if not Table then return Count end

	for _, _ in Table do
		Count += 1
	end

	return Count
end

function UtilComponent:CircularProgress(UI, CurrentTime, TotalTime)
	local LeftHalf = UI.Left.Circle
	local RightHalf = UI.Right.Circle
	local TimeText = UI.Center.Time

	local Percentage = Instance.new("NumberValue")

	local function Update()
		local Rotation = math.clamp(Percentage.Value * 3.6, 0, 360)
		local TimePassed = math.floor(TotalTime * (Percentage.Value / 100))
		local TimeLeft = TotalTime - TimePassed

		local hours = math.floor(TimeLeft / 3600)
		local minutes = math.floor((TimeLeft % 3600) / 60)
		local seconds = TimeLeft % 60
		TimeText.Text = hours > 0 and string.format("%02d:%02d:%02d", hours, minutes, seconds) or string.format("%02d:%02d", minutes, seconds)

		RightHalf.UIGradient.Rotation = math.clamp(Rotation, 0, 180)
		LeftHalf.UIGradient.Rotation = math.clamp(Rotation, 180, 360)
	end

	Percentage:GetPropertyChangedSignal("Value"):Connect(function()
		Update()
	end)

	Percentage.Value = (CurrentTime or 0) / (TotalTime or 1) * 100
	Update()
	local Tween = TweenService:Create(Percentage, TweenInfo.new(math.max(TotalTime - (CurrentTime or 0), 0), Enum.EasingStyle.Linear), {Value = 100})
	Tween:Play()
	return Tween
end

function UtilComponent:BubblyText(TextLabel: TextLabel, Text: string, Settings: table?)
	local function escapeRichText(str)
		return str
			:gsub("&", "&amp;")
			:gsub("<", "&lt;")
			:gsub(">", "&gt;")
	end

	local function colorToRGB(color)
		return ("rgb(%d,%d,%d)"):format(
			math.floor(color.R * 255),
			math.floor(color.G * 255),
			math.floor(color.B * 255)
		)
	end

	Settings = Settings or {}
	assert(typeof(TextLabel) == "Instance" and TextLabel:IsA("TextLabel"), "First arg must be a TextLabel")

	TextLabel.RichText = true
	TextLabel.TextScaled = Settings.TextScaled or false

	local len            = #Text
	local baseSize       = Settings.BaseSize       or TextLabel.TextSize
	local punchSize      = Settings.PunchSize      or (baseSize + 10)
	local typeSpeed      = Settings.TypeSpeed      or 0.025
	local bounceDuration = Settings.BounceDuration or 0.25
	local colorFadeTime  = Settings.ColorFadeTime  or 0.3
	local finalColor     = Settings.FinalColor     or TextLabel.TextColor3

	local appearTimes     = {}              -- when each char “starts”
	local sizes           = {}              -- current size of each char
	local colors          = {}              -- current color of each char
	local transparencies  = {}              -- current transparency of each char

	local rainbowStart = {}
	for i = 1, len do
		sizes[i]          = baseSize
		colors[i]         = colorToRGB(finalColor)  -- init string, will lerp
		transparencies[i] = 1
		appearTimes[i]    = math.huge

		local hue     = (i / len) % 1
		rainbowStart[i] = Color3.fromHSV(hue, 1, 1)
	end

	local function build()
		local parts = table.create(len, "")
		for i = 1, len do
			local char = escapeRichText(Text:sub(i, i))
			parts[i] = string.format(
				'<font color="%s" transparency="%.2f" size="%d">%s</font>',
				colors[i],
				transparencies[i],
				math.floor(sizes[i]),
				char
			)
		end
		return table.concat(parts)
	end

	local startTime = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local now = os.clock() - startTime
		local allDone = true

		for i = 1, len do
			if now >= (i - 1) * typeSpeed and appearTimes[i] == math.huge then
				appearTimes[i] = now
			end

			if appearTimes[i] ~= math.huge then
				local dt = now - appearTimes[i]

				local t1 = math.clamp(dt / bounceDuration, 0, 1)
				sizes[i] = punchSize - (punchSize - baseSize) * t1

				local t2 = math.clamp(dt / colorFadeTime, 0, 1)
				local c = rainbowStart[i]:Lerp(finalColor, t2)
				colors[i] = colorToRGB(c)

				transparencies[i] = 0

				if dt < math.max(bounceDuration, colorFadeTime) then
					allDone = false
				end
			else
				allDone = false
			end
		end

		TextLabel.Text = build()

		if allDone then
			conn:Disconnect()
		end
	end)
end

return Feather.WrapComponent(UtilComponent, script)