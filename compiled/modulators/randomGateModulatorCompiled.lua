-- modulators/randomGateModulator -- 
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

local function inc(val, inc, max, reset)
  if type(inc) ~= "number" then
    inc = 1
  end
  if type(reset) ~= "number" then
    reset = 1
  end
  val = val + inc
  if type(max) == "number" and val > max then
    val = reset
  end
  return val
end

local gem = {
  inc = inc,
  round = round,
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

local resolutions = {
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
-- Methods for subdivisions
--------------------------------------------------------------------------------




local function createSubdivisions(subdivisionButtons, mainBeatDuration, minResolution, steps)
  local subdivisions = {}
  for i=1,#subdivisionButtons do
    if subdivisionButtons[i].value == true then
      table.insert(subdivisions, i)
      print("Added subdivision", i)
    end
  end
  -- Add subdivisions from the active bases
  local numSubdivisions = #subdivisions
  for i=1,numSubdivisions do
    subdivision = subdivisions[i]
    local duration = mainBeatDuration
    while duration > minResolution do
      subdivision = subdivision * 2
      duration = (mainBeatDuration / subdivision) * steps
      print("Found subdivision/duration/minResolution", subdivision, duration, minResolution)
      if duration >= minResolution and gem.tableIncludes(subdivisions, subdivision) == false then
        table.insert(subdivisions, subdivision)
        print("Added subdivision", subdivision)
      end
    end
  end
  table.sort(subdivisions)
  return subdivisions
end

local function setNotesOnNodes(nodes, repeatProbability, generateNote)
  for i,node in ipairs(nodes) do
    -- This is where we add the notes to the node
    if i > 1 and gem.getRandomBoolean(repeatProbability) then
      node.note = nodes[1].note -- Repeat first note
      print("Note repeated", node.note)
    else
      node.note = generateNote(i)
      print("Note generated", node.note)
    end
  end
  return nodes
end

-- Get the subdivision to use for building the struncture
local function getSubdivision(stepDuration, steps, minResolution, subdivisionProbability, subdivisionButtons, stop, subdivisionDotProbability)
  -- Calculate depth decay
  -- TODO If decay, there should be a setting for it...
  --[[ if currentDepth > 1 then
    subdivisionProbability = math.ceil(subdivisionProbability / (currentDepth / 2)) -- TODO Adjust
    print("subdivisionProbability/currentDepth", subdivisionProbability, currentDepth)
  end ]]
  local subdivision = 1 -- Set default

  -- TODO Add a base-1 thresold resolution that tells what is the slowest resolution where subdivision can be 1 - until then, keep on subdividing

  -- Check what subdivisions can be used with the given duration
  local subdivisions = createSubdivisions(subdivisionButtons, stepDuration, minResolution, steps)
  print("Got #subdivisions/subdivisionProbability", #subdivisions, subdivisionProbability)
  if #subdivisions > 0 then
    local minSubdivision = subdivisions[1]
    local maxSubdivision = subdivisions[#subdivisions]
    if minSubdivision == 2 then
      subdivision = maxSubdivision -- Max is selected
    else
      subdivision = minSubdivision -- Min is selected
    end
    if #subdivisions > 1 and gem.getRandomBoolean(subdivisionProbability) then
      local i = 1
      while i < maxSubdivision do
        subdivision = subdivisions[gem.getRandom(#subdivisions)]
        print("SET RANDOM subdivision/round", subdivision, i)
        if subdivision > 1 then
          break
        end
        i = i + 1
      end
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
    dotted = subdivision % 4 == 0 and gem.getRandomBoolean(subdivisionDotProbability)
    print("Dotted is dotted/subdivision/subdivisionDotProbability", dotted, subdivision, subdivisionDotProbability)
    if dotted == true then
      stop = true -- TODO Param?
      subDivDuration = resolutions.getDotted(subDivDuration)
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

local function getSubdivisionSteps(subdivision, subDivPos, subdivisionTieProbability)
  local stop = false
  local subdivisionSteps = 1 -- Default
  local maxSteps = (subdivision - subDivPos) + 1
  if maxSteps == subdivision then
    maxSteps = maxSteps - 1 -- Avoid it lasting the whole subdivision
  end
  if maxSteps > 1 and gem.getRandomBoolean(subdivisionTieProbability) then
    subdivisionSteps = gem.getRandom(maxSteps)
    if subdivisionSteps > 1 then
      stop = subdivisionSteps % 2 > 0 -- Stop subdividing if not an even number -- TODO Param?
      print("subdivisionSteps % 2", (subdivisionSteps % 2))
    end
    print("Set subdivisionSteps by random subdivisionSteps/maxSteps/stop", subdivisionSteps, maxSteps, stop)
  end
  return subdivisionSteps, stop
end

local subdivision = {
  setNotesOnNodes = setNotesOnNodes,
  getSubdivisionSteps = getSubdivisionSteps,
  getSubdivision = getSubdivision,
}

-------------------------------------------------------------------------------
-- A script modulator for gating with min/max durations for on and off state --
-------------------------------------------------------------------------------





local isRunning = false

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "15133C" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local knobFillColour = "E6D5B8" -- Light

setBackgroundColour(backgroundColour)

local panel = Panel("Gate")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 60

local label = panel:Label("Label")
label.text = "Timed Gate"
label.tooltip = "A script modulator for gating with min/max durations for on and off state"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 110

local probability = panel:Knob("Probability", 50, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Set the probability that the gate will open or close"
probability.backgroundColour = widgetBackgroundColour
probability.fillColour = knobFillColour
probability.outlineColour = labelBackgoundColour
probability.x = label.x + label.width + 30
probability.width = 120

local waitResolution = panel:Menu("WaitResolution", resolutions.getResolutionNames())
waitResolution.displayName = "Max Duration"
waitResolution.tooltip = "The maximum duration of the gate"
waitResolution.selected = 11
waitResolution.width = 120
waitResolution.x = probability.x + probability.width + 10
waitResolution.backgroundColour = menuBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour

local waitResolutionMin = panel:Menu("WaitResolutionMin", resolutions.getResolutionNames())
waitResolutionMin.displayName = "Min Duration"
waitResolutionMin.tooltip = "The minimum duration of the gate"
waitResolutionMin.selected = 17
waitResolutionMin.width = 120
waitResolutionMin.x = waitResolution.x + waitResolution.width + 10
waitResolutionMin.backgroundColour = menuBackgroundColour
waitResolutionMin.textColour = widgetTextColour
waitResolutionMin.arrowColour = menuArrowColour
waitResolutionMin.outlineColour = menuOutlineColour

local sourceIndex = panel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.backgroundColour = widgetBackgroundColour
sourceIndex.textColour = widgetTextColour
sourceIndex.displayName = "Event Id"
sourceIndex.size = {90,20}

local gateButton = panel:OnOffButton("GateButton", true)
gateButton.displayName = "On"
gateButton.persistent = false
gateButton.tooltip = "Shows the current state of the gate"
gateButton.backgroundColourOn = "green"
gateButton.backgroundColourOff = "303030"
gateButton.textColourOn = "white"
gateButton.textColourOff = "gray"
gateButton.size = {90,20}
gateButton.x = sourceIndex.x
gateButton.y = sourceIndex.y + sourceIndex.height + 5
gateButton.changed = function(self)
  if self.value == true then
    gateButton.displayName = "On"
    sendScriptModulation(sourceIndex.value, 1)
  else
    gateButton.displayName = "Off"
    sendScriptModulation(sourceIndex.value, 0)
  end
end

function getDuration()
  local minResolution = resolutions.getResolution(waitResolutionMin.value)
  local resolution = resolutions.getResolution(waitResolution.value)
  local subdivisions = {{value=true}}
  local subDivProbability = 100
  local subDiv, subDivDuration, remainderDuration, stop = subdivision.getSubdivision(resolution, 1, minResolution, subDivProbability, subdivisions, false, 0)
  return subDivDuration
end

function arpeg()
  local round = 0
  while isRunning do
    local waitTime = beat2ms(getDuration()) -- Set round duration
    round = round + 1 -- Increment round
    if gem.getRandomBoolean(probability.value) then
      gateButton:setValue(gateButton.value == false) -- Toggle gate
    end
    if round == 1 then
      waitTime = waitTime - 50
    end
    wait(waitTime)
  end
end

function onNote(e)
  local voiceId = postEvent(e)
  if isRunning == false then
    isRunning = true
    arpeg()
  end
end

function onRelease(e)
  local voiceId = postEvent(e)
  isRunning = false
end

function onTransport(start)
  isRunning = start
  if isRunning then
    arpeg()
  elseif probability.value > 0 then
    gateButton:setValue(true)
  end
end