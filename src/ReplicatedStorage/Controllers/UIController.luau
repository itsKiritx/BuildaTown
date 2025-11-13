local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Containers = require(ReplicatedStorage.Scripts.Packages.Containers)
local UtilComponent = require(ReplicatedStorage.Scripts.Components.UtilComponent)
local SoundController = require(ReplicatedStorage.Scripts.Controllers.SoundController)
local PlotController = require(ReplicatedStorage.Scripts.Controllers.PlotController)
local NetworkController = require(ReplicatedStorage.Scripts.Controllers.NetworkController)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local BuildingAssets = ReplicatedStorage.Assets.Buildings
local BuildingInfo = require(ReplicatedStorage.Scripts.Info.Buildings)

local UIController = {
	InfoCardItem = nil,
}

local function PlaySound(Type, Volume)
	SoundController:GetSound("Menu/"..Type, {
		Volume = Volume or 2,
		Parent = workspace.CurrentCamera,
		Play = true,
	})
end

function UIController:SetupMainUI()
	local MainUI = PlayerGui:WaitForChild("Main")
	local Money = MainUI:WaitForChild("Money"):WaitForChild("Amount")
	Money.Text = "Loading..."

	local ShopUI = PlayerGui:WaitForChild("Shop"):WaitForChild("Main")
	local BuildUI = PlayerGui:WaitForChild("Build"):WaitForChild("Main")

	local function UpdateMoney()
		local playerMoney = UtilComponent:FormatNumber(Player:GetAttribute("Money") or 0)
		local playerGems = UtilComponent:FormatNumber(Player:GetAttribute("Gems") or 0)

		Money.Text = "$"..playerMoney
		ShopUI.Currency.Money.Amount.Text = "$"..playerMoney
		ShopUI.Currency.Gems.Amount.Text = playerGems

		BuildUI.Currency.Money.Amount.Text = "$"..playerMoney
		BuildUI.Currency.Gems.Amount.Text = playerGems
	end

	UpdateMoney()
	Player:GetAttributeChangedSignal("Money"):Connect(UpdateMoney)

	local TopButtons = MainUI:WaitForChild("TopButtons")
	local TownButton = TopButtons:WaitForChild("Town")
	local ShopButton = TopButtons:WaitForChild("Shop")

	TownButton.MouseButton1Up:Connect(function()
		local Character = Player.Character or Player.CharacterAdded:Wait()
		local Root = Character:WaitForChild("HumanoidRootPart")

		PlaySound("ButtonClick")
		if not Player:GetAttribute("Plot") then
			warn("Player has no plot assigned!")
			return
		end

		Root.CFrame = Containers.Plots:FindFirstChild(`Plot_{Player:GetAttribute("Plot")}`).Spawn.CFrame * CFrame.new(0, 5, 0)
	end)

	ShopButton.MouseButton1Up:Connect(function()
		local Character = Player.Character or Player.CharacterAdded:Wait()
		local Root = Character:WaitForChild("HumanoidRootPart")

		PlaySound("ButtonClick")
		local ShopKeeper = Containers.NPCs:FindFirstChild("ShopKeeper")
		if not ShopKeeper then return end

		Root.CFrame = ShopKeeper.PrimaryPart.CFrame * CFrame.new(0, 0, -4) * CFrame.Angles(0, math.rad(180), 0)
	end)
end

