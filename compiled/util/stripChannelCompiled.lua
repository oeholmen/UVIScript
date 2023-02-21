-- util/stripChannel -- 
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

------------------------------------------------------------------
-- Remove channel on note events
------------------------------------------------------------------

local sequencerPanel = widgets.panel({
  width = 720,
  height = 50,
})

widgets.label("Strip Channel", {
  width = sequencerPanel.width,
  height = 50,
  alpha = 0.75,
  fontSize = 30,
  backgroundColour = "505050",
  textColour = "3fe09f"
})

widgets.label("Remove channel on incoming note events", {
  width = 300,
  backgroundColour = "transparent",
  textColour = "a0a0a0",
  x = 240,
  y = 15,
})

local activeButton = widgets.button("Active", true, {
  tooltip = "Toggle state",
  x = 580,
  y = 15,
})

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

function onNote(e)
  if activeButton.value then
    e.channel = nil
  end
  postEvent(e)
end

function onRelease(e)
  if activeButton.value then
    e.channel = nil
  end
  postEvent(e)
end
