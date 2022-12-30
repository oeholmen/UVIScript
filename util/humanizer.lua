--------------------------------------------------------------------------------
-- Humanizer
--------------------------------------------------------------------------------

local gem = require "includes.common"

local backgroundColour = "#1B1A17" -- Light or Dark
local widgetBackgroundColour = "#E45826" -- Dark
local widgetTextColour = "#F3E9DD" -- Light
local labelTextColour = "white" -- Light
local knobFillColour = "#E6D5B8" -- Light
local labelBackgoundColour = widgetBackgroundColour

setBackgroundColour(backgroundColour)

local panel = Panel("Humanizer")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 50

local label = panel:Label("Label")
label.text = "Humanizer"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {105,25}

local amount = panel:Knob("Amount", 0, 0, 100, true)
amount.unit = Unit.Percent
amount.displayName = "Amount"
amount.tooltip = "Set the amount of humanization"
amount.backgroundColour = widgetBackgroundColour
amount.fillColour = knobFillColour
amount.outlineColour = labelBackgoundColour
amount.x = panel.width / 2
amount.y = 0

function onNote(e)
  run(humanize, e)
end

function humanize(e)
  if amount.value > 0 then
    local a = gem.getRandom(1, (amount.value/4))
    print("Humanize", a)
    wait(a)
  end
  postEvent(e)
end
