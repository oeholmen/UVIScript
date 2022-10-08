----------------------------------------------
-- A random gate for incoming note events
----------------------------------------------

require "../includes/common"

local isRunning = false

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "3EC1D3" -- Light
local knobFillColour = "E6D5B8" -- Light
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
panel.height = 60

local label = panel:Label("Label")
label.text = "Note Event Gate"
label.tooltip = "When the gate is closed, all note on events are stopped."
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.width = 140
label.fontSize = 22

local probability = panel:Knob("Probability", 50, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Set the probability that the gate will open or close"
probability.backgroundColour = widgetBackgroundColour
probability.fillColour = knobFillColour
probability.outlineColour = labelBackgoundColour
probability.x = label.x + label.width + 30
probability.width = 120

local waitResolution = panel:Menu("WaitResolution", getResolutionNames())
waitResolution.displayName = "Open Duration"
waitResolution.tooltip = "The duration of open gate"
waitResolution.selected = 11
waitResolution.width = 120
waitResolution.x = probability.x + probability.width + 10
waitResolution.backgroundColour = menuBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour

local waitResolutionClosed = panel:Menu("WaitResolutionClosed", getResolutionNames())
waitResolutionClosed.displayName = "Closed Duration"
waitResolutionClosed.tooltip = "The duration closed gate"
waitResolutionClosed.selected = 11
waitResolutionClosed.width = 120
waitResolutionClosed.x = waitResolution.x + waitResolution.width + 10
waitResolutionClosed.backgroundColour = menuBackgroundColour
waitResolutionClosed.textColour = widgetTextColour
waitResolutionClosed.arrowColour = menuArrowColour
waitResolutionClosed.outlineColour = menuOutlineColour

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
gateButton.y = 30
gateButton.changed = function(self)
  if self.value == true then
    gateButton.displayName = "On"
  else
    gateButton.displayName = "Off"
  end
end

function arpeg()
  local round = 0
  local waitTime = 0
  while isRunning do
    round = round + 1 -- Increment round
    if getRandomBoolean(probability.value) then
      gateButton:setValue(gateButton.value == false)
    end
    if gateButton.value == true then
      waitTime = beat2ms(getResolution(waitResolution.value))
    else
      waitTime = beat2ms(getResolution(waitResolutionClosed.value))
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
  elseif probability.value > 0 then
    gateButton:setValue(true)
  end
end
