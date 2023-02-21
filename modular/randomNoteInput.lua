-----------------------------------------------------------------------------------------------------------------
-- Random Notes - Replaces note 0 in incoming note events with a random note from the selected key and scale
-----------------------------------------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local modular = require "includes.modular"
local notes = require "includes.notes"
local scales = require "includes.scales"
local noteSelector = require "includes.noteSelector"

-- TODO Add a button for deselecting all notes

local channel = 0 -- 0 = Omni
local forward = false

local sequencerPanel = widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Random Note Input", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  width = sequencerPanel.width,
  height = 30,
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

local channelInput = widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to triggers (note=0 events) on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

--------------------------------------------------------------------------------
-- Notes
--------------------------------------------------------------------------------

widgets.setSection({
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
})

local notePanel = widgets.panel({
  x = sequencerPanel.x,
  y = widgets.posUnder(sequencerPanel),
  width = sequencerPanel.width,
  height = 200,
})

local noteLabel = widgets.label("Notes", {
  tooltip = "Set the probability that notes will be included when generating new notes",
  alpha = 0.75,
  width = sequencerPanel.width,
  height = 22,
})

local inputButton = widgets.button(" ", false, {
  tooltip = "Shows when notes are triggered",
  persistent = false,
  enabled = false,
  width = channelInput.width,
  height = 18,
  y = 2,
  x = channelInput.x,
})
inputButton.backgroundColourOff = "202020"

noteSelector.createNoteAndOctaveSelector(notePanel, widgets.getColours(), noteLabel, 15, 42, {x = 15, y = widgets.posUnder(noteLabel) + 10})

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function flashInput()
  inputButton.backgroundColourOff = "606060"
  waitBeat(.125)
  inputButton.backgroundColourOff = "202020"
end

local function getNote()
  return gem.getRandomFromTable(noteSelector.getSelectedNotes())
end

function onNote(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    if modular.handleTrigger(e, getNote()) then
      spawn(flashInput)
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
  if start == false then
    modular.releaseVoices()
  end
end
