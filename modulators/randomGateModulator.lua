-------------------------------------------------------------------------------
-- A script modulator for gating with min/max durations for on and off state --
-------------------------------------------------------------------------------

require "includes.subdivision"
local resolutions = require "includes.resolutions"

local isRunning = false

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "15133C" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local knobFillColour = "E6D5B8" -- Light

setBackgroundColour(backgroundColour)

local panel = Panel("Gate")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 60

local label = panel:Label("Label")
label.text = "Timed Gate"
label.tooltip = "A script modulator for gating with min/max durations for on and off state"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 110

local probability = panel:Knob("Probability", 50, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Set the probability that the gate will open or close"
probability.backgroundColour = widgetBackgroundColour
probability.fillColour = knobFillColour
probability.outlineColour = labelBackgoundColour
probability.x = label.x + label.width + 30
probability.width = 120

local waitResolution = panel:Menu("WaitResolution", resolutions.getResolutionNames())
waitResolution.displayName = "Max Duration"
waitResolution.tooltip = "The maximum duration of the gate"
waitResolution.selected = 11
waitResolution.width = 120
waitResolution.x = probability.x + probability.width + 10
waitResolution.backgroundColour = menuBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour

local waitResolutionMin = panel:Menu("WaitResolutionMin", resolutions.getResolutionNames())
waitResolutionMin.displayName = "Min Duration"
waitResolutionMin.tooltip = "The minimum duration of the gate"
waitResolutionMin.selected = 17
waitResolutionMin.width = 120
waitResolutionMin.x = waitResolution.x + waitResolution.width + 10
waitResolutionMin.backgroundColour = menuBackgroundColour
waitResolutionMin.textColour = widgetTextColour
waitResolutionMin.arrowColour = menuArrowColour
waitResolutionMin.outlineColour = menuOutlineColour

local sourceIndex = panel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.backgroundColour = widgetBackgroundColour
sourceIndex.textColour = widgetTextColour
sourceIndex.displayName = "Event Id"
sourceIndex.size = {90,20}

local gateButton = panel:OnOffButton("GateButton", true)
gateButton.displayName = "On"
gateButton.persistent = false
gateButton.tooltip = "Shows the current state of the gate"
gateButton.backgroundColourOn = "green"
gateButton.backgroundColourOff = "303030"
gateButton.textColourOn = "white"
gateButton.textColourOff = "gray"
gateButton.size = {90,20}
gateButton.x = sourceIndex.x
gateButton.y = sourceIndex.y + sourceIndex.height + 5
gateButton.changed = function(self)
  if self.value == true then
    gateButton.displayName = "On"
    sendScriptModulation(sourceIndex.value, 1)
  else
    gateButton.displayName = "Off"
    sendScriptModulation(sourceIndex.value, 0)
  end
end

function getDuration()
  local minResolution = resolutions.getResolution(waitResolutionMin.value)
  local resolution = resolutions.getResolution(waitResolution.value)
  local subdivisions = {{value=true}}
  local subDivProbability = 100
  local subdivision, subDivDuration, remainderDuration, stop = getSubdivision(resolution, 1, minResolution, subDivProbability, subdivisions, false, 0)
  return subDivDuration
end

function arpeg()
  local round = 0
  while isRunning do
    local waitTime = beat2ms(getDuration()) -- Set round duration
    round = round + 1 -- Increment round
    if gem.getRandomBoolean(probability.value) then
      gateButton:setValue(gateButton.value == false) -- Toggle gate
    end
    if round == 1 then
      waitTime = waitTime - 50
    end
    wait(waitTime)
  end
end

function onNote(e)
  local voiceId = postEvent(e)
  if isRunning == false then
    isRunning = true
    arpeg()
  end
end

function onRelease(e)
  local voiceId = postEvent(e)
  isRunning = false
end

function onTransport(start)
  isRunning = start
  if isRunning then
    arpeg()
  elseif probability.value > 0 then
    gateButton:setValue(true)
  end
end
