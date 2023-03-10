-- modular/lifeTrigger -- 
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

-- Holds the shape definitions - functions get the following variables
-- x is the current time-value getting plotted, from -1.0 to 1.0
-- z is the current table number, from -1.0 to 1.0
-- w is the current time-value getting plotted, from 0.0 to 1.0 (same as (x+1)/2)
-- y is the current table number, from 0.0 to 1.0 (same as (z+1)/2)
-- i = current index
-- b = bounds (min, max, length, unipolar)
-- q = gem.round(1+((x+1)/2)*511)
local shapes = {
  ramp = function(x, z, w, y, i, b) return x * z end,
  triangleShaper = function(x, z, w, y, i) return math.min(2+2*x, math.abs((x-0.5)*2)-1) * z end,
  sine = function(x, z, w, y, i) return math.sin(x*math.pi) * z end,
  tangent = function(x, z, w, y, i) return math.tan(x) * z end,
  sawInPhase = function(x, z, w, y, i) return (gem.sign(x)-x) * z end,
  sinToNoise = function(x, z, w, y, i) return 2*gem.avg({math.sin(z*x*math.pi),(1-z)*gem.getRandom()}) end,
  wacky = function(x, z, w, y, i) return math.sin(((x)+1)^(z-1)*math.pi) end,
  hpfSqrToSqr = function(x, z, w, y, i) if x < 0 then return math.sin((z*0.5)*math.pi)^(x+1) end return -math.sin((z*0.5)*math.pi)^x end,
  windowYSqr = function(x, z, w, y, i) local v = 1 if math.abs(x) > 0.5 then v = (1-math.abs(x))*2 end return v * math.min(1, math.max(-1,8*math.sin((z+0.02)*x*math.pi*32))) end,
  filteredSquare = function(x, z, w, y, i) return (1.2*math.sin(x*math.pi)+0.31*math.sin(x*math.pi*3)+0.11*math.sin(x*math.pi*5)+0.033*math.sin(x*math.pi*7)) * z end,
  organIsh = function(x, z, w, y, i) return (math.sin(x*math.pi)+(0.16*(math.sin(2*x*math.pi)+math.sin(3*x*math.pi)+math.sin(4*x*math.pi)))) * z end,
  sawAnalog = function(x, z, w, y, i) return (2.001 * (math.sin(x * 0.7905) - 0.5)) * z end,
  dome = function(x, z, w, y, i) return (2 * (math.sin(x * 1.5705) - 0.5)) * z end,
  brassy = function(x, z, w, y, i) return math.sin(math.pi*gem.sign(x)*(math.abs(x)^(((1-z)+0.1)*math.pi*math.pi))) end,
  taffy = function(x, z, w, y, i) return math.sin(x*math.pi*2)*math.cos(x*math.pi)*math.cos(z*math.pi*(math.abs((x*2)^3)-1)*math.pi) end,
  random = function(x, z, w, y, i) return ((gem.getRandom() * 2) - 1) * z end,
  harmonicSync = function(x, z, w, y, i) return math.sin(x*math.pi*(2+(62*z*z*z)))*math.sin(x*math.pi) end,
  softSine = function(x, z, w, y, i) return 0.5*(math.cos(x*math.pi/2)*((math.sin((x)*math.pi)+(1-z)*(math.sin(z*((x*x)^z)*math.pi*32))))) end,
  tripleSin = function(x, z, w, y, i) return math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x)) end,
  pwm50to100 = function(x, z, w, y, i) if x > z then return 1 end return -1 end,
  chaosToSine = function(x, z, w, y, i) return math.sin(math.pi*z*z*32*math.log(x+1)) end,
  sawSinReveal = function(x, z, w, y, i) if x + 1 > z * 2 then return x end return math.sin(x * math.pi) end,
  domeSmall = function(x, z, w, y, i) return (-1-1.275*math.sin(w*math.pi)) * z end,
  zero = function(x, z, w, y, i, b) if b.unipolar then return -1 end return 0 end,
  minMax = function(x, z, w, y, i) return z end,
  oddAndEven = function(x, z, w, y, i) x = 1 if i % 2 == 0 then x = -1 end return x * z end,
  lofiTriangle = function(x, z, w, y, i) return ((gem.round(16*math.abs(x))/8.0)-1) * z end,
  hpfSaw = function(x, z, w, y, i) return (x-(0.635*math.sin(x*math.pi))) * z end,
  squareTri = function(x, z, w, y, i) return (-1*(gem.sign(x)*0.5)+(math.abs(x)-0.5)) * z end,
  sineStrech = function(x, z, w, y, i) return math.sin(x^(1+(gem.round(z*32)*2))*math.pi) end,
  squareSawBit = function(x, z, w, y, i) return math.sin((2-(z/4))*x*x*math.pi)/gem.round(x*32*((z/4)*(z/4)-0.125)) end,
  loFiTriangles = function(x, z, w, y, i) return (gem.round((2+(z*14))*math.abs(x))/(1+(z*7.0)))-1 end,
  talkative1 = function(x, z, w, y, i) return 1.4*math.cos(x*math.pi/2)*(.5*math.sin(((z*5)+1)*3*x)+.10*math.sin(((z*6)+1)*2*x)+.08*math.sin((((1-z)*3)+1)*12*x)) end,
  sinClipper = function(x, z, w, y, i) return math.sin(x*math.pi)*(((z*z)+0.125)*8) end,
  pitfall = function(x, z, w, y, i) return (x*128)%(z*16)*0.25 end,
  nascaLines = function(x, z, w, y, i, b) return math.sqrt(1/i)*(((i/b.max)*(z+0.1)*b.max)%3)*0.5 end,
  kick = function(x, z, w, y, i) return math.sin(math.pi*z*z*32*math.log(x+1)) end,
  sinToSaw = function(x, z, w, y, i) return math.sin(-x*math.pi)*(1-z)+(-x*z) end,
  zeroCrossing = function(x, z, w, y, i) return math.sin((x+1)*math.pi*(z+1))*(-math.abs(x)^32+1) end,
  vosim = function(x, z, w, y, i) return -(w-1)*math.sin(w*math.pi*8*(math.sin(z)+1.5))^2 end,
  vosimNormalized = function(x, z, w, y, i) return (-(w-1)*math.sin(w*math.pi*9*(math.sin(y)+1.3))^2-.5)*2 end,
  --tanh = function(x, z, w, y, i) return math.tanh(x) * z end,
  acos = function(x, z, w, y, i) return math.acos(x) * z end,
  wings = function(x, z, w, y, i) return math.acos((math.abs(-math.abs(x)+1) + -math.abs(x)+1)/2) * z end,
  --atan2 = function(x, z, w, y, i) return math.atan2(y, x) * z end,
  crosser = function(x, z, w, y, i) return gem.avg({x, w}) * z end,
  diracDelta = function(x, z, w, y, i) return (math.exp(-1*(x/((0.0001+z)*2))^2))/(((0.0001+z)*2)*math.sqrt(math.pi)*16) end,
  diracDeltaFrexp = function(x, z, w, y, i) return (math.frexp(-1*(x/((0.0001+z)*2))^2))/(((0.0001+z)*2)*math.sqrt(math.pi)*16) end,
  diracDeltaRand = function(x, z, w, y, i, b) return (math.exp(-1*(x/((0.0001+z)*2))^2))/(((0.0001+z)*2)*math.sqrt(math.pi)*math.min(8, b.rand*32)) end,
  swipe1 = function(x, z, w, y, i) return math.exp(math.abs(x)/y) * z end,
  swipe2 = function(x, z, w, y, i) return math.exp(math.tan(x)/math.pi) * z end,
  swipe3 = function(x, z, w, y, i) return math.exp(x-y) * z end,
  swipe4 = function(x, z, w, y, i) return (math.exp(x)) * gem.avg({z, x}) end,
  mayhemInTheMiddle = function(x, z, w, y, i) return math.sin((x * math.pi) + (z * math.tan(w * math.pi))) end,
  zeroDancer = function(x, z, w, y, i) return math.sin(x / z + z) * z end,
  shakySine = function(x, z, w, y, i, b)
    local f = 0
    local g = b.rand * ((i-1) / b.length)
    if z < 0 then
      f = z - g
    elseif z > 0 then
      f = z + g
    end
    return math.sin(x * math.pi) * f
  end,
  testShape = function(x, z, w, y, i, b)
    return x * z
  end
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
  --{name = "Tanh", f = shapes.tanh},
  {name = "Acos", f = shapes.acos},
  --{name = "Atan2", f = shapes.atan2},
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

