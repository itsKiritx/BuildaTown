local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local DataService = require(ServerScriptService.Scripts.Services.DataService)
local PlotsService = require(ServerScriptService.Scripts.Services.PlotsService)

local RewardService = {}

function RewardService:GiveMoney(Player: Player, Amount: IntValue)
	local PlayerData = DataService:GetPlayerData(Player, 0)
	if PlayerData then
		PlayerData.Money = (PlayerData.Money or 0) + Amount
		Player:SetAttribute("Money", PlayerData.Money)
		print(`Gave {Amount} money to {Player.Name}. New balance: {PlayerData.Money}`)
	else
		warn(`Failed to give money to {Player.Name}: No player data found.`)
	end
end

function RewardService:FeatherStart()
	print("Starting RewardService")
end

return Feather.WrapService(RewardService, script)