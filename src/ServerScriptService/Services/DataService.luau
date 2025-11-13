local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local ProfileStore = require(ServerScriptService.Scripts.Library.ProfileStore)
local NetworkService = require(ServerScriptService.Scripts.Services.NetworkService)

local PlayerStore
local DataService = {
	DataStoreName = "PlayerData",
	Profiles = {},
	ProfileTemplate = {
		CurrentSlot = 1,

		Money = 500,
		Gems = 0,
		Likes = 0,
		Liked = {},

		Gamepasses = {},

		Slots = {
			[1] = {
				Inventory = {
					Buildings = {},
					Roads = {},
					Decorations = {},
				},

				Stats = {
					UpgradeLevel = 1,
				},

				Plot = {
					Buildings = {},
					Roads = {},
					Decorations = {},
				}
			}
		},
	}
}

function DataService:GetProfile(Player: Player)
	local profile = PlayerStore:StartSessionAsync(`{Player.UserId}`, {
		Cancel = function()
			return Player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		profile:AddUserId(Player.UserId)
		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			self.Profiles[Player] = nil
			Player:Kick("Your data session has ended - please rejoin.")
		end)

		if Player.Parent == Players then
			self.Profiles[Player] = profile
			print("Loaded profile for player:", Player.Name)
		else
			profile:EndSession()
		end
	else
		Player:Kick("Could not load your data - please rejoin.")
	end
end

function DataService:GetPlayerData(Player: Player, Slot: number?)
	repeat
		task.wait()
	until self.Profiles[Player]
	local profile = self.Profiles[Player]
	if not profile then
		return {}
	end

	if not Slot then
		Slot = profile.Data.CurrentSlot or 1
	elseif Slot == 0 then
		return profile.Data
	end

	Slot = tonumber(Slot)
	local Data = profile.Data.Slots[Slot]
	for index, value in self.ProfileTemplate.Slots[1] do
		if Data[index] == nil then
			Data[index] = value
		end
	end

	return Data
end

local function PlayerAdded(Player)
	if DataService.Profiles[Player] then
		warn("Profile already exists for player:", Player.Name)
		return
	end

	DataService:GetProfile(Player)
end

function DataService:FeatherStart()
	warn("Starting DataService")
	PlayerStore = ProfileStore.New(self.DataStoreName, self.ProfileTemplate)

	for _, player in Players:GetPlayers() do
		PlayerAdded(player)
	end

	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(function(Player)
		local profile = self.Profiles[Player]
		if profile ~= nil then
			profile:EndSession()
		end
	end)

	NetworkService.OnServerInvoke("FetchData", function(Data, Player)
		warn("Fetching data for player:", Player.Name, "Slot:", Data.Slot)
		local PlayerData = self:GetPlayerData(Player, Data.Slot)
		warn("Sending Player Data:", PlayerData)
		return {Data = HttpService:JSONEncode(PlayerData or {})}
	end)
end

return Feather.WrapService(DataService, script)
