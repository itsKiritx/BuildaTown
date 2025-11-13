--!strict

local function GetOrCreateFolder(name: string, parent: Instance): Folder
	local existing = parent:FindFirstChild(name)
	if existing then
		assert(existing:IsA("Folder"), string.format(
			"Expected '%s' to be a 'Folder' but got '%s'",
			existing:GetFullName(),
			existing.ClassName
		))
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local World = GetOrCreateFolder("World", workspace)

return {
	World = World,
	Entities = GetOrCreateFolder("Entities", World),
	NPCs = GetOrCreateFolder("NPCs", World),
	Plots = GetOrCreateFolder("Plots", World),
	BuildPreview = GetOrCreateFolder("BuildPreview", World),
	Debris = GetOrCreateFolder("Debris", World),
	UI = GetOrCreateFolder("UI", World),
}
