-- util/recordingSequencer -- 
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
-- Recording Sequencer - A sequencer with recording
--------------------------------------------------------------------------------

-- TODO Record only selected midi channel?

local resolutionNames = resolutions.getResolutionNames()
local quantizeResolutions = {
  "1/1", -- 11
  "1/1 tri", -- 13
  "1/2", -- 14
  "1/2 tri", -- 16
  "1/4", -- 17
  "1/4 tri", -- 19
  "1/8", -- 20
  "1/8 tri", -- 22
  "1/16", -- 23
  "1/16 tri", -- 25
  "1/32", -- 26
  "1/32 tri", -- 28
  "1/64", -- 29
  "1/64 tri", -- 31
  "Off"
}
local resolution = #resolutionNames
local isPlaying = false
local recordActive = true
local recordActivatedDuringRun = false
local recordButton
local recordOptions
local positionTable
local countIn = 4
local baseSequenceResolution = 1 -- 1/4 TODO Metronome/tick?
local seqIndex = 0 -- Holds the unique id for the base sequencer
local tickResolution = resolutions.getTriplet(resolutions.getPlayDuration())
local steps = 16
local maxSteps = 128
local ticks = steps / tickResolution
local tickCounter = 0 -- Holds the current sequence tick (position)
local sequence = {} -- Holds the recorded sequence
local noteSequence = {} -- Holds the sequence per note
local takesCounter = 0 -- Holds the counter for takes
local createTakeForEachRound = false -- Whether to create a take for each round
local backgroundColour = "117744" -- Light or Dark

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function setTableZero(theTable)
  for i=1,theTable.length do
    theTable:setValue(i, 0)
  end
end

local function isQuantizeOff()
  return resolution == #resolutionNames
end

local function isQuantizeOn()
  return isQuantizeOff() == false
end

local function getSequenceForNote(note)
  for _,v in ipairs(noteSequence) do
    if note == v.note then
      return v
    end
  end
end

local function drawNoteInTable(note, tickPos, value)
  if type(value) == "nil" then
    value = 1
  end
  local seq = getSequenceForNote(note)
  if type(seq) == "table" then
    seq.table:setValue(tickPos, value)
  end
end

local function drawNoteTicks(tickPos, eventPos, value)
  local note = sequence[tickPos][eventPos].note
  local startPos = sequence[tickPos][eventPos].startPos
  local endPos = sequence[tickPos][eventPos].endPos

  if type(endPos) == "nil" then
    endPos = startPos
  end

  if startPos > endPos then
    startPos = startPos - ticks
  end

  print("drawNoteTicks, note, tickPos, startPos, endPos, value", note, tickPos, startPos, endPos, value)

  for i=startPos, endPos do
    local tick = i
    if tick < 1 then
      tick = tick + ticks
    end
    drawNoteInTable(note, tick, value)
  end
end

