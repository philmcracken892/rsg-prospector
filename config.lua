Config = {}

Config.HoleDistance = 2.0 -- Distance to prevent digging near existing dirt piles

Config.Dig = {
    shovel = "p_shovel02x",
    anim = {"amb_work@world_human_gravedig@working@male_b@idle_a", "idle_a"},
    bone = "skel_r_hand",
    pos = {0.06, -0.06, -0.03, 270.0, 165.0, 151.0},
    duration = 15000, -- Duration in milliseconds (15 seconds)
    dirtModel = 'mp005_p_dirtpile_tall_unburied', -- Dirt pile model
    dirtPileDuration = 300000 -- Duration in milliseconds (5 minutes)
}

Config.LootTable = {
    { item = 'goldbar', chance = 10, amount = 1 },
    { item = 'goldwatch', chance = 20, amount = 2 },
    { item = 'bread', chance = 50, amount = 3 },
    { item = nil, chance = 20 } -- 20% chance to find nothing
}
