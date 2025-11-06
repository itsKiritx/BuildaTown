local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Containers = require(ReplicatedStorage.Scripts.Packages.Containers)
local UtilComponent = require(ReplicatedStorage.Scripts.Components.UtilComponent)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local BuildingInfo = require(ReplicatedStorage.Scripts.Info.Buildings)

local UIController = {}

function UIController:SetupMainUI()
	local MainUI = PlayerGui:WaitForChild("Main")
	local Money = MainUI:WaitForChild("Money"):WaitForChild("Amount")
	Money.Text = "Loading..."

	local ShopUI = PlayerGui:WaitForChild("Shop"):WaitForChild("Main")
	local BuildUI = PlayerGui:WaitForChild("Build"):WaitForChild("Main")

	local function UpdateMoney()
		local playerMoney = Player:GetAttribute("Money") or 0
		local playerGems = Player:GetAttribute("Gems") or 0

		Money.Text = "$"..tostring(playerMoney)
		ShopUI.Currency.Money.Amount.Text = "$"..tostring(playerMoney)
		ShopUI.Currency.Gems.Amount.Text = tostring(playerGems)

		BuildUI.Currency.Money.Amount.Text = "$"..tostring(playerMoney)
		BuildUI.Currency.Gems.Amount.Text = tostring(playerGems)
	end

	UpdateMoney()
	Player:GetAttributeChangedSignal("Money"):Connect(UpdateMoney)

	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Root = Character:WaitForChild("HumanoidRootPart")

	local TopButtons = MainUI:WaitForChild("TopButtons")
	local TownButton = TopButtons:WaitForChild("Town")
	local ShopButton = TopButtons:WaitForChild("Shop")

	TownButton.MouseButton1Up:Connect(function()
		if not Player:GetAttribute("Plot") then
			warn("Player has no plot assigned!")
			return
		end

		Root.CFrame = Containers.Plots:FindFirstChild(`Plot_{Player:GetAttribute("Plot")}`).Spawn.CFrame * CFrame.new(0, 5, 0)
	end)
end

function UIController:ShowShop()
	local ShopUI = PlayerGui:WaitForChild("Shop"):WaitForChild("Main")
	ShopUI.Position = UDim2.new(0.5, 0, 1.5, 0)
	ShopUI.Visible = true

	TweenService:Create(ShopUI, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
end

function UIController:HideShop()
	local ShopUI = PlayerGui:WaitForChild("Shop"):WaitForChild("Main")
	TweenService:Create(ShopUI, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
	task.delay(0.5, function()
		ShopUI.Visible = false
	end)
end

function UIController:SetupShopUI()
	local ShopUI = PlayerGui:WaitForChild("Shop"):WaitForChild("Main")

	--< Exit Button >--
	local ExitButton: TextButton = ShopUI:WaitForChild("Exit")
	ExitButton.MouseButton1Up:Connect(function()
		self:HideShop()
	end)

	ExitButton.MouseEnter:Connect(function()
		TweenService:Create(ExitButton.UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.15}):Play()
	end)

	ExitButton.MouseLeave:Connect(function()
		TweenService:Create(ExitButton.UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
	end)

	--< Tabs >--
	local Tabs = ShopUI:WaitForChild("Tabs")
	local Pages = ShopUI:WaitForChild("Pages")

	for _, TabButton in Tabs:GetChildren() do
		if TabButton:IsA("TextButton") then
			TabButton.MouseButton1Up:Connect(function()
				for _, Page in Pages:GetChildren() do
					if not Page:IsA("ScrollingFrame") then continue end
					Page.Visible = Page.Name == TabButton.Name
				end
			end)
		end
	end

	--< Buildings Tab >--
	local BuildingsPage = Pages:WaitForChild("Buildings")
	for _, Building: TextButton in BuildingsPage:GetChildren() do
		if not Building:IsA("TextButton") then continue end
		local Info = BuildingInfo[Building.Name]
		if not Info then
			warn(`No building info found for {Building.Name}`)
			continue
		end

		local UIScale = Building:WaitForChild("ViewportFrame"):WaitForChild("UIScale")
		Building.MouseEnter:Connect(function(x, y)
			TweenService:Create(UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.25}):Play()
		end)

		Building.MouseLeave:Connect(function()
			TweenService:Create(UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
		end)

		Building:WaitForChild("Title").Text = Info.Name
		Building:WaitForChild("Info"):WaitForChild("Cost").Text = "$"..tostring(Info.Price)
		Building:WaitForChild("Info"):WaitForChild("Income").Text = "+"..tostring(Info.Income).."/sec"
	end
end

local BuildTween = nil
function UIController:ShowBuild()
	local BuildUI = PlayerGui:WaitForChild("Build"):WaitForChild("Main")
	BuildUI.Position = UDim2.new(-0.5, 0, 0.5, 0)
	BuildUI.Visible = true

	if BuildTween then
		BuildTween:Cancel()
	end

	BuildTween = TweenService:Create(BuildUI, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.05, 0, 0.5, 0)})
	BuildTween:Play()
end

function UIController:HideBuild()
	local BuildUI = PlayerGui:WaitForChild("Build"):WaitForChild("Main")

	if BuildTween then
		BuildTween:Cancel()
	end

	BuildTween = TweenService:Create(BuildUI, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(-0.5, 0, 0.5, 0)})
	BuildTween:Play()
end

function UIController:ShowAnimatedText(Text: string, Color: Color3?, Duration: number?)
	local OverlayUI = PlayerGui:WaitForChild("Overlay")
	local TextUI = OverlayUI:WaitForChild("Text")

	local Label = TextUI.Template:Clone()
	Label.Text = ""
	Label.TextColor3 = Color or Color3.fromRGB(255, 255, 255)
	Label.Parent = TextUI
	Label.Visible = true

	UtilComponent:BubblyText(Label, Text)

	game.Debris:AddItem(Label, Duration or 5)
end

function UIController:FeatherStart()
	print("UIController started")
	self:SetupMainUI()
	self:SetupShopUI()
end

return Feather.WrapController(UIController, script)