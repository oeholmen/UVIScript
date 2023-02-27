-- sequencers/midiControlSequencer -- 
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

local gem = {
  inc = inc,
  avg = avg,
  sign = sign,
  round = round,
  getRandom = getRandom,
  getChangeMax = getChangeMax,
  tableIncludes = tableIncludes,
  randomizeValue = randomizeValue,
  trimStartAndEnd = trimStartAndEnd,
  getChangePerStep = getChangePerStep,
  getRandomBoolean = getRandomBoolean,
  getIndexFromValue = getIndexFromValue,
  getRandomFromTable = getRandomFromTable,
}

--------------------------------------------------------------------------------
-- Methods for working with shapes
--------------------------------------------------------------------------------

-- Keep in sync with function names
local shapeNames = {
  "Ramp Up",
  "Ramp Down",
  "Sine",
  "Triangle",
  "Triangle (Off Phs)",
  "LoFi Triangle",
  "Sqr/Tri",
  "Dome",
  "Dome Small",
  "Saw",
  "HPF Saw",
  "Analog Saw",
  "Fltr Sqr", 
  "Organ-Ish",
  "Tangent",
  "Triple Sine",
  "Punk Sine",
  "Soft Sine",
  "Even",
  "Odd",
  "Zero",
  "Min",
  "Max",
  "Chaos To Sine",
  "Saw/Sin Reveal",
  "PWM 50 to 100",
  "Triple-Sin Window",
  "Taffy",
  "Brassy",
  "HPF-Sqr To Sqr",
  "Wacky",
  "Sine To Noise",
  "Window-y SQR Sync",
  "Random",
  --"Test Shape",
}

local shapeFunctions = {
  "rampUp",
  "rampDown",
  "sine",
  "triangle",
  "triangleOffPhase",
  "lofiTriangle",
  "squareTri",
  "dome",
  "domeSmall",
  "sawInPhase",
  "hpfSaw",
  "sawAnalog",
  "filteredSquare", 
  "organIsh",
  "tangent",
  "tripleSin",
  "punkSine",
  "softSine",
  "even",
  "odd",
  "zero",
  "min",
  "max",
  "chaosToSine",
  "sawSinReveal",
  "pwm50to100",
  "tripleSinWindow",
  "taffy",
  "brassy",
  "hpfSqrToSqr",
  "wacky",
  "sinToNoise",
  "windowYSqr",
  "random",
  "testShape",
}

