-- modular/horizontalMotionSequencerInput -- 
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
      maxNote = 127
    end
    rootNote = math.max(0, rootNote)
    maxNote = math.min(127, maxNote)
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
-- Methods for working with shapes
--------------------------------------------------------------------------------

-- Keep in sync with function names
local shapeNames = {
  "Ramp Up",
  "Ramp Down",
  "Sine",
  "Triangle",
  "Triangle (Off Phs)",
  "LoFi Triangle",
  "Sqr/Tri",
  "Dome",
  "Dome Small",
  "Saw",
  "HPF Saw",
  "Analog Saw",
  "Fltr Sqr", 
  "Organ-Ish",
  "Tangent",
  "Triple Sine",
  "Soft Sine", -- TODO Rename?
  "Sweet Sine",
  "Even",
  "Odd",
  "Zero",
  "Min",
  "Max",
  "Chaos To Sine",
  "Saw/Sin Reveal",
  "PWM 50 to 100",
  "Triple-Sin Window",
  "Taffy",
  "Brassy",
  "HPF-Sqr To Sqr",
  "Wacky",
  "Sine To Noise",
  "Window-y SQR Sync",
  "Random",
  --"Test Shape",
}

local shapeFunctions = {
  "rampUp",
  "rampDown",
  "sine",
  "triangle",
  "triangleOffPhase",
  "lofiTriangle",
  "squareTri",
  "dome",
  "domeSmall",
  "sawInPhase",
  "hpfSaw",
  "sawAnalog",
  "filteredSquare", 
  "organIsh",
  "tangent",
  "tripleSin",
  "softSine",
  "sweetSine",
  "even",
  "odd",
  "zero",
  "min",
  "max",
  "chaosToSine",
  "sawSinReveal",
  "pwm50to100",
  "tripleSinWindow",
  "taffy",
  "brassy",
  "hpfSqrToSqr",
  "wacky",
  "sinToNoise",
  "windowYSqr",
  "random",
  "testShape",
}

-- Holds the shape definitions
-- x = current time-value getting plotted, from -1.0 to 1.0 OR 0.0 to 1.0 (same as (x+1)/2) - depending on stepRange=1|2
-- z = current table number, from -1.0 to 1.0
-- i = current index
local shapes = {
  triangleShaper = function(x, z)
    return math.min(2+2*x, math.abs((x-0.5)*2)-1) * z -- Unique
  end,
  sineShaper = function(x, z) return math.cos(x) * z end,
  sawInPhase = function(x, z) return (gem.sign(x)-x) * z end,
  sinToNoise = function(x, z, i) return 2*gem.avg({math.sin(z*x*math.pi),(1-z)*gem.getRandom()}) end,
  wacky = function(x, z, i) return math.sin(((x)+1)^(z-1)*math.pi) end,
  hpfSqrToSqr = function(x, z, i)
    if x < 0 then
      return math.sin((z*0.5)*math.pi)^(x+1)
    end
    return -math.sin((z*0.5)*math.pi)^x
  end,
  windowYSqr = function(x, z, i)
    local v = 1
    if math.abs(x) > 0.5 then
      v = (1-math.abs(x))*2
    end
    return v * math.min(1, math.max(-1,8*math.sin((z+0.02)*x*math.pi*32)))
  end,
  filteredSquare = function(x, z, i)
    return (1.2*math.sin(x*math.pi)+0.31*math.sin(x*math.pi*3)+0.11*math.sin(x*math.pi*5)+0.033*math.sin(x*math.pi*7)) * z
  end,
  organIsh = function(x, z)
    return (math.sin(x*math.pi)+(0.16*(math.sin(2*x*math.pi)+math.sin(3*x*math.pi)+math.sin(4*x*math.pi)))) * z
  end,
  sawAnalog = function(x, z)
    return (2.001 * (math.sin(x * 0.7905) - 0.5)) * z
  end,
  dome = function(x, z)
    return (2 * (math.sin(x * 1.5705) - 0.5)) * z
  end,
  brassy = function(x, z, i)
    return math.sin(math.pi*gem.sign(x)*(math.abs(x)^(((1-z)+0.1)*math.pi*math.pi)))
  end,
  taffy = function(x, z, i)
    return math.sin(x*math.pi*2)*math.cos(x*math.pi)*math.cos(z*math.pi*(math.abs((x*2)^3)-1)*math.pi)
  end,
  random = function(x, z)
    return ((gem.getRandom() * 2) - 1) * z
  end,
  tripleSinWindow = function(x, z, i)
    return math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x))
  end,
  pwm50to100 = function(x, z, i)
    if x > z then
      return 1
    end
    return -1
  end,
  chaosToSine = function(x, z, i)
    return math.sin(math.pi*z*z*32*math.log(x+1))
  end,
  sawSinReveal = function(x, z, i)
    if x + 1 > z * 2 then
      return x
    end
    return math.sin(x * math.pi)
  end,
  domeSmall = function(x, z)
    return (-1-1.275*math.sin(x*math.pi)) * z
  end,
  minMaxZero = function(x, z)
    return z
  end,
  oddAndEven = function(x, z, i)
    x = 1
    if i % 2 == 0 then
      x = -1
    end
    return x * z
  end,
  tangent = function(x, z)
    return math.tan(x * math.pi) * z
  end,
}

