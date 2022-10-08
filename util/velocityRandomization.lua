--------------------------------------------------------------------------------
-- Velocity Randomization
--------------------------------------------------------------------------------

require "../includes/common"

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "15133C" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour

setBackgroundColour(backgroundColour)

local panel = Panel("VelocityRandomization")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 40

local label = panel:Label("Label")
label.text = "Velocity Randomization"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {200,25}
label.y = 5

local velRandomization = panel:NumBox("VelocityRandomization", 0, 0, 100, true)
velRandomization.unit = Unit.Percent
velRandomization.displayName = "Randomize"
velRandomization.tooltip = "Amount of radomization applied to incoming note velocity"
velRandomization.backgroundColour = widgetBackgroundColour
velRandomization.textColour = widgetTextColour
velRandomization.x = label.x + label.width + 50
velRandomization.y = label.y + 5
velRandomization.width = 150

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  e.velocity = randomizeValue(e.velocity, 1, 127, velRandomization.value)
  postEvent(e)
end
