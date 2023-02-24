-- modulators/randomEnveloper -- 
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

local function shape(minValue, maxValue, numSteps, shapeFunc)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(1, numSteps)
  local shape = {}
  for i=1,numSteps do
    local value = math[shapeFunc](2 * math.pi * changePerStep * (i-1))
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

local function triangle(minValue, maxValue, numSteps)
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

local function rampUp(minValue, maxValue, numSteps)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numSteps)
  local startValue = minValue
  local shape = {}
  for i=1,numSteps do
    table.insert(shape, startValue)
    startValue = inc(startValue, changePerStep)
  end
  shape[#shape] = maxValue
  return shape
end

local function rampDown(minValue, maxValue, numSteps)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numSteps)
  local startValue = maxValue
  local shape = {}
  for i=1,numSteps do
    table.insert(shape, startValue)
    startValue = inc(startValue, -changePerStep)
  end
  shape[#shape] = minValue
  return shape
end

local gem = {
  inc = inc,
  round = round,
  shape = shape,
  rampUp = rampUp,
  rampDown = rampDown,
  triangle = triangle,
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
-- Common Generative Functions
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Resolution Parameters
--------------------------------------------------------------------------------

local divOpt = {}
for i=1,128 do
  table.insert(divOpt, "/ " .. i)
end

local globalResolution = nil -- Holds the global resolution for all voices
local resolutionInputs = {}
local toggleResolutionInputs = {}
local resolutionProbabilityInputs = {}
local minRepeats = {}
local divisions = {}

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function adjustForDuration(decay, currentDuration)
  -- TODO Param for adjusting decay
  -- TODO Increase decay for longer durations - less repetition of longer notes
  local middleIndex = 17 -- 1/4 (1 beat) -- TODO Param?
  local middleResolution = resolutions.getResolution(middleIndex)
  local increase = 0
  if currentDuration > middleResolution and gem.tableIncludes(resolutions.getResolutions(), currentDuration) then
    -- Note is longer than 1/4 - increase decay
    local resolutionIndex = gem.getIndexFromValue(currentDuration, resolutions.getResolutions())
    local percentIncrease = (middleIndex * resolutionIndex) / 100
    local factor = decay / percentIncrease
    increase = decay * (factor / 100)
    print("Decay adjusted decay, increase", decay, increase)
  end
  return math.min(100, (decay + increase)) / 100
end

local function getNoteDuration(currentDuration, repeatCounter, durationRepeatProbability, durationRepeatDecay, useGlobalProbability)
  --print("repeatCounter", repeatCounter)
  repeatCounter = repeatCounter - 1
  -- Repeat the current duration until repeat counter reaches zero
  if repeatCounter > 0 then
    --print("Repeating duration", repeatCounter, currentDuration)
    return currentDuration, repeatCounter, durationRepeatProbability
  end

  -- Find available resolutions
  local availableResolutions = {}
  local selectedDivisionsAndRepeats = {}
  for i,v in ipairs(resolutionInputs) do
    local resolutionActive = toggleResolutionInputs[i].value
    if resolutionActive and gem.getRandomBoolean(resolutionProbabilityInputs[i].value) then
      table.insert(availableResolutions, v.value)
      table.insert(selectedDivisionsAndRepeats, {division=divisions[i].value,repeats=minRepeats[i].value})
    end
  end

  --print("#availableResolutions", #availableResolutions)

  -- Check if we should use the global resolution
  if type(globalResolution) == "number" and type(useGlobalProbability) == "number" and gem.getRandomBoolean(useGlobalProbability) then
    currentDuration = globalResolution
    --print("Set currentDuration from globalResolution", currentDuration)
  end

  -- Failsafe in case no resolutions are selected
  if #availableResolutions == 0 then
    if type(globalResolution) == "number" then
      return globalResolution, 1, durationRepeatProbability
    else
      return resolutions.getResolution(17), 1, durationRepeatProbability
    end
  end

  local resolutionIndex = nil
  if gem.tableIncludes(resolutions.getResolutions(), currentDuration) then
    resolutionIndex = gem.getIndexFromValue(currentDuration, resolutions.getResolutions())
  end

  -- Check resolution repeat by probability
  if type(currentDuration) == "number" then
    local durationRepeatProbabilityDecay = durationRepeatProbability * adjustForDuration(durationRepeatDecay, currentDuration)
    durationRepeatProbability = durationRepeatProbability - durationRepeatProbabilityDecay
    -- Repeat only if current resolution is still available
    if gem.tableIncludes(availableResolutions, resolutionIndex) and gem.getRandomBoolean(durationRepeatProbability) then
      --print("Repeating current duration", currentDuration)
      return currentDuration, 1, durationRepeatProbability
    end
  end

  -- Remove last known resolution if repeat was not selected
  if type(resolutionIndex) == "number" and type(currentDuration) == "number" and #availableResolutions > 1 then
    local removeIndex = gem.getIndexFromValue(resolutionIndex, availableResolutions)
    table.remove(availableResolutions, removeIndex)
    table.remove(selectedDivisionsAndRepeats, removeIndex)
    --print("Remove current duration to avoid repeat", removeIndex)
  end

  local index = 1
  if #availableResolutions > 1 then
    index = gem.getRandom(#availableResolutions)
    --print("Index selected by random", index)
  end

  -- Get resolution and divide by the selected division - not lower than system min res (1/128)
  globalResolution = resolutions.getPlayDuration(resolutions.getResolution(availableResolutions[index]) / selectedDivisionsAndRepeats[index].division)

  return globalResolution, selectedDivisionsAndRepeats[index].repeats, nil
end

local function createResolutionSelector(resolutionPanel, colours, numResolutions)
  if type(numResolutions) == "nil" then
    numResolutions = 12
  end
  local offset = 5
  local perRow = 3
  local columnCount = 0
  local rowCount = 1
  for i=1,numResolutions do
    local toggleResolution = resolutionPanel:OnOffButton("ToggleResolution" .. i, (i == 1))
    toggleResolution.backgroundColourOff = "#ff084486"
    toggleResolution.backgroundColourOn = "#ff02ACFE"
    toggleResolution.textColourOff = "#ff22FFFF"
    toggleResolution.textColourOn = "#efFFFFFF"
    toggleResolution.displayName = " "
    toggleResolution.tooltip = "Toggle resolution on/off"
    toggleResolution.size = {23,20}
    toggleResolution.x = (columnCount * 232) + 5
    toggleResolution.y = ((toggleResolution.height + 5) * rowCount) + 5

    local resolution = resolutionPanel:Menu("Resolution" .. i, resolutions.getResolutionNames())
    if i == 1 then
      resolution.selected = 20
    elseif i == 2 then
      resolution.selected = 23
    elseif i == 6 then
      resolution.selected = 22
    elseif i == 7 then
      resolution.selected = 18
    elseif i > 9 then
      resolution.selected = i - 3
    else
      resolution.selected = offset
    end
    offset = offset + 3
    resolution.showLabel = false
    resolution.backgroundColour = colours.widgetBackgroundColour
    resolution.textColour = colours.widgetTextColour
    resolution.arrowColour = colours.menuArrowColour
    resolution.outlineColour = colours.menuOutlineColour
    resolution.tooltip = "Select resolution"
    resolution.size = {70,20}
    resolution.x = toggleResolution.x + toggleResolution.width + 1
    resolution.y = toggleResolution.y

    local resolutionProbability = resolutionPanel:NumBox("ResolutionProbability" .. i, 100, 0, 100, true)
    resolutionProbability.unit = Unit.Percent
    resolutionProbability.textColour = colours.widgetTextColour
    resolutionProbability.backgroundColour = colours.widgetBackgroundColour
    resolutionProbability.showLabel = false
    resolutionProbability.tooltip = "Probability of resolution being used"
    resolutionProbability.size = {42,20}
    resolutionProbability.x = resolution.x + resolution.width + 1
    resolutionProbability.y = resolution.y

    local minRepeatValue = 1
    if i == 6 then
      minRepeatValue = 3
    end
    local minRepeat = resolutionPanel:NumBox("MinRepeat" .. i, minRepeatValue, 1, 128, true)
    minRepeat.textColour = colours.widgetTextColour
    minRepeat.backgroundColour = colours.widgetBackgroundColour
    minRepeat.showLabel = false
    minRepeat.tooltip = "Set the minimum number of repeats for this resolution"
    minRepeat.size = {36,20}
    minRepeat.x = resolutionProbability.x + resolutionProbability.width + 1
    minRepeat.y = resolutionProbability.y

    local division = resolutionPanel:Menu("Division" .. i, divOpt)
    division.showLabel = false
    division.backgroundColour = colours.widgetBackgroundColour
    division.textColour = colours.widgetTextColour
    division.arrowColour = colours.menuArrowColour
    division.outlineColour = colours.menuOutlineColour
    division.tooltip = "Set a division for this resolution"
    division.size = {45,20}
    division.x = minRepeat.x + minRepeat.width + 1
    division.y = minRepeat.y

    table.insert(toggleResolutionInputs, toggleResolution)
    table.insert(resolutionInputs, resolution)
    table.insert(resolutionProbabilityInputs, resolutionProbability)
    table.insert(minRepeats, minRepeat)
    table.insert(divisions, division)

    columnCount = columnCount + 1
    if i % perRow == 0 then
      rowCount = rowCount + 1
      columnCount = 0
    end
  end
  return rowCount
end

local resolutionSelector = {
  resolutionInputs = resolutionInputs,
  toggleResolutionInputs = toggleResolutionInputs,
  getNoteDuration = getNoteDuration,
  createResolutionSelector = createResolutionSelector,
}

-----------------------------------------------------------------------
-- A script modulator that creates random multi-envelopes over time.
-----------------------------------------------------------------------

local heldNotes = {}
local backgroundColour = "303030" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "FF9551" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local secondRowY = 40
local widgetWidth = 129

local colours = {
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = labelTextColour,
  menuArrowColour = menuArrowColour,
  menuOutlineColour = menuOutlineColour,
  backgroundColour = backgroundColour
}

setBackgroundColour(backgroundColour)

local panel = Panel("Toggle")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 66

local label = panel:Label("Label")
label.text = "Timed Enveloper"
label.tooltip = "A script modulator that creates multi-envelopes over time"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 150
label.x = 0
label.y = 0

local sourceIndex = panel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.backgroundColour = widgetBackgroundColour
sourceIndex.textColour = widgetTextColour
sourceIndex.displayName = "Event Id"
sourceIndex.width = 100
sourceIndex.x = label.x + label.width + 10
sourceIndex.y = 0

local legato = panel:OnOffButton("Legato", false)
legato.displayName = "Legato"
legato.backgroundColourOff = "#ff084486"
legato.backgroundColourOn = "#ff02ACFE"
legato.textColourOff = "#ff22FFFF"
legato.textColourOn = "#efFFFFFF"
legato.fillColour = "#dd000061"
legato.width = 60
legato.x = panel.width - legato.width - 10
legato.y = 0

local loop = panel:OnOffButton("Loop", true)
loop.displayName = "Loop"
loop.backgroundColourOff = "#ff084486"
loop.backgroundColourOn = "#ff02ACFE"
loop.textColourOff = "#ff22FFFF"
loop.textColourOn = "#efFFFFFF"
loop.fillColour = "#dd000061"
loop.width = legato.width
loop.x = legato.x - legato.width - 10
loop.y = 0

local maxSteps = panel:NumBox("MaxSteps", 1, 1, 8, true)
maxSteps.displayName = "Max Steps"
maxSteps.tooltip = "Set the maximum number of steps that can be tied"
maxSteps.textColour = widgetTextColour
maxSteps.backgroundColour = widgetBackgroundColour
maxSteps.width = widgetWidth
maxSteps.x = 5
maxSteps.y = secondRowY

local minLevel = panel:NumBox("MinLevel", 50, 0, 100, true)
minLevel.unit = Unit.Percent
minLevel.displayName = "Spike Level"
minLevel.tooltip = "Set the minimum level for spikes"
minLevel.textColour = widgetTextColour
minLevel.backgroundColour = widgetBackgroundColour
minLevel.x = maxSteps.x + maxSteps.width + 10
minLevel.y = secondRowY
minLevel.width = widgetWidth

local attack = panel:NumBox("Attack", 0, 0, 100, true)
attack.unit = Unit.Percent
attack.displayName = "Attack"
attack.tooltip = "Set attack as percentage of duration - 0 = random variation"
attack.textColour = widgetTextColour
attack.backgroundColour = widgetBackgroundColour
attack.x = minLevel.x + minLevel.width + 10
attack.y = secondRowY
attack.width = widgetWidth

local decay = panel:NumBox("Decay", 0, 0, 100, true)
decay.unit = Unit.Percent
decay.displayName = "Decay"
decay.tooltip = "Set decay as percentage of rest duration - 0 = random variation"
decay.textColour = widgetTextColour
decay.backgroundColour = widgetBackgroundColour
decay.x = attack.x + attack.width + 10
decay.y = secondRowY
decay.width = widgetWidth

local bipolar = panel:NumBox("Bipolar", 0, 0, 100, true)
bipolar.unit = Unit.Percent
bipolar.displayName = "Bipolar"
bipolar.tooltip = "Set the probability that the returned value will be negative"
bipolar.textColour = widgetTextColour
bipolar.backgroundColour = widgetBackgroundColour
bipolar.x = decay.x + decay.width + 10
bipolar.y = secondRowY
bipolar.width = widgetWidth

--------------------------------------------------------------------------------
-- Resolution Panel
--------------------------------------------------------------------------------

local resolutionPanel = Panel("Resolutions")
resolutionPanel.backgroundColour = "404040"
resolutionPanel.x = panel.x
resolutionPanel.y = panel.y + panel.height + 5
resolutionPanel.width = 700
resolutionPanel.height = 135

local resLabel = resolutionPanel:Label("ResolutionsLabel")
resLabel.text = "Resolutions"
resLabel.tooltip = "Set probability for each resolution to be selected"
resLabel.alpha = 0.75
resLabel.fontSize = 15
resLabel.width = 350
resLabel.x = 5
resLabel.y = 5

local clearResolutions = resolutionPanel:Button("ClearResolutions")
clearResolutions.displayName = "All off"
clearResolutions.tooltip = "Deactivate all resolutions"
clearResolutions.persistent = false
clearResolutions.height = resLabel.height
clearResolutions.width = 90
clearResolutions.x = resolutionPanel.width - (clearResolutions.width * 3) - 30
clearResolutions.y = resLabel.y
clearResolutions.changed = function()
  for i,v in ipairs(resolutionSelector.resolutionInputs) do
    resolutionSelector.toggleResolutionInputs[i]:setValue(false)
  end
end

local addResolutions = resolutionPanel:Button("AddResolutions")
addResolutions.displayName = "All on"
addResolutions.tooltip = "Activate all resolutions"
addResolutions.persistent = false
addResolutions.height = clearResolutions.height
addResolutions.width = 90
addResolutions.x = clearResolutions.x + clearResolutions.width + 10
addResolutions.y = resLabel.y
addResolutions.changed = function()
  for i,v in ipairs(resolutionSelector.resolutionInputs) do
    resolutionSelector.toggleResolutionInputs[i]:setValue(true)
  end
end

local randomizeResolutions = resolutionPanel:Button("RandomizeResolutions")
randomizeResolutions.displayName = "Randomize"
randomizeResolutions.tooltip = "Randomize selected resolutions"
randomizeResolutions.persistent = false
randomizeResolutions.height = clearResolutions.height
randomizeResolutions.width = 90
randomizeResolutions.x = addResolutions.x + addResolutions.width + 10
randomizeResolutions.y = resLabel.y
randomizeResolutions.changed = function()
  for i,v in ipairs(resolutionSelector.resolutionInputs) do
    resolutionSelector.toggleResolutionInputs[i]:setValue(gem.getRandomBoolean())
  end
end

local rowCount = resolutionSelector.createResolutionSelector(resolutionPanel, colours, 9)

local resLabel = resolutionPanel:Label("ResolutionsLabel")
resLabel.text = "Base Resolution"
resLabel.alpha = 0.5
resLabel.fontSize = 15
resLabel.width = 106
resLabel.x = 5
resLabel.y = (25 * rowCount) + 5

local baseResolution = resolutionPanel:Menu("BaseResolution", resolutions.getResolutionNames())
baseResolution.displayName = resLabel.text
baseResolution.tooltip = "The duration between resets"
baseResolution.selected = 11
baseResolution.showLabel = false
baseResolution.height = 20
baseResolution.width = 106
baseResolution.backgroundColour = widgetBackgroundColour
baseResolution.textColour = widgetTextColour
baseResolution.arrowColour = menuArrowColour
baseResolution.outlineColour = menuOutlineColour
baseResolution.x = resLabel.x + resLabel.width + 10
baseResolution.y = resLabel.y

local durationRepeatProbabilityInput = resolutionPanel:NumBox("DurationRepeatProbability", 100, 0, 100, true)
durationRepeatProbabilityInput.unit = Unit.Percent
durationRepeatProbabilityInput.textColour = widgetTextColour
durationRepeatProbabilityInput.backgroundColour = widgetBackgroundColour
durationRepeatProbabilityInput.displayName = "Repeat Probability"
durationRepeatProbabilityInput.tooltip = "The probability that a resolution will be repeated"
durationRepeatProbabilityInput.size = {222,20}
durationRepeatProbabilityInput.x = baseResolution.x + baseResolution.width + 10
durationRepeatProbabilityInput.y = baseResolution.y

local durationRepeatDecay = resolutionPanel:NumBox("DurationRepeatDecay", 1, 25., 100)
durationRepeatDecay.unit = Unit.Percent
durationRepeatDecay.textColour = widgetTextColour
durationRepeatDecay.backgroundColour = widgetBackgroundColour
durationRepeatDecay.displayName = "Probability Decay"
durationRepeatDecay.tooltip = "The reduction in repeat probability for each iteration of the playing voice"
durationRepeatDecay.size = durationRepeatProbabilityInput.size
durationRepeatDecay.x = durationRepeatProbabilityInput.x + durationRepeatProbabilityInput.width + 10
durationRepeatDecay.y = durationRepeatProbabilityInput.y

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function hasVoiceId(voiceId)
  for _,v in ipairs(heldNotes) do
    if v == voiceId then
      return true
    end
  end
  return false
end

-- https://www.uvi.net/uviscript/class_mapper.html
-- Linear: param = min + (max-min)*pos 
-- Exponential: param = min * (max/min)^pos
-- Exponential: return 10 * (controllerValue/max)^4 (controllerValueToWidgetValue)
-- TweakSynth line 808
function modulateExponential(modulationTime, startValue, endValue, voiceId)
  local millisecondsPerStep = 20
  print("Duration of modulation (ms):", modulationTime)
  print("Change from/to:", startValue, endValue)
  if modulationTime <= (millisecondsPerStep*9) then
    print("Short duration, modulate linear:")
    modulateLinear(modulationTime, startValue, endValue, voiceId)
    return
  end

  local diff = math.max(endValue, startValue) - math.min(endValue, startValue)

  local parts = {
    {duration=0.5,startValue=startValue,endValue=diff*0.2},
    {duration=0.3,startValue=diff*0.2,endValue=diff*0.2+diff*0.3},
    {duration=0.3,startValue=diff*0.2+diff*0.3,endValue=endValue},
  }

  for i,v in ipairs(parts) do
    local remainingTime = modulationTime * v.duration
    local diff = math.max(v.endValue, v.startValue) - math.min(v.endValue, v.startValue)
    local numberOfSteps = remainingTime / millisecondsPerStep
    local changePerStep = diff / numberOfSteps
    print("i, diff, numberOfSteps, changePerStep", i, diff, numberOfSteps, changePerStep)
  
    local currentValue = v.startValue
    if v.startValue < v.endValue then
      while remainingTime > 0 do
        print("currentValue, endValue", currentValue, v.endValue)
        local change = changePerStep
        nextValue = math.min((currentValue + change), v.endValue)
        modulateLinear(millisecondsPerStep, currentValue, nextValue, voiceId)
        wait(millisecondsPerStep)
        currentValue = nextValue -- Increment current value
        if remainingTime - millisecondsPerStep <= 0 then
          modulateLinear(remainingTime, currentValue, v.endValue, voiceId)
        end
        remainingTime = remainingTime - millisecondsPerStep
      end
    else
      modulateLinear(modulationTime, v.startValue, v.endValue, voiceId)
    end
  end
end

function modulateLinear(modulationTime, startValue, endValue, voiceId)
  print("sendScriptModulation2 startValue, endValue, modulationTime", startValue, endValue, modulationTime)
  sendScriptModulation2(sourceIndex.value, startValue, endValue, modulationTime, voiceId)
end

function attackDecay(targetVal, stepDuration, voiceId)
  -- FIND ATTACK TIME
  local attackValue = attack.value
  if attackValue == 0 then
    attackValue = gem.getRandom(3,50) -- TODO Parameter for this?
  end
  local attackTime = stepDuration * (attackValue / 100)
  if true then --gem.getRandomBoolean() then
    -- LINEAR
    modulateLinear(attackTime, 0, targetVal, voiceId)
  else
    -- EXPONENTIAL
    spawn(modulateExponential, attackTime, 0, targetVal, voiceId)
  end
  wait(attackTime)
  local restDuration = stepDuration - attackTime
  if restDuration > 1 then
    -- FIND DECAY TIME
    local decayValue = decay.value
    if decayValue == 0 then
      decayValue = gem.getRandom(30,100) -- TODO Parameter for this?
    end
    local decayTime = restDuration * (decayValue / 100)
    modulateLinear(decayTime, targetVal, 0, voiceId)
  end
  wait(restDuration)
  if loop.value == false then
    if type(voiceId) == "nil" then
      heldNotes = {}
    else
      remove(voiceId)
    end
  end
end

function doModulation(waitDuration, durationRepeatProbability, repeatCounter, voiceId)
  local steps = 1
  if maxSteps.value > 1 then
    steps = gem.getRandom(maxSteps.value)
  end
  waitDuration, repeatCounter, durationRepeatProbability = resolutionSelector.getNoteDuration(waitDuration, repeatCounter, durationRepeatProbability, durationRepeatDecay.value)
  if durationRepeatProbability == nil then
    durationRepeatProbability = durationRepeatProbabilityInput.value
  end
  local val = 1 -- Spike level
  if minLevel.value < 100 then
    val = gem.getRandom(math.max(1, minLevel.value), 100) / 100
  end
  if gem.getRandomBoolean(bipolar.value) then
    val = -val
  end
  -- Do the attack/decay phase
  attackDecay(val, beat2ms(waitDuration * steps), voiceId)
  return waitDuration, durationRepeatProbability, repeatCounter
end

function modulateVoice(voiceId)
  local waitDuration = nil
  local durationRepeatProbability = durationRepeatProbabilityInput.value
  local repeatCounter = 1
  while hasVoiceId(voiceId) do
    waitDuration, durationRepeatProbability, repeatCounter = doModulation(waitDuration, durationRepeatProbability, repeatCounter, voiceId)
  end
end

function modulateBroadcast()
  local waitDuration = nil
  local durationRepeatProbability = durationRepeatProbabilityInput.value
  local repeatCounter = 1
  while #heldNotes > 0 do
    waitDuration, durationRepeatProbability, repeatCounter = doModulation(waitDuration, durationRepeatProbability, repeatCounter)
  end
end

function remove(voiceId)
  for i,v in ipairs(heldNotes) do
    if v == voiceId then
      table.remove(heldNotes, i)
    end
  end
end

function onNote(e)
  local voiceId = postEvent(e)
  --print("onNote voiceId", voiceId)
  table.insert(heldNotes, voiceId)
  if legato.value == true then
    if #heldNotes == 1 then
      modulateBroadcast()
    end
  else
    spawn(modulateVoice, voiceId)
  end
end

function onRelease(e)
  local voiceId = postEvent(e)
  remove(voiceId)
end
