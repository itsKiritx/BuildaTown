local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Containers = require(ReplicatedStorage.Scripts.Packages.Containers)
local UtilComponent = require(ReplicatedStorage.Scripts.Components.UtilComponent)
local NetworkController = require(ReplicatedStorage.Scripts.Controllers.NetworkController)
local SoundController = require(ReplicatedStorage.Scripts.Controllers.SoundController)
local UIController = require(ReplicatedStorage.Scripts.Controllers.UIController)
local PlotController = require(ReplicatedStorage.Scripts.Controllers.PlotController)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Mouse = Player:GetMouse()

local BuildingInfo = require(ReplicatedStorage.Scripts.Info.Buildings)

local BuildController = {
	BuildUI = nil,
	CurrentPreview = nil,
	CurrentRemoval = nil,
}

local function PlaySound(Type)
	SoundController:GetSound("Build/"..Type, {
		Volume = 2,
		Parent = workspace.CurrentCamera,
		Play = true,
	})
end

function BuildController:UpdateInventory(Data)
	Data = Data or HttpService:JSONDecode(NetworkController:InvokeServer("FetchData", {}).Data)
	local Inventory = Data.Inventory or {}

	local Pages = self.BuildUI:WaitForChild("Pages")
	local BuildingsPage = Pages:WaitForChild("Buildings")
	local Template = self.BuildUI:WaitForChild("Storage"):WaitForChild("Template")

	local Buildings = Inventory.Buildings
	for Building, Quantity in Buildings do
		local Info = BuildingInfo[Building]

		local UI = BuildingsPage:FindFirstChild(Building) or Template:Clone()
		UI.Name = Building
		UI.Title.Text = Info.Name
		UI.Amount.Text = "x"..tostring(Quantity)

		local Model = ReplicatedStorage.Assets.Buildings:FindFirstChild(Building)
		if Model and not UI.ViewportFrame:FindFirstChildOfClass("Model") then
			local Clone = Model:Clone()
			Clone:PivotTo(Clone:GetAttribute("ViewportPivot"))
			Clone.Parent = UI.ViewportFrame
		end

		UI.Visible = Quantity > 0
		UI.Parent = BuildingsPage
	end
end

function BuildController:PlaceBuilding()
	local BuildingPreview = self.CurrentPreview or Containers.BuildPreview:FindFirstChildOfClass("Model")
	if not BuildingPreview then
		warn("No building preview found for placement.")
		return
	end

	local Rotation = BuildingPreview:GetAttribute("Rotation") or 1
	local PosX = BuildingPreview.PrimaryPart.Position.X
	local PosZ = BuildingPreview.PrimaryPart.Position.Z

	local Result = NetworkController:InvokeServer("Plot/PlaceBuilding", {
		Building = BuildingPreview.Name,
		Position = {X = PosX, Z = PosZ},
		Rotation = Rotation,
	})

	if Result.Success == "Success" then
		PlaySound("Place")
	else
		PlaySound("Error")
		warn("Failed to place building:", Result.Success)
	end
end

function BuildController:RemoveBuilding()
	local BuildingPreview = self.CurrentRemoval
	if not BuildingPreview then
		warn("No building preview found for placement.")
		return
	end

	local BuildingID = BuildingPreview:GetAttribute("ID")
	local Result = NetworkController:InvokeServer("Plot/RemoveBuilding", {
		BuildingID = BuildingID,
	})

	if Result.Success == "Success" then
		PlaySound("Remove")
	else
		PlaySound("Error")
		warn("Failed to remove building:", Result.Success)
	end
end

