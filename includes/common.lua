--------------------------------------------------------------------------------
-- Common methods
--------------------------------------------------------------------------------
  
local function getRandom(min, max, factor)
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

local function getRandomBoolean(probability)
  -- Default probability of getting true is 50%
  if type(probability) ~= "number" then
    probability = 50
  end
  return getRandom(100) <= probability
end

local function getChangeMax(max, probabilityLevel)
  return math.ceil(max * (probabilityLevel / 100))
end

local function getIndexFromValue(value, selection)
  for i,v in ipairs(selection) do
    if v == value then
      return i
    end
  end
  return nil
end

return {  
  getRandom = getRandom,
  getRandomBoolean = getRandomBoolean,
  getChangeMax = getChangeMax,
  getIndexFromValue = getIndexFromValue,

  randomizeValue = function(value, limitMin, limitMax, randomizationAmount)
    if randomizationAmount > 0 then
      local limitRange = limitMax - limitMin
      local changeMax = getChangeMax(limitRange, randomizationAmount)
      local min = math.max(limitMin, (value - changeMax))
      local max = math.min(limitMax, (value + changeMax))
      --print("Before randomize value", value)
      value = getRandom(min, max)
      --print("After randomize value/changeMax/min/max", value, changeMax, min, max)
    end
    return value
  end,
  
  tableIncludes = function(theTable, theItem)
    return type(getIndexFromValue(theItem, theTable)) == "number"
  end,
  
  round = function(value)
    local int, frac = math.modf(value)
    --print("int/frac", int, frac)
    if math.abs(frac) < 0.5 then
      value = int
    elseif value < 0 then
      value = int - 1
    else
      value = int + 1
    end
    return value
  end,
  
  getRandomFromTable = function(theTable, except)
    if #theTable == 0 then
      return nil
    end
    if #theTable == 1 then
      return theTable[1]
    end
    local index = getRandom(#theTable)
    local value = theTable[index]
    --print("getRandomFromTable index, value", index, value)
    if type(except) ~= "nil" then
      local maxRounds = 10
      while value == except and maxRounds > 0 do
        value = theTable[getRandom(#theTable)]
        maxRounds = maxRounds - 1
        --print("getRandomFromTable except, maxRounds", except, maxRounds)
      end
    end
    return value
  end,
  
  trimStartAndEnd = function(s)
    return s:match("^%s*(.-)%s*$")
  end
}
