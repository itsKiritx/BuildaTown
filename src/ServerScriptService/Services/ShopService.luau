local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local NetworkService = require(ServerScriptService.Scripts.Services.NetworkService)
local DataService = require(ServerScriptService.Scripts.Services.DataService)
local RewardService = require(ServerScriptService.Scripts.Services.RewardService)
local UtilComponent = require(ReplicatedStorage.Scripts.Components.UtilComponent)

local RarityInfo = require(ReplicatedStorage.Scripts.Info.Rarities)
local BuildingInfo = require(ReplicatedStorage.Scripts.Info.Buildings)

local ShopService = {
	RestockInterval = 60 * 5, -- 5 minutes
	CurrentStock = {},
	CurrentSeed = nil,
}

function ShopService:UpdateStock() -- Restocks globally every 5 minutes using a synced seed
	local syncedTime = math.floor(workspace:GetServerTimeNow())
	self.CurrentSeed = math.floor(syncedTime / self.RestockInterval)
	local RNG = Random.new(self.CurrentSeed)
	local NewStock = {}

	for Building, Info in BuildingInfo do
		local Rarity = RarityInfo[Info.Rarity]
		local Roll = RNG:NextNumber(0, 1)

		if Roll <= Rarity.Chance then
			NewStock[Building] = RNG:NextInteger(Rarity.Quantity[1], Rarity.Quantity[2])
		end
	end

	local NextStock = (self.CurrentSeed + 1) * self.RestockInterval
	NetworkService:FireAllClients("Shop/Restock", {
		Stock = HttpService:JSONEncode(NewStock),
		NextStock = NextStock,
	})

	warn("Shop restocked with seed:", self.CurrentSeed, "and stock:", NewStock, "Next restock in", NextStock - syncedTime, "seconds")
	self.CurrentStock = NewStock
end

function ShopService:BuyBuilding(Player, BuildingName)
	local PlayerData = DataService:GetPlayerData(Player, 0)
	local SlotData = DataService:GetPlayerData(Player)
	if not PlayerData then
		warn("Player data not found for", Player.Name)
		return "Player data not found"
	end

	PlayerData.CurrentPurchases = PlayerData.CurrentPurchases or {}
	PlayerData.CurrentPurchases.Seed = PlayerData.CurrentPurchases.Seed or self.CurrentSeed
	PlayerData.CurrentPurchases.Buildings = PlayerData.CurrentPurchases.Buildings or {}

	if PlayerData.CurrentPurchases.Seed ~= self.CurrentSeed then
		PlayerData.CurrentPurchases.Seed = self.CurrentSeed
		PlayerData.CurrentPurchases.Buildings = {}
	end

	local StockAmount = self.CurrentStock[BuildingName] or 0
	if PlayerData.Money < BuildingInfo[BuildingName].Price then
		warn("Not enough currency to buy building:", BuildingName)
		return "Not enough currency"
	end

	PlayerData.CurrentPurchases.Buildings[BuildingName] = PlayerData.CurrentPurchases.Buildings[BuildingName] or 0
	if PlayerData.CurrentPurchases.Buildings[BuildingName] >= StockAmount then
		warn("Item out of stock:", BuildingName)
		return "Item out of stock"
	end

	RewardService:GiveMoney(Player, -BuildingInfo[BuildingName].Price)
	PlayerData.CurrentPurchases.Buildings[BuildingName] += 1

	SlotData.Inventory = SlotData.Inventory or {}
	SlotData.Inventory.Buildings = SlotData.Inventory.Buildings or {}
	SlotData.Inventory.Buildings[BuildingName] = (SlotData.Inventory.Buildings[BuildingName] or 0) + 1

	NetworkService:FireClient("Inventory/Update", Player, {
		Inventory = HttpService:JSONEncode(SlotData.Inventory),
	})

	warn("Player bought building:", BuildingName)
	return "Success"
end

function ShopService:FeatherStart()
	print("Starting ShopService")

	NetworkService.OnServerInvoke("Shop/GetStock", function(Data, Player)
		local PlayerData = DataService:GetPlayerData(Player, 0)
		local CurrentPurchases = PlayerData.CurrentPurchases or {}
		if CurrentPurchases.Seed ~= self.CurrentSeed then
			CurrentPurchases.Seed = self.CurrentSeed
			CurrentPurchases.Buildings = {}
		end

		local Stock = UtilComponent:DeepClone(self.CurrentStock)
		for BuildingName, AmountPurchased in CurrentPurchases.Buildings do
			local StockAmount = self.CurrentStock[BuildingName] or 0
			Stock[BuildingName] = math.max(0, StockAmount - AmountPurchased)
		end

		local toReturn = {
			Stock = Stock,
			NextStock = (self.CurrentSeed + 1) * self.RestockInterval,
		}

		warn("Player", Player.Name, "requested shop stock:", toReturn)
		return {Stock = HttpService:JSONEncode(toReturn)}
	end)

	NetworkService.OnServerInvoke("Shop/BuyBuilding", function(Data, Player)
		local BuildingName = Data.BuildingName
		warn("Player", Player.Name, "is attempting to buy building:", BuildingName)
		local Result = self:BuyBuilding(Player, BuildingName)
		return {Success = Result}
	end)

	while true do
		if self.CurrentSeed ~= math.floor(workspace:GetServerTimeNow() / self.RestockInterval) then
			self:UpdateStock()
		end
		task.wait(1)
	end

end

return Feather.WrapService(ShopService, script)