-- Holds the shape definitions
-- x = current time-value getting plotted, from -1.0 to 1.0 OR 0.0 to 1.0 (same as (x+1)/2) - depending on stepRange=1|2
-- z = current table number, from -1.0 to 1.0
-- i = current index
local shapes = {
  triangleShaper = function(x, z) return math.min(2+2*x, math.abs((x-0.5)*2)-1) * z end,
  sineShaper = function(x, z) return math.cos(x) * z end,
  sawInPhase = function(x, z) return (gem.sign(x)-x) * z end,
  sinToNoise = function(x, z, i) return 2*gem.avg({math.sin(z*x*math.pi),(1-z)*gem.getRandom()}) end,
  wacky = function(x, z, i) return math.sin(((x)+1)^(z-1)*math.pi) end,
  hpfSqrToSqr = function(x, z, i) if x < 0 then return math.sin((z*0.5)*math.pi)^(x+1) end return -math.sin((z*0.5)*math.pi)^x end,
  windowYSqr = function(x, z, i) local v = 1 if math.abs(x) > 0.5 then v = (1-math.abs(x))*2 end return v * math.min(1, math.max(-1,8*math.sin((z+0.02)*x*math.pi*32))) end,
  filteredSquare = function(x, z, i) return (1.2*math.sin(x*math.pi)+0.31*math.sin(x*math.pi*3)+0.11*math.sin(x*math.pi*5)+0.033*math.sin(x*math.pi*7)) * z end,
  organIsh = function(x, z) return (math.sin(x*math.pi)+(0.16*(math.sin(2*x*math.pi)+math.sin(3*x*math.pi)+math.sin(4*x*math.pi)))) * z end,
  sawAnalog = function(x, z) return (2.001 * (math.sin(x * 0.7905) - 0.5)) * z end,
  dome = function(x, z) return (2 * (math.sin(x * 1.5705) - 0.5)) * z end,
  brassy = function(x, z, i) return math.sin(math.pi*gem.sign(x)*(math.abs(x)^(((1-z)+0.1)*math.pi*math.pi))) end,
  taffy = function(x, z, i) return math.sin(x*math.pi*2)*math.cos(x*math.pi)*math.cos(z*math.pi*(math.abs((x*2)^3)-1)*math.pi) end,
  random = function(x, z) return ((gem.getRandom() * 2) - 1) * z end,
  punkSine = function(x, z) return math.sin(x*math.pi*(2+(62*z*z*z)))*math.sin(x*math.pi) end,
  softSine = function(x, z) return 0.5*(math.cos(x*math.pi/2)*((math.sin((x)*math.pi)+(1-z)*(math.sin(z*((x*x)^z)*math.pi*32))))) end,
  tripleSin = function(x, z) return math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x)) end,
  pwm50to100 = function(x, z, i) if x > z then return 1 end return -1 end,
  chaosToSine = function(x, z, i) return math.sin(math.pi*z*z*32*math.log(x+1)) end,
  sawSinReveal = function(x, z, i) if x + 1 > z * 2 then return x end return math.sin(x * math.pi) end,
  domeSmall = function(x, z) return (-1-1.275*math.sin(x*math.pi)) * z end,
  minMaxZero = function(x, z) return z end,
  oddAndEven = function(x, z, i) x = 1 if i % 2 == 0 then x = -1 end return x * z end,
  tangent = function(x, z) return math.tan(x * math.pi) * z end,
  lofiTriangle = function(x, z) return ((gem.round(16*math.abs(x))/8.0)-1) * z end,
  hpfSaw = function(x, z) return (x-(0.635*math.sin(x*math.pi))) * z end,
  squareTri = function(x, z) return (-1*(gem.sign(x)*0.5)+(math.abs(x)-0.5)) * z end,
  testShape = function(x, z, i)
    return x
  end
}

local function getDefaultShapeOptions()
  return {
    z = 1,
    stepRange = 2,
    phase = -1,
    factor = 1,
  }
end

local function getValueOrDefault(value, default)
  if type(value) == "number" then
    return value
  end
  return default
end

local function getShapeOptions(overrides)
  local defaultShapeOptions = getDefaultShapeOptions()
  if type(overrides) == "nil" then
    return defaultShapeOptions
  end
  return {
    stepRange = getValueOrDefault(overrides.stepRange, defaultShapeOptions.stepRange),
    phase = getValueOrDefault(overrides.phase, defaultShapeOptions.phase),
    factor = getValueOrDefault(overrides.factor, defaultShapeOptions.factor),
    z = getValueOrDefault(overrides.z, defaultShapeOptions.z),
  }
end

local function getShapeTemplate(options, shapeTemplate)
  if type(options) == "nil" and type(shapeTemplate) == "table" then
    options = shapeTemplate
  end
  return getShapeOptions(options)
end

local function getShapeNames(options, max)
  if type(max) ~= "number" then
    max = #shapeNames
  end

  local res = {}

  for _,r in ipairs(shapeNames) do
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

local function getShapeFunctions()
  return shapeFunctions
end

local function getShapeFunction(i)
  return shapeFunctions[i]
end

local function getShapeBounds(bounds, options)
  local shapeBounds = {}
  if type(bounds) == "nil" then
    bounds = {}
  end
  shapeBounds.min = getValueOrDefault(bounds.min, -1) -- x-azis max value
  shapeBounds.max = getValueOrDefault(bounds.max, 1) -- x-azis min value
  shapeBounds.length = getValueOrDefault(bounds.length, 128) -- y-axis steps
  shapeBounds.unipolar = shapeBounds.min == 0
  shapeBounds.changePerStep = gem.getChangePerStep(options.stepRange, shapeBounds.length)
  return shapeBounds
