local self = barrelcrafting

if mods["angelspetrochem"] then
  self.add_item_fix("petroleum-gas", "gas-methane-barrel")
  self.add_item_fix("light-oil", "liquid-fuel-oil-barrel")
  self.add_item_fix("heavy-oil", "liquid-naphtha-barrel")
  self.add_item_fix("sulfuric-acid", "liquid-sulfuric-acid-barrel")
  if mods["bobplates"] then
    if settings.startup["bobmods-plates-purewater"].value == true then
      self.add_item_fix("pure-water", "water-purified-barrel")
    end
    self.add_item_fix("oxygen", "gas-oxygen-barrel")
    self.add_item_fix("hydrogen", "gas-hydrogen-barrel")
    self.add_item_fix("chlorine", "gas-chlorine-barrel")
    self.add_item_fix("hydrogen-chloride", "gas-hydrogen-chloride-barrel")
    self.add_item_fix("ferric-chloride-solution", "liquid-ferric-chloride-solution-barrel")
    self.add_item_fix("liquid-air", "gas-compressed-air-barrel")
    self.add_item_fix("nitrogen", "gas-nitrogen-barrel")
    self.add_item_fix("nitric-acid", "liquid-nitric-acid-barrel")
    self.add_item_fix("nitrogen-dioxide", "gas-nitrogen-dioxide-barrel")
    self.add_item_fix("sulfur-dioxide", "gas-sulfur-dioxide-barrel")
    self.add_item_fix("hydrogen-sulfide", "gas-hydrogen-sulfide-barrel")
  elseif mods["bobelectronics"] then
    self.add_item_fix("ferric-chloride-solution", "liquid-ferric-chloride-solution-barrel")
  end
  if mods["bobrevamp"] then
    self.add_item_fix("dinitrogen-tetroxide", "gas-dinitrogen-tetroxide-barrel")
    self.add_item_fix("hydrogen-peroxide", "gas-hydrogen-peroxide-barrel")
    self.add_item_fix("hydrazine", "gas-hydrazine-barrel")
    if mods["bobplates"] and settings.startup["bobmods-revamp-hardmode-barrel"].value then
      self.add_item_fix("carbon-dioxide", "gas-carbon-dioxide-barrel")
      self.add_item_fix("nitric-oxide", "gas-nitrogen-monoxide-barrel")
      self.add_item_fix("nitric-dioxide", "gas-nitrogen-dioxide-barrel")
    end
  end
  if mods["bobwarfare"] then
    self.add_item_fix("glycerol", "liquid-glycerol-barrel")
  end
  if mods["bobplates"] and data.raw["fluid"]["deuterium"] then
    self.add_item_fix("heavy-water", "liquid-water-heavy-barrel")
    self.add_item_fix("deuterium", "gas-deuterium-barrel")
  end
end
