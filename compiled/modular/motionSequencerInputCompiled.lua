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

local panelNameIndex = 1
local widgetNameIndex = 1

local widgetDefaults = {
  panel = Panel("DefaultPanel"),
  width = 120,
  height = 20,
  menuHeight = 45,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
  col = 0,
  row = 0,
  cols = 6
}

local widgetColours = {
  backgroundColour = "202020",
  widgetBackgroundColour = "01011F", -- Dark
  menuBackgroundColour = "01011F", -- widgetBackgroundColour
  widgetTextColour = "9f02ACFE", -- Light
  tableBackgroundColour = "191E25",
  sliderColour = "5FB5FF", -- Table slider colour
  labelTextColour = "black", -- Light
  labelBackgroundColour = "CFFFFE",
  menuArrowColour = "66AEFEFF", -- labelTextColour
  menuOutlineColour = "5f9f02ACFE", -- widgetTextColour
  menuTextColour = "9f02ACFE",
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

local function setColours(colours)
  widgetColours.backgroundColour = getWidgetValue(colours.backgroundColour, widgetColours.backgroundColour)
  widgetColours.widgetBackgroundColour = getWidgetValue(colours.widgetBackgroundColour, widgetColours.widgetBackgroundColour)
  widgetColours.menuBackgroundColour = getWidgetValue(colours.menuBackgroundColour, widgetColours.menuBackgroundColour)
  widgetColours.widgetTextColour = getWidgetValue(colours.widgetTextColour, widgetColours.widgetTextColour)
  widgetColours.tableBackgroundColour = getWidgetValue(colours.tableBackgroundColour, widgetColours.tableBackgroundColour)
  widgetColours.sliderColour = getWidgetValue(colours.sliderColour, widgetColours.sliderColour)
  widgetColours.labelTextColour = getWidgetValue(colours.labelTextColour, widgetColours.labelTextColour)
  widgetColours.labelBackgroundColour = getWidgetValue(colours.labelBackgroundColour, widgetColours.labelBackgroundColour)
  widgetColours.menuArrowColour = getWidgetValue(colours.menuArrowColour, widgetColours.menuArrowColour)
  widgetColours.menuOutlineColour = getWidgetValue(colours.menuOutlineColour, widgetColours.menuOutlineColour)
  widgetColours.menuTextColour = getWidgetValue(colours.menuTextColour, widgetColours.menuTextColour)
  widgetColours.backgroundColourOff = getWidgetValue(colours.backgroundColourOff, widgetColours.backgroundColourOff)
  widgetColours.backgroundColourOn = getWidgetValue(colours.backgroundColourOn, widgetColours.backgroundColourOn)
  widgetColours.textColourOff = getWidgetValue(colours.textColourOff, widgetColours.textColourOff)
  widgetColours.textColourOn = getWidgetValue(colours.textColourOn, widgetColours.textColourOn)
end

local function setSection(settings)
  if type(settings) ~= "table" then
    settings = {}
  end
  widgetDefaults.width = getWidgetValue(settings.width, widgetDefaults.width)
  widgetDefaults.height = getWidgetValue(settings.height, widgetDefaults.height)
  widgetDefaults.menuHeight = getWidgetValue(settings.menuHeight, widgetDefaults.menuHeight)
  widgetDefaults.xOffset = getWidgetValue(settings.xOffset, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getWidgetValue(settings.yOffset, widgetDefaults.yOffset)
  widgetDefaults.xOffset = getWidgetValue(settings.x, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getWidgetValue(settings.y, widgetDefaults.yOffset)
  widgetDefaults.xSpacing = getWidgetValue(settings.xSpacing, widgetDefaults.xSpacing)
  widgetDefaults.ySpacing = getWidgetValue(settings.ySpacing, widgetDefaults.ySpacing)
  widgetDefaults.cols = getWidgetValue(settings.cols, widgetDefaults.cols)
  widgetDefaults.col = getWidgetValue(settings.col, 0)
  widgetDefaults.row = getWidgetValue(settings.row, 0)
  setColours(settings)
end

local function getWidgetName(name, panel)
  if panel then
    name = getWidgetValue(name, "Panel" .. panelNameIndex)
    panelNameIndex = panelNameIndex + 1
  elseif type(name) == "nil" then
    name = "Widget" .. widgetNameIndex
    widgetNameIndex = widgetNameIndex + 1
  end
  return name
end

local function getWidgetX(options)
  if type(options.x) == "number" then
    return options.x
  end

  -- Calculate widget x position
  local col = getWidgetValue(options.col, widgetDefaults.col)
  local width = col * widgetDefaults.width
  local xSpacing = col * widgetDefaults.xSpacing
  return widgetDefaults.xOffset + width + xSpacing
end

local function getWidgetY(options)
  if type(options.y) == "number" then
    return options.y
  end

  -- Calculate widget y position
  local row = getWidgetValue(options.row, widgetDefaults.row)
  local height = row * widgetDefaults.height
  local ySpacing = row * widgetDefaults.ySpacing
  return widgetDefaults.yOffset + height + ySpacing
end

local function incrementRow(i)
  if type(i) == "nil" then
    i = 1
  end
  widgetDefaults.row = widgetDefaults.row + i
  widgetDefaults.col = 0
end

local function incrementCol(i)
  if type(i) == "nil" then
    i = 1
  end
  widgetDefaults.col = widgetDefaults.col + i
  if widgetDefaults.col >= widgetDefaults.cols then
    incrementRow()
  end
  --print("widgetDefaults.col, widgetDefaults.row", widgetDefaults.col, widgetDefaults.row)
end

local function getWidgetBounds(options, increment)
  local x = getWidgetX(options)
  local y = getWidgetY(options)
  local w = getWidgetValue(options.width, widgetDefaults.width)
  local h = getWidgetValue(options.height, widgetDefaults.height)

  -- Increment col and row
  if increment and options.increment ~= false then
    incrementCol()
  end

  return {x, y, w, h}
end

local function getWidgetOptions(options, displayName, default, panel)
  if type(options) ~= "table" then
    options = {}
  end
  options.default = getWidgetValue(default, options.default)
  options.name = getWidgetName(options.name, panel)
  options.displayName = getWidgetValue(displayName, options.name)
  options.tooltip = getWidgetValue(options.tooltip, options.displayName)
  options.integer = getWidgetValue(options.integer, (options.unit == Unit.Percent or options.unit == Unit.MidiKey))
  options.min = getWidgetValue(options.min, 0)
  options.default = getWidgetValue(options.default, options.min)
  if options.unit == Unit.MidiKey then
    options.max = getWidgetValue(options.max, 127)
  elseif options.unit == Unit.Percent then
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
  if type(options.editable) == "boolean" then
    widget.editable = options.editable
  end
  if type(options.backgroundColour) == "string" then
    widget.backgroundColour = options.backgroundColour
  end
  if type(options.fillStyle) == "string" then
    widget.fillStyle = options.fillStyle
  end
  if type(options.sliderColour) == "string" then
    widget.sliderColour = options.sliderColour
  end
  if type(options.backgroundColourWhenEditing) == "string" then
    widget.backgroundColourWhenEditing = options.backgroundColourWhenEditing
  end
  if type(options.textColourWhenEditing) == "string" then
    widget.textColourWhenEditing = options.textColourWhenEditing
  end
  if type(options.textColour) == "string" then
    widget.textColour = options.textColour
  end
end

local function setPanel(panel)
  widgetDefaults.panel = panel
end

local function getPanel(options)
  return widgetDefaults.panel
end

local widgets = {
  channels = function()
    local channels = {"Omni"}
    for j=1,16 do
      table.insert(channels, "" .. j)
    end
    return channels
  end,
  getColours = function() return widgetColours end,
  setColours = setColours,
  setPanel = setPanel,
  getPanel = getPanel,
  setSection = setSection,
  xOffset = xOffset,
  yOffset = yOffset,
  xSpacing = xSpacing,
  ySpacing = ySpacing,
  widthDefault = widthDefault,
  heightDefault = heightDefault,
  posSide = posSide,
  posUnder = posUnder,
  xOffset = function(val) widgetDefaults.xOffset = val end,
  yOffset = function(val) widgetDefaults.yOffset = val end,
  xSpacing = function(val) widgetDefaults.xSpacing = val end,
  ySpacing = function(val) widgetDefaults.ySpacing = val end,
  posSide = function(widget) return widget.x + widget.width + widgetDefaults.xSpacing end,
  posUnder = function(widget) return widget.y + widget.height + widgetDefaults.ySpacing end,
  width = function(val) widgetDefaults.width = val end,
  height = function(val) widgetDefaults.height = val end,
  col = function(i) incrementCol(i) end,
  row = function(i) incrementRow(i) end,
  panel = function(options)
    -- The first time, we use the default panel
    local create = panelNameIndex > 1
    if create == false then
      options.name = widgetDefaults.panel.name
    end
    options = getWidgetOptions(options, nil, nil, true)
    if create then
      widgetDefaults.panel = Panel(options.name)
      --print("Created panel", options.name)
    end
    widgetDefaults.panel.backgroundColour = widgetColours.backgroundColour
    widgetDefaults.panel.bounds = getWidgetBounds(options, false)
    setOptional(widgetDefaults.panel, options)
    return widgetDefaults.panel
  end,
  button = function(displayName, default, options)
    local isOnOff = true
    if type(default) == "table" then
      options = default
      default = nil
      isOnOff = false
    end
    options = getWidgetOptions(options, displayName, default)
    local widget
    if isOnOff then
      widget = widgetDefaults.panel:OnOffButton(options.name, (options.default == true))
    else
      widget = widgetDefaults.panel:Button(options.name)
    end
    widget.backgroundColourOff = widgetColours.backgroundColourOff
    widget.backgroundColourOn = widgetColours.backgroundColourOn
    widget.textColourOff = widgetColours.textColourOff
    widget.textColourOn = widgetColours.textColourOn
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  label = function(displayName, options)
    options = getWidgetOptions(options, displayName)
    local widget = widgetDefaults.panel:Label("Label")
    widget.text = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.labelBackgroundColour
    widget.textColour = widgetColours.labelTextColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  menu = function(displayName, default, items, options)
    if type(default) == "table" then
      options = items
      items = default
      default = nil
    end
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:Menu(options.name, items)
    widget.selected = options.default
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.menuBackgroundColour
    widget.textColour = widgetColours.menuTextColour
    widget.arrowColour = widgetColours.menuArrowColour
    widget.outlineColour = widgetColours.menuOutlineColour
    setOptional(widget, options)
    if widget.showLabel == true then
      options.height = getWidgetValue(options.height, widgetDefaults.menuHeight)
    end
    widget.bounds = getWidgetBounds(options, true)
    return widget
  end,
  numBox = function(displayName, default, options)
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:NumBox(options.name, options.default, options.min, options.max, options.integer)
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.widgetBackgroundColour
    widget.textColour = widgetColours.widgetTextColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  table = function(size, default, options)
    options = getWidgetOptions(options, nil, default)
    local widget = widgetDefaults.panel:Table(options.name, size, options.default, options.min, options.max, options.integer)
    widget.fillStyle = "solid"
    widget.backgroundColour = widgetColours.tableBackgroundColour
    widget.sliderColour = widgetColours.sliderColour
    widget.bounds = getWidgetBounds(options, true)
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
-- Common functions for working with event processor that act as modular inputs
--------------------------------------------------------------------------------

local activeVoices = {}

local function isNoteInActiveVoices(note)
  for _,v in ipairs(activeVoices) do
    if v.note == note then
      return true
    end
  end
  return false
end

local function isTrigger(e, channel)
  local isListeningForEvent = channel == 0 or channel == e.channel
  local isTrigger = e.note == 0 -- Note 0 is used as trigger
  return isTrigger and isListeningForEvent
end

local function handleTrigger(e, note, data)
  if isNoteInActiveVoices(note) == false then
    local id = playNote(note, e.velocity, -1, nil, e.channel)
    table.insert(activeVoices, {id=id,note=note,channel=e.channel,data=data})
    return true
  end
  return false
end

local function handleReleaseTrigger(e)
  for i,v in ipairs(activeVoices) do
    if v.channel == e.channel then
      releaseVoice(v.id)
      table.remove(activeVoices, i)
      return true
    end
  end
  return false
end

local modular = {
  releaseVoices = function()
    for i,v in ipairs(activeVoices) do
      releaseVoice(v.id)
    end
    activeVoices = {}
  end,
  isTrigger = isTrigger,
  handleTrigger = handleTrigger,
  handleReleaseTrigger = handleReleaseTrigger,
  getActiveVoices = function() return activeVoices end,
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

local backgroundColour = "606060"
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
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local movingCells = {}
local forward = false
local channel = 0

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetPitches()
  pitchOffsetPos = 1
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

local sequencerPanel = widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Motion Sequencer Input", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 90,
  xOffset = 531,
  yOffset = 5,
  xSpacing = 5,
  ySpacing = 5,
})

widgets.button("Forward", forward, {
  tooltip = "Forward triggers (note=0 events) to the next processor",
  changed = function(self) forward = self.value end,
})

local channelInput = widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

widgets.setSection({
  width = sequencerPanel.width,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
})

local notePanel = widgets.panel({
  backgroundColour = backgroundColour,
  y = widgets.posUnder(sequencerPanel),
  height = 250,
})

positionTable = widgets.table(tableMotion.options.tableLength, 0, {
  enabled = false,
  persistent = false,
  sliderColour = "green",
  backgroundColour = "CFFFFE",
  height = 6,
})

widgets.setSection()

motionTable = widgets.table(tableMotion.options.tableLength, 0, {
  tooltip = "Events are triggered when the value hits max or min",
  showPopupDisplay = true,
  backgroundColour = "191E25",
  min = -24,
  max = 24,
  integer = true,
  height = 160,
  y = widgets.posUnder(positionTable),
})

local noteWidgetHeight = 20
local noteWidgetWidth = 130
local noteWidgetRowSpacing = 5
local noteWidgetCellSpacing = 14
local firstRowY = motionTable.y + motionTable.height + 10

widgets.setSection({
  width = noteWidgetWidth,
  height = noteWidgetHeight,
  menuHeight = 45,
  xOffset = 10,
  yOffset = firstRowY,
  xSpacing = noteWidgetCellSpacing,
  ySpacing = noteWidgetRowSpacing,
  cols = 4
})

local speedTypeMenu = widgets.menu("Speed Type", tableMotion.speedTypes, {
  changed = function(self) tableMotion.options.speedType = self.selectedText end
})

local startModeMenu = widgets.menu("Start Mode", tableMotion.startModes, {
  changed = function(self)
    tableMotion.options.startMode = self.selectedText
    resetPitches()
  end
})

local scaleMenu = widgets.menu("Scale", #scalesNames, scalesNames, {
  width = 90,
  changed = function(self)
    scaleDefinitionIndex = self.value
    setScale()
  end
})

local noteInput = widgets.numBox("Base Note", baseNote, {
  width = 33,
  x = widgets.posSide(scaleMenu) - 10,
  y = firstRowY + 25,
  unit = Unit.MidiKey,
  showLabel = false,
  tooltip = "Set the root note",
  increment = false,
  changed = function(self)
    baseNote = self.value
    setScale()
  end
})

local moveSpeedInput = widgets.numBox("Motion Speed", tableMotion.options.moveSpeed, {
  name = "MoveSpeed",
  min = tableMotion.options.moveSpeedMin,
  max = tableMotion.options.moveSpeedMax,
  tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller",
  unit = Unit.MilliSeconds,
  changed = function(self) tableMotion.options.moveSpeed = self.value end
})

widgets.col(3)

local factorInput = widgets.numBox("Speed Factor", tableMotion.options.factor, {
  name = "Factor",
  min = tableMotion.options.factorMin,
  max = tableMotion.options.factorMax,
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. Controlled by the Y-axis on the XY controller",
  changed = function(self) tableMotion.options.factor = self.value end
})

local motionTableLengthInput = widgets.numBox("Length", tableMotion.options.tableLength, {
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the table length",
  changed = function(self)
    tableMotion.options.tableLength = self.value
    positionTable.length = tableMotion.options.tableLength
    motionTable.length = tableMotion.options.tableLength
    pitchOffsetPos = 1 -- Reset pos on length change
    resetPitches()
    startMoving()
    end
})

local bipolarButton = widgets.button("Bipolar", bipolar, {
  width = (noteWidgetWidth / 2) - (noteWidgetCellSpacing / 2),
  changed = function(self)
    bipolar = self.value
    setScale()
  end
})

widgets.button("Reset", false, {
  width = bipolarButton.width,
  x = widgets.posSide(bipolarButton),
  increment = false,
  changed = function(self)
    resetPitches()
    startMoving()
    self.value = false
  end
})

local octaveRangeInput = widgets.numBox("Octave Range", octaveRange, {
  tooltip = "Set the octave range",
  min = 1,
  max = 4,
  integer = true,
  changed = function(self)
    octaveRange = self.value
    setScale()
  end
})

local speedRandomizationAmountInput = widgets.numBox("Speed Rand", tableMotion.options.speedRandomizationAmount, {
  unit = Unit.Percent,
  tooltip = "Set the radomization amount applied to speed",
  changed = function(self) tableMotion.options.speedRandomizationAmount = self.value end
})

local xySpeedFactor = notePanel:XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = widgets.posSide(moveSpeedInput) - 5
xySpeedFactor.width = noteWidgetWidth
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  uniqueIndex = 1
  tableMotion.options.startMode = tableMotion.startModes[6]
  startModeMenu.selected = gem.getIndexFromValue(tableMotion.options.startMode, tableMotion.startModes)
  setScale()
end

function onNote(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    startPlaying()
    modular.handleTrigger(e, getNote())
  else
    postEvent(e)
  end
end

function onRelease(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    modular.handleReleaseTrigger(e)
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
