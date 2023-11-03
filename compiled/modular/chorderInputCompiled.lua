-- modular/chorderInput -- 
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
  knobHeight = 45,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
  col = 0,
  row = 0,
  rowDirection = 1,
  cols = 6
}

local widgetColours = {
  backgroundColour = "202020",
  panelBackgroundColour = "202020",
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
  buttonBackgroundColourOff = "#606060",
  buttonBackgroundColourOn = "#303030",
  buttonTextColourOff = "white",
  buttonTextColourOn = "silver",
}

local function getValueOrDefault(value, default)
  if type(value) == "nil" then
    return default
  elseif type(value) == "function" then
    return value(default, widgetDefaults)
  end
  return value
end

local function setColours(colours)
  widgetColours.backgroundColour = getValueOrDefault(colours.backgroundColour, widgetColours.backgroundColour)
  widgetColours.panelBackgroundColour = getValueOrDefault(colours.panelBackgroundColour, widgetColours.panelBackgroundColour)
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
  widgetColours.buttonBackgroundColourOff = getValueOrDefault(colours.buttonBackgroundColourOff, widgetColours.buttonBackgroundColourOff)
  widgetColours.buttonBackgroundColourOn = getValueOrDefault(colours.buttonBackgroundColourOn, widgetColours.buttonBackgroundColourOn)
  widgetColours.buttonTextColourOff = getValueOrDefault(colours.buttonTextColourOff, widgetColours.buttonTextColourOff)
  widgetColours.buttonTextColourOn = getValueOrDefault(colours.buttonTextColourOn, widgetColours.buttonTextColourOn)
end

