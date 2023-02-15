-- modular/probabilityTrigger -- 
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

local widgetNameIndex = 1

local widgetDefaults = {
  panel = nil,
  width = 100,
  height = 20,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 5,
  ySpacing = 5,
}

local widgetColours = {
  backgroundColour = "202020",
  widgetBackgroundColour = "01011F", -- Dark
  menuBackgroundColour = "01011F", -- widgetBackgroundColour
  widgetTextColour = "9f02ACFE", -- Light
  labelTextColour = "black", -- Light
  labelBackgoundColour = "CFFFFE",
  menuArrowColour = "66AEFEFF", -- labelTextColour
  menuOutlineColour = "5f9f02ACFE", -- widgetTextColour
  menuTextColour = "#9f02ACFE",
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

local function setPanel(panel)
  widgetDefaults.panel = panel
end

local function xOffset(val)
  widgetDefaults.xOffset = val
end

local function yOffset(val)
  widgetDefaults.yOffset = val
end

local function xSpacing(val)
  widgetDefaults.xSpacing = val
end

local function ySpacing(val)
  widgetDefaults.ySpacing = val
end

local function widthDefault(val)
  widgetDefaults.width = val
end

local function heightDefault(val)
  widgetDefaults.height = val
end

local function setColour(key, color)
  widgetColours[key] = color
end

local function getColour(key)
  return widgetColours[key]
end

local function posSide(widget)
  return widget.x + widget.width + widgetDefaults.xSpacing
end

local function posUnder(widget)
  return widget.y + widget.height + widgetDefaults.ySpacing
end

local function setWidgetDefaults(settings)
  widgetDefaults.width = getWidgetValue(settings.width, widgetDefaults.width)
  widgetDefaults.height = getWidgetValue(settings.height, widgetDefaults.height)
  widgetDefaults.xOffset = getWidgetValue(settings.xOffset, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getWidgetValue(settings.yOffset, widgetDefaults.yOffset)
  widgetDefaults.xSpacing = getWidgetValue(settings.xSpacing, widgetDefaults.xSpacing)
  widgetDefaults.ySpacing = getWidgetValue(settings.ySpacing, widgetDefaults.ySpacing)
end

local function getWidgetName(name)
  if type(name) == "nil" then
    name = "Widget" .. widgetNameIndex
    widgetNameIndex = widgetNameIndex + 1
  end
  return name
end

local function getWidgetX(options)
  if type(options.x) == "number" then
    return options.x
  end

  if type(options.col) == "number" then
    -- Calculate widget x position
    local col = options.col - 1
    local width = col * widgetDefaults.width
    local xSpacing = col * widgetDefaults.xSpacing
    return widgetDefaults.xOffset + width + xSpacing
  end

  return widgetDefaults.xSpacing
end

local function getWidgetY(options)
  if type(options.y) == "number" then
    return options.y
  end

  if type(options.row) == "number" then
    -- Calculate widget y position
    local row = options.row - 1
    local height = row * widgetDefaults.height
    local ySpacing = row * widgetDefaults.ySpacing
    return widgetDefaults.yOffset + height + ySpacing
  end

  return widgetDefaults.yOffset + widgetDefaults.ySpacing
end

local function getWidgetBounds(options)
  local x = getWidgetX(options)
  local y = getWidgetY(options)
  local w = getWidgetValue(options.width, widgetDefaults.width)
  local h = getWidgetValue(options.height, widgetDefaults.height)
  return {x, y, w, h}
end

local function getWidgetOptions(displayName, default, col, row, options)
  if type(default) == "table" then
    options = default
  else
    if type(options) == "nil" then
      options = {}
    end
    options.default = getWidgetValue(default, options.default)
    options.col = getWidgetValue(col, options.col)
    options.row = getWidgetValue(row, options.row)
  end
  options.name = getWidgetName(options.name)
  options.displayName = getWidgetValue(displayName, options.name)
  options.unit = getWidgetValue(options.unit, Unit.Generic)
  options.tooltip = getWidgetValue(options.tooltip, options.displayName)
  options.integer = getWidgetValue(options.integer, (unit == Unit.Percent))
  options.min = getWidgetValue(options.min, 0)
  options.default = getWidgetValue(options.default, options.min)
  if options.unit == Unit.Percent then
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
  if type(options.showLabel) == "boolean" then
    widget.showLabel = options.showLabel
  end
  if type(options.persistent) == "boolean" then
    widget.persistent = options.persistent
  end
end

local function numBox(displayName, default, col, row, options)
  options = getWidgetOptions(displayName, default, col, row, options)
  local widget = widgetDefaults.panel:NumBox(options.name, options.default, options.min, options.max, options.integer)
  widget.displayName = options.displayName
  widget.tooltip = options.tooltip
  widget.unit = options.unit
  widget.backgroundColour = widgetColours.widgetBackgroundColour
  widget.textColour = widgetColours.widgetTextColour
  widget.bounds = getWidgetBounds(options)
  setOptional(widget, options)
  return widget
end

local function menu(displayName, default, items, col, row, options)
  options = getWidgetOptions(displayName, default, col, row, options)
  local widget = widgetDefaults.panel:Menu(options.name, items)
  widget.selected = options.default
  widget.displayName = options.displayName
  widget.tooltip = options.tooltip
  widget.backgroundColour = widgetColours.menuBackgroundColour
  widget.textColour = widgetColours.menuTextColour
  widget.arrowColour = widgetColours.menuArrowColour
  widget.outlineColour = widgetColours.menuOutlineColour
  widget.bounds = getWidgetBounds(options)
  setOptional(widget, options)
  return widget
end

local function button(displayName, default, col, row, options)
  options = getWidgetOptions(displayName, default, col, row, options)
  local widget = widgetDefaults.panel:OnOffButton(options.name, (options.default == true))
  widget.backgroundColourOff = widgetColours.backgroundColourOff
  widget.backgroundColourOn = widgetColours.backgroundColourOn
  widget.textColourOff = widgetColours.textColourOff
  widget.textColourOn = widgetColours.textColourOn
  widget.displayName = options.displayName
  widget.tooltip = options.tooltip
  widget.unit = options.unit
  widget.bounds = getWidgetBounds(options)
  setOptional(widget, options)
  return widget
end

local function label(displayName, col, row, options)
  options = getWidgetOptions(displayName, nil, col, row, options)
  local widget = widgetDefaults.panel:Label("Label")
  widget.text = options.displayName
  widget.tooltip = options.tooltip
  widget.backgroundColour = widgetColours.labelBackgoundColour
  widget.textColour = widgetColours.labelTextColour
  widget.bounds = getWidgetBounds(options)
  setOptional(widget, options)
  return widget
end

local widgets = {
  setColour = setColour,
  getColour = getColour,
  setPanel = setPanel,
  setWidgetDefaults = setWidgetDefaults,
  xOffset = xOffset,
  yOffset = yOffset,
  xSpacing = xSpacing,
  ySpacing = ySpacing,
  widthDefault = widthDefault,
  heightDefault = heightDefault,
  posSide = posSide,
  posUnder = posUnder,
  button = button,
  label = label,
  menu = menu,
  numBox = numBox,
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

local function quantizeToClosest(beat)
  for i,v in ipairs(resolutionValues) do
    local currentValue = v
    local nextValue = resolutionValues[i+1]
    --print("beat, currentValue, nextValue", beat, currentValue, nextValue)
    if type(nextValue) == "nil" or beat == currentValue then
      --print("beat == currentValue or nextValue == nil", beat, currentValue, nextValue)
      return currentValue
    end
    if beat < currentValue and beat > nextValue then
      local diffCurrent = currentValue - beat
      local diffNext = beat - nextValue
      if diffCurrent < diffNext then
        --print("Return currentValue diffCurrent < diffNext", diffCurrent, diffNext)
        return currentValue
      else
        --print("Return nextValue diffNext < diffCurrent", diffNext, diffCurrent)
        return nextValue
      end
    end
  end
  return beat
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
  
    for _,r in ipairs(resolutionNames) do
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
-- Probability Trigger - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local backgroundColour = "101010"

widgets.setColour('widgetBackgroundColour', backgroundColour)
widgets.setColour('menuBackgroundColour', backgroundColour)

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local channel = 1
local resolutionNames = resolutions.getResolutionNames()
local resolution = 23
local voiceId = nil -- Holds the id of the created note event
local probability = 50
local velocity = 64
local legato = false
local beatFactor = .5
local beatFactorMin = .1
local beatFactorMax = 4
local beatFactorProbability = 50
local beatFactorRandomizationAmount = 0
local quantizeToClosest = true

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function release()
  if type(voiceId) == "userdata" then
    releaseVoice(voiceId)
    voiceId = nil
  end
end

local function sequenceRunner()
  while isPlaying do
    local beat = resolutions.getResolution(resolution)
    if gem.getRandomBoolean(probability) then
      release()
      voiceId = playNote(0, math.floor(gem.randomizeValue(velocity, 1, 127, 3)), -1, nil, channel)
      if gem.getRandomBoolean(beatFactorProbability) then
        local factor = gem.randomizeValue(beatFactor*10, beatFactorMin*10, beatFactorMax*10, beatFactorRandomizationAmount) / 10
        --print("beatFactor, factor", beatFactor, factor)
        beat = beat * factor
        --print("Beat factor was applied")
        if factor ~= 1 and quantizeToClosest then
          --print("quantizeToClosest")
          beat = resolutions.quantizeToClosest(beat)
        end
      end
    end
    waitBeat(resolutions.getPlayDuration(beat))
    if legato == false then
      release()
    end
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
  if isPlaying == false then
    return
  end
  isPlaying = false
  release()
end

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

widgets.xSpacing(0)
widgets.ySpacing(0)

local sequencerPanel = Panel("MotionSequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 0
sequencerPanel.y = 0
sequencerPanel.width = 720
sequencerPanel.height = 30

local notePanel = Panel("Notes")
notePanel.backgroundColour = "black"
notePanel.x = sequencerPanel.x
notePanel.y = widgets.posUnder(sequencerPanel)
notePanel.width = sequencerPanel.width
notePanel.height = 205

--------------------------------------------------------------------------------
-- Probability Sequencer
--------------------------------------------------------------------------------

widgets.setPanel(sequencerPanel)
widgets.xSpacing(5)
widgets.ySpacing(5)

widgets.label("Probability Trigger", 1, 1, {
  tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.widthDefault(100)
widgets.heightDefault(22)
widgets.xOffset((sequencerPanel.width / 2) + 45)
widgets.yOffset(5)

widgets.numBox('Channel', channel, 1, 1, {
  tooltip = "Send note events starting on this channel",
  min = 1,
  max = 16,
  integer = true,
  changed = function(self) channel = self.value end
})

local autoplayButton = widgets.button('Auto Play', true, 2, 1, {
  tooltip = "Play automatically on transport",
})

local playButton = widgets.button('Play', false, 3, 1, {
  changed = function(self)
    if self.value == true then
      startPlaying()
    else
      stopPlaying()
    end
  end
})

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local noteWidgetRowSpacing = 5
local noteWidgetColSpacing = 5

local xySpeedFactor = notePanel:XY('Probability', 'Velocity')
xySpeedFactor.y = noteWidgetRowSpacing
xySpeedFactor.x = noteWidgetColSpacing
xySpeedFactor.width = 480
xySpeedFactor.height = 200

widgets.setPanel(notePanel)
widgets.widthDefault(207)
widgets.xOffset(widgets.posSide(xySpeedFactor) + 10)
widgets.yOffset(10)
widgets.xSpacing(noteWidgetColSpacing)
widgets.ySpacing(noteWidgetRowSpacing)

local resolutionInput = widgets.menu("Quantize", resolution, resolutionNames, 1, 1, {
  tooltip = "Event triggers are quantized to this resolution",
  width = 99,
  height = 48,
  changed = function(self) resolution = self.value end
})

widgets.button("Legato", legato, 1, 1, {
  tooltip = "In legato mode notes are held until the next note is played",
  x = widgets.posSide(resolutionInput) + noteWidgetColSpacing,
  width = resolutionInput.width,
  changed = function(self) legato = self.value end
})

widgets.button("Quantize Closest", quantizeToClosest, 1, 2, {
  tooltip = "Quantize to closest resolution when using beat factor",
  x = widgets.posSide(resolutionInput) + noteWidgetColSpacing,
  width = resolutionInput.width,
  changed = function(self) quantizeToClosest = self.value end
})

widgets.numBox("Beat Factor", beatFactor, 1, 3, {
  min = beatFactorMin,
  max = beatFactorMax,
  tooltip = "Set a factor to multiply the selected beat with",
  changed = function(self) beatFactor = self.value end
})

widgets.numBox("Beat Factor Probability", beatFactorProbability, 1, 4, {
  unit = Unit.Percent,
  tooltip = "Set the probabilty that the beat factor will be used",
  changed = function(self) beatFactorProbability = self.value end
})

widgets.numBox("Beat Factor Randomization", beatFactorRandomizationAmount, 1, 5, {
  unit = Unit.Percent,
  tooltip = "Set the randomization amount for the beat factor",
  changed = function(self) beatFactorRandomizationAmount = self.value end
})

widgets.numBox("Trigger Probability", probability, 1, 6, {
  name = "Probability",
  unit = Unit.Percent,
  integer = false,
  tooltip = "Set the probabilty that an event will be triggered - controlled by the x-axis of the XY controller",
  changed = function(self) probability = self.value end
})

widgets.numBox("Velocity", velocity, 1, 7, {
  name = "Velocity",
  min = 1,
  max = 127,
  tooltip = "Set the velocity amount - controlled by the y-axis of the XY controller",
  changed = function(self) velocity = self.value end
})

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

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
