------------------------------------------------------------------
-- Remove channel on note events
------------------------------------------------------------------

local gem = require "includes.common"
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

widgets.label("Remove channel on incoming note events", {
  width = 300,
  backgroundColour = "transparent",
  textColour = "a0a0a0",
  x = 240,
  y = 15,
})

local activeButton = widgets.button("Active", true, {
  tooltip = "Toggle state",
  x = 580,
  y = 15,
})

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

function onNote(e)
  if activeButton.value then
    e.channel = nil
  end
  postEvent(e)
end

function onRelease(e)
  if activeButton.value then
    e.channel = nil
  end
  postEvent(e)
end
