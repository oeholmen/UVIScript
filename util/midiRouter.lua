----------------------------------------------------------------------------------------------------------------------------
-- The midi router, routes incoming midi for all events from the selected midi in channel, to the selected midi out channel
----------------------------------------------------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

widgets.panel({
  width = 720,
  height = 50
})

widgets.setSection({
  width = 150,
  cols = 8,
  x = 15,
  y = 15,
  xSpacing = 30,
})

local label = widgets.label("Midi Router", {
  name = "router",
  tooltip = "Edit to set a label for this router.",
  width = 180,
  alpha = 0.75,
  fontSize = 24,
  backgroundColour = "transparent",
  backgroundColourWhenEditing = "white",
  textColourWhenEditing = "black",
  textColour = "865DFF"
})

local channelIn = widgets.numBox("Channel In", 0, {
  name = "inchannel",
  min = 0,
  max = 16,
  integer = true,
  tooltip = "Listen on midi in channel. 0 = omni.",
})

local channelOut = widgets.numBox("Channel Out", 1, {
  name = "outchannel",
  min = 1,
  max = 16,
  integer = true,
  tooltip = "Route to midi out channel",
})

widgets.button('On', false, {
  tooltip = "Activate router",
  width = 60,
  changed = function(self)
    channelIn.enabled = self.value
    channelOut.enabled = self.value
  end
}):changed()


--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function flashLabel()
  local flashDuration = 250
  label.textColour = "yellow"
  wait(flashDuration)
  label.textColour = "865DFF"
end

function onEvent(e)
  if channelIn.enabled and (channelIn.value == 0 or channelIn.value == e.channel) then
    spawn(flashLabel)
    e.channel = channelOut.value
  end
  postEvent(e)
end
