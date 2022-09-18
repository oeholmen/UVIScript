-----------------------------------------------------------------
-- A script modulator that toggles between two states (on/off)
-- Deprecated - use randomGateModulator instead
-----------------------------------------------------------------

require "common"

local isRunning = false

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "15133C" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

setBackgroundColour(backgroundColour)

local state = 1 -- The initial state

local panel = Panel("Toggle")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 40

local label = panel:Label("Label")
label.text = "Random on/off"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22

local sourceIndex = panel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.backgroundColour = widgetBackgroundColour
sourceIndex.textColour = widgetTextColour
sourceIndex.displayName = "Event Id"

local probability = panel:NumBox("Probability", 50, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Set the probability that the states will change"
probability.textColour = widgetTextColour
probability.backgroundColour = widgetBackgroundColour

local waitResolution = panel:Menu("WaitResolution", getResolutionNames())
waitResolution.displayName = "Duration"
waitResolution.tooltip = "The duration between changes"
waitResolution.selected = 11
waitResolution.showLabel = false
waitResolution.height = 20
waitResolution.width = 90
waitResolution.backgroundColour = menuBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour

local rampTime = panel:NumBox("RampTime", 20, 0, 500, true)
rampTime.unit = Unit.MilliSeconds
rampTime.displayName = "Ramp Time"
rampTime.textColour = widgetTextColour
rampTime.backgroundColour = widgetBackgroundColour

local stateButton = panel:OnOffButton("StateButton", true)
stateButton.displayName = "On"
stateButton.tooltip = "Shows the current state - click to manually toggle state"
stateButton.backgroundColourOn = "green"
stateButton.backgroundColourOff = "red"
stateButton.size = {60,20}
stateButton.changed = function(self)
  changeState(self.value)
end

function changeState(on)
  if on == true then
    state = 1
    stateButton.displayName = "On"
  else
    state = 0
    stateButton.displayName = "Off"
  end
  controlChange(3, state)
  sendScriptModulation(sourceIndex.value, state, rampTime.value)
end

function arpeg()
  local round = 0
  while isRunning do
    round = round + 1 -- Increment round
    local waitTime = beat2ms(getResolution(waitResolution.value))
    if round > 1 and getRandomBoolean(probability.value) then
      stateButton:setValue(state == 0)
    end
    if round == 1 then
      waitTime = waitTime - 50
    end
    wait(waitTime)
  end
end

function onTransport(start)
  isRunning = start
  if isRunning then
    arpeg()
  end
end
