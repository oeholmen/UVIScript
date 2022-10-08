-----------------------------------------------------------------------------
-- A script modulator that adjusts two connected sources probabilistically
-----------------------------------------------------------------------------

require "../includes/common"

local isRunning = false

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "15133C" -- Dark
local widgetTextColour = "66ff99" -- Light
--local knobFillColour = "#E6D5B8" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

setBackgroundColour(backgroundColour)

local panel = Panel("Switcher")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 40

local label = panel:Label("Label")
label.text = "Switch"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
--label.position = {0,0}
--label.size = {140,25}
--label.y = 5

local sourceIndex1 = panel:NumBox("SourceIndex1", 0, 0, 127, true)
sourceIndex1.backgroundColour = widgetBackgroundColour
sourceIndex1.textColour = widgetTextColour
sourceIndex1.displayName = "Event 1"
--sourceIndex1.x = label.x + label.width + 150
--sourceIndex1.y = label.y

local probability = panel:NumBox("Probability", 50, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Set the probability that 1 or 2 is selected"
probability.textColour = widgetTextColour
probability.backgroundColour = widgetBackgroundColour
--probability.fillColour = knobFillColour
--probability.outlineColour = labelBackgoundColour
--probability.x = panel.width / 2
--probability.y = label.y

local sourceIndex2 = panel:NumBox("SourceIndex2", 1, 0, 127, true)
sourceIndex2.backgroundColour = widgetBackgroundColour
sourceIndex2.textColour = widgetTextColour
sourceIndex2.displayName = "Event 2"
--sourceIndex2.x = sourceIndex1.x + sourceIndex1.width + 10
--sourceIndex2.y = sourceIndex1.y

local waitResolution = panel:Menu("WaitResolution", getResolutionNames())
waitResolution.displayName = "Duration"
waitResolution.tooltip = "The duration between changes"
waitResolution.selected = 11
waitResolution.showLabel = false
waitResolution.height = 20
waitResolution.width = 90
--waitResolution.x = panel.width - waitResolution.width
--waitResolution.y = label.y
waitResolution.backgroundColour = menuBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour

local rampResolution = panel:Menu("RampResolution", getResolutionNames())
rampResolution.displayName = "Duration"
rampResolution.tooltip = "The duration of the change"
rampResolution.selected = 20
rampResolution.showLabel = false
rampResolution.height = 20
rampResolution.width = 90
--rampResolution.x = panel.width - rampResolution.width
--rampResolution.y = label.y
rampResolution.backgroundColour = menuBackgroundColour
rampResolution.textColour = widgetTextColour
rampResolution.arrowColour = menuArrowColour
rampResolution.outlineColour = menuOutlineColour

function arpeg()
  while isRunning do
    local rampTime = beat2ms(getResolution(rampResolution.value))
    local waitTime = getResolution(waitResolution.value)
    local probability = getRandomBoolean(probability.value)
    if probability == true then
      sendScriptModulation(sourceIndex1.value, 0, rampTime)
      sendScriptModulation(sourceIndex2.value, 1, rampTime)
    else
      sendScriptModulation(sourceIndex1.value, 1, rampTime)
      sendScriptModulation(sourceIndex2.value, 0, rampTime)
    end
    waitBeat(waitTime)
  end
end

function onTransport(start)
  isRunning = start
  if isRunning then
    arpeg()
  end
end
