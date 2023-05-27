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
  {name = "Fltr Sqr",  f = shapes.filteredSquare},
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

local directionStartModes = {"Up", "Down", "Even Up", "Even Down", "Odd Up", "Odd Down", "Random"}
local speedTypes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Random"}
local startModes = shapes.getShapeNames({"Keep State"})
local movementTypes = {"Evolve", "Morph", "Manual"}
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local morphSeqIndex = 0 -- Holds the unique id for the morphing sequencer
local movingCells = {}
local isTableMotionActive = false
local shapeWidgets = {} -- Holds the widgets for controlling shape
local resolutionNames = resolutions.getResolutionNames()

local motionOptions = {
  factor = 2,
  factorMin = 0,
  factorMax = 10,
  moveSpeed = gem.getIndexFromValue("1/16", resolutionNames),
  moveSpeedMin = 1,
  moveSpeedMax = #resolutionNames,
  speedType = speedTypes[1],
  startMode = 1,
  movementType = movementTypes[1],
  directionStartMode = directionStartModes[1],
  speedRandomizationAmount = 0,
  tableLength = 32,
}

local shapeOptions = shapes.getShapeOptions()

local function getSpeedSpreadWidget(width)
  return widgets.menu("Speed Spread", speedTypes, {
    width = width,
    tooltip = "The speed spread works with the speed factor to control speed variations across the table. Ramp Up means fast -> slower, Triangle means slower in the center. (Note: Only used for motion type 'evolve')",
    changed = function(self) motionOptions.speedType = self.selectedText end
  })
end

local function getStartDirectionWidget(width)
  return widgets.menu("Start Direction", directionStartModes, {
    width = width,
    tooltip = "Select start direction for the bars",
    changed = function(self) motionOptions.directionStartMode = self.selectedText end
  })
end

local function getMotionSpeedWidget(width)
  local motionResolutionMenu
  local motionResolutionInput

  motionResolutionMenu = widgets.menu("Motion Speed", motionOptions.moveSpeed, resolutionNames, {
    width = width,
    tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller",
    changed = function(self) motionResolutionInput:setValue(self.value) end
  })

  motionResolutionInput = widgets.numBox("Motion Resolution", motionOptions.moveSpeed, {
    visible = false,
    increment = false,
    min = 1,
    max = #resolutionNames,
    changed = function(self)
      motionOptions.moveSpeed = gem.round(self.value)
      motionResolutionMenu:setValue(motionOptions.moveSpeed)
    end
  })

  return motionResolutionMenu
end

local function getSpeedFactorWidget(width)
  return widgets.numBox("Speed Factor", motionOptions.factor, {
    width = width,
    mapper = Mapper.Cubic,
    min = motionOptions.factorMin,
    max = motionOptions.factorMax,
    tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. When using morph, this controls phase amount. Controlled by the Y-axis on the XY controller",
    changed = function(self) motionOptions.factor = self.value end
  })
end

local function getSpeedRandWidget(width)
  return widgets.numBox("Speed Rand", motionOptions.speedRandomizationAmount, {
    tooltip = "Set the radomization amount applied to speed",
    width = width,
    unit = Unit.Percent,
    integer = false,
    mapper = Mapper.Quadratic,
    changed = function(self) motionOptions.speedRandomizationAmount = self.value end
  })
end

local function getStartShapeWidget(width)
  return widgets.menu("Start Shape", startModes, {
    width = width,
    tooltip = "Set how the table will look when starting.",
  })
end

local function getStartDirection(i)
  if type(i) == "nil" then
    i = 1
  end
  local direction = 1
  if motionOptions.directionStartMode == "Down" then
    direction = -1
  elseif motionOptions.directionStartMode == "Even Up" then
    if i % 2 == 0 then
      direction = 1
    else
      direction = -1
    end
  elseif motionOptions.directionStartMode == "Even Down" then
    if i % 2 == 0 then
      direction = -1
    else
      direction = 1
    end
  elseif motionOptions.directionStartMode == "Odd Up" then
    if i % 2 == 0 then
      direction = -1
    else
      direction = 1
    end
  elseif motionOptions.directionStartMode == "Odd Down" then
    if i % 2 == 0 then
      direction = 1
    else
      direction = -1
    end
  elseif motionOptions.directionStartMode == "Random" then
    if gem.getRandomBoolean() then
      direction = 1
    else
      direction = -1
    end
  end
  return direction
