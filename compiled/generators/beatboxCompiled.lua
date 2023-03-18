-- generators/beatbox -- 
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

local function avg(t)
  local sum = 0
  for _,v in pairs(t) do -- Get the sum of all numbers in t
    sum = sum + v
  end
  return sum / #t
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
  inc = inc,
  avg = avg,
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
-- Beatbox using rythmic fragments (Fragmented Beats)
-------------------------------------------------------------------------------

local playIndex = 1
local beatResolution = 1
local beatBase = 4
local noteListen = nil
local numNotes = 8
local voices = 8
local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local playingVoices = {}
local playingIndex = {}
local roundCounterPerVoice = {}
local partInEditMode = nil
local paramsPerNote = {}
local paramsPerFragment = {}
local bounds = {}
local recallStoredState = nil -- Holds the index of the stored fragment state to recall
local storedFragments = {} -- Holds stored fragment states
local partOrder = {} -- Holds the playing order of the parts

-- Add maps for different setups
local noteMap = {36,38,42,39,41,49,54,66}
local noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Cymbal", "Tambourine", "Perc"}

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "3AB0FF"
local menuBackgroundColour = "01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"
local knobFillColour = "E6D5B8" -- Light
local outlineColour = "#FFB5FF"

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

local notePanel = Panel("Notes")
notePanel.backgroundColour = "202020"
notePanel.x = settingsPanel.x
notePanel.y = settingsPanel.y + settingsPanel.height + 5
notePanel.width = 700
notePanel.height = 106

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "505050"
rythmPanel.x = notePanel.x
rythmPanel.y = notePanel.y + notePanel.height + 5
rythmPanel.width = 700
rythmPanel.height = 470

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("SequencerLabel")
sequencerLabel.text = "Fragmented Beats"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.width = 160

meter = sequencerPanel:AudioMeter("OutputLevel", Part, false, 0, true)
meter.height = sequencerLabel.height
meter.width = sequencerLabel.width
meter.x = sequencerLabel.x + sequencerLabel.width + 15
meter.y = sequencerLabel.y
meter["0dBColour"] = "red"
meter["3dBColour"] = "orange"
meter["6dBColour"] = "yellow"
meter["10dBColour"] = "green"

local channelButton = sequencerPanel:OnOffButton("ChannelButton", false)
channelButton.backgroundColourOff = backgroundColourOff
channelButton.backgroundColourOn = backgroundColourOn
channelButton.textColourOff = textColourOff
channelButton.textColourOn = textColourOn
channelButton.displayName = "Multichannel"
channelButton.tooltip = "When multichannel mode is enabled, each voice is sent to a separate channel"
channelButton.size = {100,22}
channelButton.x = sequencerPanel.width - (channelButton.width * 3) - 10
channelButton.y = 5

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = backgroundColourOff
autoplayButton.backgroundColourOn = backgroundColourOn
autoplayButton.textColourOff = textColourOff
autoplayButton.textColourOn = textColourOn
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = channelButton.size
autoplayButton.x = channelButton.x + channelButton.width + 5
autoplayButton.y = channelButton.y

local playButton = sequencerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = backgroundColourOff
playButton.backgroundColourOn = backgroundColourOn
playButton.textColourOff = textColourOff
playButton.textColourOn = textColourOn
playButton.displayName = "Play"
playButton.size = autoplayButton.size
playButton.x = autoplayButton.x + autoplayButton.width + 5
playButton.y = channelButton.y
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

local widgetHeight = 20
local widgetWidth = 659 / 4

local timeSignatures = {"4/4", "3/4", "5/4", "6/8"}
local timeSignature = settingsPanel:Menu("TimeSignature", timeSignatures)
timeSignature.tooltip = "Select a time signature - this mostly just affects the accents"
timeSignature.showLabel = false
timeSignature.backgroundColour = colours.menuBackgroundColour
timeSignature.textColour = colours.widgetTextColour
timeSignature.arrowColour = colours.menuArrowColour
timeSignature.outlineColour = colours.menuOutlineColour
timeSignature.height = widgetHeight
timeSignature.width = widgetWidth
timeSignature.x = 5
timeSignature.y = 0
timeSignature.changed = function(self)
  local signature = {}
  for w in string.gmatch(self.selectedText, "%d+") do
    table.insert(signature, w)
  end
  beatBase = tonumber(signature[1])
  beatResolution = resolutions.getResolution(gem.getIndexFromValue("1/" .. signature[2], resolutions.getResolutionNames()))
end

