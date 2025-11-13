local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)

local Infos = ReplicatedStorage.Scripts.Info
local BuildingInfo = require(Infos.Buildings)

local ItemComponent = {}

function ItemComponent:GetItemInfo(ItemName: string)
	return BuildingInfo[ItemName]
end

function ItemComponent:IsItemOwned(Inventory, ItemName)
	for Item, Quantity in Inventory.Buildings do
		if Item == ItemName and Quantity > 0 then
			return true
		end
	end
end

function ItemComponent:FeatherStart()
	
end

return Feather.WrapComponent(ItemComponent, script)