function UIController:ShowInfoCard(Type, Info, UI, dontAnimate)
	local InfoCard = PlayerGui:WaitForChild("Shop"):WaitForChild("InfoCard")
	local GridLayout: UIGridLayout = UI.Parent:WaitForChild("UIGridLayout")

	if self.InfoCardItem == Info.Name and InfoCard.Visible then
		return
	end

	local Offset = GridLayout.Parent.AbsoluteSize.X * GridLayout.CellPadding.X.Scale
	InfoCard.Position = UDim2.new(0, UI.AbsolutePosition.X + UI.AbsoluteSize.X, 0, UI.AbsolutePosition.Y - PlayerGui.Shop.AbsolutePosition.Y)

	InfoCard.ViewportFrame:ClearAllChildren()
	local Model = BuildingAssets:FindFirstChild(Info.Name)
	if Model then
		Model = Model:Clone()
		Model:PivotTo(Model:GetAttribute("ViewportPivot"))
		Model.Parent = InfoCard.ViewportFrame
	end

	InfoCard.BuildingName.Text = Info.Name
	InfoCard.Rarity.Text = "Rarity: "..Info.Rarity
	InfoCard.Income.Text = "Income: +"..tostring(Info.Income).."/sec"
	InfoCard.BuildingSize.Text = "Size: "..(Info.Size or "N/A")
	InfoCard.RequiresRoad.Text = "Requires Road: "..tostring(Info.RequiresRoad and "Yes" or "No")
	InfoCard.Description.Text = Info.Description or "-"

	InfoCard.Buttons.Buy.Label.Text = "BUY - $"..tostring(Info.Price)

	InfoCard.Visible = true

	if dontAnimate then
		InfoCard.Position = UDim2.new(0, InfoCard.AbsolutePosition.X + Offset, 0, UI.AbsolutePosition.Y - PlayerGui.Shop.AbsolutePosition.Y)
	else
		TweenService:Create(InfoCard, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, InfoCard.AbsolutePosition.X + Offset, 0, UI.AbsolutePosition.Y - PlayerGui.Shop.AbsolutePosition.Y)}):Play()
	end
end

