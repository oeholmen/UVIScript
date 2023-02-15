-- modular/rythmicMotionsTrigger -- 
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
-- Functions for creating an positioning widgets
--------------------------------------------------------------------------------

local widgetNameIndex = 1

local widgetDefaults = {
  panel = nil,
  width = 100,
  height = 20,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 5,
  ySpacing = 5,
}

local widgetColours = {
  backgroundColour = "202020",
  widgetBackgroundColour = "01011F", -- Dark
  menuBackgroundColour = "01011F", -- widgetBackgroundColour
  widgetTextColour = "9f02ACFE", -- Light
  labelTextColour = "black", -- Light
  labelBackgoundColour = "CFFFFE",
  menuArrowColour = "66AEFEFF", -- labelTextColour
  menuOutlineColour = "5f9f02ACFE", -- widgetTextColour
  menuTextColour = "#9f02ACFE",
  backgroundColourOff = "ff084486",
  backgroundColourOn = "ff02ACFE",
  textColourOff = "ff22FFFF",
  textColourOn = "efFFFFFF",
}

local function getWidgetValue(value, default)
  if type(value) == "nil" then
    return default
  end
  return value
end

local function setPanel(panel)
  widgetDefaults.panel = panel
end

local function xOffset(val)
  widgetDefaults.xOffset = val
end

local function yOffset(val)
  widgetDefaults.yOffset = val
end

local function xSpacing(val)
  widgetDefaults.xSpacing = val
end

local function ySpacing(val)
  widgetDefaults.ySpacing = val
end

local function widthDefault(val)
  widgetDefaults.width = val
end

local function heightDefault(val)
  widgetDefaults.height = val
end

local function setColour(key, color)
  widgetColours[key] = color
end

local function getColour(key)
  return widgetColours[key]
end

local function posSide(widget)
  return widget.x + widget.width + widgetDefaults.xSpacing
end

local function posUnder(widget)
  return widget.y + widget.height + widgetDefaults.ySpacing
end

