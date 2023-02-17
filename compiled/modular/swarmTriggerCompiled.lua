-- modular/swarmTrigger -- 
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
  menuHeight = 48,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
  col = 0,
  row = 0,
  cols = 6
}

local backgroundColour = "202020"
local widgetBackgroundColour = "01011F" -- Dark
local menuBackgroundColour = "01011F" -- widgetBackgroundColour
local widgetTextColour = "9f02ACFE" -- Light
local tableBackgroundColour = "191E25"
local sliderColour = "5FB5FF" -- Table slider colour
local labelTextColour = "black" -- Light
local labelBackgoundColour = "CFFFFE"
local menuArrowColour = "66AEFEFF" -- labelTextColour
local menuOutlineColour = "5f9f02ACFE" -- widgetTextColour
local menuTextColour = "9f02ACFE"
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"

local function widgetColours()
  return {
    backgroundColour = backgroundColour,
    widgetBackgroundColour = widgetBackgroundColour,
    menuBackgroundColour = menuBackgroundColour,
    widgetTextColour = widgetTextColour,
    tableBackgroundColour = tableBackgroundColour,
    sliderColour = sliderColour,
    labelTextColour = labelTextColour,
    labelBackgoundColour = labelBackgoundColour,
    menuArrowColour = menuArrowColour,
    menuOutlineColour = menuOutlineColour,
    menuTextColour = menuTextColour,
    backgroundColourOff = backgroundColourOff,
    backgroundColourOn = backgroundColourOn,
    textColourOff = textColourOff,
    textColourOn = textColourOn,
  }
end

local function getWidgetValue(value, default)
  if type(value) == "nil" then
    return default
  end
  return value
end