local function setSection(settings)
  if type(settings) ~= "table" then
    settings = {}
  end
  setColours(settings)
  widgetDefaults.width = getValueOrDefault(settings.width, widgetDefaults.width)
  widgetDefaults.height = getValueOrDefault(settings.height, widgetDefaults.height)
  widgetDefaults.menuHeight = getValueOrDefault(settings.menuHeight, widgetDefaults.menuHeight)
  widgetDefaults.knobHeight = getValueOrDefault(settings.knobHeight, widgetDefaults.knobHeight)
  widgetDefaults.xOffset = getValueOrDefault(settings.xOffset, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getValueOrDefault(settings.yOffset, widgetDefaults.yOffset)
  widgetDefaults.xOffset = getValueOrDefault(settings.x, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getValueOrDefault(settings.y, widgetDefaults.yOffset)
  widgetDefaults.xSpacing = getValueOrDefault(settings.xSpacing, widgetDefaults.xSpacing)
  widgetDefaults.ySpacing = getValueOrDefault(settings.ySpacing, widgetDefaults.ySpacing)
  widgetDefaults.cols = getValueOrDefault(settings.cols, widgetDefaults.cols)
  widgetDefaults.col = getValueOrDefault(settings.col, 0)
  widgetDefaults.row = getValueOrDefault(settings.row, 0)
  widgetDefaults.rowDirection = getValueOrDefault(settings.rowDirection, 1)
  currentX = widgetDefaults.xOffset
  if widgetDefaults.rowDirection < 0 and widgetDefaults.row > 0 then
    -- Find y when direction is reverse
    local heightPerRow = widgetDefaults.height + widgetDefaults.ySpacing
    currentY = (heightPerRow * widgetDefaults.row) + widgetDefaults.ySpacing
  else
    currentY = widgetDefaults.yOffset
  end
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
  local yAdjust = height + ySpacing
  if row > 0 then
    currentY = currentY + yAdjust
  else
    currentY = currentY - yAdjust
  end
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
    incrementRow(widgetDefaults.rowDirection, h)
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
  section = setSection,
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
    widgetDefaults.panel.backgroundColour = widgetColours.panelBackgroundColour
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
      widget.backgroundColourOff = widgetColours.backgroundColourOff
      widget.backgroundColourOn = widgetColours.backgroundColourOn
      widget.textColourOff = widgetColours.textColourOff
      widget.textColourOn = widgetColours.textColourOn
    else
      widget = widgetDefaults.panel:Button(options.name)
      widget.backgroundColourOff = widgetColours.buttonBackgroundColourOff
      widget.backgroundColourOn = widgetColours.buttonBackgroundColourOn
      widget.textColourOff = widgetColours.buttonTextColourOff
      widget.textColourOn = widgetColours.buttonTextColourOn
    end
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
  knob = function(displayName, default, options)
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:Knob(options.name, options.default, options.min, options.max, options.integer)
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.widgetBackgroundColour
    widget.textColour = widgetColours.widgetTextColour
    if widget.showLabel == true then
      options.height = getValueOrDefault(options.height, widgetDefaults.knobHeight)
    end
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
local listenOnChannel = 0 -- 0 = Omni
local forwardModularEvents = false

local function isNoteInActiveVoices(note)
  for _,v in ipairs(activeVoices) do
    if v.note == note then
      return true
    end
  end
  return false
end

local function isTrigger(e)
  local isListeningForEvent = listenOnChannel == 0 or listenOnChannel == e.channel
  local isTrigger = e.note == 0 -- Note 0 is used as trigger
  --print("isTrigger and isListeningForEvent, channel, e.channel", isTrigger, isListeningForEvent, listenOnChannel, e.channel)
  if isTrigger and isListeningForEvent and forwardModularEvents then
    postEvent(e)
  end
  return isTrigger and isListeningForEvent
end

local function handleTrigger(e, note, data)
  --print("handleTrigger, note, isNoteInActiveVoices(note)", note, isNoteInActiveVoices(note))
  if type(note) == "number" and isNoteInActiveVoices(note) == false then
    local id = playNote(note, e.velocity, -1, nil, e.channel)
    table.insert(activeVoices, {id=id,note=note,channel=e.channel,data=data})
    return true
  end
  return false
end

local function handleReleaseTrigger(e)
  local keep = {} -- The notes to keep
  for i,v in ipairs(activeVoices) do
    if v.channel == e.channel then
      -- Release all voices on this channel
      releaseVoice(v.id)
    else
      -- Keep the voice
      table.insert(keep, v)
    end
  end
  local hasReleased = #activeVoices > #keep
  activeVoices = keep -- Update active voices
  return hasReleased
end

local function releaseActiveVoicesInModular()
  for i,v in ipairs(activeVoices) do
    releaseVoice(v.id)
  end
  activeVoices = {}
end

local function getForwardWidget(options)
  if type(options) == "nil" then
    options = {}
  end
  options.tooltip = gem.getValueOrDefault(options.tooltip, "Forward triggers (note=0 events) to the next processor")
  options.changed = gem.getValueOrDefault(options.changed, function(self) forwardModularEvents = self.value end)
  return widgets.button("Forward", forwardModularEvents, options)
end

local function getChannelWidget(options)
  if type(options) == "nil" then
    options = {}
  end
  options.tooltip = gem.getValueOrDefault(options.tooltip, "Listen to triggers (note=0 events) on this channel - if a note event is not being listened to, it will pass through")
  options.showLabel = gem.getValueOrDefault(options.showLabel, false)
  options.changed = gem.getValueOrDefault(options.changed, function(self)
    listenOnChannel = self.value - 1
    releaseActiveVoicesInModular()
  end)

  return widgets.menu("Channel", widgets.channels(), options)
end

local modular = {
  isTrigger = isTrigger,
  handleTrigger = handleTrigger,
  handleReleaseTrigger = handleReleaseTrigger,
  releaseVoices = releaseActiveVoicesInModular,
  getChannelWidget = getChannelWidget,
  getForwardWidget = getForwardWidget,
  setChannel = function(c) listenOnChannel = c end,
  getChannel = function() return listenOnChannel end,
  setForward = function(f) forwardModularEvents = f end,
  getForward = function() return forwardModularEvents end,
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
  {def={3},name="Diminished",},
  {def={2},name="Whole tone",},
  {def={1},name="Chomatic",},
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

local function createRandomScale(resolve, probability)
  if type(resolve) == "nil" then
    resolve = 12 -- The sum of the definition should resolve to this
  end
  if type(probability) == "nil" then
    probability = 50 -- Probability that the selected interval is 1 or 2
  end
  local sum = 0 -- Current scale definion sum
  local maxSum = 24
  local intervals1 = {1,2}
  local intervals2 = {1,2,3,4}
  local scaleDefinition = {}
  repeat
    local interval = 1
    if gem.getRandomBoolean(probability) then
      interval = gem.getRandomFromTable(intervals1)
    else
      interval = gem.getRandomFromTable(intervals2)
    end
    table.insert(scaleDefinition, interval)
    sum = gem.inc(sum, interval)
  until #scaleDefinition > 3 and (resolve % sum == 0 or maxSum % sum == 0 or sum >= maxSum)
  return scaleDefinition
end

local function getScaleDefinitionFromText(scaleText)
  local scale = {}
  if string.len(scaleText) > 0 then
    for w in string.gmatch(scaleText, "%d+") do
      local stepIncrement = tonumber(w)
      if stepIncrement > 0 then
        table.insert(scale, stepIncrement)
      end
    end
    print("Get scale from input", #scale)
  end
  return scale
end

local function getScaleDefinitionIndex(scaleDefinition)
  -- Check if we find a scale definition that matches the given definition
  if type(scaleDefinition) == "table" then
    scaleDefinition = getTextFromScaleDefinition(scaleDefinition)
  end
  for i,v in ipairs(scaleDefinitions) do
    if scaleDefinition == getTextFromScaleDefinition(v.def) then
      print("getScaleDefinitionIndex: found scale", v.name)
      return i
    end
  end
end

local function getScaleInputTooltip(scaleDefinition)
  local sum = gem.sum(scaleDefinition)
  local tooltip = "Scales are defined by setting semitones up from the previous note. The current scale has " .. #scaleDefinition .. " notes and the definition sum is " .. sum
  if 12 % sum == 0 then
    tooltip = tooltip .. ", whitch resolves every octave."
  else
    tooltip = tooltip .. ", whitch does not resolve every octave."
  end
  return tooltip
end

local function getScaleWidget(options, i)
  -- Scale widget
  if type(options) == "nil" then
    options = {}
  end
  if type(i) == "nil" then
    i = ""
  end
  options.name = gem.getValueOrDefault(options.name, "Scale" .. i)
  options.tooltip = gem.getValueOrDefault(options.tooltip, "Select a scale")
  options.hierarchical = true
  options.showLabel = gem.getValueOrDefault(options.showLabel, true)
  return widgets.menu("Scale", #scaleDefinitions, getScaleNames(), options)
end

local function getScaleInputWidget(scaleDefinition, width, i)
  -- Scale input widget
  if type(i) == "nil" then
    i = ""
  end
  local options = {
    name = "ScaleInput" .. i,
    tooltip = getScaleInputTooltip(scaleDefinition),
    editable = true,
    backgroundColour = "black",
    backgroundColourWhenEditing = "white",
    textColourWhenEditing = "black",
    textColour = "white",
  }
  if type(width) == "number" then
    options.width = width
  end
  return widgets.label(getTextFromScaleDefinition(scaleDefinition), options)
end

local function handleScaleInputChanged(self, scaleMenu)
  print("scaleInput.changed", self.text)
  local scaleDefinition = getScaleDefinitionFromText(self.text)
  if #scaleDefinition == 0 then
    -- Ensure we have a scale...
    print("No scale def. Using default scale.")
    scaleDefinition = scaleDefinitions[#scaleDefinitions]
    scaleMenu:setValue(#scaleDefinitions)
    return handleScaleInputChanged(self, scaleMenu)
  end
  self.tooltip = getScaleInputTooltip(scaleDefinition)
  return scaleDefinition
end

local scales = {
  widget = getScaleWidget,
  inputWidget = getScaleInputWidget,
  getScaleInputTooltip = getScaleInputTooltip,
  getScaleDefinitionIndex = getScaleDefinitionIndex,
  handleScaleInputChanged = handleScaleInputChanged,
  getTextFromScaleDefinition = getTextFromScaleDefinition,
  getScaleDefinitionFromText = getScaleDefinitionFromText,
  getScaleDefinitions = getScaleDefinitions,
  getScaleNames = getScaleNames,
  createRandomScale = createRandomScale,
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

-----------------------------------------------------------------------------------
-- Generative Chorder - Listens for incoming note events (rythm) on note number 0
-----------------------------------------------------------------------------------

local backgroundColour = "404040" -- Light or Dark
local panelBackgroundColour = "505050" -- Light or Dark
local menuBackgroundColour = "01011F"
local widgetBackgroundColour = menuBackgroundColour -- Dark
local widgetTextColour = "9f02ACFE" -- Light
local labelTextColour = "black"
local menuArrowColour = "66" .. labelTextColour

widgets.setColours({
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = labelTextColour,
  menuBackgroundColour = menuBackgroundColour,
  menuArrowColour = menuArrowColour,
  backgroundColour = backgroundColour,
  panelBackgroundColour = panelBackgroundColour,
})

local paramsPerPart = {}

-- *** NOTE *** The chord definitions use steps in the selected scale, not semitones.
-- 2 means two steps up the scale: C-E for a C major scale. A-C for an A minor scale.
local chordDefinitions = {
  {2,2,3}, -- Builds triads
  {2,2,2,1}, -- Builds 7th chords
  {3,1,3}, -- Builds supended chords
  {2,2,1,2}, -- Builds 6th chords
  {2,2,2,2,-1}, -- Builds 7th and 9th chords depending on polyphony
  {1,1,2,2,1}, -- Builds (close) 7th and 9th chords
  {4,3}, -- Builds open chords (no3)
  {1,2,1,2,1}, -- Builds supended chords including 7th and 9ths
}

local noteDisplay = {} -- Holds the widgets that displays the notes being played
local maxVoices = 16 -- Max number of oplyphonic voices
local noteNumberToNoteName = notes.getNoteMapping()
local scale = {}
local key = 1
local noteMin = 24
local noteMax = noteMin + (5 * 12)
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinition = scaleDefinitions[#scaleDefinitions]

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Scale and note functions
--------------------------------------------------------------------------------

-- Returns the notes filtered by scale and range
local function setScale()
  scale = {} -- Reset scale
  for _,note in ipairs(scales.createScale(scaleDefinition, (key - 1), noteMax)) do
    if note >= noteMin and note <= noteMax then
      table.insert(scale, note)
    end
  end
end

-- Use the selected chord definition to find the index for the next note in the chord
local function getNextScaleIndex(note, scale, chordDefinition, inversionIndex)
  local index = gem.getIndexFromValue(note, scale)
  --print("getNextScaleIndex #chordDefinition/inversionIndex", #chordDefinition, inversionIndex)
  local increment = chordDefinition[inversionIndex]
  if type(index) == "nil" then
    index = 0
    --print("!!!Note not found in scale!!!")
  end
  return index + increment
end

local function notesInclude(notesTable, note)
  for _,v in pairs(notesTable) do
    if v.note == note then
      --print("Note already included", note)
      return true
    end
  end
  return false
end

local function hasNoteWithinMonoLimit(notesTable, partPos)
  local monoLimit = paramsPerPart[partPos].monoLimit.value
  for _,v in pairs(notesTable) do
    if v.note <= monoLimit then
      return true
    end
  end
  return false
end

local function isRootNote(note, partPos)
  -- Note index is 1 higher than note number
  local noteIndex = note + 1
  return noteNumberToNoteName[key] == noteNumberToNoteName[noteIndex]
end

local function createChordDefinition(part)
  local maxSteps = 4 -- Max steps
  local maxLength = paramsPerPart[part].polyphony.value -- Max length depends on polyphony
  local definition = {} -- Table to hold definition
  local ln = gem.getRandom(maxLength) -- Set a random length for the definition
  for i=1, ln do
    local steps = gem.getRandom(maxSteps)
    table.insert(definition, steps)
    --print("Add steps to definition", steps)
  end
  return definition
end

local function getChordInputText(definition)
  if #definition == 0 then
    return "Randomize"
  end
  return table.concat(definition, ",")
end

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local tableWidth = 720

local sequencerPanel = widgets.panel({
  width = tableWidth,
  height = 30,
  x = 0,
  y = 0,
})

local chorderLabel = widgets.label("Chorder Input", {
  width = tableWidth,
  height = 30,
  alpha = 0.5,
  fontSize = 22
})

widgets.setSection({
  x = 470,
  y = 5,
  xSpacing = 5,
  ySpacing = 5,
})

modular.getForwardWidget()
modular.getChannelWidget()

-- Add params that are to be editable per part
for i=1,1 do
  local numSlots = 8
  local chords = {}
  local spreads = {}
  local inversions = {}
  local chordDefinitionSlots = {}

  --------------------------------------------------------------------------------
  -- Chord Definition Panel
  --------------------------------------------------------------------------------
  
  local chordDefinitionPanel = widgets.panel({
    width = 356,
    height = 108,
    y = widgets.posUnder(sequencerPanel),
    x = 5,
  })

  widgets.section({
    width = 90,
    x = 5,
    y = 5,
    xSpacing = 5,
    ySpacing = 5,
    cols = 6,
  })

  local chordDefinitionLabel = widgets.label("Chord Definition", {
    backgroundColour = "transparent",
    textColour = "white",
    width = 155
  })

  local createChordDefinitionButton = widgets.button("Create", {
    tooltip = "Create a random chord definition.",
  })

  local chordSelectionMenu = widgets.menu("Chord Selection", {"Active Input", "Auto", "Random", "Slots"}, {
    tooltip = "Auto: Default chord definitions are alternated, Random: Chord definitions are created by random, Slots: Chord definitions are selected from the slots",
  })

  widgets.section({
    width = 90,
    x = 5,
    y = widgets.posUnder(chordDefinitionLabel),
    xSpacing = 5,
    ySpacing = 5,
    cols = 9,
  })

  local chordDefinitionInput = widgets.label(getChordInputText(chordDefinitions[1]), {
    tooltip = "The current chord definition. Numbers represent steps up or down the scale that is currently selected. Feel free to type your own chord definitions here, or select from the menu.",
    editable = true,
    width = 251,
    height = 45,
    fontSize = 22,
    backgroundColour = "black",
    textColour = "white",
    backgroundColourWhenEditing = "white",
    textColourWhenEditing = "black",
  })

  createChordDefinitionButton.changed = function()
    chordDefinitionInput.text = getChordInputText(createChordDefinition(i))
  end

  widgets.row()
  widgets.col(1, chordDefinitionInput.width)

  local loadActions = {"Load..."}
  for _,v in ipairs(chordDefinitions) do
    table.insert(loadActions, getChordInputText(v))
  end

  local loadChordDefinition = widgets.menu("Load Menu", loadActions, {
    tooltip = "Load a chord definition",
    showLabel = false,
    changed = function(self)
      -- 1 is the menu label...
      if self.value == 1 then
        return
      end
    
      local actionIndex = self.value - 1
      chordDefinitionInput.text = self.selectedText
    
      -- Must be last
      self.selected = 1
    end    
  })

  widgets.row()

  for j=1,numSlots do
    local definitionSlot = widgets.button("" .. j, false, {
      enabled = false,
      tooltip = "Unused",
      height = 20,
      width = 27,
      changed = function(self)
        chordDefinitionInput.text = self.tooltip
        self.value = false
      end
    })
    table.insert(chordDefinitionSlots, definitionSlot)
  end

  local saveActions = {"Save to..."}
  for j=1,numSlots do
    table.insert(saveActions, "Slot " .. j)
  end
  local saveChordDefinition = widgets.menu("Save", saveActions, {
    tooltip = "Save the current chord definition to the selected slot",
    showLabel = false,
    changed = function(self)
      -- 1 is the menu label...
      if self.value == 1 then
        return
      end
    
      local actionIndex = self.value - 1
    
      -- Save chord definition
      if string.len(chordDefinitionInput.text) > 0 then
        chordDefinitionSlots[actionIndex].tooltip = chordDefinitionInput.text
        chordDefinitionSlots[actionIndex].enabled = true
      else
        chordDefinitionSlots[actionIndex].tooltip = "Unused"
        chordDefinitionSlots[actionIndex].enabled = false
      end
      --print("Chord definition saved to slot", chordDefinitionInput.text, actionIndex)
    
      -- Must be last
      self.selected = 1
    end  
  })

  --------------------------------------------------------------------------------
  -- Polyphony and note limits
  --------------------------------------------------------------------------------
  
  local polyhonyPanel = widgets.panel({
    x = widgets.posSide(chordDefinitionPanel),
    y = chordDefinitionPanel.y,
    width = 348,
    height = 60,
  })
  
  widgets.section({
    width = 109,
    x = 5,
    y = 8,
    cols = 3,
  })

  local generatePolyphonyPart = widgets.numBox("Polyphony", 4, {
    tooltip = "How many notes are played at once",
    min = 1,
    max = maxVoices,
    integer = true,
  })
  generatePolyphonyPart.changed = function(self)
    for i,v in ipairs(noteDisplay) do
      v.enabled = maxVoices - self.value <= maxVoices - i
    end
  end

  local baseNoteRandomization = widgets.numBox("Base Chord", 25, {
    tooltip = "Probability that the root chord will be selected",
    unit = Unit.Percent,
  })

  local harmonizationPropbability = widgets.numBox("Harmonize", 100, {
    tooltip = "When harmonizing, we get notes from the currently playing chord. Otherwise notes are selected from the current scale.",
    unit = Unit.Percent,
  })

  local noteMinInput = widgets.numBox("Note Min", noteMin, {
    max = noteMax,
    tooltip = "Lowest note",
    unit = Unit.MidiKey,
  })

  local monoLimit = widgets.numBox("Mono Limit", noteMin + 24, {
    tooltip = "Below this note there will only be played one note (polyphony=1)",
    unit = Unit.MidiKey,
  })

  local noteMaxInput = widgets.numBox("Note Max", noteMax, {
    min = noteMin,
    tooltip = "Highest note",
    unit = Unit.MidiKey,
  })

  noteMinInput.changed = function(self)
    noteMaxInput:setRange(self.value, 127)
    noteMin = self.value
    setScale()
  end

  noteMaxInput.changed = function(self)
    noteMinInput:setRange(0, self.value)
    noteMax = self.value
    setScale()
  end  

  -- Key and scale
  local scalePanel = widgets.panel({
    x = chordDefinitionPanel.x,
    y = widgets.posUnder(chordDefinitionPanel),
    width = chordDefinitionPanel.width,
    height = 60,
  })

  widgets.section({
    width = 120,
    x = 5,
    y = 5,
    cols = 4,
  })

  local keyMenu = widgets.menu("Key", key, notes.getNoteNames(), {
    width = 60,
    changed = function(self)
      key = self.value
      setScale()
    end
  })

  local scaleMenu = scales.widget()
  scaleMenu.persistent = false -- Avoid running changed function on load, overwriting scaleInput

  widgets.label("Scale Definition", {
    textColour = "#d0d0d0",
    backgroundColour = "transparent",
  })

  widgets.row()
  widgets.col()
  widgets.col(1, keyMenu.width)

  local scaleInput = scales.inputWidget(scaleDefinition, 153)

  scaleMenu.changed = function(self)
    print("scaleMenu.changed", self.selectedText)
    scaleInput.text = scales.getTextFromScaleDefinition(scaleDefinitions[self.value])
  end

  scaleInput.changed = function(self)
    scaleDefinition = scales.handleScaleInputChanged(self, scaleMenu)
    setScale()
  end

  -- Note Spread
  local noteSpreadPanel = widgets.panel({
    x = widgets.posSide(scalePanel),
    y = widgets.posUnder(polyhonyPanel),
    width = 171,
    height = 108,
  })

  widgets.section({
    width = 159,
    x = 5,
    y = 5,
    cols = 1,
  })

  widgets.label("Note Spread (Voicing)", {
    textColour = "white",
    backgroundColour = "transparent",
  })

  table.insert(spreads, widgets.numBox("Close", 100, {
    tooltip = "Set the probability that close chords will be included",
    unit = Unit.Percent,
  }))

  table.insert(spreads, widgets.numBox("Medium", 100, {
    tooltip = "Set the probability that medium chords will be included",
    unit = Unit.Percent,
  }))

  table.insert(spreads, widgets.numBox("Wide", 100, {
    tooltip = "Set the probability that wide chords will be included",
    unit = Unit.Percent,
  }))

  -- Inversions
  local inversionPanel = widgets.panel({
    x = widgets.posSide(noteSpreadPanel),
    y = noteSpreadPanel.y,
    width = noteSpreadPanel.width,
    height = noteSpreadPanel.height,
  })

  widgets.section({
    width = 159,
    cols = 1,
  })

  widgets.label("Chord Inversions", {
    textColour = "white",
    backgroundColour = "transparent",
  })

  for inversion=1,3 do
    local p = 100
    if inversion == 3 then
      p = 0
    end
    table.insert(inversions, widgets.numBox("Inv " .. inversion, p, {
      name = "Inversion" .. inversion,
      tooltip = "Probability that inversion " .. inversion .. " will be included",
      unit = Unit.Percent,
    }))
  end

  table.insert(paramsPerPart, {scaleInput=scaleInput,scaleMenu=scaleMenu,keyMenu=keyMenu,chordDefinitionSlots=chordDefinitionSlots,chordDefinitionInput=chordDefinitionInput,chordSelectionMenu=chordSelectionMenu,inversions=inversions,spreads=spreads,chords=chords,baseNoteRandomization=baseNoteRandomization,polyphony=generatePolyphonyPart,harmonizationPropbability=harmonizationPropbability,monoLimit=monoLimit})
end

local voiceLabelWidth = 693 / maxVoices

local voicesPanel = widgets.panel({
  width = 710,
  height = 45,
  x = 5,
  y = 212,
  backgroundColour = "transparent"
})

widgets.section({
  width = voiceLabelWidth,
  cols = 16,
  x = 1,
  y = 2,
  xSpacing = 1,
  ySpacing = 1,
})

for j=1,maxVoices do
  local voiceLabel = widgets.label("Voice " .. j, {
    persistent = false,
  })
end

for j=1,maxVoices do
  table.insert(noteDisplay, widgets.label("-", {
    tooltip = "Displays the note played by voice " .. j,
    enabled = false,
    persistent = false,
    backgroundColour = "black",
    textColour = "white",
  }))
end

paramsPerPart[1].polyphony:changed()

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

local function getNotes()
  local currentPartPosition = 1 -- Holds the currently playing part
  local heldNoteIndex = 0
  local inversionIndex = 0
  local notesToPlay = {} -- Ensure notes are reset when seqencer starts

  -- Number of simultainious notes are set by polyphony
  local polyphony = paramsPerPart[currentPartPosition].polyphony.value
  local minNote = scale[1]
  local maxNote = scale[#scale]

  inversionIndex = 0 -- Reset counter for inversion progress
  -- Chord Selection: {"Active Input", "Auto", "Random", "Slots"}
  local chordSelection = paramsPerPart[currentPartPosition].chordSelectionMenu.selectedText
  if chordSelection == "Auto" then
    local index = gem.getRandom(#chordDefinitions)
    paramsPerPart[currentPartPosition].chordDefinitionInput.text = getChordInputText(chordDefinitions[index])
  elseif chordSelection == "Random" then
    paramsPerPart[currentPartPosition].chordDefinitionInput.text = getChordInputText(createChordDefinition(currentPartPosition))
  elseif chordSelection == "Slots" then
    local chordDefinitionSlots = {}
    for _,v in ipairs(paramsPerPart[currentPartPosition].chordDefinitionSlots) do
      if v.enabled == true then
        table.insert(chordDefinitionSlots, v)
      end
    end
    if #chordDefinitionSlots > 0 then
      chordDefinitionSlots[math.ceil(gem.getRandom(#chordDefinitionSlots))]:setValue(true)
    end
  end

  -- Find inversions to include
  local inversions = paramsPerPart[currentPartPosition].inversions
  local activeInversions = {0} -- Always add root
  for i,v in ipairs(inversions) do
    if gem.getRandomBoolean(v.value) == true then
      table.insert(activeInversions, i)
    end
  end

  if #activeInversions > 0 then
    -- Get a chord def index from the active definitions
    inversionIndex = gem.getRandomFromTable(activeInversions)
    --print("Chord inversion selected by random/#activeInversions", inversionIndex, #activeInversions)
  end

  -- Find spreads to include
  local selectedSpread = 2 -- Reset to default
  local spreads = paramsPerPart[currentPartPosition].spreads
  local activeSpreads = {}
  for i,v in ipairs(spreads) do
    if gem.getRandomBoolean(v.value) == true then
      table.insert(activeSpreads, i)
    end
  end

  if #activeSpreads > 0 then
    -- Get a chord def index from the active definitions
    if #activeSpreads > 1 then
      selectedSpread = activeSpreads[gem.getRandom(#activeSpreads)]
    else
      selectedSpread = activeSpreads[1]
    end
    --print("Chord spread selected by random: selectedSpread/#activeSpreads", selectedSpread, #activeSpreads)
  end

  --------------------------------------------------------------------------------
  -- Note functions
  --------------------------------------------------------------------------------

  -- Main function for getting note to play
  local function getNoteToPlay(voice, chordDefinition)
    -- Note generator function
    local function generateNote()
      local note = nil
      local baseNoteRandomization = paramsPerPart[currentPartPosition].baseNoteRandomization.value
      local monoLimit = paramsPerPart[currentPartPosition].monoLimit.value
      local baseMin = minNote
      local baseMax = maxNote

      if #scale == 0 then
        return note
      end

      if #scale == 1 then
        return scale[1]
      end

      if hasNoteWithinMonoLimit(notesToPlay, currentPartPosition) == true then
        -- Ensure we only have one note below the mono limit
        baseMin = monoLimit
        --print("Adjust baseMin to mono limit", baseMin)
      elseif monoLimit > baseMin then
        -- Ensure we have a note within the mono limit
        baseMax = monoLimit
        --print("Adjust baseMax to mono limit", baseMax)
      end

      local function getBaseNote()
        local baseNote = minNote -- Start from the lowest note
        if gem.getRandomBoolean(baseNoteRandomization) then
          while isRootNote(baseNote, currentPartPosition) == false and baseNote <= baseMax do
            baseNote = baseNote + 1 -- increment note until we hit the base note
          end
          --print("Get root note: note/baseMin/baseMax", baseNote, baseMin, baseMax)
        else
          local noteRange = baseMax - baseMin
          if monoLimit <= baseMin then
            -- If there is no mono limit, we ajust the note range by polyphony to get a base note range
            noteRange = math.max(12, math.ceil(noteRange / polyphony))
            --print("Calculate range for base note baseMin/baseMax/noteRange", baseMin, baseMax, noteRange)
          end
          baseNote = baseNote + gem.getRandom(noteRange) - 1
        end

        return notes.getNoteAccordingToScale(scale, baseNote)
      end

      -- The note on the first voice is the base note
      if voice == 1 then
        note = getBaseNote()
      end

      local harmonizationPropbability = paramsPerPart[currentPartPosition].harmonizationPropbability.value
      if type(note) == "nil" and gem.getRandomBoolean(harmonizationPropbability) == true then
        local startingNotes = {}
        for _,v in ipairs(notesToPlay) do
          table.insert(startingNotes, v.note)
          --print("Insert into startingNotes", v.note)
        end
        if #startingNotes > 0 then
          -- If we have notes added, use them as the basis for the next note
          --print("startingNotes", #startingNotes)
          local prevNote = startingNotes[#startingNotes]
          --print("Found prevNote", prevNote)
          -- Increment inversion index
          inversionIndex = inversionIndex + 1
          if inversionIndex > #chordDefinition then
            inversionIndex = 1
          end
          local scaleIndex = getNextScaleIndex(prevNote, scale, chordDefinition, inversionIndex)
          note = scale[scaleIndex]
          if type(note) == "number" then
            note = notes.transpose(note, baseMin, baseMax)
            local noteRange = baseMax - prevNote
            local octaveFactor = 12-- / (selectedSpread / 2)
            local octaveRange = math.floor(noteRange / octaveFactor)
            local notesLeft = polyphony - #notesToPlay
            local octave = 0
            local octaveProbability = 50
            local negOctProbability = 50
            if selectedSpread == 1 then
              octaveProbability = 15
              negOctProbability = 75
            elseif selectedSpread == 3 then
              octaveProbability = 75
              negOctProbability = 15
            end
            if gem.getRandomBoolean(octaveProbability) then
              octave = math.floor(octaveRange / notesLeft)
            end
            --print("Check octave/note/baseMax/negOctProbability", octave, note, baseMax, negOctProbability)
            if octave > 0 and octave < 3 and note > baseMax / 2 and gem.getRandomBoolean(negOctProbability) then
              octave = -octave
              --print("Negative octave", octave)
            end
            local octaveOffset = octave * 12
            --print("Calculate octave adjustment - noteRange/octaveRange/notesLeft/octave", noteRange, octaveRange, notesLeft, octave)
            if octaveOffset > 0 and note + octaveOffset <= baseMax then
              note = note + octaveOffset
              --print("Octave adjusted octave/octaveOffset/note", octave, octaveOffset, note)
            end
            --print("Found note from prev note - note, prevNote", note, prevNote)
          end
        end
      end

      -- Get random note from scale
      if type(note) == "nil" then
        note = notes.getNoteAccordingToScale(scale, gem.getRandom(baseMin, baseMax))
      end

      return note
    end

    -- Get notes for each node in the tree
    local note = generateNote()
    local noteToPlay = {
      note = note,
      voice = voice,
    }

    return noteToPlay
  end

  -- Get chord definition from input
  local chordDefinition = {}
  local input = paramsPerPart[currentPartPosition].chordDefinitionInput
  if string.len(input.text) > 0 then
    for w in string.gmatch(input.text, "-?%d+") do
      table.insert(chordDefinition, w)
      --print("Add to chordDefinition", w)
    end
    --print("Get chordDefinition from input", #chordDefinition)
  end

  -- Create a random chord definition if empty
  if #chordDefinition == 0 then
    chordDefinition = createChordDefinition(currentPartPosition)
  end
  
  -- Add notes to play
  local voice = 1
  local roundCounter = 0
  local maxRounds = polyphony * 2
  local monoLimit = paramsPerPart[currentPartPosition].monoLimit.value
  while voice <= polyphony and roundCounter < maxRounds do
    local noteToPlay = getNoteToPlay(voice, chordDefinition)
    if type(noteToPlay.note) == "number" and notesInclude(notesToPlay, noteToPlay.note) == false then
      table.insert(notesToPlay, noteToPlay)
      --print("Insert note", noteToPlay.note)
      noteDisplay[voice].text = noteNumberToNoteName[noteToPlay.note + 1] .. " (" .. noteToPlay.note .. ")"
      voice = voice + 1
    end
    roundCounter = gem.inc(roundCounter)
    --print("Searching for notes roundCounter", roundCounter)
  end
  print("Notes ready to play ", #notesToPlay)

  return notesToPlay
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

local function handleTrigger(e)
  local notesForPlaying = getNotes()
  if #notesForPlaying > 0 then
    for _,v in ipairs(notesForPlaying) do
      modular.handleTrigger(e, v.note)
    end
  end
end

function onInit()
  print("Init Chorder")
  setScale()
end

function onNote(e)
  if modular.isTrigger(e) then
    handleTrigger(e)
  else
    postEvent(e)
  end
end

function onRelease(e)
  if modular.isTrigger(e) then
    modular.handleReleaseTrigger(e)
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start == false then
    modular.releaseVoices()
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local chordDefinitionInputData = {}
  local chordDefinitionSlotsData = {}
  local scaleInputData = {}
  local i = 1

  for _,v in ipairs(paramsPerPart) do
    table.insert(chordDefinitionInputData, v.chordDefinitionInput.text)
    table.insert(scaleInputData, v.scaleInput.text)
    for _,s in ipairs(v.chordDefinitionSlots) do
      table.insert(chordDefinitionSlotsData, s.tooltip)
    end
  end

  return {chordDefinitionInputData, chordDefinitionSlotsData, scaleInputData}
end

function onLoad(data)
  local chordDefinitionInputData = data[1]
  local chordDefinitionSlotsData = data[2]
  local scaleInputData = data[3]

  local dataCounter = 1
  for i,v in ipairs(chordDefinitionInputData) do
    paramsPerPart[i].chordDefinitionInput.text = chordDefinitionInputData[i]

    -- Check if we find a scale definition that matches the stored definition
    local scaleIndex = scales.getScaleDefinitionIndex(scaleInputData[i])
    if type(scaleIndex) == "number" then
      print("onLoad, found scale", scaleIndex)
      paramsPerPart[i].scaleMenu:setValue(scaleIndex)
    end
    print("onLoad, scaleInput.text", scaleInputData[i])
    paramsPerPart[i].scaleInput.text = scaleInputData[i]
    paramsPerPart[i].scaleInput:changed()

    for _,v in ipairs(paramsPerPart[i].chordDefinitionSlots) do
      v.tooltip = chordDefinitionSlotsData[dataCounter]
      v.enabled = v.tooltip ~= "Unused"
      dataCounter = dataCounter + 1
    end
  end
end
