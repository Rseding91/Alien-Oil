data:extend(
	{
		{
			type = "item",
			name = "alien-activator",
			icon = "__Alien Oil__/graphics/activator.png",
			flags = {"goes-to-quickbar"},
			subgroup = "extraction-machine",
			order = "b[fluids]-bc[pumpjack]",
			place_result = "alien-activator",
			stack_size = 2
		},
		{
			type = "item",
			name = "alien-compass",
			icon = "__Alien Oil__/graphics/compass-icon.png",
			flags = {"goes-to-quickbar"},
			subgroup = "defensive-structure",
			order = "c[alien]",
			place_result = "alien-compass",
			stack_size = 2
		},
		{
			type = "item",
			name = "crude-oil-collected",
			icon = "__Alien Oil__/graphics/dodecahedron.png",
			subgroup = "extraction-machine",
			order = "b[fluids]-bd[pumpjack]",
			flags = {"goes-to-quickbar"},
			stack_size = 1
		}
	}
)