function BuildController:InitiateBuild()
	local Plot = PlotController:GetPlot()
	local PlotOutline = Plot:FindFirstChild("Plot")

	self.CurrentPreview = nil
	self.CurrentRemoval = nil
	local CurrentRotation = 0
	local RotationAngles = {0, 90, 180, 270}

	local LastPosition = nil

	local function CleanUp()
		if self.CurrentPreview then
			self.CurrentPreview:Destroy()
			self.CurrentPreview = nil
			CurrentRotation = 0
			LastPosition = nil
		end
	end

	local function Rotate()
		CurrentRotation += 1
		if CurrentRotation > #RotationAngles then
			CurrentRotation = 1
		end

		if self.CurrentPreview then
			self.CurrentPreview:SetAttribute("Rotation", CurrentRotation)
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.KeyCode == Enum.KeyCode.R then
			Rotate()
		end
	end)

	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {Plot.Buildings}
	overlapParams.FilterType = Enum.RaycastFilterType.Include

	Plot.Buildings.ChildAdded:Connect(function(Building)
		if not Building:IsA("Model") then return end

		local SelectionBox = Building:FindFirstChild("SelectionBox") or Instance.new("SelectionBox")
		SelectionBox.Adornee = Building
		SelectionBox.Parent = Building
		SelectionBox.LineThickness = 0.05
		SelectionBox.SurfaceTransparency = 0.5
		SelectionBox.Transparency = 0

		SelectionBox.Color3 = Color3.fromRGB(175, 175, 175)
		SelectionBox.SurfaceColor3 = Color3.fromRGB(175, 175, 175)

		local CurrentTool = Player:GetAttribute("CurrentTool")
		SelectionBox.Visible = (CurrentTool == "Build") or (CurrentTool == "Remove")
	end)

	local function ResetSelectionBoxes()
		for _, Building in Plot.Buildings:GetChildren() do
			if not Building:IsA("Model") then continue end
			local SelectionBox = Building:FindFirstChild("SelectionBox")
			if SelectionBox then
				SelectionBox.Color3 = Color3.fromRGB(175, 175, 175)
				SelectionBox.SurfaceColor3 = Color3.fromRGB(175, 175, 175)
			end
		end
	end

	RunService:BindToRenderStep("BuildPreview", Enum.RenderPriority.Camera.Value + 1, function()
		local CurrentTool = Player:GetAttribute("CurrentTool")
		if CurrentTool == "Remove" then
			CleanUp()

			local Target = Mouse.Target
			local Building = nil
			if Target and Target:IsDescendantOf(Plot.Buildings) then
				Building = Target:FindFirstAncestorOfClass("Model")
			end

			if not Building then
				self.CurrentRemoval = nil
				ResetSelectionBoxes()
				return
			end

			if Building and self.CurrentRemoval == Building then
				return
			end

			if Building and self.CurrentRemoval ~= Building then
				ResetSelectionBoxes()
			end

			self.CurrentRemoval = Building

			local SelectionBox = Building:FindFirstChild("SelectionBox") or Instance.new("SelectionBox")
			SelectionBox.Adornee = Building
			SelectionBox.Parent = Building
			SelectionBox.LineThickness = 0.05
			SelectionBox.SurfaceTransparency = 0.5
			SelectionBox.Transparency = 0
			SelectionBox.Visible = true

			SelectionBox.Color3 = Color3.fromRGB(255, 0, 0)
			SelectionBox.SurfaceColor3 = Color3.fromRGB(255, 0, 0)

			return
		end

		if CurrentTool ~= "Build" then
			CleanUp()
			return
		end

		local CurrentBuilding = Player:GetAttribute("CurrentBuilding")
		if not CurrentBuilding then
			CleanUp()
			return
		end

		-- Preview Logic Here
		local Model: Model = ReplicatedStorage.Assets.Buildings:FindFirstChild(CurrentBuilding)
		if not Model then
			CleanUp()
			return
		end

		if self.CurrentPreview and self.CurrentPreview.Name ~= Model.Name then
			CleanUp()
		end

		if self.CurrentPreview and self.CurrentPreview.Name == Model.Name then
			Model = self.CurrentPreview
		else
			Model = Model:Clone()
		end

		self.CurrentPreview = Model
		Model.Parent = Containers.BuildPreview

		-- Selection Box
		local SelectionBox = Model:FindFirstChild("SelectionBox") or Instance.new("SelectionBox")
		SelectionBox.Adornee = Model
		SelectionBox.Parent = Model
		SelectionBox.LineThickness = 0.05
		SelectionBox.SurfaceTransparency = 0.5
		SelectionBox.Transparency = 0
		SelectionBox.Visible = true

		-- Mouse Positioning
		local MouseX = math.floor(Mouse.Hit.Position.X)
		local MouseZ = math.floor(Mouse.Hit.Position.Z)
		local MouseY = Mouse.Hit.Position.Y

		-- Building Size
		local Size = Model.PrimaryPart.Size
		local Rotation = RotationAngles[CurrentRotation] or 0

		local RotatedSize = if Rotation == 90 or Rotation == 270
		then Vector3.new(Size.Z, Size.Y, Size.X)
		else Size

		local buildingHalfSize = RotatedSize / 2

		-- Snap to grid clamped to Plot Outline
		local plotPos = PlotOutline.Position
		local plotSize = PlotOutline.Size

		local minX = plotPos.X - plotSize.X/2 + buildingHalfSize.X
		local maxX = plotPos.X + plotSize.X/2 - buildingHalfSize.X
		local minZ = plotPos.Z - plotSize.Z/2 + buildingHalfSize.Z
		local maxZ = plotPos.Z + plotSize.Z/2 - buildingHalfSize.Z

		local clampedX = math.clamp(MouseX, minX, maxX)
		local clampedZ = math.clamp(MouseZ, minZ, maxZ)

		local clampedY = (plotPos.Y - plotSize.Y/2) + buildingHalfSize.Y

		local newCFrame = CFrame.new(clampedX, clampedY, clampedZ) * CFrame.Angles(0, math.rad(Rotation), 0)

		-- Check for collisions
		local ColissionSize = Size - Vector3.new(0.05, 0.05, 0.05)
		local overlappingParts = workspace:GetPartBoundsInBox(newCFrame, ColissionSize, overlapParams)
		if #overlappingParts > 0 then
			SelectionBox.Color3 = Color3.fromRGB(255, 0, 0)
			SelectionBox.SurfaceColor3 = Color3.fromRGB(255, 0, 0)
		else
			SelectionBox.Color3 = Color3.fromRGB(13, 105, 172)
			SelectionBox.SurfaceColor3 = Color3.fromRGB(13, 105, 172)
		end

		Model:PivotTo(newCFrame)
	end)
end

function BuildController:FeatherStart()
	print("BuildController started")
	self.BuildUI = PlayerGui:WaitForChild("Build"):WaitForChild("Main")

	task.wait(1)
	self:UpdateInventory()

	NetworkController.OnClientEvent("Inventory/Update", function(Data)
		local Inventory = HttpService:JSONDecode(Data.Inventory)
		self:UpdateInventory({Inventory = Inventory})
	end)

	self:InitiateBuild()
end

return Feather.WrapController(BuildController, script)