local category = "barrel-crafting"
local subgroup = "barrel-crafting-subgroup"

local fluids = data.raw["fluid"]

function has_fluid(results)
  if not (results) then return false end
  for i,  result in pairs (results) do
    if (result.type) and (result.type == "fluid") then 
      return true 
    end
  end
  return false
end

function is_fluid_recipe(recipe)
  if recipe.normal then
    if has_fluid(recipe.normal.ingredients) or has_fluid(recipe.normal.results) then
      return true
    end
  elseif recipe.expensive then
    if has_fluid(recipe.expensive.ingredients) or has_fluid(recipe.expensive.results) then
      return true
    end
  else
    if has_fluid(recipe.ingredients) or has_fluid(recipe.results) then
      return true
    end
  end
end

local recipes_with_fluids_names_list = {}

for recipe_name, recipe_prot in pairs (data.raw.recipe) do
  if not string.find(recipe_name, "-barrel") and is_fluid_recipe(recipe_prot) then
    log ("added: " .. recipe_name)
    recipes_with_fluids_names_list[#recipes_with_fluids_names_list+1] = recipe_name
  end
end

function is_item_exists(item_name) 
  for item_prot_name, item_prot in pairs (data.raw.item) do
    if item_prot_name == item_name then
      return true
    end
  end
  return false
end

-- function lcm( m, n )
    -- return ( m ~= 0 and n ~= 0 ) and math.abs(m * n / gcd( m, n )) or 0
-- end

function gcd(a, b)
    if (b == 0) then
        return a
    else 
        return gcd(b, a % b)
    end
end

function get_new_factor_k(ingredients, results)
  local amounts_list = {}

  local g = nil
  for i, ingredient in pairs(ingredients) do
    if g == nil then
      g = ingredient.amount
    else
      g = gcd(g, ingredient.amount)
    end
  end
  
  for i, result in pairs(results) do
    if g == nil then
      g = result.amount
    else
      g = gcd(g, result.amount)
    end
  end

  return (g or 1)
end

function get_item_prot(item_name) 
  local item_type_list = {
    "ammo",
    "armor",
    "gun",
    "item",
    "capsule",
    "repair-tool",
    "mining-tool",
    "item-with-entity-data",
    "rail-planner",
    "tool",
    "blueprint",
    "deconstruction-item",
    "blueprint-book",
    "selection-tool",
    "item-with-tags",
    "item-with-label",
    "item-with-inventory",
    "module"
  }
  for i, item_type in pairs (item_type_list) do
    for item_prot_name, item_prot in pairs (data.raw[item_type]) do
      if item_prot_name == item_name then
        return item_prot
      end
    end
  end
  return nil
end

function get_icons(recipe)
  if recipe.icons then return true end
  if recipe.icon then 
    recipe.icons = {{icon = recipe.icon}}
    recipe.icon = nil
    return true
  end
  local result_name = nil
  if recipe.result or recipe.results then
    result_name = recipe.result or recipe.results[1].name or recipe.results[1][1]
  elseif recipe.normal then
    result_name = recipe.normal.result or recipe.normal.results[1].name or recipe.normal.results[1][1]
  elseif recipe.expensive then
    result_name = recipe.expensive.result or recipe.expensive.results[1].name or recipe.expensive.results[1][1]
  end
  
  -- log ("Log1: [".. recipe.name .. "] = " .. result_name)
  if result_name then
    -- log ('get_icons: result_name is '..result_name)
    local item_prot = get_item_prot(result_name) or data.raw.fluid[result_name]
    -- log ("Log2: [".. recipe.name .. "] = " .. result_name .. " " .. serpent.block(item_prot))
    
    if item_prot then
      -- log ('result_name: '..result_name)
      recipe.icons = item_prot.icons or {{icon = item_prot.icon}}
      recipe.icon_size = item_prot.icon_size
    else
      log ('error: no item_prot for recipe '.. serpent.block(recipe))
    end
  else
    log ('error: no result_name by recipe: '..recipe.name)
    log (serpent.block (recipe))
  end
  -- log ("Log: [".. recipe.name .. "] = " .. serpent.block(recipe))
end

local locale = " "
local new_line = [[ 
 ]]
locale = locale .. new_line


for _, recipe_name in pairs (recipes_with_fluids_names_list) do
  local new_recipe = util.table.deepcopy(data.raw.recipe[recipe_name])
  new_recipe.name = "bc-"..recipe_name
  
  new_recipe.allow_decomposition = false
  -- new_recipe.category = category
  new_recipe.subgroup = subgroup
  new_recipe.enabled = true
  new_recipe.main_product = nil
  new_recipe.hide_from_player_crafting = true
  new_recipe.allow_as_intermediate = false
  
  locale = locale .. new_recipe.name .. new_line
  local factor_k = 50
  
  local icons_successful = get_icons(new_recipe) -- bool
  
  
  -- multiply ingredients by factor_k
  for _, r in pairs({new_recipe, new_recipe.normal, new_recipe.expensive}) do
    if r then
      local need_barrels = 0
    
      -- changing production time
      if r.energy_required then
        r.energy_required = r.energy_required * factor_k
      else
        r.energy_required = 0.5 * factor_k 
      end
    
      if r.ingredients then
        for i, ingredient in pairs(r.ingredients) do
          -- normalize ingredients
          -- log ('error: ' .. new_recipe.name .. " " .. serpent.block(ingredient))
          if not ingredient.amount then
            ingredient = {name = ingredient[1], amount = ingredient[2]}
            r.ingredients[i] = ingredient
          end
          -- log ('error: ' .. new_recipe.name .. " " .. serpent.block(ingredient))
          ingredient.amount = ingredient.amount * factor_k

          -- replace with barrels
           if (ingredient.type) and (ingredient.type == "fluid") and is_item_exists(ingredient.name .. "-barrel") then
            need_barrels = need_barrels - ingredient.amount / factor_k
            r.ingredients[i] = {name = ingredient.name .. "-barrel", amount = ingredient.amount / factor_k, type = "item"}
          end
        end
      else
        r.ingredients = {}
      end

      -- normalize 'result' into 'results'
      if r.result then
        r.results = {{name = r.result, amount = r.result_count or 1}}
        r.result = nil
        r.result_count = nil
      end
    
      -- multiply results by factor_k
      if r.results then
        -- here can be items and/or fluids
        for i, result in pairs(r.results) do
          -- normalize ingredients
          if (result.amount_min) and (result.amount_max) then
            result.amount = math.floor((0.5 * result.amount_min + 0.5 * result.amount_max) * factor_k + 0.5) -- here was error
            result.amount_min = nil
            result.amount_max = nil
          elseif not result.amount then
            result = {name = result[1], amount = result[2] * factor_k}
            r.results[i] = result
          else
            result.amount = result.amount * factor_k
          end
        
          -- replace with barrels
          if (result.type) and (result.type == "fluid") and is_item_exists(result.name .. "-barrel") then
            need_barrels = need_barrels + result.amount / factor_k
            r.results[i] = {name = result.name .. "-barrel", amount = result.amount / factor_k, type = "item"}
          end
        end
      else
        r.results = {}
      end
    
      -- log ('error: ' .. new_recipe.name .. " " .. serpent.block(r.ingredients))
      -- rescale ingredients based on new k
      local new_factor_k = get_new_factor_k(r.ingredients, r.results)
      for i, ingredient in pairs (r.ingredients) do
        ingredient.amount = ingredient.amount / new_factor_k
      end
    
      -- rescale results based on new k
      for i, result in pairs (r.results) do
        if result.amount then
          result.amount = result.amount / new_factor_k
        elseif result.amount_max and result.amount_min then
          result.amount_max = result.amount_max / new_factor_k
          result.amount_min = result.amount_min / new_factor_k
        else
          log ("error on: [".. new_recipe.name .. "] = " .. serpent.block(r))
        end
      end
    
      -- rescale energy based on new k
      r.energy_required = r.energy_required / new_factor_k
      need_barrels = need_barrels / new_factor_k
    
      if need_barrels > 0 then
        -- add ingredient
        table.insert(r.ingredients, {name = "empty-barrel", amount = need_barrels})
      elseif need_barrels < 0 then
        -- add result
        table.insert(r.results, {name = "empty-barrel", amount = -need_barrels})
      end
    end
  end
  
  -- Look for technology that unlocks this 
  for _, tech in pairs(data.raw.technology) do
    for _,effect in pairs(tech.effects or {}) do
      if effect.type and effect.type == "unlock-recipe" and effect.recipe == recipe_name then
        new_recipe.enabed = false
        table.insert(tech.effects, {type = "unlock-recipe", recipe = new_recipe.name})
      end
    end
  end
  
  -- log ("new_recipe: [".. new_recipe.name .. "] = " .. serpent.block(new_recipe))
  data:extend({new_recipe})
end
