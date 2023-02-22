--------------------------------------------------------------------------------
-- Sieve
--------------------------------------------------------------------------------
-- Set the probability that incomming notes will pass through the sieve
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

local backgroundColour = "202020" -- Light or Dark

widgets.setColours({
  backgroundColour = backgroundColour,
  widgetBackgroundColour = "black",
  widgetTextColour = "3EC1D3",
  labelTextColour = "black",
  labelBackgoundColour = "black",
  menuBackgroundColour = "01011F",
  menuArrowColour = "66" .. "black",
  menuOutlineColour = "5f" .. "3EC1D3",
  backgroundColourOff = "red",
})

setBackgroundColour(backgroundColour)

widgets.panel({
  backgroundColour = backgroundColour,
  x = 10,
  y = 10,
  width = 700,
  height = 40,
})

widgets.setSection({
  x = 10,
  y = 8,
  xSpacing = 15,
})

widgets.label("Sieve", {
  tooltip = "Set the probability that incomming notes will pass through. The sieve can be used to block ranges with probability set to 0.",
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  x = 210,
})

local sieveProbability = widgets.numBox("Probability", 50, {
  tooltip = "Set the probability that incomming notes will pass through the sieve",
  unit = Unit.Percent,
})

local noteMin = widgets.numBox("Min", 0, {
  tooltip = "Lowest note - notes below this are passed through",
  unit = Unit.MidiKey,
})

local noteMax = widgets.numBox("Max", 127, {
  tooltip = "Highest note - notes above this are passed through",
  unit = Unit.MidiKey,
})

local sieveButton = widgets.button(" ", {
  tooltip = "Shows current state",
  width = 22,
})

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  if e.note < noteMin.value or e.note > noteMax.value or gem.getRandomBoolean(sieveProbability.value) then
    print("Passing through", e.note)
    sieveButton.backgroundColourOff = "green"
    postEvent(e)
  else
    print("Stopping", e.note)
    sieveButton.backgroundColourOff = "red"
  end
end

function onRelease(e)
  e.velocity = 0
  postEvent(e)
end
