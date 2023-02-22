-- modular/gridSequencerInput -- 
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
    --incrementCol(1, w, h)
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
-- Grid Sequencer - Listens for incoming note events (rythm) on note number 0
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
local menuSelectedBackgroundColour = "052525"
local menuTextColour = "#9f02ACFE"
local noteSelectedTextColour = "green"
local notePlayingTextColour = "yellow"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local knobFillColour = "E6D5B8" -- Light

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local playModes = {"->", "<-", "-><-", "<-->", "Follow ->", "Follow <-"}
local scaleIncrementDefinition = {} -- Holds the increment definition for scales
local degreeDefinition = {} -- Holds the definition for degrees on the y-axis
local noteInputs = {} -- Holds the note inputs
local listeners = {} -- Holds the note listeners
local gridXY = {} -- Holds x and y axis positon and other settings
local xAxis = 1 -- Hold the index for the x axis in the gridXY table
local yAxis = 2 -- Hold the index for the y axis in the gridXY table
local scalesNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local rootNote = 1 -- Holds the current root note (key)
local scaleDefinitionIndex = #scalesNames -- Holds the scale definition index
local startOctave = -1 -- Holds the start octave when creating the scale
local octaves = 9 -- Holds the octave range
local noteRandomizationProbability = 0
local manualInput = false
local channel = 0 -- 0 = Omni
local forward = false

-- X Axis (index 1)
table.insert(gridXY, {
  pos = 0,
  direction = 1,
  increment = 1,
  playMode = playModes[1],
  chord = false,
  chordNotes = 2,
  chordNotesIncrement = 1,
  randomChord = false,
  randomProbability = 0, -- Probability that position will be selected by chance
  advanceProbability = 100, -- Probability that a new position for the axis will be selected by the play mode
  mustAdvance = true, -- Set true to ensure pos is moved to within the selected area even if advanceProbability = 0
  hasAdvanced = false,
  offset = 2,
  size = 8,
  max = 12
})

-- Y Axis (index 2)
table.insert(gridXY, {
  pos = 0,
  direction = 1,
  increment = 1,
  playMode = playModes[1],
  chord = false,
  chordNotes = 2,
  chordNotesIncrement = 1,
  randomChord = false,
  randomProbability = 0, -- Probability that position will be selected by chance
  advanceProbability = 100, -- Probability that a new position for the axis will be selected by the play mode
  mustAdvance = true, -- Set true to ensure pos is moved to within the selected area even if advanceProbability = 0
  hasAdvanced = false,
  offset = 3,
  size = 3,
  max = 9
})

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function getCell(x, y)
  --print("Get grid cell: x, y, floor(x), floor(y)", x, y, math.floor(x), math.floor(y))
  -- Not < 1
  x = math.max(1, math.ceil(x))
  y = math.max(1, math.ceil(y))
  -- Not > max
  if x > gridXY[xAxis].max then
    print("x > gridXY[xAxis].max")
    x = gridXY[xAxis].max
  end
  if y > gridXY[yAxis].max then
    print("y > gridXY[yAxis].max")
    y = gridXY[yAxis].max
  end
  -- Get cell name
  local cellName = 'Note' .. x .. '_' .. y
  for _,v in ipairs(noteInputs) do
    if v.name == cellName then
      return v
    end
  end
end

local function toggleNoteInputs(enabled)
  for i,v in ipairs(noteInputs) do
    v.enabled = enabled
  end
end

local function showListeners(show)
  for i,v in ipairs(noteInputs) do
    if show then
      v.width = 30
      v.x = listeners[i].x + listeners[i].width
    else
      v.width = 42
      v.x = listeners[i].x
    end
    listeners[i].visible = show
  end
end

local function isPosWithinSelectedAxis(pos, axis)
  return pos > gridXY[axis].offset and pos <= gridXY[axis].offset + gridXY[axis].size
end

local function isWithinSelectedGrid(x, y)
  return isPosWithinSelectedAxis(x, xAxis) and isPosWithinSelectedAxis(y, yAxis)
end

-- Returns the (reset) position before any increments are made
local function getStartPos(axis)
  local startPos = gridXY[axis].offset

  if string.sub(gridXY[axis].playMode, 1, 6) == "Follow" then
    return startPos + 1
  end

  gridXY[axis].mustAdvance = true

  if gridXY[axis].increment < 1 then
    return startPos
  end

  return startPos + 1 - math.floor(gridXY[axis].increment)
end

local function setPos()
  for axis=xAxis,yAxis do
    -- When direction is forward, we set the start pos
    if gridXY[axis].direction == 1 then
      gridXY[axis].pos = getStartPos(axis)
    else
      -- When direction is backward, we set the end pos
      local endPos = gridXY[axis].offset + gridXY[axis].size
      if gridXY[axis].playMode == "Follow <-" then
        gridXY[axis].pos = endPos
      else
        gridXY[axis].mustAdvance = true
        gridXY[axis].pos = endPos - gridXY[axis].increment
      end
    end
  end
