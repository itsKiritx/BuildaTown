local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Containers = require(ReplicatedStorage.Scripts.Packages.Containers)

local DataService = require(ServerScriptService.Scripts.Services.DataService)
local NetworkService = require(ServerScriptService.Scripts.Services.NetworkService)
local RewardService = require(ServerScriptService.Scripts.Services.RewardService)
local ItemComponent = require(ReplicatedStorage.Scripts.Components.ItemComponent)
local UtilComponent = require(ReplicatedStorage.Scripts.Components.UtilComponent)

local Plots = Containers.Plots
local PlotsService = {
	ActivePlots = {
		--["Plot_1"] = true
	},
}

local function GetEmptyPlot()
	for i = 1, 6 do
		local Plot = Plots:FindFirstChild(`Plot_{i}`)
		if Plot and not PlotsService.ActivePlots[Plot.Name] then
			return Plot
		end
	end
end

function PlotsService:GetPlayerPlot(Player: Player)
	return Containers.Plots:FindFirstChild(`Plot_{Player:GetAttribute("Plot")}`)
end

function PlotsService:GetBuildingByID(Plot, ID)
	local BuildingsFolder = Plot:FindFirstChild("Buildings")
	if not BuildingsFolder then return end

	for _, Building in BuildingsFolder:GetChildren() do
		if Building:IsA("Model") and Building:GetAttribute("ID") == ID then
			return Building
		end
	end
end

function PlotsService:ValidatePosition(Player: Player, Building: string, Position: Vector3, Rotation: number)
	local Plot = self:GetPlayerPlot(Player)
	if not Plot then
		warn(`Player {Player.Name} has no plot assigned.`)
		return "No plot assigned"
	end

	local BuildingsFolder = Plot:FindFirstChild("Buildings")
	local PlotOutline: Part = Plot:FindFirstChild("Plot")

	local PlotNumber = Player:GetAttribute("Plot")
	local isOddPlot = (PlotNumber % 2) == 1
	local isEvenPlot = not isOddPlot

	local PlotCenter = CFrame.new(PlotOutline.Position.X, 0, PlotOutline.Position.Z)
	local RotationAngles = {0, 90, 180, 270}
	local RotationAngle = (RotationAngles[Rotation] or 0) + (isEvenPlot and 180 or 0)
	if RotationAngle >= 360 then
		RotationAngle = RotationAngle - 360
	end

	local ActualPosX = Position.X * (isEvenPlot and -1 or 1)
	local ActualPosZ = Position.Z * (isEvenPlot and -1 or 1)

	local BuildingModel: Model = ReplicatedStorage.Assets.Buildings:FindFirstChild(Building)
	local CF = PlotCenter * CFrame.new(ActualPosX, BuildingModel.PrimaryPart.Size.Y / 2, ActualPosZ) * CFrame.Angles(0, math.rad(RotationAngle), 0)

	-- Check for overlaps
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {Plot.Buildings}
	overlapParams.FilterType = Enum.RaycastFilterType.Include

	local ColissionSize = BuildingModel.PrimaryPart.Size - Vector3.new(0.05, 0.05, 0.05)
	local overlappingParts = workspace:GetPartBoundsInBox(CF, ColissionSize, overlapParams)
	if #overlappingParts > 0 then
		warn("Building position overlaps with existing buildings")
		return false
	end

	-- Check within plot bounds
	local Size = BuildingModel.PrimaryPart.Size
	local Rotation = RotationAngles[Rotation] or 0

	local RotatedSize = if Rotation == 90 or Rotation == 270
	then Vector3.new(Size.Z, Size.Y, Size.X)
	else Size

	local halfSize = RotatedSize / 2
	local plotPos = PlotOutline.Position
	local plotSize = PlotOutline.Size

	local minX = plotPos.X - plotSize.X/2 + halfSize.X
	local maxX = plotPos.X + plotSize.X/2 - halfSize.X
	local minZ = plotPos.Z - plotSize.Z/2 + halfSize.Z
	local maxZ = plotPos.Z + plotSize.Z/2 - halfSize.Z

	local BuildingPosition = CF.Position
	if BuildingPosition.X < minX or BuildingPosition.X > maxX or BuildingPosition.Z < minZ or BuildingPosition.Z > maxZ then
		warn("Building position out of plot bounds")
		return false
	end

	return true
