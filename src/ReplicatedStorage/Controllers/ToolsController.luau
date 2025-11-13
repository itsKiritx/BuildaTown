local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Containers = require(ReplicatedStorage.Scripts.Packages.Containers)
local NetworkController = require(ReplicatedStorage.Scripts.Controllers.NetworkController)
local PlotController = require(ReplicatedStorage.Scripts.Controllers.PlotController)
local UIController = require(ReplicatedStorage.Scripts.Controllers.UIController)
local BuildController = require(ReplicatedStorage.Scripts.Controllers.BuildController)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ToolsController = {}

function ToolsController:SetupBuildTool()
	local Connections = {}

	local function SetupTool(Tool)
		Tool.Equipped:Connect(function()
			Player:SetAttribute("CurrentTool", "Build")
			UIController:ShowBuild()
			PlotController:ShowOutline()
		end)

		Tool.Unequipped:Connect(function()
			Player:SetAttribute("CurrentTool", nil)
			Player:SetAttribute("CurrentBuilding", nil)
			UIController:HideBuild()
			PlotController:HideOutline()
		end)

		Tool.Activated:Connect(function()
			BuildController:PlaceBuilding()
		end)
	end

	repeat
		task.wait()
	until Player:FindFirstChild("Backpack") and Player.Backpack:FindFirstChild("Build")

	SetupTool(Player.Backpack:FindFirstChild("Build"))
end

function ToolsController:SetupRemoveTool()
	local Connections = {}

	local function SetupTool(Tool)
		Tool.Equipped:Connect(function()
			Player:SetAttribute("CurrentTool", "Remove")
			PlotController:ShowOutline()
		end)

		Tool.Unequipped:Connect(function()
			Player:SetAttribute("CurrentTool", nil)
			Player:SetAttribute("CurrentBuilding", nil)
			PlotController:HideOutline()
		end)

		Tool.Activated:Connect(function()
			BuildController:RemoveBuilding()
		end)
	end

	repeat
		task.wait()
	until Player:FindFirstChild("Backpack") and Player.Backpack:FindFirstChild("Remove")

	SetupTool(Player.Backpack:FindFirstChild("Remove"))
end

function ToolsController:FeatherStart()
	print("ToolsController started")
	self:SetupBuildTool()
	self:SetupRemoveTool()
end

return Feather.WrapController(ToolsController, script)