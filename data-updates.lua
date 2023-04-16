local category = "barrel-crafting"
local subgroup = "barrel-crafting-subgroup"

-- Load functions --
local self = barrelcrafting
local round = self.fn.round
local lcm = self.fn.lcm
local gcd = self.fn.gcd
local all = self.fn.all
local any = self.fn.any
local first = barrelcrafting.fn.first
local sum_by = barrelcrafting.fn.sum_by
local count_by = barrelcrafting.fn.count_by

local item_type = barrelcrafting.fn.item_type
local is_type_fluid = self.fn.is_type_fluid
local is_type_item = barrelcrafting.fn.is_type_item
local copy_recipe_ingredients = barrelcrafting.fn.copy_recipe_ingredients
local copy_recipe_results     = barrelcrafting.fn.copy_recipe_results
local normalize_recipe        = barrelcrafting.fn.normalize_recipe

local blocked_recipes = barrelcrafting.blocked_recipes
local item_fixes      = barrelcrafting.item_fixes

-- log("barrel fixes: " .. serpent.block(barrelcrafting, {nocode = true}))

-- Factorio Helpers --

function get_first_recipe_result_name(recipe)
  if recipe.main_product then
    return recipe.main_product
  elseif recipe.result or recipe.results then
    return recipe.result or recipe.results[1].name or recipe.results[1][1]
  elseif recipe.normal then
    return recipe.normal.result or recipe.normal.results[1].name or recipe.normal.results[1][1]
  elseif recipe.expensive then
    return recipe.expensive.result or recipe.expensive.results[1].name or recipe.expensive.results[1][1]
  end
  return nil
end

function get_prot_by_name(item_name, types)
  for _, item_type in ipairs(types) do
    for item_prot_name, item_prot in pairs(data.raw[item_type]) do
      if item_prot_name == item_name then
        return item_prot
      end
    end
  end
  return nil
end

function get_item_prot(item_name) 
  return get_prot_by_name(item_name, {
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
    "module",
    "fluid"
  })
end

function is_item_exists(item_name) 
  if get_prot_by_name(item_name, {"item"}) then
    return true
  end
  return false
end

function map_fluid_to_item_name(item_proto)
  if item_proto and barrelcrafting.item_fixes[item_proto.name] and is_item_exists(barrelcrafting.item_fixes[item_proto.name].full_item) then
    return barrelcrafting.item_fixes[item_proto.name]
--  elseif is_type_fluid(item_proto) and is_item_exists(item_proto.name .. "-barrel") then
--    return { name = item_proto.name .. "-barrel", amount = self.defaults.amount, empty_item = self.defaults.empty_item}
  end
  return nil
end

function is_fluid_recipe(recipe)
  for _, r in pairs({recipe.normal, recipe.expensive, recipe}) do
    if r then
      if any(r.ingredients, map_fluid_to_item_name) or any(r.results, map_fluid_to_item_name) then
        return true
      end
    end
  end
  return false
end

function get_new_factor_k(old_k, arg)
  local k = nil
  for _,ingredients in ipairs(arg) do
    for i, ingredient in pairs(ingredients) do
      if k == nil then
        k = ingredient.amount
      else
        k = gcd(k, ingredient.amount)
      end
    end
  end
  k = (k or 1)
  
  -- update new k to be "around" old k if we can
  local temp = round(k / old_k)
  if temp < 1 then
    temp = 1
  end
  return k / temp
end

function set_icons(recipe)
  if recipe.icons then return true end
  if recipe.icon then 
    recipe.icons = {{icon = recipe.icon}}
    recipe.icon = nil
    return true
  end
  local result_name = get_first_recipe_result_name(recipe)
  
  -- log("Log1: [".. recipe.name .. "] = " .. result_name)
  if result_name then
    -- log('set_icons: result_name is '..result_name)
    local item_prot = get_item_prot(result_name)
    -- or data.raw.fluid[result_name]
    -- log("Log2: [".. recipe.name .. "] = " .. result_name .. " " .. serpent.block(item_prot))
    
    if item_prot then
      -- log('result_name: '..result_name)
      recipe.icons = item_prot.icons or {{icon = item_prot.icon}}
      recipe.icon_size = item_prot.icon_size
    else
      -- log('error: no item_prot for recipe '.. serpent.block(recipe))
    end
  else
    -- log('error: no result_name by recipe: '..recipe.name)
    -- log(serpent.block (recipe))
  end
  -- log("Log: [".. recipe.name .. "] = " .. serpent.block(recipe))
end

