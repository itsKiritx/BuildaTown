local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Containers = require(ReplicatedStorage.Scripts.Packages.Containers)

local DataService = require(ServerScriptService.Scripts.Services.DataService)

local Plots = Containers.Plots
local PlotsService = {
	ActivePlots = {},
}

local function GetEmptyPlot()
	for i = 1, 6 do
		local Plot = Plots:FindFirstChild(`Plot_{i}`)
		if Plot and not PlotsService.ActivePlots[Plot.Name] then
			return Plot
		end
	end
end

function PlotsService:LoadPlot(Player: Player)
	local Plot = GetEmptyPlot()
	if not Plot then
		warn("No empty plots available!")
		return
	end

	local PlotID = tonumber(Plot.Name:sub(6))
	self.ActivePlots[Plot.Name] = {
		Player = Player,
		Plot = PlotID,
		Connections = {},
	}

	local PlayerData = DataService:GetPlayerData(Player, 0)
	local SlotData = DataService:GetPlayerData(Player)
	warn("Slot Data:", SlotData)

	Player:SetAttribute("Plot", PlotID)
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

		print(`Player {TriggeringPlayer.Name} liked plot {PlotID}`)
	end)

	--< Load Buildings >--
	local Buildings = SlotData.Plot.Buildings or {}

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

	self.ActivePlots[plotName] = nil
	warn(`Freed up plot {plotID} from player {Player.Name}`)
end

function PlotsService:FeatherStart()
	warn("Starting PlotsService")
end

return Feather.WrapService(PlotsService, script)
