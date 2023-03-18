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

widgets.setColours({
  labelBackgroundColour = "F5E9CF",
  backgroundColour = "4D455D",
})

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
  xOffset = 433,
  yOffset = 5,
  xSpacing = 5,
  ySpacing = 5,
})

local inputButton = widgets.button(" ", false, {
  tooltip = "Shows when notes are triggered",
  persistent = false,
  enabled = false,
  backgroundColourOff = "202020"
})

modular.getForwardWidget()
modular.getChannelWidget()

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
  height = 160,
})

local noteLabel = widgets.label("Notes", {
  tooltip = "Select notes manually, or by selecting a scale",
  alpha = 0.75,
  width = sequencerPanel.width,
  height = 22,
})

noteSelector.createNoteAndOctaveSelector(notePanel, widgets.getColours(), noteLabel, 18, 12, {x = 500, y = noteLabel.y + 2.5, height = 18})

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
  if modular.isTrigger(e) then
    if modular.handleTrigger(e, getNote()) then
      spawn(flashInput)
    end
  else
    postEvent(e)
  end
end

function onRelease(e)
  if modular.isTrigger(e) then
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
