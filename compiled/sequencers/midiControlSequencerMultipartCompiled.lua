-- sequencers/midiControlSequencer -- 
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
  tanh = function(x, z, w, y, i) return math.tanh(x) * z end,
  acos = function(x, z, w, y, i) return math.acos(x) * z end,
  wings = function(x, z, w, y, i) return math.acos((math.abs(-math.abs(x)+1) + -math.abs(x)+1)/2) * z end,
  atan2 = function(x, z, w, y, i) return math.atan2(y, x) * z end,
  crosser = function(x, z, w, y, i) return gem.avg({x, w}) * z end,
  diracDelta = function(x, z, w, y, i) return (math.exp(-1*(x/((0.0001+z)*2))^2))/(((0.0001+z)*2)*math.sqrt(math.pi)*16) end,
  diracDeltaFrexp = function(x, z, w, y, i) return (math.frexp(-1*(x/((0.0001+z)*2))^2))/(((0.0001+z)*2)*math.sqrt(math.pi)*16) end,
  swipe1 = function(x, z, w, y, i) return math.exp(math.abs(x)/y) * z end,
  swipe2 = function(x, z, w, y, i) return math.exp(math.tan(x)/math.pi) * z end,
  swipe3 = function(x, z, w, y, i) return math.exp(x-y) * z end,
  swipe4 = function(x, z, w, y, i) return (math.exp(x)) * gem.avg({z, x}) end,
  mayhemInTheMiddle = function(x, z, w, y, i) return math.sin((x * math.pi) + (z * math.tan(w * math.pi))) end,
  zeroDancer = function(x, z, w, y, i) return math.sin(x / z + z) * z end,
  testShape = function(x, z, w, y, i, b)
    -- TODO Add "Shaky sine"
    local f = 0
    local g = b.rand * ((i-1) / b.length)
    if z < 0 then
      f = z - g
    elseif z > 0 then
      f = z + g
    end
    return math.sin(x * math.pi) * f
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
  {name = "Dome", f = shapes.dome},
  {name = "Dome Small", f = shapes.domeSmall},
  {name = "Saw", f = shapes.sawInPhase},
  {name = "HPF Saw", f = shapes.hpfSaw},
  {name = "Analog Saw", f = shapes.sawAnalog},
  {name = "Fltr Sqr",  f = shapes.filteredSquare},
  {name = "Organ-Ish", f = shapes.organIsh},
  {name = "Tangent", f = shapes.tangent},
  {name = "Tanh", f = shapes.tanh},
  {name = "Acos", f = shapes.acos},
  {name = "Atan2", f = shapes.atan2},
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
  {name = "Dirac Delta (exp)", f = shapes.diracDelta, o = {factor = .3, z = .03}},
  {name = "Dirac Delta (frexp)", f = shapes.diracDeltaFrexp, o = {z = .03}},
  {name = "Swipe 1", f = shapes.swipe1},
  {name = "Swipe 2", f = shapes.swipe2},
  {name = "Swipe 3", f = shapes.swipe3},
  {name = "Swipe 4", f = shapes.swipe4, o = {z = -.25}},
  {name = "Random", f = shapes.random},
  {name = "Test Shape", f = shapes.testShape},
}

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

local function createShape(shapeIndex, shapeBounds, shapeOptions)
  local shapeDefinition = shapeDefinitions[shapeIndex]
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
  get = function(i,t,o) return createShape(i,t,o) end,
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

--------------------------------------------------------------------------------
-- Common functions and widgets that are shared for the modulation sequencers
--------------------------------------------------------------------------------

local arpeg -- Holds the arpeggiator function. Must be defined in the script that includes modseq.
local isPlaying = false
local activePage = 1
local numParts = 4
local numPages = 1
local maxPages = 8
local nextUp = 1
local paramsPerPage = {}
local paramsPerPart = {}

widgets.setColours({
  menuBackgroundColour = "#bf01011F",
  menuTextColour = "#9f02ACFE",
  menuArrowColour = "#9f09A3F4",
  menuOutlineColour = "#00000000",
  backgroundColour = "222222",
})

--------------------------------------------------------------------------------
-- Define widgets
--------------------------------------------------------------------------------

