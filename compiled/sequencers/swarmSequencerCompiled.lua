-- sequencers/swarmSequencer -- 
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
-- Methods for working with shapes
--------------------------------------------------------------------------------

local getUnipolar = function(v) return (v + 1) / 2 end

-- Holds the shape definitions - functions get the following variables
-- x is the current time-value getting plotted, from -1.0 to 1.0
-- z is the current table number, from -1.0 to 1.0
-- w is the current time-value getting plotted, from 0.0 to 1.0 (same as (x+1)/2)
-- y is the current table number, from 0.0 to 1.0 (same as (z+1)/2)
-- pos = current index (from 0)
-- b = bounds (min, max, length, unipolar, rand)
local shapes = {
  ramp = function(x, z, pos, b) return x * z end,
  triangleShaper = function(x, z, pos, b) return math.min(2+2*x, math.abs((x-0.5)*2)-1) * z end,
  sine = function(x, z, pos, b) return math.sin(x*math.pi) * z end,
  tangent = function(x, z, pos, b) return math.tan(x) * z end,
  sawInPhase = function(x, z, pos, b) return (gem.sign(x)-x) * z end,
  sinToNoise = function(x, z, pos, b) return 2*gem.avg({math.sin(z*x*math.pi),(1-z)*gem.getRandom()}) end,
  wacky = function(x, z, pos, b) return math.sin(((x)+1)^(z-1)*math.pi) end,
  hpfSqrToSqr = function(x, z, pos, b) if x < 0 then return math.sin((z*0.5)*math.pi)^(x+1) end return -math.sin((z*0.5)*math.pi)^x end,
  windowYSqr = function(x, z, pos, b) local v = 1 if math.abs(x) > 0.5 then v = (1-math.abs(x))*2 end return v * math.min(1, math.max(-1,8*math.sin((z+0.02)*x*math.pi*32))) end,
  filteredSquare = function(x, z, pos, b) return (1.2*math.sin(x*math.pi)+0.31*math.sin(x*math.pi*3)+0.11*math.sin(x*math.pi*5)+0.033*math.sin(x*math.pi*7)) * z end,
  organIsh = function(x, z, pos, b) return (math.sin(x*math.pi)+(0.16*(math.sin(2*x*math.pi)+math.sin(3*x*math.pi)+math.sin(4*x*math.pi)))) * z end,
  sawAnalog = function(x, z, pos, b) return (2.001 * (math.sin(x * 0.7905) - 0.5)) * z end,
  dome = function(x, z, pos, b) return (2 * (math.sin(x * 1.5705) - 0.5)) * z end,
  brassy = function(x, z, pos, b) return math.sin(math.pi*gem.sign(x)*(math.abs(x)^(((1-z)+0.1)*math.pi*math.pi))) end,
  taffy = function(x, z, pos, b) return math.sin(x*math.pi*2)*math.cos(x*math.pi)*math.cos(z*math.pi*(math.abs((x*2)^3)-1)*math.pi) end,
  random = function(x, z, pos, b) return ((gem.getRandom() * 2) - 1) * z end,
  harmonicSync = function(x, z, pos, b) return math.sin(x*math.pi*(2+(62*z*z*z)))*math.sin(x*math.pi) end,
  softSine = function(x, z, pos, b) return 0.5*(math.cos(x*math.pi/2)*((math.sin((x)*math.pi)+(1-z)*(math.sin(z*((x*x)^z)*math.pi*32))))) end,
  tripleSin = function(x, z, pos, b) return math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x)) end,
  pwm50to100 = function(x, z, pos, b) if x > z then return 1 end return -1 end,
  chaosToSine = function(x, z, pos, b) return math.sin(math.pi*z*z*32*math.log(x+1)) end,
  sawSinReveal = function(x, z, pos, b) if x + 1 > z * 2 then return x end return math.sin(x * math.pi) end,
  domeSmall = function(x, z, pos, b) return (-1-1.275*math.sin(getUnipolar(x)*math.pi)) * z end,
  zero = function(x, z, pos, b) if b.unipolar then return -1 end return 0 end,
  minMax = function(x, z, pos, b) return z end,
  oddAndEven = function(x, z, pos, b) x = -1 if pos % 2 == 0 then x = 1 end return x * z end,
  lofiTriangle = function(x, z, pos, b) return ((gem.round(16*math.abs(x))/8.0)-1) * z end,
  hpfSaw = function(x, z, pos, b) return (x-(0.635*math.sin(x*math.pi))) * z end,
  squareTri = function(x, z, pos, b) return (-1*(gem.sign(x)*0.5)+(math.abs(x)-0.5)) * z end,
  sineStrech = function(x, z, pos, b) return math.sin(x^(1+(gem.round(z*32)*2))*math.pi) end,
  squareSawBit = function(x, z, pos, b) return math.sin((2-(z/4))*x*x*math.pi)/gem.round(x*32*((z/4)*(z/4)-0.125)) end,
  loFiTriangles = function(x, z, pos, b) return (gem.round((2+(z*14))*math.abs(x))/(1+(z*7.0)))-1 end,
  talkative1 = function(x, z, pos, b) return 1.4*math.cos(x*math.pi/2)*(.5*math.sin(((z*5)+1)*3*x)+.10*math.sin(((z*6)+1)*2*x)+.08*math.sin((((1-z)*3)+1)*12*x)) end,
  sinClipper = function(x, z, pos, b) return math.sin(x*math.pi)*(((z*z)+0.125)*8) end,
  pitfall = function(x, z, pos, b) return (x*128)%(z*16)*0.25 end,
  nascaLines = function(x, z, pos, b) return math.sqrt(1/pos)*(((pos/2)*(z+0.1)*b.max)%3)*0.5 end,
  kick = function(x, z, pos, b) return math.sin(math.pi*z*z*32*math.log(x+1)) end,
  sinToSaw = function(x, z, pos, b) return math.sin(-x*math.pi)*(1-z)+(-x*z) end,
  zeroCrossing = function(x, z, pos, b) return math.sin((x+1)*math.pi*(z+1))*(-math.abs(x)^32+1) end,
  vosim = function(x, z, pos, b) return -(getUnipolar(x)-1)*math.sin(getUnipolar(x)*math.pi*8*(math.sin(z)+1.5))^2 end,
  vosimNormalized = function(x, z, pos, b) return (-(getUnipolar(x)-1)*math.sin(getUnipolar(x)*math.pi*9*(math.sin(getUnipolar(z))+1.3))^2-.5)*2 end,
  acos = function(x, z, pos, b) return math.acos(x) * z end,
  wings = function(x, z, pos, b) return math.acos((math.abs(-math.abs(x)+1) + -math.abs(x)+1)/2) * z end,
  crosser = function(x, z, pos, b) return gem.avg({x, getUnipolar(x)}) * z end,
  diracDelta = function(x, z, pos, b) return (math.exp(-1*(x/((0.0001+z)*2))^2))/(((0.0001+z)*2)*math.sqrt(math.pi)*16) end,
  diracDeltaFrexp = function(x, z, pos, b) return (math.frexp(-1*(x/((0.0001+z)*2))^2))/(((0.0001+z)*2)*math.sqrt(math.pi)*16) end,
  diracDeltaRand = function(x, z, pos, b) return (math.exp(-1*(x/((0.0001+z)*2))^2))/(((0.0001+z)*2)*math.sqrt(math.pi)*math.min(8, b.rand*32)) end,
  swipe1 = function(x, z, pos, b) return math.exp(math.abs(x)/getUnipolar(z)) * z end,
  swipe2 = function(x, z, pos, b) return math.exp(math.tan(x)/math.pi) * z end,
  swipe3 = function(x, z, pos, b) return math.exp(x-getUnipolar(z)) * z end,
  swipe4 = function(x, z, pos, b) return (math.exp(x)) * gem.avg({z, x}) end,
  mayhemInTheMiddle = function(x, z, pos, b) return math.sin((x * math.pi) + (z * math.tan(getUnipolar(x) * math.pi))) end,
  zeroDancer = function(x, z, pos, b) return math.sin(x / z + z) * z end,
  exponential = function(x, z, pos, b, percentPos, stepValue, o) return (stepValue + (2-stepValue)*percentPos^o.factor) * z + o.phase end,
  bridge = function(x, z, pos, b, percentPos, stepValue, o) return math.abs(x^2) * z end,
  gauss = function(x, z, pos, b, percentPos, stepValue, o) return (1 / (z+1) * math.sqrt(2*math.pi)) * gem.e^(-(x^2) / (2*z^2)) - 1 end,
  shakySine = function(x, z, pos, b, percentPos, stepValue)
    local f = 0
    local g = b.rand * percentPos
    if z < 0 then
      f = z - g
    elseif z > 0 then
      f = z + g
    end
    return math.sin(x * math.pi) * f
  end,
  testShape = function(x, z, pos, b, percentPos, stepValue, o)
    -- This is the formula for the standard normal distribution, which is a Gaussian curve with a mean of 0 and a standard deviation of 1. 
    -- Gaussian curve with a mean of 0 and a standard deviation of 1:
    -- (1 / σ√(2π)) * e^(-((x-μ)^2) / (2σ^2))
    -- Simplified: (1 / √(2π)) * e^(-(x^2) / 2)
    local mu = 0
    return (1 / (z+1) * math.sqrt(2*math.pi)) * gem.e^(-((x-mu)^2) / (2*z^2)) - 1
  end,
}