end

function PlotsService:PlaceBuilding(Player: Player, Building: string, Position: Vector3, Rotation: number)
	local PlayerData = DataService:GetPlayerData(Player, 0)
	local SlotData = DataService:GetPlayerData(Player)
	local Inventory = SlotData.Inventory
	local PlotData = SlotData.Plot

	local Plot = self:GetPlayerPlot(Player)
	if not Plot then
		warn(`Player {Player.Name} has no plot assigned.`)
		return "No plot assigned"
	end

	local BuildingsFolder = Plot:FindFirstChild("Buildings")
	local PlotOutline: Part = Plot:FindFirstChild("Plot")

	local PlotNumber = Player:GetAttribute("Plot")
	local isOddPlot = (PlotNumber % 2) == 1
	local isEvenPlot = not isOddPlot

	local PlotCenter = CFrame.new(PlotOutline.Position.X, 0, PlotOutline.Position.Z)
	local RotationAngles = {0, 90, 180, 270}
	local RotationAngle = (RotationAngles[Rotation] or 0) + (isEvenPlot and 180 or 0)
	if RotationAngle >= 360 then
		RotationAngle = RotationAngle - 360
	end

	local BuildingModel: Model = ReplicatedStorage.Assets.Buildings:FindFirstChild(Building)
	if not BuildingModel then
		warn(`Building model {Building} not found in assets.`)
		return "Building model not found"
	end

	local BuildingInfo = ItemComponent:GetItemInfo(Building)
	if not BuildingInfo then
		warn(`No build info found for building {Building}`)
		return "No build info"
	end

	local BuildData = PlotData.Buildings[tostring(Position.X)..","..tostring(Position.Z)]
	if not BuildData then
		warn(`No build data found for building {Building} at position X:{Position.X} Z:{Position.Z}`)
		return
	end

	local ActualPosX = Position.X * (isEvenPlot and -1 or 1)
	local ActualPosZ = Position.Z * (isEvenPlot and -1 or 1)

	local BuildingClone = BuildingModel:Clone()
	local CF = PlotCenter * CFrame.new(ActualPosX, BuildingClone.PrimaryPart.Size.Y / 2, ActualPosZ) * CFrame.Angles(0, math.rad(RotationAngle), 0)
	BuildingClone:PivotTo(CF)
	BuildingClone.Parent = BuildingsFolder

	BuildingClone.PrimaryPart.CanCollide = true
	BuildingClone.PrimaryPart.CanQuery = true
	BuildingClone.PrimaryPart.CanTouch = true

	local Key = tostring(Position.X)..","..tostring(Position.Z)
	BuildingClone:SetAttribute("ID", Key)
	BuildingClone:SetAttribute("Plot", PlotNumber)

	local ActivePlot = self.ActivePlots[Plot.Name]
	ActivePlot.Buildings[BuildingClone] = {
		Name = Building,
		Key = Key,
	}

	-- Set Income
	local function StartIncome()
		BuildData.LastIncomeTime = os.time()

		local CurrentIncome = BuildData.Money or 0
		local UI = ReplicatedStorage.Assets.UI.Income:Clone()
		UI.CFrame = BuildingClone.PrimaryPart.CFrame * CFrame.new(0, (BuildingClone.PrimaryPart.Size.Y / 2) + 2, 0)
		UI.BillboardGui.Title.Text = BuildingInfo.Name
		UI.BillboardGui.Income.Text = "$"..UtilComponent:FormatNumber(BuildingInfo.Income).."/sec"
		UI.BillboardGui.Money.Text = "$"..UtilComponent:FormatNumber(CurrentIncome)

		UI.Name = Key
		UI.Parent = Containers.UI

		BuildingClone:SetAttribute("Money", CurrentIncome)

		BuildingClone:GetAttributeChangedSignal("Money"):Connect(function()
			local NewMoney = BuildingClone:GetAttribute("Money") or 0
			UI.BillboardGui.Money.Text = "$"..UtilComponent:FormatNumber(NewMoney)
		end)

		local ProximityPrompt: ProximityPrompt = BuildingClone:FindFirstChild("ProximityPrompt") or Instance.new("ProximityPrompt")
		ProximityPrompt.ActionText = "Collect"
		ProximityPrompt.ObjectText = BuildingInfo.Name
		ProximityPrompt.HoldDuration = 0.25
		ProximityPrompt.MaxActivationDistance = 10
		ProximityPrompt.Parent = BuildingClone

		ProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
			if TriggeringPlayer ~= Player then -- TODO: Stealing mechanics
				return
			end

			local MoneyAmount = BuildingClone:GetAttribute("Money") or 0
			if MoneyAmount <= 0 then
				return
			end

			RewardService:GiveMoney(Player, MoneyAmount)
			BuildData.Money = 0
			BuildingClone:SetAttribute("Money", 0)

			NetworkService:FireClient("UI/ShowUI", TriggeringPlayer, {
				Type = "Income",
				Text = "Collected: $"..UtilComponent:FormatNumber(MoneyAmount),
				Duration = 3,
			})
		end)

		BuildingClone:SetAttribute("IncomeReady", true)
	end

	-- Set Timer
	if os.time() < BuildData.TimeBuilt then
		local BuildTime = BuildingInfo.BuildTime
		local TimeBuilt = BuildData.TimeBuilt
		local TimeRemaining = BuildTime - (TimeBuilt - os.time())

		local TimerUI = ReplicatedStorage.Assets.UI.Timer:Clone()
		TimerUI.CFrame = BuildingClone.PrimaryPart.CFrame * CFrame.new(0, (BuildingClone.PrimaryPart.Size.Y / 2) + 2, 0)
		TimerUI.Name = Key
		TimerUI.Parent = Containers.UI

		local Timer: Tween = UtilComponent:CircularProgress(TimerUI.BillboardGui.Progress, TimeRemaining, BuildTime)
		Timer.Completed:Connect(function()
			TimerUI:Destroy()
			StartIncome()
		end)
	else
		StartIncome()
	end

	return BuildingClone
