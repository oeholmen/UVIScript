-- modular/horizontalMotionSequencerInput -- 
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
  local numStepsUpDown = math.floor(numSteps / 2)
  local valueRange = maxValue - minValue
  local changePerStep = valueRange / numStepsUpDown
  local startValue = minValue
  local tri = {}
  for i=1,numSteps do
    table.insert(tri, math.floor(startValue))
    if rising then
      startValue = startValue + changePerStep
      if startValue >= maxValue then
        rising = false
      end
    else
      startValue = startValue - changePerStep
    end
  end
  tri[#tri] = minValue
  return tri
end

local function rampUp(minValue, maxValue, numSteps)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numSteps)
  local startValue = minValue
  local ramp = {}
  for i=1,numSteps do
    table.insert(ramp, math.floor(startValue))
    startValue = inc(startValue, changePerStep)
  end
  ramp[#ramp] = maxValue
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
  ramp[#ramp] = minValue
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
local currentX = 0
local currentY = 0

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

local function getValueOrDefault(value, default)
  if type(value) == "nil" then
    return default
  end
  return value
end

local function setColours(colours)
  widgetColours.backgroundColour = getValueOrDefault(colours.backgroundColour, widgetColours.backgroundColour)
  widgetColours.widgetBackgroundColour = getValueOrDefault(colours.widgetBackgroundColour, widgetColours.widgetBackgroundColour)
  widgetColours.menuBackgroundColour = getValueOrDefault(colours.menuBackgroundColour, widgetColours.menuBackgroundColour)
  widgetColours.widgetTextColour = getValueOrDefault(colours.widgetTextColour, widgetColours.widgetTextColour)
  widgetColours.tableBackgroundColour = getValueOrDefault(colours.tableBackgroundColour, widgetColours.tableBackgroundColour)
  widgetColours.sliderColour = getValueOrDefault(colours.sliderColour, widgetColours.sliderColour)
  widgetColours.labelTextColour = getValueOrDefault(colours.labelTextColour, widgetColours.labelTextColour)
  widgetColours.labelBackgroundColour = getValueOrDefault(colours.labelBackgroundColour, widgetColours.labelBackgroundColour)
  widgetColours.menuArrowColour = getValueOrDefault(colours.menuArrowColour, widgetColours.menuArrowColour)
  widgetColours.menuOutlineColour = getValueOrDefault(colours.menuOutlineColour, widgetColours.menuOutlineColour)
  widgetColours.menuTextColour = getValueOrDefault(colours.menuTextColour, widgetColours.menuTextColour)
  widgetColours.backgroundColourOff = getValueOrDefault(colours.backgroundColourOff, widgetColours.backgroundColourOff)
  widgetColours.backgroundColourOn = getValueOrDefault(colours.backgroundColourOn, widgetColours.backgroundColourOn)
  widgetColours.textColourOff = getValueOrDefault(colours.textColourOff, widgetColours.textColourOff)
  widgetColours.textColourOn = getValueOrDefault(colours.textColourOn, widgetColours.textColourOn)
end

local function setSection(settings)
  if type(settings) ~= "table" then
    settings = {}
  end
  widgetDefaults.width = getValueOrDefault(settings.width, widgetDefaults.width)
  widgetDefaults.height = getValueOrDefault(settings.height, widgetDefaults.height)
  widgetDefaults.menuHeight = getValueOrDefault(settings.menuHeight, widgetDefaults.menuHeight)
  widgetDefaults.xOffset = getValueOrDefault(settings.xOffset, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getValueOrDefault(settings.yOffset, widgetDefaults.yOffset)
  widgetDefaults.xOffset = getValueOrDefault(settings.x, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getValueOrDefault(settings.y, widgetDefaults.yOffset)
  widgetDefaults.xSpacing = getValueOrDefault(settings.xSpacing, widgetDefaults.xSpacing)
  widgetDefaults.ySpacing = getValueOrDefault(settings.ySpacing, widgetDefaults.ySpacing)
  widgetDefaults.cols = getValueOrDefault(settings.cols, widgetDefaults.cols)
  widgetDefaults.col = getValueOrDefault(settings.col, 0)
  widgetDefaults.row = getValueOrDefault(settings.row, 0)
  setColours(settings)
  currentX = widgetDefaults.xOffset
  currentY = widgetDefaults.yOffset
end

local function getWidgetName(name, displayName, useDisplayNameAsWidgetName, panel)
  if panel then
    name = getValueOrDefault(name, "Panel" .. panelNameIndex)
    panelNameIndex = panelNameIndex + 1
  elseif type(name) == "nil" then
    name = ""
    if useDisplayNameAsWidgetName and type(displayName) == "string" then
      name = string.gsub(displayName, "[^a-zA-Z]+", "")
    end
    if string.len(name) == 0 then
      name = "Widget" .. widgetNameIndex
      widgetNameIndex = widgetNameIndex + 1
    end
  end
  print("Widget name", name)
  return name
end

local function incrementRow(row, h)
  if type(row) == "nil" then
    row = 1
  end
  if type(h) == "nil" then
    h = widgetDefaults.height
  end
  widgetDefaults.row = widgetDefaults.row + row
  widgetDefaults.col = 0
  currentX = widgetDefaults.xOffset

  local height = math.max(1, row) * h
  local ySpacing = math.max(1, row) * widgetDefaults.ySpacing
  currentY = currentY + height + ySpacing
end

local function incrementCol(col, w, h)
  if type(col) == "nil" then
    col = 1
  end
  if type(w) == "nil" then
    w = widgetDefaults.width
  end

  local width = math.max(1, col) * w
  local xSpacing = math.max(1, col) * widgetDefaults.xSpacing
  currentX = currentX + width + xSpacing

  widgetDefaults.col = widgetDefaults.col + col
  if widgetDefaults.col >= widgetDefaults.cols then
    incrementRow(1, h)
  end
end

local function getWidgetBounds(options, increment)
  local x = getValueOrDefault(options.x, currentX)
  local y = getValueOrDefault(options.y, currentY)
  local w = getValueOrDefault(options.width, widgetDefaults.width)
  local h = getValueOrDefault(options.height, widgetDefaults.height)

  if type(options.y) == "number" then
    print("options.y, y", options.y, y)
  end

  if type(options.x) == "number" then
    print("options.x, x", options.x, x)
  end

  -- Increment position
  if increment then
    if type(options.increment) == "boolean" then
      if options.increment then
        options.increment = 1
      else
        options.increment = 0
      end
    end
    local i = getValueOrDefault(options.increment, 1)
    incrementCol(i, w, h)
  end

  return {x, y, w, h}
end

local function getWidgetOptions(options, displayName, default, panel)
  if type(options) ~= "table" then
    options = {}
  end
  options.default = getValueOrDefault(default, options.default)
  options.name = getWidgetName(options.name, displayName, type(default) ~= "nil", panel)
  options.displayName = getValueOrDefault(displayName, options.name)
  options.tooltip = getValueOrDefault(options.tooltip, options.displayName)
  options.integer = getValueOrDefault(options.integer, (options.unit == Unit.Percent or options.unit == Unit.MidiKey))
  options.min = getValueOrDefault(options.min, 0)
  options.default = getValueOrDefault(options.default, options.min)
  if options.unit == Unit.MidiKey then
    options.max = getValueOrDefault(options.max, 127)
  elseif options.unit == Unit.Percent then
    options.max = getValueOrDefault(options.max, 100)
  else
    options.max = getValueOrDefault(options.max, 1)
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
  if type(options.visible) == "boolean" then
    widget.visible = options.visible
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
  if type(options.backgroundColourOff) == "string" then
    widget.backgroundColourOff = options.backgroundColourOff
  end
  if type(options.backgroundColourOn) == "string" then
    widget.backgroundColourOn = options.backgroundColourOn
  end
  if type(options.textColourOff) == "string" then
    widget.textColourOff = options.textColourOff
  end
  if type(options.textColourOn) == "string" then
    widget.textColourOn = options.textColourOn
  end
end

local widgets = {
  setColours = setColours,
  setSection = setSection,
  channels = function()
    local channels = {"Omni"}
    for j=1,16 do
      table.insert(channels, "" .. j)
    end
    return channels
  end,
  getColours = function() return widgetColours end,
  getPanel = function(options) return widgetDefaults.panel end,
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
      default = 1
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
      options.height = getValueOrDefault(options.height, widgetDefaults.menuHeight)
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
  table = function(displayName, default, size, options)
    options = getWidgetOptions(options, displayName, default)
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
  if type(note) == "number" and isNoteInActiveVoices(note) == false then
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
  getNumVoices = function() return #activeVoices end,
  getActiveVoices = function() return activeVoices end,
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
      maxNote = 127
    end
    rootNote = math.max(0, rootNote)
    maxNote = math.min(127, maxNote)
    local scale = {}
    -- Find notes for scale
    local pos = 1
    while rootNote <= maxNote do
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
-- Common functions for notes
--------------------------------------------------------------------------------

local notenames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

local notes = {
  getNoteNames = function()
    return notenames
  end,
  
  -- Used for mapping - does not include octave, only name of note (C, C#...)
  getNoteMapping = function()
    local noteNumberToNoteName = {}
    local notenamePos = 1
    for i=0,127 do
      table.insert(noteNumberToNoteName, notenames[notenamePos])
      notenamePos = notenamePos + 1
      if notenamePos > #notenames then
        notenamePos = 1
      end
    end
    return noteNumberToNoteName
  end,
  
  transpose = function(note, min, max)
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
    -- Ensure note is inside given min/max values
    note = math.max(min, math.min(max, note))
    -- Ensure note is inside valid values
    return math.max(0, math.min(127, note))
  end,
  
  getSemitonesBetweenNotes = function(note1, note2)
    return math.max(note1, note2) - math.min(note1, note1)
  end,
  
  getNoteAccordingToScale = function(scale, noteToPlay)
    for _,note in ipairs(scale) do
      if note == noteToPlay then
        return noteToPlay
      elseif note > noteToPlay then
        print("Change from noteToPlay to note", noteToPlay, note)
        return note
      end
    end
    return noteToPlay
  end,
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
local baseNote = 60 -- Option
local tableRange = 16
local octaveRange = 2 -- Option
local bipolar = true -- Option
local activationMode = 1
local activationModes = {"Max:On,Min:Off", "Max:Toggle", "Min:Toggle", "Zero:Toggle", "Min:On,Max:Off", "Min/Max:Toggle"}
local positionTable
local motionTable
local scaleNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinitionIndex = #scaleNames
local activeScale = {} -- Holds the active scale
local activeNotes = {} -- Holds the active notes in the scale
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local movingCells = {}
local forward = false
local channel = 0

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetTableValues()
  -- Reset position
  tableMotion.setTableZero(positionTable)

  -- Set start mode
  tableMotion.setStartMode(motionTable)
end

local function move(i, uniqueId)
  local direction = 1
  local value = motionTable:getValue(i)
  --print("Start moving i, uniqueId", i, uniqueId)
  while isPlaying and movingCells[i] == uniqueId do
    -- Set note position active according to activation mode
    if activationMode == 1 and (value == motionTable.min or value == motionTable.max) then
      activeNotes[i] = value == motionTable.max
    elseif activationMode == 2 and value == motionTable.max and direction == 1 then
      activeNotes[i] = activeNotes[i] == false
    elseif activationMode == 3 and value == motionTable.min and direction == 1 then
      activeNotes[i] = activeNotes[i] == false
    elseif activationMode == 4 and value == 0 then
      activeNotes[i] = activeNotes[i] == false
    elseif activationMode == 5 and (value == motionTable.min or value == motionTable.max) then
      activeNotes[i] = value == motionTable.min
    elseif activationMode == 6 and (value == motionTable.min or value == motionTable.max) and direction == 1 then
      activeNotes[i] = activeNotes[i] == false
    end
    --print("Set activeNotes[i], i, uniqueId", activeNotes[i], i, uniqueId)
    value, direction = tableMotion.moveTable(motionTable, i, value, direction)
  end
end

local function startMoving()
  movingCells = {} -- Reset index to stop motion
  for i=1,motionTable.length do
    table.insert(movingCells, uniqueIndex)
    spawn(move, i, uniqueIndex)
    uniqueIndex = gem.inc(uniqueIndex)
  end
end

local function setRange()
  tableMotion.setRange(motionTable, tableRange, bipolar)
  resetTableValues()
end

local function setScaleTable()
  local scaleDefinition = scaleDefinitions[scaleDefinitionIndex]
  local startNote = baseNote
  if bipolar then
    startNote = startNote - (octaveRange * 12)
  end
  local maxNote = baseNote + (octaveRange * 12)
  activeScale = scales.createScale(scaleDefinition, startNote, maxNote)
  activeNotes = {} -- Reset
  for _,v in ipairs(activeScale) do
    table.insert(activeNotes, false) -- Notes start deactivated
  end

  -- Set table length according to the number of notes in the selected scale
  tableMotion.options.tableLength = #activeScale
  positionTable.length = tableMotion.options.tableLength
  motionTable.length = tableMotion.options.tableLength

  --print("#activeScale, startNote, maxNote", #activeScale, startNote, maxNote)
  resetTableValues()
  startMoving()
end

local function getNote()
  local activePositions = {}
  for i,v in ipairs(activeNotes) do
    if v then
      table.insert(activePositions, i)
    end
  end
  print("activeNotes", #activeNotes)
  print("activePositions", #activePositions)
  local scalePos = gem.getRandomFromTable(activePositions)

  -- No active notes
  if type(scalePos) == "nil" then-- or scalePos < 1 or scalePos > #activeScale then
    return
  end

  -- Set in position table
  for i=1,positionTable.length do
    local val = 0
    if activeNotes[i] then
      val = 1
    end
    if i == scalePos then
      val = 2
    end
    positionTable:setValue(i, val)
  end

  -- Get note from scale
  return activeScale[scalePos]
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  setScaleTable()
  startMoving()
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetTableValues()
end

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

local sequencerPanel = widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Horizontal Motion Sequencer", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 90,
  x = 531,
  y = 5,
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
-- Settings Panel
--------------------------------------------------------------------------------

widgets.setSection({
  width = sequencerPanel.width,
  x = 0,
  y = 0,
  xSpacing = 0,
  ySpacing = 0,
})

local settingsPanel = widgets.panel({
  backgroundColour = backgroundColour,
  y = widgets.posUnder(sequencerPanel),
  height = 254,
})

positionTable = widgets.table("Position", 0, tableMotion.options.tableLength, {
  max = 2,
  integer = true,
  enabled = false,
  persistent = false,
  sliderColour = "green",
  backgroundColour = "CFFFFE",
  height = 10,
})

widgets.setSection({
  height = 160,
  y = widgets.posUnder(positionTable),
})

motionTable = widgets.table("Motion", 0, tableMotion.options.tableLength, {
  tooltip = "Events are triggered when the value hits max or min",
  showPopupDisplay = true,
  backgroundColour = "191E25",
  min = -tableRange,
  max = tableRange,
  integer = true,
})

local noteWidgetHeight = 20
local noteWidgetWidth = 138
local noteWidgetRowSpacing = 6
local noteWidgetCellSpacing = 6
local firstRowY = motionTable.y + motionTable.height + 6

widgets.setSection({
  width = noteWidgetWidth,
  height = noteWidgetHeight,
  menuHeight = 45,
  x = 10,
  y = firstRowY,
  xSpacing = noteWidgetCellSpacing,
  ySpacing = noteWidgetRowSpacing,
  cols = 7
})

widgets.menu("Speed Type", tableMotion.speedTypes, {
  tooltip = "The speed type works with the speed factor to control speed variations across the table. Ramp Up means fast -> slower, Triangle means slower in the center.",
  width = 90,
  changed = function(self) tableMotion.options.speedType = self.selectedText end
})

widgets.menu("Start Mode", 3, tableMotion.startModes, {
  tooltip = "Set how the table will look when starting.",
  width = 90,
  changed = function(self)
    tableMotion.options.startMode = self.selectedText
    resetTableValues()
  end
}):changed()

widgets.menu("Activation Mode", activationMode, activationModes, {
  tooltip = "Activation mode controls when notes in the table are activated and deactivated.",
  width = 114,
  changed = function(self) activationMode = self.value end
})

local scaleMenu = widgets.menu("Scale", #scaleNames, scaleNames, {
  width = 114,
  changed = function(self)
    scaleDefinitionIndex = self.value
    setScaleTable()
  end
})

local moveSpeedInput = widgets.numBox("Motion Speed", tableMotion.options.moveSpeed, {
  name = "MoveSpeed",
  tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller",
  min = tableMotion.options.moveSpeedMin,
  max = tableMotion.options.moveSpeedMax,
  unit = Unit.MilliSeconds,
  changed = function(self) tableMotion.options.moveSpeed = self.value end
})

widgets.row()
widgets.col(3)

widgets.numBox("Speed Factor", tableMotion.options.factor, {
  name = "Factor",
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. Controlled by the Y-axis on the XY controller",
  min = tableMotion.options.factorMin,
  max = tableMotion.options.factorMax,
  changed = function(self) tableMotion.options.factor = self.value end
})

widgets.row()

widgets.numBox("Range", tableRange, {
  width = 90,
  min = 8,
  max = 128,
  integer = true,
  tooltip = "Set the table range - high range = fewer events, low range = more events",
  changed = function(self)
    tableRange = self.value
    setRange()
  end
})

-- TODO Add a menu for automatic reset options?
widgets.button("Reset", false, {
  tooltip = "Reset table to start mode",
  width = 90,
  changed = function(self)
    resetTableValues()
    setScaleTable()
    startMoving()
    self.value = false
  end
})

widgets.numBox("Octave Range", octaveRange, {
  width = 114,
  tooltip = "Set the octave range",
  min = 1,
  max = 4,
  integer = true,
  changed = function(self)
    octaveRange = self.value
    setScaleTable()
  end
})

widgets.button("Bipolar", bipolar, {
  tooltip = "Toggle table bipolar mode",
  width = 78,
  changed = function(self)
    bipolar = self.value
    setRange()
    setScaleTable()
    startMoving()
  end
})

local noteInput = widgets.numBox("Base Note", baseNote, {
  width = 30,
  unit = Unit.MidiKey,
  showLabel = false,
  tooltip = "Set the root note",
  changed = function(self)
    baseNote = self.value
    setScaleTable()
  end
})

widgets.numBox("Speed Rand", tableMotion.options.speedRandomizationAmount, {
  unit = Unit.Percent,
  tooltip = "Set the radomization amount applied to speed",
  changed = function(self) tableMotion.options.speedRandomizationAmount = self.value end
})

local xySpeedFactor = widgets.getPanel():XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = widgets.posSide(moveSpeedInput)
xySpeedFactor.width = noteWidgetWidth - 10
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  uniqueIndex = 1
  setScaleTable()
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
