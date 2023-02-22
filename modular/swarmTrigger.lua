--------------------------------------------------------------------------------
-- Probability Trigger - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

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
  x = (widgets.getPanel().width / 2) + 45,
  y = 5,
})

widgets.label("Swarm Trigger", {
  tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to",
  width = widgets.getPanel().width,
  x = 0, y = 0, height = 30,
  alpha = 0.5, fontSize = 22,
  --increment = false,
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
  x = widgets.posSide(xySpeedFactor) + 12,
  y = 15,
  xSpacing = noteWidgetColSpacing,
  ySpacing = noteWidgetRowSpacing,
  cols = 1,
})

widgets.menu("Swarm Base", resolution, resolutionNames, {
  tooltip = "Set the base resolution of the swarm",
  changed = function(self) resolution = self.value end
})

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
