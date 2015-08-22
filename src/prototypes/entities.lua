data:extend(
	{
		{
			type = "container",
			name = "alien-activator",
			flags = {"placeable-neutral", "player-creation", "placeable-off-grid"},
			collision_box = {{-0, 0}, {0, 0}},
			selection_box = {{-0, 0}, {0, 0}},
			minable = {hardness = 0.2, mining_time = 0.5, result = "alien-activator"},
			max_health = 150,
			drawing_position = {0.5, 0.5},
			inventory_size = 1,
			icon = "__Alien Oil__/graphics/activator.png",
			picture =
			{
				filename = "__Alien Oil__/graphics/activator.png",
				width = 32,
				height = 32,
				priority = "extra-high",
				shift = {0, 0}
			}
		},
		{
			type = "container",
			name = "alien-compass",
			flags = {"placeable-neutral", "player-creation", "placeable-off-grid"},
			collision_box = {{-0, 0}, {0, 0}},
			selection_box = {{-0, 0}, {0, 0}},
			minable = {hardness = 0.2, mining_time = 0.5, result = "alien-compass"},
			max_health = 150,
			drawing_position = {0.5, 0.5},
			inventory_size = 1,
			icon = "__Alien Oil__/graphics/compass.png",
			picture =
			{
				filename = "__Alien Oil__/graphics/compass.png",
				width = 64,
				height = 64,
				priority = "extra-high",
				shift = {0, 0}
			}
		},
		{
			type = "smoke",
			name = "alien-poison-cloud",
			flags = {"not-on-map", "placeable-off-grid"},
			show_when_smoke_off = true,
			animation =
			{
				filename = "__base__/graphics/entity/cloud/cloud-45-frames.png",
				priority = "low",
				width = 256,
				height = 256,
				frame_count = 45,
				animation_speed = 3,
				line_length = 7,
				scale = 0.75,
			},
			slow_down_factor = 0,
			wind_speed_factor = 0,
			cyclic = true,
			duration = 60 * 2,
			fade_away_duration =  60,
			spread_duration = 10,
			color = { r = 0.9, g = 0.2, b = 0.9 },
			action =
			{
				type = "direct",
				action_delivery =
				{
					type = "instant",
					target_effects =
					{
						type = "nested-result",
						action =
						{
							type = "area",
							perimeter = 2,
							entity_flags = {"breaths-air"},
							action_delivery =
							{
								type = "instant",
								target_effects =
								{
									type = "damage",
									damage = {amount = 20, type = "poison"}
								}
							}
						}
					}
				}
			},
			action_frequency = 15
		},
		{
			type = "smoke",
			name = "alien-poison-cloud-tiny",
			flags = {"not-on-map", "placeable-off-grid"},
			show_when_smoke_off = true,
			animation =
			{
				filename = "__base__/graphics/entity/cloud/cloud-45-frames.png",
				priority = "low",
				width = 256,
				height = 256,
				frame_count = 45,
				animation_speed = 3,
				line_length = 7,
				scale = 0.2,
			},
			slow_down_factor = 0,
			wind_speed_factor = 0,
			cyclic = true,
			duration = 60,
			fade_away_duration =  60,
			spread_duration = 10,
			color = { r = 0.9, g = 0.2, b = 0.9 },
			action =
			{
				type = "direct",
				action_delivery =
				{
					type = "instant",
					target_effects =
					{
						type = "nested-result",
						action =
						{
							type = "area",
							perimeter = 0.5,
							entity_flags = {"breaths-air"},
							action_delivery =
							{
								type = "instant",
								target_effects =
								{
									type = "damage",
									damage = {amount = 20, type = "poison"}
								}
							}
						}
					}
				}
			},
			action_frequency = 15
		},
		{
			type = "smoke",
			name = "alien-destroyed-crude-oil-poison-cloud",
			flags = {"not-on-map", "placeable-off-grid"},
			show_when_smoke_off = true,
			animation =
			{
				filename = "__base__/graphics/entity/cloud/cloud-45-frames.png",
				priority = "low",
				width = 256,
				height = 256,
				frame_count = 45,
				animation_speed = 3,
				line_length = 7,
				scale = 0.55,
			},
			slow_down_factor = 0,
			wind_speed_factor = 0,
      affected_by_wind = false,
			cyclic = true,
			duration = 60 * 60 * 5,
			fade_away_duration =  60 * 60 * 3,
			spread_duration = 0,
			color = { r = 0.5, g = 0.2, b = 0.5 },
			action =
			{
				type = "direct",
				action_delivery =
				{
					type = "instant",
					target_effects =
					{
						type = "nested-result",
						action =
						{
							type = "area",
							perimeter = 1.5,
							entity_flags = {"breaths-air"},
							action_delivery =
							{
								type = "instant",
								target_effects =
								{
									type = "damage",
									damage = {amount = 50, type = "poison"}
								}
							}
						}
					}
				}
			},
			action_frequency = 30
		},
		{
			type = "smoke",
			name = "alien-standard-smoke",
			flags = {"not-on-map"},
			show_when_smoke_off = true,
			animation =
			{
				filename = "__base__/graphics/entity/smoke/smoke.png",
				priority = "high",
				width = 88,
				height = 78,
				frame_count = 39,
				animation_speed = 12,
				line_length = 7
			}
		},
		{
			type = "smoke",
			name = "alien-poison-cloud-corrosive",
			flags = {"not-on-map", "placeable-off-grid"},
			show_when_smoke_off = true,
			animation =
			{
				filename = "__base__/graphics/entity/cloud/cloud-45-frames.png",
				priority = "low",
				width = 256,
				height = 256,
				frame_count = 45,
				animation_speed = 3,
				line_length = 7,
				scale = 0.75,
			},
			slow_down_factor = 0,
			wind_speed_factor = 0,
			cyclic = true,
			duration = 60 * 2,
			fade_away_duration =  60,
			spread_duration = 10,
			color = { r = 0.9, g = 0.4, b = 0.9 },
			action =
			{
				type = "direct",
				action_delivery =
				{
					type = "instant",
					target_effects =
					{
						type = "nested-result",
						action =
						{
							type = "area",
							perimeter = 2,
							action_delivery =
							{
								type = "instant",
								target_effects =
								{
									type = "damage",
									damage = {amount = 10, type = "poison"}
								}
							}
						}
					}
				}
			},
			action_frequency = 30
		}
	}
)