--------------------------------------------------------------------------------
-- Common Resolutions
--------------------------------------------------------------------------------

local gem = require "includes.common"

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

local function getResolutionsByType(maxResolutionIndex)
  if type(maxResolutionIndex) == "nil" then
    maxResolutionIndex = #resolutionValues
  end
  local startPosIndex = 11
  local resOptions = {}
  -- Create table of resolution indexes by type (1=even,2=dot,3=tri)
  for i=startPosIndex,startPosIndex+2 do
    local resolutionIndex = i
    local resolutionsOfType = {}
    while resolutionIndex <= maxResolutionIndex do
      table.insert(resolutionsOfType, resolutionIndex) -- insert current index in resolution options table
      --print("Insert resolutionIndex", resolutionIndex)
      resolutionIndex = resolutionIndex + 3 -- increment index
    end
    --print("#resolutionsOfType, i", #resolutionsOfType, i)
    table.insert(resOptions, resolutionsOfType)
  end
  -- Add the resolutions that are whole numbers (1,2,3,4...)
  local slowResolutions = {}
  for i,resolution in ipairs(resolutionValues) do
    if resolution % 1 == 0 then
      table.insert(slowResolutions, i)
      --print("getResolutionsByType - included slow resolution", resolution)
    end
  end
  --print("#slowResolutions", #slowResolutions)
  table.insert(resOptions, slowResolutions) -- Add the "slow" x resolutions
  --print("resOptions", #resOptions)
  return resOptions
end

-- Returns a table of resolutions indexes that are "approved" to use
local function getSelectedResolutions(resolutionsByType)
  local maxResolutionIndex = #resolutionValues -- TODO Set limit?
  local selectedResolutions = {}
  for i=1,3 do
    for _,resolutionIndex in ipairs(resolutionsByType[i]) do
      -- Limit dotted/tri resolutions above 1/8 dot and 1/16 tri
      if resolutionIndex > maxResolutionIndex or (i == 2 and resolutionIndex > 18) or (i == 3 and resolutionIndex > 25) then
        break
      end
      table.insert(selectedResolutions, resolutionIndex)
    end
  end
  return selectedResolutions
end

-- Tries to adjust the given resolution by adjusting
-- length, and/or setting a even/dot/tri value variant
local function getResolutionVariation(currentResolution, adjustBias, doubleOrHalfProbaility, dotOrTriProbaility)
  local currentIndex = gem.getIndexFromValue(currentResolution, resolutionValues)
  if type(currentIndex) == "nil" then
    return currentResolution
  end

  if type(adjustBias) == "nil" then
    adjustBias = 50
  end

  if type(doubleOrHalfProbaility) == "nil" then
    doubleOrHalfProbaility = 50
  end

  if type(dotOrTriProbaility) == "nil" then
    dotOrTriProbaility = 50
  end

  local resolutionsByType = getResolutionsByType()

  -- Include the resolutions that are available
  local selectedResolutions = getSelectedResolutions(resolutionsByType)

  --print("BEFORE currentIndex", currentIndex)
  local resolutionIndex = currentIndex
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
    local doubleOrHalf = gem.getRandomBoolean(doubleOrHalfProbaility)
    -- Double or half duration
    if doubleOrHalf then
      local doubleResIndex = gem.getIndexFromValue((resolution * 2), resolutionValues)
      if gem.getRandomBoolean(adjustBias) == false and type(doubleResIndex) == "number" and gem.tableIncludes(selectedResolutions, doubleResIndex) then
        resolution = resolutionValues[doubleResIndex]
        --print("Slower resolution", resolution)
      else
        resolution = resolution / 2
        --print("Faster resolution", resolution)
      end
    end
    -- Set dotted (or tri) on duration if no change was done to the lenght, or probability hits
    --if doubleOrHalf == false or gem.getRandomBoolean(dotOrTriProbaility) then
    if gem.getRandomBoolean(dotOrTriProbaility) then
      if gem.tableIncludes(resolutionsByType[3], currentIndex) then
        resolution = getTriplet(resolution)
        --print("getTriplet", resolution)
      else
        local dottedResIndex = gem.getIndexFromValue(getDotted(resolution), resolutionValues)
        if type(dottedResIndex) == "number" and gem.tableIncludes(selectedResolutions, dottedResIndex) then
          resolution = resolutionValues[dottedResIndex]
          --print("getDotted", resolution)
        end
      end
    end
  end
  currentIndex = gem.getIndexFromValue(resolution, resolutionValues)
  --print("AFTER currentIndex", currentIndex)
  if type(currentIndex) == "number" and gem.tableIncludes(selectedResolutions, currentIndex) then
    --print("Got resolution from the current index")
    return resolutionValues[currentIndex]
  end

  return currentResolution
end

-- Quantize the given beat to the closest recognized resolution value
local function quantizeToClosest(beat)
  for i,v in ipairs(resolutionValues) do
    local currentValue = v
    local nextValue = resolutionValues[i+1]
    if beat == currentValue or type(nextValue) == "nil" then
      return currentValue
    end
    if beat < currentValue and beat > nextValue then
      local diffCurrent = currentValue - beat
      local diffNext = beat - nextValue
      if diffCurrent < diffNext then
        return currentValue
      else
        return nextValue
      end
    end
  end
  return resolutionValues[#resolutionValues]
end

return {--resolutions--
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
