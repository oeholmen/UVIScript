-----------------------------------------------------------------------------------------------------------------
-- Sequencer Input - A standard sequencer that listens to incoming events on note 0
-----------------------------------------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local modular = require "includes.modular"

local channel = 0 -- 0 = Omni
local forward = false
local baseNote = 48
local tableLength = 8
local sequencerPos = 1

widgets.setSection({
  width = 720,
})

local sequencerPanel = widgets.panel({
  height = 200,
})

local sequencerLabel = widgets.label("Sequencer Input", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  height = 30,
  editable = true,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 90,
  xOffset = 531,
  yOffset = 5,
  xSpacing = 5,
  ySpacing = 5,
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
  xOffset = 5,
  yOffset = widgets.posUnder(sequencerLabel) + 5,
  xSpacing = 5,
  ySpacing = 5,
})

local sequencerTable = widgets.table(tableLength, 0, {
  --tooltip = "Events are triggered when the value hits max or min",
  showPopupDisplay = true,
  backgroundColour = "191E25",
  min = -12,
  max = 12,
  integer = true,
  height = 120,
  width = 710,
})

widgets.setSection({
  width = 120,
  yOffset = widgets.posUnder(sequencerTable) + 5,
})

widgets.numBox("Root", baseNote, {
  unit = Unit.MidiKey,
  tooltip = "Set the root note",
  changed = function(self) baseNote = self.value end
})

widgets.numBox("Steps", tableLength, {
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the number of steps in the sequencer",
  changed = function(self)
    tableLength = self.value
    sequencerTable.length = tableLength
  end
})

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function getNote()
  local note = baseNote + sequencerTable:getValue(sequencerPos)
  sequencerPos = gem.inc(sequencerPos, 1, tableLength)
  return note
end

function onNote(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    modular.handleTrigger(e, getNote())
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
  if start == false then
    modular.releaseVoices()
    sequencerPos = 1
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
