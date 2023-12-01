--------------------------------------------------------------------------------
-- Pulse Trigger - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local channel = 1
local resolutionNames = resolutions.getResolutionNames()
local velocity = 64
local resolution = 23
local gate = 90

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function pulse(uniqueId)
  local note = 0
  while isPlaying and seqIndex == uniqueId do
    local duration = resolutions.getResolution(resolution)
    playNote(note, velocity, beat2ms(resolutions.getPlayDuration(duration, gate)), nil, channel)
    waitBeat(duration)
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(pulse, seqIndex)
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
  height = 50,
})

widgets.setSection({
  width = widgets.getPanel().width,
  height = widgets.getPanel().height,
})

local sequencerLabel = widgets.label("Pulse Trigger", {
  tooltip = "A sequencer that provides a steady pulse (using note 0) that note inputs can listen to",
  editable = true,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 100,
  height = 22,
  xOffset = 165,
  yOffset = (widgets.getPanel().height / 2) - 10,
  xSpacing = 5,
})

widgets.menu("Pulse Duration", resolution, resolutionNames, {
  showLabel = false,
  tooltip = "Start the bounce from this resolution",
  changed = function(self) resolution = self.value end
})

widgets.numBox("Gate", gate, {
  tooltip = "Set the gate length",
  width = 120,
  unit = Unit.Percent,
  changed = function(self) gate = self.value end
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
  width = 100,
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

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  return {sequencerLabel.text}
end

function onLoad(data)
  sequencerLabel.text = data[1]
end
