local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Containers = require(ReplicatedStorage.Scripts.Packages.Containers)
local UtilComponent = require(ReplicatedStorage.Scripts.Components.UtilComponent)
local NetworkController = require(ReplicatedStorage.Scripts.Controllers.NetworkController)
local SoundController = require(ReplicatedStorage.Scripts.Controllers.SoundController)
local UIController = require(ReplicatedStorage.Scripts.Controllers.UIController)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local BuildingInfo = require(ReplicatedStorage.Scripts.Info.Buildings)

local ShopController = {
	ShopUI = nil,
	CardUI = nil,
	CurrentStock = {},
	CurrentPurchases = {},
}

local function PlaySound(Type)
	SoundController:GetSound("Menu/"..Type, {
		Volume = 2,
		Parent = workspace.CurrentCamera,
		Play = true,
	})
end

function ShopController:UpdateStock(Data)
	Data = Data or HttpService:JSONDecode(NetworkController:InvokeServer("Shop/GetStock", {}).Stock)
	self.CurrentStock = Data.Stock
	local NextStock = tonumber(Data.NextStock)

	--< Update Timer >--
	local RestockTimer = self.ShopUI:WaitForChild("Currency"):WaitForChild("RestockTimer")
	local RestockTime = RestockTimer:WaitForChild("Time")
	RestockTime.Value = NextStock

	--< Update Items >--
	local Pages = self.ShopUI:WaitForChild("Pages")
	local BuildingsPage = Pages:WaitForChild("Buildings")

	for _, Building in BuildingsPage:GetChildren() do
		if not Building:IsA("TextButton") then continue end

		local BuildingName = Building.Name
		local StockAmount = self.CurrentStock[BuildingName] or 0
		Building:WaitForChild("Amount").Text = "x"..tostring(StockAmount)
	end
end

function ShopController:BuyBuilding(Building)
	self.CurrentPurchases[Building] = self.CurrentPurchases[Building] or 0
	local StockAmount = self.CurrentStock[Building] or 0
	if self.CurrentPurchases[Building] >= StockAmount then
		warn("Item out of stock")
		return
	end

	self.CurrentPurchases[Building] += 1
	local Result = NetworkController:InvokeServer("Shop/BuyBuilding", {BuildingName = Building})
	if not Result.Success or Result.Success ~= "Success" then
		PlaySound("Error")
		warn("Failed to buy building:", Building, "Reason:", Result)
		return
	end

	PlaySound("BuySuccess")
	local BuildingsPage = self.ShopUI.Pages.Buildings
	local BuildingButton = BuildingsPage:FindFirstChild(Building)

	local StockAmount = (self.CurrentStock[Building] - self.CurrentPurchases[Building])
	BuildingButton.Amount.Text = "x"..tostring(StockAmount)
end

function ShopController:FeatherStart()
	print("ShopController started")
	self.ShopUI = PlayerGui:WaitForChild("Shop"):WaitForChild("Main")
	self.CardUI = PlayerGui:WaitForChild("Shop"):WaitForChild("InfoCard")
	self:UpdateStock()

	self.CardUI.Buttons.Buy.MouseButton1Up:Connect(function()
		self:BuyBuilding(self.CardUI:GetAttribute("CurrentItem"))
	end)

	NetworkController.OnClientEvent("Shop/Restock", function(Data)
		self.CurrentPurchases = {}
		local toSend = {
			Stock = HttpService:JSONDecode(Data.Stock),
			NextStock = Data.NextStock,
		}

		PlaySound("RestockNotify")
		UIController:ShowAnimatedText("The Shop has been Restocked!")
		self:UpdateStock(toSend)
	end)
end

return Feather.WrapController(ShopController, script)