local shapeDefinitions = {
  {name = "Ramp Up", f = shapes.ramp, o = {z = 1}},
  {name = "Ramp Down", f = shapes.ramp, o = {z = -1}},
  {name = "Sine", f = shapes.sine},
  {name = "Triangle", f = shapes.triangleShaper},
  {name = "Triangle (Off Phs)", f = shapes.triangleShaper, o = {phase = -.5}},
  {name = "LoFi Triangle", f = shapes.lofiTriangle},
  {name = "Sqr/Tri", f = shapes.squareTri},
  {name = "Dome", f = shapes.dome, o = {phase = 0}},
  {name = "Dome Small", f = shapes.domeSmall, o = {phase = 1}},
  {name = "Saw", f = shapes.sawInPhase},
  {name = "HPF Saw", f = shapes.hpfSaw},
  {name = "Analog Saw", f = shapes.sawAnalog, o = {phase = 0}},
  {name = "Fltr Sqr", f = shapes.filteredSquare},
  {name = "Organ-Ish", f = shapes.organIsh},
  {name = "Tangent", f = shapes.tangent},
  {name = "Acos", f = shapes.acos},
  {name = "Triple Sine", f = shapes.tripleSin},
  {name = "Harmonic Sync", f = shapes.harmonicSync},
  {name = "Soft Sine", f = shapes.softSine},
  {name = "Even", f = shapes.oddAndEven, o = {z = -1}},
  {name = "Odd", f = shapes.oddAndEven},
  {name = "Zero", f = shapes.zero},
  {name = "Min", f = shapes.minMax, o = {z = -1}},
  {name = "Max", f = shapes.minMax},
  {name = "Chaos To Sine", f = shapes.chaosToSine},
  {name = "Saw/Sin Reveal", f = shapes.sawSinReveal, o = {phase = -1}},
  {name = "PWM 50 to 100", f = shapes.pwm50to100},
  {name = "Triple-Sin Window", f = shapes.tripleSin, o = {z = 0}},
  {name = "Taffy", f = shapes.taffy, o = {z = 0}},
  {name = "Brassy", f = shapes.brassy, o = {z = 0}},
  {name = "HPF-Sqr To Sqr", f = shapes.hpfSqrToSqr, o = {z = .01}},
  {name = "Wacky", f = shapes.wacky, o = {z = .84}},
  {name = "Sine To Noise", f = shapes.sinToNoise},
  {name = "Sine Stretch", f = shapes.sineStrech, o = {z = .03}},
  {name = "SquareSaw Bit", f = shapes.squareSawBit},
  {name = "LoFi Triangles", f = shapes.loFiTriangles, o = {z = 0}},
  {name = "Talkative 1", f = shapes.talkative1},
  {name = "Sin Clipper", f = shapes.sinClipper, o = {z = 0}},
  {name = "Pitfall", f = shapes.pitfall, o = {z = .15}},
  {name = "Nasca Lines", f = shapes.nascaLines, o = {z = -.31}},
  {name = "Window-y SQR Sync", f = shapes.windowYSqr, o = {z = 0}},
  {name = "Kick", f = shapes.kick, o = {phase = 0, z = -.505}},
  {name = "Sin To Saw", f = shapes.sinToSaw, o = {z = 0}},
  {name = "Zero Crossing", f = shapes.zeroCrossing},
  {name = "VOSIM", f = shapes.vosim},
  {name = "VOSIM (Norm)", f = shapes.vosimNormalized},
  {name = "Crosser", f = shapes.crosser, o = {z = 0, factor = 4}},
  {name = "Mayhem Middle", f = shapes.mayhemInTheMiddle},
  {name = "Zero Dancer", f = shapes.zeroDancer},
  {name = "Wings", f = shapes.wings, o = {factor = .5}},
  {name = "Dirac Delta", f = shapes.diracDelta, o = {factor = .2, z = .02}},
  {name = "Dirac Delta (frexp)", f = shapes.diracDeltaFrexp, o = {z = .03}},
  {name = "Dirac Delta Rand", f = shapes.diracDeltaRand, o = {z = .06}},
  {name = "Swipe 1", f = shapes.swipe1},
  {name = "Swipe 2", f = shapes.swipe2},
  {name = "Swipe 3", f = shapes.swipe3},
  {name = "Swipe 4", f = shapes.swipe4, o = {z = -.25}},
  {name = "Shaky Sine", f = shapes.shakySine},
  {name = "Exponential", f = shapes.exponential, o = {factor = 4.5}},
  {name = "Bridge", f = shapes.bridge},
  {name = "Gauss", f = shapes.gauss, o = {z = .25}},
  {name = "Random", f = shapes.random},
  {name = "Test Shape", f = shapes.testShape},
}

