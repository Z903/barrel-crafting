if barrelcrafting == nil then barrelcrafting = {} end

local set_defaults
set_defaults = function(t, d)
  for k,v in pairs(d) do 
    if type(t[k]) == "table" and type(d[k]) == "table" then
      set_defaults(t[k], d[k])
    elseif type(d[k]) == "table" then
      t[k] = v
    elseif t[k] == nil then
      t[k] = v
    end
  end
end

-- Global Defaults --

set_defaults(barrelcrafting, {
  item_fixes = {},
  blocked_recipes = {},
  defaults = {
    amount = 50,
    empty_item = "empty-barrel"
  },
  add_item_fix = function(fluid, full_item, amount, empty_item)
    -- log("add_item_fix " .. tostring(fluid) .. " * " .. tostring(full_item) .. ", " .. tostring(amount))
    barrelcrafting.item_fixes[fluid] = {
      fluid = fluid,
      amount = amount or barrelcrafting.defaults.amount,
      empty_item = empty_item or barrelcrafting.defaults.empty_item,
      full_item = full_item
    }
    if barrelcrafting.factor_k == nil then
      barrelcrafting.factor_k = amount or barrelcrafting.defaults.amount
    else
      barrelcrafting.factor_k = barrelcrafting.fn.lcm(barrelcrafting.factor_k, amount or barrelcrafting.defaults.amount)
    end
  end,
  factor_k = nil,
  fn = {},
})

-- Math --

function barrelcrafting.fn.round(a)
  return math.floor(a+0.5)
end

function barrelcrafting.fn.lcm(m, n)
  -- log("lcm " .. tostring(m) .. " * " .. tostring(n))
  return ( m ~= 0 and n ~= 0 ) and math.abs(m * n / barrelcrafting.fn.gcd( m, n )) or 0
end

function barrelcrafting.fn.gcd(a, b)
  if (b == 0) then
    return a
  else 
    return barrelcrafting.fn.gcd(b, a % b)
  end
end

function barrelcrafting.fn.tobool(val)
  return (val and true) or false
end

-- Iterators --

function barrelcrafting.fn.all(obj, predicate)
  if obj then
    for _, result in pairs(obj) do
      if not predicate(result) then
        return false
      end
    end
  end
  return true
end

function barrelcrafting.fn.any(obj, predicate)
  if obj then
    for _, result in pairs(obj) do
      if predicate(result) then
        return true
      end
    end
  end
  return false
end

function barrelcrafting.fn.first(obj, predicate)
  if obj then
    for _, result in pairs(obj) do
      if predicate(result) then
        return result
      end
    end
  end
  return nil
end

function barrelcrafting.fn.count_by(obj, predicate)
  local counts = {}
  setmetatable(counts, { __index = function() return 0 end })
  if obj then
    for _, result in pairs(obj) do
      idx = predicate(result)
      if idx ~= nil then
        counts[idx] = counts[idx] + 1
      end
    end
  end
  return counts
end

function barrelcrafting.fn.sum_by(obj, predicate)
  local counts = {}
  setmetatable(counts, { __index = function() return 0 end })
  if obj then
    for _, result in pairs(obj) do
      t = predicate(result)
      if t ~= nil then
        counts[t[1]] = counts[t[1]] + t[2]
      end
    end
  end
  return counts
end

-- Item Helpers --

function barrelcrafting.fn.item_type(item_proto)
  return item_proto and item_proto.type
end

function barrelcrafting.fn.is_type_item(item_proto)
  return item_proto and item_proto.type == "item"
end

function barrelcrafting.fn.is_type_fluid(item_proto)
  return item_proto and item_proto.type == "fluid"
end

function barrelcrafting.fn.item_expected_amount(item_proto)
  if item_proto then
    return (item_proto.amount or (0.5 * (item_proto.amount_min + item_proto.amount_max))) * (item_proto.probability or 1)
  end
  return nil
end

-- Recipe Helpers --

function barrelcrafting.fn.normalize_recipe_item(item)
  item.name = item.name or item[1]
  item.amount = item.amount or item[2]
  item.type = item.type or "item"
  item[1] = nil
  item[2] = nil
  return item
end

function barrelcrafting.fn.normalize_recipe(recipe)
  for _, r in ipairs({recipe, recipe.normal, recipe.expensive}) do
    if r then
      -- normalize results
      if r.results or r.result then
        if r.results == nil and r.result then
          r.results = {{ r.result, r.result_count or 1 }}
        end
        for idx, item in pairs(r.results) do
          barrelcrafting.fn.normalize_recipe_item(item)
        end
        r.result = nil
        r.result_count = nil
      end
      -- normalize ingredients
      if r.ingredients then
        for idx, item in pairs(r.ingredients) do
          barrelcrafting.fn.normalize_recipe_item(item)
        end
      end
    end
  end
end

function barrelcrafting.fn.copy_recipe_ingredients(recipe)
  local t = {}
  if recipe and recipe.ingredients then
    t = table.deepcopy(recipe.ingredients)
  end
  for _,item in pairs(t) do
    barrelcrafting.fn.normalize_recipe_item(item)
  end
  return t
end

function barrelcrafting.fn.copy_recipe_results(recipe)
  local t = {}
  if recipe and recipe.results then
    t = table.deepcopy(recipe.results)
  elseif recipe and recipe.result then
    table.insert(t, { recipe.result, recipe.result_count or 1 })
  end
  for _,item in pairs(t) do
    barrelcrafting.fn.normalize_recipe_item(item)
  end
  return t
end
