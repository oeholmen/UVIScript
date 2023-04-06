--------------------------------------------------------------------------------
-- Tempo - Set and adjust tempo
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

local tempoCategory = 1
local tempoCategories = {"Any", "Slow", "Mid", "Fast"}
local tempoRanges = {
  {50,240},
  {50,90},
  {80,140},
  {130,240},
}

local sequencerPanel = widgets.panel({
  width = 720,
  height = 50,
})

widgets.label("Tempo", {
  width = sequencerPanel.width,
  height = 50,
  alpha = 0.75,
  fontSize = 30,
  backgroundColour = "505050",
  textColour = "3fe09f"
})

widgets.section({
  width = 150,
  x = 180,
  y = 15,
  xSpacing = 30
})

widgets.knob("Tempo Category", tempoCategory, {
  y = 3,
  min = 1,
  max = #tempoCategories,
  integer = true,
  changed = function(self)
    tempoCategory = self.value
    self.displayText = tempoCategories[tempoCategory]
  end
}):changed()

local tempoInput = widgets.numBox("Current tempo", Synth.parent:getParameter("Tempo"), {
  min = 10,
  max = 400,
  persistent = false,
  integer = true,
  changed = function(self)
    Synth.parent:setParameter("Tempo", self.value)
  end
})

widgets.button("Set New Tempo", false, {
  tooltip = "Set a random tempo within the selected category range",
  persistent = false,
  changed = function(self)
    local tempo = gem.getRandom(tempoRanges[tempoCategory][1], tempoRanges[tempoCategory][2])
    tempoInput:setValue(tempo)
    self.value = false
  end
})