local function getShapeIndexFromName(shapeName)
  for i,v in ipairs(shapeDefinitions) do
    if v.name == shapeName then
      return i
    end
  end
  return 1
end

local function getDefaultShapeOptions()
  return {
    z = 1,
    phase = -1,
    factor = 1,
    amount = 100,
  }
end

local function getShapeOptions(overrides)
  local defaultShapeOptions = getDefaultShapeOptions()
  if type(overrides) == "nil" then
    return defaultShapeOptions
  end
  return {
    z = gem.getValueOrDefault(overrides.z, defaultShapeOptions.z),
    phase = gem.getValueOrDefault(overrides.phase, defaultShapeOptions.phase),
    factor = gem.getValueOrDefault(overrides.factor, defaultShapeOptions.factor),
    amount = gem.getValueOrDefault(overrides.amount, defaultShapeOptions.amount),
  }
end

local function getShapeTemplate(options, shapeTemplate)
  if type(options) == "nil" and type(shapeTemplate) == "table" then
    options = shapeTemplate
  end
  return getShapeOptions(options)
end

local function getShapeNames(options, max)
  if type(max) ~= "number" then
    max = #shapeDefinitions
  end

  local items = {}

  for i,s in ipairs(shapeDefinitions) do
    table.insert(items, s.name)
    if i == max then
      break
    end
  end

  -- Add any options
  if type(options) == "table" then
    for _,o in ipairs(options) do
      table.insert(items, o)
    end
  end

  return items