local function getValueOrDefault(value, default)
  if type(value) == "number" then
    return value
  end
  return default
end

local function getShapeOptions(overrides)
  local defaultShapeOptions = getDefaultShapeOptions()
  if type(overrides) == "nil" then
    return defaultShapeOptions
  end
  return {
    z = getValueOrDefault(overrides.z, defaultShapeOptions.z),
    phase = getValueOrDefault(overrides.phase, defaultShapeOptions.phase),
    factor = getValueOrDefault(overrides.factor, defaultShapeOptions.factor),
    amount = getValueOrDefault(overrides.amount, defaultShapeOptions.amount),
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

local getUnipolar = function(v) return (v + 1) / 2 end

local function getShapeBounds(shapeBounds)
  local bounds = {}
  if type(shapeBounds) == "nil" then
    shapeBounds = {}
  end
  bounds.min = getValueOrDefault(shapeBounds.min, -1) -- x-azis max value
  bounds.max = getValueOrDefault(shapeBounds.max, 1) -- x-azis min value
  bounds.length = getValueOrDefault(shapeBounds.length, 128) -- y-axis steps
  bounds.unipolar = bounds.min >= 0 --  Whether the shape is unipolar
  bounds.rand = gem.getRandom() -- A random number that will be equal across all steps
  return bounds
end

local function createShape(shapeIndexOrName, shapeBounds, shapeOptions)
  if type(shapeIndexOrName) == "string" then
    shapeIndexOrName = getShapeIndexFromName(shapeIndexOrName)
  end
  local shapeDefinition = shapeDefinitions[shapeIndexOrName]
  local bounds = getShapeBounds(shapeBounds)
  local options = getShapeTemplate(shapeOptions, shapeDefinition.o)
  local shape = {}
  for i=1,bounds.length do
    local x = options.factor * (gem.getChangePerStep(((i-1)*2), bounds.length) + options.phase)
    local z = options.z
    local w = getUnipolar(x)
    local y = getUnipolar(z)
    local value = shapeDefinition.f(x, z, w, y, i, bounds)
    if bounds.unipolar then
      value = getUnipolar(value)
    end
    value = (bounds.max * value) * (options.amount / 100)
    table.insert(shape, math.max(bounds.min, math.min(bounds.max, value)))
  end
  return shape, options
end

local function getAmountWidget(width, showLabel, i)
  -- Widget for controlling shape amount
  if type(width) == "nil" then
    width = 120
  end
  if type(i) == "nil" then
    i = ""
  end
  return widgets.numBox("Amount", getShapeOptions().amount, {
    name = "ShapeAmount" .. i,
    tooltip = "Set the shape amount.",
    width = width,
    showLabel = showLabel == true,
    unit = Unit.Percent,
  })
end

local function getShapeWidgets(width, showLabel, i)
  -- Widgets for controlling shape
  if type(width) == "nil" then
    width = 120
  end
  if type(i) == "nil" then
    i = ""
  end
  local shapeOptions = getShapeOptions()
  return {
    factor = widgets.numBox("Shape Factor", shapeOptions.factor, {
      name = "ShapeFactor" .. i,
      tooltip = "Set the factor (multiplier) applied to the value of each step.",
      width = width,
      showLabel = showLabel == true,
      min = -8,
      max = 8,
    }),
    phase = widgets.numBox("Shape Phase", shapeOptions.phase, {
      name = "ShapePhase" .. i,
      tooltip = "Set the phase applied to the shape (move left/right).",
      width = width,
      showLabel = showLabel == true,
      min = -1,
      max = 1,
    }),
    z = widgets.numBox("Shape Morph", shapeOptions.z, {
      name = "ShapeMorph" .. i,
      tooltip = "Set the morph value. This value is mostly assigned to amplitude, but it depends on the shape.",
      width = width,
      showLabel = showLabel == true,
      min = -1,
      max = 1,
    })
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

local function getResolutionsByType(maxResolutionIndex)
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
end

-- Returns a table of resolutions indexes that are "approved" to use
local function getSelectedResolutions(resolutionsByType, minResolutionIndex, maxResolutionIndex)
  if type(minResolutionIndex) == "nil" then
    minResolutionIndex = 1 -- Slowest resolution
  end
  if type(maxResolutionIndex) == "nil" then
    maxResolutionIndex = #resolutionValues -- Fastest resolution
  end
  local selectedResolutions = {}
  for i=1,3 do
    for _,resolutionIndex in ipairs(resolutionsByType[i]) do
      if resolutionIndex >= minResolutionIndex and resolutionIndex <= maxResolutionIndex then
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
    options.selectedResolutions = getSelectedResolutions(resolutionsByType, options.minResolutionIndex, options.maxResolutionIndex)
  end

  --print("BEFORE currentIndex", currentIndex)
  local resolutionIndex = currentIndex
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
      if gem.getRandomBoolean(options.adjustBias) == false and type(doubleResIndex) == "number" and gem.tableIncludes(options.selectedResolutions, doubleResIndex) then
        resolution = resolutionValues[doubleResIndex]
        --print("Slower resolution", resolution)
      else
        resolution = resolution / 2
        --print("Faster resolution", resolution)
      end
    end
    -- Set dotted (or tri) on duration if no change was done to the lenght, or probability hits
    --if doubleOrHalf == false or gem.getRandomBoolean(options.dotOrTriProbaility) then
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
  currentIndex = gem.getIndexFromValue(resolution, resolutionValues)
  --print("AFTER currentIndex", currentIndex)
  if type(currentIndex) == "number" and gem.tableIncludes(options.selectedResolutions, currentIndex) then
    --print("Got resolution from the current index")
    return resolutionValues[currentIndex]
  end

  return currentResolution
end

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
-- Life Trigger - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local backgroundColour = "404040"
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local channel = 1
local gate = 90 -- TODO Param?
local ruleWidgets = {}
local ruleResolutions = resolutions.getResolutionNames({"Faster", "Dot/Tri", "Slower", "Base Resolution"})
local resolutionNames = resolutions.getResolutionNames()
local resolution = 20 -- The default resolution
local minResolution = 1 -- Slowest
local maxResolution = #resolutionNames -- Fastest
local velocity = 64
local rows = 4 -- Number of rows in the board
local cols = 4 -- Number of columns in the board
local cells = {} -- Holds the cell widgets
local evolve = false -- Every generation changes the base resolution to the resolution that was selected by chance
local dead = false -- Dead cells are played as pause - add an option for min live cells before accepting dead?
local locked = true -- Board is locked to move through all live cells before next gen - it starts locked to not kill the initial state
local currentRowIndex = 1
local currentColIndex = 1
local liveCells = 0 -- Holds the current live cells until next iteration
local resolutionMenu
local fill = false -- TODO Param
local shapeMenu
local shapeNames = shapes.getShapeNames()
local shapeMenuItems = {"Empty Board"}
for _,v in ipairs(shapeNames) do
  table.insert(shapeMenuItems, v)
end

local rules = {
  "Dead cells become alive when they have three alive neighbors",
  "Cells stay alive when they have two live neighbors",
  "Cells stay alive when they have three live neighbors",
  "Cells dies",
}

local ruleNames = {
  "Rebirth (Three Neighbors)",
  "Stay Alive (Two Neighbors)",
  "Stay Alive (Three Neighbors)",
  "Die",
}

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function clearCells()
  --print("Clear cells")
  currentRowIndex = 1
  currentColIndex = 1 -- Reset
  liveCells = 0 -- Reset
  for i = 1, rows do
    for j = 1, cols do
      cells[i][j].value = false
      cells[i][j].backgroundColourOn = widgets.getColours().backgroundColourOn
      cells[i][j].backgroundColourOff = widgets.getColours().backgroundColourOff
      -- If evolve is active, and the sequencer is playing, cells preserve their resolution
      local preserve = isPlaying and evolve
      if preserve == false then
        cells[i][j].displayName = resolutionNames[resolution]
        cells[i][j].tooltip = resolutions.getResolution(resolution) .. ""
      end
    end
  end
end

local function loadShape(shapeIndex)
  if type(shapeIndex) == "nil" then
    shapeIndex = gem.getRandom(#shapeNames)
    shapeMenu:setValue(shapeIndex + 1, false) 
  end
  print("--- NEW SHAPE ---", shapeIndex)
  clearCells() -- Deactivate all cells
  local values = shapes.get(shapeIndex, {min=1,max=rows,length=cols})
  for col = 1, cols do
    local value = math.ceil(values[col])
    for row = 1, rows do
      if fill then
        cells[row][col].value = value >= row -- Fill
      else
        cells[row][col].value = value == row -- Line
      end
    end
  end
  locked = true -- Lock to preserve the shape
end

local function updateBoard()
  -- Create a new board to hold the next generation
  local newGeneration = {}
  liveCells = 0 -- Clear live cells

  print("--- NEXT GENERATION! ---")

  -- Iterate through each cell on the board
  for i = 1, rows do
    newGeneration[i] = {}
    for j = 1, cols do
      local count = 0

      -- Count the number of live neighbors
      for x = -1, 1 do
        for y = -1, 1 do
          if x ~= 0 or y ~= 0 then
            local row = i + x
            local col = j + y

            -- Check if the cell is on the board
            if row >= 1 and row <= rows and col >= 1 and col <= cols then
              local val = 0
              if cells[row][col].value == true then
                val = 1
              end
              count = count + val
            end
          end
        end
      end

      -- Alive rules:
      ---- Cell stays alive (count == 2)
      ---- Cell stays alive (count == 3)
      ---- Cell becomes alive (count == 3)

      -- Dead cells go back to the base resolution
      -- Live cells are evolving according to the setting for the given rule

      -- The rules are very simple. In the next generation, the next click of the clock, the squares are going to change statuses in some way or another:
      ---- Any live cell with fewer than two live neighbours dies, as if by underpopulation.
      ---- Any live cell with two or three live neighbours lives on to the next generation.
      ---- Any live cell with more than three live neighbours dies, as if by overpopulation.
      ---- Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
      
      -- These rules, which compare the behaviour of the automaton to real life, can be condensed into the following:
      ---- Any live cell with two or three live neighbours survives.
      ---- Any dead cell with three live neighbours becomes a live cell.
      ---- All other live cells die in the next generation. Similarly, all other dead cells stay dead.

      -- Apply the rules of the game
      if cells[i][j].value == false and count == 3 then
        -- Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
        newGeneration[i][j] = 1
      elseif cells[i][j].value == true and count == 2 then
        -- Any live cell with two live neighbours lives on to the next generation.
        newGeneration[i][j] = 2
      elseif cells[i][j].value == true and count == 3 then
        -- Any live cell with three live neighbours lives on to the next generation.
        newGeneration[i][j] = 3
      else
        -- All other live cells die in the next generation. Similarly, all other dead cells stay dead.
        newGeneration[i][j] = 4
      end
    end
  end

  -- Update the cells for the next generation
  local changeCount = 0
  for i,v in ipairs(newGeneration) do
    for j,rule in ipairs(v) do
      local alive = rule < #rules
      local resIndex = nil
      local beatValue = nil
      local options = {}
      local baseResolutionIndex = resolution

      -- When evolve is active, we get the base resolution from the cell
      if evolve then
        baseResolutionIndex = gem.getIndexFromValue(tonumber(cells[i][j].tooltip), resolutions.getResolutions())
      end

      if cells[i][j].value ~= alive then
        changeCount = gem.inc(changeCount)
      end

      --if alive then
        -- Set option for the selected rule if cell is alive
        --print("rule, ruleName, i, j", rule, ruleWidgets[rule].selectedText, i, j)
        if ruleWidgets[rule].selectedText == "Faster" then
          options = {adjustBias=100, doubleOrHalfProbaility=100, dotOrTriProbaility=0}
        elseif ruleWidgets[rule].selectedText == "Dot/Tri" then
          options = {adjustBias=50, doubleOrHalfProbaility=50, dotOrTriProbaility=100}
        elseif ruleWidgets[rule].selectedText == "Slower" then
          options = {adjustBias=0, doubleOrHalfProbaility=100, dotOrTriProbaility=0}
        elseif ruleWidgets[rule].selectedText == "Base Resolution" then
          resIndex = baseResolutionIndex
        elseif ruleWidgets[rule].value <= #resolutionNames then
          -- Fixed resolution
          resIndex = ruleWidgets[rule].value
          --print("Fixed resolution", resIndex)
        end
      --[[ else
        -- Dead cells return to base res, or keeps current res if evolve is active
        resIndex = baseResolutionIndex
      end ]]

      if type(resIndex) == "number" then
        beatValue = resolutions.getResolution(resIndex)
      else
        options.minResolutionIndex = minResolution -- TODO Debug this -- Slowest
        options.maxResolutionIndex = maxResolution -- TODO Debug this -- Fastest
        beatValue = resolutions.getResolutionVariation(resolutions.getResolution(baseResolutionIndex), options)
        resIndex = gem.getIndexFromValue(beatValue, resolutions.getResolutions())
        --print("resIndex, beatValue, i, j", resIndex, beatValue, i, j)
      end

      -- Update the cells
      cells[i][j].value = alive
      cells[i][j].backgroundColourOn = widgets.getColours().backgroundColourOn
      cells[i][j].backgroundColourOff = widgets.getColours().backgroundColourOff
      cells[i][j].displayName = resolutionNames[resIndex]
      cells[i][j].tooltip = beatValue .. ""
    end
  end

  -- Reset if stale board
  if changeCount == 0 then
    --print("Stale board...")
    loadShape()
  end
end

-- Returns a random resolution from the live cells
local function getCell()
  local cell = cells[currentRowIndex][currentColIndex]

  if type(cell) == "nil" then
    locked = false
    print("No cell")
    return
  end

  print("Found cell.value @ currentRowIndex, currentColIndex", cell.value, currentRowIndex, currentColIndex)

  currentColIndex = gem.inc(currentColIndex)

  if currentColIndex > cols then
    currentColIndex = 1 -- Reset
    currentRowIndex = gem.inc(currentRowIndex)
    if currentRowIndex > rows then
      -- Round complete - unlock board!
      currentRowIndex = 1 -- Reset
      locked = false
    end
  end

  if cell.value then
    cell.backgroundColourOn = "orange" -- TODO Other colour for "dead" cells?
  elseif dead then
    cell.backgroundColourOff = "505050"
  end
  return cell--tonumber(cell.tooltip), cell.value
end

local function countLiveCells()
  for i = 1, rows do
    for j = 1, cols do
      if cells[i][j].value then
        --table.insert(liveCells, cells[i][j])
        liveCells = gem.inc(liveCells)
      end
    end
  end
  --print("Found #liveCells", #liveCells)
  currentRowIndex = 1 -- Reset row position
  currentColIndex = 1 -- Reset col position
  locked = liveCells > 0
end

local function seq(uniqueId)
  local note = 0
  locked = true -- Ensure the board is locked when starting to preserve the current state
  while isPlaying and seqIndex == uniqueId do
    -- When board has been unlocked, we can move one generation ahead
    if liveCells == 0 then
      countLiveCells()
    end
    if locked == false then
      updateBoard()
    end
    local cell = getCell() -- Get cell at current pos
    if type(cell) ~= "nil" then
      local duration = tonumber(cell.tooltip)
      if cell.value then
        playNote(note, velocity, beat2ms(resolutions.getPlayDuration(duration, gate)), nil, channel)
        print("playNote", duration)
      end
      if cell.value or (cell.value == false and dead) then
        print("waitBeat", duration)
        waitBeat(duration)
      end
    end
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(seq, seqIndex)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
end

--------------------------------------------------------------------------------
-- Header Panel
--------------------------------------------------------------------------------

widgets.panel({
  width = 720,
  height = 30,
})

widgets.setSection({
  xSpacing = 5,
  ySpacing = 5,
})

widgets.label("Life Trigger", {
  tooltip = "A sequencer that use the rules from game of life to evolve resolutions",
  width = widgets.getPanel().width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 81,
  height = 22,
  x = 174,
  y = 5,
  cols = 10
})

shapeMenu = widgets.menu("Shape", shapeMenuItems, {
  tooltip = "If the board is empty, a random shape will be selected when playing starts",
  showLabel = false,
  width = 111,
  changed = function(self)
    clearCells()
    local shapeIndex = self.value - 1
    if shapeIndex > 0 then
      loadShape(shapeIndex)
    end
  end
})

widgets.button('Fill', fill, {
  --width = 45,
  tooltip = "Fill shape instead of drawing just the line",
  changed = function(self)
    fill = self.value
    shapeMenu:changed()
  end
})

--[[ widgets.button('Clear', {
  width = 45,
  tooltip = "Clear board",
  changed = clearCells
}) ]]

widgets.button('Shape', {
  --width = 45,
  tooltip = "Load board with a random shape",
  changed = function()
    clearCells()
    loadShape()
  end
})

--[[ widgets.button('Evolve', evolve, {
  width = 45,
  tooltip = "When evolve is active, the resolution for the next generation is taken from the cell, instead of from the base resolution",
  changed = function(self)
    evolve = self.value
    resolution = resolutionMenu.value
  end
})

widgets.button('Dead', dead, {
  width = 45,
  tooltip = "When dead is active, dead cells are played as pause",
  changed = function(self)
    dead = self.value
  end
}) ]]

--[[ resolutionMenu = widgets.menu("Duration", resolution, resolutionNames, {
  tooltip = "Set the base resolution",
  showLabel = false,
  changed = function(self)
    resolution = self.value
    clearCells()
    loadShape()
  end
}) ]]

widgets.numBox('Ch', channel, {
  tooltip = "Send note events starting on this channel",
  min = 1,
  max = 16,
  integer = true,
  changed = function(self) channel = self.value end
})

local autoplayButton = widgets.button('Auto Play', true, {
  tooltip = "Play automatically on transport",
})

local playButton = widgets.button('Play', false, {
  changed = function(self)
    if self.value == true then
      startPlaying()
    else
      stopPlaying()
    end
  end
})

--------------------------------------------------------------------------------
-- Board
--------------------------------------------------------------------------------

widgets.setSection({
  xSpacing = 0,
  ySpacing = 0,
})

widgets.panel({
  backgroundColour = backgroundColour,
  x = widgets.getPanel().x,
  y = widgets.posUnder(widgets.getPanel()),
  width = widgets.getPanel().width / 2,
  height = 180,
})

widgets.setSection({
  width = (widgets.getPanel().width - ((cols+1) * 5)) / cols,
  height = (widgets.getPanel().height - ((rows+1) * 5)) / rows,
  x = 5,
  y = 5,
  xSpacing = 5,
  ySpacing = 5,
  rowDirection = -1,
  row = rows - 1,
  cols = cols,
})

-- Create the cells
for i = 1, rows do
  cells[i] = {}
  for j = 1, cols do
    cells[i][j] = widgets.button(resolutionNames[resolution])
  end
end

--------------------------------------------------------------------------------
-- Rule Settings
--------------------------------------------------------------------------------

widgets.panel({
  backgroundColour = backgroundColour,
  x = widgets.getPanel().x + widgets.getPanel().width,
  y = widgets.getPanel().y + 5,
  width = 354,
  height = widgets.getPanel().height - 10,
})

widgets.setSection({
  width = 167,
  height = 20,
  xSpacing = 5,
  ySpacing = 10,
  x = 5,
  y = 5,
  cols = 2,
})

for i,rule in ipairs(rules) do
  table.insert(ruleWidgets, widgets.menu(ruleNames[i], #resolutionNames + i, ruleResolutions, {
    name = "AliveRule" .. i,
    tooltip = rule,
  }))
end

widgets.setSection({
  y = widgets.posUnder(ruleWidgets[#ruleWidgets]) + 5,
  ySpacing = 5,
  width = 81,
  cols = 4,
})

resolutionMenu = widgets.menu("Base", resolution, resolutionNames, {
  tooltip = "Set the base resolution",
  changed = function(self)
    resolution = self.value
    clearCells()
    loadShape()
  end
})

widgets.menu("Slowest", minResolution, resolutionNames, {
  tooltip = "Set the slowest allowed resolution for new generations",
  changed = function(self)
    minResolution = self.value
  end
})

widgets.menu("Fastest", maxResolution, resolutionNames, {
  tooltip = "Set the fastest allowed resolution for new generations",
  changed = function(self)
    maxResolution = self.value
  end
})

widgets.button('Evolve', evolve, {
  tooltip = "When evolve is active, the resolution for the next generation is taken from the cell, instead of from the base resolution",
  changed = function(self)
    evolve = self.value
    resolution = resolutionMenu.value
  end
})

widgets.col(3)

widgets.button('Play Dead', dead, {
  tooltip = "When dead is active, dead cells are played as pause",
  changed = function(self)
    dead = self.value
  end
})

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
  clearCells()
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