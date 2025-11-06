local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Containers = require(ReplicatedStorage.Scripts.Packages.Containers)
local NetworkController = require(ReplicatedStorage.Scripts.Controllers.NetworkController)
local UtilComponent = require(ReplicatedStorage.Scripts.Components.UtilComponent)
local UIController = require(ReplicatedStorage.Scripts.Controllers.UIController)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ToolsController = {}

function ToolsController:SetupBuildTool()
	local Connections = {}

	local function SetupTool(Tool)
		warn("Setting up Build Tool", Tool)
		Tool.Equipped:Connect(function()
			print("Build Tool Equipped")
			UIController:ShowBuild()
		end)

		Tool.Unequipped:Connect(function()
			print("Build Tool Unequipped")
			UIController:HideBuild()
		end)

		Tool.Activated:Connect(function()
			print("Build Tool Activated")
		end)
	end

	repeat
		task.wait()
	until Player:FindFirstChild("Backpack") and Player.Backpack:FindFirstChild("Build")

	SetupTool(Player.Backpack:FindFirstChild("Build"))
end

function ToolsController:FeatherStart()
	print("ToolsController started")
	self:SetupBuildTool()
end

return Feather.WrapController(ToolsController, script)