local function getEventsForTick(tick)
  local tickEvents = {}

  for _,v in ipairs(noteSequence) do
    local isStart = v.table:getValue(tick) > 0 and v.table:getValue(getPreviousTick(tick)) == 0
    if isStart then
      local eventLength = 0
      local endPos = tick
      while eventLength < ticks and v.table:getValue(endPos) > 0 do
        -- TODO Handle eternal loop
        endPos = getNextTick(endPos)
        eventLength = gem.inc(eventLength)
      end
      table.insert(tickEvents, {
        note = v.note,
        startPos = tick,
        endPos = endPos,
        velocity = 64,
        channel = nil,
      })
    end
  end

  return tickEvents
  -- TODO Use events from note tables
  --[[ local startPos = tick
  local endPos = tick

  if isQuantizeOn() then
    local quantizeTo = resolutions.getResolution(resolution)
    local ticksInResolution = quantizeTo / tickResolution
    local ticksInQuantization = math.floor(ticksInResolution / 2)
    startPos = math.max(-ticksInQuantization, (tick - ticksInQuantization))
    endPos = math.min(ticks, (tick + ticksInQuantization - 1))
  end

  local tickEvents = {}

  for i=startPos,endPos do
    local tickPos = i
    if tickPos < 1 then
      tickPos = tickPos + ticks
    end
    for _,e in ipairs(sequence[tickPos]) do
      table.insert(tickEvents, e)
    end
  end

  --print("Found tickEvents for tick", #tickEvents, tick)

  return tickEvents ]]
end

local function playTick()
  local tickEvents = getEventsForTick(tickCounter)
  for _,e in ipairs(tickEvents) do
    if isKeyDown(e.note) == false then
      if type(e.endPos) == "nil" then
        e.endPos = ticks
        print("Missing end pos")
      end
      local diff = e.endPos - e.startPos
      if diff < 0 then
        diff = diff + ticks
      end
      local duration = diff * tickResolution
      playNote(e.note, e.velocity, beat2ms(duration), nil, e.channel)
      --print("note, startPos, endPos, diff, duration", e.note, e.startPos, e.endPos, diff, duration)
    end
  end
end

local function getPreviousTick(tick, step)
  if type(step) == "nil" then
    step = 1
  end
  local previousTick = tick - math.abs(step)
  if previousTick < 1 then
    previousTick = previousTick + ticks
  end
  return previousTick
end

local function getNextTick(tick, step)
  if type(step) == "nil" then
    step = 1
  end
  local nextTick = tick + step
  if nextTick > ticks then
    nextTick = nextTick - ticks
  end
  return nextTick
end

local function shouldPlayTick(tick)
  if isQuantizeOff() then
    return true
  end

  local quantizeTo = resolutions.getResolution(resolution)
  local ticksInResolution = quantizeTo / tickResolution
  local ticksDurationForResolution = tickResolution * ticksInResolution

  return (tick - 1) % ticksInResolution == 0 and quantizeTo == ticksDurationForResolution
end

local function getQantizedPos(tick)
  local quantizedPos = tick
  local forward = tick
  local backward = tick

  while shouldPlayTick(forward) == false do
    forward = gem.inc(forward)
  end

  while shouldPlayTick(backward) == false do
    backward = gem.inc(backward, -1)
  end

  local diffForward = forward - tick
  local diffBackward = backward - tick

  if math.abs(diffBackward) > diffForward then
    -- Go forward
    quantizedPos = forward
    if quantizedPos > ticks then
      quantizedPos = ticks - quantizedPos
    end
  else
    -- Go backward
    quantizedPos = backward
    if quantizedPos < 1 then
      quantizedPos = quantizedPos + ticks
    end
  end

  --print("tick, forward, backward, diffForward, diffBackward, quantizedPos", tick, forward, backward, diffForward, diffBackward, quantizedPos)

  return quantizedPos
end

local function clearNoteTables()
  for _,v in ipairs(noteSequence) do
    setTableZero(v.table)
  end
end

local function drawNoteTables(startPosKey)
  if type(startPosKey) == "nil" then
    startPosKey = "qantizedStartPos"
  end
  for _,v in ipairs(noteSequence) do
    if #v.events > 0 then
      setTableZero(v.table)
    end
    for _,e in ipairs(v.events) do
      local startPos = math.max(1, e[startPosKey])
      local endPos = math.min(ticks, startPos + e.eventLength)
      print("Draw note from "..startPosKey.." to endPos", v.note, startPos, endPos)
      for tickPos=startPos,endPos do
        v.table:setValue(tickPos, 1)
      end
    end
  end
end

local function quantizeSequence()
  for _,v in ipairs(noteSequence) do
    --print("Quantize note events", v.note)
    local events = {} -- Reset current events for this note
    local isStart = false
    local isEnd = false
    local eventLength = 0
    local startPos
    local qantizedStartPos
    for tick=1,v.table.length do
      local tickIsActive = v.table:getValue(tick) > 0
      if tickIsActive then
        eventLength = gem.inc(eventLength)
        --print("Note is active @ tick", tick)
      end
      isStart = tickIsActive and (tick == 1 or v.table:getValue(getPreviousTick(tick)) == 0)
      isEnd = tickIsActive and (tick == ticks or v.table:getValue(getNextTick(tick)) == 0)
      if isStart then
        startPos = tick
        qantizedStartPos = getQantizedPos(tick)
        print("Event started @ tick", tick)
      end
      if isEnd then
        print("Event ended @ tick, length", tick, eventLength)
        table.insert(events, {
          startPos = startPos,
          qantizedStartPos = qantizedStartPos,
          eventLength = eventLength,
        })
      end
    end
    v.events = events
  end
  drawNoteTables()
end

local function lastTakeIsEmpty()
  for i,tickEvents in ipairs(sequence) do
    for i,v in ipairs(tickEvents) do
      if v.take == takesCounter then
        print("Found an event for take", takesCounter)
        return false
      end
    end
  end

  print("No events for take", takesCounter)
  return true
end

local function incrementTakesCounter()
  if takesCounter > 0 and lastTakeIsEmpty() then
    return
  end

  takesCounter = gem.inc(takesCounter, 1)
  print("Set takesCounter", takesCounter)
end

local function sequenceRunner(uniqueId)
  local tablePos = 1
  local countInPos = 0
  local countInActive = recordActive and countInPos < countIn
  local countInTicks = countIn / tickResolution
  local internalTickCounter = 0
  tickCounter = 0
  if countInActive then
    tickCounter = -countInTicks
  end
  local countInQuantizeTo = 1 -- 1/4
  local countInTicksInResolution = countInQuantizeTo / tickResolution
  local countInTicksDurationForResolution = tickResolution * countInTicksInResolution
  local roundCounter = 0
  --print("tickCounter", tickCounter)
  while isPlaying and seqIndex == uniqueId do
    tickCounter = gem.inc(tickCounter, 1, ticks)
    internalTickCounter = gem.inc(internalTickCounter, 1, ticks)
    if internalTickCounter == 1 then
      roundCounter = gem.inc(roundCounter)
      if recordActive and recordOptions.text == "Punch Out" and roundCounter > 1 then
        if recordActivatedDuringRun or countInActive then
          recordActivatedDuringRun = false
        else
          recordButton:setValue(false)
        end
      end
      if createTakeForEachRound then
        incrementTakesCounter()
      end
    end
    if (internalTickCounter - 1) % countInTicksInResolution == 0 and countInQuantizeTo == countInTicksDurationForResolution then
      if countInActive then
        if countInPos == countIn then
          countInActive = false
          internalTickCounter = 1
          tablePos = 1
        elseif countInPos < countIn then
          positionTable.sliderColour = "orange"
        end
        countInPos = gem.inc(countInPos)
      end

      if countInActive == false then
        if recordActive then
          positionTable.sliderColour = "red"
        else
          positionTable.sliderColour = "green"
        end
      end

      setTableZero(positionTable)
      positionTable:setValue(tablePos, 1)
      tablePos = gem.inc(tablePos, 1, positionTable.length)
    end

    if countInActive == false then
      if tickCounter ~= internalTickCounter then
        print("tickCounter ~= internalTickCounter", tickCounter, internalTickCounter)
      end

      if shouldPlayTick(internalTickCounter) then
        playTick()
      end
    end

    waitBeat(tickResolution)
  end
end

local function removeTake()
  if lastTakeIsEmpty() then
    takesCounter = gem.inc(takesCounter, -1)
  end

  if takesCounter < 1 then
    return
  end

  local newSequence = {}
  for i=1,ticks do
    local tickEvents = {}
    for j,v in ipairs(sequence[i]) do
      if v.take == takesCounter then
        print("Skipping event for take", takesCounter)
        drawNoteTicks(i, j, 0)
        -- TODO Update events on noteSequence
      else
        print("Keeping event for take", v.take)
        table.insert(tickEvents, v)
      end
    end
    table.insert(newSequence, tickEvents)
  end

  sequence = newSequence -- Set sequence
end

local function adjustSequenceTable()
  print("Adjust sequence length, ticks", ticks)
  local newSequence = {}
  for i=1,ticks do
    local tickEvents = {}
    if type(sequence[i]) == "table" then
      tickEvents = sequence[i]
    end
    table.insert(newSequence, tickEvents)
  end
  sequence = newSequence -- Set sequence
  -- TODO Update events on noteSequence
end

local function initSequenceTable()
  print("Delete recording")
  takesCounter = 0
  sequence = {}
  for i=1,ticks do
    table.insert(sequence, {})
  end
  clearNoteTables()
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  if recordActive and createTakeForEachRound == false then
    incrementTakesCounter()
  end
  seqIndex = gem.inc(seqIndex)
  run(sequenceRunner, seqIndex)
end

local function stopPlaying()
  isPlaying = false
  setTableZero(positionTable)
  if recordOptions.text == "Punch Out" then
    recordButton:setValue(false)
  end
end

--------------------------------------------------------------------------------
-- Widgets
--------------------------------------------------------------------------------

widgets.panel({
  backgroundColour = "113344",
  x = 3,
  y = 3,
  width = 714,
  height = 48,
})

widgets.setSection({
  x = 15,
  y = 15,
  xSpacing = 15,
})

local labelWidget = widgets.label("Recording Sequencer", {
  tooltip = "Record and play back a sequence",
  alpha = 0.5,
  fontSize = 22,
  width = 210,
  editable = true,
})

widgets.col()

recordButton = widgets.button("Record", recordActive, {
  tooltip = "When record is enabled, the count in will play before the sequencer starts. Use transport or the Play button to start recording.",
  width = 96,
  changed = function(self)
    recordActive = self.value
    if recordActive then
      recordActivatedDuringRun = isPlaying
      positionTable.sliderColour = "red"
    else
      recordActivatedDuringRun = false
      positionTable.sliderColour = "green"
    end
  end
})

local autoplayButton = widgets.button("Auto Play", true, {
  tooltip = "Start automatically on transport",
  width = 96,
})

local playButton = widgets.button("Play", false, {
  width = 96,
  changed = function(self)
    if self.value then
      startPlaying()
    else
      stopPlaying()
    end
  end
})

widgets.panel({
  backgroundColour = backgroundColour,
  x = widgets.getPanel().x,
  y = widgets.posUnder(widgets.getPanel()),
  width = widgets.getPanel().width,
  height = 380,
})

widgets.setSection({
  x = 0,
  y = 5,
  ySpacing = 1,
})

for i=84,24,-1 do
  local noteTable = widgets.table("Note", 0, ticks, {
    name = "Note_" .. i,
    max = 1,
    integer = true,
    persistent = false,
    sliderColour = "blue",
    backgroundColour = "gray",
    width = 714,
    height = 6,
  })
  table.insert(noteSequence, {
    note = i,
    events = {},
    table = noteTable
  })

  widgets.row(1, 5)
end

print("noteSequence", #noteSequence)

positionTable = widgets.table("SequencePosition", 0, steps, {
  max = 1,
  integer = true,
  enabled = false,
  persistent = false,
  sliderColour = "green",
  backgroundColour = "cfffe",
  width = 714,
  height = 6,
})

widgets.panel({
  backgroundColour = backgroundColour,
  x = widgets.getPanel().x,
  y = widgets.posUnder(widgets.getPanel()),
  width = widgets.getPanel().width,
  height = 60,
})

widgets.setSection({
  x = 10,
  y = 10,
  ySpacing = 5,
  xSpacing = 15,
})

widgets.numBox("Steps", steps, {
  tooltip = "Lowest note - notes below this are passed through",
  min = 4,
  max = maxSteps,
  integer = true,
  changed = function(self)
    steps = self.value
    ticks = steps / tickResolution
    positionTable.length = steps
    for _,v in ipairs(noteSequence) do
      v.table.length = ticks
    end
    adjustSequenceTable()
  end
}):changed()

widgets.menu("Quantize", #quantizeResolutions, quantizeResolutions, {
  tooltip = "Set the quantize resolution",
  changed = function(self)
    local resolutionIndex = gem.getIndexFromValue(self.text, resolutionNames)
    if type(resolutionIndex) == "nil" then
      resolution = #resolutionNames
    else
      resolution = resolutionIndex
    end
    print("Quantize resolution", resolution)
    quantizeSequence()
  end
})

recordOptions = widgets.menu("Record Mode", 1, {
  "Punch Out",
  "Loop",
})

widgets.menu("Actions", 1, {
  "Select...",
  "Undo last take",
  "Quantize",
  "Undo Quantize",
  "--- Danger Zone ---",
  "Clear sequence",
}, {
  changed = function(self)
    if self.text == "Clear sequence" then
      initSequenceTable()
    elseif self.text == "Quantize" then
      quantizeSequence()
    elseif self.text == "Undo Quantize" then
      drawNoteTables("startPos")
    elseif self.text == "Undo last take" then
      removeTake()
    end
    self:setValue(1, false)
  end
})

widgets.row()

widgets.numBox("Count In", countIn, {
  tooltip = "Set a count in",
  min = 0,
  max = 4,
  integer = true,
  changed = function(self)
    countIn = self.value
  end
})

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
end

function onTransport(start)
  if autoplayButton.value == true then
    playButton:setValue(start)
  end
end

function onNote(e)
  if isPlaying and recordActive then
    local tickPos = tickCounter
    if tickPos < 1 then
      tickPos = tickPos + ticks
    end
    if takesCounter < 1 then
      incrementTakesCounter()
    end
    table.insert(sequence[tickPos], {note = e.note, velocity = e.velocity, channel = e.channel, startPos = tickPos, take = takesCounter})
    drawNoteInTable(e.note, tickPos)
    --print("Set note, startPos, take, #events@pos", e.note, tickPos, takesCounter, #sequence[tickPos])
  end
  postEvent(e)
end

function onRelease(e)
  if isPlaying and recordActive then
    for tick,events in ipairs(sequence) do
      for i,tickEvent in ipairs(events) do
        if e.note == tickEvent.note and type(tickEvent.endPos) == "nil" then
          sequence[tick][i].endPos = tickCounter
          print("Set note, endPos", e.note, sequence[tick][i].endPos)
          drawNoteTicks(tick, i)
        end
      end
    end
  end
  postEvent(e)
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  return {labelWidget.text, sequence}
end

function onLoad(data)
  labelWidget.text = data[1]
  sequence = data[2]
end