local function setSection(settings)
  if type(settings) ~= "table" then
    settings = {}
  end
  widgetDefaults.width = getWidgetValue(settings.width, widgetDefaults.width)
  widgetDefaults.height = getWidgetValue(settings.height, widgetDefaults.height)
  widgetDefaults.xOffset = getWidgetValue(settings.xOffset, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getWidgetValue(settings.yOffset, widgetDefaults.yOffset)
  widgetDefaults.xSpacing = getWidgetValue(settings.xSpacing, widgetDefaults.xSpacing)
  widgetDefaults.ySpacing = getWidgetValue(settings.ySpacing, widgetDefaults.ySpacing)
  widgetDefaults.cols = getWidgetValue(settings.cols, widgetDefaults.cols)
  widgetDefaults.col = getWidgetValue(settings.col, 0)
  widgetDefaults.row = getWidgetValue(settings.row, 0)
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
  options.integer = getWidgetValue(options.integer, (options.unit == Unit.Percent))
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
  if type(options.backgroundColour) == "string" then
    widget.backgroundColour = options.backgroundColour
  end
  if type(options.fillStyle) == "string" then
    widget.fillStyle = options.fillStyle
  end
  if type(options.sliderColour) == "string" then
    widget.sliderColour = options.sliderColour
  end
end

local function setPanel(panel)
  widgetDefaults.panel = panel
end

local function getPanel(options)
  return widgetDefaults.panel
end

local widgets = {
  colours = widgetColours,
  backgroundColour = backgroundColour,
  widgetBackgroundColour = widgetBackgroundColour,
  menuBackgroundColour = menuBackgroundColour,
  widgetTextColour = widgetTextColour,
  tableBackgroundColour = tableBackgroundColour,
  sliderColour = sliderColour,
  labelTextColour = labelTextColour,
  labelBackgoundColour = labelBackgoundColour,
  menuArrowColour = menuArrowColour,
  menuOutlineColour = menuOutlineColour,
  menuTextColour = menuTextColour,
  backgroundColourOff = backgroundColourOff,
  backgroundColourOn = backgroundColourOn,
  textColourOff = textColourOff,
  textColourOn = textColourOn,
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
  --setColour = function(key, color) widgetColours[key] = color end,
  --getColour = function(key) return widgetColours[key] end,
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
    widgetDefaults.panel.backgroundColour = backgroundColour
    widgetDefaults.panel.bounds = getWidgetBounds(options, false)
    setOptional(widgetDefaults.panel, options)
    --print("Get panel", widgetDefaults.panel.name)
    return widgetDefaults.panel
  end,
  button = function(displayName, default, options)
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:OnOffButton(options.name, (options.default == true))
    widget.backgroundColourOff = backgroundColourOff
    widget.backgroundColourOn = backgroundColourOn
    widget.textColourOff = textColourOff
    widget.textColourOn = textColourOn
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
    widget.backgroundColour = labelBackgoundColour
    widget.textColour = labelTextColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  menu = function(displayName, default, items, options)
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:Menu(options.name, items)
    widget.selected = options.default
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = menuBackgroundColour
    widget.textColour = menuTextColour
    widget.arrowColour = menuArrowColour
    widget.outlineColour = menuOutlineColour
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
    widget.backgroundColour = widgetBackgroundColour
    widget.textColour = widgetTextColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  table = function(size, default, options)
    options = getWidgetOptions(options, nil, default)
    local widget = widgetDefaults.panel:Table(options.name, size, options.default, options.min, options.max, options.integer)
    widget.fillStyle = "solid"
    widget.backgroundColour = tableBackgroundColour
    widget.sliderColour = sliderColour
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

setBackgroundColour("101010")

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local channel = 1 -- Send trigger on this channel
local voiceId = nil -- Holds the id of the created note event
local velocity = 64
local legato = false
local duration = 250
local durationMin = 3
local durationMax = 10000
local durationRandomization = 50
local quantizeToClosest = true
local swarmProbability = 50
local resolutionNames = resolutions.getResolutionNames()
local resolution = 23

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function release()
  -- Release voice if still active
  if type(voiceId) == "userdata" then
    releaseVoice(voiceId)
    voiceId = nil
  end
end

local function sequencer()
  local swarmActive = false
  local swarmDuration = 0
  while isPlaying do
    local swarmNoteDuration = resolutions.getResolution(resolution)
    if swarmActive or gem.getRandomBoolean(swarmProbability) then
      release() -- Release voice if still active
      voiceId = playNote(0, math.floor(gem.randomizeValue(velocity, 1, 127, 3)), -1, nil, channel)
      if swarmActive == false then
        swarmActive = true
        local maxFactor = 8 -- TODO Param for max factor?
        local swarmDurationBase = swarmNoteDuration * (gem.getRandom(maxFactor))
        local randomizationAmount = 100 -- TODO Param for randomization amount?
        local factor = 2 -- TODO Param?
        swarmDuration = gem.randomizeValue(swarmDurationBase, (swarmDurationBase / factor), (swarmDurationBase * factor), randomizationAmount)
        --print("Start swarm - duration", swarmDuration)
      end
    end
    local playDuration = ms2beat(duration)
    if swarmActive then
      playDuration = swarmNoteDuration
      if gem.getRandomBoolean(durationRandomization) then
        local factor = gem.getRandomFromTable({.125,.25,.5,.75,1.5,2,3,4})
        playDuration = playDuration * factor
      end
    elseif quantizeToClosest then
      playDuration = resolutions.quantizeToClosest(playDuration)
    end
    playDuration = resolutions.getPlayDuration(playDuration)
    waitBeat(playDuration)
    if swarmActive then
      swarmDuration = gem.inc(swarmDuration, -playDuration)
      --print("Swarm active - duration", swarmDuration)
      if swarmDuration < 0 then
        --print("End swarm - duration", swarmDuration)
        swarmActive = false
        swarmDuration = 0
      end
    end
    if legato == false or swarmActive == false then
      -- Release if legato is off, or swarm is finished
      release()
    end
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  run(sequencer)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  release()
end

--------------------------------------------------------------------------------
-- Header
--------------------------------------------------------------------------------

widgets.panel({
  width = 720,
  height = 30,
})

widgets.setSection({
  xSpacing = 5,
  ySpacing = 5,
  width = 100,
  height = 22,
  xOffset = (widgets.getPanel().width / 2) + 45,
  yOffset = 5,
})

widgets.labelBackgoundColour = "red"

widgets.label("Swarm Trigger", {
  tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to",
  width = widgets.getPanel().width,
  x = 0, y = 0, height = 30,
  alpha = 0.5, fontSize = 22,
  increment = false,
})

widgets.numBox('Channel', channel, {
  tooltip = "Send note events starting on this channel",
  min = 1, max = 16, integer = true,
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
-- Options
--------------------------------------------------------------------------------

widgets.setSection({
  xSpacing = 0,
  ySpacing = 0,
})

widgets.panel({
  x = widgets.getPanel().x,
  y = widgets.posUnder(widgets.getPanel()),
  width = widgets.getPanel().width,
  height = 210,
})

local noteWidgetColSpacing = 5
local noteWidgetRowSpacing = 5

local xySpeedFactor = widgets.getPanel():XY('Duration', 'Probability')
xySpeedFactor.x = noteWidgetColSpacing
xySpeedFactor.y = noteWidgetRowSpacing
xySpeedFactor.width = 480
xySpeedFactor.height = 200

widgets.setSection({
  width = 210,
  xOffset = widgets.posSide(xySpeedFactor) + 12,
  yOffset = 15,
  xSpacing = noteWidgetColSpacing,
  ySpacing = noteWidgetRowSpacing,
  cols = 1,
})

widgets.menu("Swarm Base", resolution, resolutionNames, {
  tooltip = "Set the base resolution of the swarm",
  changed = function(self) resolution = self.value end
})

widgets.col()

widgets.numBox("Duration Randomization", durationRandomization, {
  unit = Unit.Percent,
  tooltip = "Set the randomization amount for the duration",
  changed = function(self) durationRandomization = self.value end
})

widgets.numBox("Space", duration, {
  name = "Duration",
  tooltip = "Set the duration between swarms - controlled by the x-axis of the XY controller",
  unit = Unit.MilliSeconds,
  min = durationMin, max = durationMax, integer = false,
  changed = function(self) duration = self.value end
})

widgets.numBox("Swarm Probability", swarmProbability, {
  name = "Probability",
  unit = Unit.Percent,
  integer = false,
  tooltip = "Set the probability that a swarm will be triggered - controlled by the y-axis of the XY controller",
  changed = function(self) swarmProbability = self.value end
})

local q = widgets.button("Quantize Closest", quantizeToClosest, {
  tooltip = "Quantize the space between swarms to the closest 'known' resolution",
  width = (210 / 2) - 3,
  increment = false,
  changed = function(self) quantizeToClosest = self.value end
})

widgets.button("Legato", legato, {
  tooltip = "In legato mode notes are held until the next note is played",
  x = widgets.posSide(q) + 2,
  width = q.width,
  changed = function(self) legato = self.value end
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
