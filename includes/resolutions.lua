--------------------------------------------------------------------------------
-- Common Resolutions
--------------------------------------------------------------------------------

function getDotted(value)
  return value * 1.5
end

function getTriplet(value)
  return value / 3
end

-- NOTE: Make sure resolutions and resolutionNames are in sync
local resolutions = {
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
  getTriplet(0.125) -- "1/64 tri" -- 30
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
  "1/64 tri" -- 30
}

function getResolution(i)
  return resolutions[i]
end

function getResolutions()
  return resolutions
end

function getResolutionName(i)
  return resolutionNames[i]
end

function getResolutionNames(options, max)
  if type(max) ~= "number" then
    max = #resolutionNames
  end

  local res = {}

  for _,r in ipairs(resolutionNames) do
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
end

function getResolutionsByType(maxResolutionIndex, startPosIndex)
  if type(maxResolutionIndex) == "nil" then
    maxResolutionIndex = #resolutions - 1
  end
  if type(startPosIndex) == "boolean" then
    startPosIndex = getRandomFromTable({11,14,17,20})
  end
  if type(startPosIndex) == "nil" then
    startPosIndex = 11
  end
  local resOptions = {}
  -- Create table of resolution indexes by type (1=even,2=dot,3=tri)
  for i=startPosIndex,startPosIndex+2 do
    local resolutionIndex = i
    local resolutionsOfType = {}
    while resolutionIndex <= maxResolutionIndex do
      table.insert(resolutionsOfType, resolutionIndex) -- insert current index in resolution options table
      print("Insert resolutionIndex", resolutionIndex)
      resolutionIndex = resolutionIndex + 3 -- increment index
    end
    print("#resolutionsOfType, i", #resolutionsOfType, i)
    table.insert(resOptions, resolutionsOfType)
  end
  local slowResolutions = {}
  for i=3, 12 do
    print("Add slowResolution, index", i)
    table.insert(slowResolutions, i)
  end
  print("#slowResolutions", #slowResolutions)
  table.insert(resOptions, slowResolutions) -- Add the "slow" x resolutions
  --print("resOptions", #resOptions)
  return resOptions
end

function getPlayDuration(duration, gate)
  if type(gate) == "nil" then
    gate = 100
  end
  local maxResolution = resolutions[#resolutions]
  return math.max(maxResolution, duration * (gate / 100)) -- Never shorter than the system max resolution (1/64 tri)
end
