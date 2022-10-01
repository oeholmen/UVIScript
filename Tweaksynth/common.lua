--------------------------------------------------------------------------------
-- Common methods
--------------------------------------------------------------------------------

require "notes"
require "scales"
require "resolutions"

function randomizeValue(value, limitMin, limitMax, randomizationAmount)
  if randomizationAmount > 0 then
    local changeMax = getChangeMax(limitMax, randomizationAmount)
    local min = value - changeMax
    local max = value + changeMax
    if min < limitMin then
      min = limitMin
    end
    if max > limitMax then
      max = limitMax
    end
    --print("Before randomize value", value)
    value = getRandom(min, max)
    --print("After randomize value/changeMax/min/max", value, changeMax, min, max)
  end
  return value
end

function tableIncludes(theTable, theItem)
  for _,v in pairs(theTable) do
    if v == theItem then
      return true
    end
  end
  return false
end

function getIndexFromValue(value, selection)
  for i,v in ipairs(selection) do
    if v == value then
      return i
    end
  end
  return 1
end

function round(value)
  local int, frac = math.modf(value)
  print("int/frac", int, frac)
  if math.abs(frac) < 0.5 then
    value = int
  elseif value < 0 then
    value = int - 1
  else
    value = int + 1
  end
  return value
end

function getRandom(min, max, factor)
  if type(min) == "number" and type(max) == "number" and min < max then
    return math.random(min, max)
  elseif type(min) == "number" then
    return math.random(min)
  end
  local value = math.random()
  if type(factor) == "number" then
    value = value * factor
  end
  return value
end

function getRandomBoolean(probability)
  -- Default probability of getting true is 50%
  if type(probability) ~= "number" then
    probability = 50
  end
  return getRandom(100) <= probability
end

function getChangeMax(max, probabilityLevel)
  return math.ceil(max * (probabilityLevel / 100))
end
