-- sequencers/stochasticSequencer -- 
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

local function mapValueBetweenRanges(value, fromMin, fromMax, toMin, toMax)
  return ((value - fromMin) / (fromMax - fromMin)) * (toMax - toMin) + toMin
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
  mapValueBetweenRanges = mapValueBetweenRanges,
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
      --print("Found equal, or next is nil", beat, currentValue)
      return currentValue
    end
    if beat < currentValue and beat > nextValue then
      local diffCurrent = currentValue - beat
      local diffNext = beat - nextValue
      if diffCurrent < diffNext then
        --print("Closest to current", beat, currentValue, nextValue)
        return currentValue
      else
        --print("Closest to next", beat, nextValue, currentValue)
        return nextValue
      end
    end
  end
  --print("No resolution found, returning the given beat value", beat)
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
    if type(duration) == "nil" then
      duration = 0
    end
    if type(gate) == "nil" then
      gate = 100
    end
    local maxResolution = resolutionValues[#resolutionValues]
    return math.max(maxResolution, duration * (gate / 100)) -- Never shorter than the system max resolution
  end  
}

--------------------------------------------------------------------------------
-- Stochastic Sequencer
--------------------------------------------------------------------------------

local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "#00000000"
local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local partToStepMap = {1} -- Holds the starting step for each part
local totalNumSteps = 8
local numParts = 1
local heldNotes = {}
local paramsPerPart = {}
local partSelect = {}
local channels = {"Omni"}
local listenOnChannel = 0 -- 0 = Omni

for i=1,16 do
  table.insert(channels, "" .. i)
end

setBackgroundColour("#3f3f3f")

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function clearPosition()
  for _,v in ipairs(paramsPerPart) do
    for i=1,v.numStepsBox.value do
      v.positionTable:setValue(i, 0)
    end
    v.partsTable:setValue(1, 0)
  end
end

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local tableWidth = 700
local tableX = 0

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = menuOutlineColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 510

local label = sequencerPanel:Label("label")
label.text = "Stochastic Sequencer"
label.align = "left"
label.alpha = 0.5
label.backgroundColour = "#272727"
label.fontSize = 22
label.position = {0,0}
label.size = {182,25}

local actionMenu = sequencerPanel:Menu("ActionMenu")
actionMenu.persistent = false
actionMenu.tooltip = "Select an action. NOTE: This changes data in the affected tables"
actionMenu.backgroundColour = menuBackgroundColour
actionMenu.textColour = menuTextColour
actionMenu.arrowColour = menuArrowColour
actionMenu.outlineColour = menuOutlineColour
actionMenu.showLabel = false

local focusButton = sequencerPanel:OnOffButton("FocusPartOnOff", false)
focusButton.backgroundColourOff = "#ff084486"
focusButton.backgroundColourOn = "#ff02ACFE"
focusButton.textColourOff = "#ff22FFFF"
focusButton.textColourOn = "#efFFFFFF"
focusButton.displayName = "Focus Part"
focusButton.tooltip = "When focus is active, only the part selected for editing is shown and played"
focusButton.fillColour = "#dd000061"
focusButton.size = {102,22}
focusButton.x = 260
focusButton.y = 0
focusButton.changed = function(self)
  setTableWidths()
end

local evolveButton = sequencerPanel:OnOffButton("EvolveOnOff", false)
evolveButton.backgroundColourOff = "#ff084486"
evolveButton.backgroundColourOn = "#ff02ACFE"
evolveButton.textColourOff = "#ff22FFFF"
evolveButton.textColourOn = "#efFFFFFF"
evolveButton.displayName = "Evolve"
evolveButton.tooltip = "When evolve is active, randomization is written back to the corresponding table. NOTE: Table values are overwritten when activated!"
evolveButton.fillColour = "#dd000061"
evolveButton.size = focusButton.size
evolveButton.x = focusButton.x + focusButton.width + 10
evolveButton.y = 0

local holdButton = sequencerPanel:OnOffButton("HoldOnOff", false)
holdButton.backgroundColourOff = "#ff084486"
holdButton.backgroundColourOn = "#ff02ACFE"
holdButton.textColourOff = "#ff22FFFF"
holdButton.textColourOn = "#efFFFFFF"
holdButton.displayName = "Hold"
holdButton.fillColour = "#dd000061"
holdButton.size = evolveButton.size
holdButton.x = evolveButton.x + evolveButton.width + 10
holdButton.y = 0
holdButton.changed = function(self)
  if self.value == false then
    heldNotes = {}
    clearPosition()
  end
end

local channelMenu = sequencerPanel:Menu("Channel", channels)
channelMenu.showLabel = false
channelMenu.backgroundColour = menuBackgroundColour
channelMenu.textColour = menuTextColour
channelMenu.arrowColour = menuArrowColour
channelMenu.outlineColour = menuOutlineColour
channelMenu.displayName = "Channel"
channelMenu.tooltip = "Listen to input on this channel"
channelMenu.size = holdButton.size
channelMenu.x = holdButton.x + holdButton.width + 10
channelMenu.y = 0
channelMenu.changed = function(self)
  listenOnChannel = self.value - 1
end

-- TODO Make sure the correct part is selected after loading, if part focus is active
local editPartMenu = sequencerPanel:Menu("EditPart", partSelect)
editPartMenu.backgroundColour = menuBackgroundColour
editPartMenu.textColour = menuTextColour
editPartMenu.arrowColour = menuArrowColour
editPartMenu.outlineColour = menuOutlineColour
editPartMenu.displayName = "Edit Part"
editPartMenu.y = 405
editPartMenu.x = 0
editPartMenu.width = 110
editPartMenu.changed = function(self)
  print("editPartMenu.changed")
  for i,v in ipairs(paramsPerPart) do
    local isVisible = self.value == i

    if isVisible then
      v.partsTable.backgroundColour = "#cc33cc44"
    elseif i % 2 == 0 then
      v.partsTable.backgroundColour = "#3f09A3F4"
    else
      v.partsTable.backgroundColour = "#1f09A3F4"
    end  

    v.partResolution.visible = isVisible
    v.numStepsBox.visible = isVisible
    v.stepResolution.visible = isVisible
    v.playMode.visible = isVisible
    v.ratchetMax.visible = isVisible
    v.playProbability.visible = isVisible
    v.repeatProbability.visible = isVisible
    v.directionProbability.visible = isVisible
    v.tieRand.visible = isVisible
    v.pitchProbRand.visible = isVisible
    v.velRand.visible = isVisible
    v.gateRand.visible = isVisible
    v.pitchRand.visible = isVisible
    v.ratchetRand.visible = isVisible
    v.tieRandFreq.visible = isVisible
    v.pitchProbRandFreq.visible = isVisible
    v.velRandFreq.visible = isVisible
    v.gateRandFreq.visible = isVisible
    v.pitchRandFreq.visible = isVisible
    v.ratchetRandFreq.visible = isVisible
  end
  setTableWidths()
end

local actionsCount = 0 -- Holds the number of actions in the actions menu, except the copy part items

