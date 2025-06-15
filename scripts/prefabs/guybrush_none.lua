local assets =
{
	Asset( "ANIM", "anim/guybrush.zip" ),
	Asset( "ANIM", "anim/ghost_guybrush_build.zip" ),
}

local skins =
{
	normal_skin = "guybrush",
	ghost_skin = "ghost_guybrush_build",
}

return CreatePrefabSkin("guybrush_none",
{
	base_prefab = "guybrush",
	type = "base",
	assets = assets,
	skins = skins, 
	skin_tags = {"GUYBRUSH", "CHARACTER", "BASE"},
	build_name_override = "guybrush",
	rarity = "Character",
})