end

local function getShapeBounds(shapeBounds)
  local bounds = {}
  if type(shapeBounds) == "nil" then
    shapeBounds = {}
  end
  bounds.min = gem.getValueOrDefault(shapeBounds.min, -1) -- x-azis max value
  bounds.max = gem.getValueOrDefault(shapeBounds.max, 1) -- x-azis min value
  bounds.length = gem.getValueOrDefault(shapeBounds.length, 128) -- y-axis steps
  bounds.unipolar = bounds.min >= 0 --  Whether the shape is unipolar
  bounds.rand = gem.getRandom() -- A random number that will be equal across all steps
  return bounds
end

local function createShape(shapeIndexOrName, shapeBounds, shapeOptions)
  if type(shapeIndexOrName) == "string" then
    shapeIndexOrName = getShapeIndexFromName(shapeIndexOrName)
  end
  local shape = {} -- Holds the values for each step
  local shapeDefinition = shapeDefinitions[shapeIndexOrName]
  local bounds = getShapeBounds(shapeBounds)
  local options = getShapeTemplate(shapeOptions, shapeDefinition.o)
  local stepValue = gem.getChangePerStep(2, bounds.length)
  for i=1,bounds.length do
    local pos = i - 1
    local value =  options.factor * stepValue * pos + options.phase
    local percentPos = pos / bounds.length
    local x = shapeDefinition.f(value, options.z, pos, bounds, percentPos, stepValue, options)
    if bounds.unipolar then
      x = getUnipolar(x)
    end
    x = (bounds.max * x) * (options.amount / 100)
    table.insert(shape, math.max(bounds.min, math.min(bounds.max, x)))
  end
  return shape, options
end

local function getAmountWidget(options, i)
  -- Widget for controlling shape amount
  if type(options) == "nil" then
    options = {}
  end
  if type(i) == "nil" then
    i = ""
  end
  options.name = gem.getValueOrDefault(options.name, "ShapeAmount" .. i)
  options.tooltip = gem.getValueOrDefault(options.tooltip, "Set the shape amount.")
  options.showLabel = gem.getValueOrDefault(options.showLabel, true)
  options.unit = gem.getValueOrDefault(options.unit, Unit.Percent)
  options.integer = gem.getValueOrDefault(options.integer, true)
  if type(options.width) ~= "nil" then
    options.width = options.width
  end
  return widgets.numBox("Shape Amount", getShapeOptions().amount, options)
end