end

function PlotsService:AddBuilding(Player: Player, Building: string, Position: Vector3, Rotation: number)
	local SlotData = DataService:GetPlayerData(Player)
	local Inventory = SlotData.Inventory

	if not ItemComponent:IsItemOwned(Inventory, Building) then
		warn(`Player {Player.Name} does not own building {Building}`)
		return "Building not owned"
	end

	local Plot = self:GetPlayerPlot(Player)
	if not Plot then
		warn(`Player {Player.Name} has no plot assigned.`)
		return "No plot assigned"
	end

	if not SlotData.Inventory.Buildings[Building] or SlotData.Inventory.Buildings[Building] <= 0 then
		warn(`Player {Player.Name} has no remaining units of building {Building} to place.`)
		return "No remaining building units"
	end

	local BuildingsFolder = Plot:FindFirstChild("Buildings")
	local PlotOutline = Plot:FindFirstChild("Plot")

	local BuildingModel: Model = ReplicatedStorage.Assets.Buildings:FindFirstChild(Building)
	if not BuildingModel then
		warn(`Building model {Building} not found in assets.`)
		return "Building model not found"
	end

	local BuildInfo = ItemComponent:GetItemInfo(Building)
	if not BuildInfo then
		warn(`No build info found for building {Building}`)
		return "No build info"
	end

	local PlotNumber = Player:GetAttribute("Plot")
	local isOddPlot = (PlotNumber % 2) == 1
	local isEvenPlot = not isOddPlot

	local StandardPosX = (PlotOutline.Position.X - Position.X) * (isOddPlot and -1 or 1)
	local StandardPosZ = (PlotOutline.Position.Z - Position.Z) * (isOddPlot and -1 or 1)

	local StandardRotation = (isEvenPlot and Rotation + 2) or Rotation
	if StandardRotation > 4 then
		StandardRotation = StandardRotation - 4
	end

	SlotData.Plot = SlotData.Plot or {}
	SlotData.Plot.Buildings = SlotData.Plot.Buildings or {}

	local Key = tostring(StandardPosX)..","..tostring(StandardPosZ)
	if SlotData.Plot.Buildings[Key] then
		warn(`A building already exists at position X:{StandardPosX} Z:{StandardPosZ} for player {Player.Name}`)
		return "Building already exists at this position"
	end

	if not self:ValidatePosition(Player, Building, Vector3.new(StandardPosX, 0, StandardPosZ), StandardRotation) then
		warn(`Invalid position for building {Building} at X:{StandardPosX} Z:{StandardPosZ}`)
		return "Invalid position"
	end

	SlotData.Inventory.Buildings[Building] = (SlotData.Inventory.Buildings[Building] or 0) - 1

	SlotData.Plot.Buildings[Key] = {
		Building = Building,
		Position = {X = StandardPosX, Z = StandardPosZ},
		Rotation = StandardRotation,
		TimeBuilt = os.time() + BuildInfo.BuildTime,

		Money = 0,
		LastIncomeTime = os.time(),
	}

	NetworkService:FireClient("Inventory/Update", Player, {
		Inventory = HttpService:JSONEncode(SlotData.Inventory),
	})

	Player:SetAttribute("CurrentBuilding", nil)
	self:PlaceBuilding(Player, Building, Vector3.new(StandardPosX, 0, StandardPosZ), StandardRotation)

	return "Success"
