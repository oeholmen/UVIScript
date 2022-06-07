--------------------------------------------------------------------------------
-- Common methods
--------------------------------------------------------------------------------

function transpose(note, min, max)
  --print("Check transpose", note)
  if note < min then
    print("note < min", note, min)
    while note < min do
      note = note + 12
      print("transpose note up", note)
    end
  elseif note > max then
    print("note > max", note, max)
    while note > max do
      note = note - 12
      print("transpose note down", note)
    end
  end
  return note
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
      print("Found index", i)
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
  if type(min) == "number" and type(max) == "number" then
    local value = math.random(min, max)
    return value
  elseif type(min) == "number" then
    local value = math.random(min)
    return value
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
  "32x", -- 0
  "16x", -- 1
  "8x", -- 2
  "7x", -- 3
  "6x", -- 4
  "5x", -- 5
  "4x", -- 6
  "3x", -- 7
  "2x", -- 8
  "1/1 dot", -- 9
  "1/1", -- 10
  "1/2 dot", -- 11
  "1/1 tri", -- 12 NY
  "1/2", -- 13
  "1/4 dot", -- 14
  "1/2 tri", -- 15
  "1/4", -- 16
  "1/8 dot", -- 17
  "1/4 tri", -- 18
  "1/8", -- 19
  "1/16 dot", -- 20
  "1/8 tri", -- 21
  "1/16", -- 22
  "1/32 dot", -- 23
  "1/16 tri", -- 24
  "1/32", -- 25
  "1/64 dot", -- 26
  "1/32 tri", -- 27
  "1/64", -- 28
  "1/64 tri" -- 29
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

-- Get the subdivision to use for building the struncture
function getSubdivision(stepDuration, steps, minResolution, subdivisionProbability, subdivisionButtons, stop, subdivisionDotProbability)
  -- Calculate depth decay
  -- TODO If decay, there should be a setting for it...
  --[[ if currentDepth > 1 then
    subdivisionProbability = math.ceil(subdivisionProbability / (currentDepth / 2)) -- TODO Adjust
    print("subdivisionProbability/currentDepth", subdivisionProbability, currentDepth)
  end ]]
  if type(subdivisionDotProbability) == "nil" then
    subdivisionDotProbability = 25
  end
  local subdivision = 1 -- Set default
  -- Check what subdivisions can be used whit the given duration
  local subdivisions = createSubdivisions(subdivisionButtons, stepDuration, minResolution, steps)
  if #subdivisions > 0 then
    subdivision = subdivisions[1] -- First is default
    if #subdivisions > 1 and getRandomBoolean(subdivisionProbability) then
      subdivision = subdivisions[getRandom(#subdivisions)]
      print("SET RANDOM subdivision", subdivision)
    end
  end

  local dotted = false -- Set default
  local fullDuration = stepDuration * steps
  local subDivDuration = fullDuration / subdivision
  local remainderDuration = subDivDuration -- Default remainderDuration is the full subdivision duration
  if subDivDuration < minResolution or stop == true then
    subdivision = 1
    print("The minimum resolution or stop was reached - no further subdivisions are made subDivDuration/minResolution/stop", subDivDuration, minResolution, stop)
  end

  if subdivision > 1 then
    dotted = subdivision % 4 == 0 and getRandomBoolean(subdivisionDotProbability)
    print("Dotted is", dotted, subdivision)
    if dotted == true then
      stop = true -- TODO Param?
      subDivDuration = getDotted(subDivDuration)
      remainderDuration = fullDuration % subDivDuration -- Adjust remainder duration
      subdivision = math.ceil(fullDuration / subDivDuration) -- Adjust subdivision
      print("Dotted subdivision/duration/fullDuration/remainderDuration", subdivision, subDivDuration, fullDuration, remainderDuration)
      if remainderDuration < minResolution then
        remainderDuration = remainderDuration + subDivDuration
        subdivision = subdivision - 1 -- Adjust subdivision
        print("Adjust to avoid remainderDuration < minResolution subdivision/duration/fullDuration/remainderDuration", subdivision, subDivDuration, fullDuration, remainderDuration)
      end
    end
  end

  return subdivision, subDivDuration, remainderDuration, stop
end

function getSubdivisionSteps(subdivision, subDivPos, subdivisionTieProbability)
  local stop = false
  local subdivisionSteps = 1 -- Default
  local maxSteps = (subdivision - subDivPos) + 1
  if maxSteps == subdivision then
    maxSteps = maxSteps - 1 -- Avoid it lasting the whole subdivision
  end
  if maxSteps > 1 and getRandomBoolean(subdivisionTieProbability) then
    subdivisionSteps = getRandom(maxSteps)
    if subdivisionSteps > 1 then
      stop = subdivisionSteps % 2 > 0 -- Stop subdividing if not an even number -- TODO Param?
      print("subdivisionSteps % 2", (subdivisionSteps % 2))
    end
    print("Set subdivisionSteps by random subdivisionSteps/maxSteps/stop", subdivisionSteps, maxSteps, stop)
  end
  return subdivisionSteps, stop
end

function createSubdivisions(subdivisionButtons, mainBeatDuration, minResolution, steps)
  local subdivisions = {}
  for i=1,#subdivisionButtons do
    if subdivisionButtons[i].value == true then
      table.insert(subdivisions, i)
      print("Added subdivision", i)
    end
  end

  -- Automatically add subdivisions
  local numSubdivisions = #subdivisions
  for i=1,numSubdivisions do
    subdivision = subdivisions[i]
    local duration = mainBeatDuration
    while duration > minResolution do
      subdivision = subdivision * 2
      duration = (mainBeatDuration / subdivision) * steps
      print("Found subdivision/duration/minResolution", subdivision, duration, minResolution)
      if duration >= minResolution and tableIncludes(subdivisions, subdivision) == false then
        table.insert(subdivisions, subdivision)
        print("Added subdivision", subdivision)
      end
    end
  end
  return subdivisions
end