local function getShapeWidgets(overrides, i)
  -- Widgets for controlling shape
  if type(i) == "nil" then
    i = ""
  end
  if type(overrides) == "nil" then
    overrides = {}
  end
  local shapeOptions = getShapeOptions()
  local factorOptions = {
    name = "ShapeFactor" .. i,
    tooltip = "Set the factor (multiplier) applied to the value of each step.",
    min = -8,
    max = 8,
  }
  local phaseOptions = {
    name = "ShapePhase" .. i,
    tooltip = "Set the phase applied to the shape (move left/right).",
  }
  local zOptions = {
    name = "ShapeMorph" .. i,
    tooltip = "Set the morph value. This value is mostly assigned to amplitude, but it depends on the shape.",
  }
  local options = {factor = factorOptions, phase = phaseOptions, z = zOptions}
  for _,v in pairs(options) do
    v.showLabel = gem.getValueOrDefault(overrides.showLabel, true)
    if type(overrides.width) ~= "nil" then
      v.width = overrides.width
    end
    if type(v.min) == "nil" then
      v.min = -1
    end
    if type(v.max) == "nil" then
      v.max = 1
    end
  end
  return {
    z = widgets.numBox("Shape Morph", shapeOptions.z, options.z),
    phase = widgets.numBox("Shape Phase", shapeOptions.phase, options.phase),
    factor = widgets.numBox("Shape Factor", shapeOptions.factor, options.factor),
  }
end

