local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Containers = require(ReplicatedStorage.Scripts.Packages.Containers)
local UtilComponent = require(ReplicatedStorage.Scripts.Components.UtilComponent)
local UIController = require(ReplicatedStorage.Scripts.Controllers.UIController)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local NpcController = {}

function NpcController:SetupShopNPC()
	local ShopUI = PlayerGui:WaitForChild("Shop"):WaitForChild("Main")
	
	local NPC = Containers.NPCs:FindFirstChild("ShopKeeper")
	local ProximityPrompt = NPC:WaitForChild("ProximityPrompt")
	local BillboardGui = NPC:WaitForChild("BillboardGui")
	local Label = BillboardGui:WaitForChild("Dialogue")

	Label.Text = ""
	Label.Visible = false

	ProximityPrompt.Triggered:Connect(function()
		warn("Shop NPC Prompt Triggered")
		ProximityPrompt.Enabled = false

		Label.Text = ""
		Label.Visible = true

		UtilComponent:BubblyText(Label, `Welcome to my shop {Player.DisplayName or Player.Name}! Take a look around.`, {
			TextScaled = true
		})

		task.wait(2)
		UIController:ShowShop()

		repeat
			task.wait(1)
		until not ShopUI.Visible

		UtilComponent:BubblyText(Label, "Thanks for stopping by! Come again soon!", {
			TextScaled = true
		})

		task.wait(2)
		Label.Visible = false
		ProximityPrompt.Enabled = true
	end)
end

function NpcController:FeatherStart()
	print("NpcController started")
	self:SetupShopNPC()
end

return Feather.WrapController(NpcController, script)