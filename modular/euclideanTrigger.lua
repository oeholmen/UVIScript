--------------------------------------------------------------------------------
-- Euclidean Trigger - Distributes pulses evenly across steps using the
-- Bjorklund algorithm, and sends note 0 events for modular inputs to listen to
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local seqIndex = 0
local channel = 1
local resolutionNames = resolutions.getResolutionNames()
local resolution = 23
local gate = 90
local velocity = 64
local numSteps = 16
local numPulses = 5
local rotation = 0
local positionTable = nil
local patternTable = nil
local pulsesInput = nil
local rotationInput = nil

--------------------------------------------------------------------------------
-- Euclidean Algorithm (Bjorklund)
--------------------------------------------------------------------------------

local function buildEuclidean(steps, pulses)
  local p = {}
  if pulses <= 0 then
    for i = 1, steps do p[i] = false end
    return p
  end
  if pulses >= steps then
    for i = 1, steps do p[i] = true end
    return p
  end
  for i = 0, steps - 1 do
    p[i + 1] = ((i * pulses) % steps) < pulses
  end
  return p
end

local function getPattern()
  local base = buildEuclidean(numSteps, numPulses)
  local rotated = {}
  for i = 1, numSteps do
    rotated[i] = base[((i - 1 + rotation) % numSteps) + 1]
  end
  return rotated
end

local function updatePatternDisplay()
  if not patternTable then return end
  local pattern = getPattern()
  patternTable.length = numSteps
  for i = 1, numSteps do
    patternTable:setValue(i, pattern[i] and 1 or 0, false)
  end
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

local function euclideanPulse(uniqueId)
  local step = 1
  while isPlaying and seqIndex == uniqueId do
    local stepDuration = resolutions.getResolution(resolution)
    local pattern = getPattern()

    if positionTable then
      positionTable.length = numSteps
      for i = 1, numSteps do
        positionTable:setValue(i, i == step and 1 or 0, false)
      end
    end

    if pattern[step] then
      playNote(0, velocity, beat2ms(resolutions.getPlayDuration(stepDuration, gate)), nil, channel)
    end

    step = (step % numSteps) + 1
    waitBeat(stepDuration)
  end

  if positionTable then
    for i = 1, numSteps do
      positionTable:setValue(i, 0, false)
    end
  end
end

local function startPlaying()
  if isPlaying then return end
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(euclideanPulse, seqIndex)
end

local function stopPlaying()
  if isPlaying == false then return end
  isPlaying = false
end

--------------------------------------------------------------------------------
-- Header Panel
--------------------------------------------------------------------------------

widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Euclidean Trigger", {
  tooltip = "Distributes rhythmic pulses evenly across steps (Bjorklund algorithm). Sends note 0 events that modular inputs can listen to.",
  width = widgets.getPanel().width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 100,
  height = 22,
  xOffset = 405,
  yOffset = (widgets.getPanel().height / 2) - 11,
  xSpacing = 5,
})

widgets.numBox('Channel', channel, {
  tooltip = "Send note 0 events on this channel",
  min = 1, max = 16, integer = true,
  changed = function(self) channel = self.value end
})

local autoplayButton = widgets.button('Auto Play', true, {
  tooltip = "Play automatically on transport",
})

local playButton = widgets.button('Play', false, {
  changed = function(self)
    if self.value == true then startPlaying() else stopPlaying() end
  end
})

--------------------------------------------------------------------------------
-- Controls Panel
--------------------------------------------------------------------------------

widgets.panel({
  x = 0,
  y = widgets.posUnder(widgets.getPanel()),
  width = 720,
  height = 30,
})

widgets.setSection({
  width = 134,
  height = 22,
  xOffset = 5,
  yOffset = 4,
  xSpacing = 5,
})

local stepsInput = widgets.numBox("Steps", numSteps, {
  tooltip = "Total number of steps in the euclidean pattern",
  min = 2, max = 32, integer = true,
  changed = function(self)
    numSteps = self.value
    if pulsesInput then
      if pulsesInput.value > numSteps then
        pulsesInput:setValue(numSteps, false)
        numPulses = numSteps
      end
      pulsesInput:setRange(0, numSteps)
    end
    if rotationInput then
      rotationInput:setRange(0, numSteps - 1)
      if rotationInput.value >= numSteps then
        rotationInput:setValue(0, false)
        rotation = 0
      end
    end
    updatePatternDisplay()
  end
})

pulsesInput = widgets.numBox("Pulses", numPulses, {
  tooltip = "Number of pulses to distribute across the steps",
  min = 0, max = numSteps, integer = true,
  changed = function(self)
    numPulses = self.value
    updatePatternDisplay()
  end
})

rotationInput = widgets.numBox("Rotation", rotation, {
  tooltip = "Rotate the pattern by this number of steps",
  min = 0, max = numSteps - 1, integer = true,
  changed = function(self)
    rotation = self.value
    updatePatternDisplay()
  end
})

widgets.menu("Step Duration", resolution, resolutionNames, {
  tooltip = "Duration of each step",
  showLabel = false,
  changed = function(self) resolution = self.value end
})

widgets.numBox("Gate", gate, {
  tooltip = "Gate length as percentage of step duration",
  unit = Unit.Percent,
  changed = function(self) gate = self.value end
})

--------------------------------------------------------------------------------
-- Pattern Display Panel
--------------------------------------------------------------------------------

widgets.panel({
  x = 0,
  y = widgets.posUnder(widgets.getPanel()),
  width = 720,
  height = 38,
})

widgets.setSection({
  width = 710,
  x = 5,
  y = 4,
  cols = 1,
})

positionTable = widgets.table("Position", 0, numSteps, {
  enabled = false,
  persistent = false,
  fillStyle = "solid",
  backgroundColour = "404040",
  sliderColour = "eeeeee",
  height = 4,
})

widgets.setSection({
  y = widgets.posUnder(positionTable) + 2,
  cols = 1,
})

patternTable = widgets.table("Pattern", 0, numSteps, {
  enabled = false,
  persistent = false,
  fillStyle = "solid",
  backgroundColour = "191E25",
  sliderColour = "66FF99",
  min = 0, max = 1,
  height = 25,
})

updatePatternDisplay()

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
end

function onNote(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
    velocity = e.velocity
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

