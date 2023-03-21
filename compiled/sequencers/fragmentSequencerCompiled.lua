-- sequencers/fragmentSequencer -- 
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

local function randomizeValue(value, limitMin, limitMax, randomizationAmount)
  if randomizationAmount == 0 then
    return value
  end
  local limitRange = limitMax - limitMin
  local changeMax = getChangeMax(limitRange, randomizationAmount)
  local min = math.max(limitMin, (value - changeMax))
  local max = math.min(limitMax, (value + changeMax))
  return getRandom(min, max)
end

-- sign function: -1 if x<0; 1 if x>0
local function sign(x)
  if x < 0 then
    return -1
  end
  return 1
end

local function sum(t)
  local sum = 0
  for _,v in pairs(t) do -- Get the sum of all numbers in t
    sum = sum + v
  end
  return sum
end

local function avg(t)
  return sum(t) / #t
end

local function round(value)
  local int, frac = math.modf(value)
  if math.abs(frac) < 0.5 then
    value = int
  elseif value < 0 then
    value = int - 1
  else
    value = int + 1
  end
  return value
end

local function tableIncludes(theTable, theItem)
  return type(getIndexFromValue(theItem, theTable)) == "number"
end

local function getRandomFromTable(theTable, except)
  if #theTable == 0 then
    return nil
  end
  if #theTable == 1 then
    return theTable[1]
  end
  local index = getRandom(#theTable)
  local value = theTable[index]
  if type(except) ~= "nil" then
    local maxRounds = 10
    while value == except and maxRounds > 0 do
      value = theTable[getRandom(#theTable)]
      maxRounds = maxRounds - 1
    end
  end
  return value
end

local function trimStartAndEnd(s)
  return s:match("^%s*(.-)%s*$")
end

local function getChangePerStep(valueRange, numSteps)
  return valueRange / (numSteps - 1)
end

local function inc(val, inc, resetAt, resetTo)
  if type(inc) ~= "number" then
    inc = 1
  end
  if type(resetTo) ~= "number" then
    resetTo = 1
  end
  val = val + inc
  if type(resetAt) == "number" then
    if (inc > 0 and val > resetAt) or (inc < 0 and val < resetAt) then
      val = resetTo
    end
  end
  return val
end

local function advanceValue(bounds, value, min, max, direction)
  local valueRange = bounds.max - bounds.min
  local changeFactor = max - min
  local changePerStep = getChangePerStep(changeFactor, valueRange)

  if direction < 0 then
    changePerStep = -changePerStep
  end

  value = inc(value, changePerStep)
  if value > max then
    direction = -1
    value = max
  elseif value < min then
    direction = 1
    value = min
  end
  return value, direction
end

local function getValueOrDefault(value, default)
  if type(value) ~= "nil" then
    return value
  end
  return default
end

local gem = {
  e = 2.71828,
  inc = inc,
  avg = avg,
  sum = sum,
  sign = sign,
  round = round,
  getRandom = getRandom,
  getChangeMax = getChangeMax,
  advanceValue = advanceValue,
  tableIncludes = tableIncludes,
  randomizeValue = randomizeValue,
  trimStartAndEnd = trimStartAndEnd,
  getChangePerStep = getChangePerStep,
  getRandomBoolean = getRandomBoolean,
  getValueOrDefault = getValueOrDefault,
  getIndexFromValue = getIndexFromValue,
  getRandomFromTable = getRandomFromTable,
}

--------------------------------------------------------------------------------
-- Common Resolutions
--------------------------------------------------------------------------------

local function getDotted(value)
  return value * 1.5
end

local function getTriplet(value)
  return value / 3
end

-- NOTE: Make sure resolutionValues and resolutionNames are in sync
local resolutionValues = {
  128, -- "32x" -- 1
  64, -- "16x" -- 2
  32, -- "8x" -- 3
  28, -- "7x" -- 4
  24, -- "6x" -- 5
  20, -- "5x" -- 6
  16, -- "4x" -- 7
  12, -- "3x" -- 8
  8, -- "2x" -- 9
  6, -- "1/1 dot" -- 10
  4, -- "1/1" -- 11
  3, -- "1/2 dot" -- 12
  getTriplet(8), -- "1/1 tri" -- 13
  2, -- "1/2" -- 14
  getDotted(1), -- "1/4 dot", -- 15
  getTriplet(4), -- "1/2 tri", -- 16
  1, -- "1/4", -- 17
  getDotted(0.5), -- "1/8 dot", -- 18
  getTriplet(2), -- "1/4 tri", -- 19
  0.5,  -- "1/8", -- 20
  getDotted(0.25), -- "1/16 dot", -- 21
  getTriplet(1), -- "1/8 tri", -- 22
  0.25, -- "1/16", -- 23
  getDotted(0.125), -- "1/32 dot", -- 24
  getTriplet(0.5), -- "1/16 tri", -- 25
  0.125, -- "1/32" -- 26
  getDotted(0.0625), -- "1/64 dot", -- 27
  getTriplet(0.25), -- "1/32 tri", -- 28
  0.0625, -- "1/64", -- 29
  getDotted(0.03125), -- "1/128 dot" -- 30
  getTriplet(0.125), -- "1/64 tri" -- 31
  0.03125 -- "1/128" -- 32
}

local resolutionNames = {
  "32x", -- 1
  "16x", -- 2
  "8x", -- 3
  "7x", -- 4
  "6x", -- 5
  "5x", -- 6
  "4x", -- 7
  "3x", -- 8
  "2x", -- 9
  "1/1 dot", -- 10
  "1/1", -- 11
  "1/2 dot", -- 12
  "1/1 tri", -- 13
  "1/2", -- 14
  "1/4 dot", -- 15
  "1/2 tri", -- 16
  "1/4", -- 17
  "1/8 dot", -- 18
  "1/4 tri", -- 19
  "1/8", -- 20
  "1/16 dot", -- 21
  "1/8 tri", -- 22
  "1/16", -- 23
  "1/32 dot", -- 24
  "1/16 tri", -- 25
  "1/32", -- 26
  "1/64 dot", -- 27
  "1/32 tri", -- 28
  "1/64", -- 29
  "1/128 dot", -- 30
  "1/64 tri", -- 31
  "1/128" -- 32
}

local function getEvenFromTriplet(value)
  return value * 3
end

local function getEvenFromDotted(value)
  return value / 1.5
end

-- This variable is used by getResolutionsByType as the starting point for finding even/dot/tri resolutions
local resolutionTypeStartPosIndex = 11 -- 1/1

local function getResolutionsByType(maxResolutionIndex, includeSlowResolutions)
  if type(maxResolutionIndex) == "nil" then
    maxResolutionIndex = #resolutionValues
  end
  if type(includeSlowResolutions) == "nil" then
    includeSlowResolutions = true
  end
  local resOptions = {}
  -- Create table of resolution indexes by type (1=even,2=dot,3=tri,4=slow)
  for i=resolutionTypeStartPosIndex,resolutionTypeStartPosIndex+2 do
    local resolutionIndex = i
    local resolutionsOfType = {}
    while resolutionIndex <= maxResolutionIndex do
      table.insert(resolutionsOfType, resolutionIndex) -- insert current index in resolution options table
      --print("Insert resolutionIndex", resolutionIndex)
      resolutionIndex = gem.inc(resolutionIndex, 3) -- increment index
    end
    --print("#resolutionsOfType, i", #resolutionsOfType, i)
    table.insert(resOptions, resolutionsOfType)
  end
  -- Add the resolutions that are whole numbers (1,2,3,4...)
  if includeSlowResolutions then
    local slowResolutions = {}
    for i,resolution in ipairs(resolutionValues) do
      if resolution % 1 == 0 then
        table.insert(slowResolutions, i)
        --print("getResolutionsByType - included slow resolution", resolutionValues[i], i)
      end
    end
    --print("#slowResolutions", #slowResolutions)
    table.insert(resOptions, slowResolutions) -- Add the "slow" x resolutions
  end
  --print("resOptions", #resOptions)
  return resOptions
end

local function isResolutionWithinRange(resolutionIndex, options, i)
  if resolutionIndex < options.minResolutionIndex or resolutionIndex > options.maxResolutionIndex then
    return false
  end

  if i == 2 and resolutionIndex > options.maxDotResolutionIndex then
    return false
  end

  if i == 3 and resolutionIndex > options.maxTriResolutionIndex then
    return false
  end

  return true
end

-- Returns a table of resolutions indexes that are within the given range
local function getSelectedResolutions(resolutionsByType, options)
  if type(options) == "nil" then
    options = {}
  end

  if type(options.minResolutionIndex) == "nil" then
    options.minResolutionIndex = 1
  end

  if type(options.maxResolutionIndex) == "nil" then
    options.maxResolutionIndex = #resolutionValues
  end

  if type(options.maxDotResolutionIndex) == "nil" then
    options.maxDotResolutionIndex = #resolutionValues
  end

  if type(options.maxTriResolutionIndex) == "nil" then
    options.maxTriResolutionIndex = #resolutionValues
  end

  local selectedResolutions = {}
  for i,type in ipairs(resolutionsByType) do
    for _,resolutionIndex in ipairs(type) do
      if isResolutionWithinRange(resolutionIndex, options, i) then
        table.insert(selectedResolutions, resolutionIndex)
      end
    end
  end
  return selectedResolutions
end

-- Tries to adjust the given resolution by adjusting
-- length, and/or setting a even/dot/tri value variant
-- Options are: adjustBias (0=slow -> 100=fast), doubleOrHalfProbaility, dotOrTriProbaility, selectedResolutions
local function getResolutionVariation(currentResolution, options)
  local currentIndex = gem.getIndexFromValue(currentResolution, resolutionValues)

  if type(currentIndex) == "nil" then
    return currentResolution
  end

  if type(options) == "nil" then
    options = {}
  end

  if type(options.minResolutionIndex) == "nil" then
    options.minResolutionIndex = 1
  end

  if type(options.maxResolutionIndex) == "nil" then
    options.maxResolutionIndex = #resolutionValues
  end

  if type(options.maxDotResolutionIndex) == "nil" then
    options.maxDotResolutionIndex = #resolutionValues
  end

  if type(options.maxTriResolutionIndex) == "nil" then
    options.maxTriResolutionIndex = #resolutionValues
  end

  if type(options.adjustBias) == "nil" then
    options.adjustBias = 50
  end

  if type(options.doubleOrHalfProbaility) == "nil" then
    options.doubleOrHalfProbaility = 50
  end

  if type(options.dotOrTriProbaility) == "nil" then
    options.dotOrTriProbaility = 50
  end

  local resolutionsByType = getResolutionsByType()

  if type(options.selectedResolutions) == "nil" then
    options.selectedResolutions = getSelectedResolutions(resolutionsByType, options)
  end

  -- Normalize resolution
  local resolution = currentResolution
  if gem.tableIncludes(resolutionsByType[2], currentIndex) then
    resolution = getEvenFromDotted(resolutionValues[currentIndex])
    --print("getEvenFromDotted", resolution)
  elseif gem.tableIncludes(resolutionsByType[3], currentIndex) then
    resolution = getEvenFromTriplet(resolutionValues[currentIndex])
    --print("getEvenFromTriplet", resolution)
  elseif gem.tableIncludes(resolutionsByType[1], currentIndex) or gem.tableIncludes(resolutionsByType[4], currentIndex) then
    resolution = resolutionValues[currentIndex]
    --print("getEvenOrSlow", resolution)
  end

  if type(resolution) == "number" then
    local doubleOrHalf = gem.getRandomBoolean(options.doubleOrHalfProbaility)
    -- Double (slow) or half (fast) duration
    if doubleOrHalf then
      local doubleResIndex = gem.getIndexFromValue((resolution * 2), resolutionValues)
      local halfResIndex = gem.getIndexFromValue((resolution / 2), resolutionValues)
      if gem.getRandomBoolean(options.adjustBias) == false and type(doubleResIndex) == "number" and gem.tableIncludes(options.selectedResolutions, doubleResIndex) then
        resolution = resolutionValues[doubleResIndex]
        --print("Slower resolution", resolution)
      elseif type(halfResIndex) == "number" and gem.tableIncludes(options.selectedResolutions, halfResIndex) then
        resolution = resolution / 2
        --print("Faster resolution", resolution)
      end
    end
    -- Set dot or tri on duration if probability hits
    if gem.getRandomBoolean(options.dotOrTriProbaility) then
      if gem.tableIncludes(resolutionsByType[3], currentIndex) then
        resolution = getTriplet(resolution)
        --print("getTriplet", resolution)
      else
        local dottedResIndex = gem.getIndexFromValue(getDotted(resolution), resolutionValues)
        if type(dottedResIndex) == "number" and gem.tableIncludes(options.selectedResolutions, dottedResIndex) then
          resolution = resolutionValues[dottedResIndex]
          --print("getDotted", resolution)
        end
      end
    end
  end
  if type(resolution) == "number" then
    currentIndex = gem.getIndexFromValue(resolution, resolutionValues)
  end
  --print("AFTER currentIndex", currentIndex)
  if type(currentIndex) == "number" and gem.tableIncludes(options.selectedResolutions, currentIndex) then
    --print("Got resolution from the current index")
    return resolutionValues[currentIndex]
  end

  return currentResolution
end

-- If you want to add the resolutions to an existing table, give it as the second argument
local function getResolutionsFromIndexes(indexes, resolutions)
  if type(resolutions) == "nil" then
    resolutions = {}
  end
  for _,v in ipairs(indexes) do
    if gem.tableIncludes(resolutions, v) == false then
      table.insert(resolutions, resolutionValues[v])
    end
  end
  table.sort(resolutions, function(a,b) return a > b end) -- Ensure sorted desc
  return resolutions
end

local quantizeOptions = {"Off", "Any", "Even", "Dot", "Tri", "Even+Dot", "Even+Tri", "Dot+Tri"}

-- Quantize the given beat to the closest recognized resolution value
local function quantizeToClosest(beat, quantizeType)
  if type(quantizeType) == "nil" then
    quantizeType = quantizeOptions[2] -- Any
  end
  if quantizeType == quantizeOptions[1] then
    -- Quantize off, just return return the given beat value
    return beat
  end
  local includeSlowResolutions = beat > resolutionValues[resolutionTypeStartPosIndex]
  local resolutionsByType = getResolutionsByType(#resolutionValues, includeSlowResolutions)
  local quantizeResolutions = {}
  if includeSlowResolutions then
    --print("Beat > resolutionsByType[1][1]", beat, resolutionValues[resolutionsByType[1][1]])
    quantizeResolutions = getResolutionsFromIndexes(resolutionsByType[4], quantizeResolutions) -- Slow
  else
    for i=1,3 do
      if quantizeType == quantizeOptions[2] or string.find(quantizeType, quantizeOptions[i+2], 1, true) then
        quantizeResolutions = getResolutionsFromIndexes(resolutionsByType[i], quantizeResolutions)
        --print("Add quantize resolutions", quantizeType)
      end
    end
  end
  --print("quantizeResolutions min/max/count", quantizeResolutions[1], quantizeResolutions[#quantizeResolutions], #quantizeResolutions)
  for i,v in ipairs(quantizeResolutions) do
    local currentValue = v
    local nextValue = quantizeResolutions[i+1]
    if beat == currentValue or type(nextValue) == "nil" then
      print("Found equal, or next is nil", beat, currentValue)
      return currentValue
    end
    if beat < currentValue and beat > nextValue then
      local diffCurrent = currentValue - beat
      local diffNext = beat - nextValue
      if diffCurrent < diffNext then
        print("Closest to current", beat, currentValue, nextValue)
        return currentValue
      else
        print("Closest to next", beat, nextValue, currentValue)
        return nextValue
      end
    end
  end
  print("No resolution found, returning the given beat value", beat)
  return beat
end

local resolutions = {
  getResolutionsFromIndexes = getResolutionsFromIndexes,
  getSelectedResolutions = getSelectedResolutions,
  getResolutionVariation = getResolutionVariation,
  getResolutionsByType = getResolutionsByType,
  quantizeToClosest = quantizeToClosest,
  getDotted = getDotted,
  getTriplet = getTriplet,
  getEvenFromDotted = getEvenFromDotted,
  getEvenFromTriplet = getEvenFromTriplet,
  getResolution = function(i)
    return resolutionValues[i]
  end,
  getQuantizeOptions = function()
    return quantizeOptions
  end,
  getResolutions = function()
    return resolutionValues
  end,
  getResolutionName = function(i)
    return resolutionNames[i]
  end,
  getResolutionNames = function(options, max)
    if type(max) ~= "number" then
      max = #resolutionNames
    end
    local res = {}
    for i,r in ipairs(resolutionNames) do
      table.insert(res, r)
      if i == max then
        break
      end
    end
    -- Add any options
    if type(options) == "table" then
      for _,o in ipairs(options) do
        table.insert(res, o)
      end
    end
    return res
  end,
  getPlayDuration = function(duration, gate)
    if type(gate) == "nil" then
      gate = 100
    end
    local maxResolution = resolutionValues[#resolutionValues]
    return math.max(maxResolution, duration * (gate / 100)) -- Never shorter than the system max resolution
  end  
}

--------------------------------------------------------------------------------
-- Common functions for working with rythmic fragments
--------------------------------------------------------------------------------

local paramsPerFragment = {}

-- Expand defaults
local resolutionFragments = {
  {'1/16','1/16','1/8'},
  {'1/16','1/8','1/16'},
  {'1/4 dot','1/8'},
  {'1/4 dot','1/16','1/16'},
  {'1/4','1/8','1/8'},
  {'1/8','1/4','1/8'},
  {'1/4','1/8','1/16','1/16'},
  {'1/16','1/8 dot'},
  {'1/8 dot','1/16'},
  {'1/2 dot','1/4'},
  {'1/8 dot','1/4','1/4','1/16'},
  {'1/16','1/16','1/16','1/16','1/16','1/16','1/16','1/32','1/32'},
  {'1/8','1/8','1/16','1/4','1/8','1/16','1/8','1/16','1/16'},
  {'-1/1 dot','1/4 dot','1/8'},
  {'-1/4','1/4','-1/4','1/8 dot','1/16'},
  {'1/4','-1/4','1/4','-1/4','1/4','-1/4','1/4 dot','-1/16','1/16'},
  {'1.75','1/16','-1/4','-1/8','1/8'}
}

local singleResolutions = {14,15,17,18,20,23} -- Resolution indexes
local resolutionsForEvolve = {} -- Resolutions used when evolving
local resolutionsByType = resolutions.getResolutionsByType()
local maxResolutionIndex = resolutionsByType[1][#resolutionsByType[1]] -- Set max resolution to the highest even resolution index

local function setMaxResolutionIndex(i)
  maxResolutionIndex = i
end

-- Turn all recognized fragment items into note names
local function fragmentDefinitionToResolutionNames(fragmentDefinition)
  local parsed = {}
  for _,v in ipairs(fragmentDefinition) do
    local index = gem.getIndexFromValue(v, resolutions.getResolutions())
    local text = v
    --print("index, text", index, text)
    if type(index) == "number" then
      text = resolutions.getResolutionName(index)
      --print("text", text)
    end
    table.insert(parsed, text)
  end
  return parsed
end

local function parseToBeatValue(duration)
  if type(tonumber(duration)) == "number" then
    duration = tonumber(duration)
    --print("Duration is number", duration)
    return duration
  end

  --print("Duration is NOT a number, try to find beat value from name", duration)
  -- TODO Check if duration starts with a '-' indicating pause
  local isRest = string.sub(duration,1,1) == "-"
  if isRest then
    duration = string.sub(duration, 2, string.len(duration))
    --print("Duration starts with - 'REST'", duration)
  end
  local index = gem.getIndexFromValue(duration, resolutions.getResolutionNames())
  if type(index) == "number" then
    --print("Found duration", duration)
    if isRest then
      return -resolutions.getResolution(index)
    end
    return resolutions.getResolution(index)
  end

  --print("Could not resolve duration, returning 0", duration)
  return 0
end

local function createFragmentFromText(fragmentText)
  local fragment = {}
  if string.len(fragmentText) > 0 then
    for w in string.gmatch(fragmentText, "[^,]+") do
      --print("Before parse", w)
      local beat = parseToBeatValue(gem.trimStartAndEnd(w))
      --print("Add to fragment", w)
      if type(beat) == "number" then
        table.insert(fragment, beat)
      end
    end
  end
  return fragment
end

local function calculateFragmentDuration(fragmentText)
  local fragment = createFragmentFromText(fragmentText)
  local total = 0
  for _,v in ipairs(fragment) do
    total = total + math.abs(v)
    --print("calculateFragmentDuration v, total", v, total)
  end
  --print("TOTAL", total)
  return total
end

-- Get the fragment as text for fragment input
local function getFragmentInputText(fragment)
  if #fragment == 0 then
    return ""
  end
  return table.concat(fragment, ",")
end

-- Include all durations shorter than or equal to the total fragmentDuration
local function addDurations(resolutionIndexes, durations, fragmentDuration)
  for _,i in ipairs(resolutionIndexes) do
    local duration = resolutions.getResolution(i)
    if duration <= fragmentDuration then
      table.insert(durations, duration)
      --print("addDurations() Inserted duration", duration)
    end
  end
  return durations
end

-- Returns a probability (between 0-100) for the given resolution index
local function getProbabilityForResolutionIndex(i)
  local baseProbability = math.ceil(100 / resolutions.getResolution(i))
  local factor = i / 2
  return math.min(100, math.floor(baseProbability * factor))
end

-- Returns indexes for "whole" resolutions, filtered by probability
local function getSlowResolutions()
  local slowResolutions = {}
  for _,i in ipairs(resolutionsByType[4]) do
    local probability = getProbabilityForResolutionIndex(i)
    --print("getSlowResolutions - set probability for resolution", probability, resolutions.getResolution(i))
    if gem.getRandomBoolean(probability) then
      table.insert(slowResolutions, i)
      --print("getSlowResolutions - included slow resolution")
    end
  end
  --print("getSlowResolutions - found slow resolutions", #slowResolutions)
  return slowResolutions
end

-- Returns a table of resolutions indexes that are "approved" to use
local function getSelectedResolutions()
  local options = {
    minResolutionIndex = 3, -- Slowest
    maxResolutionIndex = maxResolutionIndex, -- Fastest
    maxDotResolutionIndex = 18, -- Fastest dotted
    maxTriResolutionIndex = 25, -- Fastest triplet
  }
  return resolutions.getSelectedResolutions(resolutionsByType, options)
  --[[ local selectedResolutions = getSlowResolutions()
  for i=1,3 do
    for _,resolutionIndex in ipairs(resolutionsByType[i]) do
      -- Limit dotted/tri resolutions above 1/8 dot and 1/16 tri
      if resolutionIndex > maxResolutionIndex or (i == 2 and resolutionIndex > 18) or (i == 3 and resolutionIndex > 25) then
        break
      end
      table.insert(selectedResolutions, resolutionIndex)
    end
  end
  return selectedResolutions ]]
end

-- Auto generate fragment
-- durationType:
--    "Create fragment (even+dot)" 1
--    "Create fragment (even+tri)" 2
--    "Create fragment (extended)" 3
--    "Create fragment (slow)" 4
local function createFragmentDefinition(durationType)
  if type(durationType) == "nil" then
    durationType = 1
  end
  local currentDuration = 0
  local fragmentDurations = {1,2,3,4,8}
  local fragmentDuration = gem.getRandomFromTable(fragmentDurations) -- TODO Param?
  --print("Selected fragmentDuration", fragmentDuration)
  local durations = {}
  -- Add resolutions that can fit inside the fragmentDuration
  if durationType == 1 or durationType == 2 then -- Add even
    durations = addDurations({17,20,23}, durations, fragmentDuration)
  end
  if durationType == 1 then -- Add dotted
    durations = addDurations({15,18}, durations, fragmentDuration)
  end
  if durationType == 2 then -- Add tri
    durations = addDurations({19,22}, durations, fragmentDuration)
  end
  if durationType == 3 then
    -- Extended includes both long and short durations
    local extendedDurations = getSlowResolutions()
    for _,v in ipairs(fragmentDurations) do
      table.insert(extendedDurations, v)
    end
    fragmentDuration = resolutions.getResolution(gem.getRandomFromTable(extendedDurations))
    durations = addDurations(getSelectedResolutions(), durations, fragmentDuration)
  end
  if durationType == 4 then
    -- Slow durations
    local slowResolutions = getSlowResolutions()
    fragmentDuration = resolutions.getResolution(gem.getRandomFromTable(slowResolutions))
    --print("Selected fragmentDuration", fragmentDuration)
    durations = addDurations(slowResolutions, durations, fragmentDuration)
  end
  --print("Found durations", #durations)
  -- Select durations to fill the definition until the total fragment duration is reached
  local definition = {}
  while currentDuration < fragmentDuration do
    local duration = gem.getRandomFromTable(durations)
    if currentDuration + duration > fragmentDuration then
      duration = fragmentDuration - currentDuration
      --print("currentDuration + duration > fragmentDuration", currentDuration, duration, fragmentDuration)
    end
    currentDuration = currentDuration + duration
    table.insert(definition, duration)
    --print("Add duration", duration)
  end
  return definition
end

local function parseFragment(fragmentInputIndex)
  if type(fragmentInputIndex) == "nil" then
    return
  end
  local fragmentInput = paramsPerFragment[fragmentInputIndex].fragmentInput
  local fragmentPlayProbability = paramsPerFragment[fragmentInputIndex].fragmentPlayProbability.value
  local fragmentActive = paramsPerFragment[fragmentInputIndex].fragmentActive.value
  if fragmentActive and string.len(fragmentInput.text) > 0 and gem.getRandomBoolean(fragmentPlayProbability) then
    local fragment = createFragmentFromText(fragmentInput.text)
    local selectProbability = 100
    local repeatProbability = paramsPerFragment[fragmentInputIndex].fragmentRepeatProbability.value
    local repeatProbabilityDecay = paramsPerFragment[fragmentInputIndex].fragmentRepeatProbabilityDecay.value
    local minRepeats = paramsPerFragment[fragmentInputIndex].fragmentMinRepeats.value
    local reverseFragmentProbability = paramsPerFragment[fragmentInputIndex].reverseFragmentProbability.value
    local randomizeFragmentProbability = paramsPerFragment[fragmentInputIndex].randomizeFragmentProbability.value
    local restProbability = paramsPerFragment[fragmentInputIndex].restProbability.value
    -- i = the fragment input number
    -- f = the resolutions of the fragment definition (resolution name (1/8) or beat value (0.5))
    -- p = probability of include
    -- r = repeat probability
    -- d = repeat probability decay
    -- m = min repeats
    -- rev = reverse probability
    -- rnd = random order probability
    -- rst = rest randomization probability
    return {
      f=fragment,
      i=fragmentInputIndex,
      p=selectProbability,
      r=repeatProbability,
      d=repeatProbabilityDecay,
      m=minRepeats,
      rnd=randomizeFragmentProbability,
      rev=reverseFragmentProbability,
      rst=restProbability,
    }
  end
end

local function getSelectedFragments(fragmentIndexes)
  local selectedFragments = {}
  for i=1, #paramsPerFragment do
    local fragment = parseFragment(i)
    local includeFragment = type(fragmentIndexes) ~= "table" or gem.tableIncludes(fragmentIndexes, i)
    if type(fragment) == "table" and includeFragment then
      table.insert(selectedFragments, fragment)
    end
  end
  return selectedFragments
end

local function getFragment(fragmentIndexes, prevFragmentIndex)
  local selectedFragments = getSelectedFragments(fragmentIndexes)

  -- Remove the previous fragment to avoid repeat unless it is the only available fragment
  if #selectedFragments > 1 and type(prevFragmentIndex) == "number" and prevFragmentIndex > 0 then
    for i,v in ipairs(selectedFragments) do
      if v.i == prevFragmentIndex then
        table.remove(selectedFragments, i)
        break
      end
    end
  end

  local fragment = gem.getRandomFromTable(selectedFragments)

  if type(fragment) == "table" then
    return fragment
  end
end

local function flashFragmentActive(fragmentActive, duration)
  if type(duration) == "nil" then
    duration = 1
  end
  local flashDuration = math.min(150, beat2ms(duration))
  fragmentActive.textColourOn = "white"
  wait(flashDuration)
  fragmentActive.textColourOn = "black"
end

-- Get fragment state for storage
local function getFragmentState()
  local fragments = {}
  for i,v in ipairs(paramsPerFragment) do
    table.insert(fragments, {
      fragmentActive = v.fragmentActive.value,
      lockedForEvolve = v.lockedForEvolve.value,
      fragmentInput = v.fragmentInput.text,
      playProbability = v.fragmentPlayProbability.value,
      repeatProbability = v.fragmentRepeatProbability.value,
      repeatProbabilityDecay = v.fragmentRepeatProbabilityDecay.value,
      minRepeats = v.fragmentMinRepeats.value,
      reverseProbability = v.reverseFragmentProbability.value,
      randomizeProbability = v.randomizeFragmentProbability.value,
      restProbability = v.restProbability.value,
    })
  end
  return fragments
end

-- Set the fragment state based on the given state
local function setFragmentState(state)
  local fragments = state
  for i,v in ipairs(paramsPerFragment) do
    v.fragmentActive.value = fragments[i].fragmentActive
    v.lockedForEvolve.value = fragments[i].lockedForEvolve or false
    v.fragmentInput.text = fragments[i].fragmentInput
    v.fragmentPlayProbability.value = fragments[i].playProbability
    v.fragmentRepeatProbability.value = fragments[i].repeatProbability
    v.fragmentRepeatProbabilityDecay.value = fragments[i].repeatProbabilityDecay
    v.fragmentMinRepeats.value = fragments[i].minRepeats
    v.reverseFragmentProbability.value = fragments[i].reverseProbability
    v.randomizeFragmentProbability.value = fragments[i].randomizeProbability
    v.restProbability.value = fragments[i].restProbability
  end
end

-- Tries to adjust the given resolution by adjusting
-- length, and/or setting a even/dot/tri value variant
local function getResolutionFromCurrentIndex(currentResolution, adjustBias, dotOrTriProbaility)
  -- Include the resolutions that are available
  --local selectedResolutions = getSelectedResolutions()
  local options = {
    adjustBias=adjustBias,
    selectedResolutions=selectedResolutions,
    dotOrTriProbaility=dotOrTriProbaility,
    maxDotResolutionIndex = 18, -- Fastest dotted
    maxTriResolutionIndex = 25, -- Fastest triplet
  }
  return resolutions.getResolutionVariation(currentResolution, options)
  --[[ local currentIndex = gem.getIndexFromValue(currentResolution, resolutions.getResolutions())
  if type(currentIndex) == "nil" then
    return
  end

  -- Include the resolutions that are available
  local selectedResolutions = getSelectedResolutions()

  --print("BEFORE currentIndex", currentIndex)
  local resolutionIndex = currentIndex
  if gem.tableIncludes(resolutionsByType[2], currentIndex) then
    resolution = resolutions.getEvenFromDotted(resolutions.getResolution(currentIndex))
    --print("getEvenFromDotted", resolution)
  elseif gem.tableIncludes(resolutionsByType[3], currentIndex) then
    resolution = resolutions.getEvenFromTriplet(resolutions.getResolution(currentIndex))
    --print("getEvenFromTriplet", resolution)
  elseif gem.tableIncludes(resolutionsByType[1], currentIndex) or gem.tableIncludes(resolutionsByType[4], currentIndex) then
    resolution = resolutions.getResolution(currentIndex)
    --print("getEvenOrSlow", resolution)
  end
  if type(resolution) == "number" then
    local doubleOrHalf = gem.getRandomBoolean() -- 50/50 chance for double or half duration
    -- Double or half duration
    if doubleOrHalf then
      if type(adjustBias) == "nil" then
        adjustBias = 50
      end
      local doubleResIndex = gem.getIndexFromValue((resolution * 2), resolutions.getResolutions())
      if gem.getRandomBoolean(adjustBias) == false and type(doubleResIndex) == "number" and gem.tableIncludes(selectedResolutions, doubleResIndex) then
        resolution = resolutions.getResolution(doubleResIndex)
        --print("Slower resolution", resolution)
      else
        resolution = resolution / 2
        --print("Faster resolution", resolution)
      end
    end
    -- Set dotted (or tri) on duration if no change was done to the lenght, or probability hits
    if doubleOrHalf == false or gem.getRandomBoolean() then
      if gem.tableIncludes(resolutionsByType[3], currentIndex) then
        resolution = resolutions.getTriplet(resolution)
        --print("getTriplet", resolution)
      else
        local dottedResIndex = gem.getIndexFromValue(resolutions.getDotted(resolution), resolutions.getResolutions())
        if type(dottedResIndex) == "number" and gem.tableIncludes(selectedResolutions, dottedResIndex) then
          resolution = resolutions.getResolution(dottedResIndex)
          --print("getDotted", resolution)
        end
      end
    end
  end
  currentIndex = gem.getIndexFromValue(resolution, resolutions.getResolutions())
  --print("AFTER currentIndex", currentIndex)
  if type(currentIndex) == "number" and gem.tableIncludes(selectedResolutions, currentIndex) then
    --print("Got resolution from the current index")
    return resolutions.getResolution(currentIndex)
  end ]]
end

-- Remove first resolution and append a (new) resolution last in the fragments
-- Returns the removed resolution (or nil if no resolution was removed for some reason)
local function evolveFragment(fragmentIndex, previous, randomizeCurrentResolutionProbability, adjustBias)
  local fragment = parseFragment(fragmentIndex)
  local removed = nil
  if type(fragment) == "table" then
    removed = fragment.f[1]
    table.remove(fragment.f, 1) -- Remove first

    -- Holds the evolved resolution
    local resolution = nil

    -- Select evolve strategy

    -- Strategy 1: Create a resolution based on the current index
    if type(randomizeCurrentResolutionProbability) == "number" and gem.getRandomBoolean(randomizeCurrentResolutionProbability) then
      resolution = getResolutionFromCurrentIndex(removed, adjustBias)
    end

    -- Strategy 2: Use resolution from the previous fragment
    local usePreviousResolutionProbability = 75 -- TODO Param?
    if type(resolution) == "nil" and gem.getRandomBoolean(usePreviousResolutionProbability) then
      resolution = previous
      --print("Got resolution from the previous fragment")
    end

    -- Strategy 3: Get a resolution from the evolve memory
    if type(resolution) == "nil" then
      --print("Got resolution from the evolve memory")
      resolution = gem.getRandomFromTable(resolutionsForEvolve)
    end

    -- Set the resolution on the fragment, and update fragment input text
    table.insert(fragment.f, resolution)
    --print("Found resolution for evolve", resolution)
    paramsPerFragment[fragmentIndex].fragmentInput.text = getFragmentInputText(fragmentDefinitionToResolutionNames(fragment.f))
  end
  return removed
end

local function clearResolutionsForEvolve()
  resolutionsForEvolve = {}
end

local function removeDuplicates()
  local removeAmount = 0
  local uniqueResolutions = {}
  for _,v in ipairs(resolutionsForEvolve) do
    if gem.tableIncludes(uniqueResolutions, v) == false then
      table.insert(uniqueResolutions, v)
    else
      removeAmount = removeAmount + 1
      --print("Removing duplicate duration", v)
    end
  end
  resolutionsForEvolve = uniqueResolutions
  return removeAmount
end

local function setResolutionsForEvolve()
  local numFragments = #paramsPerFragment
  -- Remove the duplicates resolutions if memory is full
  if #resolutionsForEvolve > math.ceil(numFragments ^ 2.5) then
    local removeAmount = removeDuplicates()
    --print("Removed from resolutionsForEvolve", removeAmount)
  end
  -- Find all resolutions that are present in the current fragments, and add to evolve memory
  for i=1,numFragments do
    local fragment = parseFragment(i)
    if type(fragment) == "table" then
      for _,v in ipairs(fragment.f) do
        -- TODO Check that no resolution "takes over" if there are few resolutions to choose from
        table.insert(resolutionsForEvolve, v)
        --print("Add to resolutionsForEvolve", v)
      end
    end
  end
  --print("Total resolutionsForEvolve", #resolutionsForEvolve)
end

local function evolveFragments(previous, randomizeCurrentResolutionProbability, adjustBias)
  setResolutionsForEvolve()
  for i,v in ipairs(paramsPerFragment) do
    if v.lockedForEvolve.value == false and string.len(v.fragmentInput.text) > 0 then
      previous = evolveFragment(i, previous, randomizeCurrentResolutionProbability, adjustBias)
    end
  end
  return previous
end

local function getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount, sources)
  local isRepeat = false
  local mustRepeat = false
  local duration = nil
  local rest = false
  local isFragmentStart = type(activeFragment) == "nil" or (reverseFragment == false and fragmentPos == #activeFragment.f) or (reverseFragment and fragmentPos == 1)
  if isFragmentStart then
    -- Start fragment (previous fragment is completed or no fragemt is selected)
    fragmentRepeatCount = fragmentRepeatCount + 1
    -- Check modulo for grouping/required number of repeats
    if type(activeFragment) == "table" and type(activeFragment.m) == "number" then
      --print("***MustRepeat?*** fragmentRepeatCount % activeFragment.m", fragmentRepeatCount, activeFragment.m, (fragmentRepeatCount % activeFragment.m))
      mustRepeat = fragmentRepeatCount % activeFragment.m > 0
    end

    -- Reload fragment in case parameters are changed
    if type(activeFragment) == "table" then
      local fragment = parseFragment(activeFragment.i)
      if type(fragment) == "table" or mustRepeat == false then
        activeFragment = fragment
      end
    end

    --print("FRAGMENT fragmentRepeatCount, mustRepeat", fragmentRepeatCount, mustRepeat)
    if type(activeFragment) == "table" and (mustRepeat or gem.getRandomBoolean(fragmentRepeatProbability)) then
      -- REPEAT FRAGMENT
      isRepeat = true
      fragmentRepeatProbability = fragmentRepeatProbability - (fragmentRepeatProbability * (activeFragment.d / 100))
      --print("REPEAT FRAGMENT, activeFragment.i, fragmentRepeatProbability", activeFragment.i, fragmentRepeatProbability)
    else
      -- CHANGE FRAGMENT
      fragmentRepeatCount = 0 -- Init repeat counter
      -- Register old fragemnt index (if any)
      local prevFragmentIndex = nil
      if type(activeFragment) == "table" then
        prevFragmentIndex = activeFragment.i
      end
      -- Change to a new fragment input
      activeFragment = getFragment(sources, prevFragmentIndex)
      if type(activeFragment) == "table" then
        isRepeat = prevFragmentIndex == activeFragment.i -- Check if same as previous
        fragmentRepeatProbability = activeFragment.r
      end
      --print("CHANGE FRAGMENT, isRepeat, fragmentRepeatProbability", isRepeat, fragmentRepeatProbability)
    end
    -- RANDOMIZE fragment
    randomizeFragment = type(activeFragment) == "table" and #activeFragment.f > 1 and gem.getRandomBoolean(activeFragment.rnd)
    if randomizeFragment then
      local tmp = {}
      local seen = {}
      local maxRounds = 100
      while #seen < #activeFragment.f and maxRounds > 0 do
        local i = gem.getRandom(#activeFragment.f)
        --print("maxRounds outer", maxRounds)
        while gem.tableIncludes(seen, i) do
          i = gem.getRandom(#activeFragment.f)
          maxRounds = maxRounds - 1
          --print("maxRounds inner", maxRounds)
        end
        table.insert(tmp, activeFragment.f[i])
        table.insert(seen, i)
        --print("#seen, i", #seen, i)
      end
      activeFragment.f = tmp
      --print("randomizeFragment")
    end
    -- REVERSE fragment
    reverseFragment = type(activeFragment) == "table" and #activeFragment.f > 1 and gem.getRandomBoolean(activeFragment.rev)
    if reverseFragment then
      --print("REVERSE fragment", reverseFragment)
      fragmentPos = #activeFragment.f
    else
      fragmentPos = 1
    end
    --print("SET fragmentPos", fragmentPos)
  else
    -- INCREMENT fragment pos
    local increment = 1
    if reverseFragment then
      increment = -increment
    end
    fragmentPos = fragmentPos + increment
    --print("INCREMENT FRAGMENT POS", fragmentPos)
  end

  if type(activeFragment) == "table" then
    -- Get duration at current position
    duration = activeFragment.f[fragmentPos]
    -- A negative duration means a rest
    if duration < 0 then
      rest = gem.getRandomBoolean(activeFragment.rst) == false -- Apply randomization
      duration = math.abs(duration)
      --print("Rest detected for duration in activeFragment.i at fragmentPos, rest", duration, activeFragment.i, fragmentPos, rest)
    else
      rest = gem.getRandomBoolean(activeFragment.rst) -- Apply randomization
    end
  end

  return duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount
end

local function getParamsPerFragment(rythmPanel, rythmLabel, colours, numSelectors, x, y)
  if type(numSelectors) == "nil" then
    numSelectors = 4
  end
  if type(x) == "nil" then
    x = 0
  end
  if type(y) == "nil" then
    y = 0
  end
  local perColumn = 2
  local rowCounter = 0
  local columnCounter = 0
  for i=1,numSelectors do
    local offsetX = 354
    local offsetY = 100
    local defaultResolution = ""

    offsetX = (offsetX * columnCounter) + x
    offsetY = (offsetY * rowCounter) + 30 + y
  
    if i == 1 then
      defaultResolution = "1/8"
    end

    -- Increment counters
    columnCounter = columnCounter + 1
    if columnCounter >= perColumn then
      columnCounter = 0
      rowCounter = rowCounter + 1
    end

    local fragmentActive = rythmPanel:OnOffButton("FragmentActive" .. i, true)
    fragmentActive.backgroundColourOff = colours.backgroundColourOff
    fragmentActive.backgroundColourOn = colours.backgroundColourOn
    fragmentActive.textColourOff = "black"
    fragmentActive.textColourOn = "black"
    fragmentActive.fontSize = 20
    fragmentActive.displayName = "" .. i
    fragmentActive.tooltip = "Toggle fragment on/off"
    fragmentActive.size = {24,24}
    if type(rythmLabel) == "nil" then
      fragmentActive.x = offsetX
      fragmentActive.y = offsetY
    else
      fragmentActive.x = rythmLabel.x + offsetX
      fragmentActive.y = rythmLabel.y + rythmLabel.height + offsetY
    end

    local lockedForEvolve = rythmPanel:OnOffButton("LockedForEvolve" .. i, false)
    lockedForEvolve.backgroundColourOff = colours.backgroundColourOff
    lockedForEvolve.backgroundColourOn = colours.backgroundColourOn
    lockedForEvolve.textColourOff = "black"
    lockedForEvolve.textColourOn = "black"
    --lockedForEvolve.normalImage = "../resources/icons/lock_open.png"
    --lockedForEvolve.pressedImage = "../resources/icons/lock_closed.png"
    lockedForEvolve.fontSize = 14
    lockedForEvolve.displayName = "L"
    lockedForEvolve.tooltip = "Set fragment locked for evolve"
    lockedForEvolve.size = {24,20}
    lockedForEvolve.x = fragmentActive.x
    lockedForEvolve.y = fragmentActive.y + fragmentActive.height + 3

    -- Fragment Input
    local fragmentInput = rythmPanel:Label("FragmentInput" .. i)
    fragmentInput.text = defaultResolution
    fragmentInput.label = "Fragment definition. Use resolution names (1/8) or beat values (0.5), separated by comma (,). Prefix resolution with '-' (minus) for rests. Click to type, or select from the menus."
    fragmentInput.tooltip = fragmentInput.label
    fragmentInput.editable = true
    fragmentInput.backgroundColour = colours.labelTextColour
    fragmentInput.backgroundColourWhenEditing = "white"
    fragmentInput.textColour = "white"
    fragmentInput.textColourWhenEditing = colours.labelTextColour
    fragmentInput.x = fragmentActive.x + fragmentActive.width + 3
    fragmentInput.y = fragmentActive.y + 0
    fragmentInput.width = 235
    fragmentInput.height = 24
    fragmentInput.fontSize = 14
    fragmentInput.changed = function(self)
      local total = calculateFragmentDuration(self.text)
      if total == 0 then
        fragmentInput.tooltip = fragmentInput.label
      else
        fragmentInput.tooltip = "Total beat duration is " .. total
      end
      paramsPerFragment[i].fragmentInputDirty = true
    end
  
    -- Menus
    --    "Create fragment (even+dot)" 1
    --    "Create fragment (even+tri)" 2
    --    "Create fragment (extended)" 3
    --    "Create fragment (slow)" 4
    local actions = {"Actions...", "Create fragment (even+dot)", "Create fragment (even+tri)", "Create fragment (extended)", "Create fragment (slow)"}
    local fragmentActions = rythmPanel:Menu("FragmentActions" .. i, actions)
    fragmentActions.tooltip = "Select an action (replaces current input!)"
    fragmentActions.showLabel = false
    fragmentActions.height = 20
    fragmentActions.width = 75
    fragmentActions.x = fragmentInput.x
    fragmentActions.y = fragmentInput.y - 24
    fragmentActions.backgroundColour = colours.menuBackgroundColour
    fragmentActions.textColour = colours.widgetTextColour
    fragmentActions.arrowColour = colours.menuArrowColour
    fragmentActions.outlineColour = colours.menuOutlineColour
    fragmentActions.changed = function(self)
      if self.value > 1 then
        -- Create
        local fragmentDefinition = fragmentDefinitionToResolutionNames(createFragmentDefinition(self.value-1))
        --print("#fragmentDefinition", #fragmentDefinition)
        fragmentInput.text = getFragmentInputText(fragmentDefinition)
      end
      -- Must be last
      self:setValue(1, false)
    end
  
    local resolutionNames = resolutions.getResolutionNames()
    local addToFragment = {"Add..."}
    for _,v in ipairs(resolutionNames) do
      table.insert(addToFragment, v)
    end
  
    local fragmentAdd = rythmPanel:Menu("FragmentAdd" .. i, addToFragment)
    fragmentAdd.tooltip = "Add to the fragment"
    fragmentAdd.showLabel = false
    fragmentAdd.height = 20
    fragmentAdd.width = fragmentActions.width
    fragmentAdd.x = fragmentActions.x + fragmentActions.width + 5
    fragmentAdd.y = fragmentActions.y
    fragmentAdd.backgroundColour = colours.menuBackgroundColour
    fragmentAdd.textColour = colours.widgetTextColour
    fragmentAdd.arrowColour = colours.menuArrowColour
    fragmentAdd.outlineColour = colours.menuOutlineColour
    fragmentAdd.changed = function(self)
      if string.len(fragmentInput.text) == 0 then
        fragmentInput.text = self.selectedText
      else
        fragmentInput.text = fragmentInput.text .. "," .. self.selectedText
      end
      -- Must be last
      self:setValue(1, false)
    end
  
    local loadFragment = {"Load..."}
    for _,v in ipairs(resolutionFragments) do
      table.insert(loadFragment, getFragmentInputText(v))
    end
  
    local fragmentLoad = rythmPanel:Menu("FragmentLoad" .. i, loadFragment)
    fragmentLoad.tooltip = "Load fragment (replaces current input!)"
    fragmentLoad.showLabel = false
    fragmentLoad.height = 20
    fragmentLoad.width = fragmentActions.width
    fragmentLoad.x = fragmentAdd.x + fragmentAdd.width + 5
    fragmentLoad.y = fragmentAdd.y
    fragmentLoad.backgroundColour = colours.menuBackgroundColour
    fragmentLoad.textColour = colours.widgetTextColour
    fragmentLoad.arrowColour = colours.menuArrowColour
    fragmentLoad.outlineColour = colours.menuOutlineColour
    fragmentLoad.changed = function(self)
      fragmentInput.text = self.selectedText
      -- Must be last
      self:setValue(1, false)
    end
  
    -- Add p = play probability
    local fragmentPlayProbabilityLabel = rythmPanel:Label("FragmentPlayProbabilityLabel" .. i)
    fragmentPlayProbabilityLabel.text = "p"
    fragmentPlayProbabilityLabel.tooltip = "Probability that this fragment will be selected"
    fragmentPlayProbabilityLabel.textColour = colours.labelTextColour
    fragmentPlayProbabilityLabel.alpha = 0.5
    fragmentPlayProbabilityLabel.fontSize = 20
    fragmentPlayProbabilityLabel.width = 20
    fragmentPlayProbabilityLabel.x = fragmentInput.x
    fragmentPlayProbabilityLabel.y = fragmentInput.y + fragmentInput.height + 3
  
    local fragmentPlayProbability = rythmPanel:NumBox("FragmentPlayProbability" .. i, 100, 0, 100, true)
    fragmentPlayProbability.unit = Unit.Percent
    fragmentPlayProbability.showLabel = false
    fragmentPlayProbability.tooltip = fragmentPlayProbabilityLabel.tooltip
    fragmentPlayProbability.textColour = colours.widgetTextColour
    fragmentPlayProbability.backgroundColour = colours.widgetBackgroundColour
    fragmentPlayProbability.width = 36
    fragmentPlayProbability.x = fragmentPlayProbabilityLabel.x + fragmentPlayProbabilityLabel.width - 1
    fragmentPlayProbability.y = fragmentPlayProbabilityLabel.y
  
    -- Add r = repeat probability
    local fragmentRepeatProbabilityLabel = rythmPanel:Label("FragmentRepeatProbabilityLabel" .. i)
    fragmentRepeatProbabilityLabel.text = "r"
    fragmentRepeatProbabilityLabel.tooltip = "Probability that this fragment will be repeated"
    fragmentRepeatProbabilityLabel.textColour = colours.labelTextColour
    fragmentRepeatProbabilityLabel.alpha = 0.5
    fragmentRepeatProbabilityLabel.fontSize = 20
    fragmentRepeatProbabilityLabel.width = fragmentPlayProbabilityLabel.width
    fragmentRepeatProbabilityLabel.x = fragmentPlayProbability.x + fragmentPlayProbability.width + 5
    fragmentRepeatProbabilityLabel.y = fragmentPlayProbability.y
  
    local fragmentRepeatProbability = rythmPanel:NumBox("FragmentRepeatProbability" .. i, 100, 0, 100, true)
    fragmentRepeatProbability.unit = Unit.Percent
    fragmentRepeatProbability.showLabel = false
    fragmentRepeatProbability.tooltip = fragmentRepeatProbabilityLabel.tooltip
    fragmentRepeatProbability.textColour = colours.widgetTextColour
    fragmentRepeatProbability.backgroundColour = colours.widgetBackgroundColour
    fragmentRepeatProbability.width = fragmentPlayProbability.width
    fragmentRepeatProbability.x = fragmentRepeatProbabilityLabel.x + fragmentRepeatProbabilityLabel.width - 1
    fragmentRepeatProbability.y = fragmentRepeatProbabilityLabel.y
  
    -- Add d = repeat probability decay
    local fragmentRepeatProbabilityDecayLabel = rythmPanel:Label("FragmentRepeatProbabilityDecayLabel" .. i)
    fragmentRepeatProbabilityDecayLabel.text = "d"
    fragmentRepeatProbabilityDecayLabel.tooltip = "The reduction in repeat probability for each iteration of the fragment"
    fragmentRepeatProbabilityDecayLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    fragmentRepeatProbabilityDecayLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    fragmentRepeatProbabilityDecayLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    fragmentRepeatProbabilityDecayLabel.width = fragmentRepeatProbabilityLabel.width
    fragmentRepeatProbabilityDecayLabel.x = fragmentRepeatProbability.x + fragmentRepeatProbability.width + 5
    fragmentRepeatProbabilityDecayLabel.y = fragmentRepeatProbability.y
  
    local fragmentRepeatProbabilityDecay = rythmPanel:NumBox("FragmentRepeatProbabilityDecay" .. i, 25, 0, 100, true)
    fragmentRepeatProbabilityDecay.unit = Unit.Percent
    fragmentRepeatProbabilityDecay.showLabel = false
    fragmentRepeatProbabilityDecay.tooltip = fragmentRepeatProbabilityDecayLabel.tooltip
    fragmentRepeatProbabilityDecay.textColour = colours.widgetTextColour
    fragmentRepeatProbabilityDecay.backgroundColour = colours.widgetBackgroundColour
    fragmentRepeatProbabilityDecay.width = fragmentRepeatProbability.width
    fragmentRepeatProbabilityDecay.x = fragmentRepeatProbabilityDecayLabel.x + fragmentRepeatProbabilityDecayLabel.width - 1
    fragmentRepeatProbabilityDecay.y = fragmentRepeatProbabilityDecayLabel.y
  
    -- Add m = min repeats
    local fragmentMinRepeatsLabel = rythmPanel:Label("FragmentRepeatProbabilityDecayLabel" .. i)
    fragmentMinRepeatsLabel.text = "m"
    fragmentMinRepeatsLabel.tooltip = "Minimum repeats for this fragment"
    fragmentMinRepeatsLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    fragmentMinRepeatsLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    fragmentMinRepeatsLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    fragmentMinRepeatsLabel.width = fragmentRepeatProbabilityLabel.width
    fragmentMinRepeatsLabel.x = fragmentRepeatProbabilityDecay.x + fragmentRepeatProbabilityDecay.width + 5
    fragmentMinRepeatsLabel.y = fragmentRepeatProbabilityDecay.y
  
    local fragmentMinRepeats = rythmPanel:NumBox("FragmentMinRepeats" .. i, 1, 1, 64, true)
    fragmentMinRepeats.showLabel = false
    fragmentMinRepeats.tooltip = fragmentMinRepeatsLabel.tooltip
    fragmentMinRepeats.textColour = colours.widgetTextColour
    fragmentMinRepeats.backgroundColour = colours.widgetBackgroundColour
    fragmentMinRepeats.width = 26
    fragmentMinRepeats.x = fragmentMinRepeatsLabel.x + fragmentMinRepeatsLabel.width - 1
    fragmentMinRepeats.y = fragmentMinRepeatsLabel.y
  
    -- Randomize fragment probability
    local randomizeFragmentProbabilityLabel = rythmPanel:Label("RandomizeFragmentProbabilityLabel" .. i)
    randomizeFragmentProbabilityLabel.text = "rnd"
    randomizeFragmentProbabilityLabel.tooltip = "Probability that rythmic fragments will be played in random order"
    randomizeFragmentProbabilityLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    randomizeFragmentProbabilityLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    randomizeFragmentProbabilityLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    randomizeFragmentProbabilityLabel.width = 30
    randomizeFragmentProbabilityLabel.x = fragmentLoad.x + fragmentLoad.width + 0
    randomizeFragmentProbabilityLabel.y = fragmentLoad.y
  
    local randomizeFragmentProbability = rythmPanel:NumBox("RandomizeFragmentProbability" .. i, 0, 0, 100, true)
    randomizeFragmentProbability.unit = Unit.Percent
    randomizeFragmentProbability.showLabel = false
    randomizeFragmentProbability.tooltip = "Probability that rythmic fragments will be played in random order"
    randomizeFragmentProbability.textColour = colours.widgetTextColour
    randomizeFragmentProbability.backgroundColour = colours.widgetBackgroundColour
    randomizeFragmentProbability.width = fragmentRepeatProbability.width
    randomizeFragmentProbability.x = randomizeFragmentProbabilityLabel.x + randomizeFragmentProbabilityLabel.width - 1
    randomizeFragmentProbability.y = randomizeFragmentProbabilityLabel.y
  
    -- Reverse fragment probability
    local reverseFragmentProbabilityLabel = rythmPanel:Label("ReverseFragmentProbabilityLabel" .. i)
    reverseFragmentProbabilityLabel.text = "rev"
    reverseFragmentProbabilityLabel.tooltip = "Probability that rythmic fragments will be played backwards"
    reverseFragmentProbabilityLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    reverseFragmentProbabilityLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    reverseFragmentProbabilityLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    reverseFragmentProbabilityLabel.width = randomizeFragmentProbabilityLabel.width
    reverseFragmentProbabilityLabel.x = randomizeFragmentProbabilityLabel.x
    reverseFragmentProbabilityLabel.y = fragmentInput.y + 2
  
    local reverseFragmentProbability = rythmPanel:NumBox("ReverseProbability" .. i, 0, 0, 100, true)
    reverseFragmentProbability.unit = Unit.Percent
    reverseFragmentProbability.showLabel = false
    reverseFragmentProbability.tooltip = reverseFragmentProbabilityLabel.tooltip
    reverseFragmentProbability.textColour = colours.widgetTextColour
    reverseFragmentProbability.backgroundColour = colours.widgetBackgroundColour
    reverseFragmentProbability.width = fragmentRepeatProbability.width
    reverseFragmentProbability.x = reverseFragmentProbabilityLabel.x + reverseFragmentProbabilityLabel.width - 1
    reverseFragmentProbability.y = reverseFragmentProbabilityLabel.y
  
    -- Rest probability
    local restProbabilityLabel = rythmPanel:Label("RestProbabilityLabel" .. i)
    restProbabilityLabel.text = "rst"
    restProbabilityLabel.tooltip = "Probability of rest randomization"
    restProbabilityLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    restProbabilityLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    restProbabilityLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    restProbabilityLabel.width = randomizeFragmentProbabilityLabel.width
    restProbabilityLabel.x = reverseFragmentProbabilityLabel.x
    restProbabilityLabel.y = fragmentMinRepeats.y
  
    local restProbability = rythmPanel:NumBox("RestProbability" .. i, 0, 0, 100, true)
    restProbability.unit = Unit.Percent
    restProbability.showLabel = false
    restProbability.tooltip = restProbabilityLabel.tooltip
    restProbability.textColour = colours.widgetTextColour
    restProbability.backgroundColour = colours.widgetBackgroundColour
    restProbability.width = fragmentRepeatProbability.width
    restProbability.x = restProbabilityLabel.x + restProbabilityLabel.width - 1
    restProbability.y = restProbabilityLabel.y

    table.insert(paramsPerFragment, {fragmentInput=fragmentInput, fragmentInputDirty=false, fragmentActive=fragmentActive, lockedForEvolve=lockedForEvolve, fragmentPlayProbability=fragmentPlayProbability, randomizeFragmentProbability=randomizeFragmentProbability, reverseFragmentProbability=reverseFragmentProbability, restProbability=restProbability, fragmentRepeatProbability=fragmentRepeatProbability, fragmentRepeatProbabilityDecay=fragmentRepeatProbabilityDecay, fragmentMinRepeats=fragmentMinRepeats})
  end
  return paramsPerFragment
end

local rythmicFragments = {
  resolutions = resolutions,
  getParamsPerFragment = getParamsPerFragment,
  getDuration = getDuration,
  evolveFragments = evolveFragments,
  clearResolutionsForEvolve = clearResolutionsForEvolve,
  getSelectedResolutions = getSelectedResolutions,
  getFragmentState = getFragmentState,
  setFragmentState = setFragmentState,
  flashFragmentActive = flashFragmentActive,
  createFragmentDefinition = createFragmentDefinition,
  getFragmentInputText = getFragmentInputText,
  fragmentDefinitionToResolutionNames = fragmentDefinitionToResolutionNames,
  setMaxResolutionIndex = setMaxResolutionIndex,
}

-------------------------------------------------------------------------------
-- Sequencer using rythmic fragments
-------------------------------------------------------------------------------

local isPlaying = false
local heldNotes = {}

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "F637EC"
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"
local knobFillColour = "E6D5B8" -- Light

local colours = {
  backgroundColour = backgroundColour,
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = labelTextColour,
  menuBackgroundColour = menuBackgroundColour,
  menuArrowColour = menuArrowColour,
  menuOutlineColour = menuOutlineColour,
  backgroundColourOff = backgroundColourOff,
  backgroundColourOn = backgroundColourOn,
  textColourOff = textColourOff,
  textColourOn = textColourOn,
  knobFillColour = knobFillColour,
}

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

local sequencerPanel = Panel("RandomNoteGenerator")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 36

local settingsPanel = Panel("Settings")
settingsPanel.backgroundColour = backgroundColour
settingsPanel.x = sequencerPanel.x
settingsPanel.y = sequencerPanel.y + sequencerPanel.height + 5
settingsPanel.width = 700
settingsPanel.height = 30

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "505050"
rythmPanel.x = settingsPanel.x
rythmPanel.y = settingsPanel.y + settingsPanel.height
rythmPanel.width = 700
rythmPanel.height = 218

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("SequencerLabel")
sequencerLabel.text = "Fragment Sequencer"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.width = 180

local activeButton = sequencerPanel:OnOffButton("Active", true)
activeButton.tooltip = "Deactivate to bypass sequencer"
activeButton.backgroundColourOff = "#ff084486"
activeButton.backgroundColourOn = "#ff02ACFE"
activeButton.textColourOff = "#ff22FFFF"
activeButton.textColourOn = "#efFFFFFF"
activeButton.displayName = "Active"
activeButton.fillColour = "#dd000061"
activeButton.size = {102,22}
activeButton.x = sequencerPanel.width - (activeButton.width * 2) - 5
activeButton.y = 5

local holdButton = sequencerPanel:OnOffButton("HoldOnOff", false)
holdButton.tooltip = "Activate to hold notes"
holdButton.backgroundColourOff = "#ff084486"
holdButton.backgroundColourOn = "#ff02ACFE"
holdButton.textColourOff = "#ff22FFFF"
holdButton.textColourOn = "#efFFFFFF"
holdButton.displayName = "Hold"
holdButton.fillColour = "#dd000061"
holdButton.size = {102,22}
holdButton.x = activeButton.x + activeButton.width + 5
holdButton.y = activeButton.y
holdButton.changed = function(self)
  if self.value == false then
    heldNotes = {}
  end
end

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

local widgetWidth = 659 / 5

local playMode = settingsPanel:Menu("PlayMode", {"As Played", "Up", "Down", "Random", "Mono", "Duo", "Chord"})
playMode.showLabel = false
playMode.tooltip = "Select Play Mode"
playMode.x = 5
playMode.y = 0
playMode.width = widgetWidth
playMode.height = 20
playMode.backgroundColour = menuBackgroundColour
playMode.textColour = widgetTextColour
playMode.arrowColour = menuArrowColour
playMode.outlineColour = menuOutlineColour

local gateInput = settingsPanel:NumBox("Gate", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.textColour = widgetTextColour
gateInput.backgroundColour = widgetBackgroundColour
gateInput.displayName = "Gate"
gateInput.tooltip = "Note gate"
gateInput.width = widgetWidth
gateInput.x = playMode.x + playMode.width + 10
gateInput.y = playMode.y

local gateRandomization = settingsPanel:NumBox("GateRand", 0, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.width = widgetWidth
gateRandomization.x = gateInput.x + gateInput.width + 10
gateRandomization.y = gateInput.y

local velocityInput = settingsPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Default velocity for played notes"
velocityInput.width = widgetWidth
velocityInput.x = gateRandomization.x + gateRandomization.width + 10
velocityInput.y = gateRandomization.y

local velocityAccent = settingsPanel:NumBox("VelocityAccent", 64, 1, 127, true)
velocityAccent.textColour = widgetTextColour
velocityAccent.backgroundColour = widgetBackgroundColour
velocityAccent.displayName = "Accent"
velocityAccent.tooltip = "Velocity used at the start of a fragment (if fragment has multiple resolutions)"
velocityAccent.width = widgetWidth
velocityAccent.x = velocityInput.x + velocityInput.width + 10
velocityAccent.y = velocityInput.y

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythm"
rythmLabel.alpha = 0.75
rythmLabel.fontSize = 15
rythmLabel.width = 156

local evolveFragmentProbability = rythmPanel:NumBox("EvolveFragmentProbability", 0, 0, 100, true)
evolveFragmentProbability.unit = Unit.Percent
evolveFragmentProbability.textColour = widgetTextColour
evolveFragmentProbability.backgroundColour = widgetBackgroundColour
evolveFragmentProbability.displayName = "Evolve"
evolveFragmentProbability.tooltip = "Set the probability that fragments will change over time, using the resolutions present in the fragments"
evolveFragmentProbability.width = 120
evolveFragmentProbability.height = 18
evolveFragmentProbability.x = rythmLabel.x + rythmLabel.width
evolveFragmentProbability.y = rythmLabel.y

local randomizeCurrentResolutionProbability = rythmPanel:NumBox("RandomizeCurrentResolutionProbability", 0, 0, 100, true)
randomizeCurrentResolutionProbability.unit = Unit.Percent
randomizeCurrentResolutionProbability.textColour = widgetTextColour
randomizeCurrentResolutionProbability.backgroundColour = widgetBackgroundColour
randomizeCurrentResolutionProbability.displayName = "Adjust"
randomizeCurrentResolutionProbability.tooltip = "Set the probability that evolve will adjust resolutions, based on the resolutions present in the fragments"
randomizeCurrentResolutionProbability.width = evolveFragmentProbability.width
randomizeCurrentResolutionProbability.height = evolveFragmentProbability.height
randomizeCurrentResolutionProbability.x = evolveFragmentProbability.x + evolveFragmentProbability.width + 10
randomizeCurrentResolutionProbability.y = evolveFragmentProbability.y

local biasLabel = rythmPanel:Label("BiasLabel")
biasLabel.text = "Bias slow > fast"
biasLabel.tooltip = "Adjust bias: <50=more slow resolutions, >50=more fast resolutions"
biasLabel.alpha = 0.5
biasLabel.fontSize = 15
biasLabel.width = 90
biasLabel.height = randomizeCurrentResolutionProbability.height
biasLabel.x = randomizeCurrentResolutionProbability.x + randomizeCurrentResolutionProbability.width + 10
biasLabel.y = randomizeCurrentResolutionProbability.y

local adjustBias = rythmPanel:Knob("Bias", 50, 0, 100, true)
adjustBias.showLabel = false
adjustBias.showValue = false
adjustBias.displayName = "Bias"
adjustBias.tooltip = biasLabel.tooltip
adjustBias.backgroundColour = widgetBackgroundColour
adjustBias.fillColour = knobFillColour
adjustBias.outlineColour = widgetTextColour
adjustBias.width = 18
adjustBias.height = biasLabel.height
adjustBias.x = biasLabel.x + biasLabel.width
adjustBias.y = biasLabel.y

local minResLabel = rythmPanel:Label("MinResolutionsLabel")
minResLabel.text = "Min resolution"
minResLabel.alpha = 0.5
minResLabel.fontSize = 15
minResLabel.width = 90
minResLabel.height = adjustBias.height
minResLabel.x = adjustBias.x + adjustBias.width + 10
minResLabel.y = adjustBias.y

local minResolution = rythmPanel:Menu("MinResolution", resolutions.getResolutionNames())
minResolution.displayName = minResLabel.text
minResolution.tooltip = "The highest allowed resolution for evolve adjustments"
minResolution.selected = 26
minResolution.showLabel = false
minResolution.width = 60
minResolution.height = adjustBias.height
minResolution.backgroundColour = widgetBackgroundColour
minResolution.textColour = widgetTextColour
minResolution.arrowColour = menuArrowColour
minResolution.outlineColour = menuOutlineColour
minResolution.x = minResLabel.x + minResLabel.width
minResolution.y = minResLabel.y
minResolution.changed = function(self)
  rythmicFragments.setMaxResolutionIndex(self.value)
end
minResolution:changed()

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, rythmLabel, colours)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function getNotes(heldNoteIndex)
  -- Reset notes table
  local notes = {} -- Holds the note(s) that plays at this position

  -- Increment held note position
  heldNoteIndex = heldNoteIndex + 1
  if heldNoteIndex > #heldNotes then
    heldNoteIndex = 1
  end

  -- Add notes to play
  -- "As Played", "Up", "Down", "Random", "Mono", "Duo", "Chord"
  local sortedNotes = {}
  for _,v in ipairs(heldNotes) do
    table.insert(sortedNotes, v.note)
  end
  if playMode.selectedText == "Down" then
    table.sort(sortedNotes, function(a,b) return a > b end)
  else
    table.sort(sortedNotes)
  end

  if playMode.selectedText == "As Played" then
    table.insert(notes, heldNotes[heldNoteIndex].note)
  elseif playMode.selectedText == "Up" then
    table.insert(notes, sortedNotes[heldNoteIndex])
  elseif playMode.selectedText == "Down" then
    table.insert(notes, sortedNotes[heldNoteIndex])
  elseif playMode.selectedText == "Random" then
    table.insert(notes, gem.getRandomFromTable(sortedNotes))
  elseif playMode.selectedText == "Mono" then
    -- Last held
    table.insert(notes, heldNotes[#heldNotes].note)
  elseif playMode.selectedText == "Duo" then
    -- Lowest and highest held notes
    table.insert(notes, sortedNotes[1])
    if #heldNotes > 1 then
      table.insert(notes, sortedNotes[#sortedNotes])
    end
  elseif playMode.selectedText == "Chord" then
    -- All held notes
    for i=1,#sortedNotes do
      table.insert(notes, sortedNotes[i])
    end
  end
  print("#notes", #notes)
  return notes, heldNoteIndex
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function stopPlaying()
  isPlaying = false
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive.textColourOn = "black"
  end
end

function play()
  local previous = nil
  local notes = {}
  local heldNoteIndex = 0
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatCount = 0
  local fragmentRepeatProbability = 0
  local duration = nil
  local rest = false
  local reverseFragment = false
  local durationCounter = 0
  while isPlaying do
    local offset = 0
    if #heldNotes == 0 then
      local buffer = 1 -- How long to wait for notes before stopping the sequencer
      wait(buffer)
      print("waiting for heldNotes", buffer)
      offset = offset + buffer
    end
    if #heldNotes == 0 then
      print("#heldNotes == 0 - stopping sequencer")
      stopPlaying()
      break
    end
    notes, heldNoteIndex = getNotes(heldNoteIndex)
    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = rythmicFragments.getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
    local gate = gem.randomizeValue(gateInput.value, gateInput.min, gateInput.max, gateRandomization.value)
    local doPlayNote = gate > 0 and rest == false and #notes > 0 and type(duration) == "number" and activeButton.value == true
    if doPlayNote then
      -- TODO Add option to accent every n-th beat?
      local velocity = velocityInput.value
      -- Use accent value in fragment start, if there is more than one resolution defined in the fragment
      if isFragmentStart and #activeFragment.f > 1 then
        velocity = velocityAccent.value
      end
      velocity = velocity + heldNotes[heldNoteIndex].velocity / 2 -- 50% between played velocity and sequencer velocity
      for _,note in ipairs(notes) do
        playNote(note, velocity, beat2ms(resolutions.getPlayDuration(duration, gate)) - offset)
      end
    end
    if type(duration) == "nil" then
      duration = 1 -- Failsafe
    end
    waitBeat(duration)
    durationCounter = durationCounter + duration
    if durationCounter >= 4 then
      durationCounter = 0 -- Reset counter
      if gem.getRandomBoolean(evolveFragmentProbability.value) then
        previous = rythmicFragments.evolveFragments(previous, randomizeCurrentResolutionProbability.value, adjustBias.value)
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  if holdButton.value == true then
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        -- When hold button is active
        -- we remove the note from held notes
        -- if table has more than one note
        if #heldNotes > 1 then
          table.remove(heldNotes, i)
        end
        break
      end
    end
  end
  table.insert(heldNotes, e)
  if #heldNotes == 1 and isPlaying == false then
    isPlaying = true
    spawn(play)
  end
  if activeButton.value == false then
    postEvent(e)
  end
end

function onRelease(e)
  if holdButton.value == false then
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        table.remove(heldNotes, i)
      end
    end
    postEvent(e)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local fragmentInputData = {}

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  return {fragmentInputData}
end

function onLoad(data)
  local fragmentInputData = data[1]

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end
end
