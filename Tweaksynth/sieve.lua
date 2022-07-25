--------------------------------------------------------------------------------
-- Sieve
--------------------------------------------------------------------------------
-- Set the probability that incomming notes will pass through the sieve
--------------------------------------------------------------------------------

require "common"

local backgroundColour = "5800FF" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "0096FF" -- Light
local labelTextColour = "72FFFF" -- Light
local menuArrowColour = "aa" .. widgetTextColour
local labelBackgoundColour = "101010"
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
label.size = {75,25}

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
sieveButton.backgroundColourOff = "red"
sieveButton.backgroundColourOn = "green"
sieveButton.size = {20,20}

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