end

local function setSelectedGrid()
  local i = 1
  for y=1,gridXY[yAxis].max do
    for x=1,gridXY[xAxis].max do
      if isWithinSelectedGrid(x, y) then
        noteInputs[i].textColour = noteSelectedTextColour
        noteInputs[i].backgroundColour = menuSelectedBackgroundColour
      else
        noteInputs[i].textColour = menuTextColour
        noteInputs[i].backgroundColour = menuBackgroundColour
      end
      i = gem.inc(i)
    end
  end
  setPos()
end

local function setDirectionFromPlaymode(axis, playMode)
  gridXY[axis].playMode = playMode
  gridXY[axis].direction = 1
  gridXY[axis].increment = math.abs(gridXY[axis].increment)

  if playMode == "<-" or playMode == "<-->" or playMode == "Follow <-" then
    gridXY[axis].direction = -1
    gridXY[axis].increment = -gridXY[axis].increment
  end

  --print("setDirectionFromPlaymode: direction, increment, playMode", gridXY[axis].direction, gridXY[axis].increment, playMode)
end

local function handleFollow(axis)
  if gridXY[axis].hasAdvanced or gem.getRandomBoolean(gridXY[axis].advanceProbability) == false then
    -- Skip follow if the axis has already advanced or advance probability does not hit
    return
  end
  gridXY[axis].pos = gem.inc(gridXY[axis].pos, gridXY[axis].increment)
  if gridXY[axis].direction == 1 and (gridXY[axis].pos > gridXY[axis].offset + gridXY[axis].size or gridXY[axis].pos > gridXY[axis].max) then
    gridXY[axis].pos = getStartPos(axis)
  elseif gridXY[axis].pos <= gridXY[axis].offset then
    gridXY[axis].pos = gridXY[axis].offset + gridXY[axis].size
  end
end

-- playModes = {"->", "<-", "-><-", "<-->", "Follow ->", "Follow <-"}
local function advanceByPlayMode(v, axis)
  local otherAxis = xAxis
  if axis == otherAxis then
    otherAxis = yAxis
  end
  local axisIsFollow = string.sub(v.playMode, 1, 6) == "Follow"
  local otherAxisIsFollow = string.sub(gridXY[otherAxis].playMode, 1, 6) == "Follow"
  local bothAxisAreFollow = axisIsFollow and otherAxisIsFollow
  if gem.getRandomBoolean(v.randomProbability) then
    --print("Advance random")
    if v.size > 1 then
      v.pos = gem.getRandom(v.offset + 1, v.offset + v.size)
    else
      v.pos = v.offset + v.size
    end
    v.hasAdvanced = true
    if otherAxisIsFollow then
      handleFollow(otherAxis)
    end
  elseif v.playMode == "-><-" or v.playMode == "<-->" then
    v.pos = gem.inc(v.pos, v.increment)
    if math.floor(v.pos) <= v.offset then
      v.direction = 1
      v.increment = math.abs(v.increment) -- Turn positive
      --print("Turned direction and increment positive", v.direction, v.increment)
      v.pos = getStartPos(axis) + v.increment
      if v.size > 1 and otherAxisIsFollow == false then
        v.pos = gem.inc(v.pos, v.increment) -- To avoid repeat
      end
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    elseif v.pos > v.offset + v.size or v.pos > v.max then
      v.direction = -1
      v.increment = -v.increment -- Turn negative
      --print("Turned direction and increment negative", v.direction, v.increment)
      v.pos = v.offset + v.size
      if v.size > 1 and otherAxisIsFollow == false then
        v.pos = gem.inc(v.pos, v.increment) -- To avoid repeat
      end
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  elseif (v.direction == 1 and axisIsFollow == false) or bothAxisAreFollow then
    --print("advanceByPlayMode: direction == 1")
    v.pos = gem.inc(v.pos, v.increment)
    --print("advanceByPlayMode: axis, pos", axis, v.pos)
    if v.pos > v.offset + v.size or v.pos > v.max then
      --v.pos = gem.inc(v.offset, v.increment)
      v.pos = getStartPos(axis) + v.increment
      --print("advanceByPlayMode: reset axis, pos", axis, v.pos)
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  elseif v.direction == -1 and axisIsFollow == false then
    v.pos = gem.inc(v.pos, v.increment)
    --print("axis, v.pos, v.increment, v.offset", axis, v.pos, v.increment, v.offset)
    if v.pos <= v.offset then
      v.pos = v.offset + v.size
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  end
end

local function getCellForAxis(axis, pos)
  if axis == xAxis then
    local yPos = gridXY[yAxis].pos
    --print("getCell @ axis, pos, yPos", axis, pos, yPos)
    return getCell(pos, yPos)
  end

  local xPos = gridXY[xAxis].pos
  --print("getCell @ axis, xPos, pos", axis, xPos, pos)
  return getCell(xPos, pos)
end