end

function PlotsService:RemoveBuilding(Player: Player, BuildingID: string)
	local SlotData = DataService:GetPlayerData(Player)

	local Plot = self:GetPlayerPlot(Player)
	if not Plot then
		warn(`Player {Player.Name} has no plot assigned.`)
		return "No plot assigned"
	end

	local Building = self:GetBuildingByID(Plot, BuildingID)
	if not Building then
		warn(`Building with ID {BuildingID} not found on player {Player.Name}'s plot.`)
		return "Building not found"
	end

	local BuildingInfo = ItemComponent:GetItemInfo(Building.Name)
	if not BuildingInfo then
		warn(`No build info found for building {Building.Name}`)
		return "No build info"
	end

	local ActivePlot = self.ActivePlots[Plot.Name]

	local MoneyAmount = Building:GetAttribute("Money") or 0
	if MoneyAmount > 0 then
		RewardService:GiveMoney(Player, MoneyAmount / 2)

		NetworkService:FireClient("UI/ShowUI", Player, {
			Type = "Income",
			Text = "Collected: $"..UtilComponent:FormatNumber(MoneyAmount / 2).." (50% Refund)",
			Duration = 3,
		})
	end

	ActivePlot.Buildings[Building] = nil
	for _, v in Containers.UI:GetChildren() do
		if v.Name == BuildingID then
			v:Destroy()
		end
	end

	SlotData.Inventory = SlotData.Inventory or {}
	SlotData.Inventory.Buildings = SlotData.Inventory.Buildings or {}
	SlotData.Inventory.Buildings[Building.Name] = (SlotData.Inventory.Buildings[Building.Name] or 0) + 1

	SlotData.Plot = SlotData.Plot or {}
	SlotData.Plot.Buildings = SlotData.Plot.Buildings or {}
	SlotData.Plot.Buildings[BuildingID] = nil

	NetworkService:FireClient("Inventory/Update", Player, {
		Inventory = HttpService:JSONEncode(SlotData.Inventory),
	})

	Building:Destroy()

	return "Success"
end

