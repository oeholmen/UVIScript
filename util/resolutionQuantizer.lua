--------------------------------------------------------------------------------
-- Resolution Quantizer
--------------------------------------------------------------------------------

-- TODO Quantize duration/set gate?

local gem = require "includes.common"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

local backgroundColour = "484848" -- Light or Dark
local labelTextColour = "15133C" -- Dark
local labelBackgoundColour = "66ff99" -- Light
local sliderColour = "5FB5FF"
local menuBackgroundColour = "01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "66" .. labelTextColour

widgets.setColours({
  backgroundColour = backgroundColour,
  labelTextColour = labelTextColour,
  labelBackgoundColour = labelBackgoundColour,
  sliderColour = sliderColour,
  menuBackgroundColour = menuBackgroundColour,
  menuTextColour = menuTextColour,
  menuArrowColour = menuArrowColour,
})

setBackgroundColour(backgroundColour)

local recordedEvents = {}
local seqIndex = 0 -- Holds the unique id for the sequencer
local isPlaying = false
local resolutionNames = resolutions.getResolutionNames({'Bypass'})
local resolution = 23
--local legato = false
local channel = 0 -- 0 = Omni

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function sequenceRunner(uniqueId)
  print("Starting sequenceRunner")
  while isPlaying and seqIndex == uniqueId do
    for _,e in ipairs(recordedEvents) do
      playNote(e.note, e.velocity, -1, nil, e.channel)
    end
    recordedEvents = {}
    waitBeat(resolutions.getResolution(resolution))
  end
end

local function startPlaying()
  if isPlaying or resolution == #resolutionNames then
    return
  end
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(sequenceRunner, seqIndex)
end

local function stopPlaying()
  print("Stop playing")
  isPlaying = false
  recordedEvents = {}
end

local function isTrigger(e)
  return channel == 0 or channel == e.channel
end

--------------------------------------------------------------------------------
-- Widgets
--------------------------------------------------------------------------------

widgets.panel({
  width = 720,
  height = 60,
  x = 0,
  y = 0,
  backgroundColour = backgroundColour,
})

widgets.setSection({
  x = 15,
  y = 18,
  xSpacing = 30,
  width = 90
})

local sequencerLabel = widgets.label("Resolution Quantizer", {
  tooltip = "Quantize incoming notes to the given resolution",
  alpha = 0.5,
  fontSize = 22,
  width = 180,
  height = 25,
  y = 20
})

widgets.setSection({
  x = widgets.posSide(sequencerLabel) + 15,
  y = 5,
})

widgets.menu("Resolution", resolution, resolutionNames, {
  tooltip = "Set the quantize resolution",
  changed = function(self)
    resolution = self.value
    if isPlaying and resolution == #resolutionNames then
      stopPlaying()
    end
  end
})

widgets.menu("Channel", widgets.channels(), {
  tooltip = "Only quantize events sent on this channel",
  changed = function(self) channel = self.value - 1 end
})

--[[ widgets.button("Legato", legato, {
  tooltip = "Note events are held until the next event is received and ready to play",
  y = 30,
  changed = function(self) legato = self.value end
}) ]]

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
end

function onNote(e)
  if isTrigger(e) and resolution < #resolutionNames then
    table.insert(recordedEvents, e)
    print("Event received!")
    startPlaying()
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start then
    stopPlaying()
    startPlaying()
  else
    stopPlaying()
  end
end
