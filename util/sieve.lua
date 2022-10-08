--------------------------------------------------------------------------------
-- Sieve
--------------------------------------------------------------------------------
-- Set the probability that incomming notes will pass through the sieve
--------------------------------------------------------------------------------

require "../includes/common"

local backgroundColour = "202020" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "3EC1D3" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

setBackgroundColour(backgroundColour)

local panel = Panel("Sieve")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 40

local label = panel:Label("Label")
label.text = "Sieve"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {55,25}

local sieveProbability = panel:NumBox("SieveProbability", 50, 0, 100, true)
sieveProbability.unit = Unit.Percent
sieveProbability.backgroundColour = widgetBackgroundColour
sieveProbability.textColour = widgetTextColour
sieveProbability.displayName = "Probability"
sieveProbability.tooltip = "Set the probability that incomming notes will pass through the sieve"

local noteMin = panel:NumBox("NoteMin", 0, 0, 127, true)
noteMin.unit = Unit.MidiKey
noteMin.backgroundColour = widgetBackgroundColour
noteMin.textColour = widgetTextColour
noteMin.displayName = "Min"
noteMin.tooltip = "Lowest note - notes below this are passed through"

local noteMax = panel:NumBox("NoteMax", 127, 0, 127, true)
noteMax.unit = Unit.MidiKey
noteMax.backgroundColour = widgetBackgroundColour
noteMax.textColour = widgetTextColour
noteMax.displayName = "Max"
noteMax.tooltip = "Highest note - notes above this are passed through"

local sieveButton = panel:Button("SieveButton")
sieveButton.displayName = " "
sieveButton.tooltip = "Shows current state"
sieveButton.backgroundColourOff = "red"
sieveButton.backgroundColourOn = "green"
sieveButton.size = {20,20}
sieveButton.x = panel.width - 40

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  if e.note <= noteMin.value or e.note >= noteMax.value or getRandomBoolean(sieveProbability.value) then
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