local velocityInput = settingsPanel:NumBox("Velocity", 90, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Velocity amount triggered on beats that are not accented"
velocityInput.height = widgetHeight
velocityInput.width = timeSignature.width
velocityInput.x = timeSignature.x + timeSignature.width + 10
velocityInput.y = timeSignature.y

local velocityAccent = settingsPanel:NumBox("VelocityAccent", 127, 1, 127, true)
velocityAccent.textColour = widgetTextColour
velocityAccent.backgroundColour = widgetBackgroundColour
velocityAccent.displayName = "Accent"
velocityAccent.tooltip = "Velocity amount triggered on accented beats"
velocityAccent.height = widgetHeight
velocityAccent.width = velocityInput.width
velocityAccent.x = velocityInput.x + velocityInput.width + 10
velocityAccent.y = velocityInput.y

local templates = {
  "Tools...",
  --- Note Maps --
  "--- Mappings ---",
  "BeatBox Anthology 2",
  "Drum Designer",
  "Drumulation",
  "Prime 8",
  "Program 24",
  "Soul Drums",
  "Super 7",
  --- Templates ---
  "--- Templates ---",
  "Kick on down, snare on up",
  "Four on the floor",
  --- Notes ---
  "--- Notes ---",
  "Mute all",
  "Unmute all",
  "Toggle mute",
  "Set all note probabilities to 100%",
  "Set all note probabilities to 0%",
  "Randomize note probabilities",
  "Randomize note triggers",
  --- Rests ---
  "--- Rests ---",
  "All rests off",
  "Randomize rests",
  --- Rythmic fragments ---
  "--- Rythmic fragments ---",
  "Clear fragments",
  "Randomize fragments",
  "Randomize fragments (single)",
  "Randomize fragments (slow)",
  "Randomize fragments (extended)",
  --- Part sources ---
  "--- Part sources ---",
  "Part to source",
  "All sources on",
  "All sources off",
  "Randomize source probability",
  --- All settings ---
  "--- All settings ---",
  "Set to default",
  "Set to zero",
  "Randomize",
}
local templateMenu = settingsPanel:Menu("Templates", templates)
templateMenu.tooltip = "Select a tool - NOTE: Will change current settings!"
templateMenu.showLabel = false
templateMenu.height = widgetHeight
templateMenu.width = widgetWidth
templateMenu.x = velocityAccent.x + velocityAccent.width + 10
templateMenu.y = velocityAccent.y
templateMenu.backgroundColour = colours.menuBackgroundColour
templateMenu.textColour = colours.widgetTextColour
templateMenu.arrowColour = colours.menuArrowColour
templateMenu.outlineColour = colours.menuOutlineColour
templateMenu.changed = function(self)
  if self.value == 1 then
    return
  end
  for part,v in ipairs(paramsPerNote) do
    for source,w in ipairs(v.sourceSelectors) do
      if self.selectedText == "Part to source" then
        if part == source then
          w:setValue(100)
        else
          w:setValue(0)
        end
      elseif self.selectedText == "Randomize" or self.selectedText == "Randomize source probability" then
        w:setValue(gem.getRandom(100))
      elseif self.selectedText == "All sources on" or self.selectedText == "Set to default" then
        w:setValue(100)
      elseif self.selectedText == "All sources off" or self.selectedText == "Set to zero" then
        w:setValue(0)
      end
    end
    if self.selectedText == "BeatBox Anthology 2" then
      noteMap = {36,38,42,39,41,49,54,66}
      noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Cymbal", "Tambourine", "Perc"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Drum Designer" then
      noteMap = {36,38,40,42,44,46,49,39}
      noteLabels = {"Kick", "Snare 1", "Snare 2", "Hihat 1", "Hihat 2", "Open HH", "Cymbal", "Clap"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Drumulation" then
      noteMap = {36,38,42,39,43,46,37,41}
      noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Open HH", "Rimshot", "Cowbell"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Prime 8" then
      noteMap = {36,38,42,39,41,49,37,47}
      noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Cymbal", "Rimshot", "Cowbell"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Program 24" then
      noteMap = {36,38,42,39,41,49,37,48}
      noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Cymbal", "Snare 2", "Bongo"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Soul Drums" then
      noteMap = {36,38,42,39,41,49,37,54}
      noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Cymbal", "Rimshot", "Tambourine"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Super 7" then
      noteMap = {36,38,42,39,41,49,37,50}
      noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Cymbal", "Rimshot", "Perc"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Mute all" then
      v.mute:setValue(true)
    elseif self.selectedText == "Unmute all" then
      v.mute:setValue(false)
    elseif self.selectedText == "All rests off" then
      v.restDownBeatProbability:setValue(0)
      v.restUpBeatProbability:setValue(0)
      v.restFirstInFragmentProbability:setValue(0)
    elseif self.selectedText == "Set all note probabilities to 100%" then
      v.noteProbability:setValue(100)
    elseif self.selectedText == "Set all note probabilities to 0%" then
      v.noteProbability:setValue(0)
    elseif self.selectedText == "Toggle mute" then
      v.mute:setValue(v.mute.value == false)
    elseif self.selectedText == "Clear fragments" then
      paramsPerFragment[part].fragmentInput.text = ""
    elseif self.selectedText == "Randomize fragments" then
      paramsPerFragment[part].fragmentInput.text = getRandomFragment(1)
    elseif self.selectedText == "Randomize fragments (single)" then
      paramsPerFragment[part].fragmentInput.text = getRandomFragment(2)
    elseif self.selectedText == "Randomize fragments (extended)" then
      paramsPerFragment[part].fragmentInput.text = getRandomFragment(3)
    elseif self.selectedText == "Randomize fragments (slow)" then
      paramsPerFragment[part].fragmentInput.text = getRandomFragment(4)
    elseif self.selectedText == "Randomize note probabilities" then
      v.noteProbability:setValue(gem.getRandom(100))
    elseif self.selectedText == "Randomize note triggers" then
      v.noteInput:setValue(gem.getRandom(21, 108))
    elseif self.selectedText == "Randomize rests" then
      v.restDownBeatProbability:setValue(gem.getRandom(100))
      v.restUpBeatProbability:setValue(gem.getRandom(100))
      v.restFirstInFragmentProbability:setValue(gem.getRandom(100))
    elseif self.selectedText == "Randomize" then
      paramsPerFragment[part].fragmentInput.text = getRandomFragment(1)
      v.mute:setValue(false)
      v.accentFragmentStart:setValue(gem.getRandomBoolean(25))
      v.accentDownBeat:setValue(gem.getRandomBoolean(25))
      v.accentUpBeat:setValue(gem.getRandomBoolean(25))
      --v.accent:setValue(gem.getRandom(v.accent.max))
      v.restDownBeatProbability:setValue(gem.getRandom(25))
      v.restUpBeatProbability:setValue(gem.getRandom(25))
      v.restFirstInFragmentProbability:setValue(gem.getRandom(25))
      v.noteProbability:setValue(gem.getRandom(100))
    elseif self.selectedText == "Set to default" then
      if part == 1 then
        paramsPerFragment[part].fragmentInput.text = "1/8"
      else
        paramsPerFragment[part].fragmentInput.text = ""
      end
      v.mute:setValue(false)
      v.accentFragmentStart:setValue(false)
      v.accentDownBeat:setValue(false)
      v.accentUpBeat:setValue(false)
      --v.accent:setValue(0)
      v.restDownBeatProbability:setValue(0)
      v.restUpBeatProbability:setValue(0)
      v.restFirstInFragmentProbability:setValue(0)
      v.noteProbability:setValue(100)
    elseif self.selectedText == "Set to zero" then
      paramsPerFragment[part].fragmentInput.text = ""
      v.mute:setValue(false)
      v.accentFragmentStart:setValue(false)
      v.accentDownBeat:setValue(false)
      v.accentUpBeat:setValue(false)
      --v.accent:setValue(0)
      v.restFirstInFragmentProbability:setValue(0)
      v.noteProbability:setValue(0)
      v.restDownBeatProbability:setValue(0)
      v.restUpBeatProbability:setValue(0)
    elseif self.selectedText == "Kick on down, snare on up" then
      if part == 1 then
        v.mute:setValue(false)
        v.sourceSelectors[1]:setValue(100)
        v.sourceSelectors[2]:setValue(100)
        v.noteProbability:setValue(100)
        v.restDownBeatProbability:setValue(0)
        v.restUpBeatProbability:setValue(100)
      elseif part == 2 then
        v.mute:setValue(false)
        v.sourceSelectors[1]:setValue(100)
        v.sourceSelectors[2]:setValue(100)
        v.noteProbability:setValue(100)
        v.restDownBeatProbability:setValue(100)
        v.restUpBeatProbability:setValue(0)
      end
    elseif self.selectedText == "Four on the floor" then
      if part == 1 then
        v.mute:setValue(false)
        v.sourceSelectors[1]:setValue(100)
        v.sourceSelectors[2]:setValue(100)
        v.noteProbability:setValue(100)
        v.restDownBeatProbability:setValue(0)
        v.restUpBeatProbability:setValue(0)
      elseif part == 2 then
        v.mute:setValue(false)
        v.sourceSelectors[1]:setValue(100)
        v.sourceSelectors[2]:setValue(100)
        v.noteProbability:setValue(100)
        v.restDownBeatProbability:setValue(100)
        v.restUpBeatProbability:setValue(0)
      end
    end
  end
  if self.selectedText == "Four on the floor" or self.selectedText == "Kick on down, snare on up" then
    paramsPerFragment[1].fragmentInput.text = "1/4"
  end
  -- Must be last
  self:setValue(1, false)
end

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local rowSpacing = 3

local noteLabel = notePanel:Label("NotesLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Select notes"
noteLabel.alpha = 0.75
noteLabel.fontSize = 15
noteLabel.width = 60
noteLabel.x = 0
noteLabel.y = 0

local all0Percent = notePanel:Button("All0Percent")
all0Percent.visible = false
all0Percent.displayName = "Set 0%"
all0Percent.tooltip = "Set all fragment probabilities to 0"
all0Percent.persistent = false
all0Percent.height = 18
all0Percent.width = 90
all0Percent.x = notePanel.width - (all0Percent.width * 3) - 24
all0Percent.y = rowSpacing
all0Percent.changed = function()
  if type(partInEditMode) == "number" then
    for _,v in ipairs(paramsPerNote[partInEditMode].sourceSelectors) do
      v:setValue(0)
    end
  end
end

local all100Percent = notePanel:Button("All100Percent")
all100Percent.visible = false
all100Percent.displayName = "Set 100%"
all100Percent.tooltip = "Set all fragment probabilities to 100"
all100Percent.persistent = false
all100Percent.height = all0Percent.height
all100Percent.width = all0Percent.width
all100Percent.x = all0Percent.x + all0Percent.width + 10
all100Percent.y = rowSpacing
all100Percent.changed = function()
  if type(partInEditMode) == "number" then
    for _,v in ipairs(paramsPerNote[partInEditMode].sourceSelectors) do
      v:setValue(100)
    end
  end
end

local setRandomPercent = notePanel:Button("SetRandomPercent")
setRandomPercent.visible = false
setRandomPercent.displayName = "Set random %"
setRandomPercent.tooltip = "Randomize fragment probabilities"
setRandomPercent.persistent = false
setRandomPercent.height = all0Percent.height
setRandomPercent.width = all0Percent.width
setRandomPercent.x = all100Percent.x + all100Percent.width + 10
setRandomPercent.y = rowSpacing
setRandomPercent.changed = function()
  if type(partInEditMode) == "number" then
    for _,v in ipairs(paramsPerNote[partInEditMode].sourceSelectors) do
      v:setValue(gem.getRandom(100))
    end
  end
end

for i=1,numNotes do
  local noteInputLabel = notePanel:Label("Label" .. i)
  noteInputLabel.tooltip = "Editable label for this note trigger"
  noteInputLabel.editable = true
  noteInputLabel.text = noteLabels[i]
  noteInputLabel.backgroundColour = menuBackgroundColour
  noteInputLabel.backgroundColourWhenEditing = "#cccccc"
  noteInputLabel.textColour = "9f9f9f"
  noteInputLabel.width = 76
  noteInputLabel.height = 22
  noteInputLabel.x = ((noteInputLabel.width + 10) * (i - 1)) + 10
  noteInputLabel.y = noteLabel.height + 5

  local noteInput = notePanel:NumBox("TriggerNote" .. i, noteMap[i], 0, 127, true)
  noteInput.displayName = "Note"
  noteInput.tooltip = "The note to trigger"
  noteInput.unit = Unit.MidiKey
  noteInput.showLabel = false
  noteInput.backgroundColour = menuBackgroundColour
  noteInput.textColour = menuTextColour
  noteInput.height = 22
  noteInput.width = 37
  noteInput.x = noteInputLabel.x
  noteInput.y = noteInputLabel.y + noteInputLabel.height + rowSpacing

  local noteProbability = notePanel:NumBox("NoteProbability" .. i, 100, 0, 100, true)
  noteProbability.tooltip = "Probability that note will be played"
  noteProbability.unit = Unit.Percent
  noteProbability.showLabel = false
  noteProbability.backgroundColour = menuBackgroundColour
  noteProbability.textColour = menuTextColour
  noteProbability.height = noteInput.height
  noteProbability.width = noteInput.width
  noteProbability.x = noteInput.x + noteInput.width + rowSpacing
  noteProbability.y = noteInput.y

  local listen = notePanel:OnOffButton("Listen" .. i)
  listen.displayName = "L"
  listen.tooltip = "Note learn"
  listen.persistent = false
  listen.textColourOff = "white"
  listen.backgroundColourOn = "green"
  listen.normalImage = "../resources/icons/headphone_inactive_grey.png"
  listen.pressedImage = "../resources/icons/headphone_active_white_no_check.png"
  listen.height = 24
  listen.width = 24
  listen.x = noteInput.x
  listen.y = noteInput.y + noteInput.height + rowSpacing
  listen.changed = function(self)
    if self.value then
      noteListen = i
    else
      noteListen = nil
    end
  end

  local edit = notePanel:OnOffButton("Edit" .. i)
  edit.displayName = "E"
  edit.tooltip = "Edit note details"
  edit.persistent = false
  edit.textColourOff = "white"
  edit.backgroundColourOn = "orange"
  edit.normalImage = "../resources/icons/edit_inactive_grey.png"
  edit.pressedImage = "../resources/icons/edit_active_white_no_check.png"
  edit.height = listen.height
  edit.width = listen.width
  edit.x = listen.x + listen.width + 2
  edit.y = listen.y
  edit.changed = function(self)
    if type(partInEditMode) == "nil" then
      for j,v in ipairs(paramsPerNote) do
        local isVisible = i == j
        if isVisible then
          partInEditMode = j
          --noteLabel.text = v.noteInputLabel.text
          -- Remember bounds
          bounds = {
            noteInputLabel=v.noteInputLabel.bounds,
            noteInput=v.noteInput.bounds,
            noteProbability=v.noteProbability.bounds,
            listen=v.listen.bounds,
            edit=v.edit.bounds,
            mute=v.mute.bounds
          }
          -- Set bounds for edit
          v.noteInputLabel.bounds = paramsPerNote[1].noteInputLabel.bounds
          v.noteInput.bounds = paramsPerNote[1].noteInput.bounds
          v.noteProbability.bounds = paramsPerNote[1].noteProbability.bounds
          v.listen.bounds = paramsPerNote[1].listen.bounds
          v.edit.bounds = paramsPerNote[1].edit.bounds
          v.mute.bounds = paramsPerNote[1].mute.bounds
        end
        for _,w in ipairs(v.sourceSelectors) do
          w.visible = isVisible
        end
        v.sourceSelectorAll.visible = isVisible
        v.noteInputLabel.visible = isVisible
        v.noteInput.visible = isVisible
        v.noteProbability.visible = isVisible
        v.accent.visible = isVisible
        v.accentTable.visible = isVisible
        v.pitch.visible = isVisible
        v.pitchTable.visible = isVisible
        v.pitchChangeProbability.visible = isVisible
        v.accentFragmentStart.visible = isVisible
        v.accentDownBeat.visible = isVisible
        v.accentUpBeat.visible = isVisible
        v.restFirstInFragmentProbability.visible = isVisible
        v.restDownBeatProbability.visible = isVisible
        v.restUpBeatProbability.visible = isVisible
        v.sourceLabel.visible = isVisible
        v.restLabel.visible = isVisible
        v.accentLabel.visible = isVisible
        v.listen.visible = isVisible
        v.edit.visible = isVisible
        v.edit.displayName = "X"
        v.mute.visible = isVisible
      end
      all0Percent.visible = true
      all100Percent.visible = true
      setRandomPercent.visible = true
    else
      for j,v in ipairs(paramsPerNote) do
        if i == j then
          v.noteInputLabel.bounds = bounds.noteInputLabel
          v.noteInput.bounds = bounds.noteInput
          v.noteProbability.bounds = bounds.noteProbability
          v.listen.bounds = bounds.listen
          v.edit.bounds = bounds.edit
          v.mute.bounds = bounds.mute
        end
        v.noteInputLabel.visible = true
        v.noteInput.visible = true
        v.noteProbability.visible = true
        v.listen.visible = true
        v.mute.visible = true
        v.edit.visible = true
        v.edit.displayName = "E"
        v.accent.visible = false
        v.accentTable.visible = false
        v.pitch.visible = false
        v.pitchTable.visible = false
        v.pitchChangeProbability.visible = false
        v.accentDownBeat.visible = false
        v.accentUpBeat.visible = false
        v.accentFragmentStart.visible = false
        v.restFirstInFragmentProbability.visible = false
        v.restDownBeatProbability.visible = false
        v.restUpBeatProbability.visible = false
        v.accentLabel.visible = false
        v.sourceLabel.visible = false
        v.restLabel.visible = false
        v.sourceSelectorAll.visible = false
        for _,w in ipairs(v.sourceSelectors) do
          w.visible = false
        end
      end
      all0Percent.visible = false
      all100Percent.visible = false
      setRandomPercent.visible = false
      partInEditMode = nil
    end
    --noteLabel.text = "Drums"
  end

  local mute = notePanel:OnOffButton("Mute" .. i)
  mute.displayName = "M"
  mute.tooltip = "Mute note"
  mute.textColourOff = "white"
  mute.backgroundColourOn = "red"
  mute.normalImage = "../resources/icons/mute_active_white_no_check.png"
  mute.pressedImage = "../resources/icons/mute_inactive_grey.png"
  mute.height = edit.height
  mute.width = edit.width
  mute.x = edit.x + edit.width + 2
  mute.y = edit.y

  local accentLabel = notePanel:Label("AccentLabel" .. i)
  accentLabel.visible = false
  accentLabel.text = "Accent/Pitch"
  accentLabel.tooltip = "Set accents and pitch offsets"
  accentLabel.height = noteInput.height
  accentLabel.width = 120
  accentLabel.x = noteInputLabel.width + 18
  accentLabel.y = noteLabel.y

  local accent = notePanel:NumBox("NoteAccent" .. i, 1, 1, 16, true)
  accent.visible = false
  accent.showLabel = false
  accent.tooltip = "Accent table lenght"
  accent.backgroundColour = menuBackgroundColour
  accent.textColour = menuTextColour
  accent.height = noteInput.height
  accent.width = 20
  accent.x = accentLabel.x
  accent.y = accentLabel.y + accentLabel.height + rowSpacing

  local accentTable = notePanel:Table("AccentTable" .. i, 1, velocityInput.default, 1, 127, true)
  accentTable.visible = false
  accentTable.showPopupDisplay = true
  accentTable.tooltip = "Set velocity for this voice"
  accentTable.fillStyle = "solid"
  accentTable.backgroundColour = "#9f02ACFE"
  accentTable.sliderColour = outlineColour
  accentTable.width = accentLabel.width - accent.width
  accentTable.height = accent.height
  accentTable.x = accent.x + accent.width
  accentTable.y = accent.y

  accent.changed = function(self)
    --print("accent.changed", self.value)
    accentTable.length = self.value
  end

  local pitch = notePanel:NumBox("NotePitch" .. i, 1, 1, 16, true)
  pitch.visible = false
  pitch.showLabel = false
  pitch.tooltip = "Pitch offset table lenght"
  pitch.backgroundColour = menuBackgroundColour
  pitch.textColour = menuTextColour
  pitch.height = noteInput.height
  pitch.width = 20
  pitch.x = accent.x
  pitch.y = accent.y + accent.height + rowSpacing

  local pitchTable = notePanel:Table("PitchOffsetTable" .. i, 1, 0, -12, 12, true)
  pitchTable.visible = false
  pitchTable.showPopupDisplay = true
  pitchTable.tooltip = "Set pitch offset for this voice"
  pitchTable.fillStyle = "solid"
  pitchTable.backgroundColour = "#9f02ACFE"
  pitchTable.sliderColour = outlineColour
  pitchTable.width = accentLabel.width - 50
  pitchTable.height = pitch.height
  pitchTable.x = pitch.x + pitch.width
  pitchTable.y = pitch.y

  local pitchChangeProbability = notePanel:NumBox("PitchChangeProbability" .. i, 0, 0, 100, true)
  pitchChangeProbability.unit = Unit.Percent
  pitchChangeProbability.visible = false
  pitchChangeProbability.showLabel = false
  pitchChangeProbability.displayName = "Pitch change probability"
  pitchChangeProbability.tooltip = "Probability that the pitch offset from another step will be used"
  pitchChangeProbability.backgroundColour = menuBackgroundColour
  pitchChangeProbability.textColour = menuTextColour
  pitchChangeProbability.height = pitch.height
  pitchChangeProbability.width = 30
  pitchChangeProbability.x = pitchTable.x + pitchTable.width
  pitchChangeProbability.y = pitchTable.y

  pitch.changed = function(self)
    --print("pitch.changed", self.value)
    pitchTable.length = self.value
  end

  local accentFragmentStart = notePanel:OnOffButton("AccentFragmentStart" .. i, false)
  accentFragmentStart.visible = false
  accentFragmentStart.displayName = "Start"
  accentFragmentStart.tooltip = "Accent note at the start of a fragment"
  accentFragmentStart.backgroundColourOff = backgroundColourOff
  accentFragmentStart.backgroundColourOn = backgroundColourOn
  accentFragmentStart.textColourOff = textColourOff
  accentFragmentStart.textColourOn = textColourOn
  accentFragmentStart.height = accent.height
  accentFragmentStart.width = accentLabel.width / 3
  accentFragmentStart.x = pitch.x
  accentFragmentStart.y = pitch.y + pitch.height + rowSpacing

  local accentDownBeat = notePanel:OnOffButton("AccentDownBeat" .. i, false)
  accentDownBeat.visible = false
  accentDownBeat.displayName = "Down"
  accentDownBeat.tooltip = "Accent note if triggered on the downbeat"
  accentDownBeat.backgroundColourOff = backgroundColourOff
  accentDownBeat.backgroundColourOn = backgroundColourOn
  accentDownBeat.textColourOff = textColourOff
  accentDownBeat.textColourOn = textColourOn
  accentDownBeat.height = accent.height
  accentDownBeat.width = accentFragmentStart.width
  accentDownBeat.x = accentFragmentStart.x + accentFragmentStart.width
  accentDownBeat.y = accentFragmentStart.y

  local accentUpBeat = notePanel:OnOffButton("AccentUpBeat" .. i, false)
  accentUpBeat.visible = false
  accentUpBeat.displayName = "Up"
  accentUpBeat.tooltip = "Accent note if triggered on the upbeat"
  accentUpBeat.backgroundColourOff = backgroundColourOff
  accentUpBeat.backgroundColourOn = backgroundColourOn
  accentUpBeat.textColourOff = textColourOff
  accentUpBeat.textColourOn = textColourOn
  accentUpBeat.height = accent.height
  accentUpBeat.width = accentDownBeat.width
  accentUpBeat.x = accentDownBeat.x + accentDownBeat.width
  accentUpBeat.y = accentDownBeat.y

  local restLabel = notePanel:Label("RestLabel" .. i)
  restLabel.visible = false
  restLabel.text = "Rests"
  restLabel.tooltip = "Set rests"
  restLabel.height = noteInput.height
  restLabel.width = accentLabel.width
  restLabel.x = accentLabel.x + accentLabel.width + 8
  restLabel.y = noteLabel.y

  local restDownBeatProbability = notePanel:NumBox("RestDownBeatProbability" .. i, 0, 0, 100, true)
  restDownBeatProbability.unit = Unit.Percent
  restDownBeatProbability.visible = false
  restDownBeatProbability.displayName = "Downbeat"
  restDownBeatProbability.tooltip = "Probability that a rest will be played if triggered at the start of a downbeat"
  restDownBeatProbability.backgroundColour = menuBackgroundColour
  restDownBeatProbability.textColour = menuTextColour
  restDownBeatProbability.height = restLabel.height
  restDownBeatProbability.width = restLabel.width
  restDownBeatProbability.x = restLabel.x
  restDownBeatProbability.y = restLabel.y + restLabel.height + rowSpacing

  local restUpBeatProbability = notePanel:NumBox("RestUpBeatProbability" .. i, 0, 0, 100, true)
  restUpBeatProbability.unit = Unit.Percent
  restUpBeatProbability.visible = false
  restUpBeatProbability.displayName = "Upbeat"
  restUpBeatProbability.tooltip = "Probability that a rest will be played if triggered at the start of an upbeat"
  restUpBeatProbability.backgroundColour = menuBackgroundColour
  restUpBeatProbability.textColour = menuTextColour
  restUpBeatProbability.height = restDownBeatProbability.height
  restUpBeatProbability.width = restDownBeatProbability.width
  restUpBeatProbability.x = restDownBeatProbability.x
  restUpBeatProbability.y = restDownBeatProbability.y + restDownBeatProbability.height + rowSpacing

  local restFirstInFragmentProbability = notePanel:NumBox("RestFirstInFragmentProbability" .. i, 0, 0, 100, true)
  restFirstInFragmentProbability.unit = Unit.Percent
  restFirstInFragmentProbability.visible = false
  restFirstInFragmentProbability.displayName = "Fragment"
  restFirstInFragmentProbability.tooltip = "Probability that a rest will be played at the start of a fragment"
  restFirstInFragmentProbability.backgroundColour = menuBackgroundColour
  restFirstInFragmentProbability.textColour = menuTextColour
  restFirstInFragmentProbability.height = restUpBeatProbability.height
  restFirstInFragmentProbability.width = restUpBeatProbability.width
  restFirstInFragmentProbability.x = restUpBeatProbability.x
  restFirstInFragmentProbability.y = restUpBeatProbability.y + restUpBeatProbability.height + rowSpacing

  local sourceLabel = notePanel:Label("SourceInput" .. i)
  sourceLabel.visible = false
  sourceLabel.text = "Sources"
  sourceLabel.tooltip = "Select the fragments that are available for this part - NOTE: If all are 0, then all fragments can be selected."
  sourceLabel.height = accent.height
  sourceLabel.width = 60
  sourceLabel.x = restLabel.x + restLabel.width + 8
  sourceLabel.y = noteLabel.y

  local sourceSelectors = {}
  local perColumn = 3
  local rowCounter = 1
  local columnCounter = 0
  for j=1,numNotes do
    local defaultValue = 0
    if j == i then
      defaultValue = 100
    end
    local sourceSelector = notePanel:NumBox("SourceSelector" .. i .. "_" .. j, defaultValue, 0, 100, true)
    sourceSelector.unit = Unit.Percent
    sourceSelector.visible = false
    sourceSelector.displayName = "Rythm " .. j
    sourceSelector.tooltip = "Probability of rythmic fragment " .. j .. " being used for this part"
    sourceSelector.backgroundColour = menuBackgroundColour
    sourceSelector.textColour = menuTextColour
    sourceSelector.size = {112,22}
    sourceSelector.x = sourceLabel.x + (columnCounter * (sourceSelector.width + 5))
    sourceSelector.y = sourceLabel.y + ((sourceLabel.height + rowSpacing) * rowCounter)
    table.insert(sourceSelectors, sourceSelector)
    columnCounter = columnCounter + 1
    if columnCounter >= perColumn then
      columnCounter = 0
      rowCounter = rowCounter + 1
    end
  end

  local sourceSelectorAll = notePanel:NumBox("SourceSelectorAll" .. i, 100, 0, 100, true)
  sourceSelectorAll.unit = Unit.Percent
  sourceSelectorAll.visible = false
  sourceSelectorAll.displayName = "All sources"
  sourceSelectorAll.tooltip = "Set value for all sources"
  sourceSelectorAll.backgroundColour = menuBackgroundColour
  sourceSelectorAll.textColour = menuTextColour
  sourceSelectorAll.size = {112,22}
  sourceSelectorAll.x = sourceLabel.x + (columnCounter * (sourceSelectorAll.width + 5))
  sourceSelectorAll.y = sourceLabel.y + ((sourceLabel.height + rowSpacing) * rowCounter)
  sourceSelectorAll.changed = function(self)
    for _,v in ipairs(sourceSelectors) do
      v:setValue(self.value)
    end
  end

  table.insert(paramsPerNote, {noteInputLabel=noteInputLabel, noteInput=noteInput, noteProbability=noteProbability, accent=accent, accentTable=accentTable, pitch=pitch, pitchTable=pitchTable, pitchChangeProbability=pitchChangeProbability, restFirstInFragmentProbability=restFirstInFragmentProbability, restDownBeatProbability=restDownBeatProbability, restDownBeatProbability=restDownBeatProbability, restUpBeatProbability=restUpBeatProbability, accentLabel=accentLabel, restLabel=restLabel, sourceLabel=sourceLabel, sourceSelectors=sourceSelectors, sourceSelectorAll=sourceSelectorAll, listen=listen, edit=edit, mute=mute, accentFragmentStart=accentFragmentStart, accentDownBeat=accentDownBeat, accentUpBeat=accentUpBeat})
end

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythmic fragments"
rythmLabel.alpha = 0.75
rythmLabel.fontSize = 15
rythmLabel.width = 120

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, rythmLabel, colours, numNotes)

local selectNone = rythmPanel:Button("SelectNone")
selectNone.displayName = "Select none"
selectNone.tooltip = "Deselect all fragments"
selectNone.persistent = false
selectNone.height = noteLabel.height
selectNone.width = 120
selectNone.x = rythmPanel.width - (selectNone.width * 4) - 36
selectNone.y = 5
selectNone.changed = function()
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive:setValue(false)
  end
end

local selectAll = rythmPanel:Button("SelectAll")
selectAll.displayName = "Select all"
selectAll.tooltip = "Select all fragments"
selectAll.persistent = false
selectAll.height = noteLabel.height
selectAll.width = selectNone.width
selectAll.x = selectNone.x + selectNone.width + 10
selectAll.y = 5
selectAll.changed = function()
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive:setValue(true)
  end
end

local invertSelection = rythmPanel:Button("InvertSelection")
invertSelection.displayName = "Invert selection"
invertSelection.tooltip = "Invert current selection"
invertSelection.persistent = false
invertSelection.height = noteLabel.height
invertSelection.width = selectAll.width
invertSelection.x = selectAll.x + selectAll.width + 10
invertSelection.y = 5
invertSelection.changed = function()
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive:setValue(v.fragmentActive.value == false and string.len(v.fragmentInput.text) > 0)
  end
end

local randomizeSelection = rythmPanel:Button("RandomizeSelection")
randomizeSelection.displayName = "Randomize selection"
randomizeSelection.tooltip = "Randomize fragment selection"
randomizeSelection.persistent = false
randomizeSelection.height = noteLabel.height
randomizeSelection.width = selectNone.width
randomizeSelection.x = invertSelection.x + invertSelection.width + 10
randomizeSelection.y = 5
randomizeSelection.changed = function()
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive:setValue(string.len(v.fragmentInput.text) > 0 and gem.getRandomBoolean())
  end
end

--- Structure - Store/recall parts, set playing order etc. ---

local loadFragmentMenu = rythmPanel:Menu("LoadFragmentMenu", {"Load..."})
loadFragmentMenu.enabled = false

local storeButton = rythmPanel:Button("StoreButton")
storeButton.displayName = "Store"
storeButton.tooltip = "Store the current state of the fragments"
storeButton.width = 75
storeButton.height = 20
storeButton.x = rythmLabel.x
storeButton.y = 417

local slotSpacing = 3
local unusedSlotDefaultText = "Unused"
local actions = {"Save..."}
local slotToStoredIndex = {} -- Holds the index of the stored fragment for each slot
local fragmentSlots = {}
for i=1,8 do
  local fragmentSlot = rythmPanel:OnOffButton("StoreFragmentSlot" .. i)
  fragmentSlot.backgroundColourOff = backgroundColourOff
  fragmentSlot.backgroundColourOn = backgroundColourOn
  fragmentSlot.textColourOff = textColourOff
  fragmentSlot.textColourOn = textColourOn
  fragmentSlot.displayName = "" .. i
  fragmentSlot.enabled = false
  fragmentSlot.tooltip = unusedSlotDefaultText
  fragmentSlot.width = 20
  fragmentSlot.height = storeButton.height
  fragmentSlot.x = storeButton.x + storeButton.width + ((i-1) * (fragmentSlot.width + slotSpacing)) + 10
  fragmentSlot.y = storeButton.y
  fragmentSlot.changed = function(self)
    if self.value then
      local storedIndex = slotToStoredIndex[i]
      if type(storedFragments[storedIndex]) == "table" then
        recallStoredState = storedIndex
        --print("Set part/recallStoredState", i, recallStoredState)
        -- If sequencer is not playing, we can recall right now
        if isPlaying == false then
          recall()
        end
      end
    end
    for j,v in ipairs(fragmentSlots) do
      if j ~= i then
        v:setValue(false, false)
      end
    end
  end
  table.insert(fragmentSlots, fragmentSlot)
  table.insert(slotToStoredIndex, nil)
  table.insert(actions, "Save to " .. i)
end

local slotActions = rythmPanel:Menu("SlotActions", actions)
slotActions.tooltip = "Save current fragment state to the selected slot"
slotActions.showLabel = false
slotActions.height = storeButton.height
slotActions.width = 90
slotActions.x = storeButton.x + storeButton.width + ((fragmentSlots[1].width + slotSpacing) * #fragmentSlots) + 15
slotActions.y = storeButton.y
slotActions.backgroundColour = menuBackgroundColour
slotActions.textColour = widgetTextColour
slotActions.arrowColour = menuArrowColour
slotActions.outlineColour = menuOutlineColour
slotActions.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local index = self.value - 1

  -- Save current fragment state
  -- TODO Add options to remove?
  if index <= #fragmentSlots then
    storeButton:changed() -- Store the current state
    slotToStoredIndex[index] = #storedFragments -- Set the most recent stored fragment to this slot
    fragmentSlots[index].tooltip = "Part " .. index .. " - Stored state " .. slotToStoredIndex[index]
    fragmentSlots[index].enabled = true
  end

  -- Must be last
  self:setValue(1, false)
end

loadFragmentMenu.tooltip = "Load a stored fragment state"
loadFragmentMenu.showLabel = false
loadFragmentMenu.height = storeButton.height
loadFragmentMenu.width = slotActions.width
loadFragmentMenu.x = slotActions.x + slotActions.width + 10
loadFragmentMenu.y = slotActions.y
loadFragmentMenu.backgroundColour = menuBackgroundColour
loadFragmentMenu.textColour = widgetTextColour
loadFragmentMenu.arrowColour = menuArrowColour
loadFragmentMenu.outlineColour = menuOutlineColour
loadFragmentMenu.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local index = self.value - 1

  if type(storedFragments[index]) == "table" then
    recallStoredState = index
    -- If sequencer is not playing, we can recall right now
    if isPlaying == false then
      recall()
    end  
  end

  -- Must be last
  self:setValue(1, false)
end

local partOrderButton = rythmPanel:OnOffButton("PartOrderLabel")
partOrderButton.displayName = "Part Order"
partOrderButton.tooltip = "Activate part order"
partOrderButton.width = 60
partOrderButton.height = 20
partOrderButton.backgroundColourOff = backgroundColourOff
partOrderButton.backgroundColourOn = backgroundColourOn
partOrderButton.textColourOff = textColourOff
partOrderButton.textColourOn = textColourOn
partOrderButton.x = loadFragmentMenu.x + loadFragmentMenu.width + 10
partOrderButton.y = loadFragmentMenu.y

local partOrderInput = rythmPanel:Label("PartOrderInput")
partOrderInput.text = ""
partOrderInput.tooltip = "Set the playing order of the parts (1-8 as stored in the slots). Format <PART><x|e><REPEATS> separated by comma (use e instead of x to activate evolve). Example: 1x16,2e8,3"
partOrderInput.editable = true
partOrderInput.backgroundColour = "black"
partOrderInput.backgroundColourWhenEditing = "white"
partOrderInput.textColour = "white"
partOrderInput.textColourWhenEditing = "black"
partOrderInput.x = partOrderButton.x + partOrderButton.width
partOrderInput.y = partOrderButton.y
partOrderInput.width = 156
partOrderInput.height = 20
partOrderInput.fontSize = 15
partOrderInput.changed = function(self)
  setPartOrder(self.text)
end

--- Evolve ---

local recallButton = rythmPanel:Button("RecallButton")
recallButton.displayName = "Recall"
recallButton.enabled = false
recallButton.tooltip = "Recall the last stored fragment state"
recallButton.width = storeButton.width
recallButton.height = storeButton.height
recallButton.x = storeButton.x
recallButton.y = storeButton.y + storeButton.height + 10

local evolveButton = rythmPanel:OnOffButton("EvolveActive", false)
evolveButton.backgroundColourOff = backgroundColourOff
evolveButton.backgroundColourOn = backgroundColourOn
evolveButton.textColourOff = textColourOff
evolveButton.textColourOn = textColourOn
evolveButton.displayName = "Evolve"
evolveButton.tooltip = "Activate evolve"
evolveButton.width = recallButton.width
evolveButton.height = recallButton.height
evolveButton.x = recallButton.x + recallButton.width + 10
evolveButton.y = recallButton.y

local evolveFragmentProbability = rythmPanel:NumBox("EvolveFragmentProbability", 50, 0, 100, true)
evolveFragmentProbability.unit = Unit.Percent
evolveFragmentProbability.textColour = widgetTextColour
evolveFragmentProbability.backgroundColour = widgetBackgroundColour
evolveFragmentProbability.displayName = "Amount"
evolveFragmentProbability.tooltip = "Set the probability that fragments will change over time, using the resolutions present in the fragments"
evolveFragmentProbability.width = 105
evolveFragmentProbability.height = recallButton.height
evolveFragmentProbability.x = evolveButton.x + evolveButton.width + 10
evolveFragmentProbability.y = evolveButton.y

local randomizeCurrentResolutionProbability = rythmPanel:NumBox("RandomizeCurrentResolutionProbability", 0, 0, 100, true)
randomizeCurrentResolutionProbability.unit = Unit.Percent
randomizeCurrentResolutionProbability.textColour = widgetTextColour
randomizeCurrentResolutionProbability.backgroundColour = widgetBackgroundColour
randomizeCurrentResolutionProbability.displayName = "Adjust"
randomizeCurrentResolutionProbability.tooltip = "Set the probability that evolve will adjust resolutions (double, half, dot/tri), based on the resolutions present in the fragments"
randomizeCurrentResolutionProbability.width = evolveFragmentProbability.width
randomizeCurrentResolutionProbability.height = evolveFragmentProbability.height
randomizeCurrentResolutionProbability.x = evolveFragmentProbability.x + evolveFragmentProbability.width + 10
randomizeCurrentResolutionProbability.y = evolveFragmentProbability.y

local biasLabel = rythmPanel:Label("BiasLabel")
biasLabel.text = "Bias slow > fast"
biasLabel.tooltip = "Adjust bias: <50=more slow resolutions, >50=more fast resolutions"
biasLabel.alpha = 0.5
biasLabel.fontSize = 15
biasLabel.width = 95
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
adjustBias.width = 20
adjustBias.height = biasLabel.height
adjustBias.x = biasLabel.x + biasLabel.width
adjustBias.y = biasLabel.y

local minResLabel = rythmPanel:Label("MinResolutionsLabel")
minResLabel.text = "Min resolution"
minResLabel.alpha = 0.5
minResLabel.fontSize = 15
minResLabel.width = biasLabel.width
minResLabel.height = adjustBias.height
minResLabel.x = adjustBias.x + adjustBias.width + 10
minResLabel.y = adjustBias.y

local minResolution = rythmPanel:Menu("MinResolution", resolutions.getResolutionNames())
minResolution.displayName = minResLabel.text
minResolution.tooltip = "The highest allowed resolution for evolve adjustments"
minResolution.selected = 26
minResolution.showLabel = false
minResolution.width = 69
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

storeButton.changed = function(self)
  table.insert(storedFragments, rythmicFragments.getFragmentState())
  recallButton.enabled = true
  loadFragmentMenu.enabled = true
  loadFragmentMenu:addItem("State " .. #storedFragments)
end

recallButton.changed = function(self)
  recallStoredState = #storedFragments
  -- If sequencer is not playing, we can recall right now
  if isPlaying == false then
    recall()
  end
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

-- Returns a fragment that can be set directly on fragmentInput.text
-- Used by the tools menu
-- 1 = Default (even+dot)
-- 2 = Single
-- 3 = Extended (fast+slow)
-- 4 = Slow
function getRandomFragment(definitionNumber)
  local fragmentDefinition = {}
  if definitionNumber == 2 then
    fragmentDefinition = {resolutions.getResolution(gem.getRandomFromTable(rythmicFragments.getSelectedResolutions()))} -- Single
  else
    fragmentDefinition = rythmicFragments.createFragmentDefinition(definitionNumber)
  end
  return rythmicFragments.getFragmentInputText(rythmicFragments.fragmentDefinitionToResolutionNames(fragmentDefinition))
end

function getNote(voice)
  local noteProbability = paramsPerNote[voice].noteProbability.value
  if gem.getRandomBoolean(noteProbability) then
    local pitchTable = paramsPerNote[voice].pitchTable
    local pitchChangeProbability = paramsPerNote[voice].pitchChangeProbability.value
    local pos = (roundCounterPerVoice[voice] % pitchTable.length) + 1

    -- Check for pitch change randomization
    if gem.getRandomBoolean(pitchChangeProbability) then
      -- Get pitch adjustment from random index in pitch table for current part
      pos = gem.getRandom(paramsPerNote[voice].pitch.value)
      --print("Playing pitch from random pos", pos)
    end

    local offset = pitchTable:getValue(pos)
    --print("Pitch offset/pos", offset, pos)
    return paramsPerNote[voice].noteInput.value + offset
  end
end

function startPlaying()
  if isPlaying then
    return
  end
  seqIndex = gem.inc(seqIndex)
  run(sequenceRunner, seqIndex)
end

function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  initNotes()
end

function getSources(voice)
  local sources = {}
  for i,v in ipairs(paramsPerNote[voice].sourceSelectors) do
    if gem.getRandomBoolean(v.value) then
      table.insert(sources, i)
    end
  end
  return sources
end

function hasActiveSources(voice)
  local sources = {}
  for i,v in ipairs(paramsPerNote[voice].sourceSelectors) do
    if v.value > 0 and string.len(paramsPerFragment[i].fragmentInput.text) > 0 then
      table.insert(sources, i)
    end
  end
  return #sources > 0
end

function getChannel(voice)
  local channel = nil
  if channelButton.value then
    channel = voice -- TODO Add offset: + channelOffset.value - 1
  end
  return channel
end

function isStartOfBeat(playDuration)
  return math.floor(playDuration) == playDuration
end

function isDownBeat(playDuration)
  return isStartOfBeat(playDuration) and (playDuration % beatBase == 0 or (beatBase > 3 and playDuration % math.ceil(beatBase / 2) == 0))
end

function isUpBeat(playDuration)
  return isStartOfBeat(playDuration) and isDownBeat(playDuration) == false
end

function isNoteActive(voice)
  return paramsPerNote[voice].noteProbability.value > 0 and paramsPerNote[voice].mute.value == false and hasActiveSources(voice)
end

function initNotes()
  playingVoices = {}
  playingIndex = {}
  roundCounterPerVoice = {}
  rythmicFragments.clearResolutionsForEvolve()
  for voice=1,numNotes do
    table.insert(playingVoices, false) -- Init voices
    table.insert(playingIndex, nil) -- Init index
    table.insert(roundCounterPerVoice, 0) -- Init rounds
    setSourceActive(voice)
  end
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive.textColourOn = "black"
  end
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentInputDirty = false
  end
end

function useAccent(voice, activeFragment, isFragmentStart, mustRepeat, isDownBeat, isUpBeat)
  if paramsPerNote[voice].accentDownBeat.value and isDownBeat then
    --print("ACCENT isDownBeat", isDownBeat)
    return true
  end
  
  if paramsPerNote[voice].accentUpBeat.value and isUpBeat then
    --print("ACCENT isUpBeat", isUpBeat)
    return true
  end

  if paramsPerNote[voice].accentFragmentStart.value and isFragmentStart then
    if #activeFragment.f > 1 then
      --print("ACCENT #activeFragment.f", #activeFragment.f)
      return true
    end
    if activeFragment.m > 1 and mustRepeat == false then
      --print("ACCENT activeFragment.m, mustRepeat", activeFragment.m, mustRepeat)
      return true
    end
  end

  return false
end

function flashNoteLabel(voice, duration)
  local flashDuration = 150--math.min(150, beat2ms(duration))
  if type(duration) == "number" then
    flashDuration = math.min(flashDuration, beat2ms(duration))
  end
  paramsPerNote[voice].noteInputLabel.textColour = "efefef"
  wait(flashDuration)
  paramsPerNote[voice].noteInputLabel.textColour = "9f9f9f"
end

-- Set textcolour on the active source for the given voice
function setSourceActive(voice, activeFragment)
  for i,v in ipairs(paramsPerNote[voice].sourceSelectors) do
    if type(activeFragment) == "table" and activeFragment.i == i then
      v.textColour = labelBackgoundColour
    else
      v.textColour = menuTextColour
    end
  end
end

function playVoices(partDuration)
  for voice=1,voices do
    if playingVoices[voice] == false then
      playingVoices[voice] = isNoteActive(voice)
      if playingVoices[voice] then
        print("Play voice", voice)
        playingIndex[voice] = playIndex
        spawn(play, voice, playIndex, partDuration)
        playIndex = gem.inc(playIndex)
      end
    end
  end
end

function recall()
  -- Find the state we are to recall
  rythmicFragments.setFragmentState(storedFragments[recallStoredState])
  --print("Recalled fragments from stored state", recallStoredState)
  recallStoredState = nil
end

-- Parse the part order input
-- Format: <PART><x|e><REPEATS> separated by comma (use e instead of x to activate evolve). Example: 1x16,2e8,3
-- Set the part to zero "0" to use the current state instead of loading a part
function setPartOrder(partOrderText)
  partOrder = {} -- Reset
  for s in string.gmatch(partOrderText, "[^,]+") do
    local evolve = type(string.find(s, "e", 1, true)) == "number" -- Check if "e" is given for evolve
    local part = tonumber(string.sub(s, 1, 1)) -- Parts are 1-8, so we get the first pos in the string
    local repeats = tonumber(string.sub(s, 3)) -- Get repeats from the third pos to the end - if any is set
    if type(repeats) ~= "number" then
      repeats = 1
    end
    if type(part) == "number" then
      --print("setPartOrder part, repeats, evolve", part, repeats, evolve)
      table.insert(partOrder, {part=part,repeats=repeats,evolve=evolve})
    end
  end
  --print("#partOrder", #partOrder)
  return partOrder
end

function sequenceRunner(uniqueId)
  local previous = nil -- Previous resolution when using evolve
  local partOrderPos = 1 -- Position in the part order
  local partOrderRepeatCounter = 0 -- Counter for part repeats
  local slotIndex = nil -- The currently selected slot
  local remainingDuration = 0
  local partDuration = nil -- When using part order, this is the duration of the parts with repeats
  local partInfo = nil
  local startEvolve = false -- Can be set by part order
  local beatCounter = 1 -- Holds the beat count
  playIndex = 1 -- Reset play index
  isPlaying = true
  initNotes()
  while isPlaying and seqIndex == uniqueId do
    if beatCounter == 1 then
      if partOrderButton.value and #partOrder > 0 then
        if partOrderRepeatCounter == 0 then
          -- Start new part
          partInfo = partOrder[partOrderPos]
          slotIndex = partInfo.part
          partOrderRepeatCounter = partInfo.repeats
          startEvolve = partInfo.evolve
          --print("startEvolve, slotIndex, partOrderPos", startEvolve, slotIndex, partOrderPos)
          partDuration = partOrderRepeatCounter * beatBase * beatResolution
          remainingDuration = partDuration
          -- If slot is already selected, deactivate so we can select it again
          if slotIndex > 0 then
            if fragmentSlots[slotIndex].value == true then
              fragmentSlots[slotIndex]:setValue(false)
            end
            fragmentSlots[slotIndex]:setValue(true)
          end
          -- Increment part order position
          partOrderPos = partOrderPos + 1
          if partOrderPos > #partOrder then
            partOrderPos = 1
          end
        end

        partOrderRepeatCounter = partOrderRepeatCounter - 1 -- Decrement repeat counter
        --print("Decrementing partOrderRepeatCounter", partOrderRepeatCounter)
      end

      if type(recallStoredState) == "number" then
        initNotes()
        recall()
        evolveButton:setValue(startEvolve)
      end

      --print("beatCounter, remainingDuration, partDuration", beatCounter, remainingDuration, partDuration)
      if type(partDuration) == "nil" or remainingDuration == partDuration or remainingDuration == 0 then
        playVoices(partDuration)
      end
    end

    waitBeat(beatResolution)

    if remainingDuration > 0 then
      remainingDuration = remainingDuration - beatResolution
      --print("SequenceRunner remainingDuration", remainingDuration)
    end

    beatCounter = beatCounter + 1 -- Increment counter
    print("Increment beat counter", beatCounter)
    if beatCounter > beatBase then
      beatCounter = 1 -- Reset counter
      if evolveButton.value and gem.getRandomBoolean(evolveFragmentProbability.value) then
        previous = rythmicFragments.evolveFragments(previous, randomizeCurrentResolutionProbability.value, adjustBias.value)
      end
    end
  end
end

function play(voice, uniqueId, partDuration)
  --print("voice, uniqueId, partDuration", voice, uniqueId, partDuration)
  local playDuration = 0 -- Keep track of the played duration
  local duration = nil
  local isFragmentStart = false
  local isRepeat = false
  local mustRepeat = false
  local rest = false
  local activeFragment = nil
  local fragmentPos = 0
  local fragmentRepeatProbability = 0
  local reverseFragment = false
  local fragmentRepeatCount = 0
  -- Start loop
  while playingIndex[voice] == uniqueId do
    roundCounterPerVoice[voice] = roundCounterPerVoice[voice] + 1

    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = rythmicFragments.getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount, getSources(voice))

    if type(duration) == "nil" or activeFragment.i == 0 or isNoteActive(voice) == false then
      -- Return voice to sequence runner
      setSourceActive(voice)
      playingVoices[voice] = false
      break
    end

    local isDownBeat = isDownBeat(playDuration)
    local isUpBeat = isUpBeat(playDuration)

    -- Check rest at start of downbeat
    if isDownBeat and rest == false and gem.getRandomBoolean(paramsPerNote[voice].restDownBeatProbability.value) then
      rest = true
    end

    -- Check rest at start of upbeat
    if isUpBeat and rest == false and gem.getRandomBoolean(paramsPerNote[voice].restUpBeatProbability.value) then
      rest = true
    end

    -- Check rest at start of fragment - only if fragment has more than one item
    if isFragmentStart and rest == false and (#activeFragment.f > 1 or (activeFragment.m > 1 and mustRepeat == false)) and gem.getRandomBoolean(paramsPerNote[voice].restFirstInFragmentProbability.value) then
      rest = true
    end

    if type(partDuration) == "number" and (playDuration + duration) > partDuration then
      duration = partDuration - playDuration -- Remaining
    end

    -- Update total play duration
    playDuration = playDuration + duration

    local note = getNote(voice)
    local doPlayNote = rest == false and type(note) == "number"
    if doPlayNote then
      local velocity = velocityInput.value
      local accentTable = paramsPerNote[voice].accentTable
      if accentTable.enabled then
        local pos = (roundCounterPerVoice[voice] % accentTable.length) + 1
        velocity = accentTable:getValue(pos)
        --print("Velocity set from accentTable at pos", velocity, pos)
      end
      if useAccent(voice, activeFragment, isFragmentStart, mustRepeat, isDownBeat, isUpBeat) then
        velocity = velocityAccent.value
      end
      playNote(note, velocity, beat2ms(resolutions.getPlayDuration(duration)), nil, getChannel())

      if isFragmentStart then
        setSourceActive(voice, activeFragment)
      end

      for i,v in ipairs(paramsPerFragment) do
        if activeFragment.i == i then
          spawn(rythmicFragments.flashFragmentActive, v.fragmentActive, duration)
        end
      end
      spawn(flashNoteLabel, voice, duration)
    end

    if type(partDuration) == "number" and playDuration == partDuration then
      print("playDuration == partDuration", playDuration, "voice " .. voice)
      playingVoices[voice] = false -- Break loop
      break
    end

    if activeFragment.i > 0 and paramsPerFragment[activeFragment.i].fragmentInputDirty then
      paramsPerFragment[activeFragment.i].fragmentInputDirty = false
      playingVoices[voice] = false -- Restart voice next bar to reload fragment input
      print("fragmentInputDirty", "voice " .. voice)
    end

    if duration > 0 then
      waitBeat(duration)
    end
  end
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  if type(noteListen) == "number" then
    paramsPerNote[noteListen].noteInput:setValue(e.note)
    paramsPerNote[noteListen].listen:setValue(false)
  end
  for i,v in ipairs(paramsPerNote) do
    if v.noteInput.value == e.note then
      spawn(flashNoteLabel, i)
    end
  end
  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(true)
  end
end

function onRelease(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(false)
  end
end

function onTransport(start)
  if autoplayButton.value == true then
    playButton:setValue(start)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local fragmentInputData = {}
  local noteLabelData = {}
  local fragmentSlotsData = {}
  local accentTableData = {}
  local pitchTableData = {}

  for _,v in ipairs(paramsPerNote) do
    table.insert(noteLabelData, v.noteInputLabel.text)
    local accentData = {}
    for j=1, v.accent.value do
      table.insert(accentData, v.accentTable:getValue(j))
    end
    table.insert(accentTableData, accentData)
    local pitchData = {}
    for j=1, v.pitch.value do
      table.insert(pitchData, v.pitchTable:getValue(j))
    end
    table.insert(pitchTableData, pitchData)
  end

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  for _,v in ipairs(fragmentSlots) do
    table.insert(fragmentSlotsData, v.tooltip)
  end

  return {fragmentInputData, noteLabelData, fragmentSlotsData, storedFragments, partOrderInput.text, slotToStoredIndex, accentTableData, pitchTableData}
end

function onLoad(data)
  local fragmentInputData = data[1]
  local noteLabelData = data[2]
  local fragmentSlotsData = data[3]
  storedFragments = data[4]
  partOrderInput.text = tostring(data[5])
  slotToStoredIndex = data[6]
  local accentTableData = data[7]
  local pitchTableData = data[8]

  setPartOrder(partOrderInput.text)

  if type(storedFragments) == "nil" then
    storedFragments = {}
  end

  if type(fragmentSlotsData) == "nil" then
    fragmentSlotsData = {}
  end

  if type(slotToStoredIndex) == "nil" then
    slotToStoredIndex = {}
    for i=1,#fragmentSlots do
      table.insert(slotToStoredIndex, nil)
    end
  end

  recallButton.enabled = #storedFragments > 0

  for i=1,#storedFragments do
    loadFragmentMenu:addItem("State " .. i)
  end
  loadFragmentMenu.enabled = #storedFragments > 0

  for i,v in ipairs(paramsPerNote) do
    v.noteInputLabel.text = noteLabelData[i]
    if type(accentTableData) == "table" then
      v.accent:setValue(#accentTableData[i])
      --print("Loading v.accent.value/v.accentTable.length", v.accent.value, v.accentTable.length)
      for j,a in ipairs(accentTableData[i]) do
        v.accentTable:setValue(j,a)
      end
    end
    if type(pitchTableData) == "table" then
      v.pitch:setValue(#pitchTableData[i])
      --print("Loading v.pitch.value/v.pitchTable.length", v.pitch.value, v.pitchTable.length)
      for j,a in ipairs(pitchTableData[i]) do
        v.pitchTable:setValue(j,a)
      end
    end
  end

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end

  for i,v in ipairs(fragmentSlotsData) do
    fragmentSlots[i].tooltip = v
    fragmentSlots[i].enabled = type(slotToStoredIndex[i]) == "number"
  end
end