function PlotsService:LoadPlot(Player: Player)
	local Plot = GetEmptyPlot()
	if not Plot then
		warn("No empty plots available, retrying!")
		repeat
			task.wait(1)
			Plot = GetEmptyPlot()
		until Plot
	end

	local PlotID = tonumber(Plot.Name:sub(6))
	self.ActivePlots[Plot.Name] = {
		Player = Player,
		Plot = PlotID,
		Buildings = {},
		Connections = {},
	}

	local PlayerData = DataService:GetPlayerData(Player, 0)
	local SlotData = DataService:GetPlayerData(Player)

	Player:SetAttribute("Plot", PlotID)
	Player:SetAttribute("Upgrade", SlotData.Stats.UpgradeLevel or 1)
	warn(`Assigned plot {PlotID} to player {Player.Name}`)

	--< Load Sign >--
	local Sign = Plot.Sign.Main.SurfaceGui.Main
	Sign.Title.Text = (Player.DisplayName or Player.Name)..`'s \n Town`
	Sign.Likes.Amount.Text = "👍 "..tostring(PlayerData.Likes or 0).." Likes"

	local UserID = Player.UserId
	local ThumbType = Enum.ThumbnailType.HeadShot
	local ThumbSize = Enum.ThumbnailSize.Size420x420
	local IconID, IsReady = Players:GetUserThumbnailAsync(UserID, ThumbType, ThumbSize)
	Sign.Icon.Image = IsReady and IconID

	local ProximityPrompt: ProximityPrompt = Plot.Sign.ProximityPrompt
	ProximityPrompt.Enabled = true
	self.ActivePlots[Plot.Name].Connections["PromptTriggered"] = ProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
		if TriggeringPlayer == Player then -- Manage Plot instead of liking

		end

		if PlayerData.Liked and PlayerData.Liked[tostring(TriggeringPlayer.UserId)] then
			warn(`Player {TriggeringPlayer.Name} has already liked this plot.`)
			return
		end

		PlayerData.Likes = (PlayerData.Likes or 0) + 1
		PlayerData.Liked = PlayerData.Liked or {}
		PlayerData.Liked[tostring(TriggeringPlayer.UserId)] = true

		Sign.Likes.Amount.Text = "👍 "..tostring(PlayerData.Likes).." Likes"
	end)

	--< Load Buildings >--
	local Buildings = SlotData.Plot.Buildings or {}
	local OfflineIncome = 0
	for _, BuildingData in Buildings do
		local BuildingInfo = ItemComponent:GetItemInfo(BuildingData.Building)
		local Income = BuildingInfo.Income * (os.time() - BuildingData.LastIncomeTime)
		warn(`Building {BuildingData.Building} generated offline income of ${Income} for player {Player.Name}`)

		BuildingData.Money += Income
		OfflineIncome += Income
		self:PlaceBuilding(Player, BuildingData.Building, Vector3.new(BuildingData.Position.X, 0, BuildingData.Position.Z), BuildingData.Rotation)
	end

	warn(`Gave offline income of ${OfflineIncome} to player {Player.Name}`)
	if OfflineIncome > 0 then
		NetworkService:FireClient("UI/ShowUI", Player, {
			Type = "Income",
			Text = `Your town generated ${UtilComponent:FormatNumber(OfflineIncome)} while you were away!`,
			Duration = 5,
		})
	end

	self.ActivePlots[Plot.Name].Connections["IncomeUpdate"] = RunService.Heartbeat:Connect(function()
		for Building, Data in self.ActivePlots[Plot.Name].Buildings do
			local BuildingInfo = ItemComponent:GetItemInfo(Building.Name)
			if not BuildingInfo then
				continue
			end

			if not Building:GetAttribute("IncomeReady") then
				continue
			end

			local BuildData = Buildings[tostring(Data.Key)]
			if not BuildData then
				continue
			end

			local CurrentTime = os.time()
			local TimeElapsed = CurrentTime - BuildData.LastIncomeTime
			if TimeElapsed >= 1 then
				local IncomeToAdd = BuildingInfo.Income * TimeElapsed
				BuildData.Money += IncomeToAdd
				BuildData.LastIncomeTime = CurrentTime

				Building:SetAttribute("Money", BuildData.Money)
			end
		end
	end)
end

function PlotsService:UnloadPlot(Player: Player)
	local plotID = Player:GetAttribute("Plot")
	if not plotID then
		warn(`Player {Player.Name} has no plot assigned.`)
		return
	end

	local plotName = `Plot_{plotID}`
	local Plot = Plots:FindFirstChild(plotName)

	--< Unload Sign >--
	local Sign = Plot.Sign.Main.SurfaceGui.Main
	Sign.Title.Text = "Empty Plot"
	Sign.Likes.Amount.Text = "👍 0 Likes"
	Sign.Icon.Image = ""

	local ProximityPrompt: ProximityPrompt = Plot.Sign.ProximityPrompt
	ProximityPrompt.Enabled = false

	for _, Connection in self.ActivePlots[plotName].Connections do
		Connection:Disconnect()
	end

	--< Unload Buildings >--
	for Building, _ in self.ActivePlots[plotName].Buildings do
		Building:Destroy()
	end

	self.ActivePlots[plotName] = nil
	warn(`Freed up plot {plotID} from player {Player.Name}`)
end

function PlotsService:FeatherStart()
	warn("Starting PlotsService")

	NetworkService.OnServerInvoke("Plot/PlaceBuilding", function(Data, Player)
		return {Success = self:AddBuilding(Player, Data.Building, Data.Position, Data.Rotation)}
	end)

	NetworkService.OnServerInvoke("Plot/RemoveBuilding", function(Data, Player)
		return {Success = self:RemoveBuilding(Player, Data.BuildingID)}
	end)
end

return Feather.WrapService(PlotsService, script)