end

local function setTableZero(theTable)
  for i=1,theTable.length do
    theTable:setValue(i, 0)
  end  
end

local function updateShapeWidgets()
  -- Update widgets with values from the shape
  local callChanged = false
  shapeWidgets.phase:setValue(shapeOptions.phase, callChanged)
  shapeWidgets.factor:setValue(shapeOptions.factor, callChanged)
  shapeWidgets.z:setValue(shapeOptions.z, callChanged)
end

local function setStartMode(theTable, loadShape, stateFunction)
  -- Reset table according to start mode (unless keep state is selected)
  if motionOptions.startMode < #startModes then
    local values = {}
    local shapeIndex = motionOptions.startMode
    --print("Calling shapeFunc", shapeFunc)
    if type(loadShape) == "table" then
      -- Load the shape with the settings provided
      values = shapes.get(shapeIndex, theTable, loadShape)
    elseif loadShape == true then
      -- Load the shape without settings to get the original form of the shape
      values, shapeOptions = shapes.get(shapeIndex, theTable)
    else
      -- Load the shape with the default settings
      values, shapeOptions = shapes.get(shapeIndex, theTable, shapeOptions)
    end
    for i,v in ipairs(values) do
      local value = v
      --[[ if shapeFunc == "sine" then
        -- Sine prefers round
        value = gem.round(v)
      else ]]if v > 1 then
        value = math.ceil(v)
      else
        value = math.floor(v)
      end
      --print("Set value, i", value, i)
      theTable:setValue(i, value)
      if type(stateFunction) == "function" then
        --print("Calling stateFunc")
        stateFunction(i, value)
      end
    end
    if type(loadShape) ~= "table" then
      updateShapeWidgets()
    end
  end
end

local function getDurationRange()
  local limitRange = motionOptions.moveSpeedMax - motionOptions.moveSpeedMin
  local changeMax = gem.getChangeMax(limitRange, motionOptions.speedRandomizationAmount)
  local min = math.max(motionOptions.moveSpeedMin, (motionOptions.moveSpeed - changeMax))
  local max = math.min(motionOptions.moveSpeedMax, (motionOptions.moveSpeed + changeMax))
  return min, max
end

local function getWaitDuration()
  if motionOptions.speedRandomizationAmount == 0 then
    return beat2ms(resolutions.getResolution(motionOptions.moveSpeed))
  end
  local min, max = getDurationRange()
  local resolutionMin = resolutions.getResolution(min) -- Slow
  local resolutionMax = resolutions.getResolution(max) -- Fast
  return gem.randomizeValue(beat2ms(resolutions.getResolution(motionOptions.moveSpeed)), beat2ms(resolutionMax), beat2ms(resolutionMin), motionOptions.speedRandomizationAmount)
end

local function moveTable(theTable, i, value, direction)
  local middle = math.floor(theTable.length / 2)
  -- Increment value
  local amount = i - 1
  if (i > middle and motionOptions.speedType == "Triangle") or motionOptions.speedType == "Ramp Down" then
    amount = theTable.length - i
  elseif motionOptions.speedType == "Random" then
    amount = gem.getRandom(theTable.length) - 1
  elseif (motionOptions.speedType == "Even" and i % 2 == 0) or (motionOptions.speedType == "Odd" and i % 2 > 0) then
    amount = 0
  elseif motionOptions.speedType == "Even" and i == 1 then
    amount = i
  end
  local min = theTable.min
  local max = theTable.max
  local duration = getWaitDuration() + (amount * motionOptions.factor) -- TODO Param for operator?
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

