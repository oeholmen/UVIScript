------------------------------------------------------------------
-- Block all incoming note events
------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local channel = 0 -- 0 = Omni

local sequencerPanel = widgets.panel({
  width = 720,
  height = 50,
})

widgets.label("Block Note Events", {
  width = sequencerPanel.width,
  height = 50,
  alpha = 0.75,
  fontSize = 30,
  backgroundColour = "505050",
  textColour = "red"
})

widgets.label("Block incoming note events", {
  width = 200,
  backgroundColour = "transparent",
  textColour = "a0a0a0",
  x = 260,
  y = 23,
})

widgets.setSection({
  x = 460,
  y = 23,
  xSpacing = 5,
  height = 22
})

widgets.menu("Channel", widgets.channels(), {
  tooltip = "Only block incoming notes on the given channel - (Omni blocks all)",
  y = 0,
  changed = function(self) channel = self.value - 1 end
})

local activeButton = widgets.button("Active", true, {
  tooltip = "Toggle state",
})

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function isOpen(e)
  if activeButton.value then
    if channel == 0 or channel == e.channel then
        return false
    end
  end
  return true
end

function onNote(e)
  if isOpen(e) then
    postEvent(e)
  end
end

function onRelease(e)
  if isOpen(e) then
    postEvent(e)
  end
end