function UIController:ShowShop()
	PlaySound("UIPopup")
	local ShopUI = PlayerGui:WaitForChild("Shop"):WaitForChild("Main")
	ShopUI.Position = UDim2.new(0.5, 0, 1.5, 0)
	ShopUI.Visible = true

	TweenService:Create(ShopUI, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
end

function UIController:HideShop()
	PlaySound("UIClose")
	local ShopUI = PlayerGui:WaitForChild("Shop"):WaitForChild("Main")
	TweenService:Create(ShopUI, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
	task.delay(0.5, function()
		ShopUI.Visible = false
	end)
end

function UIController:SetupShopUI()
	local ShopUI = PlayerGui:WaitForChild("Shop"):WaitForChild("Main")
	local InfoCard = PlayerGui:WaitForChild("Shop"):WaitForChild("InfoCard")

	--< Restock Timer >--
	local RestockTimer: TextLabel = ShopUI:WaitForChild("Currency"):WaitForChild("RestockTimer")
	local RestockTime: IntValue = RestockTimer:WaitForChild("Time")
	task.spawn(function()
		while task.wait(0.5) do
			local timeLeft = RestockTime.Value - workspace:GetServerTimeNow()
			if timeLeft <= 0 then
				RestockTimer.Text = "Restocking..."
			else
				local minutes = math.floor(timeLeft / 60)
				local seconds = timeLeft % 60
				RestockTimer.Text = `Restocks: {string.format("%02d:%02d", minutes, seconds)}`
			end
		end
	end)

	--< Exit Button >--
	local ExitButton: TextButton = ShopUI:WaitForChild("Exit")
	ExitButton.MouseButton1Up:Connect(function()
		self:HideShop()
	end)

	ExitButton.MouseEnter:Connect(function()
		PlaySound("ButtonHover")
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

		Building:WaitForChild("Title").Text = Info.Name
		Building:WaitForChild("Info"):WaitForChild("Cost").Text = "$"..UtilComponent:FormatNumber(Info.Price)
		Building:WaitForChild("Info"):WaitForChild("Income").Text = "$"..UtilComponent:FormatNumber(Info.Income).."/sec"

		Building:WaitForChild("Locked"):WaitForChild("Upgrade").Text = "REQUIRES UPGRADE "..tostring(Info.Upgrade)
		Building.Locked.Visible = (Player:GetAttribute("Upgrade") or 1) < Info.Upgrade

		Building.MouseButton1Up:Connect(function()
			PlaySound("ButtonClick")
			if InfoCard:GetAttribute("CurrentItem") == Info.Name and InfoCard.Visible then
				return
			end

			task.wait()
			self:ShowInfoCard("Building", Info, Building, true)
			InfoCard:SetAttribute("CurrentItem", Info.Name)
		end)

		Building.MouseEnter:Connect(function()
			TweenService:Create(UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.25}):Play()
			if InfoCard:GetAttribute("CurrentItem") then return end

			PlaySound("ButtonHover")
			self.InfoCardItem = Info.Name
			self:ShowInfoCard("Building", Info, Building)
		end)

		Building.MouseLeave:Connect(function()
			self.InfoCardItem = nil
			TweenService:Create(UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
			if InfoCard:GetAttribute("CurrentItem") then return end

			InfoCard.Visible = false
			InfoCard:SetAttribute("CurrentItem", nil)
		end)
	end

	Player:GetAttributeChangedSignal("Upgrade"):Connect(function()
		for _, Building: TextButton in BuildingsPage:GetChildren() do
			if not Building:IsA("TextButton") then continue end
			local Info = BuildingInfo[Building.Name]
			if not Info then
				warn(`No building info found for {Building.Name}`)
				continue
			end

			Building:WaitForChild("Locked"):WaitForChild("Upgrade").Text = "REQUIRES UPGRADE "..tostring(Info.Upgrade)
			Building.Locked.Visible = Player:GetAttribute("Upgrade") < Info.Upgrade
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.InfoCardItem then
			InfoCard.Visible = false
			InfoCard:SetAttribute("CurrentItem", nil)
		end
	end)
end

local BuildTween = nil
function UIController:ShowBuild()
	PlaySound("UIPopup")
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
	PlaySound("UIClose")
	local BuildUI = PlayerGui:WaitForChild("Build"):WaitForChild("Main")

	if BuildTween then
		BuildTween:Cancel()
	end

	BuildTween = TweenService:Create(BuildUI, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(-0.5, 0, 0.5, 0)})
	BuildTween:Play()
end

function UIController:SetupBuildUI()
	local BuildUI = PlayerGui:WaitForChild("Build"):WaitForChild("Main")
	local Pages = BuildUI:WaitForChild("Pages")
	local BuildingsPage = Pages:WaitForChild("Buildings")

	Player:SetAttribute("CurrentBuilding", nil)
	local function SetupBuilding(Building: TextButton)
		local UIScale = Building:WaitForChild("ViewportFrame"):WaitForChild("UIScale")
		Building.MouseButton1Up:Connect(function()
			PlaySound("ButtonClick")
			if Player:GetAttribute("CurrentBuilding") == Building.Name then
				Player:SetAttribute("CurrentBuilding", nil)
				return
			end

			Player:SetAttribute("CurrentBuilding", Building.Name)
		end)

		Building.MouseEnter:Connect(function()
			PlaySound("ButtonHover")
			TweenService:Create(UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.25}):Play()
		end)

		Building.MouseLeave:Connect(function()
			TweenService:Create(UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
		end)
	end

	for _, Building: TextButton in BuildingsPage:GetChildren() do
		if not Building:IsA("TextButton") then continue end
		SetupBuilding(Building)
	end

	BuildingsPage.ChildAdded:Connect(function(Child)
		if not Child:IsA("TextButton") then return end
		SetupBuilding(Child)
	end)
end

function UIController:CircularProgress(UI, CurrentTime, TotalTime)
	UtilComponent:CircularProgress(UI, CurrentTime, TotalTime)
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
	self:SetupBuildUI()

	NetworkController.OnClientEvent("UI/ShowUI", function(Data)
		local Type = Data.Type
		self:ShowAnimatedText(Data.Text or "", Data.Color and Color3.fromHex(Data.Color) or nil, Data.Duration or nil)
		if Type == "Income" then
			PlaySound("MoneyCollect", 0.5)
		end
	end)

	-- Test Progress Circle
	task.delay(5, function()
		local TF = 25
		local T1 = os.time() + TF
		local T0 = os.time()

		local DT = TF - (T1 - T0)

		self:CircularProgress(workspace.Timer.BillboardGui.Progress, DT, TF)
	end)
end

return Feather.WrapController(UIController, script)