local pageButtons = {}
local colours = widgets.getColours()
local headerPanel = widgets.panel()
local footerPanel = widgets.panel()
local cyclePagesButton = footerPanel:OnOffButton("CyclePagesButton")
local changePageProbability = footerPanel:NumBox("ChangePageProbability", 0, 0, 100, true)
local defaultActions = {"Actions..."}

local actionMenu = footerPanel:Menu("ActionMenu", defaultActions)
actionMenu.enabled = false

--------------------------------------------------------------------------------
-- Common Functions
--------------------------------------------------------------------------------

-- Get the index for this part in paramsPerPart, given page and part number
local function getPartIndex(part, page)
  if type(page) == "nil" then
    page = activePage -- Default is the active page
  end
  --print("getPartIndex page/part/numParts", page, part, numParts)
  return (page * numParts) + (part - numParts)
end

-- Get page from part index
local function getPageFromPartIndex(partIndex)
  --print("getPageFromPartIndex partIndex", partIndex)
  return math.ceil(partIndex / maxPages)
end

local function advancePage()
  local next = activePage + 1
  if next > numPages then
    next = 1
  end
  pageButtons[next]:setValue(true)
end

local function gotoNextPage()
  -- Check that there is actually a a change
  if activePage == nextUp then
    return
  end
  activePage = nextUp
  for page,params in ipairs(paramsPerPage) do
    local isVisible = page == activePage
    params.sequencerPanel.visible = isVisible
    params.minRepeats.visible = isVisible
    pageButtons[page]:setValue(isVisible, false)
  end
end

local function clearPosition()
  for _,v in ipairs(paramsPerPart) do
    for i=1,v.numStepsBox.value do
      v.positionTable:setValue(i, 0)
    end
  end
end

