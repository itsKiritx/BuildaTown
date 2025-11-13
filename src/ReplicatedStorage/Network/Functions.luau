local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ByteNet = require(ReplicatedStorage.Scripts.Packages.ByteNet)
local Packets = require(ReplicatedStorage.Scripts.Network.Packets) :: any


return ByteNet.defineNamespace("Functions", function()
	return Packets.definePackets({

		Packets.definePacket("FetchData", {
			Slot = ByteNet.optional(ByteNet.int8),
			FetchId = ByteNet.optional(ByteNet.int8),
		}),
		Packets.definePacket("FetchData/Return", {
			Data = ByteNet.string,
			FetchId = ByteNet.optional(ByteNet.int8),
		}),

		--< Shop >--
		Packets.definePacket("Shop/GetStock", {
			FetchId = ByteNet.optional(ByteNet.int8),
		}),
		Packets.definePacket("Shop/GetStock/Return", {
			Stock = ByteNet.string,
			FetchId = ByteNet.optional(ByteNet.int8),
		}),

		Packets.definePacket("Shop/BuyBuilding", {
			BuildingName = ByteNet.string,
			FetchId = ByteNet.optional(ByteNet.int8),
		}),
		Packets.definePacket("Shop/BuyBuilding/Return", {
			Success = ByteNet.string,
			FetchId = ByteNet.optional(ByteNet.int8),
		}),

		--< Plot >--
		Packets.definePacket("Plot/PlaceBuilding", {
			Building = ByteNet.string,
			Position = ByteNet.struct({
				X = ByteNet.int32,
				Z = ByteNet.int32,
			}),

			Rotation = ByteNet.int32,
			FetchId = ByteNet.optional(ByteNet.int8),
		}),
		Packets.definePacket("Plot/PlaceBuilding/Return", {
			Success = ByteNet.string,
			FetchId = ByteNet.optional(ByteNet.int8),
		}),

		Packets.definePacket("Plot/RemoveBuilding", {
			BuildingID = ByteNet.string,
			FetchId = ByteNet.optional(ByteNet.int8),
		}),
		Packets.definePacket("Plot/RemoveBuilding/Return", {
			Success = ByteNet.string,
			FetchId = ByteNet.optional(ByteNet.int8),
		}),

	})
end)
