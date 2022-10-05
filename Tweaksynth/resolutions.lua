--------------------------------------------------------------------------------
-- Common Resolutions
--------------------------------------------------------------------------------

function getDotted(value)
  return value * 1.5
end

function getTriplet(value)
  return value / 3
end

local resolutions = {
  128, -- "32x" -- 0
  64, -- "16x" -- 1
  32, -- "8x" -- 2
  28, -- "7x" -- 3
  24, -- "6x" -- 4
  20, -- "5x" -- 5
  16, -- "4x" -- 6
  12, -- "3x" -- 7
  8, -- "2x" -- 8
  6, -- "1/1 dot" -- 9
  4, -- "1/1" -- 10
  3, -- "1/2 dot" -- 11
  getTriplet(8), -- "1/1 tri" -- 12
  2, -- "1/2" -- 13
  getDotted(1), -- "1/4 dot", -- 14
  getTriplet(4), -- "1/2 tri", -- 15
  1, -- "1/4", -- 16
  getDotted(0.5), -- "1/8 dot", -- 17
  getTriplet(2), -- "1/4 tri", -- 18
  0.5,  -- "1/8", -- 19
  getDotted(0.25), -- "1/16 dot", -- 20
  getTriplet(1), -- "1/8 tri", -- 21
  0.25, -- "1/16", -- 22
  getDotted(0.125), -- "1/32 dot", -- 23
  getTriplet(0.5), -- "1/16 tri", -- 24
  0.125, -- "1/32" -- 25
  getDotted(0.0625), -- "1/64 dot", -- 26
  getTriplet(0.25), -- "1/32 tri", -- 27
  0.0625, -- "1/64", -- 28
  getTriplet(0.125) -- "1/64 tri" -- 29
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

function getResolutionsByType(maxResolutionIndex)
  if type(maxResolutionIndex) == "nil" then
    maxResolutionIndex = #resolutions - 1
  end
  local resOptions = {}
  -- Create table of resolution indexes by type (1=even,2=dot,3=tri)
  local startPos = 11 -- Start at 1/1 - pos 11
  for i=startPos,startPos+2 do
    local resolutionIndex = i
    local resolutionsOfType = {}
    while resolutionIndex <= maxResolutionIndex do
      table.insert(resolutionsOfType, resolutionIndex) -- insert current index in resolution options table
      print("Insert resolutionIndex", resolutionIndex)
      resolutionIndex = resolutionIndex + 3 -- increment index
    end
    print("resolutionsOfType", #resolutionsOfType)
    table.insert(resOptions, resolutionsOfType)
  end
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