local function setPageDuration(page)
  --print("setPageDuration for page", page)
  local pageResolutions = {}
  for part=1,numParts do
    local partIndex = getPartIndex(part, page)
    --print("getResolution for partIndex", partIndex)
    local partResolution = resolutions.getResolution(paramsPerPart[partIndex].stepResolution.value)
    if paramsPerPart[partIndex].stepButton.value then
      partResolution = partResolution * paramsPerPart[partIndex].numStepsBox.value
    end
    table.insert(pageResolutions, partResolution)
    --print("Added resolution/part/page", partResolution, part, page)
  end
  table.sort(pageResolutions)
  paramsPerPage[page].pageDuration = pageResolutions[#pageResolutions]
end

local function getShapeLoadOptions(partIndex, loadNew)
  if loadNew == true then
    return -- Load a new shape without adjustments
  end

  return {
    z = paramsPerPart[partIndex].shapeWidgets.z.value,
    phase = paramsPerPart[partIndex].shapeWidgets.phase.value,
    factor = paramsPerPart[partIndex].shapeWidgets.factor.value,
    amount = paramsPerPart[partIndex].shapeWidgets.amount.value,
  }
end

local function loadShape(partIndex, loadNew)
  local options = getShapeLoadOptions(partIndex, loadNew)
  local values = {}
  if paramsPerPart[partIndex].shapeMenu.value == 1 then
    -- If not shape was selected, just return
    return
  end
  local shapeIndex = paramsPerPart[partIndex].shapeMenu.value - 1
  values, options = shapes.get(shapeIndex, paramsPerPart[partIndex].seqValueTable, options)
  for i,v in ipairs(values) do
    paramsPerPart[partIndex].seqValueTable:setValue(i, v)
  end
  if loadNew == true then
    -- Update widgets with values from the shape
    local callChanged = false
    paramsPerPart[partIndex].shapeWidgets.z:setValue(options.z, callChanged)
    paramsPerPart[partIndex].shapeWidgets.phase:setValue(options.phase, callChanged)
    paramsPerPart[partIndex].shapeWidgets.factor:setValue(options.factor, callChanged)
    paramsPerPart[partIndex].shapeWidgets.amount:setValue(options.amount, callChanged)
  end
end

local function setNumSteps(partIndex, numSteps)
  --print("setNumSteps for partIndex/numSteps", partIndex, numSteps)
  paramsPerPart[partIndex].positionTable.length = numSteps
  paramsPerPart[partIndex].seqValueTable.length = numSteps
  if type(paramsPerPart[partIndex].smoothStepTable) ~= "nil" then
    paramsPerPart[partIndex].smoothStepTable.length = numSteps
  end
  local page = getPageFromPartIndex(partIndex)
  setPageDuration(page)
end

local function pageRunner()
  local repeatCounter = -1
  while isPlaying do
    repeatCounter = repeatCounter + 1
    local repeats = paramsPerPage[activePage].minRepeats.value
    --print("New round on page/duration/repeats/repeatCounter", activePage, paramsPerPage[activePage].pageDuration, repeats, repeatCounter)
    if repeatCounter >= repeats and nextUp == activePage then
      if gem.getRandomBoolean(changePageProbability.value) then
        nextUp = gem.getRandom(numPages)
      elseif cyclePagesButton.value == true then
        nextUp = activePage + 1
        if nextUp > numPages then
          nextUp = 1
        end
      end
      repeatCounter = 0 -- Reset repeat counter
    end

    gotoNextPage()

    waitBeat(paramsPerPage[activePage].pageDuration)
  end
end

local function startPlaying()
  if isPlaying == true then
    return
  end
  spawn(pageRunner)
  for i=1,numParts do
    --print("Start playing", i)
    spawn(arpeg, i)
  end
  isPlaying = true
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  --print("Stop playing")
  isPlaying = false
  clearPosition()
  gotoNextPage()
end

--------------------------------------------------------------------------------
-- Common Widgets
--------------------------------------------------------------------------------

headerPanel.backgroundColour = colours.menuOutlineColour
headerPanel.x = 10
headerPanel.y = 10
headerPanel.width = 700
headerPanel.height = 30

local label = headerPanel:Label("Label")
label.backgroundColour = "808080"
label.textColour = colours.backgroundColour
label.fontSize = 22
label.position = {0,0}
label.size = {190,25}

local labelInput = headerPanel:Label("Label")
labelInput.text = ""
labelInput.editable = true
labelInput.backgroundColour = colours.backgroundColour
labelInput.textColour = "808080"
labelInput.backgroundColourWhenEditing = "white"
labelInput.textColourWhenEditing = "black"
labelInput.fontSize = 16
labelInput.width = 180
labelInput.x = label.x + label.width + 10
labelInput.y = 3

local playButton = headerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = "#ff084486"
playButton.backgroundColourOn = "#ff02ACFE"
playButton.textColourOff = "#ff22FFFF"
playButton.textColourOn = "#efFFFFFF"
playButton.displayName = "Play"
playButton.size = {102,22}
playButton.x = headerPanel.width - playButton.width
playButton.y = 2
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

local autoplayButton = headerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = "#ff084486"
autoplayButton.backgroundColourOn = "#ff02ACFE"
autoplayButton.textColourOff = "#ff22FFFF"
autoplayButton.textColourOn = "#efFFFFFF"
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = {102,22}
autoplayButton.x = playButton.x - playButton.width - 5
autoplayButton.y = playButton.y

footerPanel.backgroundColour = colours.menuOutlineColour
footerPanel.x = 10
footerPanel.width = 700
if maxPages == 1 then
  footerPanel.enabled = false
  footerPanel.visible = false
  footerPanel.height = 10
else
  footerPanel.height = 30
end

changePageProbability.displayName = "Random"
changePageProbability.tooltip = "Probability of random page change"
changePageProbability.enabled = false
changePageProbability.unit = Unit.Percent
changePageProbability.size = {110,22}
changePageProbability.x = (33 * maxPages) + 102

local pageButtonSize = {25,22}

local nextPageButton = footerPanel:Button("NextPageButton")
nextPageButton.persistent = false
nextPageButton.enabled = numPages > 1
nextPageButton.displayName = ">"
nextPageButton.tooltip = "Go to next page in the cycle"
nextPageButton.size = pageButtonSize
nextPageButton.changed = function(self)
  advancePage()
end

cyclePagesButton.enabled = numPages > 1
cyclePagesButton.displayName = ">>"
cyclePagesButton.tooltip = "Play pages in cycle"
cyclePagesButton.backgroundColourOff = "#6600cc44"
cyclePagesButton.backgroundColourOn = "#aa00cc44"
cyclePagesButton.textColourOff = "#cc22FFFF"
cyclePagesButton.textColourOn = "#ccFFFFFF"
cyclePagesButton.size = pageButtonSize

local numPagesBox = footerPanel:NumBox("Pages", numPages, 1, maxPages, true)
numPagesBox.tooltip = "Number of active pages"
numPagesBox.backgroundColour = colours.menuBackgroundColour
numPagesBox.textColour = colours.menuTextColour
numPagesBox.size = {90,22}
numPagesBox.x = 0
numPagesBox.changed = function(self)
  numPages = self.value
  changePageProbability.enabled = self.value > 1
  nextPageButton.enabled = self.value > 1
  cyclePagesButton.enabled = self.value > 1
  for page=1,self.max do
    setPageDuration(page)
    pageButtons[page].enabled = page <= numPages
    paramsPerPage[page].minRepeats.enabled = numPages > 1
  end
  -- Update action menu
  local actionMenuItems = {}
  for i=1,#defaultActions do
    table.insert(actionMenuItems, defaultActions[i])
  end
  if numPages > 1 then
    for i=1,numPages do
      table.insert(actionMenuItems, "Copy settings from page " .. i)
    end
  end
  actionMenu.items = actionMenuItems
  actionMenu.enabled = #actionMenuItems > 1
end

-- Add page buttons
local xPadding = 1
for page=1,maxPages do
  local pageButton = footerPanel:OnOffButton("PageButton" .. page, (page==1))
  pageButton.persistent = false
  pageButton.enabled = page <= numPages
  pageButton.displayName = "" .. page
  pageButton.backgroundColourOff = "#ff084486"
  pageButton.backgroundColourOn = "#ff02ACFE"
  pageButton.textColourOff = "#ff22FFFF"
  pageButton.textColourOn = "#efFFFFFF"
  pageButton.size = pageButtonSize
  pageButton.x = numPagesBox.width + ((pageButton.width + xPadding) * page) - 17
  pageButton.changed = function(self)
    if self.value == true then
      nextUp = page -- register next up
      if isPlaying == false then
        gotoNextPage()
      end
    end
    self:setValue(true, false) -- The clicked button should stay active
  end
  table.insert(pageButtons, pageButton)
end

cyclePagesButton.x = pageButtons[#pageButtons].x + pageButtons[#pageButtons].width + xPadding
nextPageButton.x = cyclePagesButton.x + cyclePagesButton.width + xPadding

actionMenu.persistent = false
actionMenu.tooltip = "Select an action. NOTE: This changes data in the affected tables"
actionMenu.backgroundColour = colours.menuBackgroundColour
actionMenu.textColour = colours.menuTextColour
actionMenu.arrowColour = colours.menuArrowColour
actionMenu.outlineColour = colours.menuOutlineColour
actionMenu.showLabel = false
actionMenu.x = changePageProbability.x + changePageProbability.width + 5
actionMenu.size = {110,22}
actionMenu.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end
  -- Copy settings from another page
  local sourcePage = self.value - #defaultActions
  local targetPage = activePage
  for part=1,numParts do
    local sourcePartIndex = getPartIndex(part, sourcePage)
    local targetPartIndex = getPartIndex(part, targetPage)
    if sourcePartIndex ~= targetPartIndex then
      local source = paramsPerPart[sourcePartIndex]
      local target = paramsPerPart[targetPartIndex]
      target.numStepsBox:setValue(source.numStepsBox.value)
      for i=1, target.numStepsBox.value do
        target.seqValueTable:setValue(i, source.seqValueTable:getValue(i))
        target.smoothStepTable:setValue(i, source.smoothStepTable:getValue(i))
      end
      -- Copy Settings
      target.stepResolution:setValue(source.stepResolution.value)
      target.smoothInput:setValue(source.smoothInput.value)
      target.valueRandomization:setValue(source.valueRandomization.value)
      target.smoothRandomization:setValue(source.smoothRandomization.value)
      target.stepButton:setValue(source.stepButton.value)
      target.bipolarButton:setValue(source.bipolarButton.value)
    end
  end
  self.selected = 1
end

local function setTitle(title)
  label.text = title
end

local function setTitleTooltip(tooltip)
  label.tooltip = tooltip
end

--------------------------------------------------------------------------------
-- Return Module
--------------------------------------------------------------------------------

local modseq = {
  colours = colours,
  isPlaying = function() return isPlaying == true end,
  isNotPlaying = function() return isPlaying == false end,
  setArpFunc = function(f) arpeg = f end,
  setPlaying = function(m) isPlaying = m ~= false end,
  getNumParts = function() return numParts end,
  getNumPages = function() return numPages end,
  getMaxPages = function() return maxPages end,
  getPageParams = function(p) return paramsPerPage[p] end,
  addPageParams = function(params) table.insert(paramsPerPage, params) end,
  getPartParams = function(p) if type(p) == "number" then return paramsPerPart[p] end return paramsPerPart end,
  addPartParams = function(params) table.insert(paramsPerPart, params) end,
  headerPanel = headerPanel,
  footerPanel = footerPanel,
  actionMenu = actionMenu,
  loadShape = loadShape,
  labelInput = labelInput,
  playButton = playButton,
  autoplayButton = autoplayButton,
  getPartIndex = getPartIndex,
  setPageDuration = setPageDuration,
  setNumSteps = setNumSteps,
  setTitle = setTitle,
  setTitleTooltip = setTitleTooltip,
}

--------------------------------------------------------------------------------
-- A sequencer sending midi control change values
--------------------------------------------------------------------------------

local shapeNames = shapes.getShapeNames()
local shapeMenuItems = {"Select shape..."}
for _,v in ipairs(shapeNames) do
  table.insert(shapeMenuItems, v)
end

modseq.setTitle("Multi Midi CC Sequencer")

setBackgroundColour(modseq.colours.backgroundColour)

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

-- Add params that are to be editable per page / part
for page=1,modseq.getMaxPages() do
  local tableX = 0
  local tableY = 0
  local tableWidth = 640
  local tableHeight = 63
  local buttonRowHeight = 60
  local buttonSpacing = 10
  local defaultSteps = 16

  if modseq.getNumParts() == 1 then
    tableHeight = tableHeight * 1.5
  end

  local sequencerPanel = widgets.panel({name="SequencerPage" .. page})
  sequencerPanel.visible = page == 1
  sequencerPanel.backgroundColour = modseq.colours.menuOutlineColour
  sequencerPanel.x = 10
  sequencerPanel.y = modseq.headerPanel.height + 15
  sequencerPanel.width = 700
  sequencerPanel.height = modseq.getNumParts() * (tableHeight + buttonRowHeight)

  for part=1,modseq.getNumParts() do
    local isVisible = true
    local i = modseq.getPartIndex(part, page)
    print("Set paramsPerPart, page/part", page, i)

    -- Tables

    local positionTable = sequencerPanel:Table("Position" .. i, defaultSteps, 0, 0, 1, true)
    positionTable.visible = isVisible
    positionTable.enabled = false
    positionTable.persistent = false
    positionTable.fillStyle = "solid"
    positionTable.backgroundColour = "#9f02ACFE"
    positionTable.sliderColour = "#FFB5FF"
    positionTable.width = tableWidth
    positionTable.height = 3
    positionTable.x = tableX
    positionTable.y = tableY

    local seqValueTable = sequencerPanel:Table("ControlValue" .. i, defaultSteps, 0, 0, 127)
    seqValueTable.visible = isVisible
    seqValueTable.displayName = "Velocity"
    seqValueTable.tooltip = "Velocity for this step"
    seqValueTable.showPopupDisplay = true
    seqValueTable.showLabel = false
    seqValueTable.fillStyle = "solid"
    seqValueTable.sliderColour = "#9f09A3F4"
    if i % 2 == 0 then
      seqValueTable.backgroundColour = "#3f000000"
    else
      seqValueTable.backgroundColour = "#3f000000"
    end
    seqValueTable.width = tableWidth
    seqValueTable.height = tableHeight
    seqValueTable.x = tableX
    seqValueTable.y = positionTable.y + positionTable.height + 2
    
    local inputWidgetY = seqValueTable.y + seqValueTable.height + 5

    -- Inputs
    local partLabelInput = sequencerPanel:Label("Label")
    partLabelInput.text = "CC " .. (part+101)
    partLabelInput.editable = true
    partLabelInput.backgroundColour = modseq.colours.backgroundColour
    partLabelInput.textColour = "808080"
    partLabelInput.backgroundColourWhenEditing = "white"
    partLabelInput.textColourWhenEditing = "black"
    partLabelInput.fontSize = 16
    partLabelInput.width = 81
    partLabelInput.height = 20
    partLabelInput.x = 0
    partLabelInput.y = inputWidgetY

    local stepButton = sequencerPanel:OnOffButton("Step" .. i, false)
    stepButton.displayName = "Step"
    stepButton.tooltip = "The selected resolution applies to each step, not the whole round"
    stepButton.visible = isVisible
    stepButton.backgroundColourOff = "#ff084486"
    stepButton.backgroundColourOn = "#ff02ACFE"
    stepButton.textColourOff = "#ff22FFFF"
    stepButton.textColourOn = "#efFFFFFF"
    stepButton.size = {60,20}
    stepButton.x = partLabelInput.x + partLabelInput.width + buttonSpacing
    stepButton.y = inputWidgetY
    stepButton.changed = function(self)
      modseq.setPageDuration(page)
    end

    local stepResolution = sequencerPanel:Menu("StepResolution" .. i, resolutions.getResolutionNames())
    stepResolution.tooltip = "Set the resolution for each round (or step, if selected)"
    stepResolution.showLabel = false
    stepResolution.visible = isVisible
    stepResolution.selected = 11
    stepResolution.x = stepButton.x + stepButton.width + buttonSpacing
    stepResolution.y = inputWidgetY
    stepResolution.size = {66,20}
    stepResolution.backgroundColour = modseq.colours.menuBackgroundColour
    stepResolution.textColour = modseq.colours.menuTextColour
    stepResolution.arrowColour = modseq.colours.menuArrowColour
    stepResolution.outlineColour = modseq.colours.menuOutlineColour
    stepResolution.changed = function(self)
      modseq.setPageDuration(page)
    end

    local numStepsBox = sequencerPanel:NumBox("Steps" .. i, defaultSteps, 1, 128, true)
    numStepsBox.displayName = "Steps"
    numStepsBox.tooltip = "The Number of steps in the part"
    numStepsBox.visible = isVisible
    numStepsBox.backgroundColour = modseq.colours.menuBackgroundColour
    numStepsBox.textColour = modseq.colours.menuTextColour
    numStepsBox.arrowColour = modseq.colours.menuArrowColour
    numStepsBox.outlineColour = modseq.colours.menuOutlineColour
    numStepsBox.size = {90,20}
    numStepsBox.x = stepResolution.x + stepResolution.width + buttonSpacing
    numStepsBox.y = inputWidgetY
    numStepsBox.changed = function(self)
      print("numStepsBox.changed index/value", i, self.value)
      modseq.setNumSteps(i, self.value)
      modseq.loadShape(i)
    end

    local valueRandomization = sequencerPanel:NumBox("ValueRandomization" .. i, 0, 0, 100, true)
    valueRandomization.displayName = "Randomize"
    valueRandomization.tooltip = "Level of randomization applied to the control value"
    valueRandomization.unit = Unit.Percent
    valueRandomization.visible = isVisible
    valueRandomization.backgroundColour = modseq.colours.menuBackgroundColour
    valueRandomization.textColour = modseq.colours.menuTextColour
    valueRandomization.arrowColour = modseq.colours.menuArrowColour
    valueRandomization.outlineColour = modseq.colours.menuOutlineColour
    valueRandomization.size = {114,20}
    valueRandomization.x = numStepsBox.x + numStepsBox.width + buttonSpacing
    valueRandomization.y = inputWidgetY

    local midiControlNumber = sequencerPanel:NumBox("MidiControlNumber" .. i, (part+101), 0, 127, true)
    midiControlNumber.displayName = "CC"
    midiControlNumber.tooltip = "The midi control number to send the value to"
    midiControlNumber.visible = isVisible
    midiControlNumber.backgroundColour = modseq.colours.menuBackgroundColour
    midiControlNumber.textColour = modseq.colours.menuTextColour
    midiControlNumber.size = valueRandomization.size
    midiControlNumber.x = valueRandomization.x + valueRandomization.width + buttonSpacing
    midiControlNumber.y = inputWidgetY

    local channelBox = sequencerPanel:NumBox("Channel" .. i, 0, 0, 16, true)
    channelBox.displayName = "Channel"
    channelBox.tooltip = "Midi channel that receives CC from this part. 0 = omni"
    channelBox.visible = isVisible
    channelBox.backgroundColour = modseq.colours.menuBackgroundColour
    channelBox.textColour = modseq.colours.menuTextColour
    channelBox.arrowColour = modseq.colours.menuArrowColour
    channelBox.outlineColour = modseq.colours.menuOutlineColour
    channelBox.size = valueRandomization.size
    channelBox.x = midiControlNumber.x + midiControlNumber.width + buttonSpacing
    channelBox.y = inputWidgetY

    widgets.setSection({
      x = 0,
      y = widgets.posUnder(partLabelInput) + 6,
      xSpacing = buttonSpacing,
    })

    local shapeMenu = widgets.menu("Shape", shapeMenuItems, {
      name = "shape" .. i,
      showLabel = false,
      width = 131,
      changed = function(self)
        modseq.loadShape(i, true)
      end
    })

    local shapeWidgets = shapes.getWidgets(115, true, i)
    shapeWidgets.amount = shapes.getAmountWidget(115, true, i)

    local smoothButton = widgets.button("Smooth", false, {
      name = "Smooth" .. i,
      tooltip = "Use smoothing (non destructive) to even out the transition between value changes",
      width = 58,
    })

    shapeWidgets.phase.changed = function(self) modseq.loadShape(i) end
    shapeWidgets.factor.changed = function(self) modseq.loadShape(i) end
    shapeWidgets.z.changed = function(self) modseq.loadShape(i) end
    shapeWidgets.amount.changed = function(self) modseq.loadShape(i) end

    local xyShapeMorph = widgets.getPanel():XY('ShapePhase' .. i, 'ShapeMorph' .. i)
    xyShapeMorph.x = widgets.posSide(seqValueTable) - 8
    xyShapeMorph.y = seqValueTable.y
    xyShapeMorph.width = 58
    xyShapeMorph.height = seqValueTable.height

    modseq.addPartParams({shapeWidgets=shapeWidgets,shapeMenu=shapeMenu,stepButton=stepButton,smoothButton=smoothButton,valueRandomization=valueRandomization,midiControlNumber=midiControlNumber,seqValueTable=seqValueTable,channelBox=channelBox,positionTable=positionTable,stepResolution=stepResolution,numStepsBox=numStepsBox,partLabelInput=partLabelInput})

    tableY = tableY + tableHeight + buttonRowHeight
  end

  local minRepeats = modseq.footerPanel:NumBox("MinRepeats" .. page, 1, 1, 128, true)
  minRepeats.displayName = "Repeats"
  minRepeats.tooltip = "The minimum number of repeats before page will be changed (only relevant when multiple pages are activated)"
  minRepeats.visible = page == 1
  minRepeats.enabled = false
  minRepeats.backgroundColour = modseq.colours.menuBackgroundColour
  minRepeats.textColour = modseq.colours.menuTextColour
  minRepeats.arrowColour = modseq.colours.menuArrowColour
  minRepeats.outlineColour = modseq.colours.menuOutlineColour
  minRepeats.size = {100,20}
  minRepeats.x = modseq.actionMenu.x + modseq.actionMenu.width + 8
  minRepeats.y = modseq.actionMenu.y

  modseq.addPageParams({sequencerPanel=sequencerPanel,minRepeats=minRepeats,pageDuration=4,active=(page==1)})
  modseq.setPageDuration(page)
end

modseq.footerPanel.y = modseq.getPageParams(1).sequencerPanel.y + modseq.getPageParams(1).sequencerPanel.height

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

local function sendControlChange(duration, startValue, targetValue, controlChangeNumber, channel)
  local durationInMs = beat2ms(duration)
  local numberOfIterations = math.max(startValue, targetValue) - math.min(startValue, targetValue)
  local durationPerIteration = math.ceil(durationInMs / numberOfIterations)
  local value = startValue
  local increment = 1
  if targetValue < startValue then
    increment = -1
  end
  print("numberOfIterations, durationPerIteration", numberOfIterations, durationPerIteration)
  local i = 0
  repeat
    value = value + increment -- Increment value
    i = i + 1 -- Increment counter
    controlChange(controlChangeNumber, gem.round(value), channel)
    --print("Over time controlChangeNumber, value, channel", controlChangeNumber, value, channel)
    wait(durationPerIteration)
  until value == targetValue or i >= numberOfIterations
  print("value == targetValue or i >= numberOfIterations", value, targetValue, i, numberOfIterations)
end

local function getNextValue(seqValueTable, currentPosition, numStepsInPart)
  local nextPosition = currentPosition + 1
  if nextPosition > numStepsInPart then
    nextPosition = 1
  end
  return seqValueTable:getValue(nextPosition)
end

modseq.setArpFunc(function(part)
  local index = 0
  local startValue = nil
  local targetValue = nil
  while modseq.isPlaying() do
    local partIndex = modseq.getPartIndex(part)
    local numStepsInPart = modseq.getPartParams(partIndex).numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local smooth = modseq.getPartParams(partIndex).smoothButton.value
    local step = modseq.getPartParams(partIndex).stepButton.value
    local duration = resolutions.getResolution(modseq.getPartParams(partIndex).stepResolution.value)
    local seqValueTable = modseq.getPartParams(partIndex).seqValueTable
    local controlChangeNumber = modseq.getPartParams(partIndex).midiControlNumber.value
    local channel = modseq.getPartParams(partIndex).channelBox.value
    local valueRandomizationAmount = modseq.getPartParams(partIndex).valueRandomization.value

    -- Set position
    for i=1, numStepsInPart do
      local isActiveStep = i >= currentPosition and i < currentPosition + 1
      if isActiveStep then
        modseq.getPartParams(partIndex).positionTable:setValue(i, 1)
      else
        modseq.getPartParams(partIndex).positionTable:setValue(i, 0)
      end
    end

    if step == false then
      duration = duration / numStepsInPart
    end

    -- Send cc
    if type(startValue) == "nil" then
      startValue = seqValueTable:getValue(currentPosition)
      startValue = gem.randomizeValue(startValue, seqValueTable.min, seqValueTable.max, valueRandomizationAmount)
    end
    targetValue = getNextValue(seqValueTable, currentPosition, numStepsInPart) -- Get next value
    targetValue = gem.randomizeValue(targetValue, seqValueTable.min, seqValueTable.max, valueRandomizationAmount)
    if channel == 0 then
      channel = nil -- Send on all channels
    end
    if smooth == false then
      controlChange(controlChangeNumber, gem.round(startValue), channel)
      --print("Send controlChangeNumber, startValue, channel", controlChangeNumber, startValue, channel)
    else
      -- Send cc over time
      spawn(sendControlChange, duration, startValue, targetValue, controlChangeNumber, channel)
    end
    startValue = targetValue

    -- Increment position
    index = (index + 1) % numStepsInPart

    -- Wait for next beat
    waitBeat(duration)
  end
end)

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function onNote(e)
  if modseq.autoplayButton.value == true then
    postEvent(e)
  else
    modseq.playButton:setValue(true)
  end
end

function onRelease(e)
  if modseq.autoplayButton.value == true then
    postEvent(e)
  else
    modseq.playButton:setValue(false)
  end
end

function onTransport(start)
  if modseq.autoplayButton.value == true then
    modseq.playButton:setValue(start)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local numStepsData = {}
  local seqValueTableData = {}
  local partLabelInputData = {}

  for _,v in ipairs(modseq.getPartParams()) do
    table.insert(numStepsData, v.numStepsBox.value)
    table.insert(partLabelInputData, v.partLabelInput.text)
    for j=1, v.numStepsBox.value do
      table.insert(seqValueTableData, v.seqValueTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, numStepsData)
  table.insert(data, seqValueTableData)
  table.insert(data, partLabelInputData)
  table.insert(data, modseq.labelInput.text)

  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqValueTableData = data[2]
  local partLabelInputData = data[3]
  modseq.labelInput.text = data[4]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    modseq.getPartParams(i).numStepsBox:setValue(v)
    modseq.getPartParams(i).partLabelInput.text = partLabelInputData[i]
    modseq.getPartParams(i).seqValueTable.length = v
    for j=1, v do
      modseq.getPartParams(i).seqValueTable:setValue(j, seqValueTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
  for page=1,modseq.getNumPages() do
    modseq.setPageDuration(page)
  end
end
