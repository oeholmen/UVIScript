-----------------------------------------------------------------------------------------------------------------
-- Sequencer Input - A standard sequencer that listens to incoming events on note 0
-----------------------------------------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local modular = require "includes.modular"
local resolutions = require "includes.resolutions"

local isPlaying = false
local channel = 0 -- 0 = Omni
local forward = false
local baseNote = 48
local tableLength = 8
local sequencerPos = 1
local octaveRange = 1
local bipolar = true
local pitchOffsetSwapProbability = 0
local resolutionNames = resolutions.getResolutionNames({'Follow Trigger'})
local resolution = #resolutionNames

widgets.setSection({
  width = 720,
})

local sequencerPanel = widgets.panel({
  height = 130,
})

local sequencerLabel = widgets.label("Sequencer Input", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  height = 30,
  editable = true,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 45,
  xOffset = 354,
  yOffset = 5,
  xSpacing = 5,
  ySpacing = 5,
  labelBackgroundColour = "transparent",
})

local clockLabel = widgets.label("Clock")

widgets.setSection({
  width = 100,
  xOffset = widgets.posSide(clockLabel),
})

widgets.menu("Resolution", resolution, resolutionNames, {
  tooltip = "Set the resolution of the sequencer",
  showLabel = false,
  changed = function(self)
    resolution = self.value
    if isPlaying and resolution == #resolutionNames then
      isPlaying = false
    end
  end
})

widgets.button("Forward", forward, {
  tooltip = "Forward triggers (note=0 events) to the next processor",
  changed = function(self) forward = self.value end,
})

widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to triggers (note=0 events) on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

widgets.setSection({
  width = 710,
  xOffset = 5,
  yOffset = widgets.posUnder(sequencerLabel) + 5,
  xSpacing = 5,
  ySpacing = 0,
})

local positionTable = widgets.table(tableLength, 0, {
  integer = true,
  enabled = false,
  persistent = false,
  fillStyle = "solid",
  backgroundColour = "404040",
  sliderColour = "66ff99",
  height = 3,
  increment = false,
})

local sequencerTable = widgets.table(tableLength, 0, {
  tooltip = "Set the pitch offset",
  showPopupDisplay = true,
  backgroundColour = "191E25",
  min = -12,
  max = 12,
  integer = true,
  height = 60,
  y = widgets.posUnder(positionTable)
})

widgets.setSection({
  width = 114,
  yOffset = widgets.posUnder(sequencerTable) + 5,
})

local noteInput = widgets.numBox("Root Note", baseNote, {
  unit = Unit.MidiKey,
  tooltip = "Set the root note",
  changed = function(self) baseNote = self.value end
})

local listenButton = widgets.button("Note Learn")

widgets.numBox("Steps", tableLength, {
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the number of steps in the sequencer",
  changed = function(self)
    tableLength = self.value
    sequencerTable.length = tableLength
    positionTable.length = tableLength
  end
})

local function setRange()
  local tableRange = octaveRange * 12
  if bipolar then
    sequencerTable:setRange(-tableRange, tableRange)
  else
    sequencerTable:setRange(0, tableRange)
  end
  for i=1,tableLength do
    sequencerTable:setValue(i, math.max(sequencerTable.min, sequencerTable:getValue(i)))
    sequencerTable:setValue(i, math.min(sequencerTable.max, sequencerTable:getValue(i)))
  end
end

widgets.numBox("Octave Range", octaveRange, {
  tooltip = "Set the octave range",
  min = 1,
  max = 4,
  integer = true,
  changed = function(self)
    octaveRange = self.value
    setRange()
  end
})

widgets.button("Bipolar", bipolar, {
  tooltip = "When bipolar is active, the octave range is both positive and negative",
  changed = function(self)
    bipolar = self.value
    setRange()
  end
})

widgets.numBox("Offset Rand", pitchOffsetSwapProbability, {
  tooltip = "Probability that the pitch offset from another step will be used",
  unit = Unit.Percent,
  changed = function(self) pitchOffsetSwapProbability = self.value end
})

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function setPosition()
  print("setPosition", sequencerPos)
  for i=1,tableLength do
    local val = 0
    if i == sequencerPos then
      val = 1
    end
    positionTable:setValue(i, val)
  end
end

local function sequenceRunner()
  print("Starting sequenceRunner")
  while isPlaying do
    setPosition()
    waitBeat(resolutions.getResolution(resolution))
    if isPlaying then
      sequencerPos = gem.inc(sequencerPos, 1, tableLength)
    end
  end
end

local function startPlaying()
  if isPlaying or resolution == #resolutionNames then
    return
  end
  isPlaying = true
  run(sequenceRunner)
end

local function stopPlaying()
  isPlaying = false
  modular.releaseVoices()
  sequencerPos = 1
  for i=1,tableLength do
    positionTable:setValue(i, 0)
  end
end

local function getNote()
  local pitchOffset = 0
  if gem.getRandomBoolean(pitchOffsetSwapProbability) then
    randomPos = gem.getRandom(tableLength)
    pitchOffset = sequencerTable:getValue(randomPos)
  else
    pitchOffset = sequencerTable:getValue(sequencerPos)
  end
  return baseNote + pitchOffset
end

function onNote(e)
  if listenButton.value then
    noteInput:setValue(e.note)
    listenButton:setValue(false)
  end
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    if modular.handleTrigger(e, getNote()) then
      if resolution == #resolutionNames then
        setPosition()
        sequencerPos = gem.inc(sequencerPos, 1, tableLength)
      else
        startPlaying()
      end
    end
  else
    postEvent(e)
  end
end

function onRelease(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    modular.handleReleaseTrigger(e)
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start then
    startPlaying()
  else
    stopPlaying()
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