-- Get a localised_name
-- https://wiki.factorio.com/Tutorial:Localisation#Default_Behavior(s)_for_finding_an_Unspecified_Localised_String
function get_localised_name(recipe)
  if recipe.localised_name ~= nil then
    return recipe.localised_name
  end
  local iproto = get_item_prot(get_first_recipe_result_name(recipe))
  if iproto and iproto.place_result then
    local iproto2 = get_item_prot(iproto.place_result)
    -- log("localised_name place_result: " .. recipe.name .. " -> " .. iproto.place_result .. " or " .. iproto.name .. " then " .. iproto2.name)
    if iproto2 then
      return iproto2.localised_name or {"entity-name." .. iproto2.name}
     else
      return iproto.localised_name or {"entity-name." .. iproto.name}
   end
  elseif iproto then
    -- log("localised_name iproto: " .. recipe.name .. " -> " .. iproto.name)
    if iproto.localised_name then
      return iproto.localised_name
    elseif is_type_fluid(iproto) then
      return {"fluid-name." .. iproto.name}
    else
      return {"item-name." .. iproto.name}
    end
  else
    -- log("localised_name else: " .. recipe.name .. " -> " .. recipe.name)
    return {"recipe-name." .. recipe.name}
  end
  -- log("localised_name: " .. serpent.block(recipe.localised_name))
end

-- Automatically find barrel like recipes

local make_recipe_key = function(a, b)
  local sortfunc = function(a, b)
    for _,i in pairs({0, 1, 2}) do
      if a[i] ~= b[i] then
        return a[i] < b[i]
      end
    end
    return false
  end
  local temp2 = function(item_protos)
    local r = {}
    for _, item_proto in pairs(item_protos) do
      table.insert(r, {item_proto.name, item_proto.type, item_proto.amount or 1})
    end
    table.sort(r, sortfunc)
    return r
  end
  return serpent.line({temp2(a), temp2(b)})
end

local fill_like = {}
local empty_like = {}

for recipe_name, recipe_prot in pairs(data.raw.recipe) do
  local r = recipe_prot
  
  -- if this is a recipe without difficulty
  if r.normal == nil and r.expensive == nil then
    local ingredients = copy_recipe_ingredients(r)
    local results     = copy_recipe_results(r)

    local items_in = count_by(ingredients, item_type)
    local items_ot = count_by(results, item_type)

    if items_in["fluid"] == 1 and items_in["item"] == 1 and items_ot["fluid"] == 0 and items_ot["item"] == 1 and first(ingredients, is_type_item).amount == 1 and first(results, is_type_item).amount == 1 then
      -- fill like recipe
      local k = make_recipe_key(ingredients, results)
      if fill_like[k] == nil then
        fill_like[k] = {}
      end
      table.insert(fill_like[k], recipe_name)
    elseif items_in["fluid"] == 0 and items_in["item"] == 1 and items_ot["fluid"] == 1 and items_ot["item"] == 1 and first(ingredients, is_type_item).amount == 1 and first(results, is_type_item).amount == 1 then
      -- empty like recipe
      local k = make_recipe_key(results, ingredients)
      if empty_like[k] == nil then
        empty_like[k] = {}
      end
      table.insert(empty_like[k], recipe_name)
    end
  end
end

for key,recipe_names in pairs(fill_like) do
  -- if there is a matching fill and empty then 
  if empty_like[key] then
    recipe_prot = data.raw.recipe[recipe_names[1]]
    local ingredients = copy_recipe_ingredients(recipe_prot)
    local results     = copy_recipe_results(recipe_prot)
    
    for _,name in pairs(recipe_names) do
      blocked_recipes[name] = true
    end
    for _,name in pairs(empty_like[key]) do
      blocked_recipes[name] = true
    end

    --log("Found Barrel " .. recipe_prot.name .. " - " .. empty_like[key].name)
    local temp = nil
    if ingredients[1].type == "fluid" then
        temp = {ingredients[1], ingredients[2], results[1]}
    else
        temp = {ingredients[2], ingredients[1], results[1]}
    end
    
    -- Dont overwrite existing entries
    if item_fixes[temp[1].name] == nil then
      barrelcrafting.add_item_fix(temp[1].name, temp[3].name, temp[1].amount,  temp[2].name)
    end

    -- log("Found Barrel: " .. tostring(temp[1].amount) .. " " .. temp[1].name .. " + " .. tostring(temp[2].amount) .. " " .. temp[2].name .. " = "  .. tostring(temp[3].amount) .. " " .. temp[3].name)
  end
end

-- Warn if we have bad fixes -- 

for name, replacement in pairs(barrelcrafting.item_fixes) do
  if not is_item_exists(replacement.full_item) then
    log("[Barrel Crafting|Warning] Item " .. name .. " full " .. replacement.full_item .. " does not exist")
  end
  if not is_item_exists(replacement.empty_item) then
    log("[Barrel Crafting|Warning] Item " .. name .. " empty " .. replacement.empty_item .. " does not exist")
  end
end

-- log("item_fixes: " .. serpent.block(item_fixes))
-- log("blocked_recipes: " .. serpent.block(blocked_recipes))
-- log("barrelcrafting: " .. serpent.block(barrelcrafting, {nocode = true}))

-- Find and add new recipes --

