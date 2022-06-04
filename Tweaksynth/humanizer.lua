--------------------------------------------------------------------------------
-- Humanizer
--------------------------------------------------------------------------------

require "common"

local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"

setBackgroundColour("#292929")

local panel = Panel("Humanizer")
panel.backgroundColour = "#00000000"
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 50

local label = panel:Label("Label")
label.text = "Humanizer"
label.alpha = 0.5
label.backgroundColour = "#2C2891"
label.textColour = "white"
label.fontSize = 22
label.position = {0,0}
label.size = {105,25}

local amount = panel:Knob("Amount", 0, 0, 100, true)
amount.unit = Unit.Percent
amount.displayName = "Amount"
amount.tooltip = "Set the amount of humanization"
amount.backgroundColour = menuBackgroundColour
amount.textColour = menuTextColour
amount.x = panel.width / 2
amount.y = 0

function onNote(e)
  run(humanize, e)
end

function humanize(e)
  if amount.value > 0 then
    local a = getRandom(1, (amount.value/4))
    print("Humanize", a)
    wait(a)
  end
  postEvent(e)
end
