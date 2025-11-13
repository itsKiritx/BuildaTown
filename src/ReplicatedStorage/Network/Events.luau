local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ByteNet = require(ReplicatedStorage.Scripts.Packages.ByteNet)
local Packets = require(ReplicatedStorage.Scripts.Network.Packets) :: any


return ByteNet.defineNamespace("Events", function()
	return Packets.definePackets({
		Packets.definePacket("Template", {
			Message = ByteNet.string,
			Bool = ByteNet.boolean,
			Number = ByteNet.float32,
			Integer = ByteNet.int32,
			Vector = ByteNet.vec3,
			Cframe = ByteNet.cframe,

			Table = ByteNet.optional(ByteNet.struct({
				SubMessage = ByteNet.string,
			}))
		}),

		Packets.definePacket("PlaceBuilding", {
			BuildingType = ByteNet.string,
			Position = ByteNet.struct({
				X = ByteNet.int32,
				Z = ByteNet.int32,
			}),
			Rotation = ByteNet.int32,
		}),

		-- UI
		Packets.definePacket("UI/ShowUI", {
			Type = ByteNet.string,
			Text = ByteNet.optional(ByteNet.string),
			Description = ByteNet.optional(ByteNet.string),
			Color = ByteNet.optional(ByteNet.string),
			Duration = ByteNet.optional(ByteNet.float32),
		}),

		-- Sound
		Packets.definePacket("Sound/PlaySound", {
			Path = ByteNet.string,
			Properties = ByteNet.optional(ByteNet.struct({
				Volume = ByteNet.optional(ByteNet.int8),
				Parent = ByteNet.optional(ByteNet.string),
				Play = ByteNet.optional(ByteNet.bool),
			})),
		}),

		--< Shop >--
		Packets.definePacket("Shop/Restock", {
			Stock = ByteNet.optional(ByteNet.string),
			NextStock = ByteNet.uint32,
		}),

		--< Inventory >--
		Packets.definePacket("Inventory/Update", {
			Inventory = ByteNet.optional(ByteNet.string),
		}),

		--< Plot >--
		Packets.definePacket("Plot/SetTimer", {
			
		})
	})
end)
