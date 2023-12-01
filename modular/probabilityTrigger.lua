--------------------------------------------------------------------------------
-- Probability Trigger - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

local backgroundColour = "101010"

widgets.setColours({
  backgroundColour = backgroundColour,
  menuBackgroundColour = backgroundColour,
  widgetBackgroundColour = backgroundColour,
})

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local channel = 1
local resolutionNames = resolutions.getResolutionNames()
local resolution = 23
local voiceId = nil -- Holds the id of the created note event
local probability = 50
local velocity = 64
local legato = false
local beatFactor = .5
local beatFactorMin = .01
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

local function sequenceRunner(uniqueId)
  while isPlaying and seqIndex == uniqueId do
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
  seqIndex = gem.inc(seqIndex)
  run(sequenceRunner, seqIndex)
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

widgets.label("Probability Trigger", {
  tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to",
  height = 30,
  width = widgets.getPanel().width,
  x = 0, y = 0,
  alpha = 0.5, fontSize = 22,
})

widgets.setSection({
  width = 100,
  xSpacing = 5,
  ySpacing = 5,
  x = (widgets.getPanel().width / 2) + 45,
  y = 5,
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
  height = 205,
})

local noteWidgetColSpacing = 10
local noteWidgetRowSpacing = 5

local xySpeedFactor = widgets.getPanel():XY('Probability', 'BeatFactorProbability')
xySpeedFactor.x = 10
xySpeedFactor.y = 10
xySpeedFactor.width = 480
xySpeedFactor.height = 190

widgets.setSection({
  width = 205,
  height = 22,
  x = widgets.posSide(xySpeedFactor) + 10,
  y = 10,
  xSpacing = noteWidgetColSpacing,
  ySpacing = noteWidgetRowSpacing,
  cols = 1,
})

local resolutionInput = widgets.menu("Quantize", resolution, resolutionNames, {
  tooltip = "Event triggers are quantized to this resolution",
  width = 93,
  height = 48,
  increment = false,
  changed = function(self) resolution = self.value end,
})

widgets.button("Legato", legato, {
  tooltip = "In legato mode notes are held until the next note is played",
  x = widgets.posSide(resolutionInput) + noteWidgetColSpacing,
  width = resolutionInput.width,
  changed = function(self) legato = self.value end
})

widgets.button("Quantize Closest", quantizeToClosest, {
  tooltip = "Quantize to closest resolution when using beat factor",
  x = widgets.posSide(resolutionInput) + noteWidgetColSpacing,
  width = resolutionInput.width,
  changed = function(self) quantizeToClosest = self.value end
})

widgets.numBox("Trigger Probability", probability, {
  name = "Probability",
  unit = Unit.Percent,
  integer = false,
  tooltip = "Set the probabilty that an event will be triggered - controlled by the x-axis of the XY controller",
  changed = function(self) probability = self.value end
})

widgets.numBox("Beat Factor Probability", beatFactorProbability, {
  name = "BeatFactorProbability",
  unit = Unit.Percent,
  integer = false,
  tooltip = "Set the probabilty that the beat factor will be used - controlled by the y-axis of the XY controller",
  changed = function(self) beatFactorProbability = self.value end
})

widgets.numBox("Beat Factor", beatFactor, {
  min = beatFactorMin,
  max = beatFactorMax,
  tooltip = "Set a factor to multiply the selected beat with",
  changed = function(self) beatFactor = self.value end
})

widgets.numBox("Beat Factor Randomization", beatFactorRandomizationAmount, {
  unit = Unit.Percent,
  tooltip = "Set the randomization amount for the beat factor",
  changed = function(self) beatFactorRandomizationAmount = self.value end
})

widgets.numBox("Velocity", velocity, {
  name = "Velocity",
  min = 1,
  max = 127,
  tooltip = "Set the velocity amount",
  changed = function(self) velocity = self.value end
})

--------------------------------------------------------------------------------
-- Handle events
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