local numPartsBox = sequencerPanel:NumBox("Parts", numParts, 1, 8, true)
numPartsBox.tooltip = "The Number of parts in the sequence"
numPartsBox.backgroundColour = menuBackgroundColour
numPartsBox.textColour = menuTextColour
numPartsBox.size = {editPartMenu.width,20}
numPartsBox.x = editPartMenu.x
numPartsBox.y = editPartMenu.y + editPartMenu.height + 5
numPartsBox.changed = function(self)
  print("numPartsBox.changed numParts/self.value", numParts, self.value)
  for i,v in ipairs(paramsPerPart) do
    v.partsTable.visible = false
    v.positionTable.visible = false
    v.seqPitchTable.visible = false
    v.tieStepTable.visible = false
    v.seqPitchChangeProbabilityTable.visible = false
    v.seqVelTable.visible = false
    v.seqGateTable.visible = false
    v.seqRatchetTable.visible = false
  end
  numParts = self.value
  for i=1,numParts do
    setNumSteps(i)
  end
  local partSelect = {}
  for i=1,numParts do
    -- Add item to part select table
    table.insert(partSelect, "Part " .. i)
    if paramsPerPart[i].init == false then
      -- Copy initial settings from prev part
      local prev = paramsPerPart[i-1]
      paramsPerPart[i].partResolution.value = prev.partResolution.value
      paramsPerPart[i].stepResolution.value = prev.stepResolution.value
      paramsPerPart[i].numStepsBox.value = prev.numStepsBox.value
      paramsPerPart[i].playMode.value = prev.playMode.value
      paramsPerPart[i].pitchRand.value = prev.pitchRand.value
      paramsPerPart[i].tieRand.value = prev.tieRand.value
      paramsPerPart[i].pitchProbRand.value = prev.pitchProbRand.value
      paramsPerPart[i].velRand.value = prev.velRand.value
      paramsPerPart[i].gateRand.value = prev.gateRand.value
      paramsPerPart[i].ratchetRand.value = prev.ratchetRand.value
      paramsPerPart[i].pitchRandFreq.value = prev.pitchRandFreq.value
      paramsPerPart[i].tieRandFreq.value = prev.tieRandFreq.value
      paramsPerPart[i].pitchProbRandFreq.value = prev.pitchProbRandFreq.value
      paramsPerPart[i].velRandFreq.value = prev.velRandFreq.value
      paramsPerPart[i].gateRandFreq.value = prev.gateRandFreq.value
      paramsPerPart[i].ratchetRandFreq.value = prev.ratchetRandFreq.value
      paramsPerPart[i].ratchetMax.value = prev.ratchetMax.value
      paramsPerPart[i].init = prev.init
    end
  end
  clearPosition()
  editPartMenu.items = partSelect
  editPartMenu:setValue(#partSelect)
  -- Update action menu
  local actionMenuItems = {"Actions...", "Randomize all tables", "Randomize pitch table", "Randomize tie table", "Randomize pitch probability table", "Randomize velocity table", "Randomize gate table", "Randomize ratchet table", "Reset all tables", "Reset pitch table", "Reset tie table", "Reset pitch probability table", "Reset velocity table", "Reset gate table", "Reset ratchet table", "Set velocity at 50%", "Set gate at 50%"}
  actionsCount = #actionMenuItems
  if numParts > 1 then
    for i=1, numParts do
      table.insert(actionMenuItems, "Copy settings from part " .. i)
    end
  end
  actionMenu.items = actionMenuItems
  setTableWidths()
end

local partRand = sequencerPanel:NumBox("PartRandomization", 0, 0, 100, true)
partRand.displayName = "Part Order"
partRand.tooltip = "Amount of radomization applied to the playing order of parts"
partRand.unit = Unit.Percent
partRand.backgroundColour = menuBackgroundColour
partRand.textColour = menuTextColour
partRand.height = 20
partRand.width = editPartMenu.width
partRand.x = numPartsBox.x
partRand.y = numPartsBox.y + numPartsBox.height + 5

function setNumSteps(index)
  print("setNumSteps", index)
  local numSteps = paramsPerPart[index].numStepsBox.value
  -- If follow step is selected, we use the value from numStepsBox
  if paramsPerPart[index].partResolution.value > #resolutions.getResolutions() then
    paramsPerPart[index].numStepsBox.enabled = true
  else
    local partDuration = resolutions.getResolution(paramsPerPart[index].partResolution.value)
    local stepDuration = resolutions.getResolution(paramsPerPart[index].stepResolution.value)
    numSteps = partDuration / stepDuration
    paramsPerPart[index].numStepsBox.enabled = false

    -- Set value in numsteps box
    if numSteps > paramsPerPart[index].numStepsBox.max then
      paramsPerPart[index].numStepsBox:setRange(1, numSteps)
    end
    paramsPerPart[index].numStepsBox:setValue(numSteps, false)
  end

  partToStepMap = {} -- Reset
  totalNumSteps = 0
  for i=1, numPartsBox.value do
    table.insert(partToStepMap, (totalNumSteps + 1))
    totalNumSteps = totalNumSteps + paramsPerPart[i].numStepsBox.value
  end

  setTableWidths()
end

function setTableWidths()
  local focusSelectedPart = focusButton.value
  local widthPerStep = tableWidth / totalNumSteps
  local x = 0
  for i=1, numPartsBox.value do
    local isVisible = (focusSelectedPart == true and i == editPartMenu.value) or focusSelectedPart == false
    local partTableWidth = paramsPerPart[i].numStepsBox.value * widthPerStep
    if focusSelectedPart then
      partTableWidth = tableWidth
      x = 0
    end
    paramsPerPart[i].partsTable.visible = isVisible
    paramsPerPart[i].partsTable.width = partTableWidth
    paramsPerPart[i].partsTable.x = x

    paramsPerPart[i].positionTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].positionTable.visible = isVisible
    paramsPerPart[i].positionTable.width = partTableWidth
    paramsPerPart[i].positionTable.x = x

    paramsPerPart[i].seqPitchTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].seqPitchTable.visible = isVisible
    paramsPerPart[i].seqPitchTable.width = partTableWidth
    paramsPerPart[i].seqPitchTable.x = x

    paramsPerPart[i].tieStepTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].tieStepTable.visible = isVisible
    paramsPerPart[i].tieStepTable.width = partTableWidth
    paramsPerPart[i].tieStepTable.x = x

    paramsPerPart[i].seqPitchChangeProbabilityTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].seqPitchChangeProbabilityTable.visible = isVisible
    paramsPerPart[i].seqPitchChangeProbabilityTable.width = partTableWidth
    paramsPerPart[i].seqPitchChangeProbabilityTable.x = x

    paramsPerPart[i].seqVelTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].seqVelTable.visible = isVisible
    paramsPerPart[i].seqVelTable.width = partTableWidth
    paramsPerPart[i].seqVelTable.x = x

    paramsPerPart[i].seqGateTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].seqGateTable.visible = isVisible
    paramsPerPart[i].seqGateTable.width = partTableWidth
    paramsPerPart[i].seqGateTable.x = x

    paramsPerPart[i].seqRatchetTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].seqRatchetTable.visible = isVisible
    paramsPerPart[i].seqRatchetTable.width = partTableWidth
    paramsPerPart[i].seqRatchetTable.x = x

    x = x + partTableWidth
  end
end

local probabilityLabel = sequencerPanel:Label("ProbabilityLabel")
local randomizeLabel = sequencerPanel:Label("RandomizeLabel")

-- Add params that are to be editable per part
for i=1,numPartsBox.max do
  print("Set paramsPerPart", i)
  local isFirst = i == 1

  local partsTable = sequencerPanel:Table("Parts" .. i, 1, 0, 0, 1, true)
  partsTable.enabled = false
  partsTable.persistent = false
  partsTable.fillStyle = "solid"
  if i % 2 == 0 then
    partsTable.backgroundColour = "#3f09A3F4"
  else
    partsTable.backgroundColour = "#1f09A3F4"
  end
  partsTable.sliderColour = "#5FB5FF"
  partsTable.width = tableWidth
  partsTable.height = 10
  partsTable.x = tableX
  partsTable.y = label.y + label.height + 10

  local positionTable = sequencerPanel:Table("Position" .. i, totalNumSteps, 0, 0, 1, true)
  positionTable.enabled = false
  positionTable.persistent = false
  positionTable.fillStyle = "solid"
  if i % 2 == 0 then
    positionTable.backgroundColour = "#9f02ACFE"
  else
    positionTable.backgroundColour = "#6f02ACFE"
  end
  positionTable.sliderColour = outlineColour
  positionTable.width = tableWidth
  positionTable.height = partsTable.height
  positionTable.x = tableX
  positionTable.y = partsTable.y + partsTable.height

  local seqPitchTable = sequencerPanel:Table("Pitch" .. i, totalNumSteps, 0, -24, 24, true)
  seqPitchTable.displayName = "Pitch"
  seqPitchTable.tooltip = "Pitch offset"
  seqPitchTable.showPopupDisplay = true
  seqPitchTable.showLabel = true
  seqPitchTable.fillStyle = "solid"
  seqPitchTable.sliderColour = menuArrowColour
  if i % 2 == 0 then
    seqPitchTable.backgroundColour = "#3f000000"
  else
    seqPitchTable.backgroundColour = "#6f000000"
  end
  seqPitchTable.width = tableWidth
  seqPitchTable.height = 120
  seqPitchTable.x = tableX
  seqPitchTable.y = positionTable.y + positionTable.height
  
  local tieStepTable = sequencerPanel:Table("TieStep" .. i, totalNumSteps, 0, 0, 1, true)
  tieStepTable.tooltip = "Tie with next step"
  tieStepTable.fillStyle = "solid"
  if i % 2 == 0 then
    tieStepTable.backgroundColour = "#99000000"
  else
    tieStepTable.backgroundColour = "#ff000000"
  end
  tieStepTable.showLabel = false
  tieStepTable.sliderColour = menuTextColour
  tieStepTable.width = tableWidth
  tieStepTable.height = 8
  tieStepTable.x = tableX
  tieStepTable.y = seqPitchTable.y + seqPitchTable.height + 2
  
  local seqPitchChangeProbabilityTable = sequencerPanel:Table("PitchChangeProbability" .. i, totalNumSteps, 0, 0, 100, true)
  seqPitchChangeProbabilityTable.displayName = "Pitch Swap Probability"
  seqPitchChangeProbabilityTable.tooltip = "Set the probability that the pitch from another step will be used"
  seqPitchChangeProbabilityTable.showPopupDisplay = true
  seqPitchChangeProbabilityTable.showLabel = true
  seqPitchChangeProbabilityTable.fillStyle = "solid"
  seqPitchChangeProbabilityTable.sliderColour = menuArrowColour
  if i % 2 == 0 then
    seqPitchChangeProbabilityTable.backgroundColour = "#3f000000"
  else
    seqPitchChangeProbabilityTable.backgroundColour = "#6f000000"
  end
  seqPitchChangeProbabilityTable.width = tableWidth
  seqPitchChangeProbabilityTable.height = 63
  seqPitchChangeProbabilityTable.x = tableX
  seqPitchChangeProbabilityTable.y = tieStepTable.y + tieStepTable.height + 2
  
  local seqVelTable = sequencerPanel:Table("Velocity" .. i, totalNumSteps, 100, 1, 127, true)
  seqVelTable.displayName = "Velocity"
  seqVelTable.tooltip = "Set step velocity"
  seqVelTable.showPopupDisplay = true
  seqVelTable.showLabel = true
  seqVelTable.fillStyle = "solid"
  seqVelTable.sliderColour = menuArrowColour
  if i % 2 == 0 then
    seqVelTable.backgroundColour = "#3f000000"
  else
    seqVelTable.backgroundColour = "#6f000000"
  end
  seqVelTable.width = tableWidth
  seqVelTable.height = seqPitchChangeProbabilityTable.height
  seqVelTable.x = tableX
  seqVelTable.y = seqPitchChangeProbabilityTable.y + seqPitchChangeProbabilityTable.height + 2
  
  local seqGateTable = sequencerPanel:Table("Gate" .. i, totalNumSteps, 100, 0, 120, true)
  seqGateTable.displayName = "Gate"
  seqGateTable.tooltip = "Set step gate length"
  seqGateTable.showPopupDisplay = true
  seqGateTable.showLabel = true
  seqGateTable.fillStyle = "solid"
  seqGateTable.sliderColour = menuArrowColour
  if i % 2 == 0 then
    seqGateTable.backgroundColour = "#3f000000"
  else
    seqGateTable.backgroundColour = "#6f000000"
  end
  seqGateTable.width = seqVelTable.width
  seqGateTable.height = seqVelTable.height
  seqGateTable.x = tableX
  seqGateTable.y = seqVelTable.y + seqVelTable.height + 2

  local seqRatchetTable = sequencerPanel:Table("Subdivision" .. i, totalNumSteps, 1, 1, 4, true)
  seqRatchetTable.displayName = "Subdivision"
  seqRatchetTable.tooltip = "Subdivision for this step"
  seqRatchetTable.showPopupDisplay = true
  seqRatchetTable.showLabel = false
  seqRatchetTable.fillStyle = "solid"
  seqRatchetTable.sliderColour = "#33229966"
  if i % 2 == 0 then
    seqRatchetTable.backgroundColour = "#3f000000"
  else
    seqRatchetTable.backgroundColour = "#6f000000"
  end
  seqRatchetTable.width = seqGateTable.width
  seqRatchetTable.height = seqVelTable.height * 0.3
  seqRatchetTable.x = tableX
  seqRatchetTable.y = seqGateTable.y + seqGateTable.height + 5

  local partResolution = sequencerPanel:Menu("PartDuration" .. i, resolutions.getResolutionNames({"Follow Step"}))
  local stepResolution = sequencerPanel:Menu("StepResolution" .. i, resolutions.getResolutionNames())

  partResolution.displayName = "Part Duration"
  partResolution.tooltip = "Set the duration of a part."
  partResolution.selected = #resolutions.getResolutions() + 1
  partResolution.visible = isFirst
  partResolution.x = editPartMenu.x + editPartMenu.width + 5
  partResolution.y = editPartMenu.y
  partResolution.width = 100
  partResolution.backgroundColour = menuBackgroundColour
  partResolution.textColour = menuTextColour
  partResolution.arrowColour = menuArrowColour
  partResolution.outlineColour = menuOutlineColour
  partResolution.changed = function(self)
    print("partResolution.changed", i)
    setNumSteps(i)
  end
  
  local numStepsBox = sequencerPanel:NumBox("Steps" .. i, totalNumSteps, 1, 32, true)
  numStepsBox.displayName = "Steps"
  numStepsBox.tooltip = "The Number of steps in the part"
  numStepsBox.visible = isFirst
  numStepsBox.backgroundColour = menuBackgroundColour
  numStepsBox.textColour = menuTextColour
  numStepsBox.width = partResolution.width
  numStepsBox.x = partResolution.x
  numStepsBox.y = partResolution.y + partResolution.height + 5
  numStepsBox.changed = function(self)
    print("numStepsBox.changed index/value", i, self.value)
    setNumSteps(i)
  end

  stepResolution.showLabel = false
  stepResolution.selected = 20
  stepResolution.visible = isFirst
  stepResolution.x = numStepsBox.x
  stepResolution.y = numStepsBox.y + numStepsBox.height + 5
  stepResolution.width = numStepsBox.width
  stepResolution.height = numStepsBox.height
  stepResolution.backgroundColour = menuBackgroundColour
  stepResolution.textColour = menuTextColour
  stepResolution.arrowColour = menuArrowColour
  stepResolution.outlineColour = menuOutlineColour
  stepResolution.changed = function(self)
    print("stepResolution.changed", i)
    setNumSteps(i)
  end

  local playMode = sequencerPanel:Menu("PlayMode" .. i, {"Mono", "As Played", "Random", "Duo", "Chord", "Lowest Held", "Highest Held"})
  playMode.displayName = "Play Mode"
  playMode.visible = isFirst
  playMode.x = partResolution.x + partResolution.width + 5
  playMode.y = editPartMenu.y
  playMode.width = 100
  playMode.backgroundColour = menuBackgroundColour
  playMode.textColour = menuTextColour
  playMode.arrowColour = menuArrowColour
  playMode.outlineColour = menuOutlineColour

  local ratchetMax = sequencerPanel:NumBox("SubdivisionMax" .. i, 4, 2, 16, true)
  ratchetMax.displayName = "Subdiv Max"
  ratchetMax.tooltip = "Set the maximum allowed subdivision that can be selected for each step"
  ratchetMax.visible = isFirst
  ratchetMax.backgroundColour = menuBackgroundColour
  ratchetMax.textColour = menuTextColour
  ratchetMax.height = numStepsBox.height
  ratchetMax.width = playMode.width
  ratchetMax.y = playMode.y + playMode.height + 5
  ratchetMax.x = playMode.x
  ratchetMax.changed = function(self)
    for i=1, seqRatchetTable.length do
      if seqRatchetTable:getValue(i) > self.value then
        seqRatchetTable:setValue(i, self.value)
      end
    end
    seqRatchetTable:setRange(1, self.value)
  end

  if isFirst then
    probabilityLabel.text = "Probability"
    probabilityLabel.width = 100
    probabilityLabel.x = playMode.x + playMode.width + 5
    probabilityLabel.y = playMode.y
  end

  local playProbability = sequencerPanel:NumBox("PartPlayProbability" .. i, 100, 0, 100, true)
  playProbability.displayName = "Play"
  playProbability.tooltip = "Set the probability that the part will be played when randomizing part order."
  playProbability.visible = isFirst
  playProbability.unit = Unit.Percent
  playProbability.backgroundColour = menuBackgroundColour
  playProbability.textColour = menuTextColour
  playProbability.x = probabilityLabel.x
  playProbability.y = probabilityLabel.y + probabilityLabel.height + 5
  playProbability.height = 20
  playProbability.width = probabilityLabel.width

  local repeatProbability = sequencerPanel:NumBox("PartRepeatProbability" .. i, 50, 0, 100, true)
  repeatProbability.displayName = "Repeat"
  repeatProbability.tooltip = "Set the probability of that the part will be repeated when randomizing part order. When set to 0, the part is never repeated."
  repeatProbability.visible = isFirst
  repeatProbability.unit = Unit.Percent
  repeatProbability.backgroundColour = menuBackgroundColour
  repeatProbability.textColour = menuTextColour
  repeatProbability.x = playProbability.x
  repeatProbability.y = playProbability.y + playProbability.height + 5
  repeatProbability.height = playProbability.height
  repeatProbability.width = playProbability.width

  local directionProbability = sequencerPanel:NumBox("PartDirectionProbability" .. i, 0, 0, 100, true)
  directionProbability.displayName = "Backward"
  directionProbability.tooltip = "Set the probability that the part will play backwards"
  directionProbability.visible = isFirst
  directionProbability.unit = Unit.Percent
  directionProbability.backgroundColour = menuBackgroundColour
  directionProbability.textColour = menuTextColour
  directionProbability.x = repeatProbability.x
  directionProbability.y = repeatProbability.y + repeatProbability.height + 5
  directionProbability.height = repeatProbability.height
  directionProbability.width = playProbability.width

  if isFirst then
    randomizeLabel.text = "Randomize (Amount/Frequency)"
    randomizeLabel.width = 240
    randomizeLabel.x = probabilityLabel.x + probabilityLabel.width + 5
    randomizeLabel.y = probabilityLabel.y
  end

  local defaultFrequency = 50
  local numBoxSize1 = {100,repeatProbability.height}
  local numBoxSize2 = {33,repeatProbability.height}

  local pitchRand = sequencerPanel:NumBox("PitchRandomization" .. i, 0, 0, 100, true)
  pitchRand.displayName = "Pitch"
  pitchRand.tooltip = "Amount of radomization applied to pitch offset"
  pitchRand.visible = isFirst
  pitchRand.unit = Unit.Percent
  pitchRand.backgroundColour = menuBackgroundColour
  pitchRand.textColour = menuTextColour
  pitchRand.size = numBoxSize1
  pitchRand.x = randomizeLabel.x
  pitchRand.y = randomizeLabel.y + randomizeLabel.height + 5

  local pitchRandFreq = sequencerPanel:NumBox("PitchRandomizationFrequency" .. i, defaultFrequency, 0, 100, true)
  pitchRandFreq.showLabel = false
  pitchRandFreq.tooltip = "Frequency of pitch offset radomization"
  pitchRandFreq.visible = isFirst
  pitchRandFreq.unit = Unit.Percent
  pitchRandFreq.backgroundColour = menuBackgroundColour
  pitchRandFreq.textColour = menuTextColour
  pitchRandFreq.size = numBoxSize2
  pitchRandFreq.x = pitchRand.x + pitchRand.width - 2
  pitchRandFreq.y = pitchRand.y

  local tieRand = sequencerPanel:NumBox("TieRandomization" .. i, 0, 0, 100, true)
  tieRand.visible = isFirst
  tieRand.displayName = "Tie"
  tieRand.tooltip = "Amount of radomization applied to ties"
  tieRand.unit = Unit.Percent
  tieRand.backgroundColour = menuBackgroundColour
  tieRand.textColour = menuTextColour
  tieRand.size = numBoxSize1
  tieRand.x = pitchRand.x
  tieRand.y = pitchRand.y + pitchRand.height + 5  

  local tieRandFreq = sequencerPanel:NumBox("TieRandomizationFrequency" .. i, defaultFrequency, 0, 100, true)
  tieRandFreq.visible = isFirst
  tieRandFreq.showLabel = false
  tieRandFreq.tooltip = "Frequency of tie radomization"
  tieRandFreq.unit = Unit.Percent
  tieRandFreq.backgroundColour = menuBackgroundColour
  tieRandFreq.textColour = menuTextColour
  tieRandFreq.size = numBoxSize2
  tieRandFreq.x = tieRand.x + tieRand.width - 2
  tieRandFreq.y = tieRand.y

  local pitchProbRand = sequencerPanel:NumBox("PitchProbabilityRandomization" .. i, 0, 0, 100, true)
  pitchProbRand.visible = isFirst
  pitchProbRand.displayName = "Pitch Swap"
  pitchProbRand.tooltip = "Amount of radomization applied to pitch swap probability - pitch swap means playing the pitch offset from another step in the part"
  pitchProbRand.unit = Unit.Percent
  pitchProbRand.backgroundColour = menuBackgroundColour
  pitchProbRand.textColour = menuTextColour
  pitchProbRand.size = numBoxSize1
  pitchProbRand.x = tieRand.x
  pitchProbRand.y = tieRand.y + tieRand.height + 5

  local pitchProbRandFreq = sequencerPanel:NumBox("PitchProbabilityRandomizationFrequency" .. i, defaultFrequency, 0, 100, true)
  pitchProbRandFreq.visible = isFirst
  pitchProbRandFreq.showLabel = false
  pitchProbRandFreq.tooltip = "Frequency of pitch swap probability radomization"
  pitchProbRandFreq.unit = Unit.Percent
  pitchProbRandFreq.backgroundColour = menuBackgroundColour
  pitchProbRandFreq.textColour = menuTextColour
  pitchProbRandFreq.size = numBoxSize2
  pitchProbRandFreq.x = pitchProbRand.x + pitchProbRand.width - 2
  pitchProbRandFreq.y = pitchProbRand.y

  local velRand = sequencerPanel:NumBox("VelocityRandomization" .. i, 0, 0, 100, true)
  velRand.displayName = "Velocity"
  velRand.visible = isFirst
  velRand.tooltip = "Amount of radomization applied to sequencer velocity"
  velRand.unit = Unit.Percent
  velRand.backgroundColour = menuBackgroundColour
  velRand.textColour = menuTextColour
  velRand.size = numBoxSize1
  velRand.x = randomizeLabel.x + 138
  velRand.y = pitchRand.y

  local velRandFreq = sequencerPanel:NumBox("VelocityRandomizationFrequency" .. i, defaultFrequency, 0, 100, true)
  velRandFreq.showLabel = false
  velRandFreq.visible = isFirst
  velRandFreq.tooltip = "Frequency of velocity radomization"
  velRandFreq.unit = Unit.Percent
  velRandFreq.backgroundColour = menuBackgroundColour
  velRandFreq.textColour = menuTextColour
  velRandFreq.size = numBoxSize2
  velRandFreq.x = velRand.x + velRand.width - 2
  velRandFreq.y = velRand.y

  local gateRand = sequencerPanel:NumBox("GateRandomization" .. i, 0, 0, 100, true)
  gateRand.visible = isFirst
  gateRand.displayName = "Gate"
  gateRand.tooltip = "Amount of radomization applied to sequencer gate"
  gateRand.unit = Unit.Percent
  gateRand.backgroundColour = menuBackgroundColour
  gateRand.textColour = menuTextColour
  gateRand.size = numBoxSize1
  gateRand.x = velRand.x
  gateRand.y = velRand.y + velRand.height + 5

  local gateRandFreq = sequencerPanel:NumBox("GateRandomizationFrequency" .. i, defaultFrequency, 0, 100, true)
  gateRandFreq.visible = isFirst
  gateRandFreq.showLabel = false
  gateRandFreq.tooltip = "Frequency of gate radomization"
  gateRandFreq.unit = Unit.Percent
  gateRandFreq.backgroundColour = menuBackgroundColour
  gateRandFreq.textColour = menuTextColour
  gateRandFreq.size = numBoxSize2
  gateRandFreq.x = gateRand.x + gateRand.width - 2
  gateRandFreq.y = gateRand.y

  local ratchetRand = sequencerPanel:NumBox("SubdivisionRandomization" .. i, 0, 0, 100, true)
  ratchetRand.displayName = "Subdivision"
  ratchetRand.tooltip = "Amount of radomization applied to step subdivision"
  ratchetRand.visible = isFirst
  ratchetRand.unit = Unit.Percent
  ratchetRand.backgroundColour = menuBackgroundColour
  ratchetRand.textColour = menuTextColour
  ratchetRand.size = numBoxSize1
  ratchetRand.x = gateRand.x
  ratchetRand.y = gateRand.y + gateRand.height + 5

  local ratchetRandFreq = sequencerPanel:NumBox("SubdivisionRandomizationFrequency" .. i, defaultFrequency, 0, 100, true)
  ratchetRandFreq.showLabel = false
  ratchetRandFreq.tooltip = "Frequency of subdivision radomization"
  ratchetRandFreq.visible = isFirst
  ratchetRandFreq.unit = Unit.Percent
  ratchetRandFreq.backgroundColour = menuBackgroundColour
  ratchetRandFreq.textColour = menuTextColour
  ratchetRandFreq.size = numBoxSize2
  ratchetRandFreq.x = ratchetRand.x + ratchetRand.width - 2
  ratchetRandFreq.y = ratchetRand.y

  table.insert(paramsPerPart, {tieRand=tieRand,tieRandFreq=tieRandFreq,pitchProbRand=pitchProbRand,pitchProbRandFreq=pitchProbRandFreq,velRand=velRand,velRandFreq=velRandFreq,gateRand=gateRand,gateRandFreq=gateRandFreq,ratchetRand=ratchetRand,ratchetRandFreq=ratchetRandFreq,pitchRand=pitchRand,pitchRandFreq=pitchRandFreq,partsTable=partsTable,positionTable=positionTable,seqPitchTable=seqPitchTable,tieStepTable=tieStepTable,seqPitchChangeProbabilityTable=seqPitchChangeProbabilityTable,seqVelTable=seqVelTable,seqGateTable=seqGateTable,seqRatchetTable=seqRatchetTable,partResolution=partResolution,stepResolution=stepResolution,playMode=playMode,playProbability=playProbability,directionProbability=directionProbability,ratchetMax=ratchetMax,repeatProbability=repeatProbability,numStepsBox=numStepsBox,init=i==1})