local shapes = {
  getWidgets = getShapeWidgets,
  getAmountWidget = getAmountWidget,
  getShapeNames = getShapeNames,
  getShapeOptions = getShapeOptions,
  get = createShape,
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
-- Swarm Trigger - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

setBackgroundColour("101010")

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local swarmActive = false
local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local channel = 1 -- Send trigger on this channel
local voiceId = nil -- Holds the id of the created note event
local velocity = 64
local duration = 1000 -- Space between swarms
local durationMin = 0
local durationMax = 60000
local shapeWidgets = {}
local shapeOptions = shapes.getShapeOptions()
local swarmLengthInput
local swarmLength = 32
local lengthRandomizationAmount = 0
local lengthRandomizationInput
local space = 0
local spaceRandomizationAmount = 10
local quantizeOptions = resolutions.getQuantizeOptions()
local quantizeType = quantizeOptions[1]
local swarmProbability = 100
local resolutionNames = resolutions.getResolutionNames()
local resolutionValues = resolutions.getResolutions()
local swarmResolutions = {}
local resolution = 23
local resolutionMin = #resolutionNames
local positionTable
local sequencerTable
local shapeIndex = 1
local startWithSpace = false
local tickBeat = .5
local playOptions = {"Active Shape", "Active+Random Settings", "Random Shape", "Random Shape+Settings", "Custom"}
local playMode = playOptions[1]
local shapeMenu
local shapeNames = shapes.getShapeNames()
local preInit = true -- Used to avoid loading a new shape when loading a preset
local heldNotes = {}
local heldNoteIndex = 0
local hold = false
local noteSelectModes = {"As Played", "Up", "Down", "Random", "Mono", "Duo", "Chord"}
local noteSelectMode = noteSelectModes[1]

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function getNotes()
  -- Reset notes table
  local notes = {} -- Holds the note(s) that plays at this position

  -- Increment held note position
  heldNoteIndex = gem.inc(heldNoteIndex)
  if heldNoteIndex > #heldNotes then
    heldNoteIndex = 1
  end

  -- Add notes to play
  -- "As Played", "Up", "Down", "Random", "Mono", "Duo", "Chord"
  local availableNotes = {}
  for _,v in ipairs(heldNotes) do
    table.insert(availableNotes, v.note)
  end

  if noteSelectMode == "Up" then
    table.sort(availableNotes)
    table.insert(notes, availableNotes[heldNoteIndex])
  elseif noteSelectMode == "Down" then
    table.sort(availableNotes, function(a,b) return a > b end)
    table.insert(notes, availableNotes[heldNoteIndex])
  elseif noteSelectMode == "Random" then
    table.insert(notes, gem.getRandomFromTable(availableNotes))
  elseif noteSelectMode == "Mono" then
    -- Last held
    table.insert(notes, heldNotes[#heldNotes].note)
  elseif noteSelectMode == "Duo" then
    -- Lowest and highest held notes
    table.insert(notes, availableNotes[1])
    if #heldNotes > 1 then
      table.insert(notes, availableNotes[#availableNotes])
    end
  elseif noteSelectMode == "Chord" then
    -- All held notes
    for i=1,#availableNotes do
      table.insert(notes, availableNotes[i])
    end
  else
    table.insert(notes, heldNotes[heldNoteIndex].note)
  end
  print("#notes, noteSelectMode", #notes, noteSelectMode)
  return notes
end

local function getRandomBipolar()
  local value = gem.getRandom()
  if gem.getRandomBoolean() then
    value = -value
  end
  return value
end

local function randomizeShapeSettings(randomizeLength)
  shapeWidgets.z:setValue(getRandomBipolar())
  shapeWidgets.phase:setValue(getRandomBipolar())
  local factor = getRandomBipolar()
  if gem.getRandomBoolean() then
    shapeWidgets.factor:setValue(factor)
  elseif gem.getRandomBoolean() then
    shapeWidgets.factor:setValue(factor * 2)
  else
    shapeWidgets.factor:setValue(factor * gem.getRandom(shapeWidgets.factor.max))
  end
  if gem.getRandomBoolean(75) then
    shapeWidgets.amount:setValue(gem.getRandom(75, shapeWidgets.amount.max))
  elseif gem.getRandomBoolean() then
    shapeWidgets.amount:setValue(gem.getRandom(50, shapeWidgets.amount.max))
  else
    shapeWidgets.amount:setValue(gem.getRandom(shapeWidgets.amount.max))
  end
  if lengthRandomizationInput.enabled and randomizeLength == true then
    swarmLengthInput:setValue(gem.randomizeValue(swarmLength, swarmLengthInput.min, swarmLengthInput.max, lengthRandomizationAmount))
  end
end

local function updateShapeWidgets()
  -- Update widgets with values from the shape
  local callChanged = false
  for k,v in pairs(shapeWidgets) do
    v:setValue(shapeOptions[k], callChanged)
  end
end

local function setShape(loadNew)
  loadNew = loadNew == true and preInit == false
  --print("setShape", loadNew)

  local values
  local options
  local length = swarmLength
  local minRes = beat2ms(resolutionValues[resolutionMin]) -- Fastest
  local maxRes = beat2ms(resolutionValues[resolution]) -- Slowest

  if lengthRandomizationInput.enabled and isPlaying then
    length = gem.randomizeValue(length, swarmLengthInput.min, swarmLengthInput.max, lengthRandomizationAmount)
  end

  -- Update tables
  positionTable.length = length
  sequencerTable.length = length
  sequencerTable:setRange(minRes, maxRes)

  -- Custom shape or no shape selected - do not change
  if playMode == "Custom" then
    --print("playMode == Custom")
    return
  end

  -- Use the shape parameters unless we are loading a new shape
  if loadNew == false then
    options = shapeOptions
  end

  values, shapeOptions = shapes.get(shapeIndex, sequencerTable, options)
  updateShapeWidgets()
  for i,v in ipairs(values) do
    sequencerTable:setValue(i, v)
  end
end

local function clearPositionTable()
  for i=1,positionTable.length do
    positionTable:setValue(i, 0)
  end
end

local function swarm(uniqueId)
  --print("Starting swarm", uniqueId)
  if playMode == playOptions[3] or playMode == playOptions[4] then
    -- Fresh shape loaded here
    shapeMenu:setValue(gem.getRandom(#shapeNames))
  end
  if playMode == playOptions[2] or playMode == playOptions[4] then
    randomizeShapeSettings()
  end
  setShape()
  local swarmPosition = 1
  while swarmActive and isPlaying and seqIndex == uniqueId do
    -- Update position table with the current position
    for i=1,positionTable.length do
      local value = 0
      if i == swarmPosition then
        value = 1
      end
      positionTable:setValue(i, value)
    end
    local playDuration = resolutions.quantizeToClosest(ms2beat(sequencerTable:getValue(swarmPosition)), quantizeType)
    local notes = getNotes()
    velocity = heldNotes[heldNoteIndex].velocity
    for _,note in ipairs(notes) do
      playNote(note, velocity, beat2ms(playDuration))
    end
    waitBeat(playDuration)
    swarmPosition = gem.inc(swarmPosition)
    swarmActive = swarmPosition <= sequencerTable.length
    if swarmActive == false then
      clearPositionTable()
      space = ms2beat(gem.randomizeValue(duration, durationMin, durationMax, spaceRandomizationAmount))
    end
  end
end

local function sequenceRunner(uniqueId)
  --print("Starting sequencer", uniqueId)
  space = ms2beat(duration)
  local elapsedBeats = space
  if startWithSpace then
    elapsedBeats = 0
  end
  swarmActive = false
  while isPlaying and seqIndex == uniqueId do
    if elapsedBeats >= space then
      if swarmActive == false and gem.getRandomBoolean(swarmProbability) then
        --print("Starting swarm, elapsedBeats, space", elapsedBeats, space)
        swarmActive = true
        spawn(swarm, seqIndex)
      end
      elapsedBeats = 0 -- Reset
    end
    waitBeat(tickBeat)
    if swarmActive == false then
      -- Only increment elapsed when swarm is not active
      elapsedBeats = gem.inc(elapsedBeats, tickBeat)
    end
  end
end

local function startPlaying()
  print("startPlaying")
  if isPlaying then
    return
  end
  print("startPlaying YES")
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(sequenceRunner, seqIndex)
end

local function stopPlaying()
  print("stopPlaying")
  if isPlaying == false then
    return
  end
  print("stopPlaying YES")
  isPlaying = false
  swarmActive = false
  clearPositionTable()
  heldNotes = {}
end

--------------------------------------------------------------------------------
-- Header Panel
--------------------------------------------------------------------------------

widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Swarm Sequencer", {
  width = widgets.getPanel().width,
  x = 0,
  y = 0,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  xSpacing = 5,
  ySpacing = 5,
  width = 100,
  height = 22,
  x = (widgets.getPanel().width / 2) + 45,
  y = 5,
})

widgets.menu("Space Quantize", gem.getIndexFromValue(tickBeat, resolutionValues), resolutionNames, {
  tooltip = "Set the quantization for space.",
  showLabel = false,
  changed = function(self) tickBeat = resolutions.getResolution(self.value) end
})

widgets.menu("Play Mode", noteSelectModes, {
  showLabel = false,
  changed = function(self) noteSelectMode = self.selectedText end,
})

widgets.button('Hold', hold, {
  tooltip = "Activate to hold notes",
  changed = function(self)
    hold = self.value
    if hold == false then
      stopPlaying()
    end
  end,
})

--------------------------------------------------------------------------------
-- XY Panel
--------------------------------------------------------------------------------

widgets.panel({
  x = widgets.getPanel().x,
  y = widgets.posUnder(widgets.getPanel()),
  width = 430,
  height = 110,
})

local noteWidgetColSpacing = 5
local noteWidgetRowSpacing = 5

local xyShapeMorph = widgets.getPanel():XY('ShapePhase', 'ShapeMorph')
xyShapeMorph.x = noteWidgetColSpacing
xyShapeMorph.y = noteWidgetRowSpacing
xyShapeMorph.width = widgets.getPanel().height * 1.3
xyShapeMorph.height = widgets.getPanel().height - 10

local xyShapeFactor = widgets.getPanel():XY('ShapeFactor', 'ShapeAmount')
xyShapeFactor.x = widgets.posSide(xyShapeMorph)
xyShapeFactor.y = noteWidgetRowSpacing
xyShapeFactor.width = xyShapeMorph.width
xyShapeFactor.height = xyShapeMorph.height

widgets.setSection({
  x = widgets.posSide(xyShapeFactor),
  width = 123,
  xSpacing = noteWidgetColSpacing,
  ySpacing = 3,
  cols = 1,
})

widgets.label("Shape Actions", {
  backgroundColour = "transparent",
  textColour = "silver",
})

local actionButtons = {}

table.insert(actionButtons, widgets.button("Select Random Shape", {
  changed = function()
    shapeMenu:setValue(gem.getRandom(#shapeNames))
  end
}))

table.insert(actionButtons, widgets.button("Randomize Settings", {
  changed = function()
    randomizeShapeSettings(true)
  end
}))

table.insert(actionButtons, widgets.button("Reset Shape Settings", {
  changed = function()
    setShape(true)
  end
}))

--------------------------------------------------------------------------------
-- Shape table
--------------------------------------------------------------------------------

widgets.panel({
  x = widgets.getPanel().x,
  y = widgets.posUnder(widgets.getPanel()),
  width = widgets.getPanel().width,
  height = 130,
})

widgets.setSection({
  width = 430,
  xSpacing = noteWidgetColSpacing,
  ySpacing = 0,
  cols = 1,
})

positionTable = widgets.table("Position", 0, swarmLength, {
  enabled = false,
  persistent = false,
  sliderColour = "yellow",
  height = 6,
  x = 0,
  y = 0,
})

sequencerTable = widgets.table("Sequencer", 0, swarmLength, {
  tooltip = "Sequencer table - activate 'Custom' to edit the table",
  enabled = false,
  showPopupDisplay = true,
  sliderColour = "pink",
  height = 123,
  x = 0,
  y = widgets.posUnder(positionTable),
})

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

widgets.panel({
  x = widgets.posSide(sequencerTable),
  y = 35,
  width = 280,
  height = 245,
})

widgets.setSection({
  width = 128,
  x = 10,
  y = 5,
  xSpacing = noteWidgetColSpacing,
  ySpacing = noteWidgetRowSpacing,
  cols = 2,
})

widgets.menu("Swarm Min", resolution, resolutionNames, {
  tooltip = "Set the slowest resolution of the swarm. This will be the resolution for a full bar in the table.",
  width = 81,
  changed = function(self)
    resolution = self.value
    setShape()
  end
})

widgets.menu("Swarm Max", resolutionMin, resolutionNames, {
  tooltip = "Set the fastest resolution of the swarm. This will be the resolution for an empty bar in the table.",
  width = 81,
  increment = false,
  changed = function(self)
    resolutionMin = self.value
    setShape()
  end
})

widgets.menu("Quantize", quantizeOptions, {
  tooltip = "Quantize output to closest resolution of the selected type.",
  width = 90,
  changed = function(self)
    quantizeType = self.selectedText
  end
})

shapeMenu = widgets.menu("Swarm Shape", shapeIndex, shapeNames, {
  tooltip = "Set the shape of the swarm. Short bars = fast, long bars = slow. You can edit the shape by selecting 'Custom' from 'Shape Play Mode'.",
  changed = function(self)
    shapeIndex = self.value
    setShape(true)
  end
})

widgets.menu("Shape Play Mode", playOptions, {
  tooltip = "Set how shapes are selected for playing. Use 'Custom' to edit you own shape.",
  changed = function(self)
    playMode = self.selectedText
    local shapeEnabled = self.value == 1
    sequencerTable.enabled = self.value == #self.items
    lengthRandomizationInput.enabled = self.value < #self.items
    shapeMenu.enabled = shapeEnabled or self.value == 2
    xyShapeMorph.enabled = shapeEnabled
    xyShapeFactor.enabled = shapeEnabled
    for k,v in pairs(shapeWidgets) do
      v.enabled = shapeEnabled
    end
    for _,v in ipairs(actionButtons) do
      v.enabled = shapeEnabled
    end
    setShape(true)
  end
})

shapeWidgets = shapes.getWidgets()
shapeWidgets.amount = shapes.getAmountWidget({integer = false})
shapeWidgets.amount.displayName = "Shape Amount"

for k,v in pairs(shapeWidgets) do
  v.changed = function(self)
    shapeOptions[k] = self.value
    setShape()
  end
end

swarmLengthInput = widgets.numBox("Length", swarmLength, {
  tooltip = "Swarm length",
  min = 2,
  max = 256,
  integer = true,
  changed = function(self)
    swarmLength = self.value
    setShape()
  end
})

lengthRandomizationInput = widgets.numBox("Rand", lengthRandomizationAmount, {
  name = "LengthRand",
  tooltip = "Swarm length randomization amount",
  unit = Unit.Percent,
  integer = false,
  changed = function(self) lengthRandomizationAmount = self.value end
})

widgets.numBox("Swarm Prob", swarmProbability, {
  name = "Probability",
  unit = Unit.Percent,
  tooltip = "Set the probability that a swarm will be triggered",
  changed = function(self) swarmProbability = self.value end
})

widgets.button("Start With Space", startWithSpace, {
  tooltip = "If this is active, the swarm will start with start playing after the first space duration is passed.",
  changed = function(self) startWithSpace = self.value end
})

widgets.numBox("Space", duration, {
  tooltip = "Set the time between swarms",
  unit = Unit.MilliSeconds,
  min = durationMin, max = durationMax, integer = false,
  changed = function(self) duration = self.value end
})

widgets.numBox("Rand", spaceRandomizationAmount, {
  name = "SpaceRand",
  tooltip = "Set the space randomization amount",
  unit = Unit.Percent,
  changed = function(self) spaceRandomizationAmount = self.value end
})

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
  preInit = false
end

function onNote(e)
  if hold == true then
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        -- When hold button is active
        -- we remove the note from held notes
        -- if table has more than one note
        if #heldNotes > 1 then
          table.remove(heldNotes, i)
        end
        break
      end
    end
  end
  table.insert(heldNotes, e)
  if #heldNotes == 1 then
    startPlaying()
  end
end

function onRelease(e)
  if hold == false then
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        table.remove(heldNotes, i)
      end
    end
    postEvent(e)
  end
  if #heldNotes == 0 then
    stopPlaying()
  end
end
