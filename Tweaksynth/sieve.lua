--------------------------------------------------------------------------------
-- Sieve
--------------------------------------------------------------------------------
-- Set the probability that incomming notes will pass through the sieve
--------------------------------------------------------------------------------

require "common"

local backgroundColour = "1a4245" -- Light or Dark
local widgetBackgroundColour = "072227" -- Dark
local widgetTextColour = "4FBDBA" -- Light
local labelTextColour = "AEFEFF" -- Light
local menuArrowColour = "aa" .. widgetTextColour
local labelBackgoundColour = "ff" .. widgetBackgroundColour
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

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  if getRandomBoolean(sieveProbability.value) then
    print("Passing through", e.note)
    postEvent(e)
  else
    print("Stopping", e.note)
  end
end

function onRelease(e)
  e.velocity = 0
  postEvent(e)
end