local make_barrel_recipe = function(recipe_prot)
  local new_recipe = util.table.deepcopy(recipe_prot)
  
  new_recipe.localised_name = get_localised_name(new_recipe)
  
  new_recipe.name = "bc-" .. new_recipe.name
  new_recipe.allow_decomposition = false
  -- new_recipe.category = category
  new_recipe.subgroup = subgroup
  -- new_recipe.enabled = true
  new_recipe.main_product = nil
  new_recipe.hide_from_player_crafting = true
  new_recipe.allow_as_intermediate = false
  
  local icons_successful = set_icons(new_recipe) -- bool

  -- Normalize recipe ingredients and results
  normalize_recipe(new_recipe)

  local factor_k = self.factor_k or self.defaults.amount

  -- multiply ingredients by factor_k
  for _, r in ipairs({new_recipe, new_recipe.normal, new_recipe.expensive}) do
    if r and r.results and r.ingredients then
      local need_items = {}

      -- changing production time
      if r.energy_required then
        r.energy_required = r.energy_required * factor_k
      else
        r.energy_required = 0.5 * factor_k 
      end
    
      for i, ingredient in pairs(r.ingredients) do
        -- log('error: ' .. new_recipe.name .. " " .. serpent.block(ingredient))
        ingredient.amount = round(ingredient.amount * factor_k)

        -- replace with barrels
        ingredient_name = map_fluid_to_item_name(ingredient)
        if ingredient_name then
          need_items[ingredient_name.empty_item] = (need_items[ingredient_name.empty_item] or 0) - ingredient.amount / ingredient_name.amount
          r.ingredients[i] = {name = ingredient_name.full_item, amount = ingredient.amount / ingredient_name.amount, type = "item"}
        end
      end

      -- multiply results by factor_k
      -- here can be items and/or fluids
      for i, result in pairs(r.results) do
        -- normalize ingredients
        if result.amount then
          result.amount = round(result.amount * factor_k)
        elseif result.amount_min ~= nil and result.amount_max ~= nil then
          result.amount = math.floor(0.5 * (result.amount_min + result.amount_max) * factor_k + 0.5)
          result.amount_min = nil
          result.amount_max = nil
        end

        -- replace with barrels
        result_name = map_fluid_to_item_name(result)
        if result_name then
          need_items[result_name.empty_item] = (need_items[result_name.empty_item] or 0) + result.amount / result_name.amount
          r.results[i] = {name = result_name.full_item, amount = result.amount / result_name.amount, type = "item"}
        end
      end
    
      -- log('error: ' .. new_recipe.name .. " " .. serpent.block(r.ingredients))
      -- rescale ingredients based on new k
      local new_factor_k = get_new_factor_k(factor_k, {r.ingredients, r.results})
      for i, ingredient in pairs(r.ingredients) do
        ingredient.amount = round(ingredient.amount / new_factor_k)
      end
    
      -- rescale results based on new k
      for i, result in pairs(r.results) do
        if result.amount then
          result.amount = result.amount / new_factor_k
        elseif result.amount_max and result.amount_min then
          result.amount_max = result.amount_max / new_factor_k
          result.amount_min = result.amount_min / new_factor_k
        end
      end
    
      -- rescale energy based on new k
      r.energy_required = r.energy_required / new_factor_k
      for name, amount in pairs(need_items) do
        local amount = amount / new_factor_k
        
        -- If we already have empty barrels then skip
        if any(r.ingredients, function(item) return item.name == name end) or any(r.results, function(item) return item.name == name end) then
          -- log("skip recipe: ".. new_recipe.name .. " barrel")
          return nil
        end

        if amount > 0 then
          -- add ingredient
          table.insert(r.ingredients, {type = "item", name = name, amount = amount, catalyst_amount = amount})
        elseif amount < 0 then
          -- add result
          table.insert(r.results, {type = "item", name = name, amount = -amount, catalyst_amount = -amount})
        end
      end
      
      -- If the recipe inputs and outputs are the same then skip
      if table.compare(
        sum_by(r.ingredients, function(item) return { item.type .. ":" .. item.name, item.amount } end),
        sum_by(r.results,     function(item) return { item.type .. ":" .. item.name, item.amount } end)
      ) then
        -- log("skip recipe: ".. new_recipe.name .. " compare")
        return nil
      end
    end
  end
  return new_recipe
end

local new_recipes = {}
for recipe_name, recipe_prot in pairs(data.raw.recipe) do
  if not blocked_recipes[recipe_name] and is_fluid_recipe(recipe_prot) then
    local new_recipe = make_barrel_recipe(recipe_prot)
    if new_recipe then

      -- Look for technology that unlocks this 
      for _, tech in pairs(data.raw.technology) do
        for _,effect in pairs(tech.effects or {}) do
          if effect.type and effect.type == "unlock-recipe" and effect.recipe == recipe_name then
            new_recipe.enabled = false
            table.insert(tech.effects, {type = "unlock-recipe", recipe = new_recipe.name})
          end
        end
      end

      -- log("old_recipe: [".. data.raw.recipe[recipe_name].name .. "] = " .. serpent.block(data.raw.recipe[recipe_name]))
      -- log("new_recipe: [".. new_recipe.name .. "] = " .. serpent.block(new_recipe))
      table.insert(new_recipes, new_recipe)
    end
  end
end

if new_recipes[1] then
  data:extend(new_recipes)
end
