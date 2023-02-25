-- modulators/modulationSequencer -- 
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
end

local function round(value)
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

-- sign function: -1 if x<0; 1 if x>0
local function signA(x)
  if x < 0 then
    return -1
  end
  return 1
end

-- sign function oposite: 1 if x<0; -1 if x>0
local function signB(x)
  if x < 0 then
    return 1
  end
  return -1
end

-- z = current table number, from -1.0 to 1.0
-- w = x current time-value getting plotted, from 0.0 to 1.0 same as (x+1)/2
-- When a 'q' is preset in the formula, the function plots to the FFT bins instead of plotting the to the waveform display. q iterates from 1 to 512 for the respective harmonics/bins. **
local function testShape(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 0
    local q = 1
    local x = (changePerStep * (i-1)) - 1
    local w = x
    local value = x
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- 0.5*(cos(x*pi/2)*((sin((x)*pi)+(1-z)*(sin(z*((x*x)^z)*pi*32)))))
local function sweetSine(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 0
    local q = 1
    local x = (changePerStep * (i-1)) - 1
    local w = x
    local value = 0.5*(math.cos(x*math.pi/2)*((math.sin((x)*math.pi)+(1-z)*(math.sin(z*((x*x)^z)*math.pi*32)))))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- sin(w*pi*(2+(62*z*z*z)))*sin(w*pi)
local function softSine(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(1, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = -0
    local q = 1
    local x = (changePerStep * (i-1)) - 1
    local w = x
    local value = math.sin(w*math.pi*(2+(62*z*z*z)))*math.sin(w*math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- sin(w*pi*(2+(62*z*z*z)))*sin(w*pi)
local function drop(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 1
    local q = 1
    local x = (changePerStep * (i-1)) - 1
    local w = x
    local value = math.sin(w*math.pi*(2+(62*z*z*z)))*math.sin(w*math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- cos(x*pi/2)*1.6*(.60*sin( ((z*16)+1)*3*x ) + .20*sin( ((z*16)+1)*9*x ) + .15*sin( ((z*16)+1)*15*x))
local function tripleSin(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 0
    local x = (changePerStep * (i-1)) - 1
    local value = math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- organish sin(x*pi)+(0.16*(sin(2*x*pi)+sin(3*x*pi)+sin(4*x*pi)))
local function organIsh(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = math.sin(x*math.pi)+(0.16*(math.sin(2*x*math.pi)+math.sin(3*x*math.pi)+math.sin(4*x*math.pi)))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- filtered sqr 1.2*sin(x*pi)+0.31*sin(x*pi*3)+0.11*sin(x*pi*5)+0.033*sin(x*pi*7)
local function filteredSquare(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = 1.2*math.sin(x*math.pi)+0.31*math.sin(x*math.pi*3)+0.11*math.sin(x*math.pi*5)+0.033*math.sin(x*math.pi*7)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- hpf saw x-(0.635*sin(x*pi))
local function hpfSaw(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = x-(0.635*math.sin(x*math.pi))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- sin(x*pi)
local function shape(minValue, maxValue, numSteps, shapeFunc)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1))
    local value = math[shapeFunc](x * math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  if shapeFunc == 'sin' or shapeFunc == 'tan' then
    shape[#shape] = shape[1]
  else
    shape[#shape] = maxValue
  end
  return shape
end

local function shapeReverse(minValue, maxValue, numSteps, shapeFunc)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = math[shapeFunc](x * math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  if shapeFunc == 'sin' or shapeFunc == 'tan' then
    shape[#shape] = shape[1]
  else
    shape[#shape] = maxValue
  end
  return shape
end

local function shapeDouble(minValue, maxValue, numSteps, shapeFunc)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = 2 * (changePerStep * (i-1))
    local value = math[shapeFunc](x * math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  if shapeFunc == 'sin' or shapeFunc == 'tan' then
    shape[#shape] = shape[1]
  else
    shape[#shape] = maxValue
  end
  return shape
end

-- Saw in phase x < 0 ? -1-x : 1-x
local function sawInPhase(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = signA(x)-x
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- SquareTri -1*(sign(x)*0.5)+(abs(x)-0.5)
local function squareTri(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = -1*(signA(x)*0.5)+(math.abs(x)-0.5)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- rint = round to nearest integer
--(rint(16*abs(x))/8.0)-1
local function lofiTriangle(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = (round(16*math.abs(x))/8.0)-1
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function doubleSaw(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = (x*2)+signB(x)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function dome50(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(1, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = -1-1.275*math.sin(x*math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function sawAnalog(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1))
    local value = 2.001 * (math.sin(x * 0.7905) - 0.5)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function dome(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - .0
    local value = 2 * (math.sin(x * 1.5705) - 0.5)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function triangleInPhase(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = math.min(2+2*x, math.abs((x-0.5)*2)-1)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function triangleOffPhase(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = math.abs(x*2)-1
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function triangleOffPhaseReverse(minValue, maxValue, numSteps)
  local rising = true
  local numStepsUpDown = math.floor(numSteps / 2)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numStepsUpDown)
  local startValue = minValue
  local shape = {}
  for i=1,numSteps do
    table.insert(shape, startValue)
    if rising then
      startValue = startValue + changePerStep
      if startValue >= maxValue then
        rising = false
      end
    else
      startValue = startValue - changePerStep
    end
  end
  shape[#shape] = minValue
  return shape
end

local function ramp(minValue, maxValue, numSteps, f)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(1, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) + f
    local value = math.min(2+2*x, math.abs((x-0.5)*2)-1)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function rampUp(minValue, maxValue, numSteps)
  return ramp(minValue, maxValue, numSteps, .5)
end

local function rampDown(minValue, maxValue, numSteps)
  return ramp(minValue, maxValue, numSteps, -.5)
end

local gem = {
  inc = inc,
  round = round,
  shape = shape,
  shapeReverse = shapeReverse,
  shapeDouble = shapeDouble,
  dome = dome,
  dome50 = dome50,
  hpfSaw = hpfSaw,
  sawAnalog = sawAnalog,
  sawInPhase = sawInPhase,
  doubleSaw = doubleSaw,
  filteredSquare = filteredSquare,
  organIsh = organIsh,
  rampUp = rampUp,
  rampDown = rampDown,
  squareTri = squareTri,
  triangle = triangleOffPhaseReverse,
  lofiTriangle = lofiTriangle,
  triangleInPhase = triangleInPhase,
  triangleOffPhase = triangleOffPhase,
  triangleOffPhaseReverse = triangleOffPhaseReverse,
  testShape = testShape,
  sweetSine = sweetSine,
  softSine = softSine,
  drop = drop,
  tripleSin = tripleSin,
  getRandom = getRandom,
  getChangeMax = getChangeMax,
  tableIncludes = tableIncludes,
  randomizeValue = randomizeValue,
  trimStartAndEnd = trimStartAndEnd,
  getRandomBoolean = getRandomBoolean,
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

local resolutions = {
  quantizeToClosest = quantizeToClosest,

  getDotted = getDotted,

  getTriplet = getTriplet,

  getEvenFromDotted = function(value)
    return value / 1.5
  end,
  
  getEvenFromTriplet = function(value)
    return value * 3
  end,
  
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
  end,
  
  getResolutionsByType = function(maxResolutionIndex)
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
-- Common functions and widgets that are shared for the modulation sequencers
--------------------------------------------------------------------------------

outlineColour = "#FFB5FF"
menuBackgroundColour = "#bf01011F"
menuTextColour = "#9f02ACFE"
menuArrowColour = "#9f09A3F4"
menuOutlineColour = "#00000000"
pageBackgoundColour = "222222"
numParts = 1
numPages = 1
maxPages = 8
activePage = 1
nextUp = 1
paramsPerPart = {}
paramsPerPage = {}
isPlaying = false

--------------------------------------------------------------------------------
-- Define widgets
--------------------------------------------------------------------------------

local pageButtons = {}
local headerPanel = Panel("Header")
local footerPanel = Panel("Footer")
local defaultActions = {"Actions...", "Randomize", "Ramp Up", "Ramp Down", "Triangle", "Sine", "Cosine", "Tangent", "Even", "Odd", "Reduce 50%"}
local actionMenu = footerPanel:Menu("ActionMenu", defaultActions)
local cyclePagesButton = footerPanel:OnOffButton("CyclePagesButton")
local changePageProbability = footerPanel:NumBox("ChangePageProbability", 0, 0, 100, true)

--------------------------------------------------------------------------------
-- Common Functions
--------------------------------------------------------------------------------

-- Get the index for this part in paramsPerPart, given page and part number
local function getPartIndex(part, page)
  if type(page) == "nil" then
    page = activePage -- Default is the active page
  end
  --print("getPartIndex page/part/numParts", page, part, numParts)
  return (page * numParts) + (part - numParts)
end

-- Get page from part index
local function getPageFromPartIndex(partIndex)
  --print("getPageFromPartIndex partIndex", partIndex)
  return math.ceil(partIndex / maxPages)
end

local function advancePage()
  local next = activePage + 1
  if next > numPages then
    next = 1
  end
  pageButtons[next]:setValue(true)
end

local function gotoNextPage()
  -- Check that there is actually a a change
  if activePage == nextUp then
    return
  end
  activePage = nextUp
  for page,params in ipairs(paramsPerPage) do
    local isVisible = page == activePage
    params.sequencerPanel.visible = isVisible
    params.minRepeats.visible = isVisible
    pageButtons[page]:setValue(isVisible, false)
  end
end

local function clearPosition()
  for _,v in ipairs(paramsPerPart) do
    for i=1,v.numStepsBox.value do
      v.positionTable:setValue(i, 0)
    end
  end
end

local function setPageDuration(page)
  print("setPageDuration for page", page)
  local pageResolutions = {}
  for part=1,numParts do
    local partIndex = getPartIndex(part, page)
    print("getResolution for partIndex", partIndex)
    local partResolution = resolutions.getResolution(paramsPerPart[partIndex].stepResolution.value)
    if paramsPerPart[partIndex].stepButton.value then
      partResolution = partResolution * paramsPerPart[partIndex].numStepsBox.value
    end
    table.insert(pageResolutions, partResolution)
    print("Added resolution/part/page", partResolution, part, page)
  end
  table.sort(pageResolutions)
  paramsPerPage[page].pageDuration = pageResolutions[#pageResolutions]
end

local function setNumSteps(partIndex, numSteps)
  print("setNumSteps for partIndex/numSteps", partIndex, numSteps)
  paramsPerPart[partIndex].positionTable.length = numSteps
  paramsPerPart[partIndex].seqValueTable.length = numSteps
  if type(paramsPerPart[partIndex].smoothStepTable) ~= "nil" then
    paramsPerPart[partIndex].smoothStepTable.length = numSteps
  end
  local page = getPageFromPartIndex(partIndex)
  setPageDuration(page)
end

local function pageRunner()
  local repeatCounter = -1
  while isPlaying do
    repeatCounter = repeatCounter + 1
    local repeats = paramsPerPage[activePage].minRepeats.value
    print("New round on page/duration/repeats/repeatCounter", activePage, paramsPerPage[activePage].pageDuration, repeats, repeatCounter)
    if repeatCounter >= repeats and nextUp == activePage then
      if gem.getRandomBoolean(changePageProbability.value) then
        nextUp = gem.getRandom(numPages)
      elseif cyclePagesButton.value == true then
        nextUp = activePage + 1
        if nextUp > numPages then
          nextUp = 1
        end
      end
      repeatCounter = 0 -- Reset repeat counter
    end

    gotoNextPage()

    waitBeat(paramsPerPage[activePage].pageDuration)
  end
end

local function startPlaying()
  if isPlaying == true then
    return
  end
  spawn(pageRunner)
  for i=1,numParts do
    print("Start playing", i)
    spawn(arpeg, i)
  end
  isPlaying = true
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  print("Stop playing")
  isPlaying = false
  clearPosition()
  gotoNextPage()
end

--------------------------------------------------------------------------------
-- Common Widgets
--------------------------------------------------------------------------------

headerPanel.backgroundColour = menuOutlineColour
headerPanel.x = 10
headerPanel.y = 10
headerPanel.width = 700
headerPanel.height = 30

local label = headerPanel:Label("Label")
label.backgroundColour = "808080"
label.textColour = pageBackgoundColour
label.fontSize = 22
label.position = {0,0}
label.size = {190,25}

local labelInput = headerPanel:Label("Label")
labelInput.text = ""
labelInput.editable = true
labelInput.backgroundColour = pageBackgoundColour
labelInput.textColour = "808080"
labelInput.backgroundColourWhenEditing = "white"
labelInput.textColourWhenEditing = "black"
labelInput.fontSize = 16
labelInput.width = 180
labelInput.x = label.x + label.width + 10
labelInput.y = 3

local playButton = headerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = "#ff084486"
playButton.backgroundColourOn = "#ff02ACFE"
playButton.textColourOff = "#ff22FFFF"
playButton.textColourOn = "#efFFFFFF"
playButton.displayName = "Play"
playButton.size = {102,22}
playButton.x = headerPanel.width - playButton.width
playButton.y = 2
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

local autoplayButton = headerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = "#ff084486"
autoplayButton.backgroundColourOn = "#ff02ACFE"
autoplayButton.textColourOff = "#ff22FFFF"
autoplayButton.textColourOn = "#efFFFFFF"
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = {102,22}
autoplayButton.x = playButton.x - playButton.width - 5
autoplayButton.y = playButton.y

footerPanel.backgroundColour = menuOutlineColour
footerPanel.x = 10
footerPanel.width = 700
if maxPages == 1 then
  footerPanel.enabled = false
  footerPanel.visible = false
  footerPanel.height = 10
else
  footerPanel.height = 30
end

changePageProbability.displayName = "Random"
changePageProbability.tooltip = "Probability of random page change"
changePageProbability.enabled = false
changePageProbability.unit = Unit.Percent
changePageProbability.size = {110,22}
changePageProbability.x = (33 * maxPages) + 102

local pageButtonSize = {25,22}

local nextPageButton = footerPanel:Button("NextPageButton")
nextPageButton.persistent = false
nextPageButton.enabled = numPages > 1
nextPageButton.displayName = ">"
nextPageButton.tooltip = "Go to next page in the cycle"
nextPageButton.size = pageButtonSize
nextPageButton.changed = function(self)
  advancePage()
end

cyclePagesButton.enabled = numPages > 1
cyclePagesButton.displayName = ">>"
cyclePagesButton.tooltip = "Play pages in cycle"
cyclePagesButton.backgroundColourOff = "#6600cc44"
cyclePagesButton.backgroundColourOn = "#aa00cc44"
cyclePagesButton.textColourOff = "#cc22FFFF"
cyclePagesButton.textColourOn = "#ccFFFFFF"
cyclePagesButton.size = pageButtonSize

local numPagesBox = footerPanel:NumBox("Pages", numPages, 1, maxPages, true)
numPagesBox.tooltip = "Number of active pages"
numPagesBox.backgroundColour = menuBackgroundColour
numPagesBox.textColour = menuTextColour
numPagesBox.size = {90,22}
numPagesBox.x = 0
numPagesBox.changed = function(self)
  numPages = self.value
  changePageProbability.enabled = self.value > 1
  nextPageButton.enabled = self.value > 1
  cyclePagesButton.enabled = self.value > 1
  for page=1,self.max do
    setPageDuration(page)
    pageButtons[page].enabled = page <= numPages
    paramsPerPage[page].minRepeats.enabled = numPages > 1
  end
  -- Update action menu
  local actionMenuItems = {}
  for i=1,#defaultActions do
    table.insert(actionMenuItems, defaultActions[i])
  end
  if numPages > 1 then
    for i=1,numPages do
      table.insert(actionMenuItems, "Copy settings from page " .. i)
    end
  end
  actionMenu.items = actionMenuItems
end

-- Add page buttons
local xPadding = 1
for page=1,maxPages do
  local pageButton = footerPanel:OnOffButton("PageButton" .. page, (page==1))
  pageButton.persistent = false
  pageButton.enabled = page <= numPages
  pageButton.displayName = "" .. page
  pageButton.backgroundColourOff = "#ff084486"
  pageButton.backgroundColourOn = "#ff02ACFE"
  pageButton.textColourOff = "#ff22FFFF"
  pageButton.textColourOn = "#efFFFFFF"
  pageButton.size = pageButtonSize
  pageButton.x = numPagesBox.width + ((pageButton.width + xPadding) * page) - 17
  pageButton.changed = function(self)
    if self.value == true then
      nextUp = page -- register next up
      if isPlaying == false then
        gotoNextPage()
      end
    end
    self:setValue(true, false) -- The clicked button should stay active
  end
  table.insert(pageButtons, pageButton)
end

cyclePagesButton.x = pageButtons[#pageButtons].x + pageButtons[#pageButtons].width + xPadding
nextPageButton.x = cyclePagesButton.x + cyclePagesButton.width + xPadding

actionMenu.persistent = false
actionMenu.tooltip = "Select an action. NOTE: This changes data in the affected tables"
actionMenu.backgroundColour = menuBackgroundColour
actionMenu.textColour = menuTextColour
actionMenu.arrowColour = menuArrowColour
actionMenu.outlineColour = menuOutlineColour
actionMenu.showLabel = false
actionMenu.x = changePageProbability.x + changePageProbability.width + 5
actionMenu.size = {110,22}
actionMenu.changed = function(self)
  -- {"Actions...", "Randomize", "Ramp Up", "Ramp Down", "Triangle", "Sine", "Cosine", "Tangent", "Even", "Odd", "Reduce 50%"}
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end
  if self.value == 2 then
    -- Randomize value table
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      for i=1,paramsPerPart[partIndex].numStepsBox.value do
        paramsPerPart[partIndex].seqValueTable:setValue(i, gem.getRandom(paramsPerPart[partIndex].seqValueTable.min, paramsPerPart[partIndex].seqValueTable.max))
      end
    end
  elseif self.value == 3 then
    -- Ramp Up
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      for i,v in ipairs(gem.rampUp(minValue, maxValue, numSteps)) do
        paramsPerPart[partIndex].seqValueTable:setValue(i, v)
      end
    end
  elseif self.value == 4 then
    -- Ramp Down
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      for i,v in ipairs(gem.rampDown(minValue, maxValue, numSteps)) do
        paramsPerPart[partIndex].seqValueTable:setValue(i, v)
      end
    end
  elseif self.value == 5 then
    -- Triangle
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      for i,v in ipairs(gem.triangle(minValue, maxValue, numSteps)) do
        paramsPerPart[partIndex].seqValueTable:setValue(i, v)
      end
    end
  elseif self.value == 6 then
    -- Sine
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      for i,v in ipairs(gem.shape(minValue, maxValue, numSteps, 'sin')) do
        paramsPerPart[partIndex].seqValueTable:setValue(i, v)
      end
    end
  elseif self.value == 7 then
    -- Cosine
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      for i,v in ipairs(gem.shape(minValue, maxValue, numSteps, 'cos')) do
        paramsPerPart[partIndex].seqValueTable:setValue(i, v)
      end
    end
  elseif self.value == 8 then
    -- Tangent
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      for i,v in ipairs(gem.shape(minValue, maxValue, numSteps, 'tan')) do
        paramsPerPart[partIndex].seqValueTable:setValue(i, v)
      end
    end
  elseif self.value == 9 then
    -- Even
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      for i=1,numSteps do
        local val = minValue
        if i % 2 == 0 then
          val = maxValue
        end
        paramsPerPart[partIndex].seqValueTable:setValue(i, val)
      end
    end
  elseif self.value == 10 then
    -- Odd
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      for i=1,numSteps do
        local val = maxValue
        if i % 2 == 0 then
          val = minValue
        end
        paramsPerPart[partIndex].seqValueTable:setValue(i, val)
      end
    end
  elseif self.value == 11 then
    -- Reduce 50%
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local seqValueTable = paramsPerPart[partIndex].seqValueTable
      local minValue = seqValueTable.min
      local maxValue = seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      for i=1,numSteps do
        local val = seqValueTable:getValue(i) / 2
        seqValueTable:setValue(i, val)
      end
    end
  else
    -- Copy settings from another page
    local sourcePage = self.value - #defaultActions
    local targetPage = activePage
    for part=1,numParts do
      local sourcePartIndex = getPartIndex(part, sourcePage)
      local targetPartIndex = getPartIndex(part, targetPage)
      if sourcePartIndex ~= targetPartIndex then
        local source = paramsPerPart[sourcePartIndex]
        local target = paramsPerPart[targetPartIndex]
        target.numStepsBox:setValue(source.numStepsBox.value)
        for i=1, target.numStepsBox.value do
          target.seqValueTable:setValue(i, source.seqValueTable:getValue(i))
          target.smoothStepTable:setValue(i, source.smoothStepTable:getValue(i))
        end
        -- Copy Settings
        target.stepResolution:setValue(source.stepResolution.value)
        target.smoothInput:setValue(source.smoothInput.value)
        target.valueRandomization:setValue(source.valueRandomization.value)
        target.smoothRandomization:setValue(source.smoothRandomization.value)
        target.stepButton:setValue(source.stepButton.value)
        target.bipolarButton:setValue(source.bipolarButton.value)
      end
    end
  end
  self.selected = 1
end

local function setTitle(title)
  label.text = title
end

local function setTitleTooltip(tooltip)
  label.tooltip = tooltip
end

--------------------------------------------------------------------------------
-- Return Module
--------------------------------------------------------------------------------

local modseq = {
  headerPanel = headerPanel,
  footerPanel = footerPanel,
  actionMenu = actionMenu,
  labelInput = labelInput,
  playButton = playButton,
  autoplayButton = autoplayButton,
  getPartIndex = getPartIndex,
  setPageDuration = setPageDuration,
  setNumSteps = setNumSteps,
  setTitle = setTitle,
  setTitleTooltip = setTitleTooltip,
}

--------------------------------------------------------------------------------
-- A sequencer sending script event modulation in broadcast mode
--------------------------------------------------------------------------------

local isAutoPlayActive = false
local heldNotes = {}

modseq.setTitle("Modulation Sequencer")
modseq.setTitleTooltip("A sequencer sending script event modulation in broadcast mode")

setBackgroundColour(pageBackgoundColour)

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

local sourceIndex = modseq.headerPanel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.displayName = "Event Id"
sourceIndex.backgroundColour = menuBackgroundColour
sourceIndex.textColour = menuTextColour
sourceIndex.size = {102,22}
sourceIndex.x = modseq.autoplayButton.x - modseq.autoplayButton.width - 5
sourceIndex.y = modseq.autoplayButton.y

-- Add params that are to be editable per page / part
for page=1,maxPages do
  local tableX = 0
  local tableY = 0
  local tableWidth = 700
  local tableHeight = 64
  local buttonRowHeight = 36
  local buttonSpacing = 9
  local inputWidgetSize = {90,20}
  local defaultSteps = 16

  if numParts == 1 then
    tableHeight = tableHeight * 2
  end

  local sequencerPanel = Panel("SequencerPage" .. page)
  sequencerPanel.visible = page == 1
  sequencerPanel.backgroundColour = menuOutlineColour
  sequencerPanel.x = 10
  sequencerPanel.y = modseq.headerPanel.height + 15
  sequencerPanel.width = 700
  sequencerPanel.height = numParts * (tableHeight + 30 + buttonRowHeight)

  for part=1,numParts do
    local isVisible = true
    local i = modseq.getPartIndex(part, page)
    print("Set paramsPerPart, page/part", page, i)

    -- Tables

    local positionTable = sequencerPanel:Table("Position" .. i, defaultSteps, 0, 0, 1, true)
    positionTable.visible = isVisible
    positionTable.enabled = false
    positionTable.persistent = false
    positionTable.fillStyle = "solid"
    positionTable.backgroundColour = "#9f02ACFE"
    positionTable.sliderColour = outlineColour
    positionTable.width = tableWidth
    positionTable.height = 3
    positionTable.x = tableX
    positionTable.y = tableY

    local seqValueTable = sequencerPanel:Table("ModulationValue" .. i, defaultSteps, 0, 0, 100)
    seqValueTable.visible = isVisible
    seqValueTable.displayName = "Velocity"
    seqValueTable.tooltip = "Velocity for this step"
    seqValueTable.showPopupDisplay = true
    seqValueTable.showLabel = false
    seqValueTable.fillStyle = "solid"
    seqValueTable.sliderColour = "#9f09A3F4"
    if i % 2 == 0 then
      seqValueTable.backgroundColour = "#3f000000"
    else
      seqValueTable.backgroundColour = "#3f000000"
    end
    seqValueTable.width = tableWidth
    seqValueTable.height = tableHeight
    seqValueTable.x = tableX
    seqValueTable.y = positionTable.y + positionTable.height + 2
    
    local smoothStepTable = sequencerPanel:Table("SmoothStep" .. i, defaultSteps, 0, 0, 100, true)
    smoothStepTable.visible = isVisible
    smoothStepTable.tooltip = "Smooth transition to next step (overrides global smoothing for this step)"
    smoothStepTable.fillStyle = "solid"
    if i % 2 == 0 then
      smoothStepTable.backgroundColour = "#3f606060"
    else
      smoothStepTable.backgroundColour = "#3f606060"
    end
    smoothStepTable.showLabel = false
    smoothStepTable.sliderColour = "#3f339900"
    smoothStepTable.width = tableWidth
    smoothStepTable.height = 30
    smoothStepTable.x = tableX
    smoothStepTable.y = seqValueTable.y + seqValueTable.height + 2

    local inputWidgetY = smoothStepTable.y + smoothStepTable.height + 5

    -- Inputs

    local stepButton = sequencerPanel:OnOffButton("Step" .. i, false)
    stepButton.displayName = "Step"
    stepButton.tooltip = "The selected resolution applies to each step, not the whole round"
    stepButton.visible = isVisible
    stepButton.backgroundColourOff = "#ff084486"
    stepButton.backgroundColourOn = "#ff02ACFE"
    stepButton.textColourOff = "#ff22FFFF"
    stepButton.textColourOn = "#efFFFFFF"
    stepButton.size = {53,20}
    stepButton.x = 0
    stepButton.y = inputWidgetY
    stepButton.changed = function(self)
      modseq.setPageDuration(page)
    end

    local stepResolution = sequencerPanel:Menu("StepResolution" .. i, resolutions.getResolutionNames())
    stepResolution.tooltip = "Set the round (or step) resolution"
    stepResolution.showLabel = false
    stepResolution.visible = isVisible
    stepResolution.selected = 11
    stepResolution.x = stepButton.x + stepButton.width + buttonSpacing
    stepResolution.y = inputWidgetY
    stepResolution.size = {60,20}
    stepResolution.backgroundColour = menuBackgroundColour
    stepResolution.textColour = menuTextColour
    stepResolution.arrowColour = menuArrowColour
    stepResolution.outlineColour = menuOutlineColour
    stepResolution.changed = function(self)
      modseq.setPageDuration(page)
    end

    local numStepsBox = sequencerPanel:NumBox("Steps" .. i, defaultSteps, 1, 128, true)
    numStepsBox.displayName = "Steps"
    numStepsBox.tooltip = "The Number of steps in the part"
    numStepsBox.visible = isVisible
    numStepsBox.backgroundColour = menuBackgroundColour
    numStepsBox.textColour = menuTextColour
    numStepsBox.arrowColour = menuArrowColour
    numStepsBox.outlineColour = menuOutlineColour
    numStepsBox.size = {80,20}
    numStepsBox.x = stepResolution.x + stepResolution.width + buttonSpacing
    numStepsBox.y = inputWidgetY
    numStepsBox.changed = function(self)
      print("numStepsBox.changed index/value", i, self.value)
      modseq.setNumSteps(i, self.value)
    end

    local valueRandomization = sequencerPanel:NumBox("ValueRandomization" .. i, 0, 0, 100, true)
    valueRandomization.displayName = "Value Rand"
    valueRandomization.tooltip = "Level of randomization applied to the control value"
    valueRandomization.unit = Unit.Percent
    valueRandomization.visible = isVisible
    valueRandomization.backgroundColour = menuBackgroundColour
    valueRandomization.textColour = menuTextColour
    valueRandomization.arrowColour = menuArrowColour
    valueRandomization.outlineColour = menuOutlineColour
    valueRandomization.size = {150,20}
    valueRandomization.x = numStepsBox.x + numStepsBox.width + buttonSpacing
    valueRandomization.y = inputWidgetY

    local smoothRandomization = sequencerPanel:NumBox("SmoothRandomization" .. i, 0, 0, 100, true)
    smoothRandomization.displayName = "Smooth Rand"
    smoothRandomization.tooltip = "Level of randomization applied to smooth level"
    smoothRandomization.unit = Unit.Percent
    smoothRandomization.visible = isVisible
    smoothRandomization.backgroundColour = menuBackgroundColour
    smoothRandomization.textColour = menuTextColour
    smoothRandomization.arrowColour = menuArrowColour
    smoothRandomization.outlineColour = menuOutlineColour
    smoothRandomization.size = {150,20}
    smoothRandomization.x = valueRandomization.x + valueRandomization.width + buttonSpacing
    smoothRandomization.y = inputWidgetY

    local smoothInput = sequencerPanel:NumBox("GlobalSmooth" .. i, 0, 0, 100, true)
    smoothInput.displayName = "Smooth"
    smoothInput.tooltip = "Use smoothing (non destructive) to even out the transition between value changes"
    smoothInput.unit = Unit.Percent
    smoothInput.visible = isVisible
    smoothInput.backgroundColour = menuBackgroundColour
    smoothInput.textColour = menuTextColour
    smoothInput.arrowColour = menuArrowColour
    smoothInput.outlineColour = menuOutlineColour
    smoothInput.size = {100,20}
    smoothInput.x = smoothRandomization.x + smoothRandomization.width + buttonSpacing
    smoothInput.y = inputWidgetY

    local bipolarButton = sequencerPanel:OnOffButton("Bipolar" .. i, false)
    bipolarButton.displayName = "Bipolar"
    bipolarButton.visible = isVisible
    bipolarButton.backgroundColourOff = "#ff084486"
    bipolarButton.backgroundColourOn = "#ff02ACFE"
    bipolarButton.textColourOff = "#ff22FFFF"
    bipolarButton.textColourOn = "#efFFFFFF"
    bipolarButton.size = {53,20}
    bipolarButton.x = smoothInput.x + smoothInput.width + buttonSpacing
    bipolarButton.y = inputWidgetY
    bipolarButton.changed = function(self)
      if self.value then
        seqValueTable:setRange(-100,100)
      else
        seqValueTable:setRange(0,100)
      end
    end

    table.insert(paramsPerPart, {stepButton=stepButton,smoothStepTable=smoothStepTable,smoothInput=smoothInput,valueRandomization=valueRandomization,smoothRandomization=smoothRandomization,seqValueTable=seqValueTable,positionTable=positionTable,stepResolution=stepResolution,numStepsBox=numStepsBox})

    tableY = tableY + tableHeight + buttonRowHeight
  end

  local minRepeats = modseq.footerPanel:NumBox("MinRepeats" .. page, 1, 1, 128, true)
  minRepeats.displayName = "Repeats"
  minRepeats.tooltip = "The minimum number of repeats before page will be changed (only relevant when multiple pages are activated)"
  minRepeats.visible = page == 1
  minRepeats.enabled = false
  minRepeats.backgroundColour = menuBackgroundColour
  minRepeats.textColour = menuTextColour
  minRepeats.arrowColour = menuArrowColour
  minRepeats.outlineColour = menuOutlineColour
  minRepeats.size = {100,20}
  minRepeats.x = modseq.actionMenu.x + modseq.actionMenu.width + 9
  minRepeats.y = modseq.actionMenu.y

  table.insert(paramsPerPage, {sequencerPanel=sequencerPanel,minRepeats=minRepeats,pageDuration=nil,active=(page==1)})
  modseq.setPageDuration(page)
end

modseq.footerPanel.y = paramsPerPage[1].sequencerPanel.y + paramsPerPage[1].sequencerPanel.height

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function arpeg(part)
  local index = 0
  while isPlaying do
    local partIndex = modseq.getPartIndex(part)
    local numStepsInPart = paramsPerPart[partIndex].numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local smooth = paramsPerPart[partIndex].smoothInput.value
    local step = paramsPerPart[partIndex].stepButton.value
    local duration = resolutions.getResolution(paramsPerPart[partIndex].stepResolution.value)
    local seqValueTable = paramsPerPart[partIndex].seqValueTable
    local smoothStepTable = paramsPerPart[partIndex].smoothStepTable
    local valueRandomizationAmount = paramsPerPart[partIndex].valueRandomization.value
    local smoothRandomizationAmount = paramsPerPart[partIndex].smoothRandomization.value

    -- Set position
    for i=1, numStepsInPart do
      local isActiveStep = i >= currentPosition and i < currentPosition + 1
      if isActiveStep then
        paramsPerPart[partIndex].positionTable:setValue(i, 1)
      else
        paramsPerPart[partIndex].positionTable:setValue(i, 0)
      end
    end

    if step == false then
      duration = duration / numStepsInPart
    end

    -- Send modulation
    local smoothStepValue = smoothStepTable:getValue(currentPosition)
    if smoothStepValue > 0 then
      smooth = smoothStepValue
    end
    smooth = gem.randomizeValue(smooth, smoothStepTable.min, smoothStepTable.max, smoothRandomizationAmount)
    local rampTime = 20
    if smooth > 0 then
      rampTime = beat2ms(duration) * (smooth / 100)
    end
    local value = seqValueTable:getValue(currentPosition)
    value = gem.randomizeValue(value, seqValueTable.min, seqValueTable.max, valueRandomizationAmount)
    sendScriptModulation(sourceIndex.value, (value/100), rampTime)

    -- Increment position
    index = (index + 1) % numStepsInPart

    -- Wait for next beat
    waitBeat(duration)
  end
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function remove(voiceId)
  for i,v in ipairs(heldNotes) do
    if v == voiceId then
      table.remove(heldNotes, i)
    end
  end
end

function onNote(e)
  local voiceId = postEvent(e)
  table.insert(heldNotes, voiceId)
  if #heldNotes == 1 then
    modseq.playButton:setValue(true)
  end
end

function onRelease(e)
  local voiceId = postEvent(e)
  remove(voiceId)
  -- Make sure we do not stop the modulation sequencer when transport is playing
  if #heldNotes == 0 and isAutoPlayActive == false then
    modseq.playButton:setValue(false)
  end
end

function onTransport(start)
  if modseq.autoplayButton.value == true then
    isAutoPlayActive = start
    modseq.playButton:setValue(start)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local numStepsData = {}
  local seqValueTableData = {}
  local smoothStepTableData = {}

  for _,v in ipairs(paramsPerPart) do
    table.insert(numStepsData, v.numStepsBox.value)
    for j=1, v.numStepsBox.value do
      table.insert(seqValueTableData, v.seqValueTable:getValue(j))
      table.insert(smoothStepTableData, v.smoothStepTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, numStepsData)
  table.insert(data, seqValueTableData)
  table.insert(data, smoothStepTableData)
  table.insert(data, modseq.labelInput.text)
  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqValueTableData = data[2]
  local smoothStepTableData = data[3]
  modseq.labelInput.text = data[4]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].seqValueTable.length = v
    paramsPerPart[i].smoothStepTable.length = v
    for j=1, v do
      paramsPerPart[i].seqValueTable:setValue(j, seqValueTableData[dataCounter])
      paramsPerPart[i].smoothStepTable:setValue(j, smoothStepTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
  for page=1,numPages do
    modseq.setPageDuration(page)
  end
end
