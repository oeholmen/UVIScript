--------------------------------------------------------------------------------
-- Set velocity on incoming notes
--------------------------------------------------------------------------------

local gem = require "includes.common"

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "15133C" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour

setBackgroundColour(backgroundColour)

local panel = Panel("Velocity")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 40

local label = panel:Label("Label")
label.text = "Note Velocity"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {120,25}
label.y = 5

local velocityInput = panel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.textColour = widgetTextColour
velocityInput.displayName = "Velocity"
velocityInput.x = label.x + label.width + 150
velocityInput.y = label.y

local velRandomization = panel:NumBox("VelocityRandomization", 0, 0, 100, true)
velRandomization.displayName = "Randomize"
velRandomization.tooltip = "Amount of radomization applied to velocity"
velRandomization.unit = Unit.Percent
velRandomization.backgroundColour = widgetBackgroundColour
velRandomization.textColour = widgetTextColour
velRandomization.x = velocityInput.x + velocityInput.width + 10
velRandomization.y = velocityInput.y

--------------------------------------------------------------------------------
-- Handle note on event
--------------------------------------------------------------------------------

function onNote(e)
  e.velocity = gem.randomizeValue(velocityInput.value, velocityInput.min, velocityInput.max, velRandomization.value)
  postEvent(e)
end