local function getCellsForAxis(axis, v)
  local cellsForAxis = {}
  local startPos = v.offset + 1
  local endPos = math.min(v.max, v.offset + v.size)
  --print("axis, startPos, endPos", i, startPos, endPos)
  if v.chord and v.randomChord then
    -- Get selected notes in random order
    local currentPos = startPos
    while currentPos <= endPos do
      table.insert(cellsForAxis, getCellForAxis(axis, currentPos))
      currentPos = gem.inc(currentPos)
    end
    -- Remove random cells until we have the correct amount
    while #cellsForAxis > v.chordNotes do
      table.remove(cellsForAxis, gem.getRandom(#cellsForAxis))
    end
  else
    -- Get selected notes in sequential order
    local currentPos = v.pos
    -- Add cells until we have the correct amount
    while #cellsForAxis < v.chordNotes do
      table.insert(cellsForAxis, getCellForAxis(axis, currentPos))
      currentPos = gem.inc(currentPos, v.chordNotesIncrement, endPos, startPos)
    end
  end
  return cellsForAxis
end

local function getNotes()
  local cells = {} -- Holds the selected grid cells to play

  -- Reset advance status
  gridXY[xAxis].hasAdvanced = false
  gridXY[yAxis].hasAdvanced = false

  -- Advance each axis according to the set increment
  for axis,v in ipairs(gridXY) do
    if v.mustAdvance or gem.getRandomBoolean(v.advanceProbability) then
      advanceByPlayMode(v, axis)
      v.mustAdvance = false
    end
  end

  -- Get multiple cells if polymode is active on any of the axis
  for axis,v in ipairs(gridXY) do
    if v.chord then
      for _,cell in ipairs(getCellsForAxis(axis, v)) do
        table.insert(cells, cell)
      end
    end
  end

  -- If no cells were found using polymode, we return the cell at the current pos
  if #cells == 0 then
    table.insert(cells, getCell(gridXY[xAxis].pos, gridXY[yAxis].pos))
  end

  --print("Returning cells", #cells)
  return cells
end

local function createTableFromText(text)
  local theTable = {}
  if string.len(text) > 0 then
    for w in string.gmatch(text, "[^,]+") do
      table.insert(theTable, tonumber(gem.trimStartAndEnd(w)))
    end
  end
  return theTable
end

local function setScale()
  if manualInput then
    -- Do not change anything when manual input is active
    --print("Skip set scale - manual input is active")
    return
  end
  local startNote = (rootNote - 1) + ((startOctave + 2) * 12)
  local maxNote = startNote + (octaves * 12)
  local scale = scales.createScale(scaleDefinitions[scaleDefinitionIndex], startNote, math.min(128, maxNote))
  local scalePos = 1
  local scaleIncrementDefinitionPos = 1
  local degreeDefinitionPos = 0
  local degreeOctave = 0
  local scaleResetPos = 1
  print("Root note is", startNote)
  print("Max note is", maxNote)
  print("Degree definition", #degreeDefinition)
  print("#scale", #scale)
  for i,v in ipairs(noteInputs) do
    -- Check if we have a degree definition
    -- Check if we are at the start of the x axis
    if #degreeDefinition > 0 and (i - 1) % gridXY[xAxis].max == 0 then
      -- Increment degree position
      degreeDefinitionPos = gem.inc(degreeDefinitionPos, 1, #degreeDefinition)
      -- Set the scale pos to the selected degree if within the scale
      if degreeDefinition[degreeDefinitionPos] <= #scale then
        scalePos = math.max(1, degreeDefinition[degreeDefinitionPos])
      end
      -- Set scale reset pos to match the scale pos set by the degree definition
      scaleResetPos = scalePos
      -- Increment degree octave on pos 1 of the degree def
      if i > 1 and degreeDefinitionPos == 1 then
        degreeOctave = gem.inc(degreeOctave, 1, (octaves - 1), 0)
        --print("Increment octave at degree pos", degreeOctave)
      end
      -- Reset the position for scale increments
      scaleIncrementDefinitionPos = 1
    end

    -- Set the note for this cell
    local noteNumber = math.min(127, scale[scalePos] + (degreeOctave * 12))
    -- Get random from scale
    if gem.getRandomBoolean(noteRandomizationProbability) then
      noteNumber = gem.getRandomFromTable(scale)
    end
    v:setValue(noteNumber)

    -- Get next scale position
    scalePos = math.max(1, gem.inc(scalePos, scaleIncrementDefinition[scaleIncrementDefinitionPos], #scale, scaleResetPos))

    if scalePos == scaleResetPos then
      -- Reset the position for scale increments when scale position is reset
      scaleIncrementDefinitionPos = 1
    else
      -- Get next scale increment position
      scaleIncrementDefinitionPos = gem.inc(scaleIncrementDefinitionPos, 1, #scaleIncrementDefinition)
    end
  end
end

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

local sequencerPanel = Panel("GridSequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 0
sequencerPanel.y = 0
sequencerPanel.width = 720
sequencerPanel.height = 30

local notePanel = Panel("Notes")
notePanel.backgroundColour = "black"
notePanel.x = sequencerPanel.x
notePanel.y = sequencerPanel.y + sequencerPanel.height
notePanel.width = sequencerPanel.width
notePanel.height = 240

local settingsPanel = Panel("Scale")
settingsPanel.backgroundColour = "404040"
settingsPanel.x = notePanel.x
settingsPanel.y = notePanel.y + notePanel.height + 0
settingsPanel.width = sequencerPanel.width
settingsPanel.height = 84

local axisMotionPanel = Panel("AxisMotionPanel")
axisMotionPanel.backgroundColour = "404040"
axisMotionPanel.x = settingsPanel.x
axisMotionPanel.y = settingsPanel.y + settingsPanel.height + 0
axisMotionPanel.width = sequencerPanel.width
axisMotionPanel.height = 132

--------------------------------------------------------------------------------
-- Grid Sequencer
--------------------------------------------------------------------------------

widgets.setPanel(sequencerPanel)
local xSpacing = 5

local sequencerLabel = sequencerPanel:Label("Label")
sequencerLabel.text = "Grid Sequencer Input"
sequencerLabel.tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.position = {0,0}
sequencerLabel.size = {sequencerPanel.width,30}

local manualInputButton = sequencerPanel:OnOffButton("ManualInputButton", manualInput)
local showListenersButton = sequencerPanel:OnOffButton("ShowListeners", false)

manualInputButton.backgroundColourOff = backgroundColourOff
manualInputButton.backgroundColourOn = backgroundColourOn
manualInputButton.textColourOff = textColourOff
manualInputButton.textColourOn = textColourOn
manualInputButton.displayName = "Manual Input"
manualInputButton.tooltip = "Make all note inputs available for direct edit or note listen"
manualInputButton.size = {100,22}
manualInputButton.x = sequencerPanel.width - (manualInputButton.width * 4) - 20
manualInputButton.y = 5
manualInputButton.changed = function(self)
  manualInput = self.value
  showListenersButton.enabled = self.value
  if self.value == false then
    showListenersButton:setValue(false)
  end
  settingsPanel.enabled = self.value == false
  toggleNoteInputs(self.value)
end

showListenersButton.enabled = false
showListenersButton.backgroundColourOff = backgroundColourOff
showListenersButton.backgroundColourOn = backgroundColourOn
showListenersButton.textColourOff = textColourOff
showListenersButton.textColourOn = textColourOn
showListenersButton.displayName = "Show Listeners"
showListenersButton.tooltip = "Show listeners for each note - only available in manual input mode"
showListenersButton.size = {100,22}
showListenersButton.x = manualInputButton.x + manualInputButton.width + xSpacing
showListenersButton.y = manualInputButton.y
showListenersButton.changed = function(self)
  showListeners(self.value)
end

local forwardButton = widgets.button("Forward", forward, {
  x = widgets.posSide(showListenersButton) + xSpacing,
  y = showListenersButton.y,
  width = 100,
  height = 22,
  tooltip = "Forward triggers (note=0 events) to the next processor",
  changed = function(self) forward = self.value end,
})

local channelInput = widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  width = 100,
  height = 22,
  x = widgets.posSide(forwardButton) + xSpacing,
  y = forwardButton.y,
  changed = function(self) channel = self.value - 1 end
})

--[[ local channelInput = sequencerPanel:Menu("ChannelInput", widgets.channels())
channelInput.tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through"
channelInput.arrowColour = menuArrowColour
channelInput.showLabel = false
channelInput.backgroundColour = menuBackgroundColour
channelInput.textColour = widgetTextColour
channelInput.size = {90,22}
channelInput.x = forwardButton.x + forwardButton.width + xSpacing
channelInput.y = forwardButton.y
channelInput.changed = function(self)
  channel = self.value - 1
end ]]

--------------------------------------------------------------------------------
-- Note Grid
--------------------------------------------------------------------------------

local rowCounter = gridXY[yAxis].max - 1
local columnCounter = 0
local colSpacing = 3
local rowSpacing = 2
local noteListen = false
local noteIndex = 0

for y=1,gridXY[yAxis].max do
  for x=1,gridXY[xAxis].max do
    local listen = notePanel:OnOffButton("Listen" .. x .. '_' .. y)
    listen.visible = false
    listen.displayName = "L"
    listen.tooltip = "Note learn - check multiple listeners to set same note on several inputs"
    listen.persistent = false
    listen.textColourOff = "white"
    listen.backgroundColourOn = "green"
    listen.height = 24
    listen.width = 14
    listen.x = (colSpacing * 1) + (columnCounter * (42 + colSpacing))
    listen.y = (rowSpacing * 1.5) + ((listen.height + rowSpacing) * rowCounter)
    listen.changed = function(self)
      if self.value then
        noteListen = true
      end
    end
    table.insert(listeners, listen)

    local noteInput = notePanel:NumBox("Note" .. x .. '_' .. y, noteIndex + 12, 0, 127, true)
    noteInput.enabled = false
    noteInput.showLabel = false
    noteInput.displayName = "Note"
    noteInput.tooltip = "The note to trigger in cell x:" .. x .. ', y:' .. y
    noteInput.unit = Unit.MidiKey
    noteInput.backgroundColour = menuBackgroundColour
    noteInput.textColour = menuTextColour
    noteInput.height = 24
    noteInput.width = 42
    noteInput.x = listen.x
    noteInput.y = listen.y
    table.insert(noteInputs, noteInput)

    noteIndex = gem.inc(noteIndex)
    columnCounter = gem.inc(columnCounter)
    if columnCounter >= gridXY[xAxis].max then
      columnCounter = 0
      rowCounter = gem.inc(rowCounter, -1)
    end
  end
end

local xyOffset = notePanel:XY('GridOffset1', 'GridOffset2')
xyOffset.bounds = {546, 6, 168, 112}

local xySize = notePanel:XY('GridSize1', 'GridSize2')
xySize.bounds = {xyOffset.x, xyOffset.y+xyOffset.height+4, xyOffset.width, xyOffset.height}

--------------------------------------------------------------------------------
-- Note Selection
--------------------------------------------------------------------------------

xSpacing = 10

local noteSelectionLabel = settingsPanel:Label("NoteSelectionLabel")
noteSelectionLabel.text = "Note Selection"
noteSelectionLabel.tooltip = "Settings for selecting the notes in the grid (disabled when manual input is active)"
noteSelectionLabel.alpha = 0.3
noteSelectionLabel.fontSize = 16
noteSelectionLabel.backgroundColour = labelBackgoundColour
noteSelectionLabel.textColour = labelTextColour
noteSelectionLabel.width = settingsPanel.width
noteSelectionLabel.height = 18
noteSelectionLabel.x = 0
noteSelectionLabel.y = 0

local keyMenu = settingsPanel:Menu("Key", notes.getNoteNames())
keyMenu.displayName = "Key"
keyMenu.tooltip = "The key to set for the notes in the grid"
keyMenu.showLabel = true
keyMenu.width = 90
keyMenu.x = 5
keyMenu.y = noteSelectionLabel.y + noteSelectionLabel.height + 10
keyMenu.backgroundColour = menuBackgroundColour
keyMenu.textColour = menuTextColour
keyMenu.arrowColour = menuArrowColour
keyMenu.outlineColour = menuOutlineColour

local scaleMenu = settingsPanel:Menu("Scale", scalesNames)
scaleMenu.selected = #scalesNames
scaleMenu.displayName = "Scale"
scaleMenu.tooltip = "The scale to set for the notes in the grid"
scaleMenu.showLabel = true
scaleMenu.width = 120
scaleMenu.x = keyMenu.x + keyMenu.width + xSpacing
scaleMenu.y = keyMenu.y
scaleMenu.backgroundColour = menuBackgroundColour
scaleMenu.textColour = menuTextColour
scaleMenu.arrowColour = menuArrowColour
scaleMenu.outlineColour = menuOutlineColour

local startOctaveInput = settingsPanel:NumBox("StartOctave", startOctave, -2, 7, true)
startOctaveInput.displayName = "Start octave"
startOctaveInput.tooltip = "The octave to start from when creating the scale"
startOctaveInput.backgroundColour = menuBackgroundColour
startOctaveInput.textColour = menuTextColour
startOctaveInput.height = 20
startOctaveInput.width = 126
startOctaveInput.x = scaleMenu.x + scaleMenu.width + xSpacing
startOctaveInput.y = scaleMenu.y

local octavesInput = settingsPanel:NumBox("Octaves", octaves, 1, 10, true)
octavesInput.displayName = "Octaves"
octavesInput.tooltip = "Set the octave range"
octavesInput.backgroundColour = menuBackgroundColour
octavesInput.textColour = menuTextColour
octavesInput.height = startOctaveInput.height
octavesInput.width = startOctaveInput.width
octavesInput.x = startOctaveInput.x
octavesInput.y = startOctaveInput.y + startOctaveInput.height + 5

local noteRandomizationProbabilityInput = settingsPanel:Knob("NoteRandomizationProbability", noteRandomizationProbability, 0, 100, true)
noteRandomizationProbabilityInput.unit = Unit.Percent
noteRandomizationProbabilityInput.displayName = "Random notes"
noteRandomizationProbabilityInput.tooltip = "Set the probability that notes within the current scale will be selected by chance."
noteRandomizationProbabilityInput.backgroundColour = widgetBackgroundColour
noteRandomizationProbabilityInput.fillColour = knobFillColour
noteRandomizationProbabilityInput.outlineColour = labelBackgoundColour
noteRandomizationProbabilityInput.showPopupDisplay = true
noteRandomizationProbabilityInput.height = 45
noteRandomizationProbabilityInput.width = 130
noteRandomizationProbabilityInput.y = startOctaveInput.y
noteRandomizationProbabilityInput.x = startOctaveInput.x + startOctaveInput.width + xSpacing
noteRandomizationProbabilityInput.changed = function(self)
  noteRandomizationProbability = self.value
  setScale()
end

local scaleIncrementInputLabel = settingsPanel:Label("ScaleIncrementInputLabel")
scaleIncrementInputLabel.text = "X"
scaleIncrementInputLabel.x = noteRandomizationProbabilityInput.x + noteRandomizationProbabilityInput.width + xSpacing
scaleIncrementInputLabel.y = noteRandomizationProbabilityInput.y
scaleIncrementInputLabel.height = startOctaveInput.height
scaleIncrementInputLabel.width = 20

local scaleIncrementInput = settingsPanel:Label("ScaleIncrementInput")
scaleIncrementInput.text = "1"
scaleIncrementInput.tooltip = "Set scale increments on the x axis - default is to increment by one step per cell. Increments are separated by comma, and will repeat until all cells are set."
scaleIncrementInput.editable = true
scaleIncrementInput.backgroundColour = labelTextColour
scaleIncrementInput.backgroundColourWhenEditing = "white"
scaleIncrementInput.textColour = "white"
scaleIncrementInput.textColourWhenEditing = labelTextColour
scaleIncrementInput.height = startOctaveInput.height
scaleIncrementInput.width = 165
scaleIncrementInput.x = scaleIncrementInputLabel.x + scaleIncrementInputLabel.width
scaleIncrementInput.y = scaleIncrementInputLabel.y
scaleIncrementInput.changed = function(self)
  scaleIncrementDefinition = createTableFromText(self.text)
  setScale()
end

local degreeInputLabel = settingsPanel:Label("DegreeInputLabel")
degreeInputLabel.text = "Y"
degreeInputLabel.x = scaleIncrementInputLabel.x
degreeInputLabel.y = scaleIncrementInputLabel.y + scaleIncrementInputLabel.height + 5
degreeInputLabel.height = scaleIncrementInputLabel.height
degreeInputLabel.width = scaleIncrementInputLabel.width

local degreeInput = settingsPanel:Label("DegreeInput")
degreeInput.text = "1"
degreeInput.tooltip = "Degree definition: if set, the scale increment input will reset at the start of each row (y-axis), setting the degree as the root note. 1 = root. Degrees are separated by comma."
degreeInput.editable = true
degreeInput.backgroundColour = labelTextColour
degreeInput.backgroundColourWhenEditing = "white"
degreeInput.textColour = "white"
degreeInput.textColourWhenEditing = labelTextColour
degreeInput.height = scaleIncrementInput.height
degreeInput.width = scaleIncrementInput.width
degreeInput.x = degreeInputLabel.x + degreeInputLabel.width
degreeInput.y = degreeInputLabel.y
degreeInput.changed = function(self)  
  degreeDefinition = createTableFromText(self.text)
  setScale()
end

keyMenu.changed = function(self)
  rootNote = self.value
  setScale()
end

scaleMenu.changed = function(self)
  scaleDefinitionIndex = self.value
  setScale()
end

startOctaveInput.changed = function(self)
  startOctave = self.value
  setScale()
end

octavesInput.changed = function(self)
  octaves = self.value
  setScale()
end

--------------------------------------------------------------------------------
-- Axis Motion Settings
--------------------------------------------------------------------------------

xSpacing = 10 -- Horizontal widget spacing

local motionLabel = axisMotionPanel:Label("MotionLabel")
motionLabel.text = "Motion"
motionLabel.tooltip = "Settings for setting the grid selection, and controlling motion along the x and y axis"
motionLabel.alpha = noteSelectionLabel.alpha
motionLabel.fontSize = noteSelectionLabel.fontSize
motionLabel.backgroundColour = labelBackgoundColour
motionLabel.textColour = labelTextColour
motionLabel.width = axisMotionPanel.width
motionLabel.height = 18
motionLabel.x = 0
motionLabel.y = 0

-- XY Axis

for axis=xAxis,yAxis do
  local axisLabel = axisMotionPanel:Label("AxisLabel" .. axis)
  axisLabel.height = 40
  axisLabel.width = 24
  if axis == xAxis then
    axisLabel.text = "X"
    axisLabel.y = motionLabel.y + motionLabel.height + 10
  else
    axisLabel.text = "Y"
    axisLabel.y = motionLabel.y + motionLabel.height + 63
  end
  axisLabel.tooltip = "Settings for the current axis"
  axisLabel.textColour = labelBackgoundColour
  axisLabel.backgroundColour = labelTextColour
  axisLabel.fontSize = 22
  axisLabel.x = 5

  local gridOffset = axisMotionPanel:Slider("GridOffset" .. axis, gridXY[axis].offset, 0, gridXY[axis].max - 1)
  gridOffset.displayName = "Offset"
  gridOffset.tooltip = "Offset of the current axis (can be adjusted by the top XY controller)"
  gridOffset.backgroundColour = menuBackgroundColour
  gridOffset.textColour = menuTextColour
  gridOffset.height = 45
  gridOffset.width = 60
  gridOffset.x = axisLabel.x + axisLabel.width + xSpacing
  gridOffset.y = axisLabel.y - 5
  gridOffset.changed = function(self)
    local offset = gem.round(self.value)
    if offset ~= gridXY[axis].offset then
      gridXY[axis].offset = offset
      gridXY[axis].mustAdvance = true
      setSelectedGrid()
    end
  end

  local gridLength = axisMotionPanel:Slider("GridSize" .. axis, gridXY[axis].size, 1, gridXY[axis].max)
  gridLength.displayName = "Length"
  gridLength.tooltip = "Length of current axis (can be adjusted by the bottom XY controller)"
  gridLength.backgroundColour = menuBackgroundColour
  gridLength.textColour = menuTextColour
  gridLength.height = gridOffset.height
  gridLength.width = gridOffset.width
  gridLength.x = gridOffset.x + gridOffset.width + xSpacing
  gridLength.y = gridOffset.y
  gridLength.changed = function(self)
    local size = gem.round(self.value)
    if size ~= gridXY[axis].size then
      gridXY[axis].size = size
      gridXY[axis].mustAdvance = true
      setSelectedGrid()
    end
  end

  local seqPlayMode = axisMotionPanel:Menu("SequencerPlayMode" .. axis, playModes)
  seqPlayMode.displayName = "Mode"
  seqPlayMode.tooltip = "The sequencer play mode for the current axis"
  seqPlayMode.x = gridLength.x + gridLength.width + xSpacing
  seqPlayMode.y = gridLength.y
  seqPlayMode.height = gridLength.height
  seqPlayMode.width = 75
  seqPlayMode.backgroundColour = menuBackgroundColour
  seqPlayMode.textColour = menuTextColour
  seqPlayMode.arrowColour = menuArrowColour
  seqPlayMode.outlineColour = menuOutlineColour
  seqPlayMode.changed = function(self)
    setDirectionFromPlaymode(axis, self.text)
  end
  seqPlayMode:changed()

  local chordNotes = axisMotionPanel:NumBox("ChordNotes" .. axis, gridXY[axis].chordNotes, 2, gridXY[axis].max, true)
  local chordNoteIncrement = axisMotionPanel:NumBox("ChordNoteIncrement" .. axis, gridXY[axis].chordNotesIncrement, 1, (math.floor(gridXY[axis].max / 2) + 1), true)
  local randomChordButton = axisMotionPanel:OnOffButton("RandomChordButton" .. axis, gridXY[axis].randomChord)

  local chordButton = axisMotionPanel:OnOffButton("ChordButton" .. axis, gridXY[axis].chord)
  chordButton.backgroundColourOff = backgroundColourOff
  chordButton.backgroundColourOn = backgroundColourOn
  chordButton.textColourOff = textColourOff
  chordButton.textColourOn = textColourOn
  chordButton.displayName = "Polymode"
  chordButton.tooltip = "In polymode, mutiple notes are played along the current axis"
  chordButton.size = {100,20}
  chordButton.x = seqPlayMode.x + seqPlayMode.width + xSpacing
  chordButton.y = seqPlayMode.y + 3
  chordButton.changed = function(self)
    gridXY[axis].chord = self.value
    if self.value then
      gridXY[axis].chordNotes = chordNotes.value
    else
      gridXY[axis].chordNotes = 1
    end
    chordNotes.enabled = self.value
    chordNoteIncrement.enabled = self.value and randomChordButton.value == false
    randomChordButton.enabled = self.value
  end
  chordButton:changed()

  chordNotes.enabled = false
  chordNotes.showLabel = false
  chordNotes.displayName = "Notes"
  chordNotes.tooltip = "Number of notes to play in polymode"
  chordNotes.backgroundColour = menuBackgroundColour
  chordNotes.textColour = menuTextColour
  chordNotes.size = {30,20}
  chordNotes.x = chordButton.x + chordButton.width + 1
  chordNotes.y = chordButton.y
  chordNotes.changed = function(self)
    gridXY[axis].chordNotes = self.value
  end

  chordNoteIncrement.enabled = false
  chordNoteIncrement.displayName = "Distance"
  chordNoteIncrement.tooltip = "The distance in steps up the scale between notes in polymode"
  chordNoteIncrement.backgroundColour = menuBackgroundColour
  chordNoteIncrement.textColour = menuTextColour
  chordNoteIncrement.size = {81,20}
  chordNoteIncrement.x = chordButton.x
  chordNoteIncrement.y = chordButton.y + chordButton.height + 2
  chordNoteIncrement.changed = function(self)
    gridXY[axis].chordNotesIncrement = self.value
  end

  randomChordButton.enabled = false
  randomChordButton.backgroundColourOff = backgroundColourOff
  randomChordButton.backgroundColourOn = backgroundColourOn
  randomChordButton.textColourOff = textColourOff
  randomChordButton.textColourOn = textColourOn
  randomChordButton.displayName = "Random"
  randomChordButton.tooltip = "Select chord notes by chance from within the active axis"
  randomChordButton.size = {48,chordNotes.height}
  randomChordButton.x = chordNoteIncrement.x + chordNoteIncrement.width + 2
  randomChordButton.y = chordNoteIncrement.y
  randomChordButton.changed = function(self)
    gridXY[axis].randomChord = self.value
    chordNoteIncrement.enabled = self.value == false
  end

  local increment = axisMotionPanel:Knob("Increment" .. axis, gridXY[axis].increment, .1, (gridXY[axis].max / 3))
  increment.displayName = "Increment"
  increment.tooltip = "Set the increment amount per step on the current axis"
  increment.backgroundColour = widgetBackgroundColour
  increment.fillColour = knobFillColour
  increment.outlineColour = labelBackgoundColour
  increment.showPopupDisplay = true
  increment.height = 39
  increment.width = 100
  increment.y = seqPlayMode.y + 8
  increment.x = randomChordButton.x + randomChordButton.width + xSpacing
  increment.changed = function(self)
    gridXY[axis].increment = self.value
    setDirectionFromPlaymode(axis, seqPlayMode.text)
  end

  local advanceProbability = axisMotionPanel:Knob("AdvanceProbability" .. axis, gridXY[axis].advanceProbability, 0, 100, true)
  advanceProbability.unit = Unit.Percent
  advanceProbability.displayName = "Advance"
  advanceProbability.tooltip = "Set the probability that the position will advance on the current axis"
  advanceProbability.backgroundColour = widgetBackgroundColour
  advanceProbability.fillColour = knobFillColour
  advanceProbability.outlineColour = labelBackgoundColour
  advanceProbability.showPopupDisplay = true
  advanceProbability.height = increment.height
  advanceProbability.width = increment.width
  advanceProbability.y = increment.y
  advanceProbability.x = increment.x + increment.width + xSpacing
  advanceProbability.changed = function(self)
    gridXY[axis].advanceProbability = self.value
  end

  local randomProbability = axisMotionPanel:Knob("RandomProbability" .. axis, gridXY[axis].randomProbability , 0, 100, true)
  randomProbability.unit = Unit.Percent
  randomProbability.displayName = "Random"
  randomProbability.tooltip = "Set the probability that the position on the current axis will be selected by chance"
  randomProbability.backgroundColour = widgetBackgroundColour
  randomProbability.fillColour = knobFillColour
  randomProbability.outlineColour = labelBackgoundColour
  randomProbability.showPopupDisplay = true
  randomProbability.height = advanceProbability.height
  randomProbability.width = advanceProbability.width
  randomProbability.y = advanceProbability.y
  randomProbability.x = advanceProbability.x + advanceProbability.width
  randomProbability.changed = function(self)
    gridXY[axis].randomProbability = self.value
  end
end

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

local function releaseVoices()
  for i,v in ipairs(modular.getActiveVoices()) do
    if v.data.backgroundColour == menuSelectedBackgroundColour then
      v.data.textColour = noteSelectedTextColour
    else
      v.data.textColour = menuTextColour
    end
  end
  modular.releaseVoices()
  setPos()
end

local function handleTrigger(e)
  local notesForPlaying = getNotes() -- The selected note inputs to play
  if #notesForPlaying > 0 then
    for _,noteInput in ipairs(notesForPlaying) do
      modular.handleTrigger(e, noteInput.value, noteInput)
      noteInput.textColour = notePlayingTextColour
    end
  end
end

local function handleReleaseTrigger(e)
  for i,v in ipairs(modular.getActiveVoices()) do
    if v.channel == e.channel then
      if v.data.backgroundColour == menuSelectedBackgroundColour then
        v.data.textColour = noteSelectedTextColour
      else
        v.data.textColour = menuTextColour
      end
    end
  end
  modular.releaseVoices()
end

function onInit()
  print("Init grid sequencer")
  setSelectedGrid()
  scaleIncrementInput:changed()
  degreeInput:changed()
end

function onNote(e)
  if noteListen then
    for i,v in ipairs(noteInputs) do
      if listeners[i].value then
        v:setValue(e.note)
        listeners[i]:setValue(false)
      end
    end
    noteListen = false
  end
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    handleTrigger(e)
  else
    postEvent(e)
  end
end

function onRelease(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    handleReleaseTrigger(e)
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start == false then
    releaseVoices()
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  return {scaleIncrementInput.text, degreeInput.text}
end

function onLoad(data)
  scaleIncrementInput.text = data[1]
  degreeInput.text = data[2]
  scaleIncrementInput:changed()
  degreeInput:changed()
end
