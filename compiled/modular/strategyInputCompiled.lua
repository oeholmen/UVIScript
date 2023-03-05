-- modular/strategyInput -- 
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
  --print("Widget name", name)
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
  if type(options.mapper) == "number" then
    widget.mapper = options.mapper
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
  if type(options.hierarchical) == "boolean" then
    widget.hierarchical = options.hierarchical
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
  getPanel = function() return widgetDefaults.panel end,
  getSectionValue = function(k) return widgetDefaults[k] end,
  xOffset = function(val) widgetDefaults.xOffset = val end,
  yOffset = function(val) widgetDefaults.yOffset = val end,
  x = function(val) widgetDefaults.xOffset = val end,
  y = function(val) widgetDefaults.yOffset = val end,
  xSpacing = function(val) widgetDefaults.xSpacing = val end,
  ySpacing = function(val) widgetDefaults.ySpacing = val end,
  posSide = function(widget) return widget.x + widget.width + widgetDefaults.xSpacing end,
  posUnder = function(widget) return widget.y + widget.height + widgetDefaults.ySpacing end,
  width = function(val) widgetDefaults.width = val end,
  height = function(val) widgetDefaults.height = val end,
  col = function(i, w, h) incrementCol(i, w, h) end,
  row = function(i, h) incrementRow(i, h) end,
  panel = function(options)
    if type(options) ~= "table" then
      options = {}
    end
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
  {def={2,2,1,2,2,2,1},name="7 Notes/Major (Ionian)",},
  {def={2,1,2,2,1,2,2},name="7 Notes/Minor (Aeolian)",},
  {def={2,1,2,2,2,1,2},name="7 Notes/Dorian",},
  {def={1,2,2,2,1,2,2},name="7 Notes/Phrygian",},
  {def={2,2,2,1,2,2,1},name="7 Notes/Lydian",},
  {def={2,2,1,2,2,1,2},name="7 Notes/Mixolydian",},
  {def={1,2,2,1,2,2,2},name="7 Notes/Locrian",},
  {def={2,2,2,1,2,1,2},name="7 Notes/Acoustic",},
  {def={2,1,2,1,1,3,2},name="7 Notes/Blues",},
  {def={1,2,1,3,1,2,2},name="7 Notes/Alterated",},
  {def={2,1,2,2,2,1,2},name="7 Notes/Yo",},
  {def={2,1,3,1,1,3,1},name="7 Notes/Maqam Saba",},
  {def={1,3,1,2,3,1,1},name="7 Notes/Persian",},
  {def={1,3,1,2,1,3,1},name="7 Notes/Arabic",},
  {def={2,1,3,1,1,2,2},name="7 Notes/Hungarian",},
  {def={2,2,3,2,3},name="5 Notes/Major Pentatonic",},
  {def={3,2,2,3,2},name="5 Notes/Minor Pentatonic",},
  {def={1,4,1,4,2},name="5 Notes/Hirajoshi",},
  {def={1,4,2,1,4},name="5 Notes/Miyako-Bushi",},
  {def={1,4,3,2,2},name="5 Notes/Iwato",},
  {def={2,2,1,2,2},name="5 Notes/Ritsu",},
  {def={2,1,4,2,1},name="5 Notes/Kumoi",},
  {def={1,3,1,2,3},name="5 Notes/Maqam Hijaz",},
  {def={2,1,4,1,2},name="5 Notes/Maqam Bayati",},
  {def={2,1,4,2,1,2},name="Misc/In",},
  {def={3},name="Misc/Diminished",},
  {def={2},name="Misc/Whole tone",},
  {def={1},name="Misc/Chomatic",},
}

local function getScaleNames()
  local items = {}
  for _,s in ipairs(scaleDefinitions) do
    table.insert(items, s.name)
  end
  return items
end

local function getScaleDefinitions()
  local items = {}
  for _,s in ipairs(scaleDefinitions) do
    table.insert(items, s.def)
  end
  return items
end

