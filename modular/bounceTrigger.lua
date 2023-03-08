--------------------------------------------------------------------------------
-- Bounce Trigger - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

local backgroundColour = "404040"
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local channel = 1
local resolutionNames = resolutions.getResolutionNames()
local velocity = 64
local waitResolution = 17
local waitResolutionMin = 26
local bounceProbability = 100
local skipProbability = 0
local oneDirection = false -- TODO Make it possible to go only on direction before resetting
local waitBetweenRounds = false -- TODO Make it possible to insert a wait between bounces

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function getStartResolutionIndex()
  if waitResolution < waitResolutionMin then
    return math.min(waitResolutionMin, waitResolution)
  else
    return math.max(waitResolutionMin, waitResolution)
  end
end

local function getDuration(isRising, currentResolutionIndex)
  local minResolution = math.max(waitResolutionMin, waitResolution)
  local maxResolution = math.min(waitResolutionMin, waitResolution)
  if isRising == true then
    currentResolutionIndex = currentResolutionIndex + 1
    if currentResolutionIndex > minResolution then
      currentResolutionIndex = minResolution
      isRising = false
    end
  else
    currentResolutionIndex = currentResolutionIndex - 1
    if currentResolutionIndex < maxResolution then
      currentResolutionIndex = maxResolution
      isRising = true
    end
  end
  return isRising, currentResolutionIndex
end

local function bounce(uniqueId)
  local isRising = waitResolution < waitResolutionMin
  local currentResolutionIndex = getStartResolutionIndex()
  local duration = resolutions.getResolution(currentResolutionIndex)
  local note = 0
  while isPlaying and seqIndex == uniqueId do
    if gem.getRandomBoolean(skipProbability) == false then
      playNote(note, velocity, beat2ms(duration), nil, channel)
    end
    waitBeat(duration)
    isRising, currentResolutionIndex = getDuration(isRising, currentResolutionIndex)
    if gem.getRandomBoolean(bounceProbability) then
      duration = resolutions.getResolution(currentResolutionIndex)
    end
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(bounce, seqIndex)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
end

--------------------------------------------------------------------------------
-- Header Panel
--------------------------------------------------------------------------------

widgets.panel({
  width = 720,
  height = 30,
})

widgets.setSection({
  xSpacing = 5,
  ySpacing = 5,
})

widgets.label("Bounce Trigger", {
  tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to",
  width = widgets.getPanel().width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 100,
  height = 22,
  x = (widgets.getPanel().width / 2) + 45,
  y = 5,
})

widgets.numBox('Channel', channel, {
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
-- Options Panel
--------------------------------------------------------------------------------

widgets.setSection({
  xSpacing = 0,
  ySpacing = 0,
})

widgets.panel({
  backgroundColour = backgroundColour,
  x = widgets.getPanel().x,
  y = widgets.posUnder(widgets.getPanel()),
  width = widgets.getPanel().width,
  height = 60,
})

widgets.setSection({
  width = 150,
  height = 45,
  xOffset = 10,
  yOffset = 5,
  xSpacing = 5,
  ySpacing = 5,
})

local waitResolutionInput = widgets.menu("Start Duration", waitResolution, resolutionNames, {
  tooltip = "Start the bounce from this resolution",
  changed = function(self) waitResolution = self.value end
})

local waitResolutionMinInput = widgets.menu("Turn Duration", waitResolutionMin, resolutionNames, {
  tooltip = "When this resolution is reached, the bounce turns",
  changed = function(self) waitResolutionMin = self.value end
})

widgets.setSection({
  width = 190,
  height = 20,
  xOffset = widgets.posSide(waitResolutionMinInput),
  yOffset = waitResolutionMinInput.y + 24,
})

widgets.numBox("Bounce Probability", bounceProbability, {
  name = "BounceProbability",
  unit = Unit.Percent,
  tooltip = "Probability that we advance to the next bounce resolution",
  changed = function(self) bounceProbability = self.value end
})

widgets.numBox("Skip Probability", skipProbability, {
  name = "SkipProbability",
  unit = Unit.Percent,
  tooltip = "Probability that a note is skipped (paused)",
  changed = function(self) skipProbability = self.value end
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