local function setWidgetDefaults(settings)
  widgetDefaults.width = getWidgetValue(settings.width, widgetDefaults.width)
  widgetDefaults.height = getWidgetValue(settings.height, widgetDefaults.height)
  widgetDefaults.xOffset = getWidgetValue(settings.xOffset, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getWidgetValue(settings.yOffset, widgetDefaults.yOffset)
  widgetDefaults.xSpacing = getWidgetValue(settings.xSpacing, widgetDefaults.xSpacing)
  widgetDefaults.ySpacing = getWidgetValue(settings.ySpacing, widgetDefaults.ySpacing)
end

local function getWidgetName(name)
  if type(name) == "nil" then
    name = "Widget" .. widgetNameIndex
    widgetNameIndex = widgetNameIndex + 1
  end
  return name
end

local function getWidgetX(options)
  if type(options.x) == "number" then
    return options.x
  end

  if type(options.col) == "number" then
    -- Calculate widget x position
    local col = options.col - 1
    local width = col * widgetDefaults.width
    local xSpacing = col * widgetDefaults.xSpacing
    return widgetDefaults.xOffset + width + xSpacing
  end

  return widgetDefaults.xSpacing
end

local function getWidgetY(options)
  if type(options.y) == "number" then
    return options.y
  end

  if type(options.row) == "number" then
    -- Calculate widget y position
    local row = options.row - 1
    local height = row * widgetDefaults.height
    local ySpacing = row * widgetDefaults.ySpacing
    return widgetDefaults.yOffset + height + ySpacing
  end

  return widgetDefaults.yOffset + widgetDefaults.ySpacing
end

local function getWidgetBounds(options)
  local x = getWidgetX(options)
  local y = getWidgetY(options)
  local w = getWidgetValue(options.width, widgetDefaults.width)
  local h = getWidgetValue(options.height, widgetDefaults.height)
  return {x, y, w, h}
end

local function getWidgetOptions(displayName, default, col, row, options)
  if type(default) == "table" then
    options = default
  else
    if type(options) == "nil" then
      options = {}
    end
    options.default = getWidgetValue(default, options.default)
    options.col = getWidgetValue(col, options.col)
    options.row = getWidgetValue(row, options.row)
  end
  options.name = getWidgetName(options.name)
  options.displayName = getWidgetValue(displayName, options.name)
  options.unit = getWidgetValue(options.unit, Unit.Generic)
  options.tooltip = getWidgetValue(options.tooltip, options.displayName)
  options.integer = getWidgetValue(options.integer, (unit == Unit.Percent))
  options.min = getWidgetValue(options.min, 0)
  options.default = getWidgetValue(options.default, options.min)
  if options.unit == Unit.Percent then
    options.max = getWidgetValue(options.max, 100)
  else
    options.max = getWidgetValue(options.max, 1)
  end
  return options
end

local function setOptional(widget, options)
  if type(options.changed) == "function" then
    widget.changed = options.changed
  end
  if type(options.alpha) == "number" then
    widget.alpha = options.alpha
  end
  if type(options.fontSize) == "number" then
    widget.fontSize = options.fontSize
  end
  if type(options.showLabel) == "boolean" then
    widget.showLabel = options.showLabel
  end
  if type(options.persistent) == "boolean" then
    widget.persistent = options.persistent
  end
end

local function numBox(displayName, default, col, row, options)
  options = getWidgetOptions(displayName, default, col, row, options)
  local widget = widgetDefaults.panel:NumBox(options.name, options.default, options.min, options.max, options.integer)
  widget.displayName = options.displayName
  widget.tooltip = options.tooltip
  widget.unit = options.unit
  widget.backgroundColour = widgetColours.widgetBackgroundColour
  widget.textColour = widgetColours.widgetTextColour
  widget.bounds = getWidgetBounds(options)
  setOptional(widget, options)
  return widget
end

local function menu(displayName, default, items, col, row, options)
  options = getWidgetOptions(displayName, default, col, row, options)
  local widget = widgetDefaults.panel:Menu(options.name, items)
  widget.selected = options.default
  widget.displayName = options.displayName
  widget.tooltip = options.tooltip
  widget.backgroundColour = widgetColours.menuBackgroundColour
  widget.textColour = widgetColours.menuTextColour
  widget.arrowColour = widgetColours.menuArrowColour
  widget.outlineColour = widgetColours.menuOutlineColour
  widget.bounds = getWidgetBounds(options)
  setOptional(widget, options)
  return widget
end

local function button(displayName, default, col, row, options)
  options = getWidgetOptions(displayName, default, col, row, options)
  local widget = widgetDefaults.panel:OnOffButton(options.name, (options.default == true))
  widget.backgroundColourOff = widgetColours.backgroundColourOff
  widget.backgroundColourOn = widgetColours.backgroundColourOn
  widget.textColourOff = widgetColours.textColourOff
  widget.textColourOn = widgetColours.textColourOn
  widget.displayName = options.displayName
  widget.tooltip = options.tooltip
  widget.unit = options.unit
  widget.bounds = getWidgetBounds(options)
  setOptional(widget, options)
  return widget
end

local function label(displayName, col, row, options)
  options = getWidgetOptions(displayName, nil, col, row, options)
  local widget = widgetDefaults.panel:Label("Label")
  widget.text = options.displayName
  widget.tooltip = options.tooltip
  widget.backgroundColour = widgetColours.labelBackgoundColour
  widget.textColour = widgetColours.labelTextColour
  widget.bounds = getWidgetBounds(options)
  setOptional(widget, options)
  return widget
end

local widgets = {
  setColour = setColour,
  getColour = getColour,
  setPanel = setPanel,
  setWidgetDefaults = setWidgetDefaults,
  xOffset = xOffset,
  yOffset = yOffset,
  xSpacing = xSpacing,
  ySpacing = ySpacing,
  widthDefault = widthDefault,
  heightDefault = heightDefault,
  posSide = posSide,
  posUnder = posUnder,
  button = button,
  label = label,
  menu = menu,
  numBox = numBox,
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

local function quantizeToClosest(beat)
  for i,v in ipairs(resolutionValues) do
    local currentValue = v
    local nextValue = resolutionValues[i+1]
    --print("beat, currentValue, nextValue", beat, currentValue, nextValue)
    if type(nextValue) == "nil" or beat == currentValue then
      --print("beat == currentValue or nextValue == nil", beat, currentValue, nextValue)
      return currentValue
    end
    if beat < currentValue and beat > nextValue then
      local diffCurrent = currentValue - beat
      local diffNext = beat - nextValue
      if diffCurrent < diffNext then
        --print("Return currentValue diffCurrent < diffNext", diffCurrent, diffNext)
        return currentValue
      else
        --print("Return nextValue diffNext < diffCurrent", diffNext, diffCurrent)
        return nextValue
      end
    end
  end
  return beat
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
-- Rythmic Motions - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

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
local sliderColour = "pink"--"5FB5FF"

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local tableRange = 16
local bipolar = true
local positionTable
local motionTable
local motionTableLength = 32
local channel = 1
local factor = 2
local factorMin = 0
local factorMax = 4
local moveSpeed = 25
local moveSpeedMin = 5
local moveSpeedMax = 250
local speedRandomizationAmount = 0
local speedTypes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Random"}
local speedType = speedTypes[1]
local startModes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Zero", "Min", "Max", "Keep State", "Random"}
local startMode = startModes[1]
local noteEventId = 0 -- Holds the index if the cell in the table that last triggered an event
local resolutionNames = resolutions.getResolutionNames()
local resolution = #resolutionNames
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local movingCells = {}
local voiceId = nil -- Holds the id of the created note event

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetTableValues()
  -- Reset event id
  noteEventId = 0
  -- Reset position
  for i=1,motionTableLength do
    positionTable:setValue(i, 0)
  end
  -- Reset pitches according to start mode
  if startMode == "Keep State" then
    return
  elseif startMode == "Ramp Up" then
    for i,v in ipairs(gem.rampUp(motionTable.min, motionTable.max, motionTableLength)) do
      motionTable:setValue(i, v)
    end
  elseif startMode == "Ramp Down" then
    for i,v in ipairs(gem.rampDown(motionTable.min, motionTable.max, motionTableLength)) do
      motionTable:setValue(i, v)
    end
  elseif startMode == "Triangle" then
    for i,v in ipairs(gem.triangle(motionTable.min, motionTable.max, motionTableLength)) do
      motionTable:setValue(i, v)
    end
  elseif startMode == "Random" then
    for i=1,motionTableLength do
      motionTable:setValue(i, gem.getRandom(motionTable.min, motionTable.max))
    end
  elseif startMode == "Min" then
    for i=1,motionTableLength do
      motionTable:setValue(i, motionTable.min)
    end
  elseif startMode == "Max" then
    for i=1,motionTableLength do
      motionTable:setValue(i, motionTable.max)
    end
  elseif startMode == "Even" then
    local minValue = motionTable.min
    local maxValue = motionTable.max
    for i=1,motionTableLength do
      local val = minValue
      if i % 2 == 0 then
        val = maxValue
      end
      motionTable:setValue(i, val)
    end
  elseif startMode == "Odd" then
    local minValue = motionTable.min
    local maxValue = motionTable.max
    for i=1,motionTableLength do
      local val = maxValue
      if i % 2 == 0 then
        val = minValue
      end
      motionTable:setValue(i, val)
    end
  else
    for i=1,motionTableLength do
      positionTable:setValue(i, 0)
      motionTable:setValue(i, 0)
    end
  end
end

local function setRange()
  if bipolar then
    motionTable:setRange(-tableRange, tableRange)
  else
    motionTable:setRange(0, tableRange)
  end
  resetTableValues()
end

local function move(i, uniqueId)
  local middle = math.floor(motionTableLength / 2)
  local direction = 1 -- TODO Param for setting start direction?
  local value = motionTable:getValue(i)
  while isPlaying and movingCells[i] == uniqueId do
    -- Send note event if value is min or max
    -- TODO Add params for triggers?
    if value == motionTable.min or value == motionTable.max then
      noteEventId = i
    end
    -- Increment value
    local amount = i - 1
    if (i > middle and speedType == "Triangle") or speedType == "Ramp Down" then
      amount = (motionTableLength - i)
    elseif speedType == "Random" then
      amount = gem.getRandom(motionTableLength) - 1
    elseif (speedType == "Even" and i % 2 == 0) or (speedType == "Odd" and i % 2 > 0) then
      amount = 0
    elseif speedType == "Even" and i == 1 then
      amount = i
    end
    local min = motionTable.min
    local max = motionTable.max
    local duration = gem.randomizeValue(moveSpeed, moveSpeedMin, moveSpeedMax, speedRandomizationAmount) + (amount * factor) -- TODO Param for operator?
    motionTable:setValue(i, value)
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
    local valueBeforeWait = motionTable:getValue(i)
    wait(duration)
    -- If value has been manually changed during the wait, we continue from that value
    if valueBeforeWait ~= motionTable:getValue(i) then
      value = motionTable:getValue(i)
    end
  end
end

local function startMoving()
  movingCells = {} -- Reset index to stop
  for i=1,motionTableLength do
    table.insert(movingCells, uniqueIndex)
    spawn(move, i, uniqueIndex)
    uniqueIndex = gem.inc(uniqueIndex)
  end
end

local function sequenceRunner()
  startMoving()
  while isPlaying do
    if noteEventId > 0 then
      -- Release the voice if active
      if type(voiceId) == "userdata" then
        releaseVoice(voiceId)
        voiceId = nil
        --print("Releasing trigger")
      end
      local velocity = 64
      voiceId = playNote(0, velocity, -1, nil, channel)
      --print("Creating trigger")
      -- Mark the position that initiated the event
      for i=1,motionTableLength do
        local value = 0
        if i == noteEventId then
          value = 1
        end
        positionTable:setValue(i, value)
      end
      noteEventId = 0 -- Reset event id
    end
    waitBeat(resolutions.getResolution(resolution))
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  run(sequenceRunner)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetTableValues()
  if type(voiceId) == "userdata" then
    releaseVoice(voiceId)
    voiceId = nil
    --print("Releasing trigger")
  end
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
notePanel.height = 250

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("Label")
sequencerLabel.text = "Rythmic Motions Trigger"
sequencerLabel.tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.position = {0,0}
sequencerLabel.size = {sequencerPanel.width,30}

widgets.setPanel(sequencerPanel)
widgets.widthDefault(100)
widgets.heightDefault(22)
widgets.xOffset((sequencerPanel.width / 2) + 45)
widgets.yOffset(5)

local channelInput = widgets.numBox('Channel', channel, 1, 1, {
  tooltip = "Send note events starting on this channel",
  min = 1,
  max = 16,
  integer = true,
})
channelInput.changed = function(self)
  channel = self.value
end

local autoplayButton = widgets.button('Auto Play', true, 2, 1, {
  tooltip = "Play automatically on transport",
})

local playButton = widgets.button('Play', false, 3, 1)
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

positionTable = notePanel:Table("Position", motionTableLength, 0, 0, 1, true)
positionTable.enabled = false
positionTable.persistent = false
positionTable.fillStyle = "solid"
positionTable.backgroundColour = widgetTextColour
positionTable.sliderColour = "green"
positionTable.width = notePanel.width
positionTable.height = 6
positionTable.x = 0
positionTable.y = 0

motionTable = notePanel:Table("MotionTable", motionTableLength, 0, -tableRange, tableRange, true)
motionTable.tooltip = "Events are triggered when the value hits max or min"
motionTable.showPopupDisplay = true
motionTable.fillStyle = "solid"
motionTable.sliderColour = sliderColour
motionTable.width = notePanel.width
motionTable.height = 160
motionTable.x = 0
motionTable.y = positionTable.y + positionTable.height

local noteWidgetHeight = 20
local noteWidgetWidth = 130
local noteWidgetRowSpacing = 5
local noteWidgetCellSpacing = 12
local firstRowY = motionTable.y + motionTable.height + noteWidgetRowSpacing
local secondRowY = firstRowY + noteWidgetHeight + noteWidgetRowSpacing
local thirdRowY = secondRowY + noteWidgetHeight + noteWidgetRowSpacing

widgets.setPanel(notePanel)
widgets.widthDefault(noteWidgetWidth)
widgets.xOffset(noteWidgetCellSpacing)
widgets.yOffset(firstRowY)
widgets.xSpacing(noteWidgetCellSpacing)
widgets.ySpacing(noteWidgetRowSpacing)

local speedTypeMenu = notePanel:Menu("SpeedType", speedTypes)
speedTypeMenu.displayName = "Speed Type"
speedTypeMenu.tooltip = "Set the speed type (depending on factor > 0) - Ramp Up = slower for every cell, Ramp Down = faster etc"
speedTypeMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
speedTypeMenu.width = noteWidgetWidth
speedTypeMenu.x = noteWidgetCellSpacing
speedTypeMenu.y = firstRowY
speedTypeMenu.backgroundColour = menuBackgroundColour
speedTypeMenu.textColour = menuTextColour
speedTypeMenu.arrowColour = menuArrowColour
speedTypeMenu.outlineColour = menuOutlineColour
speedTypeMenu.changed = function(self)
  speedType = self.selectedText
end

local startModeMenu = notePanel:Menu("StartMode", startModes)
startModeMenu.displayName = "Start Mode"
startModeMenu.selected = gem.getIndexFromValue(startMode, startModes)
startModeMenu.tooltip = "Start mode controls the table reset"
startModeMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
startModeMenu.width = noteWidgetWidth
startModeMenu.x = speedTypeMenu.x + speedTypeMenu.width + noteWidgetCellSpacing
startModeMenu.y = firstRowY
startModeMenu.backgroundColour = menuBackgroundColour
startModeMenu.textColour = menuTextColour
startModeMenu.arrowColour = menuArrowColour
startModeMenu.outlineColour = menuOutlineColour
startModeMenu.changed = function(self)
  startMode = self.selectedText
  resetTableValues()
end

local tableRangeInput = widgets.numBox("Range", tableRange, 1, 3, {
  min = 8,
  max = 128,
  integer = true,
  tooltip = "Set the table range - high range = fewer events, low range = more events",
})
tableRangeInput.changed = function(self)
  tableRange = self.value
  setRange()
end

local resolutionInput = notePanel:Menu("Quantize", resolutionNames)
resolutionInput.displayName = "Quantize"
resolutionInput.tooltip = "Event triggers are quantized to this resolution"
resolutionInput.selected = resolution
resolutionInput.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
resolutionInput.width = noteWidgetWidth
resolutionInput.backgroundColour = widgetBackgroundColour
resolutionInput.textColour = widgetTextColour
resolutionInput.arrowColour = menuArrowColour
resolutionInput.outlineColour = menuOutlineColour
resolutionInput.x = startModeMenu.x + startModeMenu.width + noteWidgetCellSpacing
resolutionInput.y = firstRowY
resolutionInput.changed = function(self)
  resolution = self.value
end

local bipolarButton = widgets.button("Bipolar", bipolar, 3, 3, {width = (noteWidgetWidth / 2) - (noteWidgetCellSpacing / 2)})
bipolarButton.changed = function(self)
  bipolar = self.value
  setRange()
end

local resetButton = widgets.button("Reset", false, nil, 3, {width = bipolarButton.width, x = widgets.posSide(bipolarButton)})
resetButton.changed = function(self)
  resetTableValues()
  startMoving()
  self.value = false
end

local motionTableLengthInput = widgets.numBox("Length", motionTableLength, 2, 3, {
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the table length",
})
motionTableLengthInput.changed = function(self)
  motionTableLength = self.value
  positionTable.length = motionTableLength
  motionTable.length = motionTableLength
  resetTableValues()
  startMoving()
end

local moveSpeedInput = widgets.numBox("Motion Speed", moveSpeed, 4, 1, {
  name = "MoveSpeed",
  min = moveSpeedMin,
  max = moveSpeedMax,
  tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller",
  unit = Unit.MilliSeconds,
})
moveSpeedInput.changed = function(self)
  moveSpeed = self.value
end

local factorInput = widgets.numBox("Speed Factor", factor, 4, 2, {
  name = "Factor",
  min = factorMin,
  max = factorMax,
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. Controlled by the Y-axis on the XY controller",
})
factorInput.changed = function(self)
  factor = self.value
end

local speedRandomizationAmountInput = widgets.numBox("Speed Rand", speedRandomizationAmount, 4, 3, {
  unit = Unit.Percent,
  tooltip = "Set the radomization amount applied to speed",
})
speedRandomizationAmountInput.changed = function(self)
  speedRandomizationAmount = self.value
end

local xySpeedFactor = notePanel:XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = moveSpeedInput.x + moveSpeedInput.width + noteWidgetCellSpacing
xySpeedFactor.width = noteWidgetWidth
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  uniqueIndex = 1
  setRange()
end

function onNote(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(true)
  end
end

function onRelease(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(false)
  end
end

function onTransport(start)
  if autoplayButton.value == true then
    playButton:setValue(start)
  end
end
