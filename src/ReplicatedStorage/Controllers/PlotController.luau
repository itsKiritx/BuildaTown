local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Containers = require(ReplicatedStorage.Scripts.Packages.Containers)
local NetworkController = require(ReplicatedStorage.Scripts.Controllers.NetworkController)
local UtilComponent = require(ReplicatedStorage.Scripts.Components.UtilComponent)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local PlotController = {}

function PlotController:GetPlot()
	return Containers.Plots:FindFirstChild(`Plot_{Player:GetAttribute("Plot")}`)
end

function PlotController:ShowOutline()
	local Plot = self:GetPlot()
	if not Plot then return end

	local Outline = Plot:FindFirstChild("Plot")
	TweenService:Create(Outline, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Transparency = 0.85}):Play()

	for _, Building in Plot.Buildings:GetChildren() do
		if not Building:IsA("Model") then continue end
		local SelectionBox = Building:FindFirstChild("SelectionBox") or Instance.new("SelectionBox")
		SelectionBox.Adornee = Building
		SelectionBox.Parent = Building
		SelectionBox.LineThickness = 0.05
		SelectionBox.SurfaceTransparency = 0.5
		SelectionBox.Transparency = 0
		SelectionBox.Visible = true

		SelectionBox.Color3 = Color3.fromRGB(175, 175, 175)
		SelectionBox.SurfaceColor3 = Color3.fromRGB(175, 175, 175)
	end
end

function PlotController:HideOutline()
	local Plot = self:GetPlot()
	if not Plot then return end

	local Outline = Plot:FindFirstChild("Plot")
	TweenService:Create(Outline, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()

	for _, Building in Plot.Buildings:GetChildren() do
		if not Building:IsA("Model") then continue end
		local SelectionBox = Building:FindFirstChild("SelectionBox")
		if SelectionBox then
			SelectionBox.Visible = false
		end
	end
end

function PlotController:FeatherStart()
	print("PlotController started")
end

return Feather.WrapController(PlotController, script)