local function getTextFromScaleDefinition(scaleDefinition)
  if type(scaleDefinition) == nil or #scaleDefinition == 0 then
    return ""
  end
  return table.concat(scaleDefinition, ",")
end

local function getScaleDefinitionFromText(scaleText)
  local scale = {}
  if string.len(scaleText) > 0 then
    for w in string.gmatch(scaleText, "%d+") do
      table.insert(scale, tonumber(w))
    end
    print("Get scale from input", #scale)
  end
  return scale
end

local function getScaleWidget(width, showLabel, i)
  -- Scale widget
  if type(width) == "nil" then
    width = 120
  end
  if type(i) == "nil" then
    i = ""
  end
  return widgets.menu("Scale", #scaleDefinitions, getScaleNames(), {
    name = "Scale" .. i,
    tooltip = "Select a scale",
    hierarchical = true,
    width = width,
    showLabel = showLabel ~= false,
  })
end

local function getScaleInputWidget(scaleDefinition, width, i)
  -- Scale input widget
  if type(width) == "nil" then
    width = 120
  end
  if type(i) == "nil" then
    i = ""
  end
  return widgets.label(getTextFromScaleDefinition(scaleDefinition), {
    tooltip = "Scales are defined by setting semitones up from the previous note, separated by comma. If 12 is divisible by the definition sum, it will resolve every octave.",
    editable = true,
    backgroundColour = "black",
    backgroundColourWhenEditing = "white",
    textColourWhenEditing = "black",
    textColour = "white",
    width = width
  })
end

