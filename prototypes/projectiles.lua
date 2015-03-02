data:extend(
	{
		{
			type = "projectile",
			name = "alien-setup-detonation",
			flags = {"not-on-map"},
			acceleration = 0,
			action =
			{
				type = "direct",
				action_delivery =
				{
					type = "instant",
					target_effects =
					{
						{
							type = "nested-result",
							action =
							{
								type = "area",
								perimeter = 3,
								action_delivery =
								{
									type = "instant",
									target_effects =
									{
										{
											type = "damage",
											damage = {amount = 561, type = "explosion"}
										}
									}
								}
							}
						},
						{
							type = "nested-result",
							action =
							{
								type = "area",
								perimeter = 10,
								action_delivery =
								{
									type = "instant",
									target_effects =
									{
										{
											type = "damage",
											damage = {amount = 39, type = "explosion"}
										}
									}
								}
							}
						}
					}
				}
			},
			animation =
			{
				filename = "__Alien Oil__/graphics/null.png",
				frame_count = 1,
				frame_width = 32,
				frame_height = 32,
				priority = "high"
			},
			light = {intensity = 1, size = 4},
			smoke = capsule_smoke,
		}
	}
)