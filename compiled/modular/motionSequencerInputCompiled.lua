-- modular/motionSequencerInput -- 
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

local function triangle(minValue, maxValue, numSteps)
  local rising = true
  local numStepsUpDown = round(numSteps / 2)
  local valueRange = maxValue - minValue
  local changePerStep = valueRange / numStepsUpDown
  local startValue = minValue
  local tri = {}
  for i=1,numSteps do
    table.insert(tri, startValue)
    if rising then
      startValue = startValue + changePerStep
      if startValue >= maxValue then
        rising = false
      end
    else
      startValue = startValue - changePerStep
    end
  end
  return tri
end

local function rampUp(minValue, maxValue, numSteps)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numSteps)
  local startValue = minValue
  local ramp = {}
  for i=1,numSteps do
    table.insert(ramp, startValue)
    startValue = inc(startValue, changePerStep)
  end
  return ramp
end

local function rampDown(minValue, maxValue, numSteps)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numSteps)
  local startValue = maxValue
  local ramp = {}
  for i=1,numSteps do
    table.insert(ramp, startValue)
    startValue = inc(startValue, -changePerStep)
  end
  return ramp
end

local gem = {
  inc = inc,
  round = round,
  triangle = triangle,
  rampUp = rampUp,
  rampDown = rampDown,
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
-- Common Scales
--------------------------------------------------------------------------------

-- Make sure these are in sync with the scale names
-- Scales are defined by distance to the next step
local scaleDefinitions = {
  {2,2,1,2,2,2,1}, -- Major (Ionian mode)
  {2,1,2,2,1,2,2}, -- Minor (Aeolian mode)
  {2,1,2,2,2,1,2}, -- Dorian mode
  {1,2,2,2,1,2,2}, -- Phrygian mode
  {2,2,2,1,2,2,1}, -- Lydian mode
  {2,2,1,2,2,1,2}, -- Mixolydian mode
  {1,2,2,1,2,2,2}, -- Locrian mode
  {2,2,2,1,2,1,2}, -- Acoustic
  {2,1,2,1,1,3,2}, -- Blues
  {1,2,1,3,1,2,2}, -- Alterated
  {2,2,3,2,3}, -- Major Pentatonic
  {3,2,2,3,2}, -- Minor Pentatonic
  {3}, -- Diminished
  {2}, -- Whole tone scale
  {1}, -- Chomatic
}

local scaleNames = {
  "Major (Ionian)",
  "Minor (Aeolian)",
  "Dorian",
  "Phrygian",
  "Lydian",
  "Mixolydian",
  "Locrian",
  "Acoustic",
  "Blues",
  "Alterated",
  "Major Pentatonic",
  "Minor Pentatonic",
  "Diminished",
  "Whole tone",
  "Chomatic",
}

local scales = {
  getScaleDefinitions = function()
    return scaleDefinitions
  end,

  getScaleNames = function()
    return scaleNames
  end,

  createScale = function(scaleDefinition, rootNote, maxNote)
    if type(maxNote) ~= "number" then
      maxNote = 128
    end
    local scale = {}
    -- Find notes for scale
    local pos = 1
    while rootNote < maxNote do
      table.insert(scale, rootNote)
      rootNote = rootNote + scaleDefinition[pos]
      pos = pos + 1
      if pos > #scaleDefinition then
        pos = 1
      end
    end
    return scale
  end
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

----------------------------------------------------------------------------------
-- Motion Sequencer - Listens for incoming note events (rythm) on note number 0
----------------------------------------------------------------------------------

local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local backgroundColour = "202020" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "CFFFFE" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local knobFillColour = "E6D5B8" -- Light
local sliderColour = "5FB5FF"

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local sequencerResolution = 0.25 -- Fallback value
local baseNote = 60 -- Option
local octaveRange = 2 -- Option
local bipolar = true -- Option
local pitchOffsetPos = 1
local positionTable
local pitchOffsetTable
local pitchOffsetTableLength = 32
local scalesNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinitionIndex = #scalesNames
local activeScale = {} -- Holds the active scale
local factor = 2
local moveSpeed = 50
local motionTypes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Zero", "Random"}
local amountType = motionTypes[1]
local startModes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Zero", "Min", "Max", "Keep State", "Random"}
local startMode = startModes[6]
local activeVoices = {}

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetPitches()
  -- Reset position
  pitchOffsetPos = 1
  for i=1,pitchOffsetTableLength do
    positionTable:setValue(i, 0)
  end
  -- Reset pitches according to start mode
  if startMode == "Keep State" then
    return
  elseif startMode == "Ramp Up" then
    for i,v in ipairs(gem.rampUp(pitchOffsetTable.min, pitchOffsetTable.max, pitchOffsetTableLength)) do
      pitchOffsetTable:setValue(i, v)
    end
  elseif startMode == "Ramp Down" then
    for i,v in ipairs(gem.rampDown(pitchOffsetTable.min, pitchOffsetTable.max, pitchOffsetTableLength)) do
      pitchOffsetTable:setValue(i, v)
    end
  elseif startMode == "Triangle" then
    for i,v in ipairs(gem.triangle(pitchOffsetTable.min, pitchOffsetTable.max, pitchOffsetTableLength)) do
      pitchOffsetTable:setValue(i, v)
    end
  elseif startMode == "Random" then
    for i=1,pitchOffsetTableLength do
      pitchOffsetTable:setValue(i, gem.getRandom(pitchOffsetTable.min, pitchOffsetTable.max))
    end
  elseif startMode == "Min" then
    for i=1,pitchOffsetTableLength do
      pitchOffsetTable:setValue(i, pitchOffsetTable.min)
    end
  elseif startMode == "Max" then
    for i=1,pitchOffsetTableLength do
      pitchOffsetTable:setValue(i, pitchOffsetTable.max)
    end
  elseif startMode == "Even" then
    local minValue = pitchOffsetTable.min
    local maxValue = pitchOffsetTable.max
    for i=1,pitchOffsetTableLength do
      local val = minValue
      if i % 2 == 0 then
        val = maxValue
      end
      pitchOffsetTable:setValue(i, val)
    end
  elseif startMode == "Odd" then
    local minValue = pitchOffsetTable.min
    local maxValue = pitchOffsetTable.max
    for i=1,pitchOffsetTableLength do
      local val = maxValue
      if i % 2 == 0 then
        val = minValue
      end
      pitchOffsetTable:setValue(i, val)
    end
  else
    for i=1,pitchOffsetTableLength do
      positionTable:setValue(i, 0)
      pitchOffsetTable:setValue(i, 0)
    end
  end
end

local function setScale()
  local scaleDefinition = scaleDefinitions[scaleDefinitionIndex]
  local oneOctScale = scales.createScale(scaleDefinition, 0, 12)
  print("#oneOctScale", #oneOctScale)
  -- TODO Check octave range / bipolar before setting the table range
  local tableRange = #oneOctScale * octaveRange
  print("tableRange", tableRange)
  if bipolar then
    pitchOffsetTable:setRange(-tableRange, tableRange)
  else
    pitchOffsetTable:setRange(0, tableRange)
  end
  local startNote = baseNote
  if bipolar then
    startNote = startNote - (octaveRange * 12)
  end
  local maxNote = baseNote + (octaveRange * 12) + 1
  activeScale = scales.createScale(scaleDefinition, math.max(0, startNote), math.min(128, maxNote))
  print("#activeScale, startNote, maxNote", #activeScale, startNote, maxNote)
  resetPitches()
end

local function move(i)
  local middle = math.floor(pitchOffsetTableLength / 2)
  local direction = 1 -- TODO Param for setting start direction?
  local value = pitchOffsetTable:getValue(i)
  print("i, duration", i, duration)
  while isPlaying do
    local amount = i - 1
    if (i > middle and amountType == "Triangle") or amountType == "Ramp Down" then
      amount = (pitchOffsetTableLength - i)-- + 1
    elseif amountType == "Random" then
      amount = gem.getRandom(pitchOffsetTableLength) - 1
    elseif amountType == "Zero" or (amountType == "Even" and i % 2 == 0) or (amountType == "Odd" and i % 2 > 0) then
      amount = 0
    end
    local min = pitchOffsetTable.min
    local max = pitchOffsetTable.max
    local duration = moveSpeed + (amount * factor) -- TODO Param for operator?
    pitchOffsetTable:setValue(i, value)
    value = gem.inc(value, direction)
    if value < min then
      if true or gem.getRandomBoolean() then
        value = min
        direction = 1
        --print("Change direction", direction)
      else
        value = max
      end
      --print("Reset value", value)
    elseif value > max then
      if true or gem.getRandomBoolean() then
        value = max
        direction = -1
        --print("Change direction", direction)
      else
        value = min
      end
      --print("Reset value", value)
    end
    local valueBeforeWait = pitchOffsetTable:getValue(i)
    wait(duration)
    -- If value has been manually changed during the wait, we continue from that value
    if valueBeforeWait ~= pitchOffsetTable:getValue(i) then
      value = pitchOffsetTable:getValue(i)
    end
  end
end

local function getNote()
  -- TODO Find pitch offset
  --pitchOffsetPos = gem.getRandom(1, pitchOffsetTableLength)
  print("pitchOffsetTable:getValue(pitchOffsetPos), pitchOffsetPos", pitchOffsetTable:getValue(pitchOffsetPos), pitchOffsetPos)
  for i=1,pitchOffsetTableLength do
    local val = 0
    if i == pitchOffsetPos then
      val = 1
    end
    positionTable:setValue(i, val)
  end
  local scalePos = pitchOffsetTable:getValue(pitchOffsetPos) + 1
  if pitchOffsetTable.min < 0 then
    scalePos = scalePos + math.abs(pitchOffsetTable.min)
  end
  print("#activeScale, scalePos", #activeScale, scalePos)
  local note = activeScale[scalePos]
  pitchOffsetPos = gem.inc(pitchOffsetPos, 1, pitchOffsetTableLength)
  print("pitchOffsetPos", pitchOffsetPos)
  return note
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  for i=1,pitchOffsetTableLength do
    spawn(move, i)
  end
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetPitches()
end

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

local sequencerPanel = Panel("MotionSequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 0
sequencerPanel.y = 0
sequencerPanel.width = 720
sequencerPanel.height = 30

local notePanel = Panel("Notes")
notePanel.backgroundColour = "606060"
notePanel.x = sequencerPanel.x
notePanel.y = sequencerPanel.y + sequencerPanel.height
notePanel.width = sequencerPanel.width
notePanel.height = 270

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("Label")
sequencerLabel.text = "Motion Sequencer Input"
sequencerLabel.tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.position = {0,0}
sequencerLabel.size = {sequencerPanel.width,30}

local channels = {"Omni"}
for j=1,16 do
  table.insert(channels, "" .. j)
end

local channelInput = sequencerPanel:Menu("ChannelInput", channels)
channelInput.tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through"
channelInput.arrowColour = menuArrowColour
channelInput.showLabel = false
channelInput.backgroundColour = menuBackgroundColour
channelInput.textColour = widgetTextColour
channelInput.size = {90,22}
channelInput.x = sequencerPanel.width - channelInput.width - 5
channelInput.y = 5

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local noteLabel = notePanel:Label("NoteLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Note setup"
noteLabel.alpha = 0.5
noteLabel.fontSize = 16
noteLabel.backgroundColour = labelBackgoundColour
noteLabel.textColour = labelTextColour
noteLabel.width = sequencerPanel.width
noteLabel.height = 18
noteLabel.x = 0
noteLabel.y = 0

positionTable = notePanel:Table("Position", pitchOffsetTableLength, 0, 0, 1, true)
positionTable.enabled = false
positionTable.persistent = false
positionTable.fillStyle = "solid"
positionTable.backgroundColour = widgetTextColour
positionTable.sliderColour = "green"
positionTable.width = notePanel.width
positionTable.height = 6
positionTable.x = 0
positionTable.y = noteLabel.y + noteLabel.height

pitchOffsetTable = notePanel:Table("PitchOffset", pitchOffsetTableLength, 0, -24, 24, true)
pitchOffsetTable.persistent = false
--pitchOffsetTable.enabled = false
--pitchOffsetTable.drawInnerEdge = false
pitchOffsetTable.tooltip = "Set pitch offset"
pitchOffsetTable.showPopupDisplay = true
pitchOffsetTable.fillStyle = "solid"
pitchOffsetTable.sliderColour = sliderColour
pitchOffsetTable.width = notePanel.width
pitchOffsetTable.height = 160
pitchOffsetTable.x = 0
pitchOffsetTable.y = positionTable.y + positionTable.height

local noteWidgetHeight = 20
local noteWidgetWidth = 130
local noteWidgetRowSpacing = 5
local noteWidgetCellSpacing = 15
local firstRowY = pitchOffsetTable.y + pitchOffsetTable.height + 5
local secondRowY = firstRowY + noteWidgetHeight + noteWidgetRowSpacing
local thirdRowY = secondRowY + noteWidgetHeight + noteWidgetRowSpacing

local amountTypeMenu = notePanel:Menu("AmountType", motionTypes)
amountTypeMenu.displayName = "Amount Type"
amountTypeMenu.tooltip = "Amount type - Ramp Up means slower for every step (depending on factor)"
--amountTypeMenu.showLabel = false
amountTypeMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
amountTypeMenu.width = noteWidgetWidth
amountTypeMenu.x = noteWidgetCellSpacing
amountTypeMenu.y = firstRowY
amountTypeMenu.backgroundColour = menuBackgroundColour
amountTypeMenu.textColour = menuTextColour
amountTypeMenu.arrowColour = menuArrowColour
amountTypeMenu.outlineColour = menuOutlineColour
amountTypeMenu.changed = function(self)
  amountType = self.selectedText
  --print("amountType", amountType)
end

local startModeMenu = notePanel:Menu("StartMode", startModes)
startModeMenu.displayName = "Start Mode"
startModeMenu.selected = gem.getIndexFromValue(startMode, startModes)
startModeMenu.tooltip = "Start mode controls the table reset"
--startModeMenu.showLabel = false
startModeMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
startModeMenu.width = noteWidgetWidth
startModeMenu.x = amountTypeMenu.x + amountTypeMenu.width + 5
startModeMenu.y = firstRowY
startModeMenu.backgroundColour = menuBackgroundColour
startModeMenu.textColour = menuTextColour
startModeMenu.arrowColour = menuArrowColour
startModeMenu.outlineColour = menuOutlineColour
startModeMenu.changed = function(self)
  startMode = self.selectedText
  --print("startMode", startMode)
  resetPitches()
end

local scaleMenu = notePanel:Menu("Scale", scalesNames)
scaleMenu.selected = #scalesNames
scaleMenu.displayName = "Scale"
scaleMenu.tooltip = "The scale to use for automatic motion"
--scaleMenu.showLabel = false
scaleMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
scaleMenu.width = noteWidgetWidth
scaleMenu.x = startModeMenu.x + startModeMenu.width + noteWidgetCellSpacing
scaleMenu.y = firstRowY
scaleMenu.backgroundColour = menuBackgroundColour
scaleMenu.textColour = menuTextColour
scaleMenu.arrowColour = menuArrowColour
scaleMenu.outlineColour = menuOutlineColour
scaleMenu.changed = function(self)
  scaleDefinitionIndex = self.value
  setScale()
end

local noteInput = notePanel:NumBox("BaseNote", baseNote, 0, 127, true)
--noteInput.enabled = false
--noteInput.showLabel = false
noteInput.displayName = "Base Note"
noteInput.tooltip = "Set the root note"
noteInput.unit = Unit.MidiKey
noteInput.backgroundColour = menuBackgroundColour
noteInput.textColour = menuTextColour
noteInput.height = noteWidgetHeight
noteInput.width = noteWidgetWidth
noteInput.x = scaleMenu.x
noteInput.y = thirdRowY
noteInput.changed = function(self)
  baseNote = self.value
  setScale()
end

local octaveRangeInput = notePanel:NumBox("OctaveRange", octaveRange, 1, 4, true)
octaveRangeInput.displayName = "Octave Range"
octaveRangeInput.tooltip = "Set the octave range"
octaveRangeInput.backgroundColour = menuBackgroundColour
octaveRangeInput.textColour = menuTextColour
octaveRangeInput.height = noteWidgetHeight
octaveRangeInput.width = noteWidgetWidth
octaveRangeInput.x = noteInput.x + noteInput.width + 5
octaveRangeInput.y = secondRowY
octaveRangeInput.changed = function(self)
  octaveRange = self.value
  setScale()
end

local bipolarButton = notePanel:OnOffButton("Bipolar", bipolar)
bipolarButton.backgroundColourOff = backgroundColourOff
bipolarButton.backgroundColourOn = backgroundColourOn
bipolarButton.textColourOff = textColourOff
bipolarButton.textColourOn = textColourOn
bipolarButton.displayName = "Bipolar"
bipolarButton.width = noteWidgetWidth
bipolarButton.height = noteWidgetHeight
bipolarButton.x = scaleMenu.x + scaleMenu.width + 5
bipolarButton.y = firstRowY
bipolarButton.changed = function(self)
  bipolar = self.value
  setScale()
end

local pitchOffsetTableLengthInput = notePanel:NumBox("PitchOffsetTableLength", pitchOffsetTableLength, 2, 128, true)
pitchOffsetTableLengthInput.displayName = "Length"
pitchOffsetTableLengthInput.tooltip = "Set the table size"
pitchOffsetTableLengthInput.backgroundColour = menuBackgroundColour
pitchOffsetTableLengthInput.textColour = menuTextColour
pitchOffsetTableLengthInput.height = noteWidgetHeight
pitchOffsetTableLengthInput.width = noteWidgetWidth
pitchOffsetTableLengthInput.x = noteInput.x + noteInput.width + 5
pitchOffsetTableLengthInput.y = thirdRowY
pitchOffsetTableLengthInput.changed = function(self)
  pitchOffsetTableLength = self.value
  positionTable.length = pitchOffsetTableLength
  pitchOffsetTable.length = pitchOffsetTableLength
  pitchOffsetPos = 1 -- Reset pos on length change
  resetPitches()
end

local moveSpeedInput = notePanel:NumBox("MoveSpeed", moveSpeed, 1., 500., false)
moveSpeedInput.displayName = "Speed"
moveSpeedInput.tooltip = "Set the move speed"
moveSpeedInput.unit = Unit.MilliSeconds
moveSpeedInput.backgroundColour = menuBackgroundColour
moveSpeedInput.textColour = menuTextColour
moveSpeedInput.height = noteWidgetHeight
moveSpeedInput.width = noteWidgetWidth
moveSpeedInput.x = noteWidgetCellSpacing--scaleMenu.x + scaleMenu.width + noteWidgetCellSpacing
moveSpeedInput.y = thirdRowY
moveSpeedInput.changed = function(self)
  moveSpeed = self.value
end

local factorInput = notePanel:NumBox("Factor", factor, 0., 30., false)
factorInput.displayName = "Speed Factor"
factorInput.tooltip = "Set the factor of slowdown or spedup per step"
factorInput.backgroundColour = menuBackgroundColour
factorInput.textColour = menuTextColour
factorInput.height = noteWidgetHeight
factorInput.width = noteWidgetWidth
factorInput.x = moveSpeedInput.x + moveSpeedInput.width + 5
factorInput.y = thirdRowY
factorInput.changed = function(self)
  factor = self.value
end

local xySpeedFactor = notePanel:XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = bipolarButton.x + bipolarButton.width + noteWidgetCellSpacing
xySpeedFactor.width = noteWidgetWidth
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

local function noteIsPlaying(note)
  for _,v in ipairs(activeVoices) do
    if v.event.note == note then
      return true
    end
  end
  return false
end

local function isTrigger(e)
  local channel = channelInput.value - 1
  local isListeningForEvent = channel == 0 or channel == e.channel
  local isTrigger = e.note == 0 -- Note 0 is used as trigger
  return isTrigger and isListeningForEvent
end

local function handleTrigger(e)
  e.note = getNote()
  if noteIsPlaying(e.note) == false then
    startPlaying()
    local id = postEvent(e)
    table.insert(activeVoices, {id=id,event=e})
    print("Add active voice on note/channel", e.note, e.channel)
  end
end

local function handleReleaseTrigger(e)
  for i,v in ipairs(activeVoices) do
    if v.event.channel == e.channel then
      releaseVoice(v.id)
      table.remove(activeVoices, i)
      print("Release active voice on channel", v.event.channel)
    end
  end
end

function onInit()
  print("Init sequencer")
  setScale()
end

function onNote(e)
  if isTrigger(e) then
    handleTrigger(e)
  else
    postEvent(e)
  end
end

function onRelease(e)
  if isTrigger(e) then
    handleReleaseTrigger(e)
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start == true then
    startPlaying()
  else
    stopPlaying()
  end
end