local function morph(theTable, uniqueId, stateFunction)
  print("startMorphing")
  local direction = getStartDirection()
  local morphSettings = {
    z = {
      value = shapeWidgets.z.value,
      min = shapeWidgets.z.min,
      max = shapeWidgets.z.max,
      direction = direction,
    },
    phase = {
      value = shapeWidgets.phase.value,
      min = shapeWidgets.phase.min,
      max = shapeWidgets.phase.max,
      direction = direction,
    }
  }
  while isTableMotionActive and motionOptions.movementType == "Morph" and morphSeqIndex == uniqueId do
    morphSettings.z.value, morphSettings.z.direction = gem.advanceValue(theTable, morphSettings.z.value, morphSettings.z.min, morphSettings.z.max, morphSettings.z.direction)
    if motionOptions.factor > 0 then
      local factor = motionOptions.factor / motionOptions.factorMax
      local range = morphSettings.phase.max - morphSettings.phase.min
      local min = morphSettings.phase.min
      local max = min + (range * factor)
      if shapeWidgets.phase.value > min then
        range = (range / 2) * factor
        min = shapeWidgets.phase.value - range
        max = shapeWidgets.phase.value + range
      end
      morphSettings.phase.value, morphSettings.phase.direction = gem.advanceValue(theTable, morphSettings.phase.value, min, max, morphSettings.phase.direction)
    end
    local options = {
      z = morphSettings.z.value,
      phase = morphSettings.phase.value,
      factor = shapeOptions.factor,
    }
    setStartMode(theTable, options, stateFunction)
    wait(getWaitDuration())
  end
end

local function move(theTable, i, uniqueId, stateFunction)
  local direction = getStartDirection(i)
  local value = theTable:getValue(i)
  while isTableMotionActive and movingCells[i] == uniqueId do
    if type(stateFunction) == "function" then
      stateFunction(i, value)
    end
    value, direction = moveTable(theTable, i, value, direction)
    -- Wait happens in moveTable
  end
end

local function startMoving(theTable, stateFunction)
  if isTableMotionActive == false then
    return
  end
  -- Reset index to stop motion
  morphSeqIndex = gem.inc(morphSeqIndex)
  movingCells = {}
  if motionOptions.movementType == "Manual" then
    print("In Manual Mode")
    return -- Nothing needs to be done in manual mode
  elseif motionOptions.movementType == "Morph" then
    print("spawn morph")
    spawn(morph, theTable, morphSeqIndex, stateFunction)
  else
    print("spawn move")
    for i=1,theTable.length do
      table.insert(movingCells, uniqueIndex)
      spawn(move, theTable, i, uniqueIndex, stateFunction)
      uniqueIndex = gem.inc(uniqueIndex)
    end
  end
end

local tableMotion = {
  setRange = function(theTable, tableRange, bipolar)
    if bipolar then
      theTable:setRange(-tableRange, tableRange)
    else
      theTable:setRange(0, tableRange)
    end
  end,
  getSpeedSpreadWidget = getSpeedSpreadWidget,
  getStartShapeWidget = getStartShapeWidget,
  getStartDirectionWidget = getStartDirectionWidget,
  getMotionSpeedWidget = getMotionSpeedWidget,
  getSpeedFactorWidget = getSpeedFactorWidget,
  getSpeedRandWidget = getSpeedRandWidget,
  startMoving = startMoving,
  isMoving = function() return isTableMotionActive == true end,
  isNotMoving = function() return isTableMotionActive == false end,
  setMoving = function(m) isTableMotionActive = m ~= false end,
  resetUniqueIndex = function() uniqueIndex = 1 end,
  setShapeWidgets = function(widgets) shapeWidgets = widgets end,
  getShapeWidgets = function() return shapeWidgets end,
  getShapeOptions = function() return shapeOptions end,
  getStartDirection = getStartDirection,
  moveTable = moveTable,
  getWaitDuration = getWaitDuration,
  setStartMode = setStartMode,
  setTableZero = setTableZero,
  directionStartModes = directionStartModes,
  speedTypes = speedTypes,
  startModes = startModes,
  movementTypes = movementTypes,
  options = motionOptions,
}

--------------------------------------------------------------------------------
-- Rythmic Motions - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local backgroundColour = "202020" -- Light or Dark

setBackgroundColour(backgroundColour)