end

local function createShape(shapeBounds, options, shapeFunc, shapeTemplate)
  options = getShapeTemplate(options, shapeTemplate)
  shapeBounds = getShapeBounds(shapeBounds, options)
  if type(shapeFunc) == "string" then
    shapeFunc = shapes[shapeFunc]
  end
  local shape = {}
  --print("Create shape, stepRange, phase, factor", options.stepRange, options.phase, options.factor)
  --print("shapeBounds.min, shapeBounds.max, shapeBounds.length, shapeBounds.changePerStep", shapeBounds.min, shapeBounds.max, shapeBounds.length, shapeBounds.changePerStep)
  for i=1,shapeBounds.length do
    local x = options.factor * ((shapeBounds.changePerStep * (i-1)) + options.phase)
    local z = options.z
    local value = shapeFunc(x, z, i, shapeBounds.min, shapeBounds.max)
    if shapeBounds.unipolar then
      value = ((shapeBounds.max * value) + shapeBounds.max) / 2
    else
      value = shapeBounds.max * value
    end
    --print("step, value, x", i, value, x)
    table.insert(shape, math.max(shapeBounds.min, math.min(shapeBounds.max, value)))
    --table.insert(shape, value)
  end
  return shape, options
end

local function getShapeWidgets(width, showLabel, i)
  -- Widgets for controlling shape
  if type(width) == "nil" then
    width = 120
  end
  if type(i) == "nil" then
    i = ""
  end
  local shapeOptions = getShapeOptions()
  return {
    stepRange = widgets.numBox("Step Range", shapeOptions.stepRange, {
      name = "ShapeStepRange" .. i,
      tooltip = "Set step range for the shape. Mostly affects polarity of the shape.",
      width = width,
      showLabel = showLabel == true,
      min = 0,
      max = 4,
    }),
    factor = widgets.numBox("Shape Factor", shapeOptions.factor, {
      name = "ShapeFactor" .. i,
      tooltip = "Set the factor (multiplier) applied to the value of each step.",
      width = width,
      showLabel = showLabel == true,
      min = -8,
      max = 8,
    }),
    phase = widgets.numBox("Shape Phase", shapeOptions.phase, {
      name = "ShapePhase" .. i,
      tooltip = "Set the phase applied to the shape (move left/right).",
      width = width,
      showLabel = showLabel == true,
      min = -1,
      max = 1,
    }),
    z = widgets.numBox("Shape Morph", shapeOptions.z, {
      name = "ShapeMorph" .. i,
      tooltip = "Set the morph value. This value is mostly assigned to amplitude, but it depends on the shape.",
      width = width,
      showLabel = showLabel == true,
      min = -1,
      max = 1,
    })
  }
end

