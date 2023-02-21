------------------------------------------------------------------
-- Scale Quantizer
------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local notes = require "includes.notes"
local scales = require "includes.scales"

local channel = 0 -- 0 = Omni
local scale = {}
local key = 1
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinition = #scaleDefinitions

local function setScale()
  scale = scales.createScale(scaleDefinition, (key - 1))
end

------------------------------------------------------------------
-- Panel
------------------------------------------------------------------

local sequencerPanel = widgets.panel({
  width = 720,
  height = 60,
})

widgets.label("Scale Quantizer", {
  tooltip = "Quantize incoming notes to the set scale",
  width = sequencerPanel.width,
  height = 60,
  alpha = 0.5,
  fontSize = 30,
  backgroundColour = "606060",
  textColour = "3fe09f"
})

widgets.setSection({
  width = 90,
  x = 400,
  y = 5,
  xSpacing = 15,
})

widgets.menu("Key", key, notes.getNoteNames(), {
  changed = function(self)
    key = self.value
    setScale()
  end
})

widgets.menu("Scale", scaleDefinition, scales.getScaleNames(), {
  changed = function(self)
    scaleDefinition = scaleDefinitions[self.value]
    setScale()
  end
})

local channelInput = widgets.menu("Channel", widgets.channels(), {
  tooltip = "Only quantize incoming notes on this channel",
  changed = function(self) channel = self.value - 1 end
})

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

function onNote(e)
  if channel == 0 or channel == e.channel then
    print("Note before", e.note)
    e.note = notes.getNoteAccordingToScale(scale, e.note)
    print("Note after", e.note)
  end
  postEvent(e)
end