-- TODO Add parts and evolve like in generativeStrategySequencer

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local tableRange = 16
local bipolar = true
local positionTable
local motionTable
local channel = 1
local triggerMode = 1 -- Holds the strategy for when events are triggered
local triggerModes = {"Min/Max", "Min", "Max", "Zero", "All"}
local currentValue = {} -- Holds the current table value to check for changes
local noteEventId = 0 -- Holds the index if the cell in the table that last triggered an event
local resolutionNames = resolutions.getResolutionNames()
local resolution = #resolutionNames
local legato = true
local voiceId = nil -- Holds the id of the created note event

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function checkTrigger(i, value)
  --print("Running stateFunc")
  -- Send note event according to the selected trigger mode
  local valueHasChanged = value ~= currentValue[i]
  --print("value, currentValue[i], valueHasChanged", value, currentValue[i], valueHasChanged)
  -- Only set as trigger if value is changed
  if valueHasChanged then
    local isTrigger = false
    if triggerMode == 1 and (value == motionTable.min or value == motionTable.max) then
      isTrigger = true
    elseif triggerMode == 2 and value == motionTable.min then
      isTrigger = true
    elseif triggerMode == 3 and value == motionTable.max then
      isTrigger = true
    elseif triggerMode == 4 and value == 0 then
      isTrigger = true
    elseif triggerMode == 5 and (value == 0 or value == motionTable.min or value == motionTable.max) then
      isTrigger = true
    end
    if isTrigger then
      noteEventId = i
      --print("Update noteEventId", noteEventId)
    end
  end
  -- Update the current value
  currentValue[i] = value
  --print("Update currentValue", value)
end

local function resetTableValues(loadShape)
  -- Reset event id
  noteEventId = 0

  -- Reset position
  tableMotion.setTableZero(positionTable)

  -- Set start mode
  tableMotion.setStartMode(motionTable, loadShape, checkTrigger)

  currentValue = {}
  for i=1,motionTable.length do
    table.insert(currentValue, nil) -- Set initial value
  end
end

local function setRange()
  print("Calling setRange")
  tableMotion.setRange(motionTable, tableRange, bipolar)
  print("Calling resetTableValues")
  resetTableValues()
  print("Done calling resetTableValues")
end

local function release()
  if type(voiceId) == "userdata" then
    releaseVoice(voiceId)
    voiceId = nil
  end
end

local function playTrigger()
  print("Play Trigger")
  if noteEventId > 0 then
    -- Release the voice if active
    release()
    local velocity = 64
    voiceId = playNote(0, velocity, -1, nil, channel)
    print("Creating trigger")
    -- Mark the position that initiated the event
    for i=1,motionTable.length do
      local value = 0
      if i == noteEventId then
        value = 1
      end
      positionTable:setValue(i, value)
    end
    noteEventId = 0 -- Reset event id
  end
end

local function startMoving()
  tableMotion.startMoving(motionTable, checkTrigger)
end

local function sequenceRunner()
  startMoving()
  print("tableMotion.isMoving", tableMotion.isMoving())
  while tableMotion.isMoving() do
    playTrigger()
    waitBeat(resolutions.getResolution(resolution))
    if legato == false then
      -- Release if legato is off
      release()
    end
  end
end

local function startPlaying()
  if tableMotion.isMoving() then
    return
  end
  tableMotion.setMoving()
  run(sequenceRunner)
end

local function stopPlaying()
  if tableMotion.isNotMoving() then
    return
  end
  tableMotion.setMoving(false)
  resetTableValues()
  release()
end

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

local sequencerPanel = widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Rythmic Motions Trigger", {
  tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 100,
  height = 22,
  x = (widgets.getPanel().width / 2) + 45,
  y = 5,
  xSpacing = 5,
  ySpacing = 5,
})

local channelInput = widgets.numBox('Channel', channel, {
  tooltip = "Send note events starting on this channel",
  min = 1,
  max = 16,
  integer = true,
  changed = function(self) channel = self.value end,
})

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
-- Sequencer Panel
--------------------------------------------------------------------------------

widgets.xSpacing(0)
widgets.ySpacing(0)
widgets.backgroundColour = "606060"

widgets.panel({
  backgroundColour = backgroundColour,
  x = sequencerPanel.x,
  y = widgets.posUnder(sequencerPanel),
  width = sequencerPanel.width,
  height = 270,
})

