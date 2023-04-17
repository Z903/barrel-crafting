require("globals")

data:extend(
{
  --item-group creation (for the new tab)
  {
    type = "item-group",
    name = "barrel-crafting", 
    icon = "__barrel-crafting__/graphics/empty-barrel.png",
    icon_size = 128,
    inventory_order = "f",
    order = "e"
  },
 -- creation of the subgroups for my item-group (the letter at order decides in which line my items of that subgroup are displayed)
  {
    type = "item-subgroup",
    name = "barrel-crafting-subgroup",
    group = "barrel-crafting", -- has to be the same as the name of the item-group to tell factorio that it is located in that tab
    order = "a"
  }
})

require("fixes.angels")
require("fixes.spaceexploration")


-- barrelcrafting.defaults.amount = 50
-- barrelcrafting.add_item_fix("petroleum-gas", "gas-methane-barrel")
-- barrelcrafting.add_item_fix("nitrogen-gas", "nitrogen-canister", 80, "empty-canister")
-- barrelcrafting.add_item_fix("nitrogen-fluid", "nitrogen-canister", 80, "empty-canister")