local scales = {
  widget = getScaleWidget,
  inputWidget = getScaleInputWidget,
  getTextFromScaleDefinition = getTextFromScaleDefinition,
  getScaleDefinitionFromText = getScaleDefinitionFromText,
  getScaleDefinitions = getScaleDefinitions,
  getScaleNames = getScaleNames,
  createScale = function(scaleDefinition, rootNote, maxNote)
    if type(maxNote) ~= "number" then
      maxNote = 127
    end
    while rootNote < 0 do
      rootNote = rootNote + 12
      print("Transpose root note up to within range", rootNote)
    end
    while maxNote > 127 do
      maxNote = maxNote - 12
      print("Transpose max note down to within range", maxNote)
    end
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

  getOctave = function(noteNumber)
    return math.floor(noteNumber / 12) - 2
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

-----------------------------------------------------------------------------------------------------------------
-- Strategy Input - A standard sequencer that listens to incoming events on note 0
-----------------------------------------------------------------------------------------------------------------

local channel = 0 -- 0 = Omni
local forward = false
local voices = 1 -- Holds the maximum amount of seen voices
local strategyPropbability = 100
local strategyInput = ""
local strategyRestart = 1
local voiceSlotStrategy = false
local randomSlotStrategy = false
local strategyPos = {} -- Holds the position in the selected strategy
local notePosition = {} -- Holds the current note position
local unusedStrategySlotDefaultText = "Unused"
local strategySlots = {}
local selectedNotes = {}
local key = 1
local noteMin = 48
local noteMax = noteMin + 24
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinition = scaleDefinitions[#scaleDefinitions]
local rangeOverlapAmount = 50
local numSlots = 8
local isPlaying = false
local resolutionNames = resolutions.getResolutionNames()
local resolution = 11

-- Strategies are ways to play chords and scales
local strategies = {
  {}, -- Randomize next note position +/- 1 oct
  {1}, -- Up
  {-1}, -- Down
  {2,-1}, -- Alternate up
  {-2,1}, -- Alternate down
  {-1,1,-2,-1,3}, -- Generated 1
  {3,1,-1,2}, -- Generated 2
  {-3,2}, -- Generated 3
  {2,2,3}, -- Up v 2
  {-3,-2,-2}, -- Down v 2
  {3,-2,7},
  {-5,4,4},
  {7,7,-5},
  {7,5,6},
  {-7,2,7},
  {7,0,-7},
  {4,0,-4},
  {0},
  {4,-2},
  {3,-2},
}

--------------------------------------------------------------------------------
-- Strategy Functions
--------------------------------------------------------------------------------

-- Returns the notes filtered by scale and range
local function setNotes()
  local scale = scales.createScale(scaleDefinition, (key - 1), noteMax)
  selectedNotes = {} -- Reset selectedNotes
  for _,note in ipairs(scale) do
    if note >= noteMin and note <= noteMax then
      table.insert(selectedNotes, note)
    end
  end
  --print("Found selectedNotes within selected scale/range", #selectedNotes)
end

local function createStrategy()
  local maxLength = 16 -- TODO Param?
  local strategy = {} -- Table to hold strategy
  local ln = gem.getRandom(maxLength) -- Length
  for i=1, ln do
    local value = gem.getRandom(-7,7)
    table.insert(strategy, value)
    --print("Add value to strategy", value)
  end
  return strategy
end

local function getStrategyInputText(strategy)
  if type(strategy) == nil or #strategy == 0 then
    return "Randomize"
  end
  return table.concat(strategy, ",")
end

local function getStrategyFromSlot(voice)
  if randomSlotStrategy then
    local slots = {}
    for _,v in ipairs(strategySlots) do
      if v.enabled == true then
        table.insert(slots, v)
      end
    end
    if #slots > 0 then
      local slot = gem.getRandomFromTable(slots)
      --slot:setValue(true)
      return slot.tooltip
    end
  end
  if voiceSlotStrategy then
    if voice > numSlots then
      voice = voice - numSlots
    end
    local slot = strategySlots[voice]
    if slot.enabled then
      return slot.tooltip
    end
  end
end

local function getNotePosition(noteCount, voice)
  local maxIndex = noteCount
  local preferLowerHalf = type(notePosition[voice]) == "nil" or notePosition[voice] > maxIndex
  -- Prefer lower/upper half when resetting, depending on above or below range
  if noteCount > 7 then
    noteCount = math.ceil(noteCount / 2)
  end
  --print("maxIndex, noteCount, preferLowerHalf", maxIndex, noteCount, preferLowerHalf)
  if maxIndex > noteCount then
    if preferLowerHalf then
      -- Lower half
      --print("Resetting in lower half", 1, noteCount)
      return gem.getRandom(1, noteCount)
    else
      -- Upper half
      --print("Resetting in upper half", noteCount, maxIndex)
      return gem.getRandom(noteCount, maxIndex)
    end
  elseif maxIndex > 1 then
    --print("Resetting within full range", maxIndex)
    return gem.getRandom(maxIndex)
  end
  return 1
end

local function getNoteFromStrategy(filteredNotes, voice)
  local strategy = {}
  local strategyText = getStrategyFromSlot(voice)
  -- Get strategy from input field if not found in a slot
  if type(strategyText) ~= "string" or string.len(strategyText) == 0 then
    strategyText = strategyInput
  end
  if string.len(strategyText) > 0 then
    for w in string.gmatch(strategyText, "-?%d+") do
      table.insert(strategy, tonumber(w))
    end
    --print("Get strategy from input or slot, voice", #strategy, voice)
  end
  -- Get random strategy from default strategies
  if #strategy == 0 then
    strategy = gem.getRandomFromTable(strategies)
    --print("No strategy found - use random strategy from default strategies")
  end
  -- Reset strategy position if required
  if type(strategyPos[voice]) == "nil" or strategyPos[voice] > #strategy then
    strategyPos[voice] = 1
    --print("Reset strategy position for voice", voice)
    if strategyRestart == 3 or strategyRestart == 4 then
      notePosition[voice] = nil -- Reset counter for note position
      --print("Reset note position for voice due to strategyRestart == 2", voice)
    end
  end
  if type(notePosition[voice]) == "nil" or #strategy == 0 then
    -- Start at a random notePosition
    notePosition[voice] = getNotePosition(#filteredNotes, voice)
    --print("Set random notePosition, voice", notePosition[voice], voice)
    if strategyRestart == 2 then
      strategyPos[voice] = 1
    end
  else
    -- Get next notePosition from strategy
    --print("Increment notePosition, voice", notePosition[voice], voice)
    notePosition[voice] = gem.inc(notePosition[voice], strategy[strategyPos[voice]])
    --print("After increment notePosition, voice", notePosition[voice], voice)
    if notePosition[voice] > #filteredNotes or notePosition[voice] < 1 then
      notePosition[voice] = getNotePosition(#filteredNotes, voice)
      --print("Out of range - set random note position for voice", notePosition[voice], voice)
      if strategyRestart == 2 then
        strategyPos[voice] = 1
        --print("Reset strategy position for voice due to strategyRestart == 2", voice)
      end
    else
      -- Increment strategy pos
      if #strategy > 1 then
        strategyPos[voice] = gem.inc(strategyPos[voice])
        --print("Increment strategy position for voice", strategyPos[voice], voice)
      end
    end
  end
  return filteredNotes[notePosition[voice]]
end

-- Returns the selected notes filtered by overlap range and playing notes
local function getFilteredNotes(voice)
  local noteRangeMin = 1
  local noteRangeMax = #selectedNotes
  local notesPerVoice = 5
  local notesRequiredForRange = voices * notesPerVoice

  --print("BEFORE selectedNotes, voices, voice", #selectedNotes, voices, voice)

  -- Adjust note range min/max for voice overlap, if we have enough available notes
  if #selectedNotes >= notesRequiredForRange then
    local range = #selectedNotes / voices
    --print("range, voices, voice", range, voices, voice)
    local overlapValue = math.ceil(range * (rangeOverlapAmount / 100))
    --print("overlapValue, voice", overlapValue, voice)
    noteRangeMax = math.min(noteRangeMax, ((range * voice) + overlapValue))
    noteRangeMin = math.max(1, (noteRangeMax - range - overlapValue))
    --print("noteRangeMin, noteRangeMax, voice", noteRangeMin, noteRangeMax, voice)
  end

  -- Find the notes, filter for min/max
  local filteredNotes = {}
  for i,v in ipairs(selectedNotes) do
    if i >= math.floor(noteRangeMin) and i <= math.ceil(noteRangeMax) then
      table.insert(filteredNotes, v)
    end
  end

  --print("AFTER notes, voice", #filteredNotes, voice)
  return filteredNotes
end

local function getNote(voice)
  if type(voice) == "nil" then
    voice = 1
  end

  -- Set the voices count
  --if voice > 1 then
    voices = math.max(voice, voices)
  --end

  local filteredNotes = getFilteredNotes(voice)

  if #filteredNotes == 0 then
    return nil
  end

  if #filteredNotes == 1 then
    return filteredNotes[1]
  end

  if gem.getRandomBoolean(strategyPropbability) then
    return getNoteFromStrategy(filteredNotes, voice)
  end

  return gem.getRandomFromTable(filteredNotes)
end

-----------------------------------------------------------------------------------------------------------------
-- Sequencer Panel
-----------------------------------------------------------------------------------------------------------------

widgets.setSection({
  width = 720,
})

local sequencerPanel = widgets.panel({
  height = 30,
})

local sequencerLabel = widgets.label("Strategy Input", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  height = 30,
  editable = true,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 100,
  xOffset = 300,
  yOffset = 5,
  xSpacing = 5,
  ySpacing = 5,
  labelBackgroundColour = "transparent",
})

local voicesLabel = widgets.label("Playing", {
  visible = false,
  textColour = "505050"
})

widgets.setSection({
  xOffset = 510,
})

widgets.button("Forward", forward, {
  tooltip = "Forward triggers (note=0 events) to the next processor",
  changed = function(self) forward = self.value end,
})

widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to triggers (note=0 events) on this channel. In omni mode, each channel is sent to a separate voice.",
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

--------------------------------------------------------------------------------
-- Strategy Panel
--------------------------------------------------------------------------------

widgets.setSection({
  width = 720,
  x = 0,
  y = widgets.posUnder(sequencerPanel),
})

widgets.panel({
  height = 84,
  backgroundColour = "404040"
})

-- Strategy input field
local strategyInputField = widgets.label(getStrategyInputText(gem.getRandomFromTable(strategies)), {
  tooltip = "Strategies are ways to play notes in a scale. Numbers represent steps up or down the scale that is currently selected. Feel free to type your own strategies here.",
  editable = true,
  backgroundColour = "black",
  backgroundColourWhenEditing = "white",
  textColourWhenEditing = "black",
  textColour = "white",
  width = 276,
  height = 20,
  x = 5,
  y = 5,
  changed = function(self) strategyInput = self.text end
})
strategyInputField:changed()

-- Slots
widgets.setSection({
  width = 30,
  height = 20,
  x = strategyInputField.x,
  y = widgets.posUnder(strategyInputField),
  cols = 8,
})

local actions = {"Actions..."}
for j=1,numSlots do
  local strategySlot = widgets.button("" .. j, false, {
    tooltip = unusedStrategySlotDefaultText,
    enabled = false,
  })
  strategySlot.changed = function(self)
    strategyInputField.text = strategySlot.tooltip
    self.value = false
  end
  table.insert(strategySlots, strategySlot)
  table.insert(actions, "Save to " .. j)
end

table.insert(actions, "--- Load ---")
for _,v in ipairs(strategies) do
  table.insert(actions, getStrategyInputText(v))
end

widgets.setSection({
  width = 116,
  height = 20,
  x = strategyInputField.x,
  y = widgets.posUnder(strategyInputField) + 24,
  cols = 6,
})

local voiceSlotStrategyInput = widgets.menu("Play Mode", {"Active Input", "Random Slot", "Voice->Slot"}, {
  tooltip = "Select the strategy to use for note selection. The default is using the strategy displayed in the input.",
  showLabel = false,
  changed = function(self)
    randomSlotStrategy = self.value == 2
    voiceSlotStrategy = self.value == 3
    notePosition = {}
  end
})

local strategyActions = widgets.menu("Actions", actions, {
  tooltip = "Available actions for strategies",
  width = 90,
  showLabel = false,
})

widgets.button("Create", {
  tooltip = "Replace the current strategy with a randomly created strategy.",
  width = 60,
  changed = function()
    local strategy = createStrategy()
    strategyInputField.text = table.concat(strategy, ",")
  end
})

-- Options
widgets.setSection({
  width = 120,
  height = 20,
  x = widgets.posSide(strategyInputField) + 2,
  y = strategyInputField.y,
})

widgets.menu("Strategy", strategyRestart, {"Restart each round", "Out of range", "When finished", "Finished+round"}, {
  tooltip = "Controls when the strategy is restarted",
  changed = function(self) strategyRestart = self.value end
})

widgets.menu("Key", key, notes.getNoteNames(), {
  width = 50,
  changed = function(self)
    key = self.value
    setNotes()
  end
})

local scaleMenu = scales.widget(120, true)

widgets.label("Scale Definition", {
  textColour = "#d0d0d0"
})

widgets.row()

local scaleInput = scales.inputWidget(scaleDefinition, 120)
scaleInput.x = widgets.posSide(scaleMenu)

widgets.row()

widgets.numBox("Probability", strategyPropbability, {
  tooltip = "Probability that the active playing strategy will be used to select the next note. Otherwise notes are selected by random.",
  unit = Unit.Percent,
  changed = function(self) strategyPropbability = self.value end
})

local noteMinInput = widgets.numBox("Note Range", noteMin, {
  width = 105,
  max = noteMax,
  tooltip = "Lowest note",
  unit = Unit.MidiKey,
})

local noteMaxInput = widgets.numBox("Max", noteMax, {
  min = noteMin,
  width = 30,
  showLabel = false,
  tooltip = "Highest note",
  unit = Unit.MidiKey,
})

widgets.numBox("Overlap", rangeOverlapAmount, {
  tooltip = "Set the overlap range for the voices. 100 = all voices use the full range, 0 = separate ranges. Requires at least 5 notes per voice.",
  width = 90,
  --showLabel = false,
  unit = Unit.Percent,
  changed = function(self) rangeOverlapAmount = self.value end
})

--widgets.row()

widgets.menu("Resolution", resolution, resolutionNames, {
  tooltip = "Set the round duration that is used for strategy restart.",
  width = 60,
  showLabel = false,
  changed = function(self)
    resolution = self.value
  end
})

--------------------------------------------------------------------------------
-- Changed functions for widgets
--------------------------------------------------------------------------------

scaleMenu.changed = function(self)
  scaleInput.text = scales.getTextFromScaleDefinition(scaleDefinitions[self.value])
end

scaleInput.changed = function(self)
  scaleDefinition = scales.getScaleDefinitionFromText(self.text)
  print("#scaleDefinition", #scaleDefinition)
  setNotes()
end

noteMinInput.changed = function(self)
  noteMaxInput:setRange(self.value, 127)
  noteMin = self.value
  setNotes()
end

noteMaxInput.changed = function(self)
  noteMinInput:setRange(0, self.value)
  noteMax = self.value
  setNotes()
end

strategyActions.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local actionIndex = self.value - 1

  -- Save strategy
  if actionIndex <= #strategySlots then
    if string.len(strategyInputField.text) > 0 then
      strategySlots[actionIndex].tooltip = strategyInputField.text
      strategySlots[actionIndex].enabled = true
    else
      strategySlots[actionIndex].tooltip = unusedStrategySlotDefaultText
      strategySlots[actionIndex].enabled = false
    end
    --print("Strategy saved to slot", strategyInputField.text, actionIndex)
  elseif actionIndex > #strategySlots + 1 then
    strategyInputField.text = self.selectedText
  end

  -- Must be last
  self:setValue(1, false)
end

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function sequenceRunner()
  print("Starting sequenceRunner")
  local round = 1
  while isPlaying do
    if strategyRestart == 1 or strategyRestart == 4 then
      notePosition = {} -- Reset counter for note position
      if strategyRestart == 4 then
        strategyPos = {} -- Reset strategy position
      end
    end
    print("Round", round)
    waitBeat(resolutions.getResolution(resolution))
    round = gem.inc(round)
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
  print("Stop playing")
  if type(voiceId) == "userdata" then
    releaseVoice(voiceId)
  end
  isPlaying = false
  voiceId = nil
  currentEvent = nil
end

local function flashVoicesLabel()
  voicesLabel.textColour = "303030"
  waitBeat(.125)
  voicesLabel.textColour = "505050"
end

function onInit()
  setNotes()
end

function onNote(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    if modular.handleTrigger(e, getNote(e.channel)) then
      voicesLabel.text = "Playing " .. voiceSlotStrategyInput.text
      spawn(flashVoicesLabel)
      voicesLabel.visible = true
      startPlaying()
    end
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
  if start then
    startPlaying()
  else
    voices = 1 -- Reset voices when stopping
    voicesLabel.visible = false
    modular.releaseVoices()
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local strategySlotsData = {}
  for _,v in ipairs(strategySlots) do
    table.insert(strategySlotsData, v.tooltip)
  end

  return {sequencerLabel.text, strategyInputField.text, scaleInput.text, strategySlotsData}
end

function onLoad(data)
  sequencerLabel.text = data[1]
  strategyInputField.text = data[2]
  scaleInput.text = data[3]
  local strategySlotsData = data[4]

  scaleInput:changed() -- Ensure the scale is updated

  for i,v in ipairs(strategySlots) do
    v.tooltip = strategySlotsData[i]
    v.enabled = v.tooltip ~= unusedStrategySlotDefaultText
  end
end