local function getDefaultShapeOptions()
  return {
    z = 1,
    stepRange = 2,
    phase = -1,
    factor = 1,
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
    stepRange = getValueOrDefault(overrides.stepRange, defaultShapeOptions.stepRange),
    phase = getValueOrDefault(overrides.phase, defaultShapeOptions.phase),
    factor = getValueOrDefault(overrides.factor, defaultShapeOptions.factor),
    z = getValueOrDefault(overrides.z, defaultShapeOptions.z),
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
    max = #shapeNames
  end

  local res = {}

  for _,r in ipairs(shapeNames) do
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
end

local function getShapeFunctions()
  return shapeFunctions
end

local function getShapeFunction(i)
  return shapeFunctions[i]
end

local function getShapeBounds(bounds, options)
  local shapeBounds = {}
  if type(bounds) == "nil" then
    bounds = {}
  end
  shapeBounds.min = getValueOrDefault(bounds.min, -1) -- x-azis max value
  shapeBounds.max = getValueOrDefault(bounds.max, 1) -- x-azis min value
  shapeBounds.length = getValueOrDefault(bounds.length, 128) -- y-axis steps
  shapeBounds.unipolar = shapeBounds.min == 0
  shapeBounds.changePerStep = gem.getChangePerStep(options.stepRange, shapeBounds.length)
  return shapeBounds
end

local function createShape(shapeBounds, options, shapeFunc, shapeTemplate)
  options = getShapeTemplate(options, shapeTemplate)
  shapeBounds = getShapeBounds(shapeBounds, options)
  if type(shapeFunc) == "string" then
    shapeFunc = shapes[shapeFunc]
  end
  local shape = {}
  --print("Create shape, stepRange, phase, factor", options.stepRange, options.phase, options.factor)
  --print("shapeBounds.min, shapeBounds.max, shapeBounds.length, shapeBounds.changePerStep", shapeBounds.min, shapeBounds.max, shapeBounds.length, shapeBounds.changePerStep)
  for i=1,shapeBounds.length do
    local x = options.factor * ((shapeBounds.changePerStep * (i-1)) + options.phase)
    local z = options.z
    local value = shapeFunc(x, z, i, shapeBounds.min, shapeBounds.max)
    if shapeBounds.unipolar then
      value = ((shapeBounds.max * value) + shapeBounds.max) / 2
    else
      value = shapeBounds.max * value
    end
    --print("step, value, x", i, value, x)
    table.insert(shape, math.max(shapeBounds.min, math.min(shapeBounds.max, value)))
    --table.insert(shape, value)
  end
  return shape, options
end

local function testShape(shapeTable, options)
  local shapeFunc = function(x, z, i)
    return x
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function sweetSine(shapeTable, options)
  local shapeFunc = function(x, z)
    return 0.5*(math.cos(x*math.pi/2)*((math.sin((x)*math.pi)+(1-z)*(math.sin(z*((x*x)^z)*math.pi*32))))) -- Unique
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function softSine(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.sin(x*math.pi*(2+(62*z*z*z)))*math.sin(x*math.pi) -- Unique
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function tripleSin(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x)) -- Unique
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function hpfSaw(shapeTable, options)
  local shapeFunc = function(x, z)
    return (x-(0.635*math.sin(x*math.pi))) * z -- Unique
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function squareTri(shapeTable, options)
  local shapeFunc = function(x, z)
    return (-1*(gem.sign(x)*0.5)+(math.abs(x)-0.5)) * z -- Unique
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function lofiTriangle(shapeTable, options)
  local shapeFunc = function(x, z)
    return ((gem.round(16*math.abs(x))/8.0)-1) * z -- Unique
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function getShapeWidgets(width, showLabel)
  -- Widgets for controlling shape
  if type(width) == "nil" then
    width = 30
  end
  local shapeOptions = getShapeOptions()
  return {
    stepRange = widgets.numBox("Step Range", shapeOptions.stepRange, {
      name = "ShapeStepRange",
      tooltip = "Set step range for the shape. Mostly affects polarity of the shape.",
      width = width,
      showLabel = showLabel == true,
      min = 0,
      max = 4,
    }),
    factor = widgets.numBox("Shape Factor", shapeOptions.factor, {
      name = "ShapeFactor",
      tooltip = "Set the factor (multiplier) applied to the value of each step.",
      width = width,
      showLabel = showLabel == true,
      min = -8,
      max = 8,
    }),
    phase = widgets.numBox("Shape Phase", shapeOptions.phase, {
      name = "ShapePhase",
      tooltip = "Set the phase applied to the shape (move left/right).",
      width = width,
      showLabel = showLabel == true,
      min = -1,
      max = 1,
    }),
    z = widgets.numBox("Shape Morph", shapeOptions.z, {
      name = "ShapeMorph",
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
  getShapeNames = getShapeNames,
  getShapeFunctions = getShapeFunctions,
  getShapeFunction = getShapeFunction,
  getShapeOptions = getShapeOptions,
  hpfSaw = hpfSaw,
  squareTri = squareTri,
  lofiTriangle = lofiTriangle,
  testShape = testShape,
  sweetSine = sweetSine,
  softSine = softSine,
  tripleSin = tripleSin,
  tangent = function(t,o) return createShape(t, o, 'tangent') end,
  even = function(t,o) return createShape(t, o, 'oddAndEven', {z = -1}) end,
  odd = function(t,o) return createShape(t, o, 'oddAndEven') end,
  min = function(t,o) return createShape(t, o, 'minMaxZero', {z = -1}) end,
  max = function(t,o) return createShape(t, o, 'minMaxZero') end,
  zero = function(t,o) return createShape(t, o, 'minMaxZero', {z = 0}) end,
  domeSmall = function(t,o) return createShape(t, o, 'domeSmall', {stepRange = 1}) end,
  sawSinReveal = function(t,o) return createShape(t, o, 'sawSinReveal', {phase = -1}) end,
  dome = function(t,o) return createShape(t, o, 'dome', {phase = 0}) end,
  sawAnalog = function(t,o) return createShape(t, o, 'sawAnalog', {phase = 0}) end,
  sawInPhase = function(t,o) return createShape(t, o, 'sawInPhase') end,
  organIsh = function(t,o) return createShape(t, o, 'organIsh') end,
  triangle = function(t,o) return createShape(t, o, 'triangleShaper') end,
  rampUp = function(t,o) return createShape(t, o, 'triangleShaper', {stepRange = 1, phase = 0.5}) end,
  rampDown = function(t,o) return createShape(t, o, 'triangleShaper', {stepRange = 1, phase = -0.5}) end,
  triangleOffPhase = function(t,o) return createShape(t, o, 'triangleShaper', {phase = -0.5}) end,
  sine = function(t,o) return createShape(t, o, 'sineShaper', {phase = -0.5, factor = math.pi}) end,
  chaosToSine = function(t,o) return createShape(t, o, 'chaosToSine') end,
  pwm50to100 = function(t,o) return createShape(t, o, 'pwm50to100') end,
  tripleSinWindow = function(t,o) return createShape(t, o, 'tripleSinWindow', {z = 0}) end,
  taffy = function(t,o) return createShape(t, o, 'taffy', {z = 0}) end,
  brassy = function(t,o) return createShape(t, o, 'brassy', {z = 0}) end,
  hpfSqrToSqr = function(t,o) return createShape(t, o, 'hpfSqrToSqr', {z = 0.01}) end,
  wacky = function(t,o) return createShape(t, o, 'wacky', {z = 0.84}) end,
  sinToNoise = function(t,o) return createShape(t, o, 'sinToNoise') end,
  filteredSquare = function(t,o) return createShape(t, o, 'filteredSquare') end,
  windowYSqr = function(t,o) return createShape(t, o, 'windowYSqr', {z = 0}) end,
  random = function(t,o) return createShape(t, o, 'random') end,
}

--------------------------------------------------------------------------------
-- Common functions for processors using table motion
--------------------------------------------------------------------------------

local directionStartModes = {"Up", "Down", "Even Up", "Even Down", "Odd Up", "Odd Down", "Random"}
local speedTypes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Random"}
local startModes = shapes.getShapeNames({"Keep State"})
local movementTypes = {"Evolve", "Morph", "Manual"} -- TODO Implement
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local morphSeqIndex = 0 -- Holds the unique id for the morphing sequencer
local movingCells = {}
local isTableMotionActive = false

local motionOptions = {
  factor = 2,
  factorMin = 0,
  factorMax = 10,
  moveSpeed = 25,
  moveSpeedMin = 5,
  moveSpeedMax = 60000,
  speedType = speedTypes[1],
  startMode = startModes[1],
  directionStartMode = directionStartModes[1],
  speedRandomizationAmount = 0,
  tableLength = 32,
  useMorph = false,
  manualMode = false,
}

local shapeOptions = {
    z = 1,
    stepRange = 2,
    phase = -1,
    factor = 1,
}

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

local function setStartMode(theTable, options, stateFunction)
  -- Reset table according to start mode (unless keep state is selected)
  if motionOptions.startMode ~= "Keep State" then
    local values = {}
    local shapeIndex = gem.getIndexFromValue(motionOptions.startMode, shapes.getShapeNames())
    local shapeFunc = shapes.getShapeFunction(shapeIndex)
    --print("Calling shapeFunc", shapeFunc)
    values, shapeOptions = shapes[shapeFunc](theTable, options)
    for i,v in ipairs(values) do
      local value = v
      if shapeFunc == "sine" then
        -- Sine prefers round
        value = gem.round(v)
      elseif v > 1 then
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
  end
  return shapeOptions
end

local function getWaitDuration()
  return gem.randomizeValue(motionOptions.moveSpeed, motionOptions.moveSpeedMin, motionOptions.moveSpeedMax, motionOptions.speedRandomizationAmount)
end

local function advanceValue(theTable, value, min, max, direction)
  local valueRange = theTable.max - theTable.min
  local changeFactor = max - min
  local changePerStep = gem.getChangePerStep(changeFactor, valueRange)

  if direction < 0 then
    changePerStep = -changePerStep
  end

  value = gem.inc(value, changePerStep)
  if value > max then
    direction = -1
    value = max
  elseif value < min then
    direction = 1
    value = min
  end
  return value, direction
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
  while isTableMotionActive and motionOptions.useMorph and morphSeqIndex == uniqueId do
    morphSettings.z.value, morphSettings.z.direction = advanceValue(theTable, morphSettings.z.value, morphSettings.z.min, morphSettings.z.max, morphSettings.z.direction)
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
      morphSettings.phase.value, morphSettings.phase.direction = advanceValue(theTable, morphSettings.phase.value, min, max, morphSettings.phase.direction)
    end
    local options = {
      z = morphSettings.z.value,
      stepRange = shapeOptions.stepRange,
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
  if motionOptions.manualMode then
    print("In manualMode")
    return -- Nothing needs to be done in manual mode
  elseif motionOptions.useMorph then
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
  startMoving = startMoving,
  isMoving = function(m) return isTableMotionActive == true end,
  isNotMoving = function(m) return isTableMotionActive == false end,
  setMoving = function(m) isTableMotionActive = m ~= false end,
  resetUniqueIndex = function() uniqueIndex = 1 end,
  getShapeWidgets = getShapeWidgets,
  getStartDirection = getStartDirection,
  moveTable = moveTable,
  advanceValue = advanceValue,
  getWaitDuration = getWaitDuration,
  setStartMode = setStartMode,
  setTableZero = setTableZero,
  directionStartModes = directionStartModes,
  speedTypes = speedTypes,
  startModes = startModes,
  options = motionOptions,
  shapeOptions = shapeOptions,
}

----------------------------------------------------------------------------------
-- Motion Sequencer - Listens for incoming note events (rythm) on note number 0
----------------------------------------------------------------------------------

local backgroundColour = "606060"
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local baseNote = 60 -- Option
local tableRange = 16
local octaveRange = 2 -- Option
local bipolar = true -- Option
local scalePos = 0
local activationMode = 1
local activationModes = {"Max:On,Min:Off", "Max:Toggle", "Min:Toggle", "Zero:Toggle", "Min:On,Max:Off", "Min/Max:Toggle"}
local playModes = {"Right", "Left", "Drunk", "Random"}
local playMode = playModes[1]
local positionTable
local motionTable
local scaleNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinitionIndex = #scaleNames
local activeScale = {} -- Holds the active scale
local noteState = {} -- Holds the state (on/off) for notes in the scale
local currentValue = {} -- Holds the current table value to check for changes
local forward = false
local channel = 0

shapeWidgets = {} -- Holds the widgets for controlling shape -- MUST BE GLOBAL

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function updateNoteState(i, value)
  -- Only toggle if value is changed
  local valueHasChanged = value ~= currentValue[i]
  if valueHasChanged then
    if activationMode == 1 and (value == motionTable.min or value == motionTable.max) then
      noteState[i] = value == motionTable.max
    elseif activationMode == 2 and value == motionTable.max then
      noteState[i] = noteState[i] == false
    elseif activationMode == 3 and value == motionTable.min then
      noteState[i] = noteState[i] == false
    elseif activationMode == 4 and value == 0 then
      noteState[i] = noteState[i] == false
    elseif activationMode == 5 and (value == motionTable.min or value == motionTable.max) then
      noteState[i] = value == motionTable.min
    elseif activationMode == 6 and (value == motionTable.min or value == motionTable.max) then
      noteState[i] = noteState[i] == false
    end
  end
  -- Update the current value
  currentValue[i] = value
  if noteState[i] then
    positionTable:setValue(i, 1)
  else
    positionTable:setValue(i, 0)
  end
end

local function resetTableValues(options)
  scalePos = 0

  -- Reset position
  tableMotion.setTableZero(positionTable)

  -- TODO Check that shape adjustments are saved correctly!

  -- Set start mode
  options = tableMotion.setStartMode(motionTable, options, updateNoteState)

  -- Update widgets with values from the shape
  local callChanged = type(options) == "table"
  shapeWidgets.stepRange:setValue(options.stepRange, callChanged)
  shapeWidgets.phase:setValue(options.phase, callChanged)
  shapeWidgets.factor:setValue(options.factor, callChanged)
  shapeWidgets.z:setValue(options.z, callChanged)
end

local function startMoving()
  tableMotion.startMoving(motionTable, updateNoteState)
end

local function setRange()
  tableMotion.setRange(motionTable, tableRange, bipolar)
  resetTableValues(tableMotion.shapeOptions)
end

local function setScaleTable()
  local scaleDefinition = scaleDefinitions[scaleDefinitionIndex]
  local startNote = baseNote
  if bipolar then
    startNote = startNote - (octaveRange * 12)
  end
  local maxNote = baseNote + (octaveRange * 12)
  activeScale = scales.createScale(scaleDefinition, startNote, maxNote)

  -- Set table length according to the number of notes in the selected scale
  tableMotion.options.tableLength = #activeScale
  positionTable.length = tableMotion.options.tableLength
  motionTable.length = tableMotion.options.tableLength

  -- Reset table values and set start shape
  resetTableValues(tableMotion.shapeOptions)

  -- Reset note state
  noteState = {}
  currentValue = {}
  for i,v in ipairs(activeScale) do
    table.insert(noteState, false) -- Notes start deactivated
    table.insert(currentValue, nil) -- Set initial value
    updateNoteState(i, motionTable:getValue(i))
  end

  startMoving()
end

local function getNote()
  -- Find all active positions
  local activePositions = {}
  for i,v in ipairs(noteState) do
    if v then
      table.insert(activePositions, i)
    end
  end
  --print("activePositions", #activePositions)  
  --print("noteState", #noteState)

  if playMode == "Random" then
    -- Get a random position from the active positions
    scalePos = gem.getRandomFromTable(activePositions)
  else
    -- Walk up or down the scale
    if #activePositions > 1 then
      local increment = 1
      local resetAt = #activeScale
      local resetTo = 1
      if playMode == "Left" or (playMode == "Drunk" and gem.getRandomBoolean()) then
        increment = -1
        resetAt = 1
        resetTo = #activeScale
      end
      local counter = 1
      repeat
        scalePos = gem.inc(scalePos, increment, resetAt, resetTo)
        counter = gem.inc(counter)
      until noteState[scalePos] or counter > #activeScale
      if noteState[scalePos] == false then
        scalePos = nil
      end
    elseif #activePositions == 1 then
      scalePos = activePositions[1]
    else
      scalePos = nil
    end
  end

  --print("type(scalePos)", type(scalePos), scalePos)

  -- No active notes
  if type(scalePos) == "nil" then
    scalePos = 0 -- Reset if no note was found
    return
  end

  -- Set in position table
  for i=1,positionTable.length do
    local val = 0
    if noteState[i] then
      val = 1
    end
    if i == scalePos then
      val = 2
    end
    positionTable:setValue(i, val)
  end

  -- Get note from scale
  return activeScale[scalePos]
end

local function startPlaying()
  if tableMotion.isMoving() then
    return
  end
  tableMotion.setMoving()
  setScaleTable()
  startMoving()
end

local function stopPlaying()
  if tableMotion.isNotMoving() then
    return
  end
  tableMotion.setMoving(false)
  resetTableValues(tableMotion.shapeOptions)
end

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

local sequencerPanel = widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Horizontal Motion Sequencer", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 90,
  x = 348,
  y = 5,
  xSpacing = 5,
  ySpacing = 5,
})

widgets.label("Play Direction", {
  width = 81,
  backgroundColour = "transparent",
})

widgets.menu("Play Mode", playModes, {
  tooltip = "Set the play direction for the sequencer",
  showLabel = false,
  changed = function(self) playMode = self.selectedText end
})

widgets.button("Forward", forward, {
  tooltip = "Forward triggers (note=0 events) to the next processor",
  changed = function(self) forward = self.value end,
})

local channelInput = widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

widgets.setSection({
  width = sequencerPanel.width,
  x = 0,
  y = 0,
  xSpacing = 0,
  ySpacing = 0,
})

local settingsPanel = widgets.panel({
  backgroundColour = backgroundColour,
  y = widgets.posUnder(sequencerPanel),
  height = 280,
})

positionTable = widgets.table("Position", 0, tableMotion.options.tableLength, {
  width = settingsPanel.width - 112,
  max = 2,
  integer = true,
  enabled = false,
  persistent = false,
  sliderColour = "green",
  backgroundColour = "CFFFFE",
  height = 10,
})

widgets.setSection({
  width = positionTable.width,
  height = 160,
  y = widgets.posUnder(positionTable),
})

motionTable = widgets.table("Motion", 0, tableMotion.options.tableLength, {
  tooltip = "Events are triggered when the value hits max or min",
  showPopupDisplay = true,
  backgroundColour = "191E25",
  min = -tableRange,
  max = tableRange,
  integer = true,
})

local noteWidgetHeight = 20
local noteWidgetWidth = 138
local noteWidgetRowSpacing = 6
local noteWidgetCellSpacing = 6
local firstRowY = motionTable.y + motionTable.height + 6

widgets.setSection({
  width = noteWidgetWidth,
  height = noteWidgetHeight,
  menuHeight = 45,
  x = 10,
  y = firstRowY,
  xSpacing = noteWidgetCellSpacing,
  ySpacing = noteWidgetRowSpacing,
  cols = 9
})

widgets.menu("Speed Type", tableMotion.speedTypes, {
  tooltip = "The speed type works with the speed factor to control speed variations across the table. Ramp Up means fast -> slower, Triangle means slower in the center.",
  width = 81,
  changed = function(self) tableMotion.options.speedType = self.selectedText end
})

local startShape = widgets.menu("Start Shape", 3, tableMotion.startModes, {
  tooltip = "Set how the table will look when starting.",
  width = 81,
  changed = function(self)
    tableMotion.options.startMode = self.selectedText
    resetTableValues() -- Load a "fresh" shape without adjustments when selecting a shape
  end
})

widgets.menu("Start Direction", tableMotion.directionStartModes, {
  tooltip = "Select start direction for the bars",
  width = 81,
  changed = function(self) tableMotion.options.directionStartMode = self.selectedText end
})

local activationModeMenu = widgets.menu("Activation Mode", activationMode, activationModes, {
  tooltip = "Activation mode controls when notes in the table are activated and deactivated.",
  width = 105,
  changed = function(self) activationMode = self.value end
})

local moveSpeedInput = widgets.numBox("Motion Speed", tableMotion.options.moveSpeed, {
  x = 470,
  name = "MoveSpeed",
  mapper = Mapper.Quartic,
  tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller",
  min = tableMotion.options.moveSpeedMin,
  max = tableMotion.options.moveSpeedMax,
  unit = Unit.MilliSeconds,
  changed = function(self) tableMotion.options.moveSpeed = self.value end
})

widgets.row()

widgets.button("Bipolar", bipolar, {
  tooltip = "Toggle table bipolar mode",
  x = widgets.posSide(activationModeMenu),
  width = 81,
  changed = function(self)
    bipolar = self.value
    setRange()
    setScaleTable()
    startMoving()
  end
})

widgets.numBox("Speed Factor", tableMotion.options.factor, {
  name = "Factor",
  mapper = Mapper.Cubic,
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. When using morph, this controls phase amount. Controlled by the Y-axis on the XY controller",
  x = moveSpeedInput.x,
  min = tableMotion.options.factorMin,
  max = tableMotion.options.factorMax,
  changed = function(self) tableMotion.options.factor = self.value end
})

widgets.row()

widgets.numBox("Range", tableRange, {
  width = 81,
  min = 8,
  max = 128,
  integer = true,
  tooltip = "Set the table range - high range = fewer events, low range = more events",
  changed = function(self)
    tableRange = self.value
    setRange()
    startMoving()
  end
})

-- TODO Add a menu for automatic reset options?
widgets.button("Reset", false, {
  tooltip = "Reset the start shape and direction",
  width = 81,
  changed = function(self)
    resetTableValues(tableMotion.shapeOptions)
    setScaleTable()
    startMoving()
    self.value = false
  end
})

local noteInput = widgets.numBox("Base Note", baseNote, {
  width = 33,
  unit = Unit.MidiKey,
  showLabel = false,
  tooltip = "Set the root note",
  changed = function(self)
    baseNote = self.value
    setScaleTable()
  end
})

widgets.menu("Scale", #scaleNames, scaleNames, {
  width = 117,
  showLabel = false,
  changed = function(self)
    scaleDefinitionIndex = self.value
    setScaleTable()
  end
})

widgets.numBox("Octave Range", octaveRange, {
  width = 117,
  tooltip = "Set the octave range",
  min = 1,
  max = 4,
  integer = true,
  changed = function(self)
    octaveRange = self.value
    setScaleTable()
  end
})

widgets.numBox("Speed Rand", tableMotion.options.speedRandomizationAmount, {
  tooltip = "Set the radomization amount applied to speed",
  x = moveSpeedInput.x,
  unit = Unit.Percent,
  changed = function(self) tableMotion.options.speedRandomizationAmount = self.value end
})

widgets.row()

shapeWidgets = shapes.getWidgets(109, true)

shapeWidgets.stepRange.changed = function(self)
  tableMotion.shapeOptions.stepRange = self.value
  resetTableValues(tableMotion.shapeOptions)
  setScaleTable()
  startMoving()
end

shapeWidgets.phase.changed = function(self)
  tableMotion.shapeOptions.phase = self.value
  resetTableValues(tableMotion.shapeOptions)
  setScaleTable()
  startMoving()
end

shapeWidgets.factor.changed = function(self)
  tableMotion.shapeOptions.factor = self.value
  resetTableValues(tableMotion.shapeOptions)
  setScaleTable()
  startMoving()
end

shapeWidgets.z.changed = function(self)
  tableMotion.shapeOptions.z = self.value
  resetTableValues(tableMotion.shapeOptions)
  setScaleTable()
  startMoving()
end

local xyShapeMorph = widgets.getPanel():XY('ShapePhase', 'ShapeMorph')
xyShapeMorph.y = motionTable.y
xyShapeMorph.x = widgets.posSide(moveSpeedInput)
xyShapeMorph.width = 100
xyShapeMorph.height = motionTable.height / 2

local xySpeedFactor = widgets.getPanel():XY('MoveSpeed', 'Factor')
xySpeedFactor.y = widgets.posUnder(xyShapeMorph)
xySpeedFactor.x = xyShapeMorph.x
xySpeedFactor.width = xyShapeMorph.width
xySpeedFactor.height = (motionTable.height / 2) - 24

local morphButton = widgets.button("Morph", tableMotion.options.useMorph, {
  tooltip = "When active, use the shape morph for creating motion",
  y = widgets.posUnder(xySpeedFactor),
  x = xyShapeMorph.x,
  width = xyShapeMorph.width / 2,
  changed = function(self)
    tableMotion.options.useMorph = self.value
    startMoving()
  end
})

widgets.button("Manual", tableMotion.options.manualMode, {
  tooltip = "When active, use the shape morph for creating motion",
  x = xyShapeMorph.x + (xyShapeMorph.width / 2),
  y = morphButton.y,
  width = xyShapeMorph.width / 2,
  changed = function(self)
    tableMotion.options.manualMode = self.value
    startMoving()
  end
})

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  tableMotion.resetUniqueIndex()
  setScaleTable()
  startShape:changed()
end

function onNote(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    startPlaying()
    modular.handleTrigger(e, getNote())
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
  if start == true then
    startPlaying()
  else
    stopPlaying()
  end
end