positionTable = widgets.table("Position", 0, tableMotion.options.tableLength, {
  enabled = false,
  persistent = false,
  sliderColour = "yellow",
  width = sequencerPanel.width - 120,
  height = 6,
  x = 0,
  y = 0,
})

motionTable = widgets.table("Motion", 0, tableMotion.options.tableLength, {
  tooltip = "Events are triggered when the value hits max or min",
  showPopupDisplay = true,
  min = -tableRange,
  max = tableRange,
  integer = true,
  sliderColour = "pink",
  width = positionTable.width,
  height = 160,
  x = 0,
  y = widgets.posUnder(positionTable),
})

widgets.setSection({
  width = 109,
  height = 20,
  x = 10,
  y = widgets.posUnder(motionTable) + 6,
  xSpacing = 12,
  ySpacing = 5,
  cols = 7
})

tableMotion.getStartShapeWidget().changed = function(self)
  tableMotion.options.startMode = self.value
  resetTableValues(true) -- Load a "fresh" shape without adjustments when selecting a shape
end

tableMotion.getSpeedSpreadWidget()
tableMotion.getStartDirectionWidget()

widgets.menu("Trigger Mode", triggerMode, triggerModes, {
  tooltip = "Trigger mode determines when a trigger is activated for output (see Quantize)",
  changed = function(self) triggerMode = self.value end
})

widgets.menu("Quantize", resolution, resolutionNames, {
  tooltip = "Quantize the outputted triggers to the selected resolution",
  width = 75,
  changed = function(self) resolution = self.value end
})

tableMotion.getMotionSpeedWidget(130)

widgets.row(2)

widgets.numBox("Range", tableRange, {
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the table range - high range = fewer events, low range = more events",
  changed = function(self)
    tableRange = self.value
    setRange()
  end
})

widgets.numBox("Length", tableMotion.options.tableLength, {
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the table length",
  changed = function(self)
    tableMotion.options.tableLength = self.value
    positionTable.length = tableMotion.options.tableLength
    motionTable.length = tableMotion.options.tableLength
    resetTableValues()
    startMoving()
  end
})

widgets.button("Bipolar", bipolar, {
  changed = function(self)
    bipolar = self.value
    setRange()
  end
})

widgets.button("Reset", false, {
  changed = function(self)
    resetTableValues()
    startMoving()
    self.value = false
  end
})

widgets.menu("Motion Type", tableMotion.movementTypes, {
  width = 75,
  changed = function(self)
    tableMotion.options.movementType = self.selectedText
    startMoving()
  end
})

tableMotion.getSpeedFactorWidget(130)

widgets.row()

tableMotion.setShapeWidgets(shapes.getWidgets())

widgets.button("Legato", legato, {
  tooltip = "In legato mode notes are held until the next note is played",
  changed = function(self) legato = self.value end
})

widgets.col(1, 75)

tableMotion.getSpeedRandWidget(130)

tableMotion.getShapeWidgets().phase.changed = function(self)
  tableMotion.getShapeOptions().phase = self.value
  resetTableValues()
  startMoving()
end

tableMotion.getShapeWidgets().factor.changed = function(self)
  tableMotion.getShapeOptions().factor = self.value
  resetTableValues()
  startMoving()
end

tableMotion.getShapeWidgets().z.changed = function(self)
  tableMotion.getShapeOptions().z = self.value
  resetTableValues()
  startMoving()
end

local xyShapeMorph = widgets.getPanel():XY('ShapePhase', 'ShapeMorph')
xyShapeMorph.y = motionTable.y
xyShapeMorph.x = widgets.posSide(motionTable) - 6
xyShapeMorph.width = 108
xyShapeMorph.height = motionTable.height / 2

local xySpeedFactor = widgets.getPanel():XY('MotionResolution', 'SpeedFactor')
xySpeedFactor.y = widgets.posUnder(xyShapeMorph)
xySpeedFactor.x = xyShapeMorph.x
xySpeedFactor.width = xyShapeMorph.width
xySpeedFactor.height = (motionTable.height / 2) - 5

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  tableMotion.resetUniqueIndex()
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
