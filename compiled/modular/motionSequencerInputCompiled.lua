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
-- Functions for creating an positioning widgets
--------------------------------------------------------------------------------

local widgetNameIndex = 1

local widgetDefaults = {
  panel = Panel("DefaultPanel"),
  width = 100,
  height = 20,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
}

local widgetColours = {
  backgroundColour = "202020",
  widgetBackgroundColour = "01011F", -- Dark
  menuBackgroundColour = "01011F", -- widgetBackgroundColour
  widgetTextColour = "9f02ACFE", -- Light
  tableBackgroundColour = "202020",
  sliderColour = "5FB5FF", -- Table slider colour
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

local function getWidgetOptions(options, col, row, displayName, default)
  if type(options) ~= "table" then
    options = {}
  end
  options.default = getWidgetValue(default, options.default)
  options.col = getWidgetValue(col, options.col)
  options.row = getWidgetValue(row, options.row)
  options.name = getWidgetName(options.name)
  options.displayName = getWidgetValue(displayName, options.name)
  options.tooltip = getWidgetValue(options.tooltip, options.displayName)
  options.integer = getWidgetValue(options.integer, (options.unit == Unit.Percent))
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
  if type(options.unit) == "number" then
    widget.unit = options.unit
  end
  if type(options.showLabel) == "boolean" then
    widget.showLabel = options.showLabel
  end
  if type(options.persistent) == "boolean" then
    widget.persistent = options.persistent
  end
  if type(options.enabled) == "boolean" then
    widget.enabled = options.enabled
  end
  if type(options.showPopupDisplay) == "boolean" then
    widget.showPopupDisplay = options.showPopupDisplay
  end
  if type(options.fillStyle) == "string" then
    widget.fillStyle = options.fillStyle
  end
  if type(options.sliderColour) == "string" then
    widget.sliderColour = options.sliderColour
  end
end

local function setPanel(panel)
  widgetDefaults.panel = panel
end

local function getPanel(col, row, options, create)
  if type(col) == "number" or type(row) == "number" or type(col) == "table" or type(options) == "table" or create == true then
    if type(col) == "table" then
      options = col
      col = nil
    end
    options = getWidgetOptions(options, col, row)
    if create == true then
      widgetDefaults.panel = Panel(options.name)
    end
    widgetDefaults.panel.backgroundColour = widgetColours.backgroundColour
    widgetDefaults.panel.bounds = getWidgetBounds(options)
    setOptional(widgetDefaults.panel, options)
  end
  return widgetDefaults.panel
end

local widgets = {
  colours = widgetColours,
  setColour = setColour,
  getColour = getColour,
  setPanel = setPanel,
  getPanel = getPanel,
  setWidgetDefaults = setWidgetDefaults,
  xOffset = xOffset,
  yOffset = yOffset,
  xSpacing = xSpacing,
  ySpacing = ySpacing,
  widthDefault = widthDefault,
  heightDefault = heightDefault,
  posSide = posSide,
  posUnder = posUnder,
  panel = function(col, row, options)
    return getPanel(col, row, options, true)
  end,
  button = function(displayName, default, col, row, options)
    options = getWidgetOptions(options, col, row, displayName, default)
    local widget = widgetDefaults.panel:OnOffButton(options.name, (options.default == true))
    widget.backgroundColourOff = widgetColours.backgroundColourOff
    widget.backgroundColourOn = widgetColours.backgroundColourOn
    widget.textColourOff = widgetColours.textColourOff
    widget.textColourOn = widgetColours.textColourOn
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.bounds = getWidgetBounds(options)
    setOptional(widget, options)
    return widget
  end,
  label = function(displayName, col, row, options)
    options = getWidgetOptions(options, col, row, displayName)
    local widget = widgetDefaults.panel:Label("Label")
    widget.text = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.labelBackgoundColour
    widget.textColour = widgetColours.labelTextColour
    widget.bounds = getWidgetBounds(options)
    setOptional(widget, options)
    return widget
  end,
  menu = function(displayName, default, items, col, row, options)
    options = getWidgetOptions(options, col, row, displayName, default)
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
  end,
  numBox = function(displayName, default, col, row, options)
    options = getWidgetOptions(options, col, row, displayName, default)
    local widget = widgetDefaults.panel:NumBox(options.name, options.default, options.min, options.max, options.integer)
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.widgetBackgroundColour
    widget.textColour = widgetColours.widgetTextColour
    widget.bounds = getWidgetBounds(options)
    setOptional(widget, options)
    return widget
  end,
  table = function(size, default, col, row, options)
    options = getWidgetOptions(options, col, row, nil, default)
    local widget = widgetDefaults.panel:Table(options.name, size, options.default, options.min, options.max, options.integer)
    widget.fillStyle = "solid"
    widget.backgroundColour = widgetColours.tableBackgroundColour
    widget.sliderColour = widgetColours.sliderColour
    widget.bounds = getWidgetBounds(options)
    setOptional(widget, options)
    return widget
  end,
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

-- Quantize the given beat to the closest recognized resolution value
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
-- Common functions for processors using table motion
--------------------------------------------------------------------------------

local speedTypes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Random"}
local startModes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Zero", "Min", "Max", "Keep State", "Random"}

local motionOptions = {
  factor = 2,
  factorMin = 0,
  factorMax = 4,
  moveSpeed = 25,
  moveSpeedMin = 5,
  moveSpeedMax = 250,
  speedType = speedTypes[1],
  startMode = startModes[1],
  speedRandomizationAmount = 0,
  tableLength = 32,
}

local function setTableZero(theTable)
    for i=1,theTable.length do
      theTable:setValue(i, 0)
    end  
end

local function setStartMode(theTable)
  -- Reset table according to start mode
  if motionOptions.startMode == "Keep State" then
    return
  elseif motionOptions.startMode == "Ramp Up" then
    for i,v in ipairs(gem.rampUp(theTable.min, theTable.max, theTable.length)) do
      theTable:setValue(i, v)
    end
  elseif motionOptions.startMode == "Ramp Down" then
    for i,v in ipairs(gem.rampDown(theTable.min, theTable.max, theTable.length)) do
      theTable:setValue(i, v)
    end
  elseif motionOptions.startMode == "Triangle" then
    for i,v in ipairs(gem.triangle(theTable.min, theTable.max, theTable.length)) do
      theTable:setValue(i, v)
    end
  elseif motionOptions.startMode == "Random" then
    for i=1,theTable.length do
      theTable:setValue(i, gem.getRandom(theTable.min, theTable.max))
    end
  elseif motionOptions.startMode == "Min" then
    for i=1,theTable.length do
      theTable:setValue(i, theTable.min)
    end
  elseif motionOptions.startMode == "Max" then
    for i=1,theTable.length do
      theTable:setValue(i, theTable.max)
    end
  elseif motionOptions.startMode == "Even" then
    local minValue = theTable.min
    local maxValue = theTable.max
    for i=1,theTable.length do
      local val = minValue
      if i % 2 == 0 then
        val = maxValue
      end
      theTable:setValue(i, val)
    end
  elseif motionOptions.startMode == "Odd" then
    local minValue = theTable.min
    local maxValue = theTable.max
    for i=1,theTable.length do
      local val = maxValue
      if i % 2 == 0 then
        val = minValue
      end
      theTable:setValue(i, val)
    end
  else
    setTableZero(theTable)
  end
end

local function moveTable(theTable, i, value, direction)
  local middle = math.floor(theTable.length / 2)
  -- Increment value
  local amount = i - 1
  if (i > middle and motionOptions.speedType == "Triangle") or motionOptions.speedType == "Ramp Down" then
    amount = (theTable.length - i)
  elseif motionOptions.speedType == "Random" then
    amount = gem.getRandom(theTable.length) - 1
  elseif (motionOptions.speedType == "Even" and i % 2 == 0) or (motionOptions.speedType == "Odd" and i % 2 > 0) then
    amount = 0
  elseif motionOptions.speedType == "Even" and i == 1 then
    amount = i
  end
  local min = theTable.min
  local max = theTable.max
  local duration = gem.randomizeValue(motionOptions.moveSpeed, motionOptions.moveSpeedMin, motionOptions.moveSpeedMax, motionOptions.speedRandomizationAmount) + (amount * motionOptions.factor) -- TODO Param for operator?
  theTable:setValue(i, value)
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
  local valueBeforeWait = theTable:getValue(i)
  wait(duration)
  -- If value has been manually changed during the wait, we continue from that value
  if valueBeforeWait ~= theTable:getValue(i) then
    value = theTable:getValue(i)
  end
  return value, direction
end

local tableMotion = {
  setRange = function(theTable, tableRange, bipolar)
    if bipolar then
      theTable:setRange(-tableRange, tableRange)
    else
      theTable:setRange(0, tableRange)
    end
  end,
  moveTable = moveTable,
  setStartMode = setStartMode,
  setTableZero = setTableZero,
  speedTypes = speedTypes,
  startModes = startModes,
  options = motionOptions
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
local motionTable
local scalesNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinitionIndex = #scalesNames
local activeScale = {} -- Holds the active scale
local activeVoices = {}
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local movingCells = {}

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetPitches()
  tableMotion.setTableZero(positionTable)
  tableMotion.setStartMode(motionTable, startMode)
end

local function setScale()
  local scaleDefinition = scaleDefinitions[scaleDefinitionIndex]
  local oneOctScale = scales.createScale(scaleDefinition, 0, 12)
  --print("#oneOctScale", #oneOctScale)
  -- Check octave range / bipolar before setting the table range
  local tableRange = #oneOctScale * octaveRange
  --print("tableRange", tableRange)
  tableMotion.setRange(motionTable, tableRange, bipolar)
  local startNote = baseNote
  if bipolar then
    startNote = startNote - (octaveRange * 12)
  end
  local maxNote = baseNote + (octaveRange * 12) + 1
  activeScale = scales.createScale(scaleDefinition, math.max(0, startNote), math.min(128, maxNote))
  --print("#activeScale, startNote, maxNote", #activeScale, startNote, maxNote)
  resetPitches()
end

local function move(i, uniqueId)
  local direction = 1
  local value = motionTable:getValue(i)
  while isPlaying and movingCells[i] == uniqueId do
    value, direction = tableMotion.moveTable(motionTable, i, value, direction)
  end
end

local function startMoving()
  movingCells = {} -- Reset index to stop
  for i=1,motionTable.length do
    table.insert(movingCells, uniqueIndex)
    spawn(move, i, uniqueIndex)
    uniqueIndex = gem.inc(uniqueIndex)
  end
end

local function getNote()
  for i=1,motionTable.length do
    local val = 0
    if i == pitchOffsetPos then
      val = 1
    end
    positionTable:setValue(i, val)
  end
  local scalePos = motionTable:getValue(pitchOffsetPos) + 1
  if motionTable.min < 0 then
    scalePos = scalePos + math.abs(motionTable.min)
  end
  --print("#activeScale, scalePos", #activeScale, scalePos)
  local note = activeScale[scalePos]
  pitchOffsetPos = gem.inc(pitchOffsetPos, 1, motionTable.length)
  --print("pitchOffsetPos", pitchOffsetPos)
  return note
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  startMoving()
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetPitches()
end

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

local sequencerPanel = widgets.getPanel(1, 1, {
  width = 720,
  height = 30,
})

widgets.label("Motion Sequencer Input", 1, 1, {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

local channels = {"Omni"}
for j=1,16 do
  table.insert(channels, "" .. j)
end

local channelInput = widgets.menu("Channel", 1, channels, 1, 1, {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  width = 90,
  x = sequencerPanel.width - 95,
  y = 5
})

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

widgets.setColour('backgroundColour', "606060")

local notePanel = widgets.panel(1, 1, {
  x = sequencerPanel.x,
  y = widgets.posUnder(sequencerPanel),
  width = sequencerPanel.width,
  height = 255,
})

positionTable = notePanel:Table("Position", tableMotion.options.tableLength, 0, 0, 1, true)
positionTable.enabled = false
positionTable.persistent = false
positionTable.fillStyle = "solid"
positionTable.backgroundColour = widgetTextColour
positionTable.sliderColour = "green"
positionTable.width = notePanel.width
positionTable.height = 6
positionTable.x = 0
positionTable.y = 0

motionTable = notePanel:Table("PitchOffset", tableMotion.options.tableLength, 0, -24, 24, true)
motionTable.tooltip = "Set pitch offset"
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
local noteWidgetCellSpacing = 15
local firstRowY = motionTable.y + motionTable.height + 10
local secondRowY = firstRowY + noteWidgetHeight + noteWidgetRowSpacing
local thirdRowY = secondRowY + noteWidgetHeight + noteWidgetRowSpacing

local speedTypeMenu = notePanel:Menu("SpeedType", tableMotion.speedTypes)
speedTypeMenu.displayName = "Speed Type"
speedTypeMenu.tooltip = "Set the speed type (depending on factor > 0) - Ramp Up = slower for every cell, Ramp Down = faster etc"
speedTypeMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
speedTypeMenu.width = noteWidgetWidth
speedTypeMenu.x = 10
speedTypeMenu.y = firstRowY
speedTypeMenu.backgroundColour = menuBackgroundColour
speedTypeMenu.textColour = menuTextColour
speedTypeMenu.arrowColour = menuArrowColour
speedTypeMenu.outlineColour = menuOutlineColour
speedTypeMenu.changed = function(self)
  tableMotion.options.speedType = self.selectedText
end

local startModeMenu = notePanel:Menu("StartMode", tableMotion.startModes)
startModeMenu.displayName = "Start Mode"
startModeMenu.tooltip = "Start mode controls the table reset"
startModeMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
startModeMenu.width = noteWidgetWidth
startModeMenu.x = speedTypeMenu.x + speedTypeMenu.width + 5
startModeMenu.y = firstRowY
startModeMenu.backgroundColour = menuBackgroundColour
startModeMenu.textColour = menuTextColour
startModeMenu.arrowColour = menuArrowColour
startModeMenu.outlineColour = menuOutlineColour
startModeMenu.changed = function(self)
  tableMotion.options.startMode = self.selectedText
  resetPitches()
end

local scaleMenu = notePanel:Menu("Scale", scalesNames)
scaleMenu.selected = #scalesNames
scaleMenu.displayName = "Scale"
scaleMenu.tooltip = "The scale to use for automatic motion"
scaleMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
scaleMenu.width = noteWidgetWidth - 36
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
noteInput.showLabel = false
noteInput.displayName = "Base Note"
noteInput.tooltip = "Set the root note"
noteInput.unit = Unit.MidiKey
noteInput.backgroundColour = menuBackgroundColour
noteInput.textColour = menuTextColour
noteInput.height = noteWidgetHeight
noteInput.width = 36
noteInput.x = scaleMenu.x + scaleMenu.width
noteInput.y = secondRowY
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
octaveRangeInput.x = scaleMenu.x-- + noteInput.width + 5
octaveRangeInput.y = thirdRowY
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
bipolarButton.x = speedTypeMenu.x-- + scaleMenu.width + 5
bipolarButton.y = thirdRowY
bipolarButton.changed = function(self)
  bipolar = self.value
  setScale()
end

local motionTableLengthInput = notePanel:NumBox("PitchOffsetTableLength", tableMotion.options.tableLength, 2, 128, true)
motionTableLengthInput.displayName = "Length"
motionTableLengthInput.tooltip = "Set the table size"
motionTableLengthInput.backgroundColour = menuBackgroundColour
motionTableLengthInput.textColour = menuTextColour
motionTableLengthInput.height = noteWidgetHeight
motionTableLengthInput.width = noteWidgetWidth
motionTableLengthInput.x = startModeMenu.x-- + noteInput.width + 5
motionTableLengthInput.y = thirdRowY
motionTableLengthInput.changed = function(self)
  tableMotion.options.tableLength = self.value
  positionTable.length = tableMotion.options.tableLength
  motionTable.length = tableMotion.options.tableLength
  pitchOffsetPos = 1 -- Reset pos on length change
  resetPitches()
  startMoving()
end

local moveSpeedInput = notePanel:NumBox("MoveSpeed", tableMotion.options.moveSpeed, tableMotion.options.moveSpeedMin, tableMotion.options.moveSpeedMax, false)
moveSpeedInput.displayName = "Motion Speed"
moveSpeedInput.tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller"
moveSpeedInput.unit = Unit.MilliSeconds
moveSpeedInput.backgroundColour = menuBackgroundColour
moveSpeedInput.textColour = menuTextColour
moveSpeedInput.height = noteWidgetHeight
moveSpeedInput.width = noteWidgetWidth
moveSpeedInput.x = noteInput.x + noteInput.width + noteWidgetCellSpacing
moveSpeedInput.y = firstRowY
moveSpeedInput.changed = function(self)
  tableMotion.options.moveSpeed = self.value
end

local factorInput = notePanel:NumBox("Factor", tableMotion.options.factor, tableMotion.options.factorMin, tableMotion.options.factorMax, false)
factorInput.displayName = "Speed Factor"
factorInput.tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. Controlled by the Y-axis on the XY controller"
factorInput.backgroundColour = menuBackgroundColour
factorInput.textColour = menuTextColour
factorInput.height = noteWidgetHeight
factorInput.width = noteWidgetWidth
factorInput.x = moveSpeedInput.x
factorInput.y = secondRowY
factorInput.changed = function(self)
  tableMotion.options.factor = self.value
end

local speedRandomizationAmountInput = notePanel:NumBox("SpeedRandomizationAmount", tableMotion.options.speedRandomizationAmount, 0, 100, true)
speedRandomizationAmountInput.unit = Unit.Percent
speedRandomizationAmountInput.displayName = "Speed Rand"
speedRandomizationAmountInput.tooltip = "Set the radomization amount applied to speed"
speedRandomizationAmountInput.backgroundColour = menuBackgroundColour
speedRandomizationAmountInput.textColour = menuTextColour
speedRandomizationAmountInput.height = noteWidgetHeight
speedRandomizationAmountInput.width = noteWidgetWidth
speedRandomizationAmountInput.x = factorInput.x
speedRandomizationAmountInput.y = thirdRowY
speedRandomizationAmountInput.changed = function(self)
  tableMotion.options.speedRandomizationAmount = self.value
end

local xySpeedFactor = notePanel:XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = speedRandomizationAmountInput.x + speedRandomizationAmountInput.width + noteWidgetCellSpacing
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
    --print("Add active voice on note/channel", e.note, e.channel)
  end
end

local function handleReleaseTrigger(e)
  for i,v in ipairs(activeVoices) do
    if v.event.channel == e.channel then
      releaseVoice(v.id)
      table.remove(activeVoices, i)
      --print("Release active voice on channel", v.event.channel)
    end
  end
end

function onInit()
  print("Init sequencer")
  uniqueIndex = 1
  tableMotion.options.startMode = tableMotion.startModes[6]
  startModeMenu.selected = gem.getIndexFromValue(tableMotion.options.startMode, tableMotion.startModes)
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