end

actionMenu.y = paramsPerPart[editPartMenu.value].ratchetMax.y + paramsPerPart[editPartMenu.value].ratchetMax.height + 5
actionMenu.x = paramsPerPart[editPartMenu.value].ratchetMax.x
actionMenu.size = paramsPerPart[editPartMenu.value].ratchetMax.size
actionMenu.changed = function(self)
  if self.value == 1 then
    return
  end
  local partParams = paramsPerPart[editPartMenu.value]
  if self.value < 9 then
    -- Randomize tables
    for i=1,partParams.numStepsBox.value do
      if self.value == 2 or self.value == 3 then
        partParams.seqPitchTable:setValue(i, gem.getRandom(partParams.seqPitchTable.min, partParams.seqPitchTable.max))
      end
      if self.value == 2 or self.value == 4 then
        partParams.tieStepTable:setValue(i, gem.getRandom(partParams.tieStepTable.min, partParams.tieStepTable.max))
      end
      if self.value == 2 or self.value == 5 then
        partParams.seqPitchChangeProbabilityTable:setValue(i, gem.getRandom(partParams.seqPitchChangeProbabilityTable.min, partParams.seqPitchChangeProbabilityTable.max))
      end
      if self.value == 2 or self.value == 6 then
        partParams.seqVelTable:setValue(i, gem.getRandom(partParams.seqVelTable.min, partParams.seqVelTable.max))
      end
      if self.value == 2 or self.value == 7 then
        partParams.seqGateTable:setValue(i, gem.getRandom(partParams.seqGateTable.min, partParams.seqGateTable.max))
      end
      if self.value == 2 or self.value == 8 then
        partParams.seqRatchetTable:setValue(i, gem.getRandom(partParams.seqRatchetTable.min, partParams.seqRatchetTable.max))
      end
    end
  elseif self.value < 16 then
    -- Clear tables (set default values)
    for i=1,partParams.numStepsBox.value do
      if self.value == 9 or self.value == 10 then
        partParams.seqPitchTable:setValue(i, partParams.seqPitchTable.default)
      end
      if self.value == 9 or self.value == 11 then
        partParams.tieStepTable:setValue(i, partParams.tieStepTable.default)
      end
      if self.value == 9 or self.value == 12 then
        partParams.seqPitchChangeProbabilityTable:setValue(i, partParams.seqPitchChangeProbabilityTable.default)
      end
      if self.value == 9 or self.value == 13 then
        partParams.seqVelTable:setValue(i, partParams.seqVelTable.default)
      end
      if self.value == 9 or self.value == 14 then
        partParams.seqGateTable:setValue(i, partParams.seqGateTable.default)
      end
      if self.value == 9 or self.value == 15 then
        partParams.seqRatchetTable:setValue(i, partParams.seqRatchetTable.default)
      end
    end
  elseif self.value == 16 then
    for i=1,partParams.numStepsBox.value do
      partParams.seqVelTable:setValue(i, math.ceil(partParams.seqVelTable.max/2))
    end
  elseif self.value == 17 then
    for i=1,partParams.numStepsBox.value do
      partParams.seqGateTable:setValue(i, 50)
    end
  else
    -- Copy settings from another part
    local sourcePartIndex = self.value - actionsCount
    local targetPartIndex = editPartMenu.value
    if sourcePartIndex ~= targetPartIndex then
      local source = paramsPerPart[sourcePartIndex]
      local target = paramsPerPart[targetPartIndex]
      target.numStepsBox:setValue(source.numStepsBox.value)
      for i=1, target.numStepsBox.value do
        target.seqPitchTable:setValue(i, source.seqPitchTable:getValue(i))
        target.tieStepTable:setValue(i, source.tieStepTable:getValue(i))
        target.seqPitchChangeProbabilityTable:setValue(i, source.seqPitchChangeProbabilityTable:getValue(i))
        target.seqVelTable:setValue(i, source.seqVelTable:getValue(i))
        target.seqGateTable:setValue(i, source.seqGateTable:getValue(i))
        target.seqRatchetTable:setValue(i, source.seqRatchetTable:getValue(i))
      end
      target.pitchRand:setValue(source.pitchRand.value)
      target.tieRand:setValue(source.tieRand.value)
      target.pitchProbRand:setValue(source.pitchProbRand.value)
      target.velRand:setValue(source.velRand.value)
      target.gateRand:setValue(source.gateRand.value)
      target.ratchetRand:setValue(source.ratchetRand.value)
      target.pitchRandFreq:setValue(source.pitchRandFreq.value)
      target.tieRandFreq:setValue(source.tieRandFreq.value)
      target.pitchProbRandFreq:setValue(source.pitchProbRandFreq.value)
      target.velRandFreq:setValue(source.velRandFreq.value)
      target.gateRandFreq:setValue(source.gateRandFreq.value)
      target.ratchetRandFreq:setValue(source.ratchetRandFreq.value)
      target.partResolution:setValue(source.partResolution.value)
      target.stepResolution:setValue(source.stepResolution.value)
      target.playMode:setValue(source.playMode.value)
      target.playProbability:setValue(source.playProbability.value)
      target.directionProbability:setValue(source.directionProbability.value)
      target.repeatProbability:setValue(source.repeatProbability.value)
      target.ratchetMax:setValue(source.ratchetMax.value)
    end
  end
  self.selected = 1
