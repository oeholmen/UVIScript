-----------------------------------------------------------------------------
-- A random gate for incoming note events
-----------------------------------------------------------------------------

require "common"

local isRunning = false

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "3EC1D3" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

setBackgroundColour(backgroundColour)

local panel = Panel("Gate")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 40

local label = panel:Label("Label")
label.text = "Random Gate"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22

local probability = panel:NumBox("Probability", 50, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Set the probability that the gate will change"
probability.textColour = widgetTextColour
probability.backgroundColour = widgetBackgroundColour
probability.height = 20
probability.width = 120

local waitResolution = panel:Menu("WaitResolution", getResolutionNames())
waitResolution.displayName = "Duration"
waitResolution.tooltip = "The duration between gates"
waitResolution.selected = 11
waitResolution.showLabel = false
waitResolution.height = 20
waitResolution.width = 120
waitResolution.x = probability.x + probability.width + 10
waitResolution.backgroundColour = menuBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour

local gateButton = panel:OnOffButton("GateButton", true)
gateButton.displayName = "On"
gateButton.persistent = false
gateButton.tooltip = "Shows the current state of the gate"
gateButton.backgroundColourOn = "green"
gateButton.backgroundColourOff = "303030"
gateButton.textColourOn = "white"
gateButton.textColourOff = "gray"
gateButton.size = {90,20}
gateButton.x = panel.width - 100
gateButton.changed = function(self)
  if self.value == true then
    gateButton.displayName = "On"
  else
    gateButton.displayName = "Off"
  end
end

function arpeg()
  local round = 0
  while isRunning do
    round = round + 1 -- Increment round
    local waitTime = beat2ms(getResolution(waitResolution.value))
    if getRandomBoolean(probability.value) then
      gateButton:setValue(gateButton.value == false)
    end
    if round == 1 then
      waitTime = waitTime - 50
    end
    wait(waitTime)
  end
end

function onNote(e)
  if gateButton.value == true then
    postEvent(e)
  end
end

function onTransport(start)
  isRunning = start
  if isRunning then
    arpeg()
  else
    gateButton:setValue(true)
  end
end
