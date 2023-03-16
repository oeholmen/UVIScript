--------------------------------------------------------------------------------
-- Swarm Trigger - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
local shapes = require "includes.shapes"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

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
local durationMax = 30000
local shapeWidgets = {}
local shapeOptions = shapes.getShapeOptions()
local swarmLengthInput
local swarmLength = 32
local lengthRandomizationAmount = 0
local lengthRandomizationInput
local space = 0
local spaceRandomizationAmount = 25
local quantizeToClosest = false
local swarmProbability = 100
local resolutionNames = resolutions.getResolutionNames()
local resolutionValues = resolutions.getResolutions()
local swarmResolutions = {}
local resolution = 23
local resolutionMin = #resolutionNames
local positionTable
local sequencerTable
local shapeIndex = 1
local playMode = "Active Shape"
local shapeMenu
local shapeNames = shapes.getShapeNames()
local preInit = true -- Used to avoid loading a new shape when loading a preset

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function updateShapeWidgets()
  -- Update widgets with values from the shape
  local callChanged = false
  shapeWidgets.phase:setValue(shapeOptions.phase, callChanged)
  shapeWidgets.factor:setValue(shapeOptions.factor, callChanged)
  shapeWidgets.z:setValue(shapeOptions.z, callChanged)
  shapeWidgets.amount:setValue(shapeOptions.amount, callChanged)
end

local function setShape(loadNew, randomizeLength)
  loadNew = loadNew == true and preInit == false
  randomizeLength = randomizeLength == true

  local values
  local options
  local length = swarmLength
  local minRes = beat2ms(resolutionValues[resolutionMin]) -- Fastest
  local maxRes = beat2ms(resolutionValues[resolution]) -- Slowest

  if randomizeLength then
    length = gem.randomizeValue(swarmLength, swarmLengthInput.min, swarmLengthInput.max, lengthRandomizationAmount)
  end

  -- Update tables
  positionTable.length = length
  sequencerTable.length = length
  sequencerTable:setRange(minRes, maxRes)

  -- Custom shape or no shape selected - do not change
  if playMode == "Custom" then
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
  print("Starting swarm", uniqueId)
  if playMode == "Random Shape" then
    -- Fresh shape loaded here
    shapeMenu.value = gem.getRandom(#shapeNames)
  end
  -- Load shape with options
  setShape(false, playMode ~= "Custom")
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
    local playDuration = ms2beat(sequencerTable:getValue(swarmPosition))
    if quantizeToClosest then
      playDuration = resolutions.quantizeToClosest(playDuration)
    end
    playNote(0, math.floor(gem.randomizeValue(velocity, 1, 127, 3)), beat2ms(playDuration), nil, channel)
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
  print("Starting sequencer", uniqueId)
  space = ms2beat(duration)
  local tickBeat = .5
  local elapsedBeats = space -- To avoid pause
  swarmActive = false
  while isPlaying and seqIndex == uniqueId do
    if elapsedBeats >= space then
      if swarmActive == false and gem.getRandomBoolean(swarmProbability) then
        print("Starting swarm, elapsedBeats, space", elapsedBeats, space)
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
  if isPlaying then
    return
  end
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(sequenceRunner, seqIndex)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  swarmActive = false
  clearPositionTable()
end

--------------------------------------------------------------------------------
-- Header Panel
--------------------------------------------------------------------------------

widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Swarm Trigger", {
  tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to",
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

widgets.numBox("Channel", channel, {
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

local xyShapeFactor = widgets.getPanel():XY('ShapePhase', 'ShapeMorph')
xyShapeFactor.x = noteWidgetColSpacing
xyShapeFactor.y = noteWidgetRowSpacing
xyShapeFactor.width = (widgets.getPanel().width / 2) - 7
xyShapeFactor.height = widgets.getPanel().height - 10

local xySpeedFactor = widgets.getPanel():XY('Space', 'SpaceRand')
xySpeedFactor.x = widgets.posSide(xyShapeFactor)
xySpeedFactor.y = noteWidgetRowSpacing
xySpeedFactor.width = xyShapeFactor.width
xySpeedFactor.height = widgets.getPanel().height - 10

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
  x = widgets.posSide(xySpeedFactor) + 5,
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

widgets.button("Quantize", quantizeToClosest, {
  tooltip = "Quantize output to the closest 'known' resolution",
  increment = false,
  width = 90,
  height = 20,
  y = 30,
  changed = function(self) quantizeToClosest = self.value end
})

widgets.row(2)

shapeMenu = widgets.menu("Swarm Shape", shapeIndex, shapeNames, {
  tooltip = "Set the shape of the swarm. Short bars = fast, long bars = slow. You can edit the shape by selecting 'Custom' from 'Shape Play Mode'.",
  changed = function(self)
    shapeIndex = self.value
    setShape(true)
  end
})

local playModeMenu = widgets.menu("Shape Play Mode", {"Active Shape", "Random Shape", "Custom"}, {
  tooltip = "Set how shapes are selected for playing. Use 'Custom' to edit you own shape.",
  changed = function(self)
    playMode = self.selectedText
    local shapeEnabled = playMode == "Active Shape"
    sequencerTable.enabled = playMode == "Custom"
    lengthRandomizationInput.enabled = playMode == "Active Shape" or playMode == "Random Shape"
    shapeMenu.enabled = shapeEnabled
    xyShapeFactor.enabled = shapeEnabled
    for k,v in pairs(shapeWidgets) do
      v.enabled = shapeEnabled
    end
    setShape(true)
  end
})

shapeWidgets = shapes.getWidgets()
shapeWidgets.amount = shapes.getAmountWidget()
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
  changed = function(self) lengthRandomizationAmount = self.value end
})

widgets.numBox("Swarm Probability", swarmProbability, {
  name = "Probability",
  unit = Unit.Percent,
  integer = false,
  width = 261,
  tooltip = "Set the probability that a swarm will be triggered",
  changed = function(self) swarmProbability = self.value end
})

widgets.col()

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
  integer = false,
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
