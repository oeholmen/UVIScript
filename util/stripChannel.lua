------------------------------------------------------------------
-- Remove channel on note events
------------------------------------------------------------------

local widgets = require "includes.widgets"

local sequencerPanel = widgets.panel({
  width = 720,
  height = 50,
})

widgets.label("Strip Channel", {
  width = sequencerPanel.width,
  height = 50,
  alpha = 0.75,
  fontSize = 30,
  backgroundColour = "505050",
  textColour = "3fe09f"
})

widgets.label("Removes channel on incoming events", {
  width = 260,
  backgroundColour = "transparent",
  textColour = "a0a0a0",
  x = 240,
  y = 15,
})

local notesActiveButton = widgets.button("Notes", true, {
  tooltip = "Strip channel on notes",
  width = 90,
  x = 510,
  y = 15,
})

local midiControlActiveButton = widgets.button("Midi CC", true, {
  tooltip = "Strip channel on midi cc",
  width = notesActiveButton.width,
  x = notesActiveButton.x + notesActiveButton.width + 10,
  y = 15,
})

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

function onController(e)
  if midiControlActiveButton.value then
    e.channel = nil
  end
  postEvent(e)
end

function onNote(e)
  if notesActiveButton.value then
    e.channel = nil
  end
  postEvent(e)
end

function onRelease(e)
  if notesActiveButton.value then
    e.channel = nil
  end
  postEvent(e)
end