end

editPartMenu:changed()
numPartsBox:changed()

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function arpeg(uniqueId)
  local index = 0
  local heldNoteIndex = 0 -- Counter for held notes (used by As Played seq mode)
  local currentPartPosition = 0 -- Holds the currently playing part
  local partRepeat = 0 -- Used for holding part repeat info
  local partDirectionBackward = false -- Used for holding part direction
  local isStarting = true
  -- START ARP LOOP
  print("Starting sequencer")
  while isPlaying and seqIndex == uniqueId do
    -- Set current position and part position
    local currentPosition = (index % totalNumSteps) + 1 -- 11 % 4 = 3
    local startOfPart = false
    for pp,sp in ipairs(partToStepMap) do
      if sp == currentPosition then
        currentPartPosition = pp
        print("Set currentPartPosition", currentPartPosition)
        startOfPart = true
        break
      end
    end

    -- If we are at the start of a part (and there is more than one part), check for part order randomization (or an active repeat)
    if startOfPart and numParts > 1 then
      if focusButton.value == true then
        currentPartPosition = editPartMenu.value
      elseif partRepeat > 0 then
        currentPartPosition = partRepeat
        partRepeat = 0 -- Reset repeat
        print("currentPartPosition repeat", currentPartPosition)
      elseif (isStarting == false or partRand.value > 50) and gem.getRandomBoolean(partRand.value) then
        -- Randomize parts within the set limit
        print("currentPartPosition before", currentPartPosition)
        -- Suggest a part by random
        local suggestedPartPosition = gem.getRandom(numParts)
        print("suggestedPartPosition", suggestedPartPosition)
        -- Check play probability
        if gem.getRandomBoolean(paramsPerPart[suggestedPartPosition].playProbability.value) then
          currentPartPosition = suggestedPartPosition
          print("playProbability was used", playProbability)
        end
        -- Check if part should be repeated next time
        if gem.getRandomBoolean(paramsPerPart[currentPartPosition].repeatProbability.value) then
          partRepeat = currentPartPosition
          print("Part is set for repeating", partRepeat)
        end
      end
      -- Set the current pos and index from the selected part
      currentPosition = partToStepMap[currentPartPosition]
      index = currentPosition - 1
      print("currentPartPosition after", currentPartPosition)
    end

    if startOfPart then
      -- Set direction for this part
      local directionProbability = paramsPerPart[currentPartPosition].directionProbability.value
      partDirectionBackward = gem.getRandomBoolean(directionProbability)
      print("directionProbability/currentPartPosition/partDirectionBackward", directionProbability, currentPartPosition, partDirectionBackward)
    end

    -- If evolve is true, the randomization is written back to the table
    local evolve = evolveButton.value

    -- Params for current part position
    local playMode = paramsPerPart[currentPartPosition].playMode.value
    local numStepsInPart = paramsPerPart[currentPartPosition].numStepsBox.value

    -- Flip position if playing backwards
    local startStep = partToStepMap[currentPartPosition]
    local endStep = startStep + numStepsInPart - 1
    print("startStep/endStep/currentPosition/currentPartPosition", startStep, endStep, currentPosition, currentPartPosition)
    if partDirectionBackward == true then
      local diff = currentPosition - startStep
      currentPosition = endStep - diff
      print("partDirectionBackward diff/currentPosition", diff, currentPosition)
    end

    -- Tables for current step position
    local seqVelTable = paramsPerPart[currentPartPosition].seqVelTable
    local seqGateTable = paramsPerPart[currentPartPosition].seqGateTable
    local seqRatchetTable = paramsPerPart[currentPartPosition].seqRatchetTable
    local seqPitchTable = paramsPerPart[currentPartPosition].seqPitchTable
    local seqPitchChangeProbabilityTable = paramsPerPart[currentPartPosition].seqPitchChangeProbabilityTable
    local tieStepTable = paramsPerPart[currentPartPosition].tieStepTable
    
    -- Params for current step position
    local tablePos = currentPosition - startStep + 1
    print("tablePos", tablePos)
    local vel = seqVelTable:getValue(tablePos) -- get velocity
    local gate = seqGateTable:getValue(tablePos) -- get gate
    local ratchet = seqRatchetTable:getValue(tablePos) -- get ratchet
    local pitchAdjustment = seqPitchTable:getValue(tablePos) -- get pitch adjustment
    local pitchChangeProbability = seqPitchChangeProbabilityTable:getValue(tablePos) -- get pitch swap probability
    local tieNext = tieStepTable:getValue(tablePos)

    -- Check if tie from previous step
    local tieStepPos = tablePos - 1
    if partDirectionBackward == true then
      tieStepPos = tablePos + 1
    end
    print("tieStepPos", tieStepPos)

    -- Hold the number of steps the note in this position should play
    local noteSteps = 1

    -- Randomize ties
    local tieRandomizationFrequency = paramsPerPart[currentPartPosition].tieRandFreq.value
    local tieRandomizationAmount = paramsPerPart[currentPartPosition].tieRand.value
    if tieRandomizationAmount > 0 and tablePos < numStepsInPart and gem.getRandomBoolean(tieRandomizationFrequency) then
      print("Before randomized tieNext", tieNext)
      local min = 1
      local max = gem.getChangeMax((numStepsInPart-tablePos), tieRandomizationAmount)
      noteSteps = gem.getRandom(min, math.max(2, max))
      if noteSteps == 1 then
        tieNext = 0
      else
        tieNext = 1
      end
      if evolve == true then
        local tieStepPos = tablePos
        for i=1, noteSteps do
          tieStepTable:setValue(tieStepPos, tieNext)
          if partDirectionBackward == true then
            tieStepPos = tieStepPos - 1
          else
            tieStepPos = tieStepPos + 1
          end
        end
      end
      print("After randomize tieNext/max/noteSteps", tieNext, max, noteSteps)
    elseif tieNext == 1 then
      local tieStepPos = tablePos
      while tieStepPos > 0 and tieStepPos < numStepsInPart and tieStepTable:getValue(tieStepPos) == 1 do
        noteSteps = noteSteps + 1
        if partDirectionBackward == true then
          tieStepPos = tieStepPos - 1
        else
          tieStepPos = tieStepPos + 1
        end
      end
      print("Set tie steps tablePos/noteSteps", tablePos, noteSteps)
    end

    -- UPDATE STEP POSITION TABLE
    for i=1, numParts do
      for j=1, paramsPerPart[i].numStepsBox.value do
        local isActiveStep = j >= tablePos and j < tablePos + noteSteps
        if partDirectionBackward == true then
          isActiveStep = j <= tablePos and j > tablePos - noteSteps
        end
        if i == currentPartPosition and isActiveStep then
          paramsPerPart[i].positionTable:setValue(j, 1)
        else
          paramsPerPart[i].positionTable:setValue(j, 0)
        end
      end
    end

    -- UPDATE PART POSITION TABLE
    if startOfPart then
      for i=1, numParts do
        if i == currentPartPosition then
          paramsPerPart[i].partsTable:setValue(1, 1)
        else
          paramsPerPart[i].partsTable:setValue(1, 0)
        end
      end
    end

    -- Randomize ratchet
    local ratchetRandomizationFrequency = paramsPerPart[currentPartPosition].ratchetRandFreq.value
    local ratchetRandomizationAmount = paramsPerPart[currentPartPosition].ratchetRand.value
    if ratchetRandomizationAmount > 0 and gem.getRandomBoolean(ratchetRandomizationFrequency) then
      local min = seqRatchetTable.min
      local max = math.min(seqRatchetTable.max, (gem.getChangeMax(seqRatchetTable.max, ratchetRandomizationAmount) + noteSteps))
      ratchet = gem.getRandom(min, max)
      print("Randomize ratchet, min/max/ratchet", min, max, ratchet)
      if evolve == true then
        seqRatchetTable:setValue(currentPosition, ratchet)
      end
    end

    local stepDuration = (resolutions.getResolution(paramsPerPart[currentPartPosition].stepResolution.value) * noteSteps) / ratchet

    for ratchetIndex=1, ratchet do
      -- Randomize gate
      local gateRandomizationFrequency = paramsPerPart[currentPartPosition].gateRandFreq.value
      if gem.getRandomBoolean(gateRandomizationFrequency) then
        gate = gem.randomizeValue(gate, seqGateTable.min, seqGateTable.max, paramsPerPart[currentPartPosition].gateRand.value)
        if evolve == true then
          seqGateTable:setValue(tablePos, gate)
        end
      end

      -- Randomize pitch adjustment
      local pitchRandomizationFrequency = paramsPerPart[currentPartPosition].pitchRandFreq.value
      local pitchRandomizationAmount = paramsPerPart[currentPartPosition].pitchRand.value
      if pitchRandomizationAmount > 0 and gem.getRandomBoolean(pitchRandomizationFrequency) then
        local changeMax = gem.getChangeMax(seqPitchTable.max, pitchRandomizationAmount)
        local min = pitchAdjustment - changeMax
        local max = pitchAdjustment + changeMax
        if min < seqPitchTable.min then
          min = seqPitchTable.min
        end
        if max > seqPitchTable.max then
          max = seqPitchTable.max
        end
        print("Before randomize pitchAdjustment", pitchAdjustment)
        pitchAdjustment = gem.getRandom(min, max)
        print("After randomize pitchAdjustment/changeMax/min/max", pitchAdjustment, changeMax, min, max)
        if evolve == true then
          seqPitchTable:setValue(tablePos, pitchAdjustment)
        end
      end

      -- Randomize velocity
      local velocityRandomizationFrequency = paramsPerPart[currentPartPosition].velRandFreq.value
      if gem.getRandomBoolean(velocityRandomizationFrequency) then
        vel = gem.randomizeValue(vel, seqVelTable.min, seqVelTable.max, paramsPerPart[currentPartPosition].velRand.value)
        if evolve == true then
          seqVelTable:setValue(tablePos, vel)
        end
      end

      -- Randomize pitch probaility
      local pitchProbabilityRandomizationFrequency = paramsPerPart[currentPartPosition].pitchProbRandFreq.value
      local pitchProbabilityRandomizationAmount = paramsPerPart[currentPartPosition].pitchProbRand.value
      if pitchProbabilityRandomizationAmount > 0 and gem.getRandomBoolean(pitchProbabilityRandomizationFrequency) then
        local changeMax = gem.getChangeMax(seqPitchChangeProbabilityTable.max, pitchProbabilityRandomizationAmount)
        local min = pitchChangeProbability - changeMax
        local max = pitchChangeProbability + changeMax
        if min < seqPitchChangeProbabilityTable.min then
          min = seqPitchChangeProbabilityTable.min
        end
        if max > seqPitchChangeProbabilityTable.max then
          max = seqPitchChangeProbabilityTable.max
        end
        print("Before randomize pitchChangeProbability", pitchChangeProbability)
        pitchChangeProbability = gem.getRandom(min, max)
        print("After randomize pitchChangeProbability/changeMax/min/max", pitchChangeProbability, changeMax, min, max)
        if evolve == true then
          seqPitchChangeProbabilityTable:setValue(tablePos, pitchChangeProbability)
        end
      end

      -- Reset notes table
      local notes = {} -- Holds the note(s) that plays at this position
      local offset = 0
      if #heldNotes == 0 then
        local buffer = 1 -- How long to wait for notes before stopping the sequencer
        wait(buffer)
        print("waiting for heldNotes", buffer)
        offset = offset + buffer
      end
      if #heldNotes == 0 then
        print("#heldNotes == 0 - stopping sequencer")
        clearPosition()
        isPlaying = false
        break
      end
  
      -- If gate is zero, no notes will play on this step
      if gate > 0 then
        -- Check for pitch change randomization
        if gem.getRandomBoolean(pitchChangeProbability) then
          -- Get pitch adjustment from random index in pitch table for current part
          local pitchPos = gem.getRandom(numStepsInPart)
          pitchAdjustment = seqPitchTable:getValue(pitchPos)
          print("Playing pitch from other pos - tablePos/pitchPos", tablePos, pitchPos)
        end

        -- Add notes to play
        -- "Mono", "As Played", "Random", "Duo", "Chord", "Mono (First Held)"
        local sortedNotes = {}
        for _,v in ipairs(heldNotes) do
          table.insert(sortedNotes, v.note)
        end
        table.sort(sortedNotes)

        if playMode == 1 then
          -- Mono (Last held)
            table.insert(notes, heldNotes[#heldNotes].note)
        elseif playMode == 2 then
          -- As played
          if partDirectionBackward == true then
            heldNoteIndex = heldNoteIndex - 1 -- Decrement held note position
            if heldNoteIndex < 1 then
              heldNoteIndex = #heldNotes
            end
          else
            heldNoteIndex = heldNoteIndex + 1 -- Increment held note position
            if heldNoteIndex > #heldNotes then
              heldNoteIndex = 1
            end
          end
          if gem.getRandomBoolean(pitchChangeProbability) then
            table.insert(notes, heldNotes[gem.getRandom(#heldNotes)].note)
          else
            -- Add a failsafe in case #heldNotes has changed since setting index
            if heldNoteIndex > #heldNotes then
              heldNoteIndex = #heldNotes
            end
            table.insert(notes, heldNotes[heldNoteIndex].note)
          end
        elseif playMode == 3 then
          -- Random
          table.insert(notes, sortedNotes[gem.getRandom(#sortedNotes)])
        elseif playMode == 4 then
          -- Duo (Lowest and highest held notes)
          table.insert(notes, sortedNotes[1])
          if #heldNotes > 1 then
            table.insert(notes, sortedNotes[#sortedNotes])
          end
        elseif playMode == 5 then
          -- Chord
          for i=1,#sortedNotes do
            table.insert(notes, sortedNotes[i])
          end
        elseif playMode == 6 then
          -- Lowest held
          table.insert(notes, sortedNotes[1])
        else
          -- Highest held
          table.insert(notes, sortedNotes[#sortedNotes])
        end
        print("#notes", #notes)
      end

      -- PLAY NOTE(S)
      for _,note in ipairs(notes) do
        if gate > 0 then
          -- Play the note for the set duration
          local duration = beat2ms(resolutions.getPlayDuration(stepDuration, gate)) - 1 -- Make sure note is not played into the next
          playNote(note+pitchAdjustment, vel, duration)
          print("Playing note/stepDuration/gate/duration/ratchet", note, stepDuration, gate, duration, ratchet)
        end
      end

      -- WAIT FOR NEXT BEAT
      wait(beat2ms(stepDuration) - offset)
    end
    -- END SUBDIVISION LOOP

    -- Increment position
    if noteSteps > 1 then
      index = index + noteSteps - 1
    end
    index = (index + 1) % totalNumSteps

    isStarting = false
  end
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
end

function onNote(e)
  if listenOnChannel == 0 or listenOnChannel == e.channel then
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
      seqIndex = gem.inc(seqIndex)
      spawn(arpeg, seqIndex)
    end
  else
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
  local pitchTableData = {}
  local tieStepTableData = {}
  local seqPitchChangeProbabilityTableData = {}
  local seqVelTableData = {}
  local seqGateTableData = {}
  local seqRatchetTableData = {}
  local numStepsData = {}

  for i=1, numParts do
    table.insert(numStepsData, paramsPerPart[i].numStepsBox.value)
    for j=1, paramsPerPart[i].numStepsBox.value do
      table.insert(pitchTableData, paramsPerPart[i].seqPitchTable:getValue(j))
      table.insert(tieStepTableData, paramsPerPart[i].tieStepTable:getValue(j))
      table.insert(seqPitchChangeProbabilityTableData, paramsPerPart[i].seqPitchChangeProbabilityTable:getValue(j))
      table.insert(seqVelTableData, paramsPerPart[i].seqVelTable:getValue(j))
      table.insert(seqGateTableData, paramsPerPart[i].seqGateTable:getValue(j))
      table.insert(seqRatchetTableData, paramsPerPart[i].seqRatchetTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, pitchTableData)
  table.insert(data, tieStepTableData)
  table.insert(data, seqPitchChangeProbabilityTableData)
  table.insert(data, seqVelTableData)
  table.insert(data, seqGateTableData)
  table.insert(data, seqRatchetTableData)
  table.insert(data, numStepsData)

  return data
end

function onLoad(data)
  local seqPitchTableData = data[1]
  local tieStepTableData = data[2]
  local seqPitchChangeProbabilityTableData = data[3]
  local seqVelTableData = data[4]
  local seqGateTableData = data[5]
  local seqRatchetTableData = data[6]
  local numStepsData = data[7]

  numPartsBox:setValue(#numStepsData)

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].seqPitchTable.length = v
    paramsPerPart[i].tieStepTable.length = v
    paramsPerPart[i].seqPitchChangeProbabilityTable.length = v
    paramsPerPart[i].seqVelTable.length = v
    paramsPerPart[i].seqGateTable.length = v
    paramsPerPart[i].seqRatchetTable.length = v
    for j=1, v do
      paramsPerPart[i].seqPitchTable:setValue(j, seqPitchTableData[dataCounter])
      paramsPerPart[i].tieStepTable:setValue(j, tieStepTableData[dataCounter])
      paramsPerPart[i].seqPitchChangeProbabilityTable:setValue(j, seqPitchChangeProbabilityTableData[dataCounter])
      paramsPerPart[i].seqVelTable:setValue(j, seqVelTableData[dataCounter])
      paramsPerPart[i].seqGateTable:setValue(j, seqGateTableData[dataCounter])
      paramsPerPart[i].seqRatchetTable:setValue(j, seqRatchetTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
end