local shapes = {
  getWidgets = getShapeWidgets,
  getShapeNames = getShapeNames,
  getShapeFunctions = getShapeFunctions,
  getShapeFunction = getShapeFunction,
  getShapeOptions = getShapeOptions,
  squareTri = function(t,o) return createShape(t, o, 'squareTri') end,
  hpfSaw = function(t,o) return createShape(t, o, 'hpfSaw') end,
  softSine = function(t,o) return createShape(t, o, 'softSine') end,
  punkSine = function(t,o) return createShape(t, o, 'punkSine') end,
  lofiTriangle = function(t,o) return createShape(t, o, 'lofiTriangle') end,
  tangent = function(t,o) return createShape(t, o, 'tangent') end,
  even = function(t,o) return createShape(t, o, 'oddAndEven', {z = -1}) end,
  odd = function(t,o) return createShape(t, o, 'oddAndEven') end,
  min = function(t,o) return createShape(t, o, 'minMaxZero', {z = -1}) end,
  max = function(t,o) return createShape(t, o, 'minMaxZero') end,
  zero = function(t,o) return createShape(t, o, 'minMaxZero', {z = 0}) end,
  domeSmall = function(t,o) return createShape(t, o, 'domeSmall', {stepRange = 1}) end,
  sawSinReveal = function(t,o) return createShape(t, o, 'sawSinReveal', {phase = -1}) end,
  dome = function(t,o) return createShape(t, o, 'dome', {phase = 0}) end,
  sawAnalog = function(t,o) return createShape(t, o, 'sawAnalog', {phase = 0}) end,
  sawInPhase = function(t,o) return createShape(t, o, 'sawInPhase') end,
  organIsh = function(t,o) return createShape(t, o, 'organIsh') end,
  triangle = function(t,o) return createShape(t, o, 'triangleShaper') end,
  rampUp = function(t,o) return createShape(t, o, 'triangleShaper', {stepRange = 1, phase = 0.5}) end,
  rampDown = function(t,o) return createShape(t, o, 'triangleShaper', {stepRange = 1, phase = -0.5}) end,
  triangleOffPhase = function(t,o) return createShape(t, o, 'triangleShaper', {phase = -0.5}) end,
  sine = function(t,o) return createShape(t, o, 'sineShaper', {phase = -0.5, factor = math.pi}) end,
  chaosToSine = function(t,o) return createShape(t, o, 'chaosToSine') end,
  pwm50to100 = function(t,o) return createShape(t, o, 'pwm50to100') end,
  tripleSin = function(t,o) return createShape(t, o, 'tripleSin') end,
  tripleSinWindow = function(t,o) return createShape(t, o, 'tripleSin', {z = 0}) end,
  taffy = function(t,o) return createShape(t, o, 'taffy', {z = 0}) end,
  brassy = function(t,o) return createShape(t, o, 'brassy', {z = 0}) end,
  hpfSqrToSqr = function(t,o) return createShape(t, o, 'hpfSqrToSqr', {z = 0.01}) end,
  wacky = function(t,o) return createShape(t, o, 'wacky', {z = 0.84}) end,
  sinToNoise = function(t,o) return createShape(t, o, 'sinToNoise') end,
  filteredSquare = function(t,o) return createShape(t, o, 'filteredSquare') end,
  windowYSqr = function(t,o) return createShape(t, o, 'windowYSqr', {z = 0}) end,
  random = function(t,o) return createShape(t, o, 'random') end,
  testShape = function(t,o) return createShape(t, o, 'testShape') end,
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
local headerPanel = widgets.panel()
local footerPanel = widgets.panel()
local cyclePagesButton = footerPanel:OnOffButton("CyclePagesButton")
local changePageProbability = footerPanel:NumBox("ChangePageProbability", 0, 0, 100, true)
local defaultActions = {"Actions..."}

local actionMenu = footerPanel:Menu("ActionMenu", defaultActions)
actionMenu.enabled = false

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
  --print("setPageDuration for page", page)
  local pageResolutions = {}
  for part=1,numParts do
    local partIndex = getPartIndex(part, page)
    --print("getResolution for partIndex", partIndex)
    local partResolution = resolutions.getResolution(paramsPerPart[partIndex].stepResolution.value)
    if paramsPerPart[partIndex].stepButton.value then
      partResolution = partResolution * paramsPerPart[partIndex].numStepsBox.value
    end
    table.insert(pageResolutions, partResolution)
    --print("Added resolution/part/page", partResolution, part, page)
  end
  table.sort(pageResolutions)
  paramsPerPage[page].pageDuration = pageResolutions[#pageResolutions]
end

local function getShapeLoadOptions(partIndex, loadNew)
  if loadNew == true then
    return -- Load a new shape without adjustments
  end

  return {
    z = paramsPerPart[partIndex].shapeWidgets.z.value,
    stepRange = paramsPerPart[partIndex].shapeWidgets.stepRange.value,
    phase = paramsPerPart[partIndex].shapeWidgets.phase.value,
    factor = paramsPerPart[partIndex].shapeWidgets.factor.value,
  }
end

local function loadShape(partIndex, loadNew)
  local options = getShapeLoadOptions(partIndex, loadNew)
  local values = {}
  if paramsPerPart[partIndex].shapeMenu.value == 1 then
    -- If not shape was selected, we load the first
    paramsPerPart[partIndex].shapeMenu.value = 2
  end
  local shapeFunc = shapes.getShapeFunction(paramsPerPart[partIndex].shapeMenu.value - 1)
  values, options = shapes[shapeFunc](paramsPerPart[partIndex].seqValueTable, options)
  for i,v in ipairs(values) do
    paramsPerPart[partIndex].seqValueTable:setValue(i, v)
  end
  if loadNew == true then
    -- Update widgets with values from the shape
    local callChanged = true
    paramsPerPart[partIndex].shapeWidgets.stepRange:setValue(options.stepRange, callChanged)
    paramsPerPart[partIndex].shapeWidgets.phase:setValue(options.phase, callChanged)
    paramsPerPart[partIndex].shapeWidgets.factor:setValue(options.factor, callChanged)
    paramsPerPart[partIndex].shapeWidgets.z:setValue(options.z, callChanged)
  end
end

local function setNumSteps(partIndex, numSteps)
  --print("setNumSteps for partIndex/numSteps", partIndex, numSteps)
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
    --print("New round on page/duration/repeats/repeatCounter", activePage, paramsPerPage[activePage].pageDuration, repeats, repeatCounter)
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
    --print("Start playing", i)
    spawn(arpeg, i)
  end
  isPlaying = true
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  --print("Stop playing")
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
  actionMenu.enabled = #actionMenuItems > 1
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
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end
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
  loadShape = loadShape,
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
-- A sequencer sending midi control change values
--------------------------------------------------------------------------------

modseq.setTitle("Midi CC Sequencer")

setBackgroundColour(pageBackgoundColour)

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

-- Add params that are to be editable per page / part
for page=1,maxPages do
  local tableX = 0
  local tableY = 0
  local tableWidth = 700
  local tableHeight = 64
  local buttonRowHeight = 36
  local buttonSpacing = 10
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
  sequencerPanel.height = numParts * (tableHeight + buttonRowHeight)

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

    local seqValueTable = sequencerPanel:Table("ControlValue" .. i, defaultSteps, 0, 0, 127)
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
    
    local inputWidgetY = seqValueTable.y + seqValueTable.height + 5

    -- Inputs
    local partLabelInput = sequencerPanel:Label("Label")
    partLabelInput.text = "CC " .. (part+101)
    partLabelInput.editable = true
    partLabelInput.backgroundColour = pageBackgoundColour
    partLabelInput.textColour = "808080"
    partLabelInput.backgroundColourWhenEditing = "white"
    partLabelInput.textColourWhenEditing = "black"
    partLabelInput.fontSize = 16
    partLabelInput.width = 75
    partLabelInput.height = 20
    partLabelInput.x = 0
    partLabelInput.y = inputWidgetY

    local stepButton = sequencerPanel:OnOffButton("Step" .. i, false)
    stepButton.displayName = "Step"
    stepButton.tooltip = "The selected resolution applies to each step, not the whole round"
    stepButton.visible = isVisible
    stepButton.backgroundColourOff = "#ff084486"
    stepButton.backgroundColourOn = "#ff02ACFE"
    stepButton.textColourOff = "#ff22FFFF"
    stepButton.textColourOn = "#efFFFFFF"
    stepButton.size = {60,20}
    stepButton.x = partLabelInput.x + partLabelInput.width + buttonSpacing
    stepButton.y = inputWidgetY
    stepButton.changed = function(self)
      modseq.setPageDuration(page)
    end

    local stepResolution = sequencerPanel:Menu("StepResolution" .. i, resolutions.getResolutionNames())
    stepResolution.tooltip = "Set the step resolution"
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
    numStepsBox.size = {90,20}
    numStepsBox.x = stepResolution.x + stepResolution.width + buttonSpacing
    numStepsBox.y = inputWidgetY
    numStepsBox.changed = function(self)
      print("numStepsBox.changed index/value", i, self.value)
      modseq.setNumSteps(i, self.value)
    end

    local valueRandomization = sequencerPanel:NumBox("ValueRandomization" .. i, 0, 0, 100, true)
    valueRandomization.displayName = "Randomize"
    valueRandomization.tooltip = "Level of randomization applied to the control value"
    valueRandomization.unit = Unit.Percent
    valueRandomization.visible = isVisible
    valueRandomization.backgroundColour = menuBackgroundColour
    valueRandomization.textColour = menuTextColour
    valueRandomization.arrowColour = menuArrowColour
    valueRandomization.outlineColour = menuOutlineColour
    valueRandomization.size = {115,20}
    valueRandomization.x = numStepsBox.x + numStepsBox.width + buttonSpacing
    valueRandomization.y = inputWidgetY

    local midiControlNumber = sequencerPanel:NumBox("MidiControlNumber" .. i, (part+101), 0, 127, true)
    midiControlNumber.displayName = "CC"
    midiControlNumber.tooltip = "The midi control number to send the value to"
    midiControlNumber.visible = isVisible
    midiControlNumber.backgroundColour = menuBackgroundColour
    midiControlNumber.textColour = menuTextColour
    midiControlNumber.size = {90,20}
    midiControlNumber.x = valueRandomization.x + valueRandomization.width + buttonSpacing
    midiControlNumber.y = inputWidgetY

    local channelBox = sequencerPanel:NumBox("Channel" .. i, 0, 0, 16, true)
    channelBox.displayName = "Ch"
    channelBox.tooltip = "Midi channel that receives CC from this part. 0 = omni"
    channelBox.visible = isVisible
    channelBox.backgroundColour = menuBackgroundColour
    channelBox.textColour = menuTextColour
    channelBox.arrowColour = menuArrowColour
    channelBox.outlineColour = menuOutlineColour
    channelBox.size = {75,20}
    channelBox.x = midiControlNumber.x + midiControlNumber.width + buttonSpacing
    channelBox.y = inputWidgetY

    local smoothButton = sequencerPanel:OnOffButton("Smooth" .. i, false)
    smoothButton.displayName = "Smooth"
    smoothButton.tooltip = "Use smoothing (non destructive) to even out the transition between value changes"
    smoothButton.visible = isVisible
    smoothButton.backgroundColourOff = "#ff084486"
    smoothButton.backgroundColourOn = "#ff02ACFE"
    smoothButton.textColourOff = "#ff22FFFF"
    smoothButton.textColourOn = "#efFFFFFF"
    smoothButton.size = {60,20}
    smoothButton.x = channelBox.x + channelBox.width + buttonSpacing
    smoothButton.y = inputWidgetY

    table.insert(paramsPerPart, {stepButton=stepButton,smoothButton=smoothButton,valueRandomization=valueRandomization,midiControlNumber=midiControlNumber,seqValueTable=seqValueTable,channelBox=channelBox,positionTable=positionTable,stepResolution=stepResolution,numStepsBox=numStepsBox,partLabelInput=partLabelInput})

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

  table.insert(paramsPerPage, {sequencerPanel=sequencerPanel,minRepeats=minRepeats,pageDuration=4,active=(page==1)})
  modseq.setPageDuration(page)
end

modseq.footerPanel.y = paramsPerPage[1].sequencerPanel.y + paramsPerPage[1].sequencerPanel.height

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function sendControlChange(duration, startValue, targetValue, controlChangeNumber, channel)
  local durationInMs = beat2ms(duration)
  local numberOfIterations = math.max(startValue, targetValue) - math.min(startValue, targetValue)
  local durationPerIteration = math.ceil(durationInMs / numberOfIterations)
  local value = startValue
  local increment = 1
  if targetValue < startValue then
    increment = -1
  end
  print("numberOfIterations, durationPerIteration", numberOfIterations, durationPerIteration)
  local i = 0
  repeat
    value = value + increment -- Increment value
    i = i + 1 -- Increment counter
    controlChange(controlChangeNumber, gem.round(value), channel)
    --print("Over time controlChangeNumber, value, channel", controlChangeNumber, value, channel)
    wait(durationPerIteration)
  until value == targetValue or i >= numberOfIterations
  print("value == targetValue or i >= numberOfIterations", value, targetValue, i, numberOfIterations)
end

function getNextValue(seqValueTable, currentPosition, numStepsInPart)
  local nextPosition = currentPosition + 1
  if nextPosition > numStepsInPart then
    nextPosition = 1
  end
  return seqValueTable:getValue(nextPosition)
end

function arpeg(part)
  local index = 0
  local startValue = nil
  local targetValue = nil
  while isPlaying do
    local partIndex = modseq.getPartIndex(part)
    local numStepsInPart = paramsPerPart[partIndex].numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local smooth = paramsPerPart[partIndex].smoothButton.value
    local step = paramsPerPart[partIndex].stepButton.value
    local duration = resolutions.getResolution(paramsPerPart[partIndex].stepResolution.value)
    local seqValueTable = paramsPerPart[partIndex].seqValueTable
    local controlChangeNumber = paramsPerPart[partIndex].midiControlNumber.value
    local channel = paramsPerPart[partIndex].channelBox.value
    local valueRandomizationAmount = paramsPerPart[partIndex].valueRandomization.value

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

    -- Send cc
    if type(startValue) == "nil" then
      startValue = seqValueTable:getValue(currentPosition)
      startValue = gem.randomizeValue(startValue, seqValueTable.min, seqValueTable.max, valueRandomizationAmount)
    end
    targetValue = getNextValue(seqValueTable, currentPosition, numStepsInPart) -- Get next value
    targetValue = gem.randomizeValue(targetValue, seqValueTable.min, seqValueTable.max, valueRandomizationAmount)
    if channel == 0 then
      channel = nil -- Send on all channels
    end
    if smooth == false then
      controlChange(controlChangeNumber, gem.round(startValue), channel)
      --print("Send controlChangeNumber, startValue, channel", controlChangeNumber, startValue, channel)
    else
      -- Send cc over time
      spawn(sendControlChange, duration, startValue, targetValue, controlChangeNumber, channel)
    end
    startValue = targetValue

    -- Increment position
    index = (index + 1) % numStepsInPart

    -- Wait for next beat
    waitBeat(duration)
  end
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function onNote(e)
  if modseq.autoplayButton.value == true then
    postEvent(e)
  else
    modseq.playButton:setValue(true)
  end
end

function onRelease(e)
  if modseq.autoplayButton.value == true then
    postEvent(e)
  else
    modseq.playButton:setValue(false)
  end
end

function onTransport(start)
  if modseq.autoplayButton.value == true then
    modseq.playButton:setValue(start)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local numStepsData = {}
  local seqValueTableData = {}
  local partLabelInputData = {}

  for _,v in ipairs(paramsPerPart) do
    table.insert(numStepsData, v.numStepsBox.value)
    table.insert(partLabelInputData, v.partLabelInput.text)
    for j=1, v.numStepsBox.value do
      table.insert(seqValueTableData, v.seqValueTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, numStepsData)
  table.insert(data, seqValueTableData)
  table.insert(data, partLabelInputData)
  table.insert(data, modseq.labelInput.text)

  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqValueTableData = data[2]
  local partLabelInputData = data[3]
  modseq.labelInput.text = data[4]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].partLabelInput.text = partLabelInputData[i]
    paramsPerPart[i].seqValueTable.length = v
    for j=1, v do
      paramsPerPart[i].seqValueTable:setValue(j, seqValueTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
  for page=1,numPages do
    modseq.setPageDuration(page)
  end
end
