-- util/arpRandomizer -- 
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

local function shape(minValue, maxValue, numSteps, shapeFunc)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(1, numSteps)
  local shape = {}
  for i=1,numSteps do
    local value = math[shapeFunc](2 * math.pi * changePerStep * (i-1))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  if shapeFunc == 'sin' or shapeFunc == 'tan' then
    shape[#shape] = shape[1]
  else
    shape[#shape] = maxValue
  end
  return shape
end

local function triangle(minValue, maxValue, numSteps)
  local rising = true
  local numStepsUpDown = math.floor(numSteps / 2)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numStepsUpDown)
  local startValue = minValue
  local shape = {}
  for i=1,numSteps do
    table.insert(shape, startValue)
    if rising then
      startValue = startValue + changePerStep
      if startValue >= maxValue then
        rising = false
      end
    else
      startValue = startValue - changePerStep
    end
  end
  shape[#shape] = minValue
  return shape
end

local function rampUp(minValue, maxValue, numSteps)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numSteps)
  local startValue = minValue
  local shape = {}
  for i=1,numSteps do
    table.insert(shape, startValue)
    startValue = inc(startValue, changePerStep)
  end
  shape[#shape] = maxValue
  return shape
end

local function rampDown(minValue, maxValue, numSteps)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numSteps)
  local startValue = maxValue
  local shape = {}
  for i=1,numSteps do
    table.insert(shape, startValue)
    startValue = inc(startValue, -changePerStep)
  end
  shape[#shape] = minValue
  return shape
end

local gem = {
  inc = inc,
  round = round,
  shape = shape,
  rampUp = rampUp,
  rampDown = rampDown,
  triangle = triangle,
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
-- Arp Randomizer
--------------------------------------------------------------------------------
-- Randomize the settings of the Falcon arpeggiator
--------------------------------------------------------------------------------

local buttonAlpha = 0.9
local buttonBackgroundColourOff = "#ff084486"
local buttonBackgroundColourOn = "#ff02ACFE"
local buttonTextColourOff = "#ff22FFFF"
local buttonTextColourOn = "#efFFFFFF"
local backgroundColour = "202020" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "F0FF42" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

--------------------------------------------------------------------------------
-- Arp Randomization Functions
--------------------------------------------------------------------------------

--{"Auto", "+/-1", "+/-2", "+/-4", "+/-5", "+/-6", "Off"}
local function getArpOctave(octaveOption)
  if octaveOption == 1 then
    octaveOption = gem.getRandom(6) + 1
  end
  octaveOption = octaveOption - 1
  return gem.getRandom(-octaveOption,octaveOption)
end

local function getArpNumStrike()
  if gem.getRandomBoolean(25) then
    return gem.getRandom(4)
  end
  return 1 -- default
end

local function getArpStepLength()
  if gem.getRandomBoolean(75) then
    return 1.0 -- default
  end

  local min = 60
  local max = 110

  if gem.getRandomBoolean() then
    min = 75
  end

  if gem.getRandomBoolean() then
    max = 100
  end

  return gem.getRandom(min, max) / 100
end

-- {"Auto", "Up, Down, Up & Down, Down & Up", "Off"}
local function getArpMode(modeOption)
  if modeOption == 1 and gem.getRandomBoolean() then
    return gem.getRandom(0,26)
  end
  
  if modeOption == 2 then
    return gem.getRandom(0,3)
  end
  
  return 0 -- default
end

-- {"Auto", "Even", "Odd", "2, 4, 8, 16", "3, 6, 12, 24", "Off"}
local function getArpNumSteps(lengthOption)
  if lengthOption == 1 then -- Auto
    return gem.getRandom(128)
  end
  if lengthOption == 2 then -- Even
    local steps = gem.getRandom(128)
    while steps % 2 ~= 0 do
      steps = gem.getRandom(128)
    end
    return steps
  end
  if lengthOption == 3 then -- Odd
    local steps = gem.getRandom(128)
    while steps % 2 == 0 do
      steps = gem.getRandom(128)
    end
    return steps
  end
  if lengthOption == 4 then
    return gem.getRandomFromTable({2, 4, 8, 16})
  end
  if lengthOption == 5 then
    return gem.getRandomFromTable({3, 6, 12, 24})
  end
end

----------------
-- 0 = 32x
-- 1 = 16x
-- 2 = 8x
-- 3 = 7x
-- 4 = 6x
-- 5 = 5x
-- 6 = 4x
-- 7 = 3x
-- 8 = 2x
-- 9 = 1/1 dot
----------------
-- 10 = 1/1
-- 11 = 1/2 dot
-- 12 = 1/1 tri
-- 13 = 1/2
-- 14 = 1/4 dot
-- 15 = 1/2 tri
-- 16 = 1/4
-- 17 = 1/8 dot
-- 18 = 1/4 tri
-- 19 = 1/8
-- 20 = 1/16 dot
-- 21 = 1/8 tri
-- 22 = 1/16 - default
-- 23 = 1/32 dot
-- 24 = 1/16 tri
-- 25 = 1/32
-- 26 = 1/64 dot
-- 27 = 1/32 tri
-- 28 = 1/64
----------------
-- 29 = 1/64 tri
----------------
-- default 22
local function getArpResolution(resolutionOption)
  if resolutionOption == 1 then
    if gem.getRandomBoolean(25) then
      return gem.getRandom(28)
    else
      resolutionOption = 2
    end
  end
  local position = resolutionOption + 14 -- resolutionOption will be 2 = even, 3 = dot, 4 = tri, so default starts at 16 (1/4)
  local resMax = 25 -- Max 1/32
  local resOptions = {}
  if gem.getRandomBoolean(25) then
    position = position - 6
    resMax = 28
  end
  -- Create table of resolution options
  while position <= resMax do
    table.insert(resOptions, position) -- insert current position in resolution options table
    print("Insert arp resolution", position)
    position = position + 3 -- increment position
  end
  -- Pick a random index from resolution options table
  local index = gem.getRandom(#resOptions)
  print("Selected arp res options index", index)
  return resOptions[index]
end

local function getArp()
  local arp -- Holds the arpeggiator if found
  local pos = 1 -- Start pos
  local maxPos = 100 -- Max pos search
  repeat
    arp = this.parent.eventProcessors[pos] -- get the event processor at the current position
    pos = pos + 1 -- increment pos
  until type(arp) == "nil" or arp.type == "Arpeggiator" or pos > maxPos
  return arp
end

local function doArpTweaks(resolutionOption, lengthOption, octaveOption, modeOption, pitchOffsetProbability)
  local arp = getArp()

  -- No arp found, just return
  if type(arp) == "nil" or arp.type ~= "Arpeggiator" then
    print("No arp found")
    return
  end

  local arpNumSteps = getArpNumSteps(lengthOption) -- get the number of steps to set for the arpeggiator
  if type(arpNumSteps) == "number" then
    arp:setParameter("NumSteps", arpNumSteps)
  else
    arpNumSteps = arp:getParameter("NumSteps")
  end
  if resolutionOption < 5 then -- 5 = lock - no change
    arp:setParameter("Resolution", getArpResolution(resolutionOption))
  end
  if modeOption < 3 then
    arp:setParameter("Mode", getArpMode(modeOption))
  end
  arp:setParameter("NumStrike", getArpNumStrike())
  arp:setParameter("StepLength", getArpStepLength())
  if octaveOption < 7 then
    arp:setParameter("Octave", getArpOctave(octaveOption))
  end
  arp:setParameter("ArpVelocityBlend", gem.getRandom())
  for i=0,arpNumSteps do
    if i > 0 and gem.getRandomBoolean(30) then
      arp:setParameter("Step"..i.."State", gem.getRandom(0,3)) -- 0-3 def 0
    else
      arp:setParameter("Step"..i.."State", 1) -- 0-3 def 0
    end
    if gem.getRandomBoolean() then
      arp:setParameter("Step"..i.."Size", gem.getRandom()) -- 0-1 def 1
    else
      arp:setParameter("Step"..i.."Size", 1) -- 0-1 def 1
    end
    if gem.getRandomBoolean(30) then
      arp:setParameter("Step"..i.."Level", gem.getRandom()) -- 0-1 def 1
    else
      arp:setParameter("Step"..i.."Level", gem.getRandom(60,100) / 100) -- 0-1 def 1
    end
    if pitchOffsetProbability > 0 then
      if gem.getRandomBoolean(pitchOffsetProbability) then
        if gem.getRandomBoolean(75) then
          arp:setParameter("Step"..i.."Offset", gem.getRandom(-12,12)) -- Random offset within octave
        else
          arp:setParameter("Step"..i.."Offset", gem.getRandom(-48,48)) -- Random offset full range
        end
      else
        arp:setParameter("Step"..i.."Offset", 0) -- No offset
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Widgets
--------------------------------------------------------------------------------

setBackgroundColour(backgroundColour)

local spacing = 20

local panel = widgets.panel({
  backgroundColour = backgroundColour,
  x = 10,
  y = 10,
  width = 700,
  height = 60,
})

local label = panel:Label("Label")
label.text = "Arp Randomizer"
label.tooltip = "Randomizes the settings of the first arpeggiator found at the same level as this script"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {140,25}

local tweakArpResMenu = panel:Menu("TweakArpResolution", {"Auto", "Even", "Dot", "Tri", "Off"})
tweakArpResMenu.selected = 2
tweakArpResMenu.backgroundColour = menuBackgroundColour
tweakArpResMenu.textColour = menuTextColour
tweakArpResMenu.arrowColour = menuArrowColour
tweakArpResMenu.outlineColour = menuOutlineColour
tweakArpResMenu.displayName = "Resolution"
tweakArpResMenu.tooltip = "Set resolution randomization - Use Off to leave the resolution unchanged"
tweakArpResMenu.width = 69
tweakArpResMenu.x = label.x + label.width + spacing

local tweakArpLengthMenu = panel:Menu("TweakArpLength", {"Auto", "Even", "Odd", "2, 4, 8, 16", "3, 6, 12, 24", "Off"})
tweakArpLengthMenu.selected = 4
tweakArpLengthMenu.backgroundColour = menuBackgroundColour
tweakArpLengthMenu.textColour = menuTextColour
tweakArpLengthMenu.arrowColour = menuArrowColour
tweakArpLengthMenu.outlineColour = menuOutlineColour
tweakArpLengthMenu.displayName = "Steps"
tweakArpLengthMenu.tooltip = "Set step randomization - Use Off to leave the step setting unchanged"
tweakArpLengthMenu.width = tweakArpResMenu.width
tweakArpLengthMenu.x = tweakArpResMenu.x + tweakArpResMenu.width + spacing

local tweakArpOctaveMenu = panel:Menu("TweakArpOctave", {"Auto", "+/-1", "+/-2", "+/-4", "+/-5", "+/-6", "Off"})
tweakArpOctaveMenu.selected = 2
tweakArpOctaveMenu.backgroundColour = menuBackgroundColour
tweakArpOctaveMenu.textColour = menuTextColour
tweakArpOctaveMenu.arrowColour = menuArrowColour
tweakArpOctaveMenu.outlineColour = menuOutlineColour
tweakArpOctaveMenu.displayName = "Octave"
tweakArpOctaveMenu.tooltip = "Set max octave randomization - Use Off to leave the octave setting unchanged"
tweakArpOctaveMenu.width = tweakArpResMenu.width
tweakArpOctaveMenu.x = tweakArpLengthMenu.x + tweakArpLengthMenu.width + spacing

local tweakArpModeMenu = panel:Menu("TweakArpModeMenu", {"Auto", "Up/Down", "Off"})
tweakArpModeMenu.backgroundColour = menuBackgroundColour
tweakArpModeMenu.textColour = menuTextColour
tweakArpModeMenu.arrowColour = menuArrowColour
tweakArpModeMenu.outlineColour = menuOutlineColour
tweakArpModeMenu.displayName = "Mode"
tweakArpModeMenu.tooltip = "Set mode randomization - Use Off to leave the mode setting unchanged"
tweakArpModeMenu.width = tweakArpResMenu.width
tweakArpModeMenu.x = tweakArpOctaveMenu.x + tweakArpOctaveMenu.width + spacing

local pitchOffsetProbabilityLabel = panel:Label("PitchOffsetProbabilityLabel")
pitchOffsetProbabilityLabel.text = "Pitch offset"
pitchOffsetProbabilityLabel.tooltip = "Probability that the pitch offset is randomized - zero leaves the pitch offset unchanged"
pitchOffsetProbabilityLabel.width = tweakArpResMenu.width
pitchOffsetProbabilityLabel.x = tweakArpModeMenu.x + tweakArpModeMenu.width + spacing

local pitchOffsetProbability = panel:NumBox("PitchOffsetProbability", 0, 0, 100, true)
pitchOffsetProbability.unit = Unit.Percent
pitchOffsetProbability.showLabel = false
pitchOffsetProbability.displayName = pitchOffsetProbabilityLabel.text
pitchOffsetProbability.tooltip = pitchOffsetProbabilityLabel.tooltip
pitchOffsetProbability.backgroundColour = menuBackgroundColour
pitchOffsetProbability.textColour = menuTextColour
pitchOffsetProbability.width = tweakArpResMenu.width
pitchOffsetProbability.x = pitchOffsetProbabilityLabel.x
pitchOffsetProbability.y = pitchOffsetProbabilityLabel.y + pitchOffsetProbabilityLabel.height + 5

local tweakArpeggiatorButton = panel:Button("TweakArp")
tweakArpeggiatorButton.persistent = false
tweakArpeggiatorButton.alpha = buttonAlpha
tweakArpeggiatorButton.backgroundColourOff = buttonBackgroundColourOff
tweakArpeggiatorButton.backgroundColourOn = buttonBackgroundColourOn
tweakArpeggiatorButton.textColourOff = buttonTextColourOff
tweakArpeggiatorButton.textColourOn = buttonTextColourOn
tweakArpeggiatorButton.displayName = "Randomize"
tweakArpeggiatorButton.tooltip = "Randomize arpeggiator settings - NOTE: this changes the settings of the arpeggiator"
tweakArpeggiatorButton.size = {90,45}
tweakArpeggiatorButton.x = pitchOffsetProbability.x + pitchOffsetProbability.width + spacing
tweakArpeggiatorButton.changed = function(self)
  doArpTweaks(tweakArpResMenu.value, tweakArpLengthMenu.value, tweakArpOctaveMenu.value, tweakArpModeMenu.value, pitchOffsetProbability.value)
end
