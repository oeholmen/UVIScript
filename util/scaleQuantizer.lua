------------------------------------------------------------------
-- Scale Quantizer
------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local notes = require "includes.notes"
local scales = require "includes.scales"

local scale = {}
local key = 1
local channel = 0 -- 0 = Omni
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinition = scaleDefinitions[#scaleDefinitions]
local setScale = function() scale = scales.createScale(scaleDefinition, (key - 1)) end
local quantizeProbability = 100

------------------------------------------------------------------
-- Panel
------------------------------------------------------------------

local backgroundColour = "505050" -- Light or Dark
setBackgroundColour(backgroundColour)

local sequencerPanel = widgets.panel({
  width = 720,
  height = 60,
  backgroundColour = backgroundColour,
})

widgets.setSection({
  x = 10,
  xSpacing = 15,
  ySpacing = 5,
  width = 110,
})

widgets.label("Scale Quantizer", {
  tooltip = "Quantize incoming notes to the set scale",
  width = sequencerPanel.width,
  height = 60,
  alpha = 0.75,
  fontSize = 30,
  backgroundColour = backgroundColour,
  textColour = "3fe09f"
})

widgets.setSection({
  x = 216,
  y = 5,
  xSpacing = 15,
  ySpacing = 5,
  width = 110,
  labelBackgroundColour = "transparent",
})

widgets.menu("Key", key, notes.getNoteNames(), {
  width = 45,
  changed = function(self)
    key = self.value
    setScale()
  end
})

local scaleMenu = scales.widget()
scaleMenu.persistent = false -- Avoid running changed function on load, overwriting scaleInput

widgets.label("Scale Definition", {
  textColour = "#d0d0d0",
  width = 90,
})

widgets.menu("Channel", widgets.channels(), {
  tooltip = "Only quantize incoming notes on this channel",
  width = 60,
  changed = function(self) channel = self.value - 1 end
})

widgets.label("Quantize Probability", {
  textColour = "#d0d0d0",
})

widgets.row()

widgets.col(1, 45)
widgets.col(1, 110)

local scaleInput = scales.inputWidget(scaleDefinition, 90)

widgets.col(1, 60)

widgets.numBox("Probability", quantizeProbability, {
  tooltip = "Probability that a note will be quantized to the selected scale",
  showLabel = false,
  unit = Unit.Percent,
  changed = function(self)
    quantizeProbability = self.value
  end
})

scaleMenu.changed = function(self)
  scaleInput.text = scales.getTextFromScaleDefinition(scaleDefinitions[self.value])
end

scaleInput.changed = function(self)
  scaleDefinition = scales.handleScaleInputChanged(self, scaleMenu)
  setScale()
end

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

function onNote(e)
  if (channel == 0 or channel == e.channel) and gem.getRandomBoolean(quantizeProbability) then
    print("Note before", e.note)
    local note = notes.getNoteAccordingToScale(scale, e.note)
    print("Note after", note)
    playNote(note, e.velocity)
  else
    postEvent(e)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  return {scaleInput.text}
end

function onLoad(data)
  -- Check if we find a scale definition that matches the stored definition
  local scaleIndex = scales.getScaleDefinitionIndex(data[1])
  if type(scaleIndex) == "number" then
    print("onLoad, found scale", scaleIndex)
    scaleMenu:setValue(scaleIndex)
  end
  scaleInput.text = data[1]
  scaleInput:changed()
end
