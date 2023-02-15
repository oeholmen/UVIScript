--------------------------------------------------------------------------------
-- Probability Trigger - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

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
