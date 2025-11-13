local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Containers = require(ReplicatedStorage.Scripts.Packages.Containers)
local DataService = require(ServerScriptService.Scripts.Services.DataService)
local PlotsService = require(ServerScriptService.Scripts.Services.PlotsService)

local Assets = ReplicatedStorage.Assets
local PlayerService = {}

local function PlayerAdded(Player: Player)
	local PlayerData = DataService:GetPlayerData(Player, 0)
	PlotsService:LoadPlot(Player)

	local Backpack = Player:WaitForChild("Backpack")
	Player:SetAttribute("Money", PlayerData.Money)
	Player:SetAttribute("Gems", PlayerData.Gems)

	local function CharacterAdded(Character)
		local Root = Character:WaitForChild("HumanoidRootPart")
		Character.Parent = Containers.Entities

		if Player:GetAttribute("Plot") then
			Root.CFrame = Containers.Plots:FindFirstChild(`Plot_{Player:GetAttribute("Plot")}`).Spawn.CFrame * CFrame.new(0, 5, 0)
		end

		--< Add Items to Backpack >--
		local BuildTool = Assets.Tools:FindFirstChild("Build"):Clone()
		BuildTool.Parent = Backpack

		local RemoveTool = Assets.Tools:FindFirstChild("Remove"):Clone()
		RemoveTool.Parent = Backpack
	end

	if Player.Character then
		CharacterAdded(Player.Character)
	end

	Player.CharacterAdded:Connect(CharacterAdded)
end

local function PlayerRemoving(Player: Player)
	PlotsService:UnloadPlot(Player)
end

function PlayerService:FeatherStart()
	print("Starting PlayerService")
	for _, player in Players:GetPlayers() do
		PlayerAdded(player)
	end

	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(PlayerRemoving)
end

return Feather.WrapService(